import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

enum EpubBlockKind { heading, subheading, paragraph, quote, code, image }

class EpubBlock {
  const EpubBlock(this.kind, this.text);

  final EpubBlockKind kind;
  final String text;
}

class EpubChapter {
  const EpubChapter({
    required this.title,
    required this.href,
    required this.blocks,
  });

  final String title;
  final String href;
  final List<EpubBlock> blocks;
}

class EpubBook {
  const EpubBook({required this.title, required this.chapters});

  final String title;
  final List<EpubChapter> chapters;
}

class EpubFormatException implements Exception {
  const EpubFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _maxArchiveBytes = 128 * 1024 * 1024;
const _maxChapterBytes = 4 * 1024 * 1024;

Future<EpubBook> parseEpubFile(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  return parseEpubBytes(bytes, fallbackTitle: p.basenameWithoutExtension(path));
}

EpubBook parseEpubBytes(Uint8List bytes, {String fallbackTitle = 'Book'}) {
  if (bytes.length > _maxArchiveBytes) {
    throw const EpubFormatException('EPUB is too large to preview');
  }

  late final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (error) {
    throw EpubFormatException('Could not read EPUB: $error');
  }

  final entries = <String, ArchiveFile>{};
  for (final entry in archive) {
    final name = _normalizeArchivePath(entry.name);
    if (name.isNotEmpty) {
      entries[name] = entry;
    }
  }

  final containerXml = _readText(entries, 'META-INF/container.xml');
  if (containerXml == null) {
    throw const EpubFormatException(
      'This file is not a valid EPUB (missing container)',
    );
  }

  final opfPath = _opfPath(containerXml);
  if (opfPath == null) {
    throw const EpubFormatException(
      'This file is not a valid EPUB (missing package document)',
    );
  }
  final opfXml = _readText(entries, opfPath);
  if (opfXml == null) {
    throw const EpubFormatException(
      'This file is not a valid EPUB (package document not found)',
    );
  }

  final package = _parsePackage(opfXml, opfPath);
  final chapters = <EpubChapter>[];
  for (final item in package.spine) {
    final chapterBytes = _readBytes(entries, item.path);
    if (chapterBytes == null) {
      continue;
    }
    if (chapterBytes.length > _maxChapterBytes) {
      throw const EpubFormatException('EPUB chapter is too large to preview');
    }
    final blocks = _blocksFromHtml(
      utf8.decode(chapterBytes, allowMalformed: true),
    );
    if (blocks.isEmpty) {
      continue;
    }
    chapters.add(
      EpubChapter(
        title: _chapterTitle(blocks, chapters.length + 1),
        href: item.path,
        blocks: blocks,
      ),
    );
  }

  if (chapters.isEmpty) {
    throw const EpubFormatException('EPUB has no readable chapters');
  }

  return EpubBook(
    title: package.title.isEmpty ? fallbackTitle : package.title,
    chapters: chapters,
  );
}

class _SpineItem {
  const _SpineItem({required this.path});

  final String path;
}

class _Package {
  const _Package({required this.title, required this.spine});

  final String title;
  final List<_SpineItem> spine;
}

String? _opfPath(String containerXml) {
  try {
    final document = XmlDocument.parse(containerXml);
    for (final element in document.findAllElements('rootfile')) {
      final path = element.getAttribute('full-path');
      if (path != null && path.trim().isNotEmpty) {
        return _normalizeArchivePath(path);
      }
    }
  } on XmlException {
    return null;
  }
  return null;
}

_Package _parsePackage(String opfXml, String opfPath) {
  late final XmlDocument document;
  try {
    document = XmlDocument.parse(opfXml);
  } on XmlException catch (error) {
    throw EpubFormatException('Could not read EPUB package: $error');
  }

  final title = document.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 'title')
      .map((element) => _normalizeWhitespace(element.innerText))
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');

  final manifest = <String, String>{};
  final manifestMediaTypes = <String, String>{};
  for (final item in document.findAllElements('item')) {
    final id = item.getAttribute('id');
    final href = item.getAttribute('href');
    if (id == null || href == null) {
      continue;
    }
    final path = _resolveHref(opfPath, href);
    if (path == null) {
      continue;
    }
    manifest[id] = path;
    manifestMediaTypes[id] =
        (item.getAttribute('media-type') ?? '').toLowerCase();
  }

