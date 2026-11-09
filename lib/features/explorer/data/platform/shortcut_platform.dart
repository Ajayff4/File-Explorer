import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShortcutPinStatus { pinned, alreadyPinned, unsupported, failed }

/// Pins files/folders to the Android home screen via the native
/// `ShortcutManager` channel. Non-Android platforms report [unsupported].
class ShortcutPlatform {
  const ShortcutPlatform({
    MethodChannel channel = const MethodChannel(
      'com.ajayff4.fileexplorer/shortcuts',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<ShortcutPinStatus> requestPin({
    required String path,
    required String label,
    required bool isFolder,
  }) async {
    try {
      final status = await _channel.invokeMethod<String>('requestPin', {
        'path': path,
        'label': label,
        'isFolder': isFolder,
      });
      return switch (status) {
        'pinned' => ShortcutPinStatus.pinned,
        'already_pinned' => ShortcutPinStatus.alreadyPinned,
        'unsupported' => ShortcutPinStatus.unsupported,
        _ => ShortcutPinStatus.failed,
      };
    } on MissingPluginException {
      return ShortcutPinStatus.unsupported;
    } on PlatformException {
      return ShortcutPinStatus.failed;
    }
  }
}

final shortcutPlatformProvider = Provider<ShortcutPlatform>((ref) {
  return const ShortcutPlatform();
});
