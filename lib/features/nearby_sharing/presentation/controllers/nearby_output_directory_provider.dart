import 'package:file_explorer/shared/settings/output_directory/output_directory_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persisted folder where received (incoming) nearby files are saved.
final nearbyOutputDirectoryProvider =
    NotifierProvider<OutputDirectoryController, String>(
  () => OutputDirectoryController(
    'nearby.output_directory',
    defaultDirectory: '/storage/emulated/0/File Explorer/Share',
  ),
);
