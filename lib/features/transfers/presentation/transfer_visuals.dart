import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:flutter/material.dart';

IconData iconForTransferOperation(TransferOperation operation) {
  return switch (operation) {
    TransferOperation.copy => Icons.content_copy_rounded,
    TransferOperation.move => Icons.drive_file_move_rounded,
    TransferOperation.delete => Icons.delete_outline_rounded,
    TransferOperation.moveToTrash => Icons.restore_from_trash_rounded,
    TransferOperation.rename => Icons.edit_rounded,
    TransferOperation.extractArchive => Icons.archive_rounded,
    TransferOperation.compressArchive => Icons.inventory_2_rounded,
    TransferOperation.encrypt => Icons.lock_rounded,
    TransferOperation.decrypt => Icons.lock_open_rounded,
  };
}

Color colorForTransferOperation(TransferOperation operation) {
  return switch (operation) {
    TransferOperation.copy => const Color(0xFF1E88E5),
    TransferOperation.move => const Color(0xFF3949AB),
    TransferOperation.delete => const Color(0xFFE53935),
    TransferOperation.moveToTrash => const Color(0xFF8D6E63),
    TransferOperation.rename => const Color(0xFF00897B),
    TransferOperation.extractArchive => const Color(0xFF6D4C41),
    TransferOperation.compressArchive => const Color(0xFF8D6E63),
    TransferOperation.encrypt => const Color(0xFF546E7A),
    TransferOperation.decrypt => const Color(0xFF546E7A),
  };
}

Color colorForTransferStatus(
  BuildContext context,
  TransferTaskStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    TransferTaskStatus.failed => _failedRed,
    TransferTaskStatus.completed => _doneGreen,
    TransferTaskStatus.cancelled => scheme.outline,
    TransferTaskStatus.running => scheme.primary,
    TransferTaskStatus.awaitingDestination ||
    TransferTaskStatus.queued =>
      _pendingBlue,
  };
}

const _doneGreen = Color(0xFF43A047);
const _pendingBlue = Color(0xFF1E88E5);
const _failedRed = Color(0xFFE53935);
