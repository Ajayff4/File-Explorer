# Changes

Progress log for the Flutter application.

## 2026-08-19

### Completed

- Fixed the ffmpeg licensing issue — the bundled static ffmpeg binary was **GPLv3**
  (johnvansickle.com build with `--enable-gpl --enable-version3` + x264/x265/xvid),
  which imposes GPL obligations on a binary distributed inside a proprietary app.
  Replaced it with a **pure-LGPL 2.1** static build:
  - Cross-compiled FFmpeg 7.1 from the official release with Zig 0.13.0
    (`zig cc -target aarch64-linux-musl`) using `--disable-gpl --disable-nonfree`,
    only LGPL-compatible components enabled (h264/hevc/vp9/av1/mpeg4 decoders,
    common audio, mp4/matroska/webm muxers) — exactly what the downloader's
    merge/remux step needs (no re-encoding, no GPL codecs).
  - Binary is 14.9 MB stripped (was 51 MB) and fully static, so it still runs on
    Android (bionic) as a subprocess. Verified on-device: `ffmpeg -version` works
    and a real video+audio merge (`-c copy`) produced a valid MP4.
  - Shipped `LGPL-2.1.txt` + a `PROVENANCE` note next to the asset documenting
    source URL, build config, and the exact configure line; recorded in
    `docs/DOWNLOADER.md`.
  - APK size dropped from ~217 MB to ~196 MB.
- Added download quality presets (Auto / 480p / 720p / 1080p / Max):
  - New `DownloadQuality` enum (nullable) on `DownloadTaskRows` — drift schema
    bumped to **v9** with a `from < 9` migration adding the `quality` column.
  - Quality is chosen from chips on the downloader screen, persisted on the
    task row, forwarded through the MethodChannel to Python, and honored by
    `_format_for` (height-capped progressive format with a merged video+audio
    fallback).
- Bundled a static ffmpeg binary so merged video+audio streams work:
  - `assets/ffmpeg/ffmpeg` is copied into app-private storage on first launch
    (`extractFfmpeg` in `MainActivity.kt`) and located by `_ffmpeg_location`
    (test-harness env var → bundled binary → system PATH → imageio-ffmpeg).
  - Capped/max qualities can now fall back to `bestvideo[height<=H]+bestaudio`
    merging instead of single-progressive-only.
- Added a Python integration test matrix (`tool/downloader_integration_test.py`
  + `run_downloader_test.sh`): resolves and downloads a battery of public sites
  in a venv (with imageio-ffmpeg), covering the quality presets.
- Fixed downloads appearing permanently stuck at "Downloading":
  - **Root cause** — a corrupt pre-v9 drift database. `createTable`/`createAll`
    materialize the current table definition (which includes the `quality`
    column), so any DB reaching the `from < 9` migration step with that column
    already present (fresh installs, or a version-skipping DB) threw
    `SqliteException: duplicate column name: quality` during `beforeOpen`.
    The DB open failure then crashed `DownloaderController.initialize()` before
    it subscribed to the engine event stream, so Python actually completed the
    download but no event ever reached Dart — the task stayed frozen at
    "Downloading" with no progress/completion/failure.
  - **Migration fix** — the `from < 9` `addColumn(downloadTaskRows.quality)`
    step is now guarded by a `pragma_table_info` existence check
    (`app_database.dart`); it only adds the column when it is actually missing,
    so any pre-v9 DB upgrades cleanly.
  - **Controller hardening** — `DownloaderController.initialize()` now
    subscribes to `engine.events()` *first* and wraps both store loads in
    try/catch (`downloader_controller.dart`). A broken store can no longer
    prevent event delivery or the task lifecycle.
  - **Debug instrumentation** — `downloader.py` gained a `_debug()` helper that
    appends timestamped lines to `files/downloader_debug.log`; `MainActivity.kt`
    gained `Log.d("DownloaderDebug", ...)` lines for `start` calls, event
    subscription/cancel, and drained events. Both proved Python was completing
    downloads while the UI was not updating.
  - **Verification** — `flutter clean` + rebuild + full uninstall/reinstall on
    the real device (wiping the corrupt DB): no `SqliteException` in logcat,
    DB opens at `user_version=9`, and a live YouTube Short download completed
    end-to-end with the persisted task marked `completed` (status enum index 2).

### Verified

- `flutter analyze` — clean (both edited Dart files).
- Live end-to-end download on a real device (wireless debug) after the fix.
- Pulled device DB: `user_version=9`, `download_task_rows.quality` present,
  persisted task status = `completed`.
- `tool/run_downloader_test.sh` integration matrix — all sites in the battery
  resolve and download.

## 2026-08-14

### Completed

