import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/app/theme/app_theme.dart';
import 'package:file_explorer/features/media/presentation/controllers/media_store_scan_provider.dart';
import 'package:file_explorer/features/search/presentation/controllers/search_index_invalidation_provider.dart';
import 'package:file_explorer/features/search/presentation/controllers/search_index_prewarm_provider.dart';
import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileExplorerApp extends ConsumerWidget {
  const FileExplorerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(searchIndexInvalidationProvider);
    ref.watch(searchIndexPreWarmProvider);
    ref.watch(mediaStoreScanProvider);
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsControllerProvider).settings;

    return MaterialApp.router(
      title: 'File Explorer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.themeAccent),
      darkTheme: AppTheme.dark(settings.themeAccent),
      themeAnimationDuration: Duration.zero,
      themeMode: switch (settings.themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      routerConfig: router,
    );
  }
}
