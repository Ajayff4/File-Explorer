# Roadmap

Resume guide for the Flutter app.

## Current Snapshot

The app is an early but usable file-manager vertical slice.

- App/package ID: `com.ajayff4.fileexplorer`.
- Visible app name: `File Explorer`.
- Primary theme direction: black and purple.
- Source logo: `assets/brand/logo.png`.
- Architecture: feature-first Flutter modules with Riverpod controllers, GoRouter navigation, Drift persistence, and repository boundaries.
- Android phones are the product target.
- Fake/in-memory fallbacks exist only for development and automated tests.

## What Works Now

| Status | Area | Task |
| --- | --- | --- |
| ✅ | Shell | Mobile bottom navigation. |
| ✅ | Home | Dashboard with storage summary, shortcuts, favorites, recents, and transfer station tile. |
| ✅ | Home | Core features page reachable from Home. |
| ✅ | Explorer | Android/local storage browsing where permissions allow it. |
| ✅ | Explorer | Storage root selector. |
| ✅ | Explorer | Breadcrumb and parent navigation. |
| ✅ | Explorer | Refresh. |
| ✅ | Explorer | Grid-first browsing with list/grid view toggle. |
| ✅ | Explorer | Hidden-file filtering. |
| ✅ | Explorer | Folder-first sorting by name, modified date, size, and type. |
| ✅ | Explorer | Current-folder favorite toggle. |
| ✅ | Explorer | Multi-select, select-all, clear-selection, and batch copy/move/delete. |
| ✅ | Explorer | New folder and new file creation with validation dialogs. |
| ✅ | Explorer | File type browsing from Home shortcuts with filtered folder counts. |
| ✅ | Explorer | Properties sheet with multi-select support: path, contents (files/folders), total size (async for folders), bytes, type, MIME type, modified. |
| ✅ | Android storage | Storage permission state model. |
| ✅ | Android storage | Permission education/recovery card. |
| ✅ | Android storage | Android storage volume MethodChannel. |
| ✅ | Android storage | Android `StatFs` storage summary lookup. |
| ✅ | Android storage | Android all-files access status bridge. |
| ✅ | Android permissions | Native all-files status check supplements `permission_handler`. |
| ✅ | Android permissions | Denied/restricted states show clearer settings recovery guidance. |
| ✅ | Transfers | Copy, move, rename, and recursive delete queue. |
| ✅ | Transfers | Copy/move destination selection with `Paste here`. |
| ✅ | Transfers | Progress/status UI. |
| ✅ | Transfers | Retry, cancel, clear-finished flows. |
| ✅ | Transfers | Destination conflict policies: `Skip`, `Replace`, `Keep both`. |
| ✅ | Transfers | Drift-backed transfer queue/history persistence. |
| ✅ | Transfers | Interrupted running tasks restore as failed. |
| ✅ | Archives | ZIP files can extract here through Transfers. |
| ✅ | Archives | Extract here writes into the selected/current folder without an extra wrapper folder. |
| ✅ | Archives | Files, folders, and selected entries can compress to ZIP through Transfers. |
| ✅ | Archives | ZIP compression supports optional passwords, with ZIP-only guidance for other formats. |
| ✅ | Archives | Compression dialog supports file name, type, level, and password fields. |
| ✅ | Archives | Single files can compress/extract with GZ. |
| ✅ | Archives | Files, folders, and selected entries can compress/extract with TAR. |
| ✅ | Archives | Folders can compress/extract with TAR.GZ. |
| ✅ | Archives | ZIP contents can be browsed in-app without extracting (folder navigation, refresh, and "Open with" for the archive). |
| ✅ | Archives | Files inside ZIP archives preview in-app: images, video, audio, and text. |
| ✅ | Favorites | Persisted favorite folders, Home list, and Explorer star action. |
| ✅ | Recents | Persisted recent folders/files and Home recent section setting support. |
| ✅ | Search | Search screen and route. |
| ✅ | Search | Current-folder vs storage-root scope. |
| ✅ | Search | File type filters and type-only discovery. |
| ✅ | Search | Debounced searches. |
| ✅ | Search | Persisted search index. |
| ✅ | Search | Manual reindex. |
| ✅ | Search | Transfer-driven index invalidation. |
| ✅ | Search | Background index pre-warm: storage volume roots are indexed once permission is granted, and roots cleared by a completed transfer are re-warmed automatically. |
| ✅ | Search | File result taps open previews, with a visible `Open folder` action for containing-folder navigation. |
| ✅ | Search | Search results reuse media thumbnails for images, videos, and apps. |
| ✅ | Search | Search results render as grid tiles by default. |
| ✅ | Media | Flat libraries for images, videos, audio, documents, and apps. |
| ✅ | Media | Home media library entry points. |
| ✅ | Media | Media item taps open the parent folder with matching type filter. |
| ✅ | Media | Home category shortcuts open flattened folder groups for matching files. |
| ✅ | Media | All media categories use three-column grid consistently. |
| ✅ | Media | Media libraries support grid and list view toggle. |
| ✅ | Media | Media library list view with thumbnails, badge count, name, size, and relative date. |
| ✅ | Media | Media library `...` more menu with view toggle and sort options (matching explorer). |
| ✅ | Media | Date, size, type, and name sorting controls in media libraries. |
| ✅ | Media | Media/category scanning behind repository boundaries. |
| ✅ | Media | MediaStore-backed category discovery for every kind (images/video/audio/documents/apps/archives) with walker fallback. |
| ✅ | Media | Media folder view and Explorer type-filter counts use MediaStore fast paths (`queryFiles`/`countMedia`) with filesystem fallback. |
| ✅ | Media | MediaStore index kept fresh: completed transfers re-scan their paths via `MediaScannerConnection.scanFile`. |
| ✅ | Media | Native APK icon thumbnails for app files. |
| ✅ | Media | Image and video thumbnails in media/explorer rows with icon fallback. |
| ✅ | Media | Media folder view groups files by parent folder with counts and kind-specific names. |
| ✅ | Media | Media folder view long-press opens Explorer with matching type filter. |
| ✅ | Media | Hidden folders filtered from image folder view. |
| ✅ | Media | Documents folder view uses blue file icon; document names show in folder view. |
| ✅ | Viewers | In-app image viewer with pinch/double-tap zoom, rotate, swipe previous/next, details, delete, Android share, transfer-backed rename, and Android wallpaper action. |
| ✅ | Viewers | Non-previewable files open Android's system app chooser on tap. |
| ✅ | Viewers | "Open as" action lets users force-open any file as Text, Image, Video, or Audio with choice of built-in or system viewer. |
| ✅ | Viewers | Built-in text file viewer with monospace font, line wrap toggle, adjustable font size, and support for 40+ text/code file extensions. |
| ✅ | Viewers | Files inside ZIP archives open in the same full image viewer / video player / audio player as regular files. |
| ✅ | Players | In-app video player with auto-hiding controls, landscape mode, 10-second seeking, speed, loop, shuffle, previous/next, and details. |
| ✅ | Players | Video player double-tap to seek forward/back 10s with ripple animation. |
| ✅ | Players | Video player mute/unmute button. |
| ✅ | Players | Video player keeps screen awake during playback via native wakelock channel. |
| ✅ | Players | In-app audio player with seek, speed, volume, mute, loop, shuffle, previous/next, and details. |
| ✅ | Explorer | Compact four-column grid tiles with purple folder icons. |
| ✅ | Explorer | Long-press opens item actions with Select, Share, Open with, transfer actions, and Properties. |
| ✅ | Explorer | Storage repository, media scanning, and search traverse all nested folders without depth limits. |
| ✅ | UI polish | Denser mobile list/card spacing and compact icon button taps. |
| ✅ | UI polish | Grid tiles keep icons, long names, and item counts aligned. |
| ✅ | UI polish | File-type colors centralized while preserving black/purple theme direction. |
| ✅ | Settings | Persisted settings store and typed `AppSettings`. |
| ✅ | Settings | Explorer, Transfers, and Search toggle groups wired into behavior. |
| ✅ | Branding | Android launcher icons generated from the provided logo. |

