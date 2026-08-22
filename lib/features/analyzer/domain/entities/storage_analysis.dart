/// Storage analysis result entities for the analyzer feature.
library;

class CategoryUsage {
  const CategoryUsage({required this.category, required this.bytes});

  /// One of: image, video, audio, document, archive, app, other.
  final String category;
  final int bytes;
}

class FolderUsage {
  const FolderUsage({required this.path, required this.bytes});

  final String path;
  final int bytes;
}

class LargeFile {
  const LargeFile({
    required this.path,
    required this.bytes,
    required this.category,
  });

  final String path;
  final int bytes;
  final String category;
}

class StorageAnalysis {
  const StorageAnalysis({
    required this.rootPath,
    required this.totalBytes,
    required this.fileCount,
    required this.folderCount,
    required this.categories,
    required this.folders,
    required this.files,
  });

  final String rootPath;
  final int totalBytes;
  final int fileCount;
  final int folderCount;
  final List<CategoryUsage> categories;
  final List<FolderUsage> folders;
  final List<LargeFile> files;
}
