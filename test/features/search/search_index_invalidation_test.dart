import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/search/data/repositories/in_memory_search_index_store.dart';
import 'package:file_explorer/features/search/data/repositories/search_index_store_provider.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/search/presentation/controllers/search_index_invalidation_provider.dart';
import 'package:file_explorer/features/transfers/data/repositories/fake_transfer_executor.dart';
import 'package:file_explorer/features/transfers/data/repositories/in_memory_transfer_task_store.dart';
import 'package:file_explorer/features/transfers/data/repositories/transfer_executor_provider.dart';
import 'package:file_explorer/features/transfers/data/repositories/transfer_task_store_provider.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed transfer clears overlapping search indexes', () async {
    final indexStore = InMemorySearchIndexStore();
    await indexStore.replaceIndex(
      rootPath: '/root',
      entries: [
        SearchResult(
          entry: FileSystemEntry(
            name: 'file.txt',
            path: '/root/file.txt',
            type: FileSystemEntryType.document,
            modifiedAt: DateTime(2026),
            sizeBytes: 42,
          ),
          parentPath: '/root',
          depth: 0,
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        searchIndexStoreProvider.overrideWithValue(indexStore),
        transferExecutorProvider
            .overrideWithValue(const FakeTransferExecutor()),
        transferTaskStoreProvider
            .overrideWithValue(InMemoryTransferTaskStore()),
      ],
    );
    addTearDown(container.dispose);

    container.read(searchIndexInvalidationProvider);
    container.read(transferControllerProvider.notifier).queueOperation(
          operation: TransferOperation.delete,
          sourcePaths: const ['/root/file.txt'],
          displayName: 'file.txt',
          totalBytes: 42,
        );
    await _pumpEventQueue();

    expect(await indexStore.hasIndex('/root'), isFalse);
  });
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
