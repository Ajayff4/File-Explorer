import 'dart:async';
import 'dart:math' as math;

import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/entry_actions_button.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/presentation/local_media_actions.dart';
import 'package:file_explorer/features/media/presentation/local_media_source_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/media/presentation/local_media_source_io.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:file_explorer/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

const _wakelockChannel = MethodChannel('com.ajayff4.fileexplorer/wakelock');

const _wallpaperChannel = MethodChannel('com.ajayff4.fileexplorer/wallpaper');

class MediaViewerSession {
  const MediaViewerSession({
    required this.entry,
    required this.entries,
  });

  final FileSystemEntry entry;
  final List<FileSystemEntry> entries;
}

class MediaViewerScreen extends ConsumerStatefulWidget {
  MediaViewerScreen({
    FileSystemEntry? entry,
    MediaViewerSession? session,
    super.key,
  }) : session = session ??
            (entry == null
                ? null
                : MediaViewerSession(entry: entry, entries: const []));

  final MediaViewerSession? session;

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late FileSystemEntry _entry;
  late List<FileSystemEntry> _playlist;
  bool _shuffle = false;
  bool _landscape = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    final session = widget.session;
    _entry = session?.entry ??
        FileSystemEntry(
          name: 'Preview',
          path: '',
          type: FileSystemEntryType.other,
          modifiedAt: DateTime(0),
        );
    _playlist = _playlistFor(session);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final fullscreenVideo = _entry.type == FileSystemEntryType.video &&
        _landscape &&
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final visualPreview = _entry.type == FileSystemEntryType.image ||
        _entry.type == FileSystemEntryType.video;

    return Scaffold(
      backgroundColor: visualPreview ? Colors.black : null,
      appBar: fullscreenVideo
          ? null
          : AppBar(
              title: Text(
                _entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      body: ColoredBox(
        color: colorScheme.surface,
        child: Column(
          children: [
            Expanded(
              child: _MediaPreview(
                key: ValueKey(_entry.path),
                entry: _entry,
                hasPlaylist: _playlist.length > 1,
                shuffle: _shuffle,
                landscape: _landscape,
                onPrevious: _openPrevious,
                onNext: _openNext,
                onToggleShuffle: _toggleShuffle,
                onToggleLandscape: _toggleLandscape,
                onShowInfo: () => _showEntryInfo(context),
                onDelete: _confirmDeleteCurrentEntry,
                onShare: _shareCurrentEntry,
                onRename: _requestRenameCurrentEntry,
                onOpenWith: _openCurrentEntryWithSystem,
                onSetWallpaper: _showWallpaperPlaceholder,
              ),
            ),
            if (!_canPreview(_entry)) _MediaDetails(entry: _entry),
          ],
        ),
      ),
    );
  }

  List<FileSystemEntry> _playlistFor(MediaViewerSession? session) {
    final entries = session?.entries ?? const <FileSystemEntry>[];
    final sameType = entries
        .where((entry) => entry.type == _entry.type && _canPreview(entry))
        .toList(growable: false);
    if (sameType.any((entry) => entry.path == _entry.path)) {
      return sameType;
    }
    return [_entry, ...sameType];
  }

  void _openPrevious() {
    _openPlaylistOffset(-1);
  }

  void _openNext() {
    if (_shuffle && _playlist.length > 1) {
      final currentIndex = _playlist.indexWhere((e) => e.path == _entry.path);
      var nextIndex = currentIndex;
      while (nextIndex == currentIndex) {
        nextIndex = math.Random().nextInt(_playlist.length);
      }
      setState(() => _entry = _playlist[nextIndex]);
      return;
    }
    _openPlaylistOffset(1);
  }

  void _openPlaylistOffset(int offset) {
    if (_playlist.length < 2) {
      return;
    }
    final currentIndex = _playlist.indexWhere((e) => e.path == _entry.path);
    final safeIndex = currentIndex == -1 ? 0 : currentIndex;
    final nextIndex = (safeIndex + offset) % _playlist.length;
    setState(() => _entry = _playlist[nextIndex]);
  }

  void _toggleShuffle() {
    setState(() => _shuffle = !_shuffle);
  }

  void _toggleLandscape() {
    final next = !_landscape;
    SystemChrome.setPreferredOrientations(
      next
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );
    SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    setState(() => _landscape = next);
  }

  void _showEntryInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return EntryPropertiesPanel(entries: [_entry]);
      },
    );
  }

  Future<void> _confirmDeleteCurrentEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete image?'),
          content: Text(_entry.name),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    ref.read(transferControllerProvider.notifier).queueOperation(
          operation: TransferOperation.delete,
          sourcePaths: [_entry.path],
          displayName: _entry.name,
        );
    Navigator.of(context).pop();
  }

  Future<void> _shareCurrentEntry() async {
    try {
      await shareLocalFile(_entry.path, fallbackMimeType: 'image/*');
    } on MissingPluginException {
      _showPlaceholder('Share is available on Android');
    } on PlatformException catch (error) {
      _showPlaceholder(error.message ?? 'Could not share image');
    }
  }

  Future<void> _openCurrentEntryWithSystem() async {
    try {
      await openLocalFileWithSystem(_entry.path);
    } on MissingPluginException {
      _showPlaceholder('Open with is available on Android');
    } on PlatformException catch (error) {
      _showPlaceholder(error.message ?? 'Could not open file');
    }
  }

  Future<void> _requestRenameCurrentEntry() async {
    if (!mounted) {
      return;
    }
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _RenameEntryDialog(initialName: _entry.name),
    );

    await Future<void>.delayed(kThemeAnimationDuration);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    final trimmedName = newName?.trim();
    if (trimmedName == null ||
        trimmedName.isEmpty ||
        trimmedName == _entry.name) {
      return;
    }
    if (RegExp(r'[\\/]').hasMatch(trimmedName)) {
      _showPlaceholder('Name cannot contain path separators');
      return;
    }

    ref.read(transferControllerProvider.notifier).queueOperation(
          operation: TransferOperation.rename,
          sourcePaths: [_entry.path],
          displayName: _entry.name,
          destinationPath: p.join(p.dirname(_entry.path), trimmedName),
          totalBytes: _entry.sizeBytes,
        );
    _showTransferSnackBar('Rename task queued');
  }

  Future<void> _showWallpaperPlaceholder() async {
    try {
      await _wallpaperChannel.invokeMethod<void>(
        'setWallpaper',
        {'path': _entry.path},
      );
      _showPlaceholder('Wallpaper updated');
    } on MissingPluginException {
      _showPlaceholder('Set as wallpaper is available on Android');
    } on PlatformException catch (error) {
      _showPlaceholder(error.message ?? 'Could not set wallpaper');
    }
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showTransferSnackBar(String message) {
    final router = GoRouter.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: 'Transfers',
            onPressed: () => router.go(AppRoutes.transfers),
          ),
        ),
      );
  }
}

