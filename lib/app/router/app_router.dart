import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/selection_bottom_bar.dart';
import 'package:file_explorer/features/home/presentation/core_features_screen.dart';
import 'package:file_explorer/features/home/presentation/home_screen.dart';
import 'package:file_explorer/features/media/presentation/media_folder_screen.dart';
import 'package:file_explorer/features/media/presentation/media_library_screen.dart';
import 'package:file_explorer/features/media/presentation/media_viewer_screen.dart';
import 'package:file_explorer/features/search/presentation/search_screen.dart';
import 'package:file_explorer/features/settings/presentation/settings_screen.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.coreFeatures,
            builder: (context, state) => const CoreFeaturesScreen(),
          ),
          GoRoute(
            path: AppRoutes.explorer,
            builder: (context, state) => const ExplorerScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.mediaLibrary,
            builder: (context, state) => MediaLibraryScreen(
              kind: MediaLibraryKind.fromRouteSegment(
                state.pathParameters['kind'],
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.mediaFolder,
            builder: (context, state) {
              final extra = state.extra;
              final kind = MediaLibraryKind.fromRouteSegment(
                state.pathParameters['kind'],
              );
              final folderPath = extra is String
                  ? extra
                  : '/';
              return MediaFolderScreen(
                folderPath: folderPath,
                kind: kind,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.transfers,
            builder: (context, state) => const TransferManagerScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.mediaViewer,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is FileSystemEntry) {
            return MediaViewerScreen(entry: extra);
          }
          if (extra is MediaViewerSession) {
            return MediaViewerScreen(session: extra);
          }
          return const MissingMediaViewerScreen();
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const coreFeatures = '/features';
  static const explorer = '/explorer';
  static const search = '/search';
  static const mediaLibrary = '/media/:kind';
  static const mediaFolder = '/media/:kind/folder';
  static const mediaViewer = '/preview';
  static const transfers = '/transfers';
  static const settings = '/settings';

  static String media(MediaLibraryKind kind) {
    return '/media/${kind.routeSegment}';
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final selectedIndex = _selectedIndex(location);
    final explorerState = ref.watch(explorerControllerProvider);
    final isSelectionMode = explorerState.isSelectionMode;
    final selectedPaths = explorerState.selectedPaths.toList();

    if (width >= 840) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _go(context, ref, index),
              extended: width >= 1120,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.folder_copy_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder_rounded),
                  label: Text('Files'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sync_alt_outlined),
                  selectedIcon: Icon(Icons.sync_alt_rounded),
                  label: Text('Transfers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: isSelectionMode
          ? SelectionBottomBar(
              selectedPaths: selectedPaths,
              onExitSelection: () {
                ref.read(explorerControllerProvider.notifier).exitSelectionMode();
              },
            )
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _go(context, ref, index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder_rounded),
                  label: 'Files',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sync_alt_outlined),
                  selectedIcon: Icon(Icons.sync_alt_rounded),
                  label: 'Transfers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.explorer)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.search)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.mediaViewer)) {
      return 1;
    }
    if (location.startsWith('/media')) {
      return 1;
    }
    if (location.startsWith(AppRoutes.transfers)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.settings)) {
      return 3;
    }
    return 0;
  }

  void _go(BuildContext context, WidgetRef ref, int index) {
    if (index == 1) {
      ref.read(explorerViewModeProvider.notifier).state = ExplorerViewMode.grid;
    }

    final route = switch (index) {
      1 => AppRoutes.explorer,
      2 => AppRoutes.transfers,
      3 => AppRoutes.settings,
      _ => AppRoutes.home,
    };
    context.go(route);
  }
}
