import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/explorer/presentation/widgets/file_entry_visuals.dart';
import 'package:file_explorer/features/media/presentation/media_viewer_screen.dart';
import 'package:file_explorer/features/media/presentation/widgets/media_thumbnail.dart';
import 'package:file_explorer/features/recents/presentation/controllers/recents_controller.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:file_explorer/shared/formatters/byte_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _SearchScope { currentFolder, storageRoot }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textController;
  _SearchScope _scope = _SearchScope.currentFolder;

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
    final currentPath = explorerState.currentPath;
    final storageRootPath =
        explorerState.listing.valueOrNull?.volume?.path ?? currentPath;
    final rootPath =
        _scope == _SearchScope.storageRoot ? storageRootPath : currentPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            tooltip: 'Reindex',
            onPressed: searchState.isSearching
                ? null
                : () {
                    ref.read(fileSearchControllerProvider.notifier).reindex(
                          rootPath: rootPath,
                        );
                  },
            icon: const Icon(Icons.update_rounded),
          ),
        ],
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
          const SizedBox(height: 12),
          SegmentedButton<_SearchScope>(
            segments: const [
              ButtonSegment(
                value: _SearchScope.currentFolder,
                icon: Icon(Icons.folder_open_rounded),
                label: Text('Current'),
              ),
              ButtonSegment(
                value: _SearchScope.storageRoot,
                icon: Icon(Icons.storage_rounded),
                label: Text('Storage'),
              ),
            ],
            selected: {_scope},
            onSelectionChanged: (selection) {
              final nextScope = selection.first;
              setState(() => _scope = nextScope);
              final nextRoot = nextScope == _SearchScope.storageRoot
                  ? storageRootPath
                  : currentPath;
              ref.read(fileSearchControllerProvider.notifier).searchNow(
                    query: _textController.text,
                    rootPath: nextRoot,
                  );
            },
          ),
          const SizedBox(height: 12),
          _TypeFilterChips(
            selectedTypes: searchState.filteredTypes,
            onChanged: (types) {
              ref.read(fileSearchControllerProvider.notifier).setFilteredTypes(
                    filteredTypes: types,
                    rootPath: rootPath,
                  );
            },
          ),
          const SizedBox(height: 16),
          if (!searchState.hasQuery && searchState.filteredTypes.isEmpty)
            const _SearchHint()
          else if (searchState.isSearching)
            _SearchLoadingState(isIndexing: searchState.isIndexing)
          else if (searchState.error != null)
            _SearchError(error: searchState.error!)
          else if (searchState.results.isEmpty)
            const _NoSearchResults()
          else ...[
            _ResultCountHeader(count: searchState.results.length),
            const SizedBox(height: 8),
            _SearchResultsGrid(
              results: searchState.results,
              activeFilter: searchState.filteredTypes.isEmpty
                  ? null
                  : searchState.filteredTypes.first,
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeFilterChips extends StatelessWidget {
  const _TypeFilterChips({
    required this.selectedTypes,
    required this.onChanged,
  });

  final Set<FileSystemEntryType> selectedTypes;
  final ValueChanged<Set<FileSystemEntryType>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: selectedTypes.isEmpty,
          onSelected: (_) => onChanged(const {}),
        ),
        for (final option in _filterOptions)
          FilterChip(
            avatar: Icon(option.icon, size: 18),
            label: Text(option.label),
            selected: selectedTypes.contains(option.type),
            onSelected: (selected) {
              final nextTypes = {...selectedTypes};
              if (selected) {
                nextTypes.add(option.type);
              } else {
                nextTypes.remove(option.type);
              }
              onChanged(nextTypes);
            },
          ),
      ],
    );
  }
}

class _FilterOption {
  const _FilterOption(this.type, this.label, this.icon);

  final FileSystemEntryType type;
  final String label;
  final IconData icon;
}

const _filterOptions = [
  _FilterOption(FileSystemEntryType.folder, 'Folders', Icons.folder_rounded),
  _FilterOption(FileSystemEntryType.image, 'Images', Icons.image_rounded),
  _FilterOption(FileSystemEntryType.video, 'Videos', Icons.movie_rounded),
  _FilterOption(FileSystemEntryType.audio, 'Audio', Icons.music_note_rounded),
  _FilterOption(
    FileSystemEntryType.document,
    'Docs',
    Icons.description_rounded,
  ),
  _FilterOption(
      FileSystemEntryType.archive, 'Archives', Icons.inventory_2_rounded),
  _FilterOption(FileSystemEntryType.app, 'Apps', Icons.apps_rounded),
];

class _ResultCountHeader extends StatelessWidget {
  const _ResultCountHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      count == 1 ? '1 result' : '$count results',
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}

class _SearchResultsGrid extends StatelessWidget {
  const _SearchResultsGrid({
    required this.results,
    this.activeFilter,
  });

  final List<SearchResult> results;
  final FileSystemEntryType? activeFilter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = (constraints.maxWidth / 108).floor().clamp(3, 6);

        return GridView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisExtent: 138,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            return _SearchResultGridTile(
              result: results[index],
              results: results,
              activeFilter: activeFilter,
            );
          },
        );
      },
    );
  }
}

class _SearchResultGridTile extends ConsumerWidget {
  const _SearchResultGridTile({
    required this.result,
    required this.results,
    this.activeFilter,
  });

  final SearchResult result;
  final List<SearchResult> results;
  final FileSystemEntryType? activeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = result.entry;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (entry.isFolder) {
            _openContainingFolder(context, ref);
          } else {
            _openFile(context, ref);
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: Center(
                      child: MediaThumbnail(
                        entry: entry,
                        fallbackIcon: iconForFileSystemEntry(entry),
                        fallbackColor: colorForFileSystemEntry(context, entry),
                        dimension: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        entry.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 18,
                    child: Text(
                      _detailFor(entry),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            if (!entry.isFolder)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: 'Open folder',
                  onPressed: () => _openContainingFolder(context, ref),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.folder_open_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFile(BuildContext context, WidgetRef ref) {
    final entry = result.entry;
    final settings = ref.read(settingsControllerProvider).settings;
    if (!settings.showFoldersOnlyInHistory) {
      ref.read(recentsControllerProvider.notifier).recordLocation(
            path: entry.path,
            label: entry.name,
            isFolder: false,
          );
    }

    context.push(
      AppRoutes.mediaViewer,
      extra: MediaViewerSession(
        entry: entry,
        entries: [
          for (final searchResult in results) searchResult.entry,
        ],
      ),
    );
  }

  void _openContainingFolder(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsControllerProvider).settings;
    final isFolder = result.entry.isFolder;
    final shouldRecordFile = !isFolder && !settings.showFoldersOnlyInHistory;

    if (activeFilter != null) {
      ref.read(explorerFilterTypeProvider.notifier).state = activeFilter;
    }
    ref.read(explorerControllerProvider.notifier).openDirectory(
          parentPathForSearchResult(result),
          recordRecent: isFolder || !shouldRecordFile,
        );
    context.go(AppRoutes.explorer);
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

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState({required this.isIndexing});

  final bool isIndexing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(isIndexing ? 'Indexing files' : 'Searching'),
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
