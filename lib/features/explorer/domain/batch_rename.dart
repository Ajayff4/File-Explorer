import 'package:path/path.dart' as p;

class BatchRenameSource {
  const BatchRenameSource({required this.path, required this.isFolder});

  final String path;
  final bool isFolder;

  String get name => p.basename(path);
}

class BatchRenameOptions {
  const BatchRenameOptions({
    this.find = '',
    this.replace = '',
    this.prefix = '',
    this.suffix = '',
    this.numbered = false,
    this.numberStart = 1,
    this.numberStep = 1,
    this.numberPadding = 2,
    this.preserveExtension = true,
  });

  final String find;
  final String replace;
  final String prefix;
  final String suffix;
  final bool numbered;
  final int numberStart;
  final int numberStep;
  final int numberPadding;
  final bool preserveExtension;

  bool get hasPattern =>
      find.isNotEmpty || prefix.isNotEmpty || suffix.isNotEmpty || numbered;
}

class BatchRenameItem {
  const BatchRenameItem({
    required this.source,
    required this.newName,
  });

  final BatchRenameSource source;
  final String newName;

  String get oldName => source.name;
  String get oldPath => source.path;
  String get newPath => p.join(p.dirname(source.path), newName);

  bool get changed => oldName != newName;
}

class BatchRenamePreview {
  const BatchRenamePreview({required this.items, required this.errors});

  final List<BatchRenameItem> items;
  final List<String> errors;

  List<BatchRenameItem> get changedItems =>
      items.where((item) => item.changed).toList(growable: false);

  bool get canApply => errors.isEmpty && changedItems.isNotEmpty;
}

BatchRenamePreview buildBatchRenamePreview(
  List<BatchRenameSource> sources,
  BatchRenameOptions options,
) {
  final items = <BatchRenameItem>[];
  final errors = <String>[];

  for (var index = 0; index < sources.length; index++) {
    final source = sources[index];
    final (stem, extension) = _splitName(source, options);
    var renamedStem = stem;
    if (options.find.isNotEmpty) {
      renamedStem = renamedStem.replaceAll(options.find, options.replace);
    }

    var newName = '${options.prefix}$renamedStem${options.suffix}';
    if (options.numbered) {
      final number = options.numberStart + (index * options.numberStep);
      newName += number.abs().toString().padLeft(options.numberPadding, '0');
    }
    newName += extension;

    items.add(BatchRenameItem(source: source, newName: newName));
    _validateName(source, newName, errors);
  }

  final names = <String, List<String>>{};
  for (final item in items) {
    if (!item.changed) {
      continue;
    }
    final key = item.newName.toLowerCase();
    names.putIfAbsent(key, () => []).add(item.newName);
  }
  for (final duplicate in names.values) {
    if (duplicate.length > 1) {
      errors.add('More than one item would be named "${duplicate.first}"');
    }
  }

  return BatchRenamePreview(items: items, errors: errors);
}

(String, String) _splitName(
  BatchRenameSource source,
  BatchRenameOptions options,
) {
  final name = source.name;
  if (source.isFolder || !options.preserveExtension) {
    return (name, '');
  }
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == name.length - 1) {
    return (name, '');
  }
  return (name.substring(0, dotIndex), name.substring(dotIndex));
}

void _validateName(
  BatchRenameSource source,
  String newName,
  List<String> errors,
) {
  final label = source.name;
  if (newName.isEmpty) {
    errors.add('"$label" would have an empty name');
    return;
  }
  if (newName == '.' || newName == '..') {
    errors.add('"$label" would have an invalid name');
    return;
  }
  if (newName.contains('/') ||
      newName.contains('\\') ||
      newName.contains('\u0000')) {
    errors.add('"$label" would contain an invalid character');
    return;
  }
  if (newName.trim() != newName) {
    errors.add('"$label" would begin or end with a space');
  }
}
