/// Build-time toggle for the legacy Android storage-permission model.
///
/// When enabled, the app requests the classic READ/WRITE_EXTERNAL_STORAGE
/// permissions (the model used before Android 11's "All files access") instead
/// of MANAGE_EXTERNAL_STORAGE. This is needed only for testing on Android < 11
/// devices (e.g. Android 9) where the All-files-access flow is unavailable.
///
/// It is OFF by default, so production builds are completely unaffected.
/// Enable it for a test build with:
///
///   flutter build apk --dart-define=LEGACY_STORAGE=true
///   flutter install --debug -d <device> --dart-define=LEGACY_STORAGE=true
const bool kLegacyStorageMode =
    bool.fromEnvironment('LEGACY_STORAGE', defaultValue: false);
