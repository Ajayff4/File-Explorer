import 'package:file_explorer/features/search/data/repositories/drift_search_index_store.dart';
import 'package:file_explorer/features/search/domain/repositories/search_index_store.dart';
import 'package:file_explorer/shared/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

SearchIndexStore createSearchIndexStore(Ref ref) {
  return DriftSearchIndexStore(ref.watch(appDatabaseProvider));
}
