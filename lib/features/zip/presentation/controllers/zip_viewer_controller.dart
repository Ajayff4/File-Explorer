import 'dart:typed_data';

import 'package:file_explorer/features/zip/data/repositories/zip_repository_provider.dart';
import 'package:file_explorer/features/zip/domain/entities/zip_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final zipViewerControllerProvider = StateNotifierProvider.autoDispose
    .family<ZipViewerController, ZipViewerState, String>((ref, archivePath) {
  return ZipViewerController(ref, archivePath: archivePath)
    ..loadInitialDirectory();
});

class ZipViewerState {
  const ZipViewerState({
    required this.archivePath,
    this.directoryPath = '',
    this.listing = const AsyncValue.loading(),
  });

  final String archivePath;
  final String directoryPath;
  final AsyncValue<ZipListing> listing;

  bool get isRoot => directoryPath.isEmpty;

  ZipViewerState copyWith({
    String? directoryPath,
    AsyncValue<ZipListing>? listing,
  }) {
    return ZipViewerState(
      archivePath: archivePath,
      directoryPath: directoryPath ?? this.directoryPath,
      listing: listing ?? this.listing,
    );
  }
}

class ZipViewerController extends StateNotifier<ZipViewerState> {
  ZipViewerController(this._ref, {required String archivePath})
      : super(ZipViewerState(archivePath: archivePath));

  final Ref _ref;

  Future<void> loadInitialDirectory() {
    return openDirectory(state.directoryPath);
  }

  Future<void> openDirectory(String directoryPath) async {
    final repository = _ref.read(zipRepositoryProvider);
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
        .read(zipRepositoryProvider)
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
