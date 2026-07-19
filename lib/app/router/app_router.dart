import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/home/presentation/home_screen.dart';
import 'package:file_explorer/features/settings/presentation/settings_screen.dart';
import 'package:file_explorer/features/transfers/presentation/transfer_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
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
          path: AppRoutes.explorer,
          builder: (context, state) => const ExplorerScreen(),
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
  ],
);

class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const explorer = '/explorer';
  static const transfers = '/transfers';
  static const settings = '/settings';
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final selectedIndex = _selectedIndex(location);

    if (width >= 840) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _go(context, index),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _go(context, index),
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
    if (location.startsWith(AppRoutes.transfers)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.settings)) {
      return 3;
    }
    return 0;
  }

  void _go(BuildContext context, int index) {
    final route = switch (index) {
      1 => AppRoutes.explorer,
      2 => AppRoutes.transfers,
      3 => AppRoutes.settings,
      _ => AppRoutes.home,
    };
    context.go(route);
  }
}
