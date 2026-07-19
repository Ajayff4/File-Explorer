import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/entry_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hides dot-prefixed entries when hidden files are disabled', () {
    final entries = [
      _entry('.config'),
      _entry('Download'),
      _entry('.nomedia'),
    ];

    final visible = visibleExplorerEntries(
      entries,
      showHiddenFiles: false,
    );

    expect(visible.map((entry) => entry.name), ['Download']);
  });

  test('keeps hidden entries when hidden files are enabled', () {
    final entries = [
      _entry('.config'),
      _entry('Download'),
    ];

    final visible = visibleExplorerEntries(
      entries,
      showHiddenFiles: true,
    );

    expect(visible, entries);
  });
}

FileSystemEntry _entry(String name) {
  return FileSystemEntry(
    name: name,
    path: '/storage/emulated/0/$name',
    type: FileSystemEntryType.folder,
    modifiedAt: DateTime(2026),
  );
}
