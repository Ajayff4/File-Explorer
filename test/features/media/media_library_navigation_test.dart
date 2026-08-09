import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_provider.dart';
import 'package:file_explorer/features/media/presentation/media_folder_screen.dart';
import 'package:file_explorer/features/media/presentation/media_library_screen.dart';
import 'package:file_explorer/features/recents/data/repositories/in_memory_recent_location_store.dart';
import 'package:file_explorer/features/recents/data/repositories/recent_location_store_provider.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/fake_storage_permission_repository.dart';
import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_provider.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/media_library_back');
  const platform = MediaStorePlatform(channel: channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  List<Map<String, Object?>> queryFilesItems() => [
        {
          'path': '/storage/emulated/0/Download/report.pdf',
          'name': 'report.pdf',
          'sizeBytes': 100,
          'modifiedAtMs': 1700000000000,
        },
      ];

  ProviderContainer buildContainer() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'queryFiles') {
        return queryFilesItems();
      }
      return null;
    });

    return ProviderContainer(
      overrides: [
        storageRepositoryProvider
            .overrideWithValue(const FakeStorageRepository()),
        storagePermissionRepositoryProvider.overrideWithValue(
          const FakeStoragePermissionRepository(
            initialState: StoragePermissionState.fullAccess(
              accessMode: StorageAccessMode.allFiles,
              message: 'Full storage access is enabled',
            ),
          ),
        ),
        recentLocationStoreProvider.overrideWithValue(
          InMemoryRecentLocationStore(),
        ),
        mediaStorePlatformProvider.overrideWithValue(platform),
        mediaLibraryResultsProvider.overrideWith((ref, request) async {
          return <SearchResult>[
            SearchResult(
              entry: FileSystemEntry(
                name: 'report.pdf',
                path: '/storage/emulated/0/Download/report.pdf',
                type: FileSystemEntryType.document,
                modifiedAt: DateTime(2026, 7, 30),
                sizeBytes: 100,
              ),
              parentPath: '/storage/emulated/0/Download',
              depth: 0,
            ),
          ];
        }),
      ],
    );
  }

  Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('back from a media folder pops to the media library',
      (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpApp(tester, container);
    container.read(appRouterProvider).go('/media/documents');
    await tester.pumpAndSettle();
    expect(find.byType(MediaLibraryScreen), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(find.byType(MediaFolderScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(MediaFolderScreen), findsNothing);
    expect(find.byType(MediaLibraryScreen), findsOneWidget);
  });

  testWidgets('back from the media library goes home', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await pumpApp(tester, container);
    container.read(appRouterProvider).go('/media/documents');
    await tester.pumpAndSettle();
    expect(find.byType(MediaLibraryScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(MediaLibraryScreen), findsNothing);
    expect(
      container.read(appRouterProvider).routerDelegate.currentConfiguration.uri,
      Uri.parse('/'),
    );
  });
}
