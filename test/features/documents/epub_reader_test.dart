import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_explorer/features/documents/domain/epub_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads spine order, metadata and chapter text', () {
    final book = parseEpubBytes(_buildEpub(), fallbackTitle: 'Fallback');

    expect(book.title, 'Sample Book');
    expect(book.chapters, hasLength(2));
    expect(book.chapters[0].title, 'Second Chapter');
    expect(book.chapters[0].href, 'OEBPS/text/ch2.xhtml');
    expect(book.chapters[1].title, 'First Chapter');

    final firstBlocks = book.chapters[1].blocks;
    expect(firstBlocks.first.kind, EpubBlockKind.heading);
    expect(firstBlocks.first.text, 'First Chapter');
    expect(
      firstBlocks.map((block) => block.text),
      containsAllInOrder([
        'First Chapter',
        'Hello & world.',
        'Quoted.',
        '• One',
        '• Two',
        'Map',
      ]),
    );
    expect(
      firstBlocks.map((block) => block.kind),
      containsAllInOrder([
        EpubBlockKind.heading,
        EpubBlockKind.paragraph,
        EpubBlockKind.quote,
        EpubBlockKind.paragraph,
        EpubBlockKind.paragraph,
        EpubBlockKind.image,
      ]),
    );
  });

  test('uses manifest order when the spine is missing', () {
    final book = parseEpubBytes(
      _buildEpub(
        spine: '',
        metadataTitle: '',
      ),
      fallbackTitle: 'Fallback',
    );

    expect(book.title, 'Fallback');
    expect(
      book.chapters.map((chapter) => chapter.title),
      ['First Chapter', 'Second Chapter'],
    );
  });

  test('rejects files without an EPUB container', () {
    final archive = Archive();
    archive.addFile(ArchiveFile.string('readme.txt', 'not an epub'));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

    expect(
      () => parseEpubBytes(bytes),
      throwsA(
        isA<EpubFormatException>().having(
          (error) => error.message,
          'message',
          contains('container'),
        ),
      ),
    );
  });
}

Uint8List _buildEpub({
  String spine = '<itemref idref="c2"/><itemref idref="c1"/>',
  String metadataTitle = '<dc:title>Sample Book</dc:title>',
}) {
  final archive = Archive();
  archive.addFile(
    ArchiveFile.string('mimetype', 'application/epub+zip'),
  );
  archive.addFile(
    ArchiveFile.string(
      'META-INF/container.xml',
      '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OEBPS/content.opf',
      '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    $metadataTitle
  </metadata>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>$spine</spine>
</package>
''',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OEBPS/ch1.xhtml',
      '''
<html xmlns="http://www.w3.org/1999/xhtml">
<body>
  <h1>First Chapter</h1>
  <p>Hello &amp; world.</p>
  <blockquote>Quoted.</blockquote>
  <ul><li>One</li><li>Two</li></ul>
  <p><img alt="Map"/></p>
</body>
</html>
''',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OEBPS/text/ch2.xhtml',
      '''
<html xmlns="http://www.w3.org/1999/xhtml">
<body>
  <h2>Second Chapter</h2>
  <p>Body two.</p>
</body>
</html>
''',
    ),
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
