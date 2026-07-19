import 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/storage_permissions/data/repositories/storage_permission_repository_io.dart';
import 'package:file_explorer/features/storage_permissions/domain/repositories/storage_permission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storagePermissionRepositoryProvider =
    Provider<StoragePermissionRepository>((ref) {
  return createStoragePermissionRepository();
});
