import 'package:file_explorer/shared/settings/output_directory/output_directory_store_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user-chosen output directory for a feature and persists changes.
///
/// Seed each feature with its own provider, e.g.
/// ```dart
/// final nearbyOutputDirectoryProvider =
///     NotifierProvider<OutputDirectoryController, String>(
///   () => OutputDirectoryController(
///     'nearby.output_directory',
///     defaultDirectory: '/storage/emulated/0/Download/NearbyShare',
///   ),
/// );
/// ```
class OutputDirectoryController extends Notifier<String> {
  OutputDirectoryController(this._key, {required this.defaultDirectory});

  final String _key;
  final String defaultDirectory;

  @override
  String build() {
    _load();
    return defaultDirectory;
  }

  Future<void> _load() async {
    final store = createOutputDirectoryStore(ref, _key);
    final directory = await store.load();
    state = directory.isEmpty ? defaultDirectory : directory;
  }

  Future<void> setDirectory(String directory) async {
    state = directory;
    final store = createOutputDirectoryStore(ref, _key);
    await store.save(directory);
  }
}
