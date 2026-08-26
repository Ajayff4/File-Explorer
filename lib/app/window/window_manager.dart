import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/shared/config/flavor_config.dart';
import 'package:file_explorer/app/theme/app_theme.dart';
import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_view_mode.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_factory_io.dart';
import 'package:file_explorer/features/search/data/repositories/search_index_store_provider.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  });

  final List<WindowSession> windows;
  final int activeIndex;
  final bool switcherVisible;

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
    );
  }

  Future<void> select(int index) async {
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
    );
  }

  void removeAt(int index) {
    if (state.windows.length <= 1) return;
    if (index < 0 || index >= state.windows.length) return;

    final windows = [...state.windows];
    final removed = windows.removeAt(index);
    removed.dispose();

    var active = state.activeIndex;
    if (index < active) {
      active--;
    } else if (index == active) {
      active = active >= windows.length ? windows.length - 1 : active;
    }

    state = WindowManagerState(
      windows: windows,
      activeIndex: active < 0 ? 0 : active,
      switcherVisible: state.switcherVisible,
    );
  }

  void removeActive() => removeAt(state.activeIndex);

  void openSwitcher() {
    captureActive();
    state = WindowManagerState(
      windows: state.windows,
      activeIndex: state.activeIndex,
      switcherVisible: true,
    );
  }

  void closeSwitcher() {
    state = WindowManagerState(
      windows: state.windows,
      activeIndex: state.activeIndex,
      switcherVisible: false,
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

class _WindowHostState extends ConsumerState<WindowHost> {
  @override
  void initState() {
    super.initState();
    final root = ProviderScope.containerOf(context, listen: false);
    ref.read(windowManagerProvider.notifier).initRoot(root);
    // Defer window creation until after the first frame so we don't modify
    // provider state while the widget tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(windowManagerProvider.notifier).ensureDefaultWindow();
    });
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
    return UncontrolledProviderScope(
      container: active.scope,
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
              RepaintBoundary(
                key: ref.read(windowManagerProvider.notifier).activeBoundaryKey,
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
/// of a captured thumbnail. Styled with the app's neumorphic (soft-UI) surfaces.
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
            child: NeumorphicCard(
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

                        return NeumorphicCard(
                          borderRadius: 24,
                          inset: isActive,
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
                  FloatingActionButton(
                    tooltip: 'New window',
                    onPressed: () {
                      ref.read(windowManagerProvider.notifier).addWindow(
                            startLocation: wm.active.currentLocation,
                          );
                      ref
                          .read(windowManagerProvider.notifier)
                          .closeSwitcher();
                    },
                    child: const Icon(Icons.add_rounded),
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
