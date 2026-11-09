import 'package:file_explorer/features/explorer/data/platform/shortcut_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/shortcuts');
  const platform = ShortcutPlatform(channel: channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps native pin results to statuses', () async {
    final statuses = <String, ShortcutPinStatus>{
      'pinned': ShortcutPinStatus.pinned,
      'already_pinned': ShortcutPinStatus.alreadyPinned,
      'unsupported': ShortcutPinStatus.unsupported,
      'failed': ShortcutPinStatus.failed,
    };

    for (final entry in statuses.entries) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'requestPin');
        expect(call.arguments, {
          'path': '/storage/emulated/0/Download',
          'label': 'Download',
          'isFolder': true,
        });
        return entry.key;
      });

      final status = await platform.requestPin(
        path: '/storage/emulated/0/Download',
        label: 'Download',
        isFolder: true,
      );
      expect(status, entry.value);
    }
  });

  test('reports unsupported when the native channel is missing', () async {
    expect(await platform.isSupported(), isFalse);
    expect(
      await platform.requestPin(path: '/tmp', label: 'tmp', isFolder: true),
      ShortcutPinStatus.unsupported,
    );
  });

  test('reads native pin support flag', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isSupported') return true;
      return null;
    });

    expect(await platform.isSupported(), isTrue);
  });
}