- Rounded out the Universal Downloader after the first live end-to-end download on a real device:
  - **Pause/resume** — a full-stack `paused` status: `pause`/`resume` on the engine seam, MethodChannel cases in `MainActivity.kt`, Python `_pause_events` (the progress hook blocks in place on the worker thread so the connection stays alive; resume sets the event and the download continues seamlessly, cancel wakes a blocked hook and aborts).
    - `DownloadTaskStatus.paused` was appended at the end of the enum so existing Drift rows (persisted by index) stay valid.
    - Cancel now also cancels paused tasks (previously a blocked thread would have kept running).
    - Interrupted `paused` tasks restore as failed, same as `running`.
    - UI: pause/resume icons on active tasks, a paused status color/icon, and paused shows progress.
  - **Copy-error button** — failed tasks expose a one-tap "copy error" action that puts the failure message on the clipboard.
  - **Browse as a separate view** — "Open folder"/"Browse" now push a dedicated `DownloadBrowseScreen` (`/downloader/browse`) instead of switching to the Explorer tab, so back returns to the downloader (not Explorer). The browse view lists folder contents, navigates up/down, and opens files through the existing preview pipeline.
  - **Grid view for browse + folder picker** — the downloader browse view and the change-folder picker now render entries as grids (thumbnails/icons, 4–8 responsive columns) via a shared `DownloadEntryGrid` widget, matching Explorer's grid instead of plain list rows.
  - **Kebab menu polish** — completed-task actions (Move to / Open folder / Browse) moved into a polished `PopupMenuButton` on the card's right side (rounded surface, soft icon tiles) instead of the in-card button row.
  - **Full path in folder picker** — the current-path text in the output-folder picker wraps to 2 lines instead of hard-truncating with `...`.
  - **Completion datetime** — finished tasks show when they completed via a new `formatDownloadTimestamp` helper (Today/Yesterday at HH:MM, or `DD Mon HH:MM`).
  - **Folder-create crash fix** — the new-folder dialog no longer uses a `TextEditingController` (disposing an in-use controller mid-teardown tripped a framework assert); it captures input directly instead.
- Documented downloader limitations in `docs/DOWNLOADER.md`: site support is limited to what `yt-dlp` can resolve (e.g. Threads and sites without a working extractor will not download), no playlist handling, no ffmpeg-based format conversion/merging, no DRM/logged-in content, and no resumed byte-range downloads after a network drop.
- Downloader controller tests grew from 10 to **15** (pause, resume, ignore-pause-on-failed, cancel-paused, restore-paused-as-failed).

### Verified

- `flutter analyze` — clean.
- Downloader controller tests — 15/15 pass.
- Live YouTube download confirmed end-to-end on a real device (wireless debug).

## 2026-08-13

### Completed

- Added a Universal Downloader: paste a YouTube/Instagram/Twitter/other media link and download it as video or audio with queueing, live progress/speed, retry, cancel, and a concurrent-download limit. Implementation reference: `docs/DOWNLOADER.md`.
  - **Engine** — yt-dlp is bundled into the APK through the Chaquopy Gradle plugin (CPython 3.12 + `pip install yt-dlp`). `download_engine.dart` defines the seam; `ChaquopyDownloadEngine` drives it over a MethodChannel/EventChannel, with a `FakeDownloadEngine` stand-in for non-Android dev and tests.
  - **Python module** — `android/app/src/main/python/downloader.py` wraps yt-dlp: `resolve`/`start`/`cancel`, single-file video/audio formats (no ffmpeg needed), progress hooks pushed into a drain queue.
  - **Kotlin bridge** — `MainActivity.kt` exposes `resolve`/`start`/`cancel` plus an EventChannel that polls the drain queue every 150 ms; values are `unbox()`ed from Chaquopy `PyObject`s into codec-safe types.
  - **Controller** — `DownloaderController` handles enqueue, concurrency gating (`maxConcurrentDownloads`, 1–16), progress/status event application, cancel, retry, clear-finished, and restoring interrupted running tasks as failed. Settings (concurrency + output folder) persist via drift.
  - **Persistence** — new `DownloadTaskRows` drift table (schema v8 + migration); task rows saved on every change so history survives restarts.
  - **UI** — `DownloaderScreen`: URL entry with paste-from-clipboard and video/audio chips, active/finished queues with progress bars and speed, a summary card (pending/done/failed), settings card with concurrency stepper and a folder picker, and per-task cancel/retry/move-to/open-browse actions.
  - **Navigation** — new `/downloader` route plus Home tile, More-sheet entry, and Core Features card.
  - **Gradle** — Chaquopy v17.0.0, 64-bit ABIs only (`disable-abi-filtering=true` so Flutter doesn't re-add `armeabi-v7a`, which Chaquopy doesn't ship for Python 3.12+), `minSdk` raised to 24.
  - **Tests** — 10 fresh `DownloaderController` tests: enqueue→running→completed, failure + clear-finished, retry, cancel, concurrency cap and next-start-on-finish, persistence restore, interrupted→failed, and settings save/load.
  - Verification: `flutter analyze` clean, `flutter test` all green, `flutter build apk --debug` succeeds with yt-dlp bundled. Live end-to-end download on a real device is still pending.

## 2026-08-09

### Completed

- Added background search index pre-warm and post-invalidation re-warm so indexed folder searches stay fast:
  - `FileSearchController.warmUpIndex(root)` pre-builds/persists a root's index (walks the tree once, seeds MediaStore rows); it is a no-op when the index exists, when a build is already in flight, or when indexed search is disabled.
  - `searchIndexPreWarmProvider` (watched from `app.dart`) warms every storage volume root once browse permission is confirmed, so the first folder search never forces an on-demand walk.
  - `searchIndexInvalidationProvider` now re-warms the roots it clears after a completed transfer instead of leaving them missing: `SearchIndexStore.clearIndexesForPaths` reports the cleared root paths and each root is rebuilt in the background.
  - Fresh tests: `warmUpIndex` pre-builds and is gated on indexed search, completed transfers clear then re-warm overlapping roots, and volume roots pre-warm only once permission is granted.

- Added in-app ZIP archive browsing:
  - Opening a `.zip` file shows its contents directly in a folder-style viewer (`ZipViewerScreen`) instead of only offering "Extract here".
  - Folder navigation, back-to-parent, and refresh inside the archive.
  - Archive entries render with folder/file type badges and human-readable sizes.
  - "Open with" opens the whole archive via Android's system app chooser.
