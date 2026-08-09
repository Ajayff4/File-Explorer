import 'package:file_explorer/features/archive/data/repositories/local_archive_repository_stub.dart'
    if (dart.library.io)
      'package:file_explorer/features/archive/data/repositories/local_archive_repository_io.dart';
import 'package:file_explorer/features/archive/domain/repositories/archive_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final archiveRepositoryProvider = Provider<ArchiveRepository>((ref) {
  return createArchiveRepository();
});