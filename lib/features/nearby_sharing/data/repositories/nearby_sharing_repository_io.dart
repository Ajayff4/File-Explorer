import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_explorer/features/nearby_sharing/data/protocol/nearby_crc.dart';
import 'package:file_explorer/features/nearby_sharing/data/protocol/nearby_protocol.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_events.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_peer.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_transfer_file.dart';
import 'package:file_explorer/features/nearby_sharing/domain/repositories/nearby_sharing_repository.dart';

/// IO implementation of [NearbySharingRepository] built on `dart:io` sockets.
///
/// No external plugin is required: discovery uses a UDP beacon and the transfer
/// channel is a raw TCP socket speaking the newline-JSON protocol defined in
/// [NearbyProtocol].
class NearbySharingRepositoryIo implements NearbySharingRepository {
  @override
  Future<NearbyHost> startHost(NearbyHostConfig config) async {
    await Directory(config.destinationDir).create(recursive: true);
    final server = await ServerSocket.bind(
      config.bindAddress ?? InternetAddress.anyIPv4,
      config.tcpPort,
    );
    final udp = await RawDatagramSocket.bind(
      config.bindAddress ?? InternetAddress.anyIPv4,
      config.udpPort,
    );
    udp.broadcastEnabled = true;

    final controller = StreamController<NearbyTransferEvent>.broadcast();
    var closed = false;
    void emit(NearbyTransferEvent event) {
      if (!closed) controller.add(event);
    }

    final connections = <Socket>{};
    final beacon = NearbyBeaconMessage(
      id: config.deviceId,
      name: config.deviceName,
      tcpPort: server.port,
      code: config.code,
    );
    final beaconBytes = utf8.encode(beacon.toLine());
    final targets = await _broadcastTargets(config.broadcastAddress);
    final beaconTimer = Timer.periodic(config.beaconInterval, (_) {
      for (final target in targets) {
        try {
          udp.send(beaconBytes, target, config.udpPort);
        } catch (_) {
          // Interface may have changed; ignore transient send errors.
        }
      }
    });

    server.listen((socket) {
      connections.add(socket);
      _handleHostConnection(socket, config, emit).whenComplete(
        () => connections.remove(socket),
      );
    });

    Future<void> stop() async {
      closed = true;
      beaconTimer.cancel();
      for (final socket in connections) {
        try {
          await socket.close();
        } catch (_) {}
      }
      await server.close();
      try {
        udp.close();
      } catch (_) {}
      await controller.close();
    }

    return NearbyHost(
      events: controller.stream,
      code: config.code,
      port: server.port,
      stop: stop,
    );
  }

