import 'package:file_explorer/features/zip/presentation/zip_file_preview_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies image extensions', () {
    expect(kindForZipPreview('photo.jpg'), ZipPreviewKind.image);
    expect(kindForZipPreview('photo.JPEG'), ZipPreviewKind.image);
    expect(kindForZipPreview('a.png'), ZipPreviewKind.image);
    expect(kindForZipPreview('b.webp'), ZipPreviewKind.image);
  });

  test('classifies video extensions', () {
    expect(kindForZipPreview('clip.mp4'), ZipPreviewKind.video);
    expect(kindForZipPreview('clip.mkv'), ZipPreviewKind.video);
    expect(kindForZipPreview('clip.MOV'), ZipPreviewKind.video);
  });

  test('classifies audio extensions', () {
    expect(kindForZipPreview('song.mp3'), ZipPreviewKind.audio);
    expect(kindForZipPreview('song.flac'), ZipPreviewKind.audio);
    expect(kindForZipPreview('song.WAV'), ZipPreviewKind.audio);
  });

  test('classifies text extensions as text', () {
    expect(kindForZipPreview('readme.md'), ZipPreviewKind.text);
    expect(kindForZipPreview('notes.txt'), ZipPreviewKind.text);
    expect(kindForZipPreview('config.json'), ZipPreviewKind.text);
  });

  test('classifies unknown extensions as unsupported', () {
    expect(kindForZipPreview('data.dat'), ZipPreviewKind.unsupported);
    expect(kindForZipPreview('archive'), ZipPreviewKind.unsupported);
  });
}