- Added in-app preview for files inside ZIP archives:
  - Images, videos, audio, text/code files, and "Open as" for forcing a type.
  - ZIP media previews now reuse the **same** full-featured viewer/player used for regular files (`MediaViewerScreen`):
    - Images: pinch/double-tap zoom, rotate, swipe next/previous, share, details, delete, transfer-backed rename, and set-as-wallpaper.
    - Video: auto-hiding controls, landscape mode, 10-second double-tap seeking with ripple, playback speed, loop, shuffle, previous/next, mute, and screen-wake wakelock.
    - Audio: seek, speed, volume, mute, loop, shuffle, previous/next, and details.
  - Entries are extracted to a temporary file for playback and cleaned up when the preview closes.
- Replaced the separate, reduced-feature ZIP image/video/audio screens with the shared viewers/players (single implementation, no duplicated media UI).

## 2026-08-08

### Completed

- Expanded the MediaStore API from images/video/audio to **every** library kind — documents, apps, and archives are now answered from Android's MediaStore `Files` collection:
  - Native `queryMedia` gained extension filtering (`extensionFilterFor`) so `document`/`archive`/`app` kinds are served from `MediaStore.Files` instead of the recursive walker; the walker remains the fallback for non-Android platforms and query failures.
  - `MediaStoreMediaLibraryRepository` now answers all kinds (image, video, audio, document, archive, app) from the index, matching the app's `FileSystemEntryType` mapping.
  - New native `queryFiles` MethodChannel: per-folder MediaStore listing, used by the media folder view for a fast path instead of walking the directory tree.
  - New native `countMedia` MethodChannel: per-folder type counts from MediaStore, used by Explorer's type-filter folder listings (with filesystem walker fallback).
  - New native `scanFiles` MethodChannel wrapping `MediaScannerConnection.scanFile`.
- Added post-transfer MediaStore rescanning (`mediaStoreScanProvider`, watched from `app.dart`):
  - When a transfer completes, its source and destination paths are sent to the OS media scanner so newly created files (copy/move/rename/extract/compress destinations) appear in MediaStore-backed views immediately and moved/deleted source rows are pruned.
  - Best-effort scanning; failures never surface as unhandled errors.
  - Fresh tests for completed-transfer scanning and the non-Android no-op path.
- Cleaned up `StorageRepository`: removed `folderContainsFileType` (no production callers) and its recursive walker, keeping the interface minimal.
- Fixed "Open with"/share for files outside the FileProvider root (e.g. `Directory.systemTemp`), and returned readable error messages when no app can open a file.
- Device permission and routing fixes on the real Android device (permission recovery guidance, media library screen permission handling, routing docs added in `docs/ROUTING.md`).

## 2026-08-06

### Completed

- Added built-in text file viewer:
  - Opens `.txt`, `.md`, `.html`, `.css`, `.js`, `.ts`, `.jsx`, `.tsx`, `.json`, `.xml`, `.yaml`, `.py`, `.java`, `.kt`, `.dart`, `.go`, `.rs`, `.c`, `.cpp`, `.php`, `.rb`, `.swift`, and many more text-based file types.
  - Monospace font display with selectable text.
  - Toggle line wrapping on/off.
  - Adjustable font size (10pt to 24pt).
  - Loading state, error handling with retry, and empty file state.
  - Text files now open in built-in viewer by default instead of system app chooser.
- Updated "Open as" Text option to show choice between built-in text viewer and system apps.
- Added "Open with" for non-previewable files:
  - Tapping any file (PDF, documents, etc.) in explorer now opens Android's app chooser instead of doing nothing.
  - Grid and list views both handle taps for all file types.
  - Uses existing `openLocalFileWithSystem` MethodChannel with MIME type lookup.
- Added "Open as" action for forcing file type:
  - Long-press any file and tap "Open as" from the actions sheet.
  - Shows type options: Text, Image, Video, Audio.
  - For Image/Video/Audio: shows a choice between "Use File Explorer" (built-in viewer) and "Use other app" (system chooser).
  - For Text: directly opens system chooser with `text/plain` MIME type.
  - Selection bottom bar "More" delegates to full actions sheet when single file is selected.
- Enabled Android predictive back gesture (`android:enableOnBackInvokedCallback="true"` in manifest).
- Added list view to media library screens:
  - All media libraries (Images, Videos, Audio, Documents, Apps, Archives) now support grid and list view toggle.
  - List view shows 64x64 thumbnails with badge count, name, total size, and relative date.
  - All media libraries now use 3-column grid consistently (was 4-column for non-image/video).
- Replaced sort icon with `...` more menu in media libraries:
  - Menu matches explorer pattern with view toggle (grid/list) and sort options with check marks.
  - Sort options: Name A-Z/Z-A, Modified newest/oldest, Size largest/smallest, Type A-Z.
- Documents folder view now uses blue file icon (`insert_drive_file`) instead of extension badges.
- Document file names now show in media folder view (same as audio/app/archive).
- Extracted shared `FileEntryListTile` widget for consistent list rendering across explorer and media:
  - 64x64 thumbnail with icon fallback, badge count, name, subtitle (size/date or count/date).
  - Selection mode support with checkbox.
  - Used in both explorer list view and media library list view.
- Added shared number formatting utilities (`lib/shared/formatters/number_format.dart`):
  - `formatCount` adds comma separators (e.g. 1,606).
  - `formatItemCount` formats item counts with commas.
  - Used consistently across explorer, media library, and properties panel.
