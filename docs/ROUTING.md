# Routing

How navigation is structured after the back-button stabilization work
(2026-08-08), why it is split across two navigators, and the Android back
handling rules that must stay intact.

## Architecture

One `GoRouter` (v15.1.2) is built by the Riverpod provider
`appRouterProvider` and handed to `MaterialApp.router`:

```
lib/app/app.dart
  └─ MaterialApp.router(routerConfig: ref.watch(appRouterProvider))
       └─ Router (root / "outer" navigator, created by GoRouterDelegate)
            ├─ ShellRoute page           → AppShell (Scaffold + bottom nav)
            │    └─ Shell's OWN nested navigator
            │         ├─ HomeScreen            /
            │         ├─ CoreFeaturesScreen   /features          (pushed, not a tab)
            │         ├─ ExplorerScreen       /explorer
            │         ├─ SearchScreen         /search
            │         ├─ TransferManagerScreen /transfers
            │         ├─ SettingsScreen       /settings
            │         ├─ MediaLibraryScreen   /media/:kind
            │         └─ MediaFolderScreen    /media/:kind/folder (pushed)
            └─ MediaViewerScreen    /preview        (pushed on ROOT navigator)
            └─ TextFileViewerScreen /text-preview   (pushed on ROOT navigator)
```

### Two navigator levels

- **Root (outer) navigator** — the `Navigator` the `Router` widget builds. It
  holds the `ShellRoute` page plus any full-screen routes pushed imperatively
  on top of it (media/text viewer). A pushed viewer therefore covers the whole
  shell including the bottom navigation bar.
- **Shell (inner) navigator** — `ShellRoute` gives `AppShell` its own nested
  `Navigator` that keeps the bottom-nav tab state. `AppShell` decides the
  selected tab from `state.uri.path` (`_selectedIndex`), so the highlighted tab
  follows the URL even when a non-tab screen (search, media, viewers) is shown.

Because the viewer lives on the **root** navigator while folders live on the
**shell** navigator, popping them goes through different navigators. This is
exactly the combination that broke predictive back (see below).

## Route table

| Path | Screen | Kind segment(s) | Reached via | `extra` payload |
| --- | --- | --- | --- | --- |
| `/` | HomeScreen | — | initial, bottom nav | — |
| `/features` | CoreFeaturesScreen | — | `context.push` | — |
| `/explorer` | ExplorerScreen | — | bottom nav | — |
| `/search` | SearchScreen | — | search icon (Home/Explorer) | — |
| `/transfers` | TransferManagerScreen | — | bottom nav | — |
| `/settings` | SettingsScreen | — | bottom nav | — |
| `/media/:kind` | MediaLibraryScreen | `images` `videos` `audio` `documents` `apps` `archives` | `context.go(AppRoutes.media(kind))` from Home | — |
| `/media/:kind/folder` | MediaFolderScreen | same | `context.push(...)` from media library, `extra: path` | `String` folder path |
| `/preview` | MediaViewerScreen | — | `context.push` from folder/explorer/search/actions, `extra: MediaViewerSession` | `FileSystemEntry` or `MediaViewerSession` |
| `/text-preview` | TextFileViewerScreen | — | `context.push` for text files | `FileSystemEntry` |

Unknown `extra` on the viewer routes renders `MissingMediaViewerScreen`.

## Navigation patterns

- **`context.go(route)`** — top-level navigation that replaces the current
  match. Used for bottom-nav tabs, Home → media library, and "bail out to
  home/explorer" fallbacks in back handlers.
- **`context.push(route, extra: ...)`** — imperative push. `AppRoutes.coreFeatures`
  and `/media/:kind/folder` push onto the **shell** navigator; `/preview` and
  `/text-preview` push onto the **root** navigator. Pushing is what makes the
  route `canPop()`-able so back works without changing the URL.
- **`context.pop()`** — pops the current match; throws `GoError` if nothing can
  pop, so call sites guard with `context.canPop()`.

### Viewer back

The viewer screens have **no `BackButtonListener`**; their close buttons call
`Navigator.of(context).pop(...)` directly on the root navigator. go_router
observes that pop via `GoRouterDelegate._handlePopPageWithRouteMatch`, which
pops the imperative page and completes the match. Keep it that way — the
viewer must pop itself off the root navigator and never try to
`context.go(...)` its way out.

