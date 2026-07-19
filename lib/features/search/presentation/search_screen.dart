import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explorerState = ref.watch(explorerControllerProvider);
    final searchState = ref.watch(fileSearchControllerProvider);
    final rootPath = explorerState.currentPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchBar(
            controller: _textController,
            hintText: 'Search files and folders',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (_textController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _textController.clear();
                    ref.read(fileSearchControllerProvider.notifier).setQuery(
                          query: '',
                          rootPath: rootPath,
                        );
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
            onChanged: (query) {
              ref.read(fileSearchControllerProvider.notifier).setQuery(
                    query: query,
                    rootPath: rootPath,
                  );
              setState(() {});
            },
            onSubmitted: (query) {
              ref.read(fileSearchControllerProvider.notifier).searchNow(
                    query: query,
                    rootPath: rootPath,
                  );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Scope: $rootPath',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (!searchState.hasQuery)
            const _SearchHint()
          else if (searchState.isSearching)
            const LinearProgressIndicator()
          else if (searchState.error != null)
            _SearchError(error: searchState.error!)
          else if (searchState.results.isEmpty)
            const _NoSearchResults()
          else
            ...searchState.results.map(
              (result) => _SearchResultTile(result: result),
            ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({required this.result});

  final SearchResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = result.entry;

    return Card(
      child: ListTile(
        leading: Icon(iconForFileSystemEntryType(entry.type)),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          result.parentPath,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(_detailFor(entry)),
        onTap: () {
          ref.read(explorerControllerProvider.notifier).openDirectory(
                parentPathForSearchResult(result),
              );
          context.go(AppRoutes.explorer);
        },
      ),
    );
  }

  String _detailFor(FileSystemEntry entry) {
    if (entry.isFolder) {
      return '${entry.childrenCount ?? 0} items';
    }
    return formatBytes(entry.sizeBytes ?? 0);
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.manage_search_rounded),
        title: Text('Type to search this location'),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.search_off_rounded),
        title: Text('No matches found'),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.error_outline_rounded),
        title: const Text('Search failed'),
        subtitle: Text('$error'),
      ),
    );
  }
}
