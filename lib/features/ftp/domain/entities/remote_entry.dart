/// A single file or folder on a remote FTP/SFTP/FTPS server.
library;

class RemoteEntry {
  const RemoteEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.sizeBytes,
    this.modifiedAt,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? sizeBytes;
  final DateTime? modifiedAt;

  /// Directories first, then alphabetical (case-insensitive).
  static List<RemoteEntry> sorted(List<RemoteEntry> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }
}
