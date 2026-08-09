import 'package:file_explorer/features/zip/data/repositories/local_zip_repository_stub.dart';
import 'package:file_explorer/features/zip/data/repositories/zip_repository_provider.dart';
import 'package:file_explorer/features/zip/presentation/controllers/zip_viewer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const archivePath = FakeZipRepository.sampleArchivePath;

void main() {
  test('loads initial directory listing from root', () async {
    final container = makeContainer();
    final state = container.read(zipViewerControllerProvider(archivePath));
    expect(state.archivePath, archivePath);
    expect(state.isRoot, isTrue);

    await waitForListing(container);
    final loaded = container.read(zipViewerControllerProvider(archivePath));
    expect(loaded.listing.hasValue, isTrue);

    final entries = loaded.listing.valueOrNull!.entries;
    expect(entries.map((e) => e.name), contains('Documents'));
    expect(entries.map((e) => e.name), contains('backup_manifest.json'));
  });

  test('navigates into a subfolder', () async {
    final container = makeContainer();
    final controller = container.read(zipViewerControllerProvider(archivePath).notifier);
    await controller.openDirectory('Documents');

    final state = container.read(zipViewerControllerProvider(archivePath));
    expect(state.directoryPath, 'Documents');
    expect(state.isRoot, isFalse);
    expect(
      state.listing.valueOrNull!.entries.map((e) => e.name),
      contains('notes.txt'),
    );
  });

  test('openParentDirectory returns to root', () async {
    final container = makeContainer();
    final controller = container.read(zipViewerControllerProvider(archivePath).notifier);
    await controller.openDirectory('Documents');
    await controller.openParentDirectory();

    final state = container.read(zipViewerControllerProvider(archivePath));
    expect(state.isRoot, isTrue);
    expect(state.listing.valueOrNull!.entries, isNotEmpty);
  });

  test('openParentDirectory at root keeps root', () async {
    final container = makeContainer();
    final controller = container.read(zipViewerControllerProvider(archivePath).notifier);
    await controller.openParentDirectory();

    final state = container.read(zipViewerControllerProvider(archivePath));
    expect(state.isRoot, isTrue);
  });
}

ProviderContainer makeContainer() {
  final container = ProviderContainer(
    overrides: [
      zipRepositoryProvider.overrideWithValue(const FakeZipRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> waitForListing(ProviderContainer container) async {
  final notifier = container.read(zipViewerControllerProvider(archivePath).notifier);
  await notifier.loadInitialDirectory();
}
