import 'package:file_explorer/features/documents/domain/epub_reader.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';

class EpubViewerScreen extends StatefulWidget {
  const EpubViewerScreen({required this.entry, super.key});

  final FileSystemEntry entry;

  @override
  State<EpubViewerScreen> createState() => _EpubViewerScreenState();
}

class _EpubViewerScreenState extends State<EpubViewerScreen> {
  final _scrollController = ScrollController();

  EpubBook? _book;
  String? _error;
  bool _loading = true;
  int _chapterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    try {
      final book = await parseEpubFile(widget.entry.path);
      if (!mounted) {
        return;
      }
      setState(() {
        _book = book;
        _chapterIndex = 0;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
      _book = null;
    });
    _loadBook();
  }

  void _selectChapter(int index) {
    final book = _book;
    if (book == null || index < 0 || index >= book.chapters.length) {
      return;
    }
    setState(() => _chapterIndex = index);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    final chapter = book == null ? null : book.chapters[_chapterIndex];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              book?.title ?? widget.entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (chapter != null)
              Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        actions: [
          if (book != null)
            PopupMenuButton<int>(
              tooltip: 'Chapters',
              icon: const Icon(Icons.toc_rounded),
              initialValue: _chapterIndex,
              onSelected: _selectChapter,
              itemBuilder: (context) {
                return [
                  for (var index = 0; index < book.chapters.length; index++)
                    CheckedPopupMenuItem<int>(
                      value: index,
                      checked: index == _chapterIndex,
                      child: Text(
                        book.chapters[index].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ];
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

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
                Icons.menu_book_outlined,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not open EPUB',
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
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final book = _book!;
    final chapter = book.chapters[_chapterIndex];

    return Column(
      children: [
        Expanded(
          child: Container(
            color: colorScheme.surface,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: chapter.blocks.length,
              itemBuilder: (context, index) {
                return _EpubBlockView(block: chapter.blocks[index]);
              },
            ),
          ),
        ),
        Material(
          color: colorScheme.surfaceContainerHighest,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous chapter',
                    onPressed: _chapterIndex > 0
                        ? () => _selectChapter(_chapterIndex - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '${_chapterIndex + 1} / ${book.chapters.length}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next chapter',
                    onPressed: _chapterIndex < book.chapters.length - 1
                        ? () => _selectChapter(_chapterIndex + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EpubBlockView extends StatelessWidget {
  const _EpubBlockView({required this.block});

  final EpubBlock block;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    switch (block.kind) {
      case EpubBlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: SelectableText(
            block.text,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case EpubBlockKind.subheading:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: SelectableText(
            block.text,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case EpubBlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableText(
            block.text,
            style: textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        );
      case EpubBlockKind.quote:
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorScheme.primary, width: 3),
            ),
          ),
          child: SelectableText(
            block.text,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      case EpubBlockKind.code:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            block.text,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        );
      case EpubBlockKind.image:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.text,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
