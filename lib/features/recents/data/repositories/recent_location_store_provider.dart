import 'package:file_explorer/features/recents/data/repositories/recent_location_store_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/recents/data/repositories/recent_location_store_io.dart';
import 'package:file_explorer/features/recents/domain/repositories/recent_location_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recentLocationStoreProvider = Provider<RecentLocationStore>((ref) {
  return createRecentLocationStore(ref);
});
