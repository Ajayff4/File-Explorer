import 'dart:async';

import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_events.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_peer.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_transfer_file.dart';
import 'package:file_explorer/features/nearby_sharing/domain/repositories/nearby_sharing_repository.dart';

/// In-memory [NearbySharingRepository] for tests and non-IO platforms. It does
/// not open sockets; instead it lets the test drive events through
/// [hostEvents] (see [simulateIncoming]) and replays a canned send flow.
class NearbySharingRepositoryFake implements NearbySharingRepository {
  NearbySharingRepositoryFake({
    this.discoveredPeers = const [],
    this.hostCode = '1234',
    this.hostPort = 45322,
  });

  final List<NearbyPeer> discoveredPeers;
  final String hostCode;
  final int hostPort;

  /// Stream the controller/host subscribes to; tests push events here.
  final StreamController<NearbyTransferEvent> hostEvents =
      StreamController<NearbyTransferEvent>.broadcast();

  NearbyHostConfig? lastHostConfig;
  NearbyPeer? lastSendPeer;
  List<NearbyOutgoingFile>? lastSentFiles;

  @override
  Future<NearbyHost> startHost(NearbyHostConfig config) async {
    lastHostConfig = config;
    return NearbyHost(
      events: hostEvents.stream,
      code: config.code,
      port: hostPort,
      stop: () async {
        if (!hostEvents.isClosed) await hostEvents.close();
      },
    );
  }

  /// Simulate a peer pushing [files] to the host. Call after [startHost].
  void simulateIncoming(List<NearbyIncomingFile> files) {
    for (final file in files) {
      hostEvents.add(
        NearbyFileOffered(
          id: file.id,
          name: file.name,
          size: file.size,
        ),
      );
      hostEvents.add(
        NearbyFileProgress(
          id: file.id,
          transferredBytes: file.size,
          totalBytes: file.size,
        ),
      );
      hostEvents.add(
        NearbyFileCompleted(
          id: file.id,
          ok: true,
          savedPath: '/dest/${file.name}',
        ),
      );
    }
    hostEvents.add(NearbySessionFinished(id: 'host', ok: true));
  }

  @override
  Stream<NearbyPeer> discover({NearbyDiscoveryConfig? config}) {
    final controller = StreamController<NearbyPeer>();
    for (final peer in discoveredPeers) {
      controller.add(peer);
    }
    controller.onCancel = () => controller.close();
    return controller.stream;
  }

  @override
  Future<NearbySendSession> sendFiles({
    required NearbyPeer peer,
    required String code,
    required List<NearbyOutgoingFile> files,
    required String deviceId,
    required String deviceName,
  }) async {
    lastSendPeer = peer;
    lastSentFiles = files;
    final controller = StreamController<NearbyTransferEvent>.broadcast();
    unawaited(_simulateSend(files, controller));
    return NearbySendSession(
      events: controller.stream,
      cancel: () async {
        if (!controller.isClosed) await controller.close();
      },
    );
  }

  Future<void> _simulateSend(
    List<NearbyOutgoingFile> files,
    StreamController<NearbyTransferEvent> controller,
  ) async {
    for (final file in files) {
      controller.add(
        NearbyFileOffered(
          id: file.id,
          name: file.name,
          size: file.size,
        ),
      );
      controller.add(
        NearbyFileProgress(
          id: file.id,
          transferredBytes: file.size,
          totalBytes: file.size,
        ),
      );
      controller.add(NearbyFileCompleted(id: file.id, ok: true));
    }
    controller.add(NearbySessionFinished(id: 'guest', ok: true));
    if (!controller.isClosed) await controller.close();
  }
}
