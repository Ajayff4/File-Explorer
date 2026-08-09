import 'package:file_explorer/features/archive/presentation/archive_file_preview_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies image extensions', () {
    expect(kindForArchivePreview('photo.jpg'), ArchivePreviewKind.image);
    expect(kindForArchivePreview('photo.JPEG'), ArchivePreviewKind.image);
    expect(kindForArchivePreview('a.png'), ArchivePreviewKind.image);
    expect(kindForArchivePreview('b.webp'), ArchivePreviewKind.image);
  });

  test('classifies video extensions', () {
    expect(kindForArchivePreview('clip.mp4'), ArchivePreviewKind.video);
    expect(kindForArchivePreview('clip.mkv'), ArchivePreviewKind.video);
    expect(kindForArchivePreview('clip.MOV'), ArchivePreviewKind.video);
  });

  test('classifies audio extensions', () {
    expect(kindForArchivePreview('song.mp3'), ArchivePreviewKind.audio);
    expect(kindForArchivePreview('song.flac'), ArchivePreviewKind.audio);
    expect(kindForArchivePreview('song.WAV'), ArchivePreviewKind.audio);
  });

  test('classifies text extensions as text', () {
    expect(kindForArchivePreview('readme.md'), ArchivePreviewKind.text);
    expect(kindForArchivePreview('notes.txt'), ArchivePreviewKind.text);
    expect(kindForArchivePreview('config.json'), ArchivePreviewKind.text);
  });

  test('classifies unknown extensions as unsupported', () {
    expect(kindForArchivePreview('data.dat'), ArchivePreviewKind.unsupported);
    expect(kindForArchivePreview('archive'), ArchivePreviewKind.unsupported);
  });
}