## Last Verified

Current local check status:

```bash
git status --short
# clean: MediaStore category discovery committed

dart format lib
# passed

flutter analyze
# passed

flutter test
# passed except 3 pre-existing stale widget expectations around Home/media behavior

flutter build apk --debug
# passed after native media_store channel changes
```

Local analyzer passes after the MediaStore category discovery implementation. Verified on a real Android device: Images/Videos/Audio categories open in ~1–2s (previously scaled with total folder/file count). Android debug build is only necessary after native, Gradle, manifest, platform-channel, dependency, or asset changes.

The latest debug APK path, after running a build, is:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Resume Checklist

When coming back:

1. Check git status in `project/`.
2. Commit any completed slice if it is still uncommitted.
3. Pick the next development slice from Immediate Pending Work.

## Immediate Pending Work

Recommended next slices, in order:

| Status | Priority | Area | Task |
| --- | --- | --- | --- |
| ✅ | 1 | Media | MediaStore-backed category discovery for images/audio/video (replace recursive filesystem walk). |
| ✅ | 2 | Media | MediaStore-backed category discovery for all kinds (documents/apps/archives via `MediaStore.Files`). |
| ✅ | 3 | Media | Post-transfer MediaStore rescanning (`mediaStoreScanProvider`). |
| [ ] | 4 | Tests | Update stale test expectations for current Home/media behavior. |
| ✅ | 5 | Archives | Add archive browsing with in-app media/text previews (extract-free ZIP viewer). |
| [ ] | 6 | Archives | Evaluate a separate engine for RAR and 7Z support. |
| [ ] | 7 | Media | Add thumbnail cache for media libraries and Explorer. |
| [ ] | 8 | UI | Polish media folder view on real device and tune grid density. |

