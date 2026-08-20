import 'package:path/path.dart' as p;

enum ArchiveFormat { zip, tar, gzip, tarGzip, tarBzip2, tarXz }

ArchiveFormat? archiveFormatForPath(String path) {
  final name = p.basename(path).toLowerCase();
  if (name.endsWith('.tar.gz') || name.endsWith('.tgz')) {
    return ArchiveFormat.tarGzip;
  }
  if (name.endsWith('.tar.bz2') || name.endsWith('.tbz2')) {
    return ArchiveFormat.tarBzip2;
  }
  if (name.endsWith('.tar.xz') || name.endsWith('.txz')) {
    return ArchiveFormat.tarXz;
  }
  if (name.endsWith('.gz')) {
    return ArchiveFormat.gzip;
  }
  if (name.endsWith('.tar')) {
    return ArchiveFormat.tar;
  }
  if (name.endsWith('.zip')) {
    return ArchiveFormat.zip;
  }
  return null;
}

bool isBrowsableArchive(ArchiveFormat format) {
  return true;
}

String archiveBaseName(String path) {
  final name = p.basename(path);
  final lowerName = name.toLowerCase();

  const suffixes = [
    '.tar.gz',
    '.tar.bz2',
    '.tar.xz',
    '.tgz',
    '.tbz2',
    '.txz',
    '.gz',
    '.tar',
    '.zip',
  ];
  for (final suffix in suffixes) {
    if (lowerName.endsWith(suffix)) {
      final baseName = name.substring(0, name.length - suffix.length);
      return baseName.isEmpty ? 'archive' : baseName;
    }
  }

  final baseName = p.basenameWithoutExtension(name);
  return baseName.isEmpty ? 'archive' : baseName;
}

String extensionForArchiveFormat(ArchiveFormat format) {
  return switch (format) {
    ArchiveFormat.zip => '.zip',
    ArchiveFormat.tar => '.tar',
    ArchiveFormat.gzip => '.gz',
    ArchiveFormat.tarGzip => '.tar.gz',
    ArchiveFormat.tarBzip2 => '.tar.bz2',
    ArchiveFormat.tarXz => '.tar.xz',
  };
}
