import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_explorer/features/media/data/repositories/media_library_repository_provider.dart'
    show mediaStorePlatformProvider;
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_events.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_peer.dart';
import 'package:file_explorer/features/nearby_sharing/domain/entities/nearby_transfer_file.dart';
import 'package:file_explorer/features/nearby_sharing/domain/repositories/nearby_sharing_repository.dart';
import 'package:file_explorer/features/nearby_sharing/data/repositories/nearby_sharing_repository_provider.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NearbyMode { idle, scanning, hosting, sending }

enum TransferDirection { incoming, outgoing }

/// UI-model for a single file moving over a nearby session.
class NearbyTransferItem {
  const NearbyTransferItem({
    required this.id,
    required this.name,
    required this.size,
    this.transferredBytes = 0,
    this.totalBytes,
    this.ok,
    required this.direction,
    this.savedPath,
  });

  final String id;
  final String name;
  final int size;
  final int transferredBytes;
  final int? totalBytes;
  final bool? ok;
  final TransferDirection direction;
  final String? savedPath;

  NearbyTransferItem copyWith({
    int? transferredBytes,
    int? totalBytes,
    bool? ok,
    String? savedPath,
  }) {
    return NearbyTransferItem(
      id: id,
      name: name,
      size: size,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      ok: ok ?? this.ok,
      direction: direction,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}

class NearbySharingState {
  const NearbySharingState({
    this.mode = NearbyMode.idle,
    this.peers = const [],
    this.scanning = false,
    this.hosting = false,
    this.code,
    this.transfers = const [],
    this.error,
    this.selfName = 'My Phone',
    this.destinationDir = '/storage/emulated/0/File Explorer/Share',
  });

  final NearbyMode mode;
  final List<NearbyPeer> peers;
  final bool scanning;
  final bool hosting;
  final String? code;
  final List<NearbyTransferItem> transfers;
  final String? error;
  final String selfName;
  final String destinationDir;

  NearbySharingState copyWith({
    NearbyMode? mode,
    List<NearbyPeer>? peers,
    bool? scanning,
    bool? hosting,
    String? code,
    bool clearCode = false,
    List<NearbyTransferItem>? transfers,
    String? error,
    bool clearError = false,
    String? selfName,
    String? destinationDir,
  }) {
    return NearbySharingState(
      mode: mode ?? this.mode,
      peers: peers ?? this.peers,
      scanning: scanning ?? this.scanning,
      hosting: hosting ?? this.hosting,
      code: clearCode ? null : code ?? this.code,
      transfers: transfers ?? this.transfers,
      error: clearError ? null : error ?? this.error,
      selfName: selfName ?? this.selfName,
      destinationDir: destinationDir ?? this.destinationDir,
    );
  }
}

final nearbySharingControllerProvider =
    NotifierProvider<NearbySharingController, NearbySharingState>(
  NearbySharingController.new,
);

class NearbySharingController extends Notifier<NearbySharingState> {
  NearbyHost? _host;
  NearbySendSession? _sendSession;
  StreamSubscription<NearbyTransferEvent>? _hostSub;
  StreamSubscription<NearbyTransferEvent>? _sendSub;
  final Map<String, String> _taskByFileId = {};
  final List<NearbyTransferItem> _transfers = [];
  late final String _deviceId;
  late final String _code;
  bool _disposed = false;

  @override
  NearbySharingState build() {
    _deviceId = 'dev-${DateTime.now().microsecondsSinceEpoch}';
    _code = _generateCode();
    _initDeviceName();
    ref.onDispose(() {
      _disposed = true;
      _hostSub?.cancel();
      _sendSub?.cancel();
      unawaited(_host?.stop());
      unawaited(_sendSession?.cancel());
    });
    return const NearbySharingState();
  }

  Future<void> _initDeviceName() async {
    try {
      String? name = await _getprop('ro.product.device');
      name ??= await _getprop('ro.product.model');
      name ??= await _getprop('ro.build.product');
      if (!_disposed && name != null && name.isNotEmpty) {
        state = state.copyWith(selfName: name);
      }
    } catch (_) {}
  }

  Future<String?> _getprop(String prop) async {
    try {
      final result = await Process.run('/system/bin/getprop', [prop]);
      final out = result.stdout.toString().trim();
      return out.isNotEmpty ? out : null;
    } catch (_) {
      return null;
    }
  }

  String _generateCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  /// Begin hosting: advertise on the LAN and accept incoming transfers into
  /// [destinationDir].
  Future<void> startHosting({required String destinationDir}) async {
    if (state.hosting) return;
    final repo = ref.read(nearbySharingRepositoryProvider);
    final code = _code;
    _transfers.clear();
    _taskByFileId.clear();
    state = state.copyWith(
      mode: NearbyMode.hosting,
      hosting: true,
      code: code,
      destinationDir: destinationDir,
      transfers: const [],
      clearError: true,
    );
    final host = await repo.startHost(
      NearbyHostConfig(
        deviceId: _deviceId,
        deviceName: state.selfName,
        code: code,
        destinationDir: destinationDir,
      ),
    );
    _host = host;
    _hostSub = host.events.listen(
      (event) => _handleEvent(event, TransferDirection.incoming,
          destinationDir: destinationDir),
    );
  }

  Future<void> stopHosting() async {
    _hostSub?.cancel();
    _hostSub = null;
    await _host?.stop();
    _host = null;
    state = state.copyWith(
      mode: NearbyMode.idle,
      hosting: false,
      clearCode: true,
    );
  }

  /// Scan the LAN for peers for a bounded time.
  void startScan() {
    if (state.scanning) return;
    final repo = ref.read(nearbySharingRepositoryProvider);
    state = state.copyWith(
      mode: NearbyMode.scanning,
      scanning: true,
      peers: const [],
      clearError: true,
    );
    final sub = repo.discover().listen(
      (peer) {
        if (peer.id == _deviceId) return;
        final peers = [...state.peers];
        peers.removeWhere((p) => p.id == peer.id);
        peers.add(peer);
        state = state.copyWith(peers: peers);
      },
      onError: (Object error) {
        state = state.copyWith(
          scanning: false,
          mode: NearbyMode.idle,
          error: 'Discovery failed: $error',
        );
      },
      onDone: () {
        state = state.copyWith(scanning: false, mode: NearbyMode.idle);
      },
    );
    _scanSub = sub;
  }

  StreamSubscription<NearbyPeer>? _scanSub;

  void stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
    state = state.copyWith(
      scanning: false,
      mode: state.hosting ? NearbyMode.hosting : NearbyMode.idle,
    );
  }

  /// Connect to [peer] and push [files].
  Future<void> sendToPeer(
    NearbyPeer peer,
    List<NearbyOutgoingFile> files,
  ) async {
    final repo = ref.read(nearbySharingRepositoryProvider);
    final session = await repo.sendFiles(
      peer: peer,
      code: peer.code,
      files: files,
      deviceId: _deviceId,
      deviceName: state.selfName,
    );
    _sendSession = session;
    _taskByFileId.clear();
    _transfers.clear();
    state = state.copyWith(
      mode: NearbyMode.sending,
      transfers: const [],
      clearError: true,
    );
    _sendSub = session.events.listen(
      (event) => _handleEvent(
        event,
        TransferDirection.outgoing,
        peerName: peer.name,
      ),
    );
  }

  Future<void> cancelSend() async {
    _sendSub?.cancel();
    _sendSub = null;
    await _sendSession?.cancel();
    _sendSession = null;
    state = state.copyWith(mode: NearbyMode.idle);
  }

  void _handleEvent(
    NearbyTransferEvent event,
    TransferDirection direction, {
    String? destinationDir,
    String? peerName,
  }) {
    final tc = ref.read(transferControllerProvider.notifier);
    switch (event) {
      case NearbyFileOffered(
          :final id,
          :final name,
          :final size,
        ):
        final task = tc.queueNearby(
          operation: direction == TransferDirection.incoming
              ? TransferOperation.receive
              : TransferOperation.send,
          displayName: name,
          destinationPath: direction == TransferDirection.incoming
              ? (destinationDir ?? '')
              : (peerName ?? ''),
          totalBytes: size,
        );
        _taskByFileId[id] = task.id;
        _upsertItem(
          NearbyTransferItem(
            id: id,
            name: name,
            size: size,
            direction: direction,
          ),
        );
      case NearbyFileProgress(
          :final id,
          :final transferredBytes,
          :final totalBytes,
        ):
        final taskId = _taskByFileId[id];
        if (taskId != null) {
          tc.reportNearbyProgress(
            taskId: taskId,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
          );
        }
        _updateItem(
          id,
          (item) => item.copyWith(
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
          ),
        );
      case NearbyFileCompleted(:final id, :final ok, :final savedPath):
        final taskId = _taskByFileId[id];
        if (taskId != null) {
          tc.finishNearby(taskId: taskId, success: ok);
        }
        _updateItem(id, (item) => item.copyWith(ok: ok, savedPath: savedPath));
        if (ok && savedPath != null) _rescan(savedPath);
      case NearbySessionFinished(:final ok):
        if (direction == TransferDirection.incoming) {
          _transfers.clear();
          _taskByFileId.clear();
          state = state.copyWith(
            mode: NearbyMode.hosting,
            transfers: const [],
            clearError: true,
          );
        } else {
          _sendSub?.cancel();
          _sendSub = null;
          _sendSession = null;
          state = state.copyWith(mode: NearbyMode.idle);
        }
        if (!ok) {
          state = state.copyWith(error: 'Transfer failed');
        }
    }
  }

  void _upsertItem(NearbyTransferItem item) {
    _transfers.removeWhere((t) => t.id == item.id);
    _transfers.add(item);
    state = state.copyWith(transfers: List.of(_transfers));
  }

  void _updateItem(
    String id,
    NearbyTransferItem Function(NearbyTransferItem) update,
  ) {
    final index = _transfers.indexWhere((t) => t.id == id);
    if (index < 0) return;
    _transfers[index] = update(_transfers[index]);
    state = state.copyWith(transfers: List.of(_transfers));
  }

  Future<void> _rescan(String path) async {
    final mediaStore = ref.read(mediaStorePlatformProvider);
    if (mediaStore == null) return;
    try {
      await mediaStore.scanFiles([path]);
    } catch (_) {
      // Rescan is best-effort; ignore failures.
    }
  }
}
