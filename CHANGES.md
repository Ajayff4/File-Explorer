# Changes

Progress log for the Flutter application.

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

### Verified

- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build web`

### Pending

- Implement Android storage permission flow.
- Replace Android fallback filesystem access with permission-aware native storage access.
- Add real directory browsing.
- Add copy, move, rename, delete, and conflict handling.
- Add Drift database schema and generated code.
- Implement transfer engine.
- Continue UI polish using reference screenshots.
