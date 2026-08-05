import 'dart:io';

import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:flutter/material.dart';

class TextFileViewerScreen extends StatefulWidget {
  const TextFileViewerScreen({required this.entry, super.key});

  final FileSystemEntry entry;

  @override
  State<TextFileViewerScreen> createState() => _TextFileViewerScreenState();
}

class _TextFileViewerScreenState extends State<TextFileViewerScreen> {
  String? _content;
  String? _error;
  bool _loading = true;
  bool _wrapLines = true;
  double _fontSize = 14;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final file = File(widget.entry.path);
      final content = await file.readAsString();
      if (mounted) {
        setState(() {
          _content = content;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: _wrapLines ? 'No wrap' : 'Wrap lines',
            icon: Icon(
              _wrapLines ? Icons.wrap_text_rounded : Icons.subject_rounded,
            ),
            onPressed: () {
              setState(() => _wrapLines = !_wrapLines);
            },
          ),
          PopupMenuButton<double>(
            tooltip: 'Font size',
            initialValue: _fontSize,
            onSelected: (size) {
              setState(() => _fontSize = size);
            },
            itemBuilder: (context) {
              return [
                for (final size in [10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0])
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
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: colorScheme.error),
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

    if (_content == null || _content!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.text_snippet_rounded,
                size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Empty file',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
