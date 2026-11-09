import 'package:file_explorer/features/explorer/presentation/widgets/explorer_drag_and_drop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExplorerDragData data(List<String> paths) {
    return ExplorerDragData(sourcePaths: paths, displayName: 'items');
  }

  test('accepts a drag onto a sibling folder', () {
    expect(
      canDropExplorerEntries(
        data(['/storage/emulated/0/Pictures/a.jpg']),
        '/storage/emulated/0/Downloads',
      ),
      isTrue,
    );
  });

  test('rejects an empty drag', () {
    expect(
      canDropExplorerEntries(data(const []), '/storage/emulated/0/Downloads'),
      isFalse,
    );
  });

  test('rejects dropping an entry onto itself', () {
    expect(
      canDropExplorerEntries(
        data(['/storage/emulated/0/Pictures']),
        '/storage/emulated/0/Pictures',
      ),
      isFalse,
    );
  });

  test('rejects dropping a folder into its own descendant', () {
    expect(
      canDropExplorerEntries(
        data(['/storage/emulated/0/Pictures']),
        '/storage/emulated/0/Pictures/Vacation',
      ),
      isFalse,
    );
  });

  test('rejects the whole drag when any source is the destination', () {
    expect(
      canDropExplorerEntries(
        data([
          '/storage/emulated/0/Documents/a.txt',
          '/storage/emulated/0/Downloads',
        ]),
        '/storage/emulated/0/Downloads',
      ),
      isFalse,
    );
  });
}
