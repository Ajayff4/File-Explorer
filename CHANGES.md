# Changes

Progress log for the Flutter application.

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
