import 'package:file_explorer/features/settings/data/repositories/settings_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/settings/data/repositories/settings_store_io.dart';
import 'package:file_explorer/features/settings/domain/repositories/settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return createSettingsStore(ref);
});