## Must-Have Feature Plan

### MediaStore Category Discovery

Goal: media category views (images/audio/video) open in ~1–2s by querying Android's MediaStore index instead of recursively walking the filesystem. No depth or count limits — MediaStore returns the complete OS-maintained index. Documents/apps/archives are now served from the MediaStore Files collection too (extension-filtered), with the filesystem walker only as fallback.

| Status | Task |
| --- | --- |
| ✅ | Add native `queryMedia` MethodChannel querying MediaStore Images/Audio/Video off the main thread. |
| ✅ | Add Dart `MediaStorePlatform` channel wrapper. |
| ✅ | Add `MediaStoreMediaLibraryRepository` mapping MediaStore rows to `SearchResult`s grouped by parent folder. |
| ✅ | Auto-fallback to the recursive walker on non-Android platforms or MediaStore query failure. |
| ✅ | Wire `mediaLibraryRepositoryProvider` with a platform check. |
| ✅ | Unit tests for row mapping and fallback. |
| ✅ | Verify category open timing on a real device (target ~1–2s like ES) — confirmed lightning fast on device. |
| ✅ | Phase 2: one complete single-pass background walk with in-memory cache, reused as fallback (no depth/count limits). |
| ✅ | Expand MediaStore to documents/apps/archives via `MediaStore.Files` with extension filters (2026-08-08). |
| ✅ | Follow-up: call `MediaScannerConnection.scanFile` after transfers so new files appear in MediaStore immediately (2026-08-08 via `mediaStoreScanProvider`). |

### MediaStore Expansion Map

Every filesystem-walk flow in the app, its current cost, and the MediaStore strategy. Implementation reference: `docs/MEDIA_STORE_IMPLEMENTATION.md`.

| Flow | Walk site | When it runs | MediaStore strategy | Priority |
| --- | --- | --- | --- | --- |
| Media category: all kinds (images/videos/audio AND documents/apps/archives) | `MediaStoreMediaLibraryRepository._find` | Category tap from Home | ✅ Done — every kind queried from MediaStore (Files + extension filter); walker fallback on failure/non-Android | — |
| Media folder view | `media_folder_screen.dart` → `queryFiles` | Folder view of any media kind | ✅ Done — per-folder MediaStore listing with directory fallback | — |
| Search: type-only browse (filter chips, no query) | `FileSearchController._collectMatchingEntries` | Type filter selected in Search | ✅ Done — all kinds from MediaStore, merged with walker for non-indexed types | — |
| Search: index build / manual reindex | `FileSearchController._collectIndexEntries` → Drift | First search per root, manual reindex | ✅ Done — index seeded from MediaStore (dedup by path), walk skips seeded paths | — |
| Search: live query without index | `FileSearchController._searchDirectory` | Only when no index store available | Leave as-is (rare fallback; index path covers Android) | Low |
| Explorer: type-filter folder counts | `explorer_screen.dart` `_countMatchingEntries` | Type-filtered Explorer browsing | ✅ Done — MediaStore `countMedia` per folder with walker fallback | — |
| Explorer: folder properties "Contains" counts | `explorer_screen.dart` → `countEntriesByType` | On demand per folder in Properties | Dropped 2026-08-09 — single-folder walk is fast enough for async UI; MediaStore count adds no macro-observable benefit | Low |
| MediaStore freshness after transfers | `mediaStoreScanProvider` → `scanFiles` | Any completed transfer | ✅ Done — `MediaScannerConnection.scanFile` on source + destination paths | — |
| `StorageRepository.folderContainsFileType` | (removed) | — | ✅ Done 2026-08-08 — removed (no production callers) | — |