class _RenameEntryDialog extends StatefulWidget {
  const _RenameEntryDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameEntryDialog> createState() => _RenameEntryDialogState();
}

class _RenameEntryDialogState extends State<_RenameEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    final extension = p.extension(widget.initialName);
    final nameSelectionEnd = extension.isEmpty
        ? widget.initialName.length
        : widget.initialName.length - extension.length;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: nameSelectionEnd.clamp(0, widget.initialName.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename image'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        textInputAction: TextInputAction.done,
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(_controller.text),
          child: const Text('Queue'),
        ),
      ],
    );
  }

  void _submit(String value) {
    Navigator.of(context).pop(value);
  }
}

class MissingMediaViewerScreen extends StatelessWidget {
  const MissingMediaViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: const Center(child: Text('No media file selected')),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.entry,
    required this.hasPlaylist,
    required this.shuffle,
    required this.landscape,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onToggleLandscape,
    required this.onShowInfo,
    required this.onDelete,
    required this.onShare,
    required this.onRename,
    required this.onOpenWith,
    required this.onSetWallpaper,
    super.key,
  });

  final FileSystemEntry entry;
  final bool hasPlaylist;
  final bool shuffle;
  final bool landscape;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleLandscape;
  final VoidCallback onShowInfo;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback onOpenWith;
  final VoidCallback onSetWallpaper;

  @override
  Widget build(BuildContext context) {
    return switch (entry.type) {
      FileSystemEntryType.image => _ImagePreview(
          entry: entry,
          hasPlaylist: hasPlaylist,
          onPrevious: onPrevious,
          onNext: onNext,
          onShowInfo: onShowInfo,
          onDelete: onDelete,
          onShare: onShare,
          onRename: onRename,
          onSetWallpaper: onSetWallpaper,
        ),
      FileSystemEntryType.video ||
      FileSystemEntryType.audio =>
        _PlaybackPreview(
          entry: entry,
          hasPlaylist: hasPlaylist,
          shuffle: shuffle,
          landscape: landscape,
          onPrevious: onPrevious,
          onNext: onNext,
          onToggleShuffle: onToggleShuffle,
          onToggleLandscape: onToggleLandscape,
          onShowInfo: onShowInfo,
        ),
      _ => _UnsupportedPreview(entry: entry, onOpenWith: onOpenWith),
    };
  }
}

