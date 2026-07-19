import 'package:file_explorer/app/app.dart';
import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/data/repositories/storage_repository_provider.dart';
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
        ],
        child: const FileExplorerApp(),
      ),
    );
    await tester.pump();

    expect(find.text('File Explorer'), findsWidgets);
    expect(find.text('Internal storage'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
  });
}
