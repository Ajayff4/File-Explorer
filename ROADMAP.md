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
- Two Android build flavors ship from one codebase:
  - `universal` — full app including the Universal Downloader (Chaquopy + yt-dlp + ffmpeg); for sideload / F-Droid / GitHub.
  - `standard` — Google Play build with the downloader fully excluded (no `yt-dlp`/Python/`ffmpeg`/libchaquopy, no `download_task_rows` table, no `…/downloader` channel). Gated by the compile-time `enableDownloader` flag.
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
| ✅ | Media | Hybrid thumbnail caching: native now **decodes the real image file** (BitmapFactory, downscaled) instead of relying on MediaStore (which serves stale thumbnails for overwritten/disk-written files); persistent disk cache keyed by path + size + mtime; videos still use MediaStore; decode fallback (2026-08-27 fix). |
| ✅ | Analyzer | Storage Analyzer: isolate scan, donut chart, largest folders/files (2026-08-22). |
| ✅ | Recycle bin | Delete redirects to `.recycle_bin` (moveToTrash) instead of permanent erase, per-volume trash with `.meta.json` sidecars (2026-08-22). |
| ✅ | Recycle bin | Restore (parent dir recreated, collision rename), delete permanently, empty trash (2026-08-22). |
| ✅ | Recycle bin | Multi-select, select-all, bulk restore/delete, and list/grid view toggle (2026-08-22). |
| ✅ | Encryption | `.ff4` AES-256-GCM encryption: encrypt/decrypt single files, folders (recursive), and multi-selects in place (2026-08-22). |
| ✅ | Encryption | Optional file-name hiding (random id), lock icon in Explorer, and the `Encryptor` tool listing all `.ff4` files flat with list/grid + select-all (2026-08-22). |
| ✅ | Encryption | Encrypt/decrypt run through the Transfer Station as queueable tasks with progress (2026-08-22). |
| ✅ | Tools | **Save Current Wallpaper** (Home → Tools) copies the device's current home + lock screen wallpapers into `File Explorer/Wallpaper` (byte-for-byte, lossless PNG fallback), with an **Open** action that jumps into Explorer (2026-08-27). |
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
| ✅ | UI polish | Neumorphic card system (`NeumorphicCard`): soft extruded-plastic surface, dual light/dark shadows derived from the background hue, and press-inset tactile feedback; used across Home, Downloader, Transfers, Media, Search, Settings, Core Features, and the permission card. |
| ✅ | UI polish | Neumorphic control theming: rounded bottom sheets with drag handle, filled rounded inputs with primary focus border, neumorphic switches, rounded checkboxes, segmented buttons with primary selection. |
| ✅ | UI polish | Home header is a pinned `SliverAppBar` (denser, always visible). |
| ✅ | UI polish | Kind-specific folder icon (`KindFolderIcon`): gradient body + darker tab + glow; audio, documents, and archives media folder tiles use it in list and grid views (2026-08-22). |
| ✅ | UI polish | Pending queue color unified to blue (`1E88E5`) across Transfers and Downloader (was orange). |
| ✅ | UI polish | Settings theme-mode segmented button: icons removed, compact density. |
| ✅ | UI polish | Home category/shortcut tiles adopt the selected accent instantly at launch (no stale-purple flash); regression-tested (2026-08-20). |
| ✅ | Windows | Multi-window — open multiple independent windows, each with its own folder, view mode, and back stack; switch via the **Windows** nav destination, which opens a live-thumbnail switcher (2026-08-23). |
| ✅ | Settings | Persisted settings store and typed `AppSettings`. |
| ✅ | Settings | Explorer, Transfers, and Search toggle groups wired into behavior. |
| ✅ | Downloader | Universal Downloader with yt-dlp bundled via Chaquopy (paste a link, queue, live progress/speed, retry, cancel, concurrency limit). See `docs/DOWNLOADER.md`. **Built only into the `universal` flavor — the `standard` (Play Store) flavor omits it entirely.** |
| ✅ | Downloader | Pause/resume (in-place blocking hook; resume continues the same connection), cancel-of-paused, and paused-task restore. |
| ✅ | Downloader | Completed tasks: copy-error action, completion datetime, and a polished kebab menu (Move to / Open folder / Browse). |
| ✅ | Downloader | Browse/open-folder open a dedicated pushed view (`/downloader/browse`) so back returns to the downloader, not Explorer. |
| ✅ | Downloader | Browse view and change-folder picker render as grids (thumbnails/icons, 4–8 responsive columns) via shared `DownloadEntryGrid`. |
| ✅ | Downloader | Quality presets (Auto / 480p / 720p / 1080p / Max) persisted on the task row (drift schema v9) and honored in Python's format selection. |
| ✅ | Downloader | Static **pure-LGPL** FFmpeg bundled in the app assets and used for video+audio merging (`-c copy`); the LGPL-2.1 license text and build provenance ship alongside the asset, replacing a previous GPLv3 binary (2026-08-19). |
| ✅ | Downloader | **Threads video downloads** via a vendored yt-dlp extractor plugin that bypasses the login wall; auto re-registered after each in-app yt-dlp update (verified: resolves `threads.com` share + `@user/post` links). |
| ⚠️ | Downloader | Site support limited to what `yt-dlp` (plus the vendored Threads plugin) can resolve; no DRM/login-gated content. See `docs/DOWNLOADER.md` → Limitations. |
| ✅ | Branding | Android launcher icons generated from the provided logo. |
| ✅ | Share / Open-with | App registers as `ACTION_VIEW` / `ACTION_SEND` / `SEND_MULTIPLE` target (images, audio, video, text, PDF, archives, APKs); opening a file from another manager (e.g. ES File Explorer) launches the built-in viewer instead of a 3rd-party app (2026-08-28). |