- Added shared `formatRelativeDate` helper for relative time display (e.g. "3d ago").
- Properties panel now supports multi-select:
  - Accepts list of entries instead of single entry.
  - Multi-select shows: Path (common parent), Contains (X files, Y folders), Size, Bytes.
  - Single select shows: icon, name, type, path, MIME type (files), contents (folders), size, bytes, modified.
  - Folder size computed asynchronously with "Computing..." state.
  - Copy path button (copies common parent for multi-select).
  - Location section removed (was redundant).
- Explorer list view updated to use shared `FileEntryListTile`:
  - Shows badge count for folders, size + date for files, count + date for folders.
  - Selection count in app bar uses comma formatting.
- Added Android MediaStore-backed media category discovery:
  - New native `queryMedia` MethodChannel (`com.ajayff4.fileexplorer/media_store`) querying MediaStore Images/Audio/Video off the main thread.
  - New `MediaStorePlatform` Dart wrapper and `MediaStoreMediaLibraryRepository` implementing `MediaLibraryRepository`.
  - Images/Videos/Audio category views now load from Android's OS-maintained media index instead of recursively walking the filesystem; category open time dropped from scan-dependent (grew with folder/file count) to ~1–2s, matching ES File Explorer.
  - Results filtered to the requested storage root and hidden dot-path segments skipped, matching previous walker behavior.
  - Automatic fallback to the recursive walker for non-media types (documents, apps, archives), on non-Android platforms, and on MediaStore query failure.
  - Added unit tests for channel row mapping, root filtering, fallback, and non-media delegation.
- Added Phase 2 MediaStore expansion (walk cache + Search integration):
  - New `MediaLibraryWalkCache`: one single-pass recursive walk per storage root, bucketed by entry type, with 5-minute TTL and in-flight dedup so concurrent category opens share one walk. `StorageMediaLibraryRepository` (documents/apps/archives fallback) now serves results from it.
  - Shared MediaStore→`SearchResult` mapping helpers (`media_store_search_results.dart`) reused by category discovery and Search.
  - Search type-only browse (filter chips, no query): media types answered from MediaStore in milliseconds and merged with walker results for non-media types; per-type walker fallback when a MediaStore query fails.
  - Search index build/reindex: seeded from MediaStore media rows (deduped by path) so media files are indexed even when the walk hits its entry cap; the walk skips already-seeded paths.
  - Search walks now propagate entry depth so shallower matches sort before deeper ones, matching the existing comparator's intent.
  - New unit tests: walk cache (single walk, TTL expiry, in-flight dedup, invalidate) and Search MediaStore paths (merge, root filtering, fallback, index seeding, no duplicates).

### Verified

- `flutter analyze`
- `dart format lib test`
- `flutter test` (3 pre-existing stale widget expectations around Home/media behavior remain)
- `flutter build apk --debug`
- Real-device pass: Images/Videos/Audio categories open in ~1–2s via MediaStore.

### Pending Verification

- Real-device pass for media library list view toggle and sort menu.
- Properties panel multi-select with large folder counts.

## 2026-08-05

### Completed

- Added media folder view with folder-based browsing:
  - Media libraries (Images, Videos, Audio, Documents, Apps) now expose a folder view that groups files by their parent folders.
  - Folder view shows file counts per folder and uses a three-column grid for images/videos, four-column for other types.
  - Long-press in media folder view opens a bottom sheet with `Open in folder` to navigate to the full Explorer with the matching type filter pre-applied.
  - Folder view names are now specific to each media kind (Audio, Apps, Archives, etc.).
  - Hidden folders are filtered out of the image folder view.
  - Folder view is linked to the actual Explorer so tapping a folder opens it in full Explorer context.
- Expanded the video player:
  - Added a mute/unmute button to playback controls.
  - Added double-tap to seek: double-tap left half to rewind 10s, right half to forward 10s, with a ripple animation at the tap position.
  - Added a native Android wakelock MethodChannel so the screen stays awake during video playback and releases when paused or disposed.
  - Fixed orientation handling so media viewer locks to portrait by default and allows all orientations only during fullscreen/landscape playback.
- Removed depth limitations:
  - Storage repository, media library scanning, and search no longer cap directory traversal at 5 levels.
  - All nested folders are now traversed for counts, media results, and search indexing.
- Cleaned up Explorer regular view by removing redundant item counts from list/grid tiles.
- Fixed media folder screen navigation bugs and search mode code refactoring.

### Verified

- `flutter analyze`
- `dart format lib test`

### Pending Verification

- Real-device pass for video double-tap seek, mute, and wakelock behavior.
- Media folder view long-press navigation to Explorer on a real device.

## 2026-08-02

### Completed

- Expanded archive workflows (full ZIP/TAR/GZ/TAR.GZ support):
  - `.zip` files expose `Extract here` from file actions.
  - Compression opens an options dialog with file name, type (ZIP/TAR/GZ/TAR.GZ), compression level, and password fields.
  - Files, folders, and selected entries can be compressed with ZIP or TAR.
  - ZIP compression supports optional passwords; other formats show ZIP-only password guidance.
  - Single files can be compressed with `Compress to GZ`.
  - Folders can be compressed with `Compress to TAR.GZ`.
  - Archive extraction supports `.zip`, `.tar`, `.gz`, `.tar.gz`, and `.tgz`.
  - Archive operations run through Transfers with progress, retry, cancel, and conflict policy handling.
  - Added the `archive` package as a direct dependency with transfer executor tests.
