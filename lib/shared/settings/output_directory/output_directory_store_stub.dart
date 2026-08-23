import 'package:file_explorer/shared/settings/output_directory/output_directory_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

OutputDirectoryStore createOutputDirectoryStore(Ref ref, String key) {
  return InMemoryOutputDirectoryStore();
}
