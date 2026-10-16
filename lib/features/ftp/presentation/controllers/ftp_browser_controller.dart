import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_explorer/features/ftp/data/services/remote_service_factory.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/domain/repositories/remote_file_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mime/mime.dart';

/// One browser session per open server screen. Auto-disposes (disconnects)
/// when the screen closes.
final ftpBrowserControllerProvider = StateNotifierProvider.autoDispose
    .family<FtpBrowserController, FtpBrowserState, FtpConnection>(
  (ref, connection) {
    final controller = FtpBrowserController(
      createRemoteFileService(connection.protocol),
      connection,
    );
    unawaited(controller.connect());
    // No ref.onDispose here: autoDispose already disposes the notifier,
    // which disconnects in [FtpBrowserController.dispose]. Registering
    // dispose twice throws (use-after-dispose).
    return controller;
  },
);

class FtpBrowserState {
  const FtpBrowserState({
    required this.connection,
    this.currentPath = '/',
    this.entries = const [],
    this.isConnecting = true,
    this.isLoading = false,
    this.error,
    this.isGrid = false,
  });

  final FtpConnection connection;
  final String currentPath;
  final List<RemoteEntry> entries;
  final bool isConnecting;
  final bool isLoading;
  final String? error;
  final bool isGrid;

  bool get canGoUp => currentPath != '/' && currentPath.isNotEmpty;

  FtpBrowserState copyWith({
    String? currentPath,
    List<RemoteEntry>? entries,
    bool? isConnecting,
    bool? isLoading,
    String? Function()? error,
    bool? isGrid,
  }) {
    return FtpBrowserState(
      connection: connection,
      currentPath: currentPath ?? this.currentPath,
      entries: entries ?? this.entries,
      isConnecting: isConnecting ?? this.isConnecting,
      isLoading: isLoading ?? this.isLoading,
      error: error == null ? this.error : error(),
      isGrid: isGrid ?? this.isGrid,
    );
  }
}

class FtpBrowserController extends StateNotifier<FtpBrowserState> {
  FtpBrowserController(this._service, FtpConnection connection)
      : super(FtpBrowserState(connection: connection));

  final RemoteFileService _service;
  bool _disposed = false;

  /// Session thumbnail cache: remote path -> downscaled PNG bytes.
  final Map<String, Uint8List> _thumbs = {};

  /// Image paths currently downloading (dedupes concurrent tile builds).
  final Map<String, Future<Uint8List?>> _thumbInflight = {};
  int _thumbActive = 0;

  Future<void> connect() async {
    state = state.copyWith(isConnecting: true, error: () => null);
    try {
      await _service.connect(state.connection);
      if (_disposed || !mounted) return;
      state = state.copyWith(isConnecting: false);
      await _load(state.connection.remotePath.isEmpty
          ? '/'
          : state.connection.remotePath);
    } catch (error) {
      if (_disposed || !mounted) return;
      state = state.copyWith(
        isConnecting: false,
        error: () => _message(error),
      );
    }
  }

  Future<void> openDirectory(String path) => _load(path);

  Future<void> goUp() async {
    final path = state.currentPath;
    if (path == '/' || path.isEmpty) return;
    final trimmed =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final index = trimmed.lastIndexOf('/');
    await _load(index <= 0 ? '/' : trimmed.substring(0, index));
  }

  Future<void> refresh() => _load(state.currentPath);

  void toggleView() {
    if (!mounted) return;
    state = state.copyWith(isGrid: !state.isGrid);
  }

  Future<Uint8List> downloadBytes(String remotePath) {
    return _service.downloadBytes(remotePath);
  }

  String downloadErrorMessage(Object error) => _message(error);

  /// True for decodable image names (actual decode may still fail).
  static bool isImageName(String name) {
    return lookupMimeType(name)?.startsWith('image/') ?? false;
  }

  /// Downscaled thumbnail bytes for [entry], or null when not an image,
  /// too big, or the fetch fails. Results cache for the session; at most
  /// 4 downloads run at once so grids don't flood the connection.
  Future<Uint8List?> thumbnailFor(RemoteEntry entry) {
    if (entry.isDirectory || !isImageName(entry.name)) {
      return Future.value(null);
    }
    const maxBytes = 20 * 1024 * 1024;
    if (entry.sizeBytes != null && entry.sizeBytes! > maxBytes) {
      return Future.value(null);
    }
    final cached = _thumbs[entry.path];
    if (cached != null) return Future.value(cached);
    return _thumbInflight.putIfAbsent(entry.path, () async {
      while (_thumbActive >= 4 && !_disposed) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (_disposed) return null;
      _thumbActive++;
      try {
        final bytes = await _service.downloadBytes(entry.path);
        if (_disposed) return null;
        final thumb = await _downscale(bytes);
        if (thumb != null) {
          if (_thumbs.length > 150) _thumbs.clear();
          _thumbs[entry.path] = thumb;
        }
        return thumb;
      } catch (_) {
        return null;
      } finally {
        _thumbActive--;
        _thumbInflight.remove(entry.path);
      }
    });
  }

  /// Decodes [bytes] to a ~256px PNG. Null when undecodable (HEIC, ...).
  static Future<Uint8List?> _downscale(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 256,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      codec.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load(String path) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final entries = await _service.listDirectory(path);
      if (_disposed || !mounted) return;
      state = state.copyWith(
        currentPath: path,
        entries: entries,
        isLoading: false,
      );
    } catch (error) {
      if (_disposed || !mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: () => _message(error),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_service.disconnect());
    super.dispose();
  }

  String _message(Object error) {
    final text = error.toString();
    return text
        .replaceFirst('RemoteConnectionException: ', '')
        .replaceFirst('FTPConnectException: ', '')
        .replaceFirst('Exception: ', '');
  }
}
