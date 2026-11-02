import 'dart:io';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/media/domain/text_file_encoding.dart';
import 'package:file_explorer/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';

class TextFileViewerScreen extends StatefulWidget {
  const TextFileViewerScreen({required this.entry, super.key});

  final FileSystemEntry entry;

  @override
  State<TextFileViewerScreen> createState() => _TextFileViewerScreenState();
}

class _TextFileViewerScreenState extends State<TextFileViewerScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String? _content;
  String? _error;
  bool _loading = true;
  bool _wrapLines = true;
  double _fontSize = 14;
  bool _editing = false;
  bool _dirty = false;
  bool _saving = false;
  TextFileEncoding _encoding = TextFileEncoding.utf8;
  bool _hasBom = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadContent({TextFileEncoding? encoding}) async {
    try {
      final bytes = await File(widget.entry.path).readAsBytes();
      final decoded = decodeTextFile(bytes, encoding: encoding);
      if (!mounted) {
        return;
      }
      _controller.removeListener(_handleContentChanged);
      _controller.text = decoded.text;
      _controller.addListener(_handleContentChanged);
      setState(() {
        _content = decoded.text;
        _encoding = decoded.encoding;
        _hasBom = decoded.hasBom;
        _dirty = false;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _handleContentChanged() {
    final dirty = _editing && _controller.text != (_content ?? '');
    if (dirty != _dirty && mounted) {
      setState(() => _dirty = dirty);
    }
  }

  void _startEditing() {
    if (_content == null) {
      return;
    }
    setState(() {
      _editing = true;
      _dirty = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _stopEditing() async {
    if (_dirty) {
      final discard = await _confirmDiscard();
      if (!discard || !mounted) {
        return;
      }
    }
    setState(() {
      _editing = false;
      _dirty = false;
    });
    _controller.text = _content ?? '';
  }

  Future<void> _save() async {
    if (_saving || !_dirty) {
      return;
    }
    final text = _controller.text;
    setState(() => _saving = true);
    try {
      final writeBom = _hasBom && _encoding.supportsBom;
      final bytes = encodeTextFile(
        text,
        encoding: _encoding,
        withBom: writeBom,
      );
      await File(widget.entry.path).writeAsBytes(bytes, flush: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _content = text;
        _hasBom = writeBom;
        _dirty = false;
        _saving = false;
      });
      _showMessage('File saved');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _showMessage('Could not save file: $e');
    }
  }

  Future<void> _changeEncoding(TextFileEncoding encoding) async {
    if (encoding == _encoding && !_editing) {
      return;
    }
    if (_editing) {
      setState(() {
        _encoding = encoding;
        _hasBom = _hasBom && encoding.supportsBom;
      });
      _showMessage('Will save as ${encoding.label}');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await _loadContent(encoding: encoding);
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your edits have not been saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    return discard ?? false;
  }

  Future<void> _handleBlockedPop() async {
    if (!_dirty) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) {
      _dirty = false;
      Navigator.of(context).pop();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBlockedPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_editing)
                Text(
                  _dirty ? 'Unsaved changes' : 'Editing',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _dirty
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
          actions: [
            if (_editing) ...[
              IconButton(
                tooltip: 'Save',
                onPressed: _dirty && !_saving ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
              ),
              IconButton(
                tooltip: 'Stop editing',
                onPressed: _saving ? null : _stopEditing,
                icon: const Icon(Icons.close_rounded),
              ),
            ] else ...[
              IconButton(
                tooltip: 'Edit',
                onPressed: !_loading && _error == null ? _startEditing : null,
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                tooltip: _wrapLines ? 'No wrap' : 'Wrap lines',
                icon: Icon(
                  _wrapLines ? Icons.wrap_text_rounded : Icons.subject_rounded,
                ),
                onPressed: () {
                  setState(() => _wrapLines = !_wrapLines);
                },
              ),
            ],
            PopupMenuButton<TextFileEncoding>(
              tooltip: 'Encoding',
              enabled: !_loading,
              initialValue: _encoding,
              onSelected: _changeEncoding,
              itemBuilder: (context) {
                return [
                  for (final encoding in TextFileEncoding.values)
                    CheckedPopupMenuItem<TextFileEncoding>(
                      value: encoding,
                      checked: _encoding == encoding,
                      child: Text(encoding.label),
                    ),
                ];
              },
              icon: const Icon(Icons.translate_rounded),
            ),
            PopupMenuButton<double>(
              tooltip: 'Font size',
              initialValue: _fontSize,
              onSelected: (size) {
                setState(() => _fontSize = size);
              },
              itemBuilder: (context) {
                return [
                  for (final size in [
                    10.0,
                    12.0,
                    14.0,
                    16.0,
                    18.0,
                    20.0,
                    24.0,
                  ])
                    CheckedPopupMenuItem<double>(
                      value: size,
                      checked: _fontSize == size,
                      child: Text('${size.toInt()}pt'),
                    ),
                ];
              },
              icon: const Icon(Icons.text_fields_rounded),
            ),
          ],
        ),
        body: _buildBody(colorScheme),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) {
      return const AppLoadingIndicator();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not read file',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadContent();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_editing) {
      return Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          expands: true,
          maxLines: null,
          minLines: null,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: _fontSize,
            height: 1.5,
            color: colorScheme.onSurface,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(8),
          ),
        ),
      );
    }

    if (_content == null || _content!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.text_snippet_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Empty file',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit file'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          _content!,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: _fontSize,
            height: 1.5,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

bool isTextFile(String path) {
  final ext = _extensionFor(path).toLowerCase();
  return _textExtensions.contains(ext);
}

const _textExtensions = {
  'txt',
  'text',
  'log',
  'md',
  'markdown',
  'html',
  'htm',
  'xhtml',
  'css',
  'scss',
  'sass',
  'less',
  'js',
  'jsx',
  'mjs',
  'cjs',
  'ts',
  'tsx',
  'json',
  'jsonc',
  'json5',
  'xml',
  'xsl',
  'xslt',
  'svg',
  'yaml',
  'yml',
  'toml',
  'ini',
  'cfg',
  'conf',
  'sh',
  'bash',
  'zsh',
  'fish',
  'py',
  'pyw',
  'pyi',
  'rb',
  'php',
  'java',
  'kt',
  'kts',
  'c',
  'h',
  'cpp',
  'hpp',
  'cc',
  'cxx',
  'cs',
  'go',
  'rs',
  'swift',
  'dart',
  'sql',
  'gradle',
  'dockerfile',
  'makefile',
  'cmake',
  'r',
  'rmd',
  'lua',
  'pl',
  'pm',
  'vue',
  'svelte',
  'astro',
};

String _extensionFor(String name) {
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == name.length - 1) {
    return '';
  }
  return name.substring(dotIndex + 1).toLowerCase();
}