- Added "New folder" and "New file" actions to Explorer:
  - App-bar/dropdown actions create a folder (`createFolder`) or an empty text file (`createFile`) in the current directory with inline dialogs and confirmation feedback.
- Polished grid-first browsing across the app:
  - Explorer, Search, and Media libraries now default to grid view for denser folder/file browsing.
  - Selecting the Files tab resets Explorer to grid view.
  - Grid tiles keep icons, long names, and item counts aligned in fixed slots.
- Refactored search mode presentation:
  - Extracted shared file entry visuals for reuse across Explorer and Search.
  - Reduced duplication between search and explorer screen layouts.
- Added selection bottom bar for Explorer multi-select:
  - Multi-select now shows a bottom action bar with copy, move, and delete batch operations.
  - Selection state and actions are shared between list and grid views.
- Added media folder view foundation:
  - Media libraries now support a folder-based view that groups results by parent directory with file counts.
  - Folder view uses three-column grid for images/videos and four-column for other types.

### Verified

- `flutter analyze`
- `flutter test test/features/transfers/data/local_transfer_executor_io_test.dart`
- `flutter build apk --debug`

### Pending Verification

- Real-device pass for archive compress/extract with passwords.
- Grid-first layout across Explorer, Search, and Media on various screen sizes.

## 2026-08-01

### Completed

- Added in-app media preview from Explorer:
  - Image, video, and audio files now open inside the app instead of doing nothing.
  - Media previews receive same-type sibling files so previous/next and shuffle can work within the current folder.
- Built a fuller video player:
  - Added start/end, previous/next, 10-second seek, play/pause, looping, shuffle, playback speed, landscape mode, background playback option, and auto-hiding controls.
  - Fixed rotated-video aspect handling by honoring `rotationCorrection` when calculating display ratio.
  - Moved video preview outside the app shell so bottom navigation does not appear during playback.
- Expanded the image viewer:
  - Added pinch zoom, double-tap zoom, swipe previous/next, rotate, labeled bottom controls, Android share, and a More menu.
  - More menu now contains Info, Delete, Rename, and Set as wallpaper.
  - Delete queues through Transfers after confirmation.
  - Rename now queues through Transfers and validates path separators.
  - Share now opens Android's system share sheet through a content URI.
  - Set as wallpaper is wired through an Android `WallpaperManager` MethodChannel.
  - Fixed image More-menu route timing around rename/delete/info actions so dialogs and sheets are opened after the popup menu settles.
  - Moved the image rename dialog text controller into the dialog lifecycle and delayed transfer queueing until after the dialog transition settles.
  - Tightened image toolbar and More-menu density by reducing button slots, row height, and icon/title gaps.
- Expanded the audio player:
  - Added a dedicated audio player surface with title/path, volume slider, mute/unmute, previous/next, loop, shuffle, speed, seek, and info.
- Added Android open-with support for unsupported files:
  - Unknown previews now show `Open with`.
  - Android launches the system chooser with a `FileProvider` content URI.
- Updated Search result behavior:
  - File result taps now open the file preview instead of jumping to the containing folder.
  - Search result rows now expose a visible `Open folder` text action that preserves the previous containing-folder navigation behavior.
  - Search results now use shared media thumbnails for images, videos, and apps, with icon fallback for other file types.
  - Search results now render as grid tiles by default.
- Expanded Explorer long-press actions:
  - Long-press now opens the entry actions sheet instead of immediately toggling selection.
  - The actions sheet keeps `Select` available for selection mode.
  - File actions now include `Share` and `Open with` using the shared Android media action channel.
- Added first archive workflow:
  - `.zip` files now expose `Extract here` from file actions.
  - ZIP extraction asks for an optional password from file actions.
  - Missing or wrong ZIP passwords now show a readable transfer failure instead of a decoder null-check error.
  - Compression now opens an options dialog with file name, type, compression level, and password fields.
  - Supported compression types are ZIP, TAR, GZ, and TAR.GZ.
  - Files, folders, and selected entries can be compressed with ZIP or TAR.
  - ZIP compression can use the optional password field; other formats show ZIP-only password guidance.
  - Single files can be compressed with `Compress to GZ`.
  - Folders can be compressed with `Compress to TAR.GZ`.
  - Archive extraction now supports `.zip`, `.tar`, `.gz`, `.tar.gz`, and `.tgz`.
  - Archive extraction writes directly into the selected/current folder instead of creating an extra wrapper folder.
  - Archive extract/compress operations run through Transfers with progress, retry, cancel, and conflict policy handling.
  - Archive, rename, and confirmed delete dialogs now queue through a live transfer controller after the actions sheet closes.
  - Added `archive` as a direct dependency and covered archive extract/compress behavior with transfer executor tests.
- Polished file details:
  - Replaced the redundant Parent folder row with a `MIME Type` row.
  - Added the `mime` package as a direct dependency.
- Added a Home feature listing page:
  - Home has a `What this app can do` entry.
  - The feature page has a back action and a richer card grid for the app's core capabilities.
  - Tightened feature-card spacing and centered the leading icon vertically.
- Polished grid browsing:
  - Explorer now opens in grid view by default.
  - Selecting the Files tab resets Explorer to grid view.
  - Explorer and media grid tiles keep icons, long names, and item counts aligned in fixed slots.
- Documented Android wireless debugging in `README.md`.

### Verified

- `flutter analyze`
- `flutter test test/features/transfers/data/local_transfer_executor_io_test.dart`
- `flutter build apk --debug` after native media action changes

