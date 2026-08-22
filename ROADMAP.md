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
| ✅ | Media | Hybrid thumbnail caching: native MediaStore thumbnail first, persistent disk cache, decode fallback (2026-08-22). |
| ✅ | Analyzer | Storage Analyzer: isolate scan, donut chart, largest folders/files (2026-08-22). |
| ✅ | Recycle bin | Delete redirects to `.recycle_bin` (moveToTrash) instead of permanent erase, per-volume trash with `.meta.json` sidecars (2026-08-22). |
| ✅ | Recycle bin | Restore (parent dir recreated, collision rename), delete permanently, empty trash (2026-08-22). |
| ✅ | Recycle bin | Multi-select, select-all, bulk restore/delete, and list/grid view toggle (2026-08-22). |
| ✅ | Encryption | `.ff4` AES-256-GCM encryption: encrypt/decrypt single files, folders (recursive), and multi-selects in place (2026-08-22). |
| ✅ | Encryption | Optional file-name hiding (random id), lock icon in Explorer, and the `Encryptor` tool listing all `.ff4` files flat with list/grid + select-all (2026-08-22). |
| ✅ | Encryption | Encrypt/decrypt run through the Transfer Station as queueable tasks with progress (2026-08-22). |
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
| ✅ | UI polish | CRED-style deep premium accent palette: richer saturated seed colors (`7C3AED` purple, `059669` green, `DB2777` pink, `DC2626` red, `2563EB` royal blue). |
| ✅ | UI polish | Sixth accent **Mint** (`00B887`) added to the picker (2026-08-22). |
| ✅ | UI polish | Neumorphic card system (`NeumorphicCard`): soft extruded-plastic surface, dual light/dark shadows derived from the background hue, press-inset tactile feedback, used across Home/Downloader/Transfers/Media/Search/Settings/Core Features/permission card. |
| ✅ | UI polish | Neumorphic control theming: rounded bottom sheets with drag handle, filled rounded inputs with primary focus border, neumorphic switches, rounded checkboxes, segmented buttons with primary selection. |
| ✅ | UI polish | Home header is a pinned `SliverAppBar` (denser, always visible). |
| ✅ | UI polish | Kind-specific folder icon (`KindFolderIcon`): gradient body + darker tab + glow; audio, documents, and archives media folder tiles use it in list and grid views (2026-08-22). |
| ✅ | UI polish | Pending queue color unified to blue (`1E88E5`) across Transfers and Downloader (was orange). |
| ✅ | UI polish | Settings theme-mode segmented button: icons removed, compact density. |
| ✅ | UI polish | Home category/shortcut tiles follow the selected accent immediately at launch (no stale purple until revisit): `themeAnimationDuration: Duration.zero` + non-const `_ShortcutGrid()` so the lazily built grid re-reads the final theme; regression-tested (2026-08-20). |
| ✅ | Settings | Persisted settings store and typed `AppSettings`. |
| ✅ | Settings | Explorer, Transfers, and Search toggle groups wired into behavior. |
| ✅ | Downloader | Universal Downloader with yt-dlp bundled via Chaquopy (paste a link, queue, live progress/speed, retry, cancel, concurrency limit). See `docs/DOWNLOADER.md`. |
| ✅ | Downloader | Pause/resume (in-place blocking hook; resume continues the same connection), cancel-of-paused, and paused-task restore. |
| ✅ | Downloader | Completed tasks: copy-error action, completion datetime, and a polished kebab menu (Move to / Open folder / Browse). |
| ✅ | Downloader | Browse/open-folder open a dedicated pushed view (`/downloader/browse`) so back returns to the downloader, not Explorer. |
| ✅ | Downloader | Browse view and change-folder picker render as grids (thumbnails/icons, 4–8 responsive columns) via shared `DownloadEntryGrid`. |
| ✅ | Downloader | Quality presets (Auto / 480p / 720p / 1080p / Max) persisted on the task row (drift schema v9) and honored in Python's format selection. |
| ✅ | Downloader | Static **pure-LGPL** ffmpeg bundled in assets (cross-compiled FFmpeg 7.1 with Zig, `--disable-gpl`), copied into app storage on first launch, used for video+audio merging (`-c copy`). LGPL-2.1 text + provenance ship next to the asset (2026-08-19, replaces a GPLv3 johnvansickle binary). |
| ✅ | Downloader | **Threads video downloads** via a vendored yt-dlp extractor plugin (`yt-dlp-threads`, crawler-UA bypass of the login wall). Bundled in app python (with `__init__.py` — Chaquopy can't import upstream's PEP 420 namespace package), imported before yt-dlp so its meta_path `PluginFinder` can't hijack the import, and registered directly into yt-dlp's extractor registry (verified: resolves `threads.com` share + `@user/post` links). Re-registered after an in-app yt-dlp update. |
| ⚠️ | Downloader | Site support limited to what `yt-dlp` (plus the vendored Threads plugin) can resolve; no DRM/login-gated content. See `docs/DOWNLOADER.md` → Limitations. |
| ✅ | Branding | Android launcher icons generated from the provided logo. |

