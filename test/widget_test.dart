import 'package:file_explorer/app/app.dart';
import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/fake_storage_permission_repository.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
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
}
