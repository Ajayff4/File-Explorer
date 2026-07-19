import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';

abstract interface class StoragePermissionRepository {
  Future<StoragePermissionState> checkPermission();

  Future<StoragePermissionState> requestFullAccess();
}
