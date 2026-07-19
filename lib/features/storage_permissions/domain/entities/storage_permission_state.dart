enum StorageAccessMode {
  sampleData,
  noPermissionRequired,
  appSpecific,
  mediaOnly,
  allFiles,
}

enum StoragePermissionStatus {
  checking,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unsupported,
}

class StoragePermissionState {
  final StoragePermissionStatus status;
  final StorageAccessMode accessMode;
  final bool canBrowse;
  final bool canRequestFullAccess;
  final String message;

  const StoragePermissionState({
    required this.status,
    required this.accessMode,
    required this.canBrowse,
    required this.canRequestFullAccess,
    required this.message,
  });

  const StoragePermissionState.checking()
      : status = StoragePermissionStatus.checking,
        accessMode = StorageAccessMode.sampleData,
        canBrowse = false,
        canRequestFullAccess = false,
        message = 'Checking storage access';

  const StoragePermissionState.sampleData()
      : status = StoragePermissionStatus.granted,
        accessMode = StorageAccessMode.sampleData,
        canBrowse = true,
        canRequestFullAccess = false,
        message = 'Using sample storage data on this platform';

  const StoragePermissionState.fullAccess({
    required this.accessMode,
    required this.message,
  })  : status = StoragePermissionStatus.granted,
        canBrowse = true,
        canRequestFullAccess = false;

  const StoragePermissionState.needsFullAccess()
      : status = StoragePermissionStatus.denied,
        accessMode = StorageAccessMode.appSpecific,
        canBrowse = false,
        canRequestFullAccess = true,
        message = 'Full storage access is needed to browse shared files';

  const StoragePermissionState.permanentlyDenied()
      : status = StoragePermissionStatus.permanentlyDenied,
        accessMode = StorageAccessMode.appSpecific,
        canBrowse = false,
        canRequestFullAccess = true,
        message = 'Storage access is disabled in system settings';

  const StoragePermissionState.restricted()
      : status = StoragePermissionStatus.restricted,
        accessMode = StorageAccessMode.appSpecific,
        canBrowse = false,
        canRequestFullAccess = false,
        message = 'Storage access is restricted on this device';

  const StoragePermissionState.unsupported()
      : status = StoragePermissionStatus.unsupported,
        accessMode = StorageAccessMode.sampleData,
        canBrowse = true,
        canRequestFullAccess = false,
        message = 'This platform uses sample data for now';
}
