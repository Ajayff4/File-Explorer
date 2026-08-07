import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_provider.dart';
import 'package:file_explorer/features/media/presentation/controllers/media_store_scan_provider.dart';
import 'package:file_explorer/features/transfers/data/repositories/fake_transfer_executor.dart';
import 'package:file_explorer/features/transfers/data/repositories/in_memory_transfer_task_store.dart';
import 'package:file_explorer/features/transfers/data/repositories/transfer_executor_provider.dart';
import 'package:file_explorer/features/transfers/data/repositories/transfer_task_store_provider.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/media_store_scan');
  const platform = MediaStorePlatform(channel: channel);

  test('completed transfer scans source and destination paths', () async {
    final scannedPaths = <List<String>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'scanFiles') {
        scannedPaths.add(
          (call.arguments['paths'] as List<Object?>).cast<String>(),
        );
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final container = ProviderContainer(
      overrides: [
        mediaStorePlatformProvider.overrideWithValue(platform),
        transferExecutorProvider
            .overrideWithValue(const FakeTransferExecutor()),
        transferTaskStoreProvider
            .overrideWithValue(InMemoryTransferTaskStore()),
      ],
    );
    addTearDown(container.dispose);

    container.read(mediaStoreScanProvider);
    container.read(transferControllerProvider.notifier).queueOperation(
          operation: TransferOperation.copy,
          sourcePaths: const ['/root/source.jpg'],
          displayName: 'source.jpg',
          destinationPath: '/root/dest.jpg',
          totalBytes: 42,
        );
    await _pumpEventQueue();

    expect(scannedPaths, isNotEmpty);
    final paths = scannedPaths.first.toSet();
    expect(paths, contains('/root/source.jpg'));
    expect(paths, contains('/root/dest.jpg'));
  });

  test('no scan runs when MediaStore is unavailable', () async {
    final scannedPaths = <List<String>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'scanFiles') {
        scannedPaths.add(
          (call.arguments['paths'] as List<Object?>).cast<String>(),
        );
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final container = ProviderContainer(
      overrides: [
        mediaStorePlatformProvider.overrideWithValue(null),
        transferExecutorProvider
            .overrideWithValue(const FakeTransferExecutor()),
        transferTaskStoreProvider
            .overrideWithValue(InMemoryTransferTaskStore()),
      ],
    );
    addTearDown(container.dispose);

    container.read(mediaStoreScanProvider);
    container.read(transferControllerProvider.notifier).queueOperation(
          operation: TransferOperation.copy,
          sourcePaths: const ['/root/source.jpg'],
          displayName: 'source.jpg',
          destinationPath: '/root/dest.jpg',
          totalBytes: 42,
        );
    await _pumpEventQueue();

    expect(scannedPaths, isEmpty);
  });
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