### Verification Note

- APK builds are only necessary after native Android/iOS, Gradle, manifest, platform-channel, dependency, or asset changes. Dart-only layout/timing fixes can usually stop at `dart format` and `flutter analyze` unless runtime behavior needs a packaged APK.

### Pending Verification

- Real-device pass for image wallpaper setting, media controls, and viewer gestures.
- Existing widget tests need updating for the current Home/media library behavior.

## 2026-07-30

### Completed

- Documented current roadmap gaps and aligned the immediate task list with the actual app state.
- Restored local verification after the type-filter browsing changes:
  - Formatted `lib` and `test`.
  - Fixed the Explorer breadcrumb analyzer lint.
  - Updated search test repositories to implement `folderContainsFileType()`.
- Hardened type-filter browsing coverage:
  - Added widget coverage for Home category shortcuts opening Explorer with an active type filter.
  - Added controller coverage for type-only search returning matching descendants without a text query.
  - Made fake storage folder type checks reflect sample folders instead of always returning true.
  - Streamed recursive folder scans so type checks can stop on the first match without materializing full directory listings.
  - Fixed filtered folder counts so folder tiles show matching files for the active type instead of total child entries.
- Polished file properties:
  - Added storage label, storage root, parent folder, full path, formatted size, raw byte count, modified date, and item count rows.
  - Added widget coverage for storage/location property rows.
- Added first media library slice:
  - Added `/media/:kind` routes for images, videos, audio, documents, and apps.
  - Added Home media library entry points while keeping Explorer folder-filter shortcuts intact.
  - Added flat media library screens with result count, storage scope, refresh, and browse-folders action.
  - Media result taps open the parent folder in Explorer with the matching type filter preserved.
  - Fake storage now returns path-specific sample folders and files for media library testing.
  - Added widget coverage for opening the Images media library from Home.
- Added first thumbnail slice:
  - Image and video media rows now render local thumbnails with icon fallback.
  - Explorer list/grid rows reuse image/video thumbnails.
  - Non-Android builds keep icon fallback through conditional imports for development/test runs.
  - Added widget coverage for thumbnail widgets in the Images library.
- Polished Explorer item layout:
  - Grid view now uses compact four-column tiles with purple folder icons.
  - Long-press opens item actions instead of rendering overflow buttons on every item.
- Added media library sorting:
  - Media libraries can sort by name, modified date, size, and type.
  - Media headers show the active sort order.
- Added extension-aware icons for known files:
  - PDF, Office documents, spreadsheets, presentations, text, code/data, archives, APK/AAB, and installer files now get more specific icons.
  - Known file icons use type colors, such as red PDFs, blue documents, green sheets/CSV, and red presentations.
- Moved media library scanning behind a repository boundary so presentation widgets no longer walk storage directly.
- Updated Home category shortcuts to open flattened folder groups, so matching folders nested deep in storage appear at the first level of the category view.
- Added Android APK icon extraction over MethodChannel so app files can show their real app icon with fallback.
  - `.apks`, `.xapk`, `.apkm`, and `.aab` now classify as app files and use Android app fallback icons.
- Updated category folder layouts:
  - Image and video categories use a three-column grid with larger thumbnails.
  - Other file categories use a compact four-column grid.
- Completed pending Android permission polish:
  - Permission checks now use the native all-files status bridge before falling back to `permission_handler` status.
  - Denied, permanently denied, and restricted states now show clearer recovery guidance.
- Completed pending UI polish:
  - Tightened mobile card/list density and icon button tap sizing.
  - Centralized file-type colors while keeping the black/purple theme direction.
- Updated README status so Settings is no longer described as a placeholder.

### Verified

- `dart format lib test`
- `flutter analyze`
- Targeted `flutter test test/features/search/file_search_controller_test.dart test/widget_test.dart`
- `flutter test`

### Pending Verification

- Real device/emulator testing of storage and transfer workflows.
- Performance testing for type-filter folder scans on large directory trees.

## 2026-07-24

### Completed

- Fixed back button navigation in Explorer:
  - `PopScope` now properly intercepts Android system back presses.
  - Back navigates up one folder level (e.g., `0→A→B` → `0→A`) instead of minimizing the app.
  - Back exits selection mode when items are selected.
  - Only allows minimize/pop when already at volume root.
  - Added `explorer_navigation.dart` helper module with `canNavigateUpInExplorer()` logic.
- Added breadcrumb navigation bar to Explorer:
  - Breadcrumb displays current path with home icon and segment links.
  - Clicking a non-terminal segment navigates to that folder.
  - Terminal segment is display-only (no tap).
  - Breadcrumb scrolls horizontally on narrow screens.
- Fixed subfolder/child count display:
  - Explorer repository now returns child count via `DirectoryListing`.
  - List/grid views display folder child count instead of generic "folder" text.
  - Count updated on each directory refresh.
- Enhanced entry actions menu:
  - Entry action sheet now includes rename/delete/move operations.
  - Actions properly queue operations through transfer controller.
  - Shared transfer presentation helpers ensure consistent operation icons.
- Added multi-select explorer workflow:
  - Selection mode with checkboxes in both list and grid views.
  - Select-all and clear-selection buttons in app bar when items selected.
  - Batch copy/move/delete operations through existing transfer queue.
  - Selection action bar at bottom with copy, move, delete buttons.
  - Proper state management for selection mode toggle.
