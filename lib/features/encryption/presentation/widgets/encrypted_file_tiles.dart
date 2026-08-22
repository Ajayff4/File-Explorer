import 'package:file_explorer/features/encryption/data/encryption_repository.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';

class EncryptedFileListTile extends StatelessWidget {
  const EncryptedFileListTile({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final EncryptedFileEntry item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.sizeBytes != null
        ? '${formatBytes(item.sizeBytes!)} · ${item.path}'
        : item.path;

    return ListTile(
      selected: selected,
      leading: selectionMode
          ? Checkbox(value: selected, onChanged: (_) => onTap())
          : const Icon(Icons.lock_rounded),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class EncryptedFileGridTile extends StatelessWidget {
  const EncryptedFileGridTile({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final EncryptedFileEntry item;
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
                        Icons.lock_rounded,
                        size: 40,
                        color: colorScheme.onSurfaceVariant,
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
