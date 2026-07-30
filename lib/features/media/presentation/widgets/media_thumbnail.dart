import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/presentation/widgets/media_thumbnail_stub.dart'
    if (dart.library.io) 'package:file_explorer/features/media/presentation/widgets/media_thumbnail_io.dart';
import 'package:flutter/material.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    required this.entry,
    required this.fallbackIcon,
    this.fallbackColor,
    super.key,
  });

  final FileSystemEntry entry;
  final IconData fallbackIcon;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: mediaThumbnailFor(
            entry: entry,
            fallback: Icon(fallbackIcon, color: fallbackColor),
          ),
        ),
      ),
    );
  }
}
