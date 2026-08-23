/// A file the local user wants to send to a peer.
class NearbyOutgoingFile {
  const NearbyOutgoingFile({
    required this.id,
    required this.path,
    required this.name,
    required this.size,
    this.mime,
    this.relativePath,
  });

  final String id;
  final String path;
  final String name;
  final int size;
  final String? mime;
  final String? relativePath;
}

/// A file being received from a peer. [savedPath] is populated once the file
/// has been written to disk.
class NearbyIncomingFile {
  const NearbyIncomingFile({
    required this.id,
    required this.name,
    required this.size,
    this.mime,
    this.relativePath,
    this.savedPath,
  });

  final String id;
  final String name;
  final int size;
  final String? mime;
  final String? relativePath;
  final String? savedPath;

  NearbyIncomingFile copyWith({String? savedPath}) {
    return NearbyIncomingFile(
      id: id,
      name: name,
      size: size,
      mime: mime,
      relativePath: relativePath,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}
