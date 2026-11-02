import 'package:file_explorer/features/explorer/domain/batch_rename.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BatchRenameSource file(String name) {
    return BatchRenameSource(path: '/storage/$name', isFolder: false);
  }

  BatchRenameSource folder(String name) {
    return BatchRenameSource(path: '/storage/$name', isFolder: true);
  }

  test('adds a prefix and suffix while preserving the extension', () {
    final preview = buildBatchRenamePreview(
      [file('photo.jpg'), file('notes.txt')],
      const BatchRenameOptions(prefix: 'trip-', suffix: '-2026'),
    );

    expect(preview.changedItems.map((item) => item.newName), [
      'trip-photo-2026.jpg',
      'trip-notes-2026.txt',
    ]);
    expect(preview.canApply, isTrue);
  });

  test('replaces matching text in the name only', () {
    final preview = buildBatchRenamePreview(
      [file('holiday-photo.jpg'), file('holiday-video.mp4')],
      const BatchRenameOptions(find: 'holiday', replace: 'trip'),
    );

    expect(preview.changedItems.map((item) => item.newName), [
      'trip-photo.jpg',
      'trip-video.mp4',
    ]);
  });

  test('numbers renamed items with padding', () {
    final preview = buildBatchRenamePreview(
      [file('a.txt'), file('b.txt'), file('c.txt')],
      const BatchRenameOptions(
        prefix: 'track-',
        numbered: true,
        numberStart: 5,
        numberStep: 2,
        numberPadding: 3,
      ),
    );

    expect(preview.changedItems.map((item) => item.newName), [
      'track-a005.txt',
      'track-b007.txt',
      'track-c009.txt',
    ]);
  });

  test('does not split extensions on folders', () {
    final preview = buildBatchRenamePreview(
      [folder('my.folder')],
      const BatchRenameOptions(prefix: 'old-'),
    );

    expect(preview.changedItems.single.newName, 'old-my.folder');
  });

  test('can rename the extension when preserveExtension is false', () {
    final preview = buildBatchRenamePreview(
      [file('report.txt')],
      const BatchRenameOptions(
          find: 'txt', replace: 'md', preserveExtension: false),
    );

    expect(preview.changedItems.single.newName, 'report.md');
  });

  test('reports duplicate names', () {
    final preview = buildBatchRenamePreview(
      [file('a.txt'), file('A.txt')],
      const BatchRenameOptions(prefix: 'p-'),
    );

    expect(preview.canApply, isFalse);
    expect(
      preview.errors,
      contains('More than one item would be named "p-a.txt"'),
    );
  });

  test('reports invalid names', () {
    final preview = buildBatchRenamePreview(
      [file('a.txt')],
      const BatchRenameOptions(prefix: 'bad/name-'),
    );

    expect(preview.canApply, isFalse);
    expect(preview.errors, hasLength(1));
  });

  test('reports names with surrounding spaces', () {
    final preview = buildBatchRenamePreview(
      [file('a')],
      const BatchRenameOptions(suffix: ' '),
    );

    expect(preview.canApply, isFalse);
    expect(preview.errors.single, contains('begin or end with a space'));
  });

  test('allows options that do not change any names', () {
    final preview = buildBatchRenamePreview(
      [file('a.txt')],
      const BatchRenameOptions(),
    );

    expect(preview.canApply, isFalse);
    expect(preview.errors, isEmpty);
  });

  test('skips unchanged items in changedItems', () {
    final preview = buildBatchRenamePreview(
      [file('a.txt'), file('b.txt')],
      const BatchRenameOptions(find: 'a', replace: 'a'),
    );

    expect(preview.changedItems, isEmpty);
    expect(preview.canApply, isFalse);
  });
}
