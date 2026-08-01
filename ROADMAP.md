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
| ✅ | Explorer | List/grid view toggle. |
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
| ✅ | Favorites | Persisted favorite folders, Home list, and Explorer star action. |
| ✅ | Recents | Persisted recent folders/files and Home recent section setting support. |
| ✅ | Search | Search screen and route. |
| ✅ | Search | Current-folder vs storage-root scope. |
| ✅ | Search | File type filters and type-only discovery. |
| ✅ | Search | Debounced searches. |
| ✅ | Search | Persisted search index. |
| ✅ | Search | Manual reindex. |
| ✅ | Search | Transfer-driven index invalidation. |
| ✅ | Media | Flat libraries for images, videos, audio, documents, and apps. |
| ✅ | Media | Home media library entry points. |
| ✅ | Media | Media item taps open the parent folder with matching type filter. |
| ✅ | Media | Home category shortcuts open flattened folder groups for matching files. |
| ✅ | Media | Image/video category folders use three-column grid; other categories use four-column grid. |
| ✅ | Media | Date, size, type, and name sorting controls in media libraries. |
| ✅ | Media | Media/category scanning behind repository boundaries. |
| ✅ | Media | Native APK icon thumbnails for app files. |
| ✅ | Media | Image and video thumbnails in media/explorer rows with icon fallback. |
| ✅ | Viewers | In-app image viewer with pinch/double-tap zoom, rotate, swipe previous/next, details, delete, share placeholder, and Android wallpaper action. |
| ✅ | Players | In-app video player with auto-hiding controls, landscape mode, 10-second seeking, speed, loop, shuffle, previous/next, and details. |
| ✅ | Players | In-app audio player with seek, speed, volume, mute, loop, shuffle, previous/next, and details. |
| ✅ | Explorer | Compact four-column grid tiles with purple folder icons. |
| ✅ | Explorer | Long-press item actions instead of visible per-item overflow buttons. |
| ✅ | UI polish | Denser mobile list/card spacing and compact icon button taps. |
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
# passed
```

Local analyzer and Android debug build pass after the latest media viewer work.

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
| [ ] | 2 | Archives | Add ZIP extract and compress actions through Transfers. |
| [ ] | 3 | Tests | Update stale widget tests for current Home/media behavior. |
| [ ] | 4 | Viewers | Replace dummy image share/rename actions with real implementations. |
| [ ] | 5 | Open with | Unknown files use Android system open-with sheet. |

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
| [ ] | Add `Extract here` for `.zip` files. |
| [ ] | Add `Compress to ZIP` for selected files/folders. |
| [ ] | Queue archive operations through Transfers. |
| [ ] | Show archive progress in Transfers. |
| [ ] | Reuse transfer conflict policies: `Skip`, `Replace`, `Keep both`. |
| [ ] | Keep password ZIP, RAR, 7Z, and archive browsing for later. |

### Viewers And Players

| Status | Area | Task |
| --- | --- | --- |
| [x] | Image viewer | Open images fullscreen from Explorer and category folders. |
| [x] | Image viewer | Swipe next/previous within folder/category. |
| [x] | Image viewer | Pinch zoom and double-tap zoom. |
| [x] | Image viewer | Add delete/details actions. |
| [ ] | Image viewer | Replace share and rename placeholders with real actions. |
| [x] | Image viewer | Set image as Android wallpaper. |
| [x] | Video player | Open videos in-app. |
| [x] | Video player | Play/pause/seek/fullscreen controls. |
| [x] | Video player | Speed, loop, shuffle, previous/next, and auto-hide controls. |
| [x] | Audio player | Open audio in-app. |
| [x] | Audio player | Play/pause/seek controls. |
| [x] | Audio player | Add folder/category playlist controls. |
| [ ] | Open with | Unknown files use Android system open-with sheet. |

## Later Roadmap

| Status | Area | Task |
| --- | --- | --- |
| [ ] | Media | Thumbnail cache. |
| [ ] | Media | Tune category scan performance with progress and cancellation. |
| [ ] | Storage | Storage analyzer. |
| [ ] | Storage | Recycle bin. |
| [ ] | Archives | Archive browsing, extract, and compress. |
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
