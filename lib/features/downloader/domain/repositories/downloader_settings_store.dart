/// Downloader preferences that persist across sessions.
class DownloaderSettings {
  const DownloaderSettings({
    this.maxConcurrentDownloads = 1,
    this.outputDirectory = '',
  });

  /// How many downloads may run at the same time (1..max).
  final int maxConcurrentDownloads;

  /// Absolute directory where finished files are kept. An empty value means
  /// the engine's default private download folder is used.
  ///
  /// Files land here hidden from the OS gallery and this app's media views
  /// until the user moves them to a visible location.
  final String outputDirectory;

  DownloaderSettings copyWith({
    int? maxConcurrentDownloads,
    String? outputDirectory,
  }) {
    return DownloaderSettings(
      maxConcurrentDownloads: maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      outputDirectory: outputDirectory ?? this.outputDirectory,
    );
  }
}

abstract interface class DownloaderSettingsStore {
  Future<DownloaderSettings> load();

  Future<void> save(DownloaderSettings settings);
}