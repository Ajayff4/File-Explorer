import 'package:file_explorer/features/explorer/data/repositories/fake_storage_repository.dart';
import 'package:file_explorer/features/explorer/domain/repositories/storage_repository.dart';

StorageRepository createStorageRepository() {
  return const FakeStorageRepository();
}
