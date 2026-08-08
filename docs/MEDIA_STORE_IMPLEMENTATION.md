# MediaStore Implementation

How media category discovery works after the 2026-08-06 optimization, why it is
fast, and how to extend the same approach to other flows.

## Problem

Media category views (Images / Videos / Audio) flatten every folder containing
that media type into one level, no matter how deep it lives in storage
(`0/A/B`, `0/X`, `0`, `0/X/Y/Z` all render side by side).

The original implementation discovered these files by recursively walking the
filesystem:

- `StorageMediaLibraryRepository._collectResults` awaited every directory
  sequentially (depth-first).
- Each `LocalStorageRepository.listDirectory()` call cost one directory
  listing, one `stat()` per entry, and a platform-channel round trip for
  storage volumes.
- Total cost scaled with the number of folders and files on the whole device —
  opening a category fresh took seconds to minutes.

## Key Insight

ES File Explorer opens the same view in ~1–2 seconds because it never scans.
Android's media scanner service continuously indexes media files into
**MediaStore**, a system SQLite database. Querying it returns every indexed
image/audio/video on all volumes — complete, with no depth or count limits —
in milliseconds.

## Architecture

```
MediaLibraryScreen
  └─ mediaLibraryResultsProvider          (unchanged UI/provider contract)
       └─ mediaLibraryRepositoryProvider
            └─ createMediaLibraryRepository()     ← factory (io/stub conditional import)
                 ├─ Android: MediaStoreMediaLibraryRepository
                 │    ├─ image/audio/video → MediaStore.Images/Audio/Video query
                 │    ├─ document/archive/app → MediaStore.Files + extension filter
                 │    │    └─ MethodChannel 'com.ajayff4.fileexplorer/media_store'
                 │    │         └─ MainActivity.queryMedia()  (background thread)
                 │    └─ any failure → fallback walker
                 └─ non-Android: StorageMediaLibraryRepository (walker)
```

### Files

| File | Role |
| --- | --- |
| `android/.../MainActivity.kt` | `queryMedia`/`countMedia` channel handlers; query the matching MediaStore collection on a background `Thread`, reply on the main thread via `Handler(Looper.getMainLooper())`. Non-media kinds (`document`/`archive`/`app`) query `MediaStore.Files` and are filtered by a lowercase extension set that mirrors the app's `FileSystemEntryType` mapping. |
| `lib/features/media/data/platform/media_store_platform.dart` | `MediaStorePlatform` — typed Dart wrapper over the channel (`MediaStoreMediaItem`: path, name, sizeBytes, modifiedAt). `MediaStoreMediaType` covers all six library kinds. |
| `lib/features/media/data/repositories/media_store_media_library_repository.dart` | `MediaStoreMediaLibraryRepository` — maps rows to `SearchResult`s (`parentPath = dirname(path)`), delegates to the walker fallback only on query failure. |
| `lib/features/media/data/repositories/media_library_repository_factory_io.dart` / `_stub.dart` | `createMediaLibraryRepository()` — Android → MediaStore repo with fallback; elsewhere → walker. Mirrors the existing `createStorageRepository()` pattern. |
| `lib/features/media/data/repositories/media_library_repository_provider.dart` | Riverpod wiring, now via the factory. |
| `test/features/media/media_store_media_library_repository_test.dart` | Unit tests: row mapping, empty-path drop, parent grouping, root filtering, error fallback, document-via-MediaStore routing. |

### Native query details

- Collections: `MediaStore.Images.Media.EXTERNAL_CONTENT_URI`,
  `MediaStore.Video…`, `MediaStore.Audio…`, and
  `MediaStore.Files.getContentUri(VOLUME_EXTERNAL)` for the non-media kinds.
  The external provider covers internal storage and SD cards in one query.
- For `document`/`archive`/`app`, rows are additionally filtered in Kotlin by a
  lowercase extension set mirroring the Dart `FileSystemEntryType` mapping
  (`extensionFilterFor` in `MainActivity.kt`), so only indexed files of that
  kind cross the channel.
