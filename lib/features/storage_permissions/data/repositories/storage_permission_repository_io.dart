import 'dart:io';

import 'package:file_explorer/features/explorer/data/platform/android_storage_platform.dart';
import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:file_explorer/features/storage_permissions/domain/repositories/storage_permission_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerStoragePermissionRepository
    implements StoragePermissionRepository {
  const PermissionHandlerStoragePermissionRepository({
    this.androidStoragePlatform = const AndroidStoragePlatform(),
  });

  final AndroidStoragePlatform androidStoragePlatform;

  @override
  Future<StoragePermissionState> checkPermission() async {
    if (!Platform.isAndroid) {
      return const StoragePermissionState.fullAccess(
        accessMode: StorageAccessMode.noPermissionRequired,
        message: 'Local filesystem access is available on this platform',
      );
    }

    final hasNativeAccess =
        await androidStoragePlatform.isAllFilesAccessGranted();
    if (hasNativeAccess) {
      return const StoragePermissionState.fullAccess(
        accessMode: StorageAccessMode.allFiles,
        message: 'Full storage access is enabled',
      );
    }

    final status = await Permission.manageExternalStorage.status;
    return _mapStatus(status, hasNativeAccess: hasNativeAccess);
  }

  @override
  Future<StoragePermissionState> requestFullAccess() async {
    if (!Platform.isAndroid) {
      return checkPermission();
    }

    await Permission.manageExternalStorage.request();
    return checkPermission();
  }

  StoragePermissionState _mapStatus(
    PermissionStatus status, {
    required bool hasNativeAccess,
  }) {
    if (status.isGranted || hasNativeAccess) {
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
