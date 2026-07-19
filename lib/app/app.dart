import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class EsFileExplorerApp extends StatelessWidget {
  const EsFileExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
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
