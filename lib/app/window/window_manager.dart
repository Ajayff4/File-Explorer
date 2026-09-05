import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/shared/config/flavor_config.dart';
import 'package:file_explorer/app/theme/app_theme.dart';
import 'package:file_explorer/app/theme/glass.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/history_backup/presentation/history_backup_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_view_mode.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_factory_io.dart';
import 'package:file_explorer/features/search/data/repositories/search_index_store_provider.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/features/sharing/incoming_intent_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';

/// Maximum number of concurrent windows.
const int _maxWindows = 5;

/// A single independent navigation session.
///
/// Each window owns its own [GoRouter] (its own back stack) and its own
/// [ProviderContainer] (a child of the root container) with per-window
/// overrides, so view state such as the Explorer path/selection is isolated.
class WindowSession {
  WindowSession({
    required this.id,
    required this.router,
    required this.scope,
    required this.overrides,
    this.thumbnail,
    this.label = 'Window',
  });

  final String id;
  final GoRouter router;
  final ProviderContainer scope;
  final List<Override> overrides;
  Uint8List? thumbnail;
  String label;

  String get currentLocation =>
      router.routeInformationProvider.value.uri.path;

  void dispose() {
    router.dispose();
    scope.dispose();
  }
}

class WindowManagerState {
  const WindowManagerState({
    required this.windows,
    required this.activeIndex,
    this.switcherVisible = false,
    this.swapDirection = 0,
  });

  final List<WindowSession> windows;
  final int activeIndex;
  final bool switcherVisible;

  /// Slide direction for the active-window swap animation:
  /// +1 = new window enters from the right (forward/next),
  /// -1 = new window enters from the left (backward/prev),
  /// 0 = no slide (initial or same-window rebuild).
  final int swapDirection;

  WindowSession get active => windows[activeIndex];
}

class WindowManager extends Notifier<WindowManagerState> {
  ProviderContainer? _root;
  int _counter = 0;

  /// Key for the [RepaintBoundary] that wraps the active window, used to
  /// capture a thumbnail of each window when it is switched away. The window
  /// switcher overlay lives OUTSIDE this boundary so it is never captured.
  final activeBoundaryKey = GlobalKey();

  void initRoot(ProviderContainer root) => _root ??= root;

  void ensureDefaultWindow() {
    if (state.windows.isEmpty) {
      addWindow(startLocation: AppRoutes.home);
    }
  }

  /// Captures a PNG snapshot of the currently active window and stores it on
  /// the corresponding [WindowSession] so the switcher can show a thumbnail.
  Future<void> captureActive() async {
    final ctx = activeBoundaryKey.currentContext;
    if (ctx == null) return;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    try {
      final image = await renderObject.toImage(pixelRatio: 0.75);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      state.windows[state.activeIndex].thumbnail = bytes.buffer.asUint8List();
      // Notify listeners so the switcher refreshes with the new thumbnail.
      state = WindowManagerState(
        windows: state.windows,
        activeIndex: state.activeIndex,
        switcherVisible: state.switcherVisible,
        swapDirection: state.swapDirection,
      );
    } catch (_) {
      // Ignore capture failures (e.g. not yet laid out).
    }
  }

  Future<void> addWindow({String? startLocation}) async {
    final root = _root;
    if (root == null) return;
    if (state.windows.length >= _maxWindows) return;

    // Snapshot the window we are leaving so its thumbnail is preserved.
    if (state.windows.isNotEmpty) {
      await captureActive();
    }

    final overrides = <Override>[
      explorerControllerProvider
          .overrideWith((ref) => ExplorerController(ref)..loadInitialDirectory()),
      explorerViewModeProvider.overrideWith((ref) => ExplorerViewMode.grid),
      fileSearchControllerProvider.overrideWith((ref) {
        final settings = ref.watch(settingsControllerProvider).settings;
        return FileSearchController(
          ref.read(storageRepositoryProvider),
          indexStore: settings.useIndexedSearch
              ? ref.read(searchIndexStoreProvider)
              : null,
          mediaStore: createMediaStorePlatform(),
          showHiddenFiles: settings.showHiddenFiles,
        );
      }),
    ];

    final scope = ProviderContainer(parent: root, overrides: overrides);
    final router = GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      initialLocation: startLocation ?? AppRoutes.explorer,
      routes: buildAppRoutes(),
      redirect: appRouteRedirect,
    );

