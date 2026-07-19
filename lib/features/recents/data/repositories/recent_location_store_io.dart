import 'package:file_explorer/features/recents/data/repositories/drift_recent_location_store.dart';
import 'package:file_explorer/features/recents/domain/repositories/recent_location_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

RecentLocationStore createRecentLocationStore(Ref ref) {
  return DriftRecentLocationStore(ref.watch(appDatabaseProvider));
}