class _ImagePreview extends StatefulWidget {
  const _ImagePreview({
    required this.entry,
    required this.hasPlaylist,
    required this.onPrevious,
    required this.onNext,
    required this.onShowInfo,
    required this.onDelete,
    required this.onShare,
    required this.onRename,
    required this.onSetWallpaper,
  });

  final FileSystemEntry entry;
  final bool hasPlaylist;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onShowInfo;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback onSetWallpaper;

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  final _transformationController = TransformationController();
  int _quarterTurns = 0;
  int _activeImagePointers = 0;
  Offset? _imagePointerDownPosition;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: _handleImagePointerDown,
            onPointerUp: _handleImagePointerUp,
            onPointerCancel: (_) => _activeImagePointers = 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _toggleZoom,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 5,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: RotatedBox(
                        quarterTurns: _quarterTurns,
                        child: localImageForPath(
                          path: widget.entry.path,
                          fit: BoxFit.contain,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          errorBuilder: (context, error, stackTrace) {
                            return _PreviewError(
                              icon: Icons.broken_image_rounded,
                              title: 'Could not open image',
                              detail: '$error',
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Center(
                child: _ImageToolbar(
                  hasPlaylist: widget.hasPlaylist,
                  onPrevious: widget.onPrevious,
                  onNext: widget.onNext,
                  onRotate: _rotate,
                  onShowInfo: widget.onShowInfo,
                  onDelete: widget.onDelete,
                  onShare: widget.onShare,
                  onRename: widget.onRename,
                  onSetWallpaper: widget.onSetWallpaper,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleZoom() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    _transformationController.value =
        currentScale > 1 ? Matrix4.identity() : Matrix4.identity()
          ..scaleByDouble(2.0, 2.0, 2.0, 1.0);
  }

  void _rotate() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _handleImagePointerDown(PointerDownEvent event) {
    if (_activeImagePointers == 0) {
      _imagePointerDownPosition = event.position;
    }
    _activeImagePointers += 1;
  }

  void _handleImagePointerUp(PointerUpEvent event) {
    final started = _imagePointerDownPosition;
    final wasSinglePointer = _activeImagePointers == 1;
    _activeImagePointers = (_activeImagePointers - 1).clamp(0, 8);
    if (!widget.hasPlaylist || !wasSinglePointer || started == null) {
      return;
    }

    final isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.02;
    final delta = event.position - started;
    if (isZoomed || delta.dx.abs() < 90 || delta.dx.abs() < delta.dy.abs()) {
      return;
    }
    if (delta.dx < 0) {
      widget.onNext();
    } else {
      widget.onPrevious();
    }
  }
}

class _ImageToolbar extends StatelessWidget {
  const _ImageToolbar({
    required this.hasPlaylist,
    required this.onPrevious,
    required this.onNext,
    required this.onRotate,
    required this.onShowInfo,
    required this.onDelete,
    required this.onShare,
    required this.onRename,
    required this.onSetWallpaper,
  });

  final bool hasPlaylist;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRotate;
  final VoidCallback onShowInfo;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback onSetWallpaper;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPlaylist)
                _ImageToolbarButton(
                  tooltip: 'Previous image',
                  label: 'Prev',
                  onPressed: onPrevious,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
              _ImageToolbarButton(
                tooltip: 'Rotate',
                label: 'Rotate',
                onPressed: onRotate,
                icon: const Icon(Icons.rotate_90_degrees_cw_rounded),
              ),
              _ImageToolbarButton(
                tooltip: 'Share image',
                label: 'Share',
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
              ),
              _ImageMoreButton(
                onShowInfo: onShowInfo,
                onDelete: onDelete,
                onRename: onRename,
                onSetWallpaper: onSetWallpaper,
              ),
              if (hasPlaylist)
                _ImageToolbarButton(
                  tooltip: 'Next image',
                  label: 'Next',
                  onPressed: onNext,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageToolbarButton extends StatelessWidget {
  const _ImageToolbarButton({
    required this.tooltip,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final String label;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      color: Colors.white,
      iconSize: 26,
      constraints: const BoxConstraints.tightFor(width: 58, height: 56),
      onPressed: onPressed,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ImageMoreButton extends StatelessWidget {
  const _ImageMoreButton({
    required this.onShowInfo,
    required this.onDelete,
    required this.onRename,
    required this.onSetWallpaper,
  });

  final VoidCallback onShowInfo;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onSetWallpaper;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ImageMoreAction>(
      tooltip: 'More image actions',
      color: Theme.of(context).colorScheme.surface,
      onSelected: (action) {
        void runAfterMenuCloses(VoidCallback callback) {
          Future<void>.delayed(const Duration(milliseconds: 220), () {
            if (context.mounted) {
              callback();
            }
          });
        }

        switch (action) {
          case _ImageMoreAction.info:
            runAfterMenuCloses(onShowInfo);
          case _ImageMoreAction.delete:
            runAfterMenuCloses(onDelete);
          case _ImageMoreAction.rename:
            runAfterMenuCloses(onRename);
          case _ImageMoreAction.wallpaper:
            runAfterMenuCloses(onSetWallpaper);
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: _ImageMoreAction.info,
            padding: EdgeInsets.zero,
            height: 42,
            child: _ImageMoreMenuItem(
              leading: Icon(Icons.info_outline_rounded),
              title: 'Info',
            ),
          ),
          PopupMenuItem(
            value: _ImageMoreAction.delete,
            padding: EdgeInsets.zero,
            height: 42,
            child: _ImageMoreMenuItem(
              leading: Icon(Icons.delete_rounded),
              title: 'Delete',
            ),
          ),
          PopupMenuItem(
            value: _ImageMoreAction.rename,
            padding: EdgeInsets.zero,
            height: 42,
            child: _ImageMoreMenuItem(
              leading: Icon(Icons.drive_file_rename_outline_rounded),
              title: 'Rename',
            ),
          ),
          PopupMenuItem(
            value: _ImageMoreAction.wallpaper,
            padding: EdgeInsets.zero,
            height: 42,
            child: _ImageMoreMenuItem(
              leading: Icon(Icons.wallpaper_rounded),
              title: 'Set as wallpaper',
            ),
          ),
        ];
      },
      child: const SizedBox(
        width: 58,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz_rounded, color: Colors.white, size: 26),
            Text(
              'More',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageMoreMenuItem extends StatelessWidget {
  const _ImageMoreMenuItem({
    required this.leading,
    required this.title,
  });

  final Widget leading;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      horizontalTitleGap: 8,
      minLeadingWidth: 22,
      leading: IconTheme.merge(
        data: const IconThemeData(size: 20),
        child: leading,
      ),
      title: Text(title),
    );
  }
}

enum _ImageMoreAction { info, delete, rename, wallpaper }

class _PlaybackPreview extends StatefulWidget {
  const _PlaybackPreview({
    required this.entry,
    required this.hasPlaylist,
    required this.shuffle,
    required this.landscape,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onToggleLandscape,
    required this.onShowInfo,
  });

  final FileSystemEntry entry;
  final bool hasPlaylist;
  final bool shuffle;
  final bool landscape;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleLandscape;
  final VoidCallback onShowInfo;

  @override
  State<_PlaybackPreview> createState() => _PlaybackPreviewState();
}

class _PlaybackPreviewState extends State<_PlaybackPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;
  Timer? _hideControlsTimer;
  bool _controlsVisible = true;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    final controller = localMediaControllerForPath(widget.entry.path);
    _controller = controller;
    if (controller == null) {
      _initialization = Future<void>.error(
        UnsupportedError('Local media playback is unavailable'),
      );
      return;
    }
    controller.addListener(_handlePlaybackTick);
    _initialization = controller.initialize().then((_) {
      controller.setLooping(false);
      _wasPlaying = controller.value.isPlaying;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    final controller = _controller;
    _hideControlsTimer?.cancel();
    controller?.removeListener(_handlePlaybackTick);
    controller?.dispose();
    _wakelockChannel.invokeMethod<void>('disable');
    super.dispose();
  }

  void _handlePlaybackTick() {
    final controller = _controller;
    final isPlaying = controller?.value.isPlaying ?? false;
    if (isPlaying && !_wasPlaying) {
      _scheduleControlsHide();
      _wakelockChannel.invokeMethod<void>('enable');
    } else if (!isPlaying && _wasPlaying) {
      _hideControlsTimer?.cancel();
      _controlsVisible = true;
      _wakelockChannel.invokeMethod<void>('disable');
    }
    _wasPlaying = isPlaying;

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleControls() {
    if (!_controlsVisible) {
      _showControlsTemporarily();
      return;
    }
    _hideControlsTimer?.cancel();
    setState(() => _controlsVisible = false);
  }

  void _showControlsTemporarily() {
    _hideControlsTimer?.cancel();
    setState(() => _controlsVisible = true);
    _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    if (widget.entry.type != FileSystemEntryType.video ||
        !(_controller?.value.isPlaying ?? false)) {
      return;
    }
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingIndicator();
        }
        if (snapshot.hasError || controller == null) {
          return _PreviewError(
            icon: widget.entry.type == FileSystemEntryType.audio
                ? Icons.music_off_rounded
                : Icons.videocam_off_rounded,
            title: widget.entry.type == FileSystemEntryType.audio
                ? 'Could not play audio'
                : 'Could not play video',
            detail: '${snapshot.error}',
          );
        }

        if (widget.entry.type == FileSystemEntryType.video) {
          return _VideoPlayerSurface(
            controller: controller,
            hasPlaylist: widget.hasPlaylist,
            shuffle: widget.shuffle,
            landscape: widget.landscape,
            onPrevious: widget.onPrevious,
            onNext: widget.onNext,
            onToggleShuffle: widget.onToggleShuffle,
            onToggleLandscape: widget.onToggleLandscape,
            onShowInfo: widget.onShowInfo,
            controlsVisible: _controlsVisible || !controller.value.isPlaying,
            onToggleControls: _toggleControls,
            onShowControls: _showControlsTemporarily,
          );
        }

        return _AudioPlayerSurface(
          entry: widget.entry,
          controller: controller,
          hasPlaylist: widget.hasPlaylist,
          shuffle: widget.shuffle,
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
          onToggleShuffle: widget.onToggleShuffle,
          onShowInfo: widget.onShowInfo,
        );
      },
    );
  }
}

class _VideoPlayerSurface extends StatefulWidget {
  const _VideoPlayerSurface({
    required this.controller,
    required this.hasPlaylist,
    required this.shuffle,
    required this.landscape,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onToggleLandscape,
    required this.onShowInfo,
    required this.controlsVisible,
    required this.onToggleControls,
    required this.onShowControls,
  });

  final VideoPlayerController controller;
  final bool hasPlaylist;
  final bool shuffle;
  final bool landscape;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleLandscape;
  final VoidCallback onShowInfo;
  final bool controlsVisible;
  final VoidCallback onToggleControls;
  final VoidCallback onShowControls;

  @override
  State<_VideoPlayerSurface> createState() => _VideoPlayerSurfaceState();
}

class _VideoPlayerSurfaceState extends State<_VideoPlayerSurface> {
  Offset? _ripplePosition;
  int _rippleKey = 0;
  DateTime? _lastTapAt;
  Offset? _lastTapPosition;
  bool _isDragging = false;
  Timer? _pendingToggle;

  void _onPointerDown(PointerDownEvent event) {
    if (_isDragging) return;
    _handleTap(event.localPosition);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.distance > 8) {
      _isDragging = true;
      _lastTapAt = null;
      _pendingToggle = null;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _isDragging = false;
  }

  void _handleTap(Offset position) {
    final now = DateTime.now();

    if (_lastTapAt != null &&
        now.difference(_lastTapAt!).inMilliseconds < 500) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final isLeft = _lastTapPosition!.dx < screenWidth / 2;
      _seekBy(
        widget.controller,
        Duration(seconds: isLeft ? -10 : 10),
      );
      widget.onShowControls();
      setState(() {
        _ripplePosition = _lastTapPosition;
        _rippleKey++;
      });
      _pendingToggle?.cancel();
      _pendingToggle = null;
      _lastTapAt = now;
      _lastTapPosition = position;
      return;
    }

    _lastTapAt = now;
    _lastTapPosition = position;
    _pendingToggle?.cancel();
    _pendingToggle = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _lastTapAt == now) {
        widget.onToggleControls();
        _lastTapAt = null;
        _lastTapPosition = null;
      }
    });
  }

  @override
  void dispose() {
    _pendingToggle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isPaused = !controller.value.isPlaying;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: _VideoFrame(controller: controller),
            ),
          ),
          if (_ripplePosition != null)
            Positioned(
              left: _ripplePosition!.dx - 80,
              top: _ripplePosition!.dy - 80,
              child: IgnorePointer(
                child: _DoubleTapRipple(
                  key: ValueKey(_rippleKey),
                ),
              ),
            ),
          IgnorePointer(
            ignoring: !widget.controlsVisible,
            child: AnimatedOpacity(
              opacity: widget.controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Color(0x00000000),
                      Color(0x99000000),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !widget.controlsVisible,
            child: AnimatedOpacity(
              opacity: widget.controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Center(
                child: _TransportButtons(
                  controller: controller,
                  largePlayButton: true,
                  foregroundColor: Colors.white,
                  hasPlaylist: widget.hasPlaylist,
                  onPrevious: widget.onPrevious,
                  onNext: widget.onNext,
                  onInteraction: widget.onShowControls,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !widget.controlsVisible,
              child: AnimatedOpacity(
                opacity: widget.controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: _PlaybackControls(
                  controller: controller,
                  overlay: true,
                  showTransport: false,
                  hasPlaylist: widget.hasPlaylist,
                  shuffle: widget.shuffle,
                  landscape: widget.landscape,
                  onPrevious: widget.onPrevious,
                  onNext: widget.onNext,
                  onToggleShuffle: widget.onToggleShuffle,
                  onToggleLandscape: widget.onToggleLandscape,
                  onInteraction: widget.onShowControls,
                  onShowInfo: isPaused ? widget.onShowInfo : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleTapRipple extends StatefulWidget {
  const _DoubleTapRipple({super.key});

  @override
  State<_DoubleTapRipple> createState() => _DoubleTapRippleState();
}

class _DoubleTapRippleState extends State<_DoubleTapRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _RipplePainter(
              progress: _controller.value,
              maxRadius: 80.0,
            ),
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress, required this.maxRadius});

  final double progress;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final rawAspectRatio = value.aspectRatio;
    final rotation = value.rotationCorrection % 180;
    final aspectRatio = rotation == 0 ? rawAspectRatio : 1 / rawAspectRatio;

    return AspectRatio(
      aspectRatio: aspectRatio == 0 ? 16 / 9 : aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}

class _AudioPlayerSurface extends StatelessWidget {
  const _AudioPlayerSurface({
    required this.entry,
    required this.controller,
    required this.hasPlaylist,
    required this.shuffle,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onShowInfo,
  });

  final FileSystemEntry entry;
  final VideoPlayerController controller;
  final bool hasPlaylist;
  final bool shuffle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onShowInfo;

  @override
  Widget build(BuildContext context) {
    final color = colorForFileSystemEntry(context, entry);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 156,
                    height: 156,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      size: 86,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    entry.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _VolumeControl(controller: controller),
        _PlaybackControls(
          controller: controller,
          hasPlaylist: hasPlaylist,
          shuffle: shuffle,
          onPrevious: onPrevious,
          onNext: onNext,
          onToggleShuffle: onToggleShuffle,
          onShowInfo: onShowInfo,
        ),
      ],
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final volume = controller.value.volume.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            tooltip: volume == 0 ? 'Unmute' : 'Mute',
            onPressed: () {
              controller.setVolume(volume == 0 ? 1 : 0);
            },
            icon: Icon(
              volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
          ),
          Expanded(
            child: Slider(
              value: volume,
              onChanged: controller.setVolume,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.controller,
    required this.hasPlaylist,
    required this.shuffle,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleShuffle,
    this.overlay = false,
    this.showTransport = true,
    this.landscape = false,
    this.onToggleLandscape,
    this.onInteraction,
    this.onShowInfo,
  });

  final VideoPlayerController controller;
  final bool hasPlaylist;
  final bool shuffle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final bool overlay;
  final bool showTransport;
  final bool landscape;
  final VoidCallback? onToggleLandscape;
  final VoidCallback? onInteraction;
  final VoidCallback? onShowInfo;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    final durationMs = duration.inMilliseconds;
    final positionMs = position.inMilliseconds.clamp(0, durationMs);

    final textColor = overlay ? Colors.white : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTransport) ...[
              _TransportButtons(
                controller: controller,
                hasPlaylist: hasPlaylist,
                onPrevious: onPrevious,
                onNext: onNext,
                onInteraction: onInteraction,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(color: textColor),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Slider(
                        value: durationMs == 0 ? 0 : positionMs.toDouble(),
                        max: durationMs == 0 ? 1 : durationMs.toDouble(),
                        onChanged: durationMs == 0
                            ? null
                            : (value) {
                                controller.seekTo(
                                  Duration(milliseconds: value.round()),
                                );
                                onInteraction?.call();
                              },
                      );
                    },
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: controller.value.isLooping ? 'Loop on' : 'Loop off',
                  color: textColor,
                  isSelected: controller.value.isLooping,
                  selectedIcon: const Icon(Icons.repeat_one_rounded),
                  onPressed: () {
                    controller.setLooping(!controller.value.isLooping);
                    onInteraction?.call();
                  },
                  icon: const Icon(Icons.repeat_rounded),
                ),
                IconButton(
                  tooltip: shuffle ? 'Shuffle on' : 'Shuffle off',
                  color: textColor,
                  isSelected: shuffle,
                  selectedIcon: const Icon(Icons.shuffle_on_rounded),
                  onPressed: hasPlaylist
                      ? () {
                          onToggleShuffle();
                          onInteraction?.call();
                        }
                      : null,
                  icon: const Icon(Icons.shuffle_rounded),
                ),
                if (onToggleLandscape != null)
                  IconButton(
                    tooltip: landscape ? 'Auto rotate' : 'Landscape',
                    color: textColor,
                    onPressed: () {
                      onToggleLandscape?.call();
                      onInteraction?.call();
                    },
                    icon: Icon(
                      landscape
                          ? Icons.screen_rotation_alt_rounded
                          : Icons.screen_rotation_rounded,
                    ),
                  ),
                _MuteButton(
                  controller: controller,
                  iconColor: textColor,
                  onInteraction: onInteraction,
                ),
                const Spacer(),
                _PlaybackSpeedMenu(
                  controller: controller,
                  foregroundColor: textColor,
                ),
                if (onShowInfo != null)
                  IconButton(
                    tooltip: 'Media information',
                    color: textColor,
                    onPressed: () {
                      onShowInfo?.call();
                      onInteraction?.call();
                    },
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransportButtons extends StatelessWidget {
  const _TransportButtons({
    required this.controller,
    required this.hasPlaylist,
    required this.onPrevious,
    required this.onNext,
    this.largePlayButton = false,
    this.foregroundColor,
    this.onInteraction,
  });

  final VideoPlayerController controller;
  final bool hasPlaylist;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool largePlayButton;
  final Color? foregroundColor;
  final VoidCallback? onInteraction;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final iconColor = foregroundColor;
    final playIconSize = largePlayButton ? 46.0 : 30.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlaybackIconButton(
          tooltip: 'Start',
          icon: Icons.first_page_rounded,
          iconColor: iconColor,
          onPressed: () {
            controller.seekTo(Duration.zero);
            onInteraction?.call();
          },
        ),
        if (hasPlaylist)
          _PlaybackIconButton(
            tooltip: 'Previous',
            icon: Icons.skip_previous_rounded,
            iconColor: iconColor,
            onPressed: () {
              onPrevious();
              onInteraction?.call();
            },
          ),
        _PlaybackIconButton(
          tooltip: 'Back 10 seconds',
          icon: Icons.replay_10_rounded,
          iconColor: iconColor,
          onPressed: () {
            _seekBy(controller, const Duration(seconds: -10));
            onInteraction?.call();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: IconButton.filled(
            tooltip: value.isPlaying ? 'Pause' : 'Play',
            iconSize: playIconSize,
            style: IconButton.styleFrom(
              backgroundColor: largePlayButton
                  ? const Color(0xCCFFFFFF)
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: largePlayButton ? Colors.black : null,
            ),
            onPressed: () {
              value.isPlaying ? controller.pause() : controller.play();
              onInteraction?.call();
            },
            icon: Icon(
              value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
        ),
        _PlaybackIconButton(
          tooltip: 'Forward 10 seconds',
          icon: Icons.forward_10_rounded,
          iconColor: iconColor,
          onPressed: () {
            _seekBy(controller, const Duration(seconds: 10));
            onInteraction?.call();
          },
        ),
        if (hasPlaylist)
          _PlaybackIconButton(
            tooltip: 'Next',
            icon: Icons.skip_next_rounded,
            iconColor: iconColor,
            onPressed: () {
              onNext();
              onInteraction?.call();
            },
          ),
        _PlaybackIconButton(
          tooltip: 'End',
          icon: Icons.last_page_rounded,
          iconColor: iconColor,
          onPressed: () {
            controller.seekTo(controller.value.duration);
            onInteraction?.call();
          },
        ),
      ],
    );
  }
}

class _PlaybackIconButton extends StatelessWidget {
  const _PlaybackIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      color: iconColor,
      iconSize: 32,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _MuteButton extends StatefulWidget {
  const _MuteButton({
    required this.controller,
    this.iconColor,
    this.onInteraction,
  });

  final VideoPlayerController controller;
  final Color? iconColor;
  final VoidCallback? onInteraction;

  @override
  State<_MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<_MuteButton> {
  double _previousVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    final isMuted = widget.controller.value.volume == 0;

    return IconButton(
      tooltip: isMuted ? 'Unmute' : 'Mute',
      color: widget.iconColor,
      iconSize: 32,
      onPressed: () {
        if (isMuted) {
          widget.controller.setVolume(_previousVolume);
        } else {
          _previousVolume = widget.controller.value.volume;
          widget.controller.setVolume(0);
        }
        widget.onInteraction?.call();
      },
      icon: Icon(isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
    );
  }
}

class _PlaybackSpeedMenu extends StatelessWidget {
  const _PlaybackSpeedMenu({
    required this.controller,
    this.foregroundColor,
  });

  final VideoPlayerController controller;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final speed = controller.value.playbackSpeed;

    return PopupMenuButton<double>(
      tooltip: 'Playback speed',
      initialValue: speed,
      onSelected: controller.setPlaybackSpeed,
      itemBuilder: (context) {
        return const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
            .map(
              (speed) => PopupMenuItem<double>(
                value: speed,
                child: Text('${speed}x'),
              ),
            )
            .toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '${speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 2)}x',
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MediaDetails extends StatelessWidget {
  const _MediaDetails({required this.entry});

  final FileSystemEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: ListTile(
          leading: Icon(
            iconForFileSystemEntry(entry),
            color: colorForFileSystemEntry(context, entry),
          ),
          title: Text(entry.path, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${typeLabelForFileSystemEntry(entry)} | '
            '${formatBytes(entry.sizeBytes ?? 0)} | '
            '${formatFileModifiedAt(entry.modifiedAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _UnsupportedPreview extends StatelessWidget {
  const _UnsupportedPreview({
    required this.entry,
    required this.onOpenWith,
  });

  final FileSystemEntry entry;
  final VoidCallback onOpenWith;

  @override
  Widget build(BuildContext context) {
    return _PreviewError(
      icon: iconForFileSystemEntry(entry),
      title: 'Preview unavailable',
      detail: typeLabelForFileSystemEntry(entry),
      action: FilledButton.icon(
        onPressed: onOpenWith,
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Open with'),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

void _seekBy(VideoPlayerController controller, Duration delta) {
  final value = controller.value;
  final durationMs = value.duration.inMilliseconds;
  final targetMs = value.position.inMilliseconds + delta.inMilliseconds;
  final boundedMs = targetMs < 0
      ? 0
      : targetMs > durationMs
          ? durationMs
          : targetMs;
  controller.seekTo(Duration(milliseconds: boundedMs));
}

bool _canPreview(FileSystemEntry entry) {
  return switch (entry.type) {
    FileSystemEntryType.image ||
    FileSystemEntryType.video ||
    FileSystemEntryType.audio =>
      true,
    _ => false,
  };
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours == 0) {
    return '$minutes:$seconds';
  }
  return '$hours:$minutes:$seconds';
}
