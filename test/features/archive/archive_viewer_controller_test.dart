import 'package:file_explorer/features/archive/data/repositories/local_archive_repository_stub.dart';
import 'package:file_explorer/features/archive/data/repositories/archive_repository_provider.dart';
import 'package:file_explorer/features/archive/presentation/controllers/archive_viewer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const archivePath = FakeArchiveRepository.sampleArchivePath;

void main() {
  test('loads initial directory listing from root', () async {
    final container = makeContainer();
    final state = container.read(archiveViewerControllerProvider(archivePath));
    expect(state.archivePath, archivePath);
    expect(state.isRoot, isTrue);

    await waitForListing(container);
    final loaded =
        container.read(archiveViewerControllerProvider(archivePath));
    expect(loaded.listing.hasValue, isTrue);

    final entries = loaded.listing.value!.entries;
    expect(entries.map((e) => e.name), contains('Documents'));
    expect(entries.map((e) => e.name), contains('backup_manifest.json'));
  });

  test('navigates into a subfolder', () async {
    final container = makeContainer();
    final controller =
        container.read(archiveViewerControllerProvider(archivePath).notifier);
    await controller.openDirectory('Documents');

    final state = container.read(archiveViewerControllerProvider(archivePath));
    expect(state.directoryPath, 'Documents');
    expect(state.isRoot, isFalse);
    expect(
      state.listing.value!.entries.map((e) => e.name),
      contains('notes.txt'),
    );
  });

  test('openParentDirectory returns to root', () async {
    final container = makeContainer();
    final controller =
        container.read(archiveViewerControllerProvider(archivePath).notifier);
    await controller.openDirectory('Documents');
    await controller.openParentDirectory();

    final state = container.read(archiveViewerControllerProvider(archivePath));
    expect(state.isRoot, isTrue);
    expect(state.listing.value!.entries, isNotEmpty);
  });

  test('openParentDirectory at root keeps root', () async {
    final container = makeContainer();
    final controller =
        container.read(archiveViewerControllerProvider(archivePath).notifier);
    await controller.openParentDirectory();

    final state = container.read(archiveViewerControllerProvider(archivePath));
    expect(state.isRoot, isTrue);
  });
}

ProviderContainer makeContainer() {
  final container = ProviderContainer(
    overrides: [
      archiveRepositoryProvider.overrideWithValue(const FakeArchiveRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> waitForListing(ProviderContainer container) async {
  final notifier =
      container.read(archiveViewerControllerProvider(archivePath).notifier);
  await notifier.loadInitialDirectory();
}