## Last Verified

Current local check status:

```bash
git status --short
# 2026-08-28 slice (uncommitted before this commit): gradle-wrapper.properties,
#   gradle.properties, settings.gradle, android/build.gradle, AndroidManifest.xml,
#   MainActivity.kt, app_router.dart, window_manager.dart, incoming_intent_handler.dart,
#   + docs/TELEGRAM_BOT.md, lib/features/sharing/

dart format lib
# passed

flutter analyze
# passed

flutter test
# 160/161 (1 pre-existing failure in nearby_share_screen_test.dart, unrelated to this
#   slice); `flutter analyze` clean; both universal + standard APKs build and were
#   verified on device 2026-08-28

flutter build apk --debug
# passed after native media_store channel changes
```

Update 2026-08-24: **Share (device-to-device transfer) landed** — renamed from Nearby; picker-based file selection from Explorer, UDP discovery across subnet broadcasts, shared `File Explorer/Share` save folder, and a dormant `--dart-define=LEGACY_STORAGE=true` for Android 9. Send-tab UX: scrolling file list with a pinned, collapsible "Nearby devices" accordion; discovered peers persist after scanning. Info dialog shows device name (now resolved from `ro.product.device` via `getprop`, no new dependency), LAN IP, and port. Also: redundant floating bottom-right multi-window tray removed (Windows nav destination already opens the switcher). `flutter analyze` clean; debug APK verified on device (RMX3031). Bug fixes: blank Send tab, self-discovery loop, clear-pending-only-on-success, receiver keeps listening across transfers, and reconnect-after-stop (session-scoped handshake code).

Update 2026-08-23: **QR generate overhaul + Analyzer/Explorer polish** — the QR Generate tab now produces customizable PNGs: solid or gradient colors (direction selectable), transparent background, Square/Rounded/Dots module styles (**Dots default**) via a new manual matrix renderer (`qr_image_builder.dart`), and a center logo with auto High error correction. **Download** saves into the public `Downloads/QRCodes` folder through a new Kotlin `saveQrToDownloads` MediaStore channel (replacing the hidden app-private path), with an Open action. Color pickers are now collapsible chips with a custom HSV dialog. Storage Analyzer: donut centered on top, full-width legend with per-category usage bars. Explorer: breadcrumbs hide the synthetic `/`, `storage`, `emulated` roots (trail starts at the volume) and the redundant AppBar folder-title was removed. `flutter analyze` clean; debug APK verified on device.

Update 2026-08-23 (2nd): **Multi-window landed** — in-app window manager reachable from the Windows nav destination / top-right overlay. Each window is an independent session with its own `GoRouter` (back stack) and its own nested `ProviderContainer` (child of root) overriding `explorerControllerProvider`/`explorerViewModeProvider`/`fileSearchControllerProvider`, so folder/view/search state is isolated. `WindowHost` renders the active window via `MaterialApp.router` wrapped in a `RepaintBoundary`; the switcher is a live-thumbnail grid (PNG captures stored per window) rendered as an overlay outside the boundary so the switcher UI is never captured, styled with neumorphic surfaces. Settings/theme stay global. `flutter analyze` clean; debug APK verified on device.

