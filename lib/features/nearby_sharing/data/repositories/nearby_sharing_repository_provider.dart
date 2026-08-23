import 'package:file_explorer/features/nearby_sharing/data/repositories/nearby_sharing_repository_stub.dart'
    if (dart.library.io)
      'package:file_explorer/features/nearby_sharing/data/repositories/nearby_sharing_repository_io.dart';
import 'package:file_explorer/features/nearby_sharing/domain/repositories/nearby_sharing_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nearbySharingRepositoryProvider =
    Provider<NearbySharingRepository>((ref) {
  return createNearbySharingRepository();
});
