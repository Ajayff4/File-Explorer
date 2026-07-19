import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/entry_sorting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sorts by name with folders first', () {
    final entries = [
      _file('zeta.txt'),
      _folder('Beta'),
      _file('alpha.txt'),
      _folder('Archive'),
    ];

    final sorted = sortExplorerEntries(
      entries,
      option: ExplorerSortOption.nameAscending,
    );

    expect(sorted.map((entry) => entry.name), [
      'Archive',
      'Beta',
      'alpha.txt',
      'zeta.txt',
    ]);
  });

  test('sorts files by largest size', () {
    final entries = [
      _file('small.bin', sizeBytes: 10),
      _file('large.bin', sizeBytes: 100),
      _file('medium.bin', sizeBytes: 50),
    ];

    final sorted = sortExplorerEntries(
      entries,
      option: ExplorerSortOption.sizeLargest,
    );

    expect(sorted.map((entry) => entry.name), [
      'large.bin',
      'medium.bin',
      'small.bin',
    ]);
  });

  test('sorts by newest modified date', () {
    final entries = [
      _file('old.txt', modifiedAt: DateTime(2024)),
      _file('new.txt', modifiedAt: DateTime(2026)),
      _file('middle.txt', modifiedAt: DateTime(2025)),
    ];

    final sorted = sortExplorerEntries(
      entries,
      option: ExplorerSortOption.modifiedNewest,
    );

    expect(sorted.map((entry) => entry.name), [
      'new.txt',
      'middle.txt',
      'old.txt',
    ]);
  });
}

FileSystemEntry _folder(String name) {
  return FileSystemEntry(
    name: name,
    path: '/storage/emulated/0/$name',
    type: FileSystemEntryType.folder,
    modifiedAt: DateTime(2026),
  );
}

FileSystemEntry _file(
  String name, {
  int sizeBytes = 0,
  DateTime? modifiedAt,
}) {
  return FileSystemEntry(
    name: name,
    path: '/storage/emulated/0/$name',
    type: FileSystemEntryType.document,
    modifiedAt: modifiedAt ?? DateTime(2026),
    sizeBytes: sizeBytes,
  );
}
