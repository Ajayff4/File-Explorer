import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:file_explorer/features/history_backup/presentation/history_backup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings card for the history backup: status line plus a manual export.
class HistoryBackupCard extends ConsumerWidget {
  const HistoryBackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyBackupControllerProvider);
    final controller = ref.read(historyBackupControllerProvider.notifier);

    final subtitle = switch (state) {
      HistoryBackupState(unavailable: true) =>
        'Needs shared-storage access on this device',
      HistoryBackupState(isWorking: true) => 'Backing up…',
      HistoryBackupState(lastBackupAt: final at?) =>
        'Last backup ${_relative(at)} · File Explorer/.history',
      _ => 'Auto-saves to File Explorer/.history · restores on reinstall',
    };

    return NeumorphicCard(
      child: ListTile(
        title: const Text('History backup'),
        subtitle: Text(subtitle),
        trailing: state.isWorking
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : FilledButton.tonal(
                onPressed: () async {
                  final ok = await controller.exportNow();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'History backed up to File Explorer/.history'
                            : 'Nothing to back up yet, or storage unavailable',
                      ),
                    ),
                  );
                },
                child: const Text('Back up now'),
              ),
      ),
    );
  }

  String _relative(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${at.year}-${at.month.toString().padLeft(2, '0')}-'
        '${at.day.toString().padLeft(2, '0')}';
  }
}
