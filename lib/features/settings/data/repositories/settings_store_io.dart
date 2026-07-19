import 'package:file_explorer/features/settings/data/repositories/drift_settings_store.dart';
import 'package:file_explorer/features/settings/domain/repositories/settings_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

SettingsStore createSettingsStore(Ref ref) {
  return DriftSettingsStore(ref.watch(appDatabaseProvider));
}