- Projection: `_data` (absolute path), `_display_name`, `_size`,
  `date_modified` (seconds → multiplied to ms before crossing the channel).
- `_data` is deprecated on API 29+ but remains readable: with `READ_MEDIA_*`
  for media rows, and with `MANAGE_EXTERNAL_STORAGE` ("All files access") for
  the non-media rows served from `MediaStore.Files`. Without All-files access,
  API 30+ redacts non-media rows entirely (the app's `MediaStore.Files` query
  returns only media rows), so documents/apps/archives come back empty.
  `MediaLibraryScreen` shows an "All files access needed" prompt for those
  kinds when the permission is missing; its "Grant access" button calls a
  blocking native request (`requestAllFilesAccess` in `MainActivity.kt`), which
  opens `ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION` via
  `startActivityForResult` and only resolves after the user returns.
- Rows with null/empty paths or hidden dot-segments (`/.`) are skipped,
  matching the walker's dot-file filtering.

## Behavior Parity Rules

These were chosen deliberately to make the swap invisible to the UI:

1. **Root filtering** — MediaStore is global, but results are filtered to the
   requested `rootPath` so scope matches what the walker would have returned.
2. **Hidden filtering** — dot-path segments are excluded, same as the walker.
3. **Empty is valid** — an empty MediaStore result means "no media", not
   failure; only a thrown error triggers the walker fallback (avoids a slow
   walk on devices that simply have no images).
4. **Fallback on failure** — every kind uses MediaStore; only a thrown
   channel/query error silently falls back to the walker.

## Verification

- `flutter analyze` clean; `dart format` applied.
- 6/6 new unit tests pass; full suite identical to pre-change baseline
  (4 stale Home/media widget expectations predate this change).
- `flutter build apk --debug` passes (native channel change).
- Real device: Images/Videos/Audio categories open in ~1–2s regardless of
  folder depth or count — parity with ES File Explorer.

## Known Limitations

