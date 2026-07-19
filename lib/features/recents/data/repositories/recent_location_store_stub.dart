import 'package:file_explorer/features/recents/data/repositories/in_memory_recent_location_store.dart';
import 'package:file_explorer/features/recents/domain/repositories/recent_location_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

RecentLocationStore createRecentLocationStore(Ref ref) {
  return InMemoryRecentLocationStore();
}
