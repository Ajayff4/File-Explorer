import 'dart:io';

import 'package:file_explorer/features/media/data/platform/media_store_platform.dart';
import 'package:file_explorer/features/media/data/repositories/media_library_repository_provider.dart';
import 'package:file_explorer/features/media/presentation/media_folder_screen.dart';
import 'package:file_explorer/features/media/presentation/media_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/media_store_folder');
  const platform = MediaStorePlatform(channel: channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mockFiles(List<Map<String, Object?>> items) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'queryFiles') {
        return items;
      }
      return null;
    });
  }

  Future<void> pumpFolder(
    WidgetTester tester,
    MediaLibraryKind kind,
    String path,
  ) async {
    final appRouter = GoRouter(
      initialLocation: '/media/${kind.routeSegment}/folder',
      routes: [
        GoRoute(
          path: '/media/:kind/folder',
          builder: (context, state) {
            return MediaFolderScreen(folderPath: path, kind: kind);
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaStorePlatformProvider.overrideWithValue(platform),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loads document kind from MediaStore', (tester) async {
    mockFiles([
      {
        'path': '/storage/emulated/0/Download/report.pdf',
        'name': 'report.pdf',
        'sizeBytes': 10,
        'modifiedAtMs': 1700000000000,
      },
      {
        'path': '/storage/emulated/0/Download/release.apk',
        'name': 'release.apk',
        'sizeBytes': 20,
        'modifiedAtMs': 1700000001000,
      },
    ]);

    await pumpFolder(
      tester,
      MediaLibraryKind.documents,
      '/storage/emulated/0/Download',
    );

    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('release.apk'), findsNothing);
  });

  testWidgets('loads archive and app kinds from MediaStore', (tester) async {
    mockFiles([
      {
        'path': '/storage/emulated/0/Download/files.zip',
        'name': 'files.zip',
        'sizeBytes': 10,
        'modifiedAtMs': 1700000000000,
      },
      {
        'path': '/storage/emulated/0/Download/app.apk',
        'name': 'app.apk',
        'sizeBytes': 20,
        'modifiedAtMs': 1700000001000,
      },
      {
        'path': '/storage/emulated/0/Download/notes.txt',
        'name': 'notes.txt',
        'sizeBytes': 30,
        'modifiedAtMs': 1700000002000,
      },
    ]);

    await pumpFolder(
      tester,
      MediaLibraryKind.archives,
      '/storage/emulated/0/Download',
    );
    expect(find.text('files.zip'), findsOneWidget);
    expect(find.text('app.apk'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await pumpFolder(
      tester,
      MediaLibraryKind.apps,
      '/storage/emulated/0/Download',
    );
    expect(find.text('app.apk'), findsOneWidget);
    expect(find.text('files.zip'), findsNothing);
  });

  testWidgets('falls back to the directory listing when MediaStore fails',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'query_failed');
    });

    await tester.runAsync(() async {
      final tempDir = await Directory.systemTemp.createTemp('folder_view');
      await File('${tempDir.path}/fallback.pdf').writeAsString('x');

      final appRouter = GoRouter(
        initialLocation: '/media/documents/folder',
        routes: [
          GoRoute(
            path: '/media/:kind/folder',
            builder: (context, state) {
              return MediaFolderScreen(
                folderPath: tempDir.path,
                kind: MediaLibraryKind.documents,
              );
            },
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaStorePlatformProvider.overrideWithValue(platform),
          ],
          child: MaterialApp.router(routerConfig: appRouter),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      await tempDir.delete(recursive: true);
    });

    await tester.pumpAndSettle();

    expect(find.text('fallback.pdf'), findsOneWidget);
  });
}
