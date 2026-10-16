import 'dart:async';

import 'package:file_explorer/features/ftp/data/repositories/ftp_connection_store_provider.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/repositories/ftp_connection_store.dart';
import 'package:flutter_riverpod/legacy.dart';

final ftpControllerProvider =
    StateNotifierProvider<FtpController, FtpState>((ref) {
  final controller = FtpController(ref.read(ftpConnectionStoreProvider));
  unawaited(controller.loadConnections());
  return controller;
});

class FtpState {
  const FtpState({
    this.connections = const [],
    this.isLoading = false,
  });

  final List<FtpConnection> connections;
  final bool isLoading;

  FtpConnection? connectionFor(String id) {
    for (final connection in connections) {
      if (connection.id == id) return connection;
    }
    return null;
  }

  FtpState copyWith({
    List<FtpConnection>? connections,
    bool? isLoading,
  }) {
    return FtpState(
      connections: connections ?? this.connections,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FtpController extends StateNotifier<FtpState> {
  FtpController(this._store) : super(const FtpState());

  final FtpConnectionStore _store;

  Future<void> loadConnections() async {
    state = state.copyWith(isLoading: true);
    final connections = await _store.loadConnections();
    if (!mounted) return;
    state = state.copyWith(connections: connections, isLoading: false);
  }

  /// Inserts or updates [connection]. Caller builds timestamps; this keeps
  /// list sorted newest first.
  Future<void> saveConnection(FtpConnection connection) async {
    final error = connection.validate();
    if (error != null) throw ArgumentError(error);
    await _store.saveConnection(connection);
    if (!mounted) return;
    final connections = [
      connection,
      for (final existing in state.connections)
        if (existing.id != connection.id) existing,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(connections: connections);
  }

  Future<void> deleteConnection(String id) async {
    await _store.deleteConnection(id);
    if (!mounted) return;
    state = state.copyWith(
      connections: [
        for (final connection in state.connections)
          if (connection.id != id) connection,
      ],
    );
  }

  /// Builds a new connection with a unique id and current timestamps.
  static FtpConnection buildNew({
    required String name,
    required FtpProtocol protocol,
    required String host,
    required int port,
    required String username,
    String? password,
    String remotePath = '/',
    bool passiveMode = true,
    bool acceptInvalidCert = false,
    SftpAuthType sftpAuthType = SftpAuthType.password,
    String? privateKeyPath,
    KeyFormat keyFormat = KeyFormat.auto,
    String? passphrase,
  }) {
    final now = DateTime.now();
    return FtpConnection(
      id: '${now.microsecondsSinceEpoch}',
      name: name.trim(),
      protocol: protocol,
      host: host.trim(),
      port: port,
      username: username.trim(),
      password: password?.isEmpty ?? true ? null : password,
      remotePath: remotePath.isEmpty ? '/' : remotePath,
      passiveMode: passiveMode,
      acceptInvalidCert: acceptInvalidCert,
      sftpAuthType: sftpAuthType,
      privateKeyPath:
          privateKeyPath?.isEmpty ?? true ? null : privateKeyPath,
      keyFormat: keyFormat,
      passphrase: passphrase?.isEmpty ?? true ? null : passphrase,
      createdAt: now,
      updatedAt: now,
    );
  }
}