## Last Verified

Current local check status:

```bash
git status --short
# clean after downloader mp3/playlist + test-fix slice (uncommitted)

dart format lib
# passed

flutter analyze
# passed

flutter test
# passed — 142/142 (encryption service/repository tests added 2026-08-22; recycle bin repository tests added 2026-08-22; stale Home/media widget expectations fixed 2026-08-20; theme-accent regression test added 2026-08-20)

flutter build apk --debug
# passed after native media_store channel changes
```

Update 2026-08-22 (2nd): **Encryption landed** — `.ff4` AES-256-GCM containers (PBKDF2-HMAC-SHA256) with in-place encrypt/decrypt of single files, folders (recursive), and multi-selects; optional file-name hiding (random id); lock icon in Explorer; the `Encryptor` Tools screen (flat list of all `.ff4` files, list/grid + select-all); and encrypt/decrypt running through the Transfer Station as queueable tasks. Also: consistent list/grid toggle icons across Explorer/Media/Recycle/Encryptor, a shared `AppLoadingIndicator` (analyzer-style spinner) used everywhere, Tools back button now returns Home (`context.push`), and destructive-action confirmations now apply to multi-select delete and recycle-bin permanent delete. `flutter analyze` clean; `flutter test` 142/142; debug APK verified on device.

Update 2026-08-22: **Recycle bin landed** — `TransferController` redirects delete to `moveToTrash` (`.recycle_bin` per volume, `.meta.json` sidecars); restore / delete-permanently / empty-trash, plus select-all, bulk restore/delete, and a list/grid toggle. Also fixed the transfer snackbars that never dismissed (Flutter 3.38+ `persist` default for snackbars with an action — added `persist: false`) and the dead "Transfers" action (stale context → `router.go`). `flutter analyze` clean; `flutter test` 135/135; debug APK verified on device.

Update 2026-08-20: `flutter analyze` clean and `flutter test` 130/130 after the downloader MP3-transcoding + playlist-toggle slice (schema v10 `audioFormat`/`playlist` columns) and the stale widget-test fix. Python module `py_compile` clean; native changes (Kotlin bridge, Python) pending a debug APK build + on-device verification.

Update 2026-08-20 (2nd): fixed the `user_version=7` migration crash — unguarded `createTable(downloadTaskRows)` in the `from < 8` branch threw `table already exists` on a version-skipping device DB (7 → 10), failing the whole DB open and freezing Settings on its loading bar. All `createTable` branches are now `tableExists`-guarded, and the v10 `addColumn` guard was hardened to use the SQL column name (`column.name`) after a 3rd hit (`duplicate column name: audio_format`, camelCase vs snake_case mismatch). See `DOS_AND_DONTS.md` + CHANGELOG. **Verified on device**: v7 DB opened cleanly, `PRAGMA user_version` now 10, no SqliteException.

Update 2026-08-20 (4th): **Home theme-accent bug fixed** — shortcut/category tiles stayed default purple at launch until Home was revisited. Root cause: MaterialApp's default 200 ms `AnimatedTheme` restarts on the async settings load, so `HomeScreen`'s rebuild reads the still-old interpolated accent and the lazily built shortcut grid never re-renders; `const _ShortcutGrid()` also never rebuilt. Fix: `themeAnimationDuration: Duration.zero` in `app.dart` + non-const `_ShortcutGrid()` in `home_screen.dart`. Regression test `test/theme_accent_repro_test.dart`; suite now **131/131**; debug APK verified on device (saved red+light accent renders on first frame). See CHANGELOG.

Update 2026-08-20 (3rd): **Threads downloads now work.** The `yt-dlp-threads` plugin was pip-installed from GitHub but never loaded: yt-dlp discovers plugins by scanning sys.path for a real `yt_dlp_plugins/extractor` directory, which never exists under Chaquopy's in-APK virtual filesystem — and yt-dlp's own meta_path `PluginFinder` then blocks any direct `import yt_dlp_plugins` with `ModuleNotFoundError`. Fixed by vendoring the plugin in `src/main/python/yt_dlp_plugins` (with `__init__.py`, `extractPackages` for real files), importing it before yt-dlp registers that finder, and registering `ThreadsIE` directly in `yt_dlp.extractor._extractors_context` (re-run after in-app yt-dlp updates). Device log confirms `ThreadsIE registered`; extractor resolves `threads.com` share + `@user/post` URLs (title/formats/duration verified locally against the exact failing URL). See `DOS_AND_DONTS.md` + CHANGELOG.

