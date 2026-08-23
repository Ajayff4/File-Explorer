# In-App Multi-Window — Design

Status: approved for implementation (MVP: switch-only window manager).

## Goal / scope

An in-app **window manager** where each "window" is an independent navigation
session: its own screen + back stack + view state. Only one window is visible at
a time; the user switches between them via a recents-style switcher. This matches
the roadmap wording ("multiple independent windows that can stay on any screen")
and the "current flow as an item in an array" mental model.

Out of scope for MVP:

- Live side-by-side split view.
- True OS multi-window (separate Android tasks / multiple Flutter engines) — not
  well supported by Flutter on mobile.

## Data model

```dart
class WindowSession {
  final String id;
  final GoRouter router;               // own navigation stack
  final ProviderContainer scope;       // own state (child of root)
  final List<Override> overrides;      // per-window controller overrides
  String label;                        // derived from active route
  String get currentLocation => router.routeInformationProvider.value.uri.path;
  void dispose() { router.dispose(); scope.dispose(); }
}

class WindowManagerState {
  final List<WindowSession> windows;
  final int activeIndex;
}

class WindowManager extends Notifier<WindowManagerState> {
  // addWindow / removeAt / select / removeActive / ensureDefaultWindow
}
```

- `windowManagerProvider` is a single global `Notifier` holding the window list
  and active index.
- Each `WindowSession` owns a `GoRouter` with a **unique root `navigatorKey`**
  and the shared route table (`buildAppRoutes()`), plus its own nested
  `ProviderContainer` (a child of the root container) with per-window overrides.

## Per-window state isolation

Root cause today: `main.dart` has one `ProviderScope` and controllers like
`explorerControllerProvider` are global singletons, so two Explorers share path
and selection.

Fix: every window is wrapped in its own nested `ProviderScope` (via
`ProviderScope(container: session.scope)`), overriding the navigation/view-state
controllers so each window gets fresh instances:

- **Per-window (overridden):** `explorerControllerProvider`,
  `explorerViewModeProvider`, `fileSearchControllerProvider`.
- **Stay global/shared:** `settingsControllerProvider` (theme/settings are
  app-wide), `transferControllerProvider`, `downloader*`, `recycleBin*`,
  `encryptor*`, `qrScanner*`, `favorites`, `recents`, search index. These are
  app services, not per-window location.

Overrides use the scoped container's `ref`:

```dart
explorerControllerProvider.overrideWith((ref) => ExplorerController(ref)..loadInitialDirectory()),
explorerViewModeProvider.overrideWith((ref) => ExplorerViewMode.grid),
fileSearchControllerProvider.overrideWith((ref) {
  final settings = ref.watch(settingsControllerProvider).settings;
  return FileSearchController(
    ref.read(storageRepositoryProvider),
    indexStore: settings.useIndexedSearch ? ref.read(searchIndexStoreProvider) : null,
    mediaStore: createMediaStorePlatform(),
    showHiddenFiles: settings.showHiddenFiles,
  );
}),
```

Scopes are created as children of the root container (captured once via
`ProviderScope.containerOf(context)` in `WindowHost.initState`) and are **not
disposed on window switch** — only when a window is closed. This keeps each
window's UI state (Explorer path, listings, selection) alive across switches.

## Rendering

`FileExplorerApp` becomes a thin `MaterialApp` wrapper around `WindowHost`:

```dart
class WindowHost extends ConsumerStatefulWidget {
  initState: capture root container -> windowManager.initRoot(root); ensureDefaultWindow();
  build:
    final active = windowManager.windows[activeIndex];
    return ProviderScope(
      container: active.scope,
      child: MaterialApp.router(
        theme / darkTheme / themeMode (from settings),
        routerConfig: active.router,
      ),
    );
}
```

Switching windows rebuilds `WindowHost`, swapping `active.scope` and
`active.router`. GoRouter state (current location) lives in the `GoRouter`
object (kept alive in the session), so the window restores its place when
re-selected. `AppShell` (bottom nav) navigates via `context.go`, which resolves
to the active window's `GoRouter` automatically.

## Switcher UI

- **New window** action (FAB inside the switcher): opens a fresh `WindowSession`
  (default Files). Cap at ~4–5 windows to bound resources.
- **Window switcher**: a recents-style modal (opened from the **Windows** nav
  destination) showing each window's label + current screen + a close (×)
  button; tap a card to switch, × to close. A FAB opens a new window at the
  current location.
- Labels are derived from each session's `currentLocation` (e.g.
  "Explorer · Download", "Home", "Transfers").

## Persistence (optional, phase 2)

MVP keeps windows in memory only. Later: persist minimal session info (count +
last location per window) via `shared_preferences`/Drift to restore on relaunch.

## Build phases

1. `WindowManager` Riverpod (add/remove/select, active index).
2. `WindowSession` factory: own `GoRouter` + `navigatorKey` + nested
   `ProviderScope` with overrides.
3. `WindowHost` rendering the active window's `MaterialApp.router`.
4. Per-window controller overrides (explorer / view-mode / search).
5. `AppShell` UI: New-window button + recents switcher overlay.
6. `flutter analyze` + device verification (two Explorers at different folders,
   switch, confirm independent state).

## Risks / notes

- Overriding global controllers per scope must cover every controller that holds
  view state; audit during phase 4 (media-library local providers share global
  sort/view state — acceptable minor limitation for MVP).
- Single Flutter engine → multiple navigators is cheap; no perf concern at 4
  windows.
- Settings/theme remain global (intended).
- Add a widget test asserting two windows show independent Explorer paths.
