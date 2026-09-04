import 'package:file_explorer/app/app.dart';
import 'package:file_explorer/features/history_backup/data/history_backup_service.dart';
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
  runApp(const ProviderScope(child: FileExplorerApp()));
}

Future<void> _requestMediaPermissionsForTesting() async {
  await Permission.photos.request();
  await Permission.videos.request();
  await Permission.audio.request();
}