Update 2026-08-22 (3rd): **QR scanner landed** — new Tools feature (`/qr-scanner`) with three tabs: live camera scan (`mobile_scanner`, QR-only + torch + permission recovery + result sheet with copy/open/scan-another), QR generation (`qr_flutter`), and a Drift-persisted scan history (`qr_scan_rows`, schema v11). Gallery scan added via `image_picker` + `MobileScannerController.analyzeImage`. Generated QR codes are now recorded into the same history with a `Scanned`/`Generated` badge (`type` column, schema v12, guarded migration). Fixed a deadlock where the camera never initialized (the `MobileScanner` widget that requests permission was only built after permission was already granted), and hardened lifecycle start/stop. Home Tools row re-laid-out as a 2×3 `Wrap` grid so labels (incl. "QR scanner") fit on one line. `flutter analyze` clean; debug APK verified on device.

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

On 2026-08-27 the app was split into `universal`/`standard` flavors (see
`docs/PLAY_STORE_FLAVORS.md`). The `standard` release APK was built and scanned:
it contains zero `download_task_rows` / `yt-dlp` / `ffmpeg` / `libchaquopy` /
  `…/downloader` channel traces, confirming the Play Store build is downloader-free.

Update 2026-08-27 (2nd): **Save Current Wallpaper tool landed** — Home → Tools → Save Wallpaper copies the device's current home + lock screen wallpapers into `File Explorer/Wallpaper` (byte-for-byte, original format; home falls back to a lossless PNG when the OS blocks reading the file). A SnackBar **Open** action navigates into the saved folder via the Explorer controller. New `lib/features/wallpaper/data/wallpaper_service.dart` + a `saveWallpaper` handler on the `wallpaper` MethodChannel. Present in both `universal` and `standard` flavors (not downloader-gated). Also fixed stale image thumbnails for directly-written files: native `getThumbnail` now decodes the real image file (BitmapFactory downscaled) instead of `MediaStore.loadThumbnail`, and the Dart disk-cache key includes size + last-modified so overwrites invalidate it. `flutter analyze` clean; universal APK built + installed on the device (RMX3031) and verified — both wallpapers save and thumbnails render correctly.

Update 2026-08-28: **Universal build fixed + Open-with/share-target working.** The `universal` flavor stopped building because Gradle 9.1.0 broke Chaquopy 17.0.0's variant wiring (chaquopy issue #1441) — bumped Gradle to `9.2.1` (`gradle-wrapper.properties`); AGP stays 9.0.1. Pinned JDK 17 in `gradle.properties` (system java-21 is a JRE with no `javac`). Added the Chaquopy Maven repo to `settings.gradle` + `android/build.gradle`. Replaced the `isUniversal` taskNames hack with a per-flavor `chaquopy { productFlavors { universal { ... pip install yt-dlp } } }`, plugin applied unconditionally (the `standard` flavor configures no Python, stays downloader-free). Both `assembleUniversalDebug` and `assembleStandardDebug` now BUILD SUCCESSFUL. **Open-with**: ES File Explorer now opens images/videos in the built-in viewer — fixed a GoRouter redirect that treated the launch `content://` URI as a route, a native/Dart race (added `getPending` pull in `initState`), a null `GoRouter.of(context)` because `IncomingIntentHandler` wrapped `MaterialApp.router` (now passes `router: active.router`), and an ES content-URI real-path fallback in `resolveContentPath`. `flutter analyze` clean; APKs verified on device (RMX3031).

Update 2026-08-14: `flutter analyze` clean, downloader controller tests 15/15 passing, and a live YouTube download was confirmed end-to-end on a real device (wireless debug). Pause/resume, copy-error, kebab-menu, browse-view, and datetime polish landed.

Update 2026-08-19: `flutter clean` + rebuild + uninstall/reinstall on the real device after fixing a drift migration crash (`duplicate column name: quality`) that left downloads stuck at "Downloading". Startup shows no `SqliteException`, DB opens at `user_version=9`, and a live YouTube Short download completed end-to-end with the task persisted as `completed`. `flutter analyze` clean on the edited Dart files.

## Resume Checklist

When coming back:

1. Check git status in `project/`.
2. Commit any completed slice if it is still uncommitted.
3. Choose the next development slice from current product gaps (see *What Works Now* + *Last Verified*).

## Immediate Pending Work

All previously planned slices have shipped (see *What Works Now* and *Last
Verified*). Choose the next feature slice from current product gaps rather than
this stale list.

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

**Status: implemented** — every flow below has shipped (see the MediaStore notes
in *What Works Now*). The two non-✅ rows are intentional: the "live query
without index" walker is a kept low-priority fallback, and the Explorer
"Contains" counts were explicitly dropped.

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
| ✅ | Bundle static **pure-LGPL** FFmpeg in the app assets and use it for video+audio merging (`_ffmpeg_location`, `extractFfmpeg`); the LGPL-2.1 license text and build provenance ship with the asset, replacing a previous GPLv3 binary (2026-08-19). |
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

All planned features have shipped — see *What Works Now* and *Last Verified* for
the current status. No pending roadmap items remain.

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
