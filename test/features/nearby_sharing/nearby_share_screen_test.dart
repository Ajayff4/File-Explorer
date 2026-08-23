import 'package:file_explorer/features/nearby_sharing/data/repositories/nearby_sharing_repository_fake.dart';
import 'package:file_explorer/features/nearby_sharing/data/repositories/nearby_sharing_repository_provider.dart';
import 'package:file_explorer/features/nearby_sharing/presentation/nearby_share_screen.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/domain/repositories/transfer_executor.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/features/transfers/data/repositories/in_memory_transfer_task_store.dart';
import 'package:flutter/material.dart';
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
  testWidgets('nearby share screen renders and scan toggles without crashing',
      (tester) async {
    final fakeRepo = NearbySharingRepositoryFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbySharingRepositoryProvider.overrideWithValue(fakeRepo),
          transferControllerProvider.overrideWith(
            (ref) => TransferController(
              _NoopExecutor(),
              InMemoryTransferTaskStore(),
            ),
          ),
        ],
        child: MaterialApp(
          home: const NearbyShareScreen(
            initialPaths: ['/storage/emulated/0/Download/x.txt'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nearby Share'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan for devices'));
    await tester.pumpAndSettle();
    expect(find.text('Stop scanning'), findsOneWidget);

    await tester.tap(find.text('Stop scanning'));
    await tester.pumpAndSettle();
    expect(find.text('Scan for devices'), findsOneWidget);
  });
}
