import 'package:file_explorer/app/app.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/history_backup/data/history_backup_service.dart';
import 'package:file_explorer/features/settings/data/repositories/settings_store_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore history snapshots from File Explorer/.history before any database
  // is opened. Never overwrites local data; a no-op without prior backups.
  await restoreHistoryBackup();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  if (kDebugMode) {
    await _requestMediaPermissionsForTesting();
  }
  final homeFolderPath = await _loadHomeFolderPath();
  runApp(
    ProviderScope(
      overrides: [
        explorerStartPathProvider.overrideWithValue(homeFolderPath),
      ],
      child: const FileExplorerApp(),
    ),
  );
}

/// Reads the persisted start folder before the first window is created so
/// Explorer can open it directly instead of flashing the storage root.
Future<String?> _loadHomeFolderPath() async {
  final bootstrap = ProviderContainer();
  try {
    final settings = await bootstrap.read(settingsStoreProvider).loadSettings();
    return settings.homeFolderPath;
  } catch (_) {
    return null;
  } finally {
    bootstrap.dispose();
  }
}

Future<void> _requestMediaPermissionsForTesting() async {
  await Permission.photos.request();
  await Permission.videos.request();
  await Permission.audio.request();
}
