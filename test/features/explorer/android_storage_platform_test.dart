import 'package:file_explorer/features/explorer/data/platform/android_storage_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/storage');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps Android storage volumes from the platform channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getStorageVolumes') {
        return [
          {
            'id': 'primary',
            'label': 'Internal storage',
            'path': '/storage/emulated/0',
            'isPrimary': true,
            'totalBytes': 128,
            'freeBytes': 40,
            'usedBytes': 88,
          },
        ];
      }
      return null;
    });

    const platform = AndroidStoragePlatform(channel: channel);
    final volumes = await platform.getStorageVolumes();

    expect(volumes, hasLength(1));
    expect(volumes.single.isPrimary, isTrue);
    expect(volumes.single.path, '/storage/emulated/0');
    expect(volumes.single.summary?.usedBytes, 88);
  });
}