    _counter++;
    final session = WindowSession(
      id: 'w$_counter',
      router: router,
      scope: scope,
      overrides: overrides,
      thumbnail: null,
      label: 'Window $_counter',
    );

    state = WindowManagerState(
      windows: [...state.windows, session],
      activeIndex: state.windows.length,
      switcherVisible: state.switcherVisible,
      // New window always appends at the end -> enters from the right,
      // except the very first window which should not slide.
      swapDirection: state.windows.isEmpty ? 0 : 1,
    );
  }

  Future<void> select(int index, {int? direction}) async {
    if (index < 0 || index >= state.windows.length) return;
    if (index == state.activeIndex) {
      closeSwitcher();
      return;
    }

    // Snapshot the window we are leaving.
    await captureActive();
    state = WindowManagerState(
      windows: state.windows,
      activeIndex: index,
      switcherVisible: state.switcherVisible,
      // Explicit direction wins (e.g. cyclic swipe from last -> first is
      // still forward). Otherwise infer from index movement.
      swapDirection:
          direction ?? (index > state.activeIndex ? 1 : -1),
    );
  }

  void removeAt(int index) {
    if (state.windows.length <= 1) return;
    if (index < 0 || index >= state.windows.length) return;

    final windows = [...state.windows];
    final removed = windows.removeAt(index);
    removed.dispose();

    var active = state.activeIndex;
    var direction = 0;
    if (index < active) {
      active--;
      // Same logical window stays active, only its index shifted -> no slide.
      direction = 0;
    } else if (index == active) {
      final newLength = windows.length;
      active = active >= newLength ? newLength - 1 : active;
      // Active window identity changed: removed last -> slide from left,
      // otherwise the next window slides in from the right.
      direction = index >= newLength ? -1 : 1;
    }

    state = WindowManagerState(
      windows: windows,
      activeIndex: active < 0 ? 0 : active,
      switcherVisible: state.switcherVisible,
      swapDirection: direction,
    );
  }

  void removeActive() => removeAt(state.activeIndex);

  void openSwitcher() {
    captureActive();
    state = WindowManagerState(
      windows: state.windows,
      activeIndex: state.activeIndex,
      switcherVisible: true,
      swapDirection: state.swapDirection,
    );
  }

  void closeSwitcher() {
    state = WindowManagerState(
      windows: state.windows,
      activeIndex: state.activeIndex,
      switcherVisible: false,
      swapDirection: state.swapDirection,
    );
  }

  @override
  WindowManagerState build() {
    return const WindowManagerState(
      windows: [],
      activeIndex: 0,
      switcherVisible: false,
    );
  }
}

final windowManagerProvider =
    NotifierProvider<WindowManager, WindowManagerState>(WindowManager.new);

/// Hosts the active window: wraps it in its own [ProviderContainer] and renders
/// it through a [MaterialApp.router] driven by the window's [GoRouter]. The
/// window content is wrapped in a [RepaintBoundary] (so its thumbnail can be
/// captured) while the window switcher is rendered as a sibling overlay OUTSIDE
/// that boundary, ensuring the switcher UI itself is never captured.
class WindowHost extends ConsumerStatefulWidget {
  const WindowHost({super.key});

  @override
  ConsumerState<WindowHost> createState() => _WindowHostState();
}

