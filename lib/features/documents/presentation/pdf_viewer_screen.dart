import 'dart:async';
import 'dart:typed_data';

import 'package:file_explorer/features/documents/data/platform/pdf_renderer_platform.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({required this.entry, super.key});

  final FileSystemEntry entry;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final _pageController = PageController();

  int? _pageCount;
  int _currentPage = 0;
  String? _error;
  bool _loading = true;

  PdfPageRenderer get _renderer => ref.read(pdfPageRendererProvider);

  @override
  void initState() {
    super.initState();
    _loadPageCount();
  }

  @override
  void dispose() {
    _pageController.dispose();
    unawaited(_renderer.close());
    super.dispose();
  }

  Future<void> _loadPageCount() async {
    try {
      final count = await _renderer.getPageCount(widget.entry.path);
      if (!mounted) {
        return;
      }
      setState(() {
        _pageCount = count;
        _currentPage = 0;
        _error = count == 0 ? 'This PDF has no pages' : null;
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
      _pageCount = null;
    });
    _loadPageCount();
  }

  void _goToPage(int page) {
    final count = _pageCount;
    if (count == null || page < 0 || page >= count) {
      return;
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                Icons.picture_as_pdf_outlined,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not open PDF',
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

    final pageCount = _pageCount ?? 0;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, page) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final renderWidth = (constraints.maxWidth * devicePixelRatio)
                      .round()
                      .clamp(320, 2400);
                  return _PdfPage(
                    path: widget.entry.path,
                    page: page,
                    renderWidth: renderWidth,
                  );
                },
              );
            },
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
                    tooltip: 'Previous page',
                    onPressed: _currentPage > 0
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '${_currentPage + 1} / $pageCount',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: _currentPage < pageCount - 1
                        ? () => _goToPage(_currentPage + 1)
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

class _PdfPage extends ConsumerStatefulWidget {
  const _PdfPage({
    required this.path,
    required this.page,
    required this.renderWidth,
  });

  final String path;
  final int page;
  final int renderWidth;

  @override
  ConsumerState<_PdfPage> createState() => _PdfPageState();
}

class _PdfPageState extends ConsumerState<_PdfPage> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _render();
  }

  @override
  void didUpdateWidget(covariant _PdfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.page != widget.page ||
        oldWidget.renderWidth != widget.renderWidth) {
      _bytes = _render();
    }
  }

  Future<Uint8List> _render() {
    return ref.read(pdfPageRendererProvider).renderPage(
          widget.path,
          widget.page,
          width: widget.renderWidth,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not render page ${widget.page + 1}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}
