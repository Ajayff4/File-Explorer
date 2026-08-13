import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:flutter/material.dart';

class DownloadEntryGrid extends StatelessWidget {
  const DownloadEntryGrid({
    required this.entries,
    required this.onOpen,
    super.key,
  });

  final List<FileSystemEntry> entries;
  final ValueChanged<FileSystemEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = (constraints.maxWidth / 92).floor().clamp(4, 8);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisExtent: 114,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return GridEntryTile(
              entry: entry,
              isSelected: false,
              isSelectionMode: false,
              onToggleSelection: () {},
              onOpen: () => onOpen(entry),
            );
          },
        );
      },
    );
  }
}