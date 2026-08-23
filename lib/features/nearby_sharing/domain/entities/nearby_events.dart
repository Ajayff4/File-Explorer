/// Progress / lifecycle events emitted while a nearby transfer is in flight.
/// Used for both incoming (host) and outgoing (guest) transfers; [savedPath] is
/// only meaningful on completion of an incoming file.
sealed class NearbyTransferEvent {
  const NearbyTransferEvent({required this.id});

  final String id;
}

/// A peer offered a file (or the local user queued one to send).
final class NearbyFileOffered extends NearbyTransferEvent {
  const NearbyFileOffered({
    required super.id,
    required this.name,
    required this.size,
    this.mime,
  });

  final String name;
  final int size;
  final String? mime;
}

/// Bytes transferred so far for [id].
final class NearbyFileProgress extends NearbyTransferEvent {
  const NearbyFileProgress({
    required super.id,
    required this.transferredBytes,
    required this.totalBytes,
  });

  final int transferredBytes;
  final int totalBytes;
}

/// A single file finished (or failed integrity check).
final class NearbyFileCompleted extends NearbyTransferEvent {
  const NearbyFileCompleted({
    required super.id,
    required this.ok,
    this.savedPath,
  });

  final bool ok;
  final String? savedPath;
}

/// The whole session (all files) finished.
final class NearbySessionFinished extends NearbyTransferEvent {
  const NearbySessionFinished({required super.id, required this.ok});

  final bool ok;
}