  /// Broadcast addresses to send beacons to.
  ///
  /// [override] is used when a specific address is configured. Otherwise we
  /// send to the limited broadcast (255.255.255.255) and to each IPv4
  /// interface's /24 subnet broadcast, since limited broadcast is frequently
  /// dropped by Android's WLAN stack while the subnet broadcast usually
  /// reaches other devices on the same Wi-Fi.
  Future<List<InternetAddress>> _broadcastTargets(
    InternetAddress? override,
  ) async {
    if (override != null) return [override];
    final targets = <InternetAddress>[];
    try {
      targets.add(InternetAddress('255.255.255.255'));
    } catch (_) {}
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final octets = addr.address.split('.');
          if (octets.length == 4) {
            try {
              targets.add(
                InternetAddress(
                  '${octets[0]}.${octets[1]}.${octets[2]}.255',
                ),
              );
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return targets;
  }

  Future<void> _handleHostConnection(
    Socket socket,
    NearbyHostConfig config,
    void Function(NearbyTransferEvent) emit,
  ) async {
    final reader = _SocketReader(socket);
    try {
      final hello = NearbyMessage.tryParse(await reader.readLine());
      if (hello is! NearbyHelloMessage || hello.code != config.code) {
        socket.write(NearbyDenyMessage(reason: 'bad code').toLine());
        await socket.flush();
        await socket.close();
        emit(NearbySessionFinished(id: 'host', ok: false));
        return;
      }
      socket.write(const NearbyOkMessage().toLine());
      await socket.flush();

      final manifest = NearbyMessage.tryParse(await reader.readLine());
      if (manifest is! NearbyManifestMessage) {
        await socket.close();
        return;
      }
      final files = manifest.files;
      socket.write(
        NearbyAcceptMessage(ids: [for (final f in files) f.id]).toLine(),
      );
      await socket.flush();

      var allOk = true;
      for (final meta in files) {
        final header = NearbyMessage.tryParse(await reader.readLine());
        if (header is! NearbyFileHeaderMessage) break;

        emit(
          NearbyFileOffered(
            id: meta.id,
            name: meta.name,
            size: meta.size,
            mime: meta.mime,
          ),
        );

        final dest = resolveDestination(
          config.destinationDir,
          meta.relativePath ?? meta.name,
        );
        final sink = File(dest).openWrite();
        var running = 0xFFFFFFFF;
        var transferred = 0;
        await reader.readExactly(meta.size, (chunk) {
          sink.add(chunk);
          running = crc32Update(running, chunk);
          transferred += chunk.length;
          emit(
            NearbyFileProgress(
              id: meta.id,
              transferredBytes: transferred,
              totalBytes: meta.size,
            ),
          );
        });
        final trailer = await reader.readBytes(4);
        await sink.close();

        final ok = (running ^ 0xFFFFFFFF) == bytesToInt32(trailer);
        if (!ok) {
          try {
            await File(dest).delete();
          } catch (_) {}
          allOk = false;
        }
        socket.write(NearbyAckMessage(id: meta.id, ok: ok).toLine());
        await socket.flush();
        emit(
          NearbyFileCompleted(
            id: meta.id,
            ok: ok,
            savedPath: ok ? dest : null,
          ),
        );
      }

      try {
        await reader.readLine();
      } catch (_) {}
      socket.write(const NearbyCompleteMessage().toLine());
      await socket.flush();
      await socket.close();
      emit(NearbySessionFinished(id: 'host', ok: allOk));
    } catch (_) {
      emit(NearbySessionFinished(id: 'host', ok: false));
      try {
        await socket.close();
      } catch (_) {}
    } finally {
      reader.dispose();
    }
  }

  @override
  Stream<NearbyPeer> discover({NearbyDiscoveryConfig? config}) {
    final cfg = config ?? NearbyDiscoveryConfig();
    final controller = StreamController<NearbyPeer>();
    RawDatagramSocket? udp;
    Timer? timeout;
    final seen = <String, NearbyPeer>{};

    void close() {
      timeout?.cancel();
      try {
        udp?.close();
      } catch (_) {}
    }

    () async {
      udp = await RawDatagramSocket.bind(
        cfg.bindAddress ?? InternetAddress.anyIPv4,
        cfg.udpPort,
      );
      udp!.broadcastEnabled = true;
      timeout = Timer(cfg.scanTimeout, () {
        close();
        controller.close();
      });
      udp!.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = udp!.receive();
        if (datagram == null) return;
        final message = NearbyMessage.tryParse(utf8.decode(datagram.data));
        if (message is! NearbyBeaconMessage) return;
        final peer = message.toPeer(datagram.address.address);
        final previous = seen[peer.id];
        if (previous != null && previous.code == peer.code) return;
        seen[peer.id] = peer;
        if (!controller.isClosed) controller.add(peer);
      });
    }();

    controller.onCancel = close;
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
    final socket = await Socket.connect(peer.host, peer.tcpPort);
    final controller = StreamController<NearbyTransferEvent>();
    final lineQueue = _LineQueue(
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter()),
    );

    unawaited(
      _runSend(
        socket: socket,
        lineQueue: lineQueue,
        controller: controller,
        peer: peer,
        code: code,
        files: files,
        deviceId: deviceId,
        deviceName: deviceName,
      ),
    );

    return NearbySendSession(
      events: controller.stream,
      cancel: () async {
        try {
          await socket.close();
        } catch (_) {}
        await controller.close();
      },
    );
  }

  Future<void> _runSend({
    required Socket socket,
    required _LineQueue lineQueue,
    required StreamController<NearbyTransferEvent> controller,
    required NearbyPeer peer,
    required String code,
    required List<NearbyOutgoingFile> files,
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      socket.write(
        NearbyHelloMessage(
          deviceId: deviceId,
          name: deviceName,
          code: code,
        ).toLine(),
      );
      await socket.flush();

      final helloResp = NearbyMessage.tryParse(await lineQueue.next());
      if (helloResp is! NearbyOkMessage) {
        controller.add(NearbySessionFinished(id: 'guest', ok: false));
        await socket.close();
        await controller.close();
        return;
      }

      final metas = [
        for (final f in files)
          NearbyFileMeta(
            id: f.id,
            name: f.name,
            size: f.size,
            mime: f.mime,
            relativePath: f.relativePath,
          ),
      ];
      socket.write(NearbyManifestMessage(files: metas).toLine());
      await socket.flush();

      final accept = NearbyMessage.tryParse(await lineQueue.next());
      final accepted =
          accept is NearbyAcceptMessage ? accept.ids.toSet() : <String>{};

      var allOk = true;
      for (final f in files) {
        if (!accepted.contains(f.id)) {
          controller.add(NearbyFileCompleted(id: f.id, ok: false));
          allOk = false;
          continue;
        }

        controller.add(
          NearbyFileOffered(
            id: f.id,
            name: f.name,
            size: f.size,
            mime: f.mime,
          ),
        );

        final file = File(f.path);
        final size = await file.length();
        socket.write(
          NearbyFileHeaderMessage(
            meta: NearbyFileMeta(
              id: f.id,
              name: f.name,
              size: size,
              mime: f.mime,
              relativePath: f.relativePath,
            ),
          ).toLine(),
        );
        await socket.flush();

        var running = 0xFFFFFFFF;
        var transferred = 0;
        await for (final chunk in file.openRead()) {
          socket.add(chunk);
          running = crc32Update(running, chunk);
          transferred += chunk.length;
          controller.add(
            NearbyFileProgress(
              id: f.id,
              transferredBytes: transferred,
              totalBytes: size,
            ),
          );
        }
        socket.add(int32Bytes(running ^ 0xFFFFFFFF));
        await socket.flush();

        final ack = NearbyMessage.tryParse(await lineQueue.next());
        final ok = ack is NearbyAckMessage && ack.ok;
        if (!ok) allOk = false;
        controller.add(NearbyFileCompleted(id: f.id, ok: ok));
      }

      socket.write(const NearbyDoneMessage().toLine());
      await socket.flush();
      try {
        await lineQueue.next();
      } catch (_) {}
      await socket.close();
      controller.add(NearbySessionFinished(id: deviceId, ok: allOk));
    } catch (_) {
      controller.add(NearbySessionFinished(id: 'guest', ok: false));
      try {
        await socket.close();
      } catch (_) {}
    } finally {
      await controller.close();
    }
  }
}

