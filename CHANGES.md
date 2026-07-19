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

### Verified

- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build web`
- `flutter build apk --debug` (confirmed locally by user)

### Pending

- Replace permission-handler all-files check with a dedicated Android platform service if we need deeper settings/result handling.
- Verify real Android directory browsing on a device/emulator.
- Add destination picker and paste workflow for copy/move.
- Add conflict handling UI and policies.
- Add Drift database schema and generated code.
- Persist transfer queue and transfer history.
- Continue UI polish using reference screenshots.