- Added real category counts to Home dashboard shortcuts:
  - New `countEntriesByType()` method in StorageRepository interface.
  - Implemented recursive file counting in LocalStorageRepository with 5-level depth limit.
  - Fake repository returns sample counts for web/test builds.
  - Home shortcuts now display actual file counts instead of "Browse" placeholder.
  - Added `categoryCounts` FutureProvider for async count computation.
  - Loading spinner shown while counts are computed.
  - Graceful fallback to "Browse" text if count fetch fails.
- Updated test repositories to implement countEntriesByType for consistency.
- Fixed filter persistence when opening storage roots or switching volumes:
  - Clearing the active `explorerFilterTypeProvider` when opening a storage root from Home.
  - Clearing the filter when selecting a different storage volume in the Explorer volume switcher.
  - Ensures tapping a storage root shows the full listing instead of a previously-applied type filter view.
- Added type-only search discovery (ES-style file type shortcuts):
  - Home shortcuts now open Explorer at storage root with type filter enabled.
  - Explorer filter logic updated to always show folders (navigation containers) but only matching file types.
  - Folder structure/hierarchy is preserved; you navigate through real folders.
  - At each folder level, only files of the selected type are visible (plus all subfolders).
  - Type filter persists when navigating into subfolders, so nested folders also show only matching files.
  - Explorer flat list approach removed; performance-optimized by filtering at render time instead of collecting all matches.
  - Search still supports type-only flat discovery results when filters are used without a text query.
  - Storage root shortcut still clears filter to show full listing.

### Verified

- `flutter analyze` (0 errors, 4 lint warnings unrelated to changes)
- Code builds without compilation errors.
- Back button logic and breadcrumb navigation confirmed through code inspection.
- Selection mode UI and multi-select actions verified in code.
- Category count provider correctly wired to home shortcuts.

### Pending Verification

- Real device/emulator testing of all features end-to-end.
- Performance testing of category count computation on large directory trees.
- Verify shortcut counts update when navigating to different storage volumes.

## 2026-07-19

### Completed

- Created the Flutter application in `project/`.
- Set the Dart package name to `file_explorer`.
- Set the native application/package ID to `com.ajayff4.fileexplorer`.
- Set the visible app name to `File Explorer`.
- Added core app dependencies:
  - `flutter_riverpod`
  - `go_router`
  - `drift`
  - `sqlite3_flutter_libs`
  - `path_provider`
  - `path`
  - `build_runner`
  - `drift_dev`
- Replaced the generated Flutter counter app with the first app foundation:
  - App shell.
  - Responsive navigation.
  - Home dashboard.
  - Explorer screen.
  - Transfers screen.
  - Settings screen.
- Added fake storage data for early UI development.
- Added black and purple as the primary visual direction.
- Updated `README.md` with run, build, web, Android, desktop, test, and codegen commands.
- Added the first storage repository boundary:
  - `StorageRepository` interface.
  - Fake repository for web/fallback/sample data.
  - Local `dart:io` repository for supported local platforms.
  - Conditional repository factory so web builds avoid `dart:io`.
- Added `ExplorerController` to centralize directory loading and refresh behavior.
- Rewired Home and Explorer screens to consume repository-backed explorer state.
- Added folder tap navigation through the controller.
- Renamed leftover app widget naming from `EsFileExplorerApp` to `FileExplorerApp`.
- Added the first storage permission foundation:
  - `StoragePermissionState` domain model.
  - `StoragePermissionRepository` interface.
  - Fake permission repository for web/tests.
  - Permission-handler-backed repository for local/Android builds.
  - Conditional repository factory so web stays decoupled from `dart:io`.
  - Storage permission education/recovery card in Explorer.
- Added Android storage permission declarations for legacy read/write, Android 13 media reads, and Android 11+ all-files access.
- Added `permission_handler` dependency.
- Added tests for storage permission state mapping.
- Added Android storage browsing foundation:
  - Native MethodChannel for Android storage volume discovery.
  - Native storage capacity lookup using Android `StatFs`.
  - Native all-files access status bridge.
  - Dart `AndroidStoragePlatform` wrapper.
  - Android-aware `LocalStorageRepository` volume and summary lookup.
  - Parent-folder navigation from Explorer without moving above the current storage root.
- Added tests for Android storage platform channel mapping.
- Pinned Android `compileSdk` to `35` because `permission_handler_android` and `sqlite3_flutter_libs` require it.
- Documented Android SDK license and SDK 35 setup commands in `README.md`.
- Added exact Linux Mint `/usr/lib/android-sdk` `sdkmanager` commands for accepting licenses and installing Android SDK 35/build tools.
- Added storage root switching in Explorer:
  - Explorer state now tracks discovered storage volumes.
  - App bar storage selector opens any detected root.
  - Selected volume summary/listing state updates together.
  - Added controller coverage for opening a secondary storage root.
- Added the first transfer queue foundation:
  - Transfer task domain model for copy, move, delete, and rename.
  - Transfer controller with queue, destination, progress, completion, retry, cancel, and clear-finished transitions.
  - State-driven Transfer Manager screen.
  - Explorer entry action sheet that queues file operation intents instead of mutating files directly.
  - Shared transfer presentation helpers for operation icons and status colors.
  - Unit tests for transfer controller state transitions.
- Updated `README.md` Android APK build commands to show explicit debug and release variants.
- Added first transfer executor foundation:
  - Transfer executor interface.
  - Conditional fake/local executor provider.
  - Local `dart:io` executor for copy, move, rename, and recursive delete.
  - Controller auto-runs ready queued tasks and keeps copy/move waiting for destination.
  - Tests for controller execution flow and local file operations.
