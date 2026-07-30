import 'package:file_explorer/app/app.dart';
import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/entry_actions_button.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/fake_storage_permission_repository.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('starts on the file manager dashboard', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageRepositoryProvider.overrideWithValue(
            const FakeStorageRepository(),
          ),
          storagePermissionRepositoryProvider.overrideWithValue(
            const FakeStoragePermissionRepository(),
          ),
        ],
        child: const FileExplorerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('File Explorer'), findsWidgets);
    expect(find.text('Internal storage'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
  });

  testWidgets('home category shortcut opens explorer with type filter',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWithValue(
          const FakeStorageRepository(),
        ),
        storagePermissionRepositoryProvider.overrideWithValue(
          const FakeStoragePermissionRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FileExplorerApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle();

    expect(
      container.read(explorerFilterTypeProvider),
      FileSystemEntryType.image,
    );
    expect(
      container.read(explorerControllerProvider).currentPath,
      FakeStorageRepository.rootPath,
    );
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('420 items'), findsOneWidget);
    expect(find.text('428 items'), findsNothing);
    expect(find.text('Downloads'), findsNothing);
  });

  testWidgets('properties sheet shows storage and location details',
      (tester) async {
    final entry = FileSystemEntry(
      name: 'photo.jpg',
      path: '${FakeStorageRepository.rootPath}/DCIM/photo.jpg',
      type: FileSystemEntryType.image,
      modifiedAt: DateTime(2026),
      sizeBytes: 2 * 1024 * 1024,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntryPropertiesPanel(
            entry: entry,
            storageVolume: const StorageVolume(
              id: 'primary',
              label: 'Internal storage',
              path: FakeStorageRepository.rootPath,
              isPrimary: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Internal storage'), findsOneWidget);
    expect(find.text('Storage root'), findsOneWidget);
    expect(find.text(FakeStorageRepository.rootPath), findsOneWidget);
    expect(find.text('Parent folder'), findsOneWidget);
    expect(find.text('${FakeStorageRepository.rootPath}/DCIM'), findsOneWidget);
    expect(find.text('Bytes'), findsOneWidget);
    expect(find.text('${entry.sizeBytes} bytes'), findsOneWidget);
  });
}