## Back button handling (the stabilized design)

Every "owned" screen root wraps its `Scaffold` in a `BackButtonListener` with
the same two rules:

1. **`isCurrent` guard first** — `if (ModalRoute.of(context)?.isCurrent != true)
   return false;`. A covered screen (media library under a folder, folder under
   a viewer) must *fall through* to the next listener instead of consuming the
   event. Without this, a single back press could pop two screens at once.
2. **Pop-first, then fall back** — `if (context.canPop()) { context.pop(); }
   else { context.go(<root>); }`. `ExplorerScreen` and `SearchScreen` add a
   selection-mode exit before the pop and a `openParentDirectory()` step for
   folder-up. `MediaFolderScreen` has **no listener**; a back press falls
   through to go_router's `popRoute` fallback, whose `maybePop` pops the
   folder off the shell navigator.

Listener priority: every `BackButtonListener` registers a child dispatcher on
the root `RootBackButtonDispatcher`; the most recently built one wins, and a
`false` return falls through to the next.

### The platform chain

Android back → `SystemChannels.navigation` `popRoute` →
`WidgetsBinding.handlePopRoute` → the root `BackButtonDispatcher`
(a `WidgetsBindingObserver`) → child `BackButtonListener`s → fallback to
`GoRouterDelegate.popRoute()` (which calls the top navigator's `maybePop` and
finally any `GoRoute.onExit`). If **no** listener handles it, the platform
default pops the Activity.

### Predictive back MUST stay disabled

`android/app/src/main/AndroidManifest.xml`:
`android:enableOnBackInvokedCallback="false"`.

This is the hard-won fix from 2026-08-08. With it set to `true` (the Flutter
default), predictive-back registers an `OnBackInvokedCallback`. After the
viewer (`/preview`, a root-navigator imperative push) is popped, that callback
is left in a broken state: the **next** system back press bypasses Flutter
entirely and the Activity default pops — the app minimizes from the folder
view instead of returning to the media library. Symptoms seen during
debugging: `WBSYS didPopRoute` fires for back #1 but never for back #2, with no
`BackButtonListener` logs at all.

Keeping predictive back off returns every back press to the classic
`onBackPressed → popRoute` path above, which is deterministic. If predictive
back is ever re-enabled, the viewer push/pop flow must be re-verified on an
API 33+ device before trusting it.

## Key files

| File | Role |
| --- | --- |
| `lib/app/router/app_router.dart` | `appRouterProvider`, `AppRoutes`, `AppShell` (nav rail / bottom nav + `_selectedIndex`). |
| `lib/app/app.dart` | `FileExplorerApp` — `MaterialApp.router` wired to the provider. |
| `lib/features/media/presentation/media_library_screen.dart` | `BackButtonListener` + `_openMediaFolder` (push) + `_openFolder` (push). |
| `lib/features/media/presentation/media_folder_screen.dart` | Folder grid; pushes `/preview`; no listener. |
| `lib/features/media/presentation/media_viewer_screen.dart` | Viewer; closes via `Navigator.of(context).pop()`. |
| `lib/features/explorer/presentation/explorer_screen.dart` | Listener with selection/folder-up logic; pushes `/preview` + `/text-preview`. |
| `lib/features/search/presentation/search_screen.dart` | Listener; pushes `/preview`. |
| `lib/features/home/presentation/core_features_screen.dart` | Listener (pop-first / go home). |
| `lib/features/explorer/presentation/widgets/entry_actions_button.dart` | Actions sheet pushes `/preview` / `/text-preview`. |
| `android/app/src/main/AndroidManifest.xml` | `enableOnBackInvokedCallback="false"` — mandatory. |
| `test/features/media/media_library_navigation_test.dart` | Regression tests: folder → media back, media → home back. |

## If back behavior regresses

Check in this order: (1) `enableOnBackInvokedCallback` still `false`;
(2) every new screen keeps the `isCurrent`-guard + pop-first listener;
(3) viewer routes still pop via `Navigator.pop`, not `context.go`.
