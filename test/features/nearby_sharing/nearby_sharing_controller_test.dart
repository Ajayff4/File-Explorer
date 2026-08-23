import 'package:file_explorer/features/nearby_sharing/data/repositories/nearby_sharing_repository_fake.dart';
import 'package:file_explorer/features/nearby_sharing/data/repositories/nearby_sharing_repository_provider.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_peer.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_transfer_file.dart';
import 'package:file_explorer/features/nearby_sharing/presentation/controllers/nearby_sharing_controller.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/data/repositories/in_memory_transfer_task_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopExecutor implements TransferExecutor {
  @override
  Future<void> execute(
    TransferTask task, {
    required TransferProgressCallback onProgress,
  }) async {}
}

void main() {
  test('controller queues receive tasks and completes them from host events',
      () async {
    final fakeRepo = NearbySharingRepositoryFake();
    final container = ProviderContainer(
      overrides: [
        nearbySharingRepositoryProvider.overrideWithValue(fakeRepo),
        transferControllerProvider.overrideWith(
          (ref) => TransferController(
            _NoopExecutor(),
            InMemoryTransferTaskStore(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(nearbySharingControllerProvider.notifier);
    await ctrl.startHosting(destinationDir: '/tmp/nb');

    fakeRepo.simulateIncoming([
      NearbyIncomingFile(id: 'f1', name: 'a.txt', size: 10),
      NearbyIncomingFile(id: 'f2', name: 'b.txt', size: 20),
    ]);

    for (var i = 0; i < 50; i++) {
      final tasks = container.read(transferControllerProvider).tasks;
      if (tasks.length == 2 &&
          tasks.every((t) => t.status == TransferTaskStatus.completed)) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 20));
    }

    final tasks = container.read(transferControllerProvider).tasks;
    expect(tasks.length, 2);
    expect(tasks.every((t) => t.operation == TransferOperation.receive), isTrue);
    expect(
      tasks.every((t) => t.status == TransferTaskStatus.completed),
      isTrue,
    );
  });

  test('scanning surfaces discovered peers and then stops', () async {
    final fakeRepo = NearbySharingRepositoryFake(
      discoveredPeers: [
        NearbyPeer(
          id: 'p1',
          name: 'Peer',
          host: '127.0.0.1',
          tcpPort: 1234,
          code: '',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        nearbySharingRepositoryProvider.overrideWithValue(fakeRepo),
        transferControllerProvider.overrideWith(
          (ref) => TransferController(
            _NoopExecutor(),
            InMemoryTransferTaskStore(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(nearbySharingControllerProvider.notifier);
    ctrl.startScan();
    await Future.delayed(const Duration(milliseconds: 20));

    final scanningState = container.read(nearbySharingControllerProvider);
    expect(scanningState.scanning, isTrue);
    expect(scanningState.peers.any((p) => p.id == 'p1'), isTrue);

    ctrl.stopScan();
    await Future.delayed(const Duration(milliseconds: 20));
    expect(container.read(nearbySharingControllerProvider).scanning, isFalse);
  });
}
