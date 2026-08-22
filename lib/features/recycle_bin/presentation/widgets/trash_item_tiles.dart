import 'package:file_explorer/app/theme/neumorphic_card.dart';
import 'package:file_explorer/features/recycle_bin/domain/entities/trash_item.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';

String formatTrashDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class TrashItemListTile extends StatelessWidget {
  const TrashItemListTile({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  final TrashItem item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final subtitle = item.originalPath.isEmpty
        ? formatTrashDate(item.deletedAt)
        : '${item.originalPath}\n${formatTrashDate(item.deletedAt)}';

    return NeumorphicCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: selected,
        leading: selectionMode
            ? Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
              )
            : Icon(
                item.isFolder
                    ? Icons.folder_rounded
                    : Icons.insert_drive_file_rounded,
                color: colors.primary,
              ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: selectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.sizeBytes != null)
                    Text(
                      formatBytes(item.sizeBytes!),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  IconButton(
                    tooltip: 'Restore',
                    onPressed: item.canRestore ? onRestore : null,
                    icon: const Icon(Icons.restore_rounded),
                  ),
                  IconButton(
                    tooltip: 'Delete permanently',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class TrashItemGridTile extends StatelessWidget {
  const TrashItemGridTile({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final TrashItem item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: Icon(
                        item.isFolder
                            ? Icons.folder_rounded
                            : Icons.insert_drive_file_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (item.sizeBytes != null)
                    SizedBox(
                      height: 16,
                      child: Text(
                        formatBytes(item.sizeBytes!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
            if (selectionMode)
              Positioned(
                top: 0,
                left: 0,
                child: Checkbox(
                  visualDensity: VisualDensity.compact,
                  value: selected,
                  onChanged: (_) => onTap(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
