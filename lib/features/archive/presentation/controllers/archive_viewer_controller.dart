import 'dart:typed_data';

import 'package:file_explorer/features/archive/data/repositories/archive_repository_provider.dart';
import 'package:file_explorer/features/archive/domain/entities/archive_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final archiveViewerControllerProvider = StateNotifierProvider.autoDispose
    .family<ArchiveViewerController, ArchiveViewerState, String>(
        (ref, archivePath) {
  return ArchiveViewerController(ref, archivePath: archivePath)
    ..loadInitialDirectory();
});

class ArchiveViewerState {
  const ArchiveViewerState({
    required this.archivePath,
    this.directoryPath = '',
    this.listing = const AsyncValue.loading(),
  });

  final String archivePath;
  final String directoryPath;
  final AsyncValue<ArchiveListing> listing;

  bool get isRoot => directoryPath.isEmpty;

  ArchiveViewerState copyWith({
    String? directoryPath,
    AsyncValue<ArchiveListing>? listing,
  }) {
    return ArchiveViewerState(
      archivePath: archivePath,
      directoryPath: directoryPath ?? this.directoryPath,
      listing: listing ?? this.listing,
    );
  }
}

class ArchiveViewerController extends StateNotifier<ArchiveViewerState> {
  ArchiveViewerController(this._ref, {required String archivePath})
      : super(ArchiveViewerState(archivePath: archivePath));

  final Ref _ref;

  Future<void> loadInitialDirectory() {
    return openDirectory(state.directoryPath);
  }

  Future<void> openDirectory(String directoryPath) async {
    final repository = _ref.read(archiveRepositoryProvider);
    state = state.copyWith(
      directoryPath: directoryPath,
      listing: const AsyncValue.loading(),
    );

    final listing = await AsyncValue.guard(
      () => repository.listDirectory(state.archivePath,
          directoryPath: directoryPath),
    );
    state = state.copyWith(listing: listing);
  }

  Future<void> openParentDirectory() {
    if (state.isRoot) {
      return Future.value();
    }
    return openDirectory(_parentOf(state.directoryPath));
  }

  Future<void> refresh() {
    return openDirectory(state.directoryPath);
  }

  Future<Uint8List?> readEntry(String entryPath) {
    return _ref
        .read(archiveRepositoryProvider)
        .readEntry(state.archivePath, entryPath);
  }

  String _parentOf(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length <= 1) {
      return '';
    }
    return segments.sublist(0, segments.length - 1).join('/');
  }
}