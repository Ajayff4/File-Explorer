# Roadmap

Resume guide for the Flutter app.

## Current Snapshot

The app is an early but usable file-manager vertical slice.

- App/package ID: `com.ajayff4.fileexplorer`.
- Visible app name: `File Explorer`.
- Primary theme direction: black and purple.
- Source logo: `assets/brand/logo.png`.
- Architecture: feature-first Flutter modules with Riverpod controllers, GoRouter navigation, Drift persistence, and repository boundaries.
- Android is the primary target for real storage behavior.
- Web and unsupported platforms use fake/in-memory fallbacks where needed.

## What Works Now

| Status | Area | Task |
| --- | --- | --- |
| ✅ | Shell | Responsive mobile bottom navigation and wider-screen navigation rail. |
| ✅ | Home | Dashboard with storage summary, shortcuts, favorites, recents, and transfer station tile. |
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
| ✅ | Explorer | Properties sheet with type, size, bytes, modified date, item count, storage, parent folder, and full path. |
| ✅ | Android storage | Storage permission state model. |
| ✅ | Android storage | Permission education/recovery card. |
| ✅ | Android storage | Android storage volume MethodChannel. |
| ✅ | Android storage | Android `StatFs` storage summary lookup. |
| ✅ | Android storage | Android all-files access status bridge. |
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
| ✅ | Media | Image thumbnails in media library rows with icon fallback. |
| ✅ | Settings | Persisted settings store and typed `AppSettings`. |
| ✅ | Settings | Explorer, Transfers, and Search toggle groups wired into behavior. |
| ✅ | Branding | Launcher icons generated for Android, iOS, web, Windows, and macOS from the provided logo. |

## Last Verified

Current local check status:

```bash
git status --short
# dirty: roadmap + verification fixes

dart format lib test
# passed

flutter analyze
# passed

flutter test
# passed
```

Local verification has been restored after the latest type-filter browsing work.

The latest debug APK path, after running a build, is:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Resume Checklist

When coming back:

1. Check git status in `project/`.
2. Commit any completed slice if it is still uncommitted.
3. Run the normal local verification pass:

```bash
dart format lib test
flutter analyze
flutter test
```

4. If testing on phone, build and install:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Immediate Pending Work

Recommended next slices, in order:

| Status | Priority | Area | Task |
| --- | --- | --- | --- |
| [ ] | 1 | Android verification | Install latest debug APK. |
| [ ] | 1 | Android verification | Confirm app icon appears correctly. |
| [ ] | 1 | Android verification | Confirm storage permission flow. |
| [ ] | 1 | Android verification | Confirm primary storage browsing. |
| [ ] | 1 | Android verification | Confirm copy, move, rename, delete on safe test folders. |
| [ ] | 1 | Android verification | Check type-filter folder scan performance on large directory trees. |
| [ ] | 2 | Documentation | Remove stale "multi-select pending" wording from planning notes. |
| [ ] | 3 | Home | Mark fake shortcut counts clearly as sample-only for web/test builds. |
| [ ] | 3 | Home | Keep media/category scanning behind repository/controller boundaries. |
| [ ] | 4 | Media | Add native thumbnails for video and app library rows. |
| [ ] | 4 | Media | Add date/size/type sorting controls to media libraries. |
| [ ] | 5 | Android permissions | Replace or supplement permission-handler all-files status with a dedicated Android platform service if deeper result handling is needed. |
| [ ] | 5 | Android permissions | Add clearer recovery path when user denies all-files access. |
| [ ] | 6 | UI polish | Align spacing, density, and dashboard layout with reference screenshots. |
| [ ] | 6 | UI polish | Keep black/purple direction while avoiding hard-coded one-off feature colors. |

## Later Roadmap

| Status | Area | Task |
| --- | --- | --- |
| [ ] | Media | Thumbnail cache. |
| [ ] | Storage | Storage analyzer. |
| [ ] | Storage | Recycle bin. |
| [ ] | Archives | Archive browsing, extract, and compress. |
| [ ] | Network | Optional network providers, not first-release core. |
| [ ] | Desktop | Context menus, keyboard shortcuts, adaptive split/dual-pane layout, and drag and drop. |

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
