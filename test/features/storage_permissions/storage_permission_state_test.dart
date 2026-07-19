import 'package:file_explorer/features/storage_permissions/domain/entities/storage_permission_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoragePermissionState', () {
    test('sample data mode can browse without requesting full access', () {
      const state = StoragePermissionState.sampleData();

      expect(state.canBrowse, isTrue);
      expect(state.canRequestFullAccess, isFalse);
      expect(state.accessMode, StorageAccessMode.sampleData);
    });

    test('needs full access blocks browsing until the user acts', () {
      const state = StoragePermissionState.needsFullAccess();

      expect(state.canBrowse, isFalse);
      expect(state.canRequestFullAccess, isTrue);
      expect(state.status, StoragePermissionStatus.denied);
    });
  });
}