- Added copy/move destination workflow:
  - Explorer shows a pending destination banner for copy/move tasks.
  - `Paste here` assigns the current folder as the destination and starts the queued task.
  - `Cancel` cancels the pending task.
  - Explorer refreshes when a completed task touches the current folder.
- Added transfer destination conflict handling:
  - Existing destinations fail with a typed `destinationExists` error by default.
  - Transfer Manager exposes `Skip`, `Replace`, and `Keep both` actions for destination conflicts.
  - Local copy, move, and rename operations share one conflict policy resolver.
  - `Keep both` writes to a unique `name (1).ext` style path.
  - Added executor and controller tests for conflict policy behavior.
- Added Drift database foundation for transfer persistence:
  - Added app database setup and generated Drift schema code.
  - Added `transfer_task_rows` table for transfer queue/history data.
  - Added transfer task store boundary with Drift-backed IO implementation.
  - Kept web/fallback builds on an in-memory transfer task store.
  - Transfer controller now saves queue, progress, failure, completion, and clear-finished changes.
  - Transfer controller hydrates saved queue/history on startup.
  - Interrupted `running` tasks restore as failed instead of staying stuck as active.
  - Added controller coverage for loading history, restoring interrupted work, and persisting loaded queued work.
- Added favorites/bookmarks foundation:
  - Added persisted `favorite_location_rows` Drift table with schema version 2 migration.
  - Added favorite location entity, store boundary, Drift IO store, and in-memory fallback store.
  - Added `FavoritesController` for loading, adding, removing, and toggling favorite folders.
  - Added Explorer star action for the current folder.
  - Added Home favorites section with open/remove actions.
  - Added controller tests for loading, toggling, and favorite ordering.
- Added recent locations/history foundation:
  - Added persisted `recent_location_rows` Drift table with schema version 3 migration.
  - Added recent location entity, store boundary, Drift IO store, and in-memory fallback store.
  - Added `RecentsController` for loading, recording, removing, and clearing recent folders.
  - Explorer now records successfully opened folders.
  - Home recent section now shows persisted folder history instead of current directory entries.
  - Added tests for recent loading, deduping, open counts, remove/clear, sorting, and Explorer recording.
- Added search foundation:
  - Added Search route and screen.
  - Added debounced file search controller.
  - Search traverses the current folder tree through `StorageRepository`.
  - Search matches file/folder names and paths.
  - Search uses result/depth caps and ignores unreadable folders.
  - Slow stale searches cannot overwrite newer query results.
  - Result taps open folders directly or open the parent folder for files.
  - Added tests for matching, sorting, clearing, and stale search cancellation.
- Added search filters and scope polish:
  - Added current folder vs storage root scope selector.
  - Added type filter chips for folders, images, videos, audio, documents, archives, and apps.
  - Added result count header.
  - Improved loading state from a bare progress bar to a list tile state.
  - Added tests for type filters and explicit search scope.
- Added indexed search persistence:
  - Added persisted `search_index_entry_rows` Drift table with schema version 4 migration.
  - Added search index store boundary with Drift-backed IO implementation and in-memory fallback.
  - First search for a scope builds an index from the storage repository.
  - Later searches reuse the stored index instead of walking storage again.
  - Search UI now shows an indexing state during first index build.
  - Added test coverage for index reuse.
- Added manual search reindex controls:
  - Search screen now exposes a reindex action.
  - Reindex clears the current scope index and rebuilds it from storage.
  - Added test coverage for clearing stale indexed results.
- Added automatic search index invalidation:
  - Search index stores can clear indexes that overlap changed paths.
  - App root listens for completed transfer tasks and invalidates affected search indexes.
  - Added test coverage for transfer-driven index invalidation.
- Added settings foundation:
  - Added persisted `setting_rows` Drift table with schema version 5 migration.
  - Added typed `AppSettings` model and setting keys.
  - Added settings store boundary with Drift-backed IO implementation and in-memory fallback.
  - Added `SettingsController` for loading, updating, and resetting settings.
  - Replaced placeholder settings with grouped Explorer, Transfers, and Search toggles.
  - `Use indexed search` now controls whether search uses the persisted index.
  - Added controller tests for defaults, persistence, and reset.
- Wired settings into app behavior:
  - `Show hidden files` now controls dot-prefixed explorer entries through a shared entry filter.
  - `Confirm destructive actions` now controls whether delete queues immediately or asks first.
  - `Show transfer station` now controls the Home transfer status tile.
  - `Show folders only in history` now filters Home recents and allows file history when disabled.
  - Added `isFolder` to recent history persistence with Drift schema version 6 migration.
  - Search result taps can record file recents when file history is enabled.
  - Added tests for explorer entry filtering and file recent recording.
- Added Explorer sorting:
  - Added a shared `sortExplorerEntries` helper for folder-first sorting.
  - Added sort options for name, modified date, size, and type.
  - Added an Explorer app bar sort menu shared by list and grid views.
  - Added tests for name, size, and modified-date ordering.
- Added app branding assets:
  - Added the source logo at `assets/brand/logo.png`.
  - Added `flutter_launcher_icons` configuration.
  - Generated launcher icons for Android, iOS, web, Windows, and macOS.
  - Updated web app icon assets and manifest colors.

### Verified

- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter build web`
- `flutter build apk --debug` (confirmed locally by user)

### Pending

- Replace permission-handler all-files check with a dedicated Android platform service if we need deeper settings/result handling.
- Verify real Android directory browsing on a device/emulator.
- Continue UI polish using reference screenshots.
