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

- Responsive shell with mobile bottom navigation and wider-screen navigation rail.
- Home dashboard with storage summary, shortcuts, favorites, recents, and transfer station tile.
- Explorer screen with:
  - Android/local storage browsing where permissions allow it.
  - Storage root selector.
  - Breadcrumb.
  - Parent navigation.
  - Refresh.
  - List/grid view toggle.
  - Hidden-file filtering.
  - Folder-first sorting by name, modified date, size, and type.
  - Current-folder favorite toggle.
- Android storage foundation:
  - Storage permission state model.
  - Permission education/recovery card.
  - Android storage volume MethodChannel.
  - Android `StatFs` storage summary lookup.
  - Android all-files access status bridge.
- Transfers:
  - Copy, move, rename, and recursive delete queue.
  - Copy/move destination selection with `Paste here`.
  - Progress/status UI.
  - Retry, cancel, clear-finished flows.
  - Destination conflict policies: `Skip`, `Replace`, `Keep both`.
  - Drift-backed transfer queue/history persistence.
  - Interrupted running tasks restore as failed.
- Favorites:
  - Persisted favorite folders.
  - Home favorite list.
  - Explorer star action.
- Recents:
  - Persisted recent locations.
  - Folder/file history model.
  - Home recent section respects the folders-only setting.
- Search:
  - Search screen and route.
  - Current-folder vs storage-root scope.
  - File type filters.
  - Debounced searches.
  - Persisted search index.
  - Manual reindex.
  - Transfer-driven index invalidation.
- Settings:
  - Persisted settings store.
  - Typed `AppSettings`.
  - Settings screen groups Explorer, Transfers, and Search toggles.
  - Settings are wired into hidden files, delete confirmation, folders-only history, indexed search, and transfer station visibility.
- Branding:
  - Launcher icons generated for Android, iOS, web, Windows, and macOS from the provided logo.

## Last Verified

Recent successful checks:

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

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

1. Real Android device verification
   - Install the latest debug APK.
   - Confirm app icon appears correctly.
   - Confirm storage permission flow.
   - Confirm primary storage browsing.
   - Confirm copy, move, rename, delete on safe test folders.

2. Multi-select explorer workflow
   - Add selection mode to list/grid.
   - Add select-all/clear-selection.
   - Reuse the existing transfer queue for batch copy/move/delete.
   - Keep operation logic in transfer/controller layers, not UI widgets.

3. File properties polish
   - Expand properties bottom sheet with path, type, size, modified date, children count, and storage location.
   - Add shared formatting helpers if duplicated display logic appears.

4. Home dashboard cleanup
   - Replace fake shortcut counts with real category summaries or mark them clearly as placeholders in code.
   - Keep media/category scanning behind repository/controller boundaries.

5. Android permission hardening
   - Replace or supplement permission-handler all-files status with a dedicated Android platform service if deeper result handling is needed.
   - Add clearer recovery path when user denies all-files access.

6. UI polish from screenshots
   - Align spacing, density, and dashboard layout with reference screenshots.
   - Keep the visual style black/purple but avoid hard-coding one-off colors inside feature widgets.

## Later Roadmap

- Media libraries: images, videos, audio, documents, apps.
- Thumbnail cache.
- Storage analyzer.
- Recycle bin.
- Archive browsing/extract/compress.
- Network providers as optional future modules, not first-release core.
- Desktop readiness: context menus, keyboard shortcuts, adaptive split/dual-pane layout, drag and drop.

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
