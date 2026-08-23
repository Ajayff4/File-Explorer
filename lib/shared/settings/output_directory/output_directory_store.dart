/// Minimal persistence for a single "output directory" setting, reused by any
/// feature that writes files to a user-chosen location (downloader, nearby
/// received files, generated QR images, ...).
abstract interface class OutputDirectoryStore {
  /// Returns the persisted directory, or an empty string if none is set.
  Future<String> load();

  /// Persists [directory].
  Future<void> save(String directory);
}

class InMemoryOutputDirectoryStore implements OutputDirectoryStore {
  InMemoryOutputDirectoryStore([this._directory = '']);

  String _directory;

  @override
  Future<String> load() async => _directory;

  @override
  Future<void> save(String directory) async => _directory = directory;
}
