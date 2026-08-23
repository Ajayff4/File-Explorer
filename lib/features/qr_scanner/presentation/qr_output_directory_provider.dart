import 'package:file_explorer/shared/settings/output_directory/output_directory_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persisted folder where generated QR images are saved.
final qrGeneratorOutputDirectoryProvider =
    NotifierProvider<OutputDirectoryController, String>(
  () => OutputDirectoryController(
    'qr_generator.output_directory',
    defaultDirectory: '/storage/emulated/0/File Explorer/QR',
  ),
);
