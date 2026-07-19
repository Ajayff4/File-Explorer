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

### Verified

- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build web`

### Not Completed

- `flutter build apk --debug` was started as an extra native verification check, then intentionally stopped after the request to avoid running build commands without confirmation.

### Pending

- Finish Android debug build verification when approved.
- Accept local Android SDK licenses with `flutter doctor --android-licenses`.
- Replace permission-handler all-files check with a dedicated Android platform service if we need deeper settings/result handling.
- Verify real Android directory browsing on a device/emulator.
- Add storage root picker/list when multiple Android volumes are available.
- Add copy, move, rename, delete, and conflict handling.
- Add Drift database schema and generated code.
- Implement transfer engine.
- Continue UI polish using reference screenshots.
