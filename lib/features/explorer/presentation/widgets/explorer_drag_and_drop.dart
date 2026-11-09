import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

/// Payload carried by an Explorer drag. The copy-vs-move decision is made on
/// drop (Ctrl = copy) so the modifier can change while dragging.
class ExplorerDragData {
  const ExplorerDragData({
    required this.sourcePaths,
    required this.displayName,
  });

  final List<String> sourcePaths;
  final String displayName;
}

/// Wraps an Explorer entry so it can be dragged onto a folder target.
/// Dragging is only enabled while in selection mode; long-press outside of
/// selection mode keeps its existing select-entry behavior.
class ExplorerDragSource extends StatelessWidget {
  const ExplorerDragSource({
    required this.entry,
    required this.selectedPaths,
    required this.isSelectionMode,
    required this.child,
    super.key,
  });

  final FileSystemEntry entry;
  final List<String> selectedPaths;
  final bool isSelectionMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isSelectionMode) {
      return child;
    }

    final isPartOfSelection = selectedPaths.contains(entry.path);
    final sourcePaths =
        isPartOfSelection ? selectedPaths : <String>[entry.path];
    final label = sourcePaths.length == 1
        ? p.basename(sourcePaths.single)
        : '${sourcePaths.length} items';

    return LongPressDraggable<ExplorerDragData>(
      data: ExplorerDragData(
        sourcePaths: List.unmodifiable(sourcePaths),
        displayName: label,
      ),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      hapticFeedbackOnStart: true,
      feedback: _DragFeedback(label: label, isFolder: entry.isFolder),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.label, required this.isFolder});

  final String label;
  final bool isFolder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      elevation: 12,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFolder ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accepts Explorer drags onto a folder and queues the matching copy/move
/// transfer. Highlights its child while a valid drag hovers over it.
class ExplorerDropTarget extends ConsumerWidget {
  const ExplorerDropTarget({
    required this.destinationPath,
    required this.child,
    this.enabled = true,
    super.key,
  });

  final String destinationPath;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) {
      return child;
    }

    return DragTarget<ExplorerDragData>(
      onWillAcceptWithDetails: (details) =>
          canDropExplorerEntries(details.data, destinationPath),
      onAcceptWithDetails: (details) =>
          queueExplorerDrop(context, ref, details.data, destinationPath),
      builder: (context, candidateData, rejectedData) {
        if (candidateData.isEmpty) {
          return child;
        }
        final colorScheme = Theme.of(context).colorScheme;
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

bool canDropExplorerEntries(
  ExplorerDragData data,
  String destinationPath,
) {
  if (data.sourcePaths.isEmpty) {
    return false;
  }
  for (final source in data.sourcePaths) {
    if (source == destinationPath) {
      return false;
    }
    if (destinationPath.startsWith('$source/')) {
      return false;
    }
  }
  return true;
}

void queueExplorerDrop(
  BuildContext context,
  WidgetRef ref,
  ExplorerDragData data,
  String destinationPath,
) {
  final copy = HardwareKeyboard.instance.isControlPressed;
  final operation = copy ? TransferOperation.copy : TransferOperation.move;
  final sources = [
    for (final source in data.sourcePaths)
      if (copy || p.dirname(source) != destinationPath) source,
  ];

  final messenger = ScaffoldMessenger.of(context);
  if (sources.isEmpty) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Already in this folder'),
          persist: false,
        ),
      );
    return;
  }

  final router = GoRouter.of(context);
  ref.read(transferControllerProvider.notifier).queueOperation(
        operation: operation,
        sourcePaths: sources,
        displayName: data.displayName,
        destinationPath: destinationPath,
      );
  ref.read(explorerControllerProvider.notifier).exitSelectionMode();

  final folderName = p.basename(destinationPath);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '${copy ? 'Copying' : 'Moving'} ${data.displayName} to $folderName',
        ),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: 'Transfers',
          onPressed: () => router.go(AppRoutes.transfers),
        ),
      ),
    );
}
