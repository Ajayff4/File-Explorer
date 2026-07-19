import 'dart:io';

import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:file_explorer/features/storage_permissions/domain/repositories/storage_permission_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerStoragePermissionRepository
    implements StoragePermissionRepository {
  const PermissionHandlerStoragePermissionRepository();

  @override
  Future<StoragePermissionState> checkPermission() async {
    if (!Platform.isAndroid) {
      return const StoragePermissionState.fullAccess(
        accessMode: StorageAccessMode.noPermissionRequired,
        message: 'Local filesystem access is available on this platform',
      );
    }

    final status = await Permission.manageExternalStorage.status;
    return _mapStatus(status);
  }

  @override
  Future<StoragePermissionState> requestFullAccess() async {
    if (!Platform.isAndroid) {
      return checkPermission();
    }

    final status = await Permission.manageExternalStorage.request();
    return _mapStatus(status);
  }

  StoragePermissionState _mapStatus(PermissionStatus status) {
    if (status.isGranted) {
      return const StoragePermissionState.fullAccess(
        accessMode: StorageAccessMode.allFiles,
        message: 'Full storage access is enabled',
      );
    }
    if (status.isPermanentlyDenied) {
      return const StoragePermissionState.permanentlyDenied();
    }
    if (status.isRestricted) {
      return const StoragePermissionState.restricted();
    }
    return const StoragePermissionState.needsFullAccess();
  }
}

StoragePermissionRepository createStoragePermissionRepository() {
  return const PermissionHandlerStoragePermissionRepository();
}