Notes:
- Search type-only browse and category discovery share the same flattened-by-parent shape, so `MediaStoreMediaLibraryRepository` mapping is reusable there.
- The Drift search index persists, so its walk is once-per-root; MediaStore seeding still cuts first-search and reindex cost sharply.
- `MediaStore.Files` serves documents, apps, and archives too (extension-filtered), so only the walk cache/`other` types really need a filesystem walk; the Phase 2 unified background walk + cache still covers fallback and non-indexed types. MediaStore row freshness is maintained by post-transfer `MediaScannerConnection.scanFile`.

### Category Cache

Superseded 2026-08-09: MediaStore category discovery (all six kinds) already opens
categories in ~1–2s, so a persist-and-refresh category cache no longer adds user value.
Removed from the roadmap.

### Archives

| Status | Task |
| --- | --- |
| ✅ | Add `Extract here` for `.zip` files. |
| ✅ | Add `Compress to ZIP` for files, folders, and selected entries. |
| ✅ | Add a compression type picker for ZIP, TAR, GZ, and TAR.GZ. |
| ✅ | Add file name, compression level, and password inputs to compression options. |
| ✅ | Add password prompts for encrypted ZIP compression and extraction. |
| ✅ | Queue archive operations through Transfers. |
| ✅ | Show archive progress in Transfers. |
| ✅ | Extract archive contents directly into the selected/current folder. |
| ✅ | Reuse transfer conflict policies: `Skip`, `Replace`, `Keep both`. |
| ✅ | Add `Compress to GZ` for single files. |
| ✅ | Add `Compress to TAR` for files, folders, and selected entries. |
| ✅ | Add `Compress to TAR.GZ` for folders. |
| ✅ | Add extraction for `.tar`, `.gz`, `.tar.gz`, and `.tgz`. |
| ✅ | Add archive browsing with folder navigation and previews of image/video/audio/text entries inside archives. |
| [ ] | Evaluate a separate engine for RAR and 7Z support. |

### Viewers And Players

| Status | Area | Task |
| --- | --- | --- |
| ✅ | Image viewer | Open images fullscreen from Explorer, Search, and category folders. |
| ✅ | Image viewer | Swipe next/previous within folder/category/search result playlists. |
| ✅ | Image viewer | Pinch zoom and double-tap zoom. |
| ✅ | Image viewer | Add delete/details actions. |
| ✅ | Image viewer | Replace share and rename placeholders with real Android share and transfer-backed rename actions. |
| ✅ | Image viewer | Set image as Android wallpaper. |
| ✅ | Video player | Open videos in-app from Explorer, Search, and category folders. |
| ✅ | Video player | Play/pause/seek/fullscreen controls. |
| ✅ | Video player | Speed, loop, shuffle, previous/next, and auto-hide controls. |
| ✅ | Video player | Double-tap left/right to seek back/forward 10s with ripple animation. |
| ✅ | Video player | Mute/unmute button in playback controls. |
| ✅ | Video player | Keep screen awake during playback via native wakelock channel. |
| ✅ | Audio player | Open audio in-app from Explorer, Search, and category folders. |
| ✅ | Audio player | Play/pause/seek controls. |
| ✅ | Audio player | Add folder/category/search playlist controls. |
| ✅ | Open with | Unknown files use Android system open-with sheet from preview. |
| ✅ | File actions | Long-press file actions include Share and Open with. |
| ✅ | Search | File results open previews, show media thumbnails, and expose a visible Open folder action. |

## Later Roadmap

| Status | Area | Task |
| --- | --- | --- |
| [ ] | Media | Thumbnail cache. |
| [ ] | Storage | Storage analyzer. |
| [ ] | Storage | Recycle bin. |
| [ ] | Archives | RAR and 7Z support evaluation. |
| [ ] | Network | Optional network providers, not first-release core. |

## Guardrails

- Keep shared behavior in shared helpers/controllers when the same logic appears in multiple places.
- UI should queue file operations through transfer controllers; widgets should not mutate files directly.
- Preserve feature-first boundaries as the app grows.
- Add tests for controller logic, storage/transfer edge cases, and shared helpers.
- Avoid large refactors unless they directly unblock the current slice.

## Useful References

- Detailed progress log: `CHANGES.md`.
- Run/build commands: `README.md`.
- Design and phase plan: `../documentation/docs/SOFTWARE_DESIGN_DOCUMENT.md`.
- POC plan: `../documentation/docs/POC_IMPLEMENTATION_PLAN_IN_PHASES.md`.
