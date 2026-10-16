import 'package:file_explorer/app/theme/glass.dart';
import 'package:file_explorer/features/ftp/domain/entities/ftp_connection.dart';
import 'package:file_explorer/features/ftp/domain/entities/remote_entry.dart';
import 'package:file_explorer/features/ftp/presentation/controllers/ftp_browser_controller.dart';
import 'package:file_explorer/features/ftp/presentation/controllers/ftp_controller.dart';
import 'package:file_explorer/features/ftp/presentation/remote_preview.dart';
import 'package:file_explorer/features/ftp/presentation/widgets/remote_thumbnail.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Live file browser for one saved server connection.
///
/// The route carries the connection id (`/ftp/browse/:id`) so the screen
/// survives route restores that drop `extra` (window remounts, new windows).
/// [initialConnection] avoids a store-load race on first open; otherwise the
/// connection resolves from the saved store, tolerating a missing entry.
class FtpBrowserScreen extends ConsumerWidget {
  const FtpBrowserScreen({
    required this.connectionId,
    this.initialConnection,
    super.key,
  });

  final String connectionId;
  final FtpConnection? initialConnection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(ftpControllerProvider);
    final connection =
        initialConnection ?? store.connectionFor(connectionId);
    if (connection == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/ftp');
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('FTP connection'),
        ),
        body: Center(
          child: store.isLoading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Loading'),
                  ],
                )
              : const Text('Connection not found'),
        ),
      );
    }
    return _FtpBrowserView(connection: connection);
  }
}

class _FtpBrowserView extends ConsumerWidget {
  const _FtpBrowserView({required this.connection});

  final FtpConnection connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ftpBrowserControllerProvider(connection));
    final controller =
        ref.read(ftpBrowserControllerProvider(connection).notifier);

    return BackButtonListener(
      onBackButtonPressed: () async {
        // Only intercept when this route is on top; a pushed viewer
        // above us must receive the back press instead.
        if (ModalRoute.of(context)?.isCurrent != true) return false;
        // System back walks up folders first, exits only at root.
        if (state.canGoUp && !state.isConnecting) {
          await controller.goUp();
          return true;
        }
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (state.canGoUp && !state.isConnecting) {
              controller.goUp();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/ftp');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(connection.name),
            Text(
              '${connection.protocol.label} · ${state.currentPath}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: state.isGrid ? 'List view' : 'Grid view',
            onPressed:
                state.isConnecting ? null : () => controller.toggleView(),
            icon: Icon(
              state.isGrid
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                state.isConnecting ? null : () => controller.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: switch (state) {
        FtpBrowserState(isConnecting: true) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Connecting'),
              ],
            ),
          ),
        FtpBrowserState(error: final error?) when state.entries.isEmpty =>
          _ErrorView(
            error: error,
            onRetry: () => controller.connect(),
          ),
        _ => RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: state.entries.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: state.isLoading
                            ? const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text('Loading'),
                                ],
                              )
                            : const Text('Empty folder'),
                      ),
                    ],
                  )
                : state.isGrid
                    ? GridView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: state.entries.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final entry = state.entries[index];
                          return _EntryGridTile(
                            connection: connection,
                            entry: entry,
                            onOpen: () =>
                                controller.openDirectory(entry.path),
                          );
                        },
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: state.entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final entry = state.entries[index];
                          return _EntryTile(
                            connection: connection,
                            entry: entry,
                            onOpen: () =>
                                controller.openDirectory(entry.path),
                          );
                        },
                      ),
          ),
      },
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({
    required this.connection,
    required this.entry,
    required this.onOpen,
  });

  final FtpConnection connection;
  final RemoteEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return GlassTile(
      child: ListTile(
        leading: RemoteThumbnail(
          connection: connection,
          entry: entry,
          size: 44,
          fallback: GlassIconChip(
            icon: entry.isDirectory
                ? Icons.folder_rounded
                : Icons.insert_drive_file_outlined,
            color: entry.isDirectory ? Colors.amber : scheme.primary,
            size: 44,
          ),
        ),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: entry.isDirectory
            ? null
            : Text(_details(entry)),
        trailing: entry.isDirectory
            ? const Icon(Icons.chevron_right_rounded)
            : null,
        onTap: entry.isDirectory
            ? onOpen
            : () => openRemoteFileForPreview(
                  context: context,
                  ref: ref,
                  connection: connection,
                  entry: entry,
                ),
      ),
    );
  }

  String _details(RemoteEntry entry) {
    final parts = <String>[];
    if (entry.sizeBytes != null) parts.add(formatBytes(entry.sizeBytes!));
    if (entry.modifiedAt != null) {
      final modified = entry.modifiedAt!.toLocal();
      parts.add(
        '${modified.year}-${modified.month.toString().padLeft(2, '0')}-'
        '${modified.day.toString().padLeft(2, '0')}',
      );
    }
    return parts.join(' · ');
  }
}

class _EntryGridTile extends ConsumerWidget {
  const _EntryGridTile({
    required this.connection,
    required this.entry,
    required this.onOpen,
  });

  final FtpConnection connection;
  final RemoteEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassTile(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: entry.isDirectory
            ? onOpen
            : () => openRemoteFileForPreview(
                  context: context,
                  ref: ref,
                  connection: connection,
                  entry: entry,
                ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RemoteThumbnail(
                connection: connection,
                entry: entry,
                size: 56,
                fallback: Icon(
                  entry.isDirectory
                      ? Icons.folder_rounded
                      : Icons.insert_drive_file_outlined,
                  size: 40,
                  color: entry.isDirectory
                      ? Colors.amber
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Connection failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
