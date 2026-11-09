import 'package:file_explorer/features/explorer/data/platform/shortcut_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Asks the launcher to pin [path] to the home screen and reports the outcome.
Future<void> pinShortcutToHomeScreen(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required bool isFolder,
  String? label,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final status = await ref.read(shortcutPlatformProvider).requestPin(
        path: path,
        label:
            label?.trim().isNotEmpty == true ? label!.trim() : p.basename(path),
        isFolder: isFolder,
      );

  final message = switch (status) {
    ShortcutPinStatus.pinned => 'Confirm the shortcut on your home screen',
    ShortcutPinStatus.alreadyPinned => 'Already pinned to the home screen',
    ShortcutPinStatus.unsupported =>
      'Home screen shortcuts require Android 8 or newer',
    ShortcutPinStatus.failed => 'Could not create the home screen shortcut',
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
