import 'package:file_explorer/app/window/window_manager.dart';
import 'package:file_explorer/features/media/presentation/controllers/media_store_scan_provider.dart';
import 'package:file_explorer/features/search/presentation/controllers/search_index_invalidation_provider.dart';
import 'package:file_explorer/features/search/presentation/controllers/search_index_prewarm_provider.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileExplorerApp extends ConsumerWidget {
  const FileExplorerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the background side-effect providers alive.
    ref.watch(searchIndexInvalidationProvider);
    ref.watch(searchIndexPreWarmProvider);
    ref.watch(mediaStoreScanProvider);
    ref.watch(settingsControllerProvider);

    return const WindowHost();
  }
}
