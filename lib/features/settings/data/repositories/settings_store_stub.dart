import 'package:file_explorer/features/settings/data/repositories/in_memory_settings_store.dart';
import 'package:file_explorer/features/settings/domain/repositories/settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

SettingsStore createSettingsStore(Ref ref) {
  return InMemorySettingsStore();
}
