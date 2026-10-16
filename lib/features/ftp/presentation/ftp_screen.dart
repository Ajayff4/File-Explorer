import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/app/theme/glass.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/presentation/controllers/ftp_controller.dart';
import 'package:file_explorer/features/ftp/presentation/widgets/ftp_connection_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Saved FTP / SFTP / FTPS connections. CRUD only for now; live browsing
/// connects later on top of [FtpConnection].
class FtpScreen extends ConsumerWidget {
  const FtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ftpControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('FTP connections'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: state.isLoading && state.connections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.connections.isEmpty
              ? _EmptyView(onAdd: () => _showForm(context, ref, null))
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(ftpControllerProvider.notifier)
                      .loadConnections(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: state.connections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final connection = state.connections[index];
                      return _ConnectionTile(connection: connection);
                    },
                  ),
                ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref,
    FtpConnection? existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FtpConnectionForm(
          existing: existing,
          onSave: (connection) async {
            try {
              await ref
                  .read(ftpControllerProvider.notifier)
                  .saveConnection(connection);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      existing == null ? 'Connection added' : 'Connection saved',
                    ),
                  ),
                );
              }
            } on ArgumentError catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message)),
                );
              }
            }
          },
        );
      },
    );
  }
}

class _ConnectionTile extends ConsumerWidget {
  const _ConnectionTile({required this.connection});

  final FtpConnection connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassTile(
      child: ListTile(
        leading: GlassIconChip(
          icon: _iconFor(connection.protocol),
          color: Theme.of(context).colorScheme.primary,
          size: 44,
        ),
        title: Text(
          connection.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${connection.protocol.label} · ${connection.address}'
          '${connection.username.isEmpty ? '' : ' · ${connection.username}'}'
          '${connection.privateKeyFileName == null ? '' : ' · ${connection.privateKeyFileName}'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        onTap: () => context.push(
              AppRoutes.ftpBrowse(connection.id),
              extra: connection,
            ),
      ),
    );
  }

  IconData _iconFor(FtpProtocol protocol) {
    return switch (protocol) {
      FtpProtocol.ftp => Icons.dns_rounded,
      FtpProtocol.sftp => Icons.lock_rounded,
      FtpProtocol.ftps => Icons.verified_user_outlined,
    };
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FtpConnectionForm(
          existing: connection,
          onSave: (updated) async {
            try {
              await ref
                  .read(ftpControllerProvider.notifier)
                  .saveConnection(updated);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            } on ArgumentError catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message)),
                );
              }
            }
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete connection?'),
        content: Text('Remove "${connection.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(ftpControllerProvider.notifier)
        .deleteConnection(connection.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection deleted')),
      );
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassIconChip(
              icon: Icons.dns_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No FTP connections yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add FTP, SFTP, or FTPS servers to reach them quickly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add connection'),
            ),
          ],
        ),
      ),
    );
  }
}
