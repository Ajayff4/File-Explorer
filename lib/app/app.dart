import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/app/theme/app_theme.dart';
import 'package:file_explorer/features/search/presentation/controllers/search_index_invalidation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileExplorerApp extends ConsumerWidget {
  const FileExplorerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(searchIndexInvalidationProvider);

    return MaterialApp.router(
      title: 'File Explorer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