/// Reads a socket as a stream of JSON control lines interleaved with fixed-size
/// binary blobs (file content + CRC trailer).
class _SocketReader {
  _SocketReader(this._socket) {
    _subscription = _socket.listen(
      (data) {
        _buffer.addAll(data);
        _pump();
      },
      onDone: () {
        _closed = true;
        _pump();
      },
      onError: (Object error) {
        _error = error;
        _pump();
      },
      cancelOnError: false,
    );
  }

  final Socket _socket;
  final List<int> _buffer = [];
  final List<_Waiter> _waiters = [];
  late final StreamSubscription<List<int>> _subscription;
  bool _closed = false;
  Object? _error;

  void _pump() {
    while (_waiters.isNotEmpty) {
      final waiter = _waiters.first;
      if (waiter.fulfill(_buffer)) {
        _waiters.removeAt(0);
      } else if (_closed || _error != null) {
        waiter.fail(_error);
        _waiters.removeAt(0);
      } else {
        break;
      }
    }
  }

  Future<String> readLine() {
    final waiter = _LineWaiter();
    _waiters.add(waiter);
    _pump();
    return waiter.completer.future;
  }

  Future<void> readExactly(int n, void Function(Uint8List chunk) onChunk) {
    final waiter = _BytesWaiter(n, onChunk);
    _waiters.add(waiter);
    _pump();
    return waiter.completer.future;
  }

  Future<Uint8List> readBytes(int n) {
    final out = <int>[];
    final completer = Completer<Uint8List>();
    _waiters.add(
      _BytesWaiter(n, out.addAll, () => completer.complete(Uint8List.fromList(out))),
    );
    _pump();
    return completer.future;
  }

  void dispose() => _subscription.cancel();
}

abstract class _Waiter {
  bool fulfill(List<int> buffer);
  void fail(Object? error);
}

class _LineWaiter implements _Waiter {
  final completer = Completer<String>();

  @override
  bool fulfill(List<int> buffer) {
    for (var i = 0; i < buffer.length; i++) {
      if (buffer[i] == 10) {
        final bytes = buffer.sublist(0, i);
        buffer.removeRange(0, i + 1);
        completer.complete(utf8.decode(bytes));
        return true;
      }
    }
    return false;
  }

  @override
  void fail(Object? error) {
    if (!completer.isCompleted) {
      completer.completeError(error ?? StateError('connection closed'));
    }
  }
}

class _BytesWaiter implements _Waiter {
  _BytesWaiter(this.remaining, this.onChunk, [this.onDone]);

  int remaining;
  final void Function(Uint8List chunk) onChunk;
  final void Function()? onDone;
  final completer = Completer<void>();

  @override
  bool fulfill(List<int> buffer) {
    if (buffer.isEmpty) return false;
    final take = remaining < buffer.length ? remaining : buffer.length;
    final chunk = Uint8List.fromList(buffer.sublist(0, take));
    buffer.removeRange(0, take);
    remaining -= take;
    onChunk(chunk);
    if (remaining == 0) {
      onDone?.call();
      completer.complete();
      return true;
    }
    return false;
  }

  @override
  void fail(Object? error) {
    if (!completer.isCompleted) {
      completer.completeError(error ?? StateError('connection closed'));
    }
  }
}

/// Buffers a stream of decoded lines and lets callers pull them one at a time.
class _LineQueue {
  _LineQueue(this._stream) {
    _stream.listen(
      (line) {
        if (_waiters.isNotEmpty) {
          _waiters.removeAt(0).complete(line);
        } else {
          _queue.add(line);
        }
      },
      onDone: () {
        for (final waiter in _waiters) {
          waiter.completeError(StateError('connection closed'));
        }
        _waiters.clear();
      },
    );
  }

  final Stream<String> _stream;
  final List<String> _queue = [];
  final List<Completer<String>> _waiters = [];

  Future<String> next() {
    if (_queue.isNotEmpty) return Future.value(_queue.removeAt(0));
    final completer = Completer<String>();
    _waiters.add(completer);
    return completer.future;
  }
}

/// Factory used by the provider (selected on `dart:io` platforms).
NearbySharingRepository createNearbySharingRepository() =>
    NearbySharingRepositoryIo();
