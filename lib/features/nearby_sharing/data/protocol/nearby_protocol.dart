import 'dart:convert';

import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_peer.dart';

/// Wire constants for the nearby-sharing protocol.
class NearbyProtocol {
  const NearbyProtocol._();

  /// UDP port used for discovery beacons / probes.
  static const int udpPort = 45321;

  /// TCP port used for the actual file-transfer channel.
  static const int tcpPort = 45322;

  /// Protocol scheme version. Bump when the message set changes incompatibly.
  static const int schemeVersion = 1;

  /// Magic prefix so we can tell our beacons apart from unrelated UDP traffic.
  static const String beaconMagic = 'fe-filex';
}

/// Metadata for a single file in a transfer manifest / header.
class NearbyFileMeta {
  const NearbyFileMeta({
    required this.id,
    required this.name,
    required this.size,
    this.mime,
    this.relativePath,
  });

  final String id;
  final String name;
  final int size;
  final String? mime;
  final String? relativePath;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        if (mime != null) 'mime': mime,
        if (relativePath != null) 'rel': relativePath,
      };

  factory NearbyFileMeta.fromJson(Map<String, Object?> json) {
    return NearbyFileMeta(
      id: json['id'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
      mime: json['mime'] as String?,
      relativePath: json['rel'] as String?,
    );
  }
}

/// A newline-delimited JSON control message on the TCP channel, or a UDP
/// discovery beacon.
sealed class NearbyMessage {
  const NearbyMessage();

  Map<String, Object?> toJson();

  /// Serialize as a single newline-terminated JSON line.
  String toLine() => '${jsonEncode(toJson())}\n';

