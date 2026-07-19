import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:file_explorer/features/storage_permissions/domain/repositories/storage_permission_repository.dart';

class FakeStoragePermissionRepository implements StoragePermissionRepository {
  const FakeStoragePermissionRepository({
    this.initialState = const StoragePermissionState.sampleData(),
    this.requestState,
  });

  final StoragePermissionState initialState;
  final StoragePermissionState? requestState;

  @override
  Future<StoragePermissionState> checkPermission() async {
    return initialState;
  }

  @override
  Future<StoragePermissionState> requestFullAccess() async {
    return requestState ?? initialState;
  }
}