class _WindowHostState extends ConsumerState<WindowHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final root = ProviderScope.containerOf(context, listen: false);
    ref.read(windowManagerProvider.notifier).initRoot(root);
    // Defer window creation until after the first frame so we don't modify
    // provider state while the widget tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(windowManagerProvider.notifier).ensureDefaultWindow();
      // Refresh the history snapshot once data has had a chance to load.
      ref.read(historyBackupControllerProvider.notifier).exportIfDue();
      // Offer a post-permission restore: the pre-startup import cannot read
      // the backup folder until storage access is granted, which typically
      // happens after the first launch.
      unawaited(_maybeOfferRestore());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back up before the app can be killed or uninstalled.
    if (state == AppLifecycleState.hidden) {
      ref.read(historyBackupControllerProvider.notifier).exportIfDue();
    }
    // Re-check on return: storage permission (and therefore backup
    // readability) is typically granted mid-session via the permission card.
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeOfferRestore());
    }
  }

  bool _restorePromptVisible = false;

  /// Shows the restore prompt when this install holds no real history but a
  /// usable snapshot exists. Restoring replaces the open databases on disk,
  /// so the app closes afterwards and the user simply reopens it.
  Future<void> _maybeOfferRestore() async {
    if (_restorePromptVisible) return;
    final controller = ref.read(historyBackupControllerProvider.notifier);
    if (!await controller.checkPendingRestore()) return;
    if (!mounted) return;
    _restorePromptVisible = true;
    try {
      final restore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore history?'),
          content: const Text(
            'A history backup from a previous install was found in '
            'File Explorer/.history. Restore it now? The app will close — '
            'just reopen it to continue with your restored history.',
          ),
          actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          GlowButton(
            label: 'Restore',
            height: 46,
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          ],
        ),
      );
      if (!mounted) return;
      if (restore == true) {
        final ok = await controller.restoreNow();
        if (!mounted) return;
        if (ok) {
          SystemNavigator.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restore failed — starting fresh')),
          );
        }
      } else {
        await controller.dismissRestore();
      }
    } finally {
      _restorePromptVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wm = ref.watch(windowManagerProvider);
    final settings = ref.watch(settingsControllerProvider).settings;

    if (wm.windows.isEmpty) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final active = wm.active;
    final activeIdKey = ValueKey(active.id);
    final direction = wm.swapDirection.clamp(-1, 1);
    return IncomingIntentHandler(
      router: active.router,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(settings.themeAccent),
        darkTheme: AppTheme.dark(settings.themeAccent),
        themeMode: switch (settings.themeMode) {
          AppThemeMode.system => ThemeMode.system,
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
        },
        home: PopScope(
          canPop: !wm.switcherVisible,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && wm.switcherVisible) {
              ref.read(windowManagerProvider.notifier).closeSwitcher();
            }
          },
child: Stack(
                children: [
                  _SwipeEdgeFeedback(
                    windowsCount: wm.windows.length,
                    activeIndex: wm.activeIndex,
                    child: RepaintBoundary(
                      key: ref.read(windowManagerProvider.notifier).activeBoundaryKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        reverseDuration: const Duration(milliseconds: 280),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.hardEdge,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, animation) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                            reverseCurve: Curves.easeOutCubic,
                          );
                          // No directional cue (first window, same-window
                          // rebuild) -> simple fade.
                          if (direction == 0) {
                            return FadeTransition(
                              opacity: curved,
                              child: child,
                            );
                          }
                          final isIncoming = child.key == activeIdKey;
                          // Incoming runs 0->1: off-screen (direction side)
                          // -> center. Outgoing runs 1->0, so its tween is
                          // mirrored (center -> opposite side).
                          final begin = isIncoming
                              ? Offset(direction.toDouble(), 0)
                              : Offset(-direction.toDouble(), 0);
                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: curved.drive(Tween(
                                begin: begin,
                                end: Offset.zero,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: activeIdKey,
                          child: UncontrolledProviderScope(
                            container: active.scope,
                            child: MaterialApp.router(
                              title: 'File Explorer',
                              debugShowCheckedModeBanner: false,
                              theme: AppTheme.light(settings.themeAccent),
                              darkTheme: AppTheme.dark(settings.themeAccent),
                              themeMode: switch (settings.themeMode) {
                                AppThemeMode.system => ThemeMode.system,
                                AppThemeMode.light => ThemeMode.light,
                                AppThemeMode.dark => ThemeMode.dark,
                              },
                              routerConfig: active.router,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (wm.switcherVisible) const WindowSwitcher(),
                ],
              ),
        ),
      ),
    );
  }
}

