import 'package:file_explorer/features/storage_permissions/data/repositories/fake_storage_permission_repository.dart';
import 'package:file_explorer/features/storage_permissions/domain/repositories/storage_permission_repository.dart';

StoragePermissionRepository createStoragePermissionRepository() {
  return const FakeStoragePermissionRepository();
}