Local analyzer passes after the MediaStore category discovery implementation. Verified on a real Android device: Images/Videos/Audio categories open in ~1–2s (previously scaled with total folder/file count). Android debug build is only necessary after native, Gradle, manifest, platform-channel, dependency, or asset changes.

The latest debug APK path, after running a build, is:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Last full check on 2026-08-13 after the Universal Downloader (Chaquopy + yt-dlp) landed: `flutter analyze` clean, `flutter test` all passing, `flutter build apk --debug` succeeds with yt-dlp bundled. A live end-to-end download on a real device is still unverified.

Update 2026-08-14: `flutter analyze` clean, downloader controller tests 15/15 passing, and a live YouTube download was confirmed end-to-end on a real device (wireless debug). Pause/resume, copy-error, kebab-menu, browse-view, and datetime polish landed.

Update 2026-08-19: `flutter clean` + rebuild + uninstall/reinstall on the real device after fixing a drift migration crash (`duplicate column name: quality`) that left downloads stuck at "Downloading". Startup shows no `SqliteException`, DB opens at `user_version=9`, and a live YouTube Short download completed end-to-end with the task persisted as `completed`. `flutter analyze` clean on the edited Dart files.

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
| ✅ | 4 | Tests | Update stale test expectations for current Home/media behavior — widget test now asserts the pinned `SliverAppBar` + storage/shortcut markers; full suite 130/130 (2026-08-20). |
| ✅ | 5 | Archives | Add archive browsing with in-app media/text previews (extract-free ZIP viewer). |
| ✅ | 6 | Downloader | Universal Downloader: yt-dlp bundled via Chaquopy, queue + progress + retry + concurrency limit (2026-08-13, `docs/DOWNLOADER.md`). |
| ✅ | 7 | Downloader | Pause/resume, copy-error, kebab-menu completed actions, separate browse view, full picker path, completion datetime (2026-08-14). |
| ✅ | 8 | Downloader | Verify a live download end-to-end on a real Android device (Dart ↔ Chaquopy event flow) — confirmed 2026-08-14. |
| ✅ | 9 | Downloader | Bundle ffmpeg for merged video+audio streams (capped/max qualities) — done, assets→app storage on first launch. |
| ✅ | 10 | Downloader | Quality presets (Auto/480p/720p/1080p/Max) end-to-end — schema v9 `quality` column, UI chips, Python format caps. |
| ✅ | 11 | Downloader | Fix downloads stuck at "Downloading": guarded `addColumn(quality)` migration (duplicate-column crash) + controller subscribes to events before store loads (2026-08-19). |
| ✅ | 12 | Media | Add thumbnail cache for media libraries and Explorer (2026-08-22: hybrid — native MediaStore thumbnail + persistent disk cache, `thumbnail_cache.dart`). |
| ✅ | 13 | UI | Polish media folder view on real device and tune grid density (2026-08-22: rounded tiles + 8px gaps + padding; Explorer/media-library list views redesigned into rounded cards). |
| ✅ | 14 | UI | Commit the staged CRED-style neumorphic UI polish — `55ed617` (2026-08-20). |

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

### Downloader

