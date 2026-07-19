import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:flutter/material.dart';

IconData iconForTransferOperation(TransferOperation operation) {
  return switch (operation) {
    TransferOperation.copy => Icons.content_copy_rounded,
    TransferOperation.move => Icons.drive_file_move_rounded,
    TransferOperation.delete => Icons.delete_outline_rounded,
    TransferOperation.rename => Icons.edit_rounded,
  };
}

Color colorForTransferStatus(
  BuildContext context,
  TransferTaskStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    TransferTaskStatus.failed => scheme.error,
    TransferTaskStatus.completed => scheme.tertiary,
    TransferTaskStatus.cancelled => scheme.outline,
    TransferTaskStatus.awaitingDestination ||
    TransferTaskStatus.queued ||
    TransferTaskStatus.running =>
      scheme.primary,
  };
}
