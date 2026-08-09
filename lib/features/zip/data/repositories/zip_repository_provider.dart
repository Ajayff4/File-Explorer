import 'package:file_explorer/features/zip/data/repositories/local_zip_repository_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/zip/data/repositories/local_zip_repository_io.dart';
import 'package:file_explorer/features/zip/domain/repositories/zip_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final zipRepositoryProvider = Provider<ZipRepository>((ref) {
  return createZipRepository();
});