| Status | Task |
| --- | --- |
| ✅ | Bundle yt-dlp via Chaquopy (CPython 3.12, 64-bit ABIs, `minSdk` 24). |
| ✅ | `DownloadEngine` seam + `ChaquopyDownloadEngine` over Method/Event channels. |
| ✅ | Python module: `resolve`/`start`/`cancel` with progress hooks and a drain queue. |
| ✅ | Kotlin bridge: MethodChannel handlers + EventChannel polling with `unbox()`. |
| ✅ | `DownloaderController`: enqueue, concurrency gating, progress/status events, cancel, retry, clear-finished. |
| ✅ | Persistence: `DownloadTaskRows` (schema v9, incl. nullable `quality`) + drift settings (`downloader.*`). |
| ✅ | `DownloaderScreen` UI: URL entry, video/audio chips, queue, settings, folder picker, move-to/open actions. |
| ✅ | Navigation: `/downloader` route + Home tile + More sheet + Core Features card. |
| ✅ | Tests: 15 controller tests (queue, fail, retry, cancel, pause/resume, concurrency, restore, settings). |
| ✅ | Pause/resume: in-place blocking hook, pause/resume/cancel-of-paused engine+Python+UI support, restore-paused-as-failed. |
| ✅ | Completed-task polish: copy-error action, completion datetime, polished kebab menu (Move to / Open folder / Browse). |
| ✅ | Browse/open-folder in a dedicated pushed view (`/downloader/browse`) so back returns to the downloader. |
| ✅ | Browse view and change-folder picker render as grids via shared `DownloadEntryGrid` (2026-08-14). |
| ✅ | Quality presets end-to-end: `DownloadQuality` enum persisted on the task (schema v9), UI chips, Python `_format_for` height caps with merged-stream fallback. |
| ✅ | Bundle static **pure-LGPL** ffmpeg in assets (FFmpeg 7.1 cross-compiled with Zig, `--disable-gpl --disable-nonfree`), copy into app storage on first launch, and use it for video+audio merging (`_ffmpeg_location`, `extractFfmpeg`). Replaces the GPLv3 johnvansickle binary; LGPL-2.1 text + provenance ship with the asset (2026-08-19). |
| ✅ | Verify a live download end-to-end on a real device — confirmed 2026-08-14 (wireless debug); regression pass 2026-08-19 after the stuck-download fix. |
| ✅ | Fix downloads stuck at "Downloading": drift migration `duplicate column name: quality` crash (pre-v9 DB with the column already materialized) broke DB open and crashed `initialize()` before event subscription. Guarded the `from < 9` `addColumn` with a `pragma_table_info` check; controller now subscribes to events first and tolerates store failures (2026-08-19). |
| ✅ | Audio transcoding to a specific container (e.g. mp3) via the already-bundled ffmpeg — `DownloadAudioFormat` enum + `FFmpegExtractAudio` postprocessor, persisted schema v10 `audioFormat` (2026-08-20). |
| ✅ | Playlist/`noplaylist` handling refinement — per-task Playlist toggle drives `noplaylist`, persisted schema v10 `playlist` column (2026-08-20). |

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
| ✅ | Media | Thumbnail cache (2026-08-22 — hybrid native + disk, see Immediate Pending Work #12). |
| ✅ | Storage | Storage analyzer (2026-08-22 — isolate scan, donut chart, largest folders/files). |
| ✅ | Storage | Recycle bin (2026-08-22 — moveToTrash redirect, restore/delete-permanently/empty, select-all + bulk, list/grid). |
| [ ] | Network | ShareIt/Xender-style peer transfer — 2+ devices on the same network transfer files to each other directly (existing network task). |
| ✅ | Security | `.eslock`-style encryption — folder-level, single-file, and multi-select encrypt/decrypt; `.ff4` AES-256-GCM, `Encryptor` Tools-screen feature, Transfer-Station integration (2026-08-22). |
| [ ] | UI | Multi-window — multiple independent windows that can stay on any screen, independent of each other. |
| [ ] | Tools | QR scanner — scan QR codes with a camera, keep a history of past scans, and generate a QR code from arbitrary text; new Tools-section feature. |

## Guardrails

- Keep shared behavior in shared helpers/controllers when the same logic appears in multiple places.
- UI should queue file operations through transfer controllers; widgets should not mutate files directly.
- Preserve feature-first boundaries as the app grows.
- Add tests for controller logic, storage/transfer edge cases, and shared helpers.
- Avoid large refactors unless they directly unblock the current slice.
- **Drift migrations must never assume a table/column is absent.** `beforeOpen`
  runs `createAll` with the *current* schema before `onUpgrade`, so any DB that
  skips versions (or is older than a feature) already has every table
  materialized. Every migration branch that adds a table or column must be
  guarded (`tableExists`/`pragma_table_info`) or the DB open crashes — happened
  twice already: v9 `duplicate column name: quality`, and v8→v10
  `table download_task_rows already exists` from a v7 device DB. See
  `DOS_AND_DONTS.md` and CHANGELOG 2026-08-20. When bumping `schemaVersion`,
  verify the upgrade on a real DB file at the *previous* version, not just a
  fresh install.

## Useful References

- Detailed progress log: `CHANGELOG.md`.
- Run/build commands: `README.md`.
- Design and phase plan: `../documentation/docs/SOFTWARE_DESIGN_DOCUMENT.md`.
- POC plan: `../documentation/docs/POC_IMPLEMENTATION_PLAN_IN_PHASES.md`.
