// Entry point for the history backup service.
//
// Re-exports the IO implementation on platforms with `dart:io` and a no-op
// stub elsewhere (e.g. web), so UI and startup hooks can import this file
// unconditionally.
export 'history_backup_service_stub.dart'
    if (dart.library.io) 'history_backup_service_io.dart';
