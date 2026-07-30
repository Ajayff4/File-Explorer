import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:flutter/widgets.dart';

Widget mediaThumbnailFor({
  required FileSystemEntry entry,
  required Widget fallback,
}) {
  return Center(child: fallback);
}