- MediaStore only contains what the OS has indexed. A file created moments ago
  (e.g. by this app's transfers) appears after the OS scans it — closed by the
  Phase 3 `MediaScannerConnection.scanFile` call after completed transfers.
- `.nomedia` folders are excluded by MediaStore (consistent with the walker's
  hidden-file behavior and with ES).
- Documents/apps/archives are served from `MediaStore.Files` filtered by
  extension. Coverage depends on the OS media scanner having indexed those
  files; files it skipped (e.g. freshly created, or OEM-excluded extensions)
  are invisible until scanned. On failure the walker fallback still runs.
- On Android 10+ (API 30+), `MediaStore.Files` hides non-media rows unless the
  app has "All files access" (`MANAGE_EXTERNAL_STORAGE`). Without it the
  non-media libraries show the All-files-access prompt instead of silently
  appearing empty. Note: a reinstall (even `adb install -r`) revokes this
  grant, so the prompt reappears after reinstall until the user re-grants it.
- The search index seeding (`_collectIndexEntries`) deliberately skips
  document/archive/app, so indexing millions of non-media rows doesn't crowd
  out media; type-only browse still serves those kinds from MediaStore.

## Extending This Approach

The walk-flow inventory and per-flow strategy live in
`ROADMAP.md` → "MediaStore Expansion Map". The reusable pieces:

- `MediaStorePlatform.queryMedia()` supports all six kinds
  (image/audio/video/​document/archive/app).
- The `SearchResult(parentPath: dirname)` mapping in
  `MediaStoreMediaLibraryRepository` is directly reusable for Search's
  type-only browse, which renders the same flattened shape.

## Phase 2: Walk Cache + Search Integration (2026-08-06)

### Walk cache

`MediaLibraryWalkCache` performs one complete single-pass walk per storage
root, bucketed by `FileSystemEntryType`, and serves all non-MediaStore
categories (documents/apps/archives) from that one walk:

- **TTL** — fresh results are served from memory (default 5 minutes); a stale
  or missing root triggers a re-walk.
- **In-flight dedup** — concurrent `resultsFor` callers await the same walk
  future instead of walking per category.
- **`invalidate(rootPath)`** — drops a root's cache for an immediate re-walk.
- Injected `now` clock keeps TTL behavior unit-testable.

`StorageMediaLibraryRepository` delegates to the cache when one is provided;
without a cache it walks a single type exactly as before. The factory and
`mediaLibraryWalkCacheProvider` wire a shared cache into both the MediaStore
repository's fallback and the pure walker on non-Android platforms.

### Search integration

`FileSearchController` receives `createMediaStorePlatform()` (Android-only,
null elsewhere) and uses it in two flows:

1. **Type-only browse** (`setFilteredTypes` with an empty query): media types
   are answered by `MediaStorePlatform.queryMedia` (root-filtered via
   `isUnderRootPath`, mapped via `toSearchResult`) while non-media types — and
   any media type whose query threw — still run through
   `_collectMatchingEntries`. Media types therefore no longer trigger a full
   device walk.
2. **Index build / reindex** (`_collectIndexEntries`): all three MediaStore
   collections seed the index first (deduped by path, root-filtered), then the
   walker (`_walkIndexEntries`) adds every non-seeded entry and skips seeded
   paths, so media files remain searchable even when the walk hits
   `_maxIndexedEntries`.

Shared helpers live in
`lib/features/media/data/platform/media_store_search_results.dart`:
`mediaStoreMediaTypeFor`, `fileSystemEntryTypeFor`, `isUnderRootPath`, and
`MediaStoreMediaItem.toSearchResult`.

Search walks now also propagate `depth` into `SearchResult`s so the existing
`_compareResults` comparator's shallower-first ordering actually applies.

### Remaining expansion-map items

- Properties "Contains" counts: optional per-folder MediaStore counts (low
  value; single-folder async UI already acceptable).
- `folderContainsFileType`: no production callers — removal candidate.
- `MediaScannerConnection.scanFile` after transfers (fresh-file gap).

## Phase 3: Scan + Counts + Cleanup (2026-08-08)

### MediaStore sync after transfers

`MediaStorePlatform.scanFiles(paths)` → native `MediaScannerConnection.scanFile`
on the `media_store` channel. `mediaStoreScanProvider`
(`features/media/presentation/controllers/media_store_scan_provider.dart`),
watched from `app.dart`, listens to `TransferController` and scans the
`sourcePaths` + `destinationPath` of every task that just completed:

- new destinations (copy/move/rename/extract/compress) are indexed immediately,
  closing the "fresh file not in MediaStore" gap;
- moved/deleted source paths are pruned from the index.

Non-Android platforms (and tests) get a null platform via
`createMediaStorePlatform()` and skip scanning. `mediaStorePlatformProvider`
exposes the platform for overriding in tests.

### MediaStore folder view (all kinds)

`MediaFolderScreen` (drilling into a folder from a category or search result)
now answers every kind — image/video/audio *and* documents/apps/archives —
from the native `MediaStore.Files` collection (`queryFiles(path)`), instead of
listing the directory:

- The FILES collection is what the media scanner indexes for *all* files, so
  non-media kinds are covered too.
- `queryFiles` scopes to `_data = path OR _data LIKE path/%` with the same
  hidden-segment exclusion as `queryMedia`/`countMedia`, then `_loadEntries`
  filters by the screen's `kind.type` and sorts by modified time.
- On any channel/query failure (or non-Android), the screen falls back to the
  original `Directory.list()` walk, so behavior is unchanged when MediaStore is
  unavailable.

### MediaStore folder counts in Explorer

Explorer's type-filter view (`_FilteredEntryListView`) previously walked every
folder recursively to answer "how many of type X live here". For image/video/
audio filters it now calls `MediaStorePlatform.countMedia(type, rootPath)` —
a native `COUNT(*)` query scoped to `_data = path OR _data LIKE path/%` with
the same hidden-segment exclusion as `queryMedia` — falling back to
`countEntriesByType` on failure or for non-media types.

### Cleanup

`StorageRepository.folderContainsFileType` (and its recursive walker) removed —
it had no production callers; the Explorer filter is the sole consumer of
per-folder type counts and now goes through `countEntriesByType` /
`countMedia`.
