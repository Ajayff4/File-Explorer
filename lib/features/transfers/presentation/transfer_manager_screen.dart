import 'package:flutter/material.dart';

class TransferManagerScreen extends StatelessWidget {
  const TransferManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TransferSummaryCard(),
          SizedBox(height: 12),
          _TransferTile(
            title: 'Photo backup',
            subtitle: 'Queued for local copy',
            icon: Icons.cloud_upload_outlined,
            progress: 0.36,
          ),
          _TransferTile(
            title: 'LAN receive',
            subtitle: 'Waiting for peer',
            icon: Icons.wifi_tethering_outlined,
            progress: 0,
          ),
        ],
      ),
    );
  }
}

class _TransferSummaryCard extends StatelessWidget {
  const _TransferSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.sync_alt_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unified transfer queue',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text('New'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress == 0 ? null : progress),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Pause',
          onPressed: () {},
          icon: const Icon(Icons.pause_rounded),
        ),
      ),
    );
  }
}