  final spine = <_SpineItem>[];
  for (final itemref in document.findAllElements('itemref')) {
    final idref = itemref.getAttribute('idref');
    if (idref == null) {
      continue;
    }
    final path = manifest[idref];
    if (path == null) {
      continue;
    }
    final mediaType = manifestMediaTypes[idref] ?? '';
    final isHtml = mediaType == 'application/xhtml+xml' ||
        mediaType == 'text/html' ||
        path.endsWith('.xhtml') ||
        path.endsWith('.html') ||
        path.endsWith('.htm');
    if (isHtml) {
      spine.add(_SpineItem(path: path));
    }
  }

  if (spine.isEmpty) {
    for (final entry in manifest.entries) {
      final mediaType = manifestMediaTypes[entry.key] ?? '';
      if (mediaType == 'application/xhtml+xml' || mediaType == 'text/html') {
        spine.add(_SpineItem(path: entry.value));
      }
    }
  }

  return _Package(title: title, spine: spine);
}

String? _resolveHref(String opfPath, String href) {
  final trimmed = href.split('#').first.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final decoded = _decodeHref(trimmed);
  final base = p.url.dirname(opfPath);
  final resolved = p.url.normalize(
    base == '.' ? decoded : p.url.join(base, decoded),
  );
  final normalized = _normalizeArchivePath(resolved);
  if (normalized.isEmpty || normalized.startsWith('../')) {
    return null;
  }
  return normalized;
}

String _decodeHref(String href) {
  try {
    return Uri.decodeFull(href);
  } catch (_) {
    return href;
  }
}

String _normalizeArchivePath(String path) {
  var normalized = path.replaceAll('\\', '/');
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  while (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }
  return normalized;
}

String? _readText(Map<String, ArchiveFile> entries, String path) {
  final bytes = _readBytes(entries, path);
  if (bytes == null) {
    return null;
  }
  return utf8.decode(bytes, allowMalformed: true);
}

Uint8List? _readBytes(Map<String, ArchiveFile> entries, String path) {
  final entry = entries[path] ?? entries[_decodeHref(path)];
  if (entry == null) {
    return null;
  }
  final bytes = entry.readBytes();
  if (bytes == null) {
    return null;
  }
  return Uint8List.fromList(bytes);
}

List<EpubBlock> _blocksFromHtml(String source) {
  final document = html_parser.parse(source);
  for (final element in document.querySelectorAll('script, style, head')) {
    element.remove();
  }
  final body = document.body ?? document.documentElement;
  if (body == null) {
    return const [];
  }

  const selector = 'h1, h2, h3, h4, h5, h6, p, blockquote, li, pre';
  final selected = <html.Element>{};
  final blocks = <EpubBlock>[];
  for (final element in body.querySelectorAll(selector)) {
    if (_hasSelectedAncestor(element, selected)) {
      continue;
    }
    selected.add(element);

    final tag = element.localName ?? '';
    final text = _normalizeWhitespace(
      tag == 'li' ? '• ${element.text}' : element.text,
    );
    if (text.isNotEmpty) {
      blocks.add(_blockForTag(tag, text));
    }
    for (final image in element.querySelectorAll('img')) {
      final alt = _normalizeWhitespace(image.attributes['alt'] ?? '');
      blocks.add(
        EpubBlock(
          EpubBlockKind.image,
          alt.isEmpty ? 'Image' : alt,
        ),
      );
    }
  }

  if (blocks.isEmpty) {
    final fallback = _normalizeWhitespace(body.text);
    if (fallback.isNotEmpty) {
      blocks.add(EpubBlock(EpubBlockKind.paragraph, fallback));
    }
  }

  return blocks;
}

bool _hasSelectedAncestor(html.Element element, Set<html.Element> selected) {
  var parent = element.parent;
  while (parent != null) {
    if (selected.contains(parent)) {
      return true;
    }
    parent = parent.parent;
  }
  return false;
}

EpubBlock _blockForTag(String tag, String text) {
  switch (tag) {
    case 'h1':
    case 'h2':
      return EpubBlock(EpubBlockKind.heading, text);
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      return EpubBlock(EpubBlockKind.subheading, text);
    case 'blockquote':
      return EpubBlock(EpubBlockKind.quote, text);
    case 'pre':
      return EpubBlock(EpubBlockKind.code, text);
    default:
      return EpubBlock(EpubBlockKind.paragraph, text);
  }
}

String _chapterTitle(List<EpubBlock> blocks, int number) {
  for (final block in blocks) {
    if (block.kind == EpubBlockKind.heading && block.text.isNotEmpty) {
      return block.text;
    }
  }
  for (final block in blocks) {
    if (block.text.isNotEmpty) {
      final text = block.text;
      return text.length <= 60 ? text : '${text.substring(0, 57)}...';
    }
  }
  return 'Chapter $number';
}

String _normalizeWhitespace(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
