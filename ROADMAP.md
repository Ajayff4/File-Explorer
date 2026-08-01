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
| ✅ | Explorer | File type browsing from Home shortcuts with filtered folder counts. |
| ✅ | Explorer | Properties sheet with type, MIME Type, size, bytes, modified date, item count, storage, and full path. |
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
| ✅ | Favorites | Persisted favorite folders, Home list, and Explorer star action. |
| ✅ | Recents | Persisted recent folders/files and Home recent section setting support. |
| ✅ | Search | Search screen and route. |
| ✅ | Search | Current-folder vs storage-root scope. |
| ✅ | Search | File type filters and type-only discovery. |
| ✅ | Search | Debounced searches. |
| ✅ | Search | Persisted search index. |
| ✅ | Search | Manual reindex. |
| ✅ | Search | Transfer-driven index invalidation. |
| ✅ | Search | File result taps open previews, with a visible `Open folder` action for containing-folder navigation. |
| ✅ | Search | Search results reuse media thumbnails for images, videos, and apps. |
| ✅ | Search | Search results render as grid tiles by default. |
| ✅ | Media | Flat libraries for images, videos, audio, documents, and apps. |
| ✅ | Media | Home media library entry points. |
| ✅ | Media | Media item taps open the parent folder with matching type filter. |
| ✅ | Media | Home category shortcuts open flattened folder groups for matching files. |
| ✅ | Media | Image/video category folders use three-column grid; other categories use four-column grid. |
| ✅ | Media | Date, size, type, and name sorting controls in media libraries. |
| ✅ | Media | Media/category scanning behind repository boundaries. |
| ✅ | Media | Native APK icon thumbnails for app files. |
| ✅ | Media | Image and video thumbnails in media/explorer rows with icon fallback. |
| ✅ | Viewers | In-app image viewer with pinch/double-tap zoom, rotate, swipe previous/next, details, delete, Android share, transfer-backed rename, and Android wallpaper action. |
| ✅ | Viewers | Unknown files can launch Android's system open-with sheet. |
| ✅ | Players | In-app video player with auto-hiding controls, landscape mode, 10-second seeking, speed, loop, shuffle, previous/next, and details. |
| ✅ | Players | In-app audio player with seek, speed, volume, mute, loop, shuffle, previous/next, and details. |
| ✅ | Explorer | Compact four-column grid tiles with purple folder icons. |
| ✅ | Explorer | Long-press opens item actions with Select, Share, Open with, transfer actions, and Properties. |
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
# dirty: media viewers/players + feature page

dart format lib
# passed

flutter analyze
# passed

flutter test
# currently has stale widget expectations around Home/media behavior

flutter build apk --debug
# passed after native media action changes; not rerun for the latest Dart-only menu timing/padding fix by request
```

Local analyzer passes after the latest ZIP/TAR/GZ/TAR.GZ archive transfer workflow, Search open-file/open-folder behavior, and media viewer rename-dialog lifecycle, timing, and menu-density fixes. Android debug build is only necessary after native, Gradle, manifest, platform-channel, dependency, or asset changes.

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
| [ ] | 1 | Media | Add category result cache with instant cached render and silent background refresh. |
| [x] | 2 | Archives | Add ZIP extract and compress actions through Transfers. |
| [ ] | 3 | Tests | Update stale widget tests for current Home/media behavior. |
| [x] | 4 | Viewers | Replace dummy image share/rename actions with real implementations. |
| [x] | 5 | Open with | Unknown files use Android system open-with sheet. |

## Must-Have Feature Plan

### Category Cache

Goal: category shortcuts should feel instant after the first scan.

| Status | Task |
| --- | --- |
| [ ] | Persist category scan results by `rootPath + FileSystemEntryType`. |
| [ ] | Store file path, parent folder, name, type, size, and modified time. |
| [ ] | Show cached category folders immediately when cache exists. |
| [ ] | Refresh cache silently in the background after cached results render. |
| [ ] | If refreshed result matches cache, keep UI unchanged. |
| [ ] | If refreshed result differs, update cache and refresh visible results. |
| [ ] | Mark related category caches stale when transfer tasks complete under the same root. |
| [ ] | Show full-screen loading only when no cache exists. |
| [ ] | Show small header refresh state when background scan is active. |
| [ ] | Allow user to leave/back out while scan continues or cancels safely. |

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
| [ ] | Add archive browsing. |
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
| [ ] | Media | Tune category scan performance with progress and cancellation. |
| [ ] | Storage | Storage analyzer. |
| [ ] | Storage | Recycle bin. |
| [ ] | Archives | Archive browsing, RAR, and 7Z support. |
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
