import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_explorer/features/nearby_sharing/data/protocol/nearby_crc.dart';
import 'package:file_explorer/features/nearby_sharing/data/protocol/nearby_protocol.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_events.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_peer.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_transfer_file.dart';
import 'package:path/path.dart' as p;

/// Configuration for a hosting (receiving) session.
class NearbyHostConfig {
  NearbyHostConfig({
    required this.deviceId,
    required this.deviceName,
    required this.code,
    required this.destinationDir,
    this.tcpPort = NearbyProtocol.tcpPort,
    this.udpPort = NearbyProtocol.udpPort,
    this.bindAddress,
    this.broadcastAddress,
    this.beaconInterval = const Duration(seconds: 1),
  });

  final String deviceId;
  final String deviceName;
  final String code;
  final String destinationDir;
  final int tcpPort;
  final int udpPort;
  final InternetAddress? bindAddress;
  final InternetAddress? broadcastAddress;
  final Duration beaconInterval;
}

/// Configuration for LAN discovery.
class NearbyDiscoveryConfig {
  NearbyDiscoveryConfig({
    this.udpPort = NearbyProtocol.udpPort,
    this.bindAddress,
    this.broadcastAddress,
    this.scanTimeout = const Duration(seconds: 8),
  });

  final int udpPort;
  final InternetAddress? bindAddress;
  final InternetAddress? broadcastAddress;
  final Duration scanTimeout;
}

/// A live hosting session. [events] reports incoming-file progress; call
/// [stop] to tear it down.
class NearbyHost {
  NearbyHost({
    required this.events,
    required this.code,
    required this.port,
    required this.stop,
  });

  final Stream<NearbyTransferEvent> events;
  final String code;
  final int port;
  final Future<void> Function() stop;
}

/// A live outgoing (send) session.
class NearbySendSession {
  NearbySendSession({
    required this.events,
    required this.cancel,
  });

  final Stream<NearbyTransferEvent> events;
  final Future<void> Function() cancel;
}

/// Abstraction over the network transport so the UI/controller can be tested
/// with a fake and the IO implementation can be swapped per platform.
abstract interface class NearbySharingRepository {
  /// Begin hosting: bind a TCP server + UDP beacon and start advertising.
  Future<NearbyHost> startHost(NearbyHostConfig config);

  /// Listen for peers on the LAN for [config.scanTimeout] (or until cancelled).
  Stream<NearbyPeer> discover({NearbyDiscoveryConfig? config});

  /// Connect to [peer] and push [files]. The returned session drives the
  /// transfer and reports progress through its [NearbySendSession.events].
  Future<NearbySendSession> sendFiles({
    required NearbyPeer peer,
    required String code,
    required List<NearbyOutgoingFile> files,
    required String deviceId,
    required String deviceName,
  });
}

/// Big-endian 4-byte encoding of a CRC32 (used as the per-file trailer).
Uint8List int32Bytes(int value) {
  return Uint8List(4)
    ..[0] = (value >> 24) & 0xFF
    ..[1] = (value >> 16) & 0xFF
    ..[2] = (value >> 8) & 0xFF
    ..[3] = value & 0xFF;
}

/// Decode the 4-byte big-endian CRC32 trailer.
int bytesToInt32(Uint8List bytes) {
  return ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]) &
      0xFFFFFFFF;
}

/// Pick a non-colliding destination path inside [dir] for [name].
///
/// [name] may contain sub-directories (a relative path); the matching parent
/// folders are created so folder structures sent by the peer are preserved.
String resolveDestination(String dir, String name) {
  final clean = name.split('/').where((part) => part.isNotEmpty).join('/');
  final full = clean.isEmpty ? '$dir/file' : '$dir/$clean';
  if (!File(full).existsSync()) {
    final parent = p.dirname(full);
    if (parent != dir) {
      try {
        Directory(parent).createSync(recursive: true);
      } on FileSystemException {
        // Fall through; the write will surface a clearer error if it fails.
      }
    }
    return full;
  }
  final lastSlash = clean.lastIndexOf('/');
  final dirPart = lastSlash >= 0 ? clean.substring(0, lastSlash) : '';
  final base = lastSlash >= 0 ? clean.substring(lastSlash + 1) : clean;
  final dot = base.lastIndexOf('.');
  final stem = dot > 0 ? base.substring(0, dot) : base;
  final ext = dot > 0 ? base.substring(dot) : '';
  var i = 1;
  String candidate;
  do {
    candidate = dirPart.isEmpty
        ? '$dir/$stem ($i)$ext'
        : '$dir/$dirPart/$stem ($i)$ext';
    i++;
  } while (File(candidate).existsSync());
  return candidate;
}

/// CRC32 helper re-exported for callers that stream file chunks.
int updateCrc(int crc, List<int> chunk) => crc32Update(crc, chunk);