  /// Parse a single line; returns `null` for blank/unrecognized input.
  static NearbyMessage? tryParse(String raw) {
    try {
      final line = raw.trim();
      if (line.isEmpty) return null;
      final Map<String, Object?>? data =
          jsonDecode(line) as Map<String, Object?>?;
      if (data == null) return null;
      final type = data['t'];
      switch (type) {
        case 'beacon':
          return NearbyBeaconMessage.fromJson(data);
        case 'hello':
          return NearbyHelloMessage.fromJson(data);
        case 'ok':
          return const NearbyOkMessage();
        case 'deny':
          return NearbyDenyMessage(
            reason: (data['reason'] as String?) ?? 'denied',
          );
        case 'manifest':
          return NearbyManifestMessage.fromJson(data);
        case 'accept':
          return NearbyAcceptMessage.fromJson(data);
        case 'reject':
          return NearbyRejectMessage.fromJson(data);
        case 'file':
          return NearbyFileHeaderMessage.fromJson(data);
        case 'ack':
          return NearbyAckMessage.fromJson(data);
        case 'nak':
          return NearbyNakMessage.fromJson(data);
        case 'done':
          return const NearbyDoneMessage();
        case 'complete':
          return const NearbyCompleteMessage();
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

/// UDP discovery beacon sent by a host; also answered to a guest probe.
final class NearbyBeaconMessage extends NearbyMessage {
  NearbyBeaconMessage({
    required this.id,
    required this.name,
    required this.tcpPort,
    required this.code,
  });

  final String id;
  final String name;
  final int tcpPort;
  final String code;

  @override
  Map<String, Object?> toJson() => {
        't': 'beacon',
        'magic': NearbyProtocol.beaconMagic,
        'v': NearbyProtocol.schemeVersion,
        'id': id,
        'name': name,
        'tcp': tcpPort,
        'code': code,
      };

  factory NearbyBeaconMessage.fromJson(Map<String, Object?> json) {
    return NearbyBeaconMessage(
      id: json['id'] as String,
      name: json['name'] as String,
      tcpPort: json['tcp'] as int,
      code: json['code'] as String,
    );
  }

  /// Build a [NearbyPeer] from this beacon, binding it to [host].
  NearbyPeer toPeer(String host) => NearbyPeer(
        id: id,
        name: name,
        host: host,
        tcpPort: tcpPort,
        code: code,
      );
}

/// Guest → host: announce intent, identity, and the pairing code.
final class NearbyHelloMessage extends NearbyMessage {
  NearbyHelloMessage({
    required this.deviceId,
    required this.name,
    required this.code,
  });

  final String deviceId;
  final String name;
  final String code;

  @override
  Map<String, Object?> toJson() => {
        't': 'hello',
        'v': NearbyProtocol.schemeVersion,
        'id': deviceId,
        'name': name,
        'code': code,
      };

  factory NearbyHelloMessage.fromJson(Map<String, Object?> json) {
    return NearbyHelloMessage(
      deviceId: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

/// Host → guest: code accepted, proceed.
final class NearbyOkMessage extends NearbyMessage {
  const NearbyOkMessage();

  @override
  Map<String, Object?> toJson() => {'t': 'ok'};
}

/// Host → guest: code rejected.
final class NearbyDenyMessage extends NearbyMessage {
  NearbyDenyMessage({required this.reason});

  final String reason;

  @override
  Map<String, Object?> toJson() => {'t': 'deny', 'reason': reason};
}

/// Guest → host: the list of files it wants to send.
final class NearbyManifestMessage extends NearbyMessage {
  NearbyManifestMessage({required this.files});

  final List<NearbyFileMeta> files;

  @override
  Map<String, Object?> toJson() => {
        't': 'manifest',
        'files': [for (final f in files) f.toJson()],
      };

  factory NearbyManifestMessage.fromJson(Map<String, Object?> json) {
    final raw = (json['files'] as List).cast<Map<String, Object?>>();
    return NearbyManifestMessage(
      files: [for (final f in raw) NearbyFileMeta.fromJson(f)],
    );
  }
}

/// Host → guest: these file ids are accepted for transfer.
final class NearbyAcceptMessage extends NearbyMessage {
  NearbyAcceptMessage({required this.ids});

  final List<String> ids;

  @override
  Map<String, Object?> toJson() => {'t': 'accept', 'ids': ids};

  factory NearbyAcceptMessage.fromJson(Map<String, Object?> json) {
    final raw = (json['ids'] as List).cast<String>();
    return NearbyAcceptMessage(ids: raw);
  }
}

/// Host → guest: these file ids are rejected.
final class NearbyRejectMessage extends NearbyMessage {
  NearbyRejectMessage({required this.ids});

  final List<String> ids;

  @override
  Map<String, Object?> toJson() => {'t': 'reject', 'ids': ids};

  factory NearbyRejectMessage.fromJson(Map<String, Object?> json) {
    final raw = (json['ids'] as List).cast<String>();
    return NearbyRejectMessage(ids: raw);
  }
}

/// Guest → host: start streaming the given file. Exactly [size] bytes of raw
/// content (then a 4-byte big-endian CRC32) follow this line on the socket.
final class NearbyFileHeaderMessage extends NearbyMessage {
  NearbyFileHeaderMessage({required this.meta});

  final NearbyFileMeta meta;

  @override
  Map<String, Object?> toJson() => {'t': 'file', ...meta.toJson()};

  factory NearbyFileHeaderMessage.fromJson(Map<String, Object?> json) {
    return NearbyFileHeaderMessage(meta: NearbyFileMeta.fromJson(json));
  }
}

/// Host → guest: a file finished; [ok] is false when the CRC check failed.
final class NearbyAckMessage extends NearbyMessage {
  NearbyAckMessage({required this.id, required this.ok});

  final String id;
  final bool ok;

  @override
  Map<String, Object?> toJson() => {'t': 'ack', 'id': id, 'ok': ok};

  factory NearbyAckMessage.fromJson(Map<String, Object?> json) {
    return NearbyAckMessage(
      id: json['id'] as String,
      ok: json['ok'] as bool,
    );
  }
}

/// Host → guest: a file could not be written; the guest should treat it as
/// failed (no retry in MVP).
final class NearbyNakMessage extends NearbyMessage {
  NearbyNakMessage({required this.id});

  final String id;

  @override
  Map<String, Object?> toJson() => {'t': 'nak', 'id': id};

  factory NearbyNakMessage.fromJson(Map<String, Object?> json) {
    return NearbyNakMessage(id: json['id'] as String);
  }
}

/// Guest → host: no more files.
final class NearbyDoneMessage extends NearbyMessage {
  const NearbyDoneMessage();

  @override
  Map<String, Object?> toJson() => {'t': 'done'};
}

/// Host → guest: session complete.
final class NearbyCompleteMessage extends NearbyMessage {
  const NearbyCompleteMessage();

  @override
  Map<String, Object?> toJson() => {'t': 'complete'};
}