IconData iconForLocation(String path) {
  if (path.startsWith(AppRoutes.explorer)) return Icons.folder_outlined;
  if (path.startsWith(AppRoutes.search)) return Icons.search;
  if (path.startsWith('/media')) return Icons.photo_library_outlined;
  if (path.startsWith(AppRoutes.transfers)) return Icons.swap_horiz_rounded;
  if (path.startsWith(AppRoutes.settings)) return Icons.settings;
  if (enableDownloader && path.startsWith('/downloader')) {
    return Icons.download_rounded;
  }
  if (path.startsWith(AppRoutes.analyzer)) return Icons.pie_chart_rounded;
  if (path.startsWith(AppRoutes.recycleBin)) return Icons.delete_outline;
  if (path.startsWith(AppRoutes.encryptor)) return Icons.lock_outline;
  if (path.startsWith(AppRoutes.qrScanner)) return Icons.qr_code_scanner;
  if (path.startsWith(AppRoutes.coreFeatures)) return Icons.grid_view_rounded;
  return Icons.home_rounded;
}



/// Thumbnail-based overlay for switching between windows. Rendered as a sibling
/// of the captured window (outside the [RepaintBoundary]) so it is never part
/// of a captured thumbnail. Styled with the app's frosted glass surfaces.
class WindowSwitcher extends ConsumerWidget {
  const WindowSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wm = ref.watch(windowManagerProvider);
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 700 ? 3 : 2;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () =>
                ref.read(windowManagerProvider.notifier).closeSwitcher(),
            child: Container(color: Colors.black54),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: GlassCard(
              borderRadius: 30,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => ref
                          .read(windowManagerProvider.notifier)
                          .closeSwitcher(),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.56,
                      ),
                      itemCount: wm.windows.length,
                      itemBuilder: (context, index) {
                        final window = wm.windows[index];
                        final isActive = index == wm.activeIndex;
                        final icon = iconForLocation(window.currentLocation);

                        return GlassTile(
                          borderRadius: 24,
                          selected: isActive,
                          padding: EdgeInsets.zero,
                          margin: EdgeInsets.zero,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      ref
                                          .read(windowManagerProvider
                                              .notifier)
                                          .select(index);
                                      ref
                                          .read(windowManagerProvider
                                              .notifier)
                                          .closeSwitcher();
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: window.thumbnail != null
                                          ? Image.memory(window.thumbnail!,
                                              fit: BoxFit.cover)
                                          : Container(
                                              color: scheme
                                                  .surfaceContainerHighest,
                                              child: Center(
                                                  child:
                                                      Icon(icon, size: 52)),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isActive)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: scheme.primary,
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                ),
                              if (wm.windows.length > 1)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Material(
                                    color: Colors.black54,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: () => ref
                                          .read(windowManagerProvider
                                              .notifier)
                                          .removeAt(index),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.close,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlowButton(
                    icon: Icons.add_rounded,
                    label: 'New window',
                    onPressed: () {
                      ref.read(windowManagerProvider.notifier).addWindow(
                            startLocation: wm.active.currentLocation,
                          );
                      ref
                          .read(windowManagerProvider.notifier)
                          .closeSwitcher();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A widget that handles horizontal swipe gestures for cyclic tab navigation.
/// Swiping left on the first tab goes to the last tab, and swiping right on
/// the last tab goes to the first tab.
class _SwipeEdgeFeedback extends ConsumerWidget {
  const _SwipeEdgeFeedback({
    required this.windowsCount,
    required this.activeIndex,
    required this.child,
  });

  final int windowsCount;
  final int activeIndex;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (windowsCount <= 1) return child;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 300) {
          // Swipe right (drag left to right) -> previous tab, cyclic.
          // Explicit -1 so wrapping first -> last still slides from the left.
          final prevIndex = (activeIndex - 1 + windowsCount) % windowsCount;
          ref
              .read(windowManagerProvider.notifier)
              .select(prevIndex, direction: -1);
        } else if (velocity < -300) {
          // Swipe left (drag right to left) -> next tab, cyclic.
          // Explicit +1 so wrapping last -> first still slides from the right.
          final nextIndex = (activeIndex + 1) % windowsCount;
          ref
              .read(windowManagerProvider.notifier)
              .select(nextIndex, direction: 1);
        }
      },
child: child,
    );
  }
}
