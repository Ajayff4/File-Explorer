import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/encryption/data/encryption_service.dart';
import 'package:file_explorer/features/encryption/presentation/encryption_dialogs.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Prompts for encryption options and queues an encrypt task in the transfer
/// center. Non-`.ff4` paths are encrypted; `.ff4` files are ignored.
Future<void> encryptPathsWithDialog(
  BuildContext context,
  WidgetRef ref,
  List<String> paths, {
  String? displayName,
  int itemCount = 1,
  VoidCallback? onDone,
}) async {
  if (paths.isEmpty) return;
  final transferController = ref.read(transferControllerProvider.notifier);
  final regularPaths = paths.where((p) => !isEncryptedFile(p)).toList();
  if (regularPaths.isEmpty) return;

  final options = await showEncryptDialog(
    context,
    itemCount: itemCount,
    displayName: displayName,
  );
  if (options == null || !context.mounted) return;

  transferController.queueOperation(
    operation: TransferOperation.encrypt,
    sourcePaths: regularPaths,
    displayName: displayName ?? '${regularPaths.length} items',
    encryptionPassword: options.password,
    encryptName: options.encryptName,
  );
  _showQueuedSnackBar(context, TransferOperation.encrypt);
  onDone?.call();
}

/// Prompts for the password and queues a decrypt task for a single `.ff4`.
Future<void> decryptPathWithDialog(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  final transferController = ref.read(transferControllerProvider.notifier);
  final password = await showDecryptDialog(
    context,
    fileName: path.split('/').last,
  );
  if (password == null || !context.mounted) return;

  transferController.queueOperation(
    operation: TransferOperation.decrypt,
    sourcePaths: [path],
    displayName: path.split('/').last,
    encryptionPassword: password,
  );
  _showQueuedSnackBar(context, TransferOperation.decrypt);
}

/// Prompts once for the password and queues a decrypt task for every `.ff4`
/// in [paths] (regular files are ignored).
Future<void> decryptPathsWithDialog(
  BuildContext context,
  WidgetRef ref,
  List<String> paths, {
  VoidCallback? onDone,
}) async {
  final transferController = ref.read(transferControllerProvider.notifier);
  final encryptedPaths = paths.where(isEncryptedFile).toList();
  if (encryptedPaths.isEmpty) return;

  final fileName = encryptedPaths.length == 1
      ? encryptedPaths.first.split('/').last
      : '${encryptedPaths.length} encrypted files';
  final password = await showDecryptDialog(context, fileName: fileName);
  if (password == null || !context.mounted) return;

  transferController.queueOperation(
    operation: TransferOperation.decrypt,
    sourcePaths: encryptedPaths,
    displayName: fileName,
    encryptionPassword: password,
  );
  _showQueuedSnackBar(context, TransferOperation.decrypt);
  onDone?.call();
}

void _showQueuedSnackBar(BuildContext context, TransferOperation operation) {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${operation.label} task queued'),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: 'Transfers',
          onPressed: () => router.go(AppRoutes.transfers),
        ),
      ),
    );
}
