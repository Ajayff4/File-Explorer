import 'package:file_explorer/app/router/app_router.dart';
import 'package:file_explorer/features/explorer/domain/entities/file_system_entry.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/explorer/presentation/explorer_screen.dart';
import 'package:file_explorer/features/media/presentation/media_viewer_screen.dart';
import 'package:file_explorer/features/recents/presentation/controllers/recents_controller.dart';
import 'package:file_explorer/features/search/domain/entities/search_result.dart';
import 'package:file_explorer/features/search/presentation/controllers/file_search_controller.dart';
import 'package:file_explorer/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

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
    final isSelectionMode = explorerState.isSelectionMode;
    final selectedCount = explorerState.selectedPaths.length;

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (ModalRoute.of(context)?.isCurrent != true) {
          return false;
        }
        if (isSelectionMode) {
          ref.read(explorerControllerProvider.notifier).exitSelectionMode();
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.explorer);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: isSelectionMode
              ? IconButton(
                  tooltip: 'Exit selection',
                  onPressed: () {
                    ref
                        .read(explorerControllerProvider.notifier)
                        .exitSelectionMode();
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : IconButton(
                  tooltip: 'Back',
                  onPressed: () {
                    context.go(AppRoutes.explorer);
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
          title: isSelectionMode
              ? Text('$selectedCount selected')
              : const Text('Search'),
          actions: [
            if (isSelectionMode) ...[
              IconButton(
                tooltip: 'Select all',
                onPressed: () {
                  final paths =
                      searchState.results.map((r) => r.entry.path).toList();
                  ref
                      .read(explorerControllerProvider.notifier)
                      .selectAll(paths);
                },
                icon: const Icon(Icons.select_all_rounded),
              ),
              IconButton(
                tooltip: 'Select range',
                onPressed: selectedCount >= 2
                    ? () {
                        final searchPaths = searchState.results
                            .map((r) => r.entry.path)
                            .toList();
                        ref
                            .read(explorerControllerProvider.notifier)
                            .selectInterval(paths: searchPaths);
                      }
                    : null,
                icon: const Icon(Icons.linear_scale_rounded),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(explorerControllerProvider.notifier)
                      .exitSelectionMode();
                },
                child: const Text('Cancel'),
              ),
            ] else ...[
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
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                ref
                    .read(fileSearchControllerProvider.notifier)
                    .setFilteredTypes(
                      filteredTypes: types,
                      rootPath: rootPath,
                    );
              },
            ),
            const SizedBox(height: 16),
            ..._buildConditionalChildren(
                searchState, isSelectionMode, ref, context),
          ],
        ),
      ),
    );
  }
}

List<Widget> _buildConditionalChildren(
  FileSearchState searchState,
  bool isSelectionMode,
  WidgetRef ref,
  BuildContext context,
) {
  if (!searchState.hasQuery && searchState.filteredTypes.isEmpty) {
    return [const _SearchHint()];
  } else if (searchState.isSearching) {
    return [_SearchLoadingState(isIndexing: searchState.isIndexing)];
  } else if (searchState.error != null) {
    return [_SearchError(error: searchState.error!)];
  } else if (searchState.results.isEmpty) {
    return [const _NoSearchResults()];
  } else {
    final entries = searchState.results.map((r) => r.entry).toList();
    return [
      _ResultCountHeader(count: searchState.results.length),
      const SizedBox(height: 8),
      EntryGrid(
        entries: entries,
        isSelectionMode: isSelectionMode,
        shrinkWrap: true,
        onOpen: (context, ref, entry) {
          if (entry.isFolder) {
            ref
                .read(explorerControllerProvider.notifier)
                .openDirectory(entry.path);
            context.go(AppRoutes.explorer);
          } else {
            _openSearchFile(context, ref, entry, searchState.results);
          }
        },
        trailingBuilder: (context, entry) {
          if (entry.isFolder) return null;
          return IconButton(
            tooltip: 'Open folder',
            onPressed: () => _openContainingFolder(
                context,
                ref,
                entry,
                searchState.filteredTypes.isEmpty
                    ? null
                    : searchState.filteredTypes.first),
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.folder_open_rounded),
          );
        },
      ),
    ];
  }
}

void _openSearchFile(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
  List<SearchResult> results,
) {
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
      entries: [for (final r in results) r.entry],
    ),
  );
}

void _openContainingFolder(
  BuildContext context,
  WidgetRef ref,
  FileSystemEntry entry,
  FileSystemEntryType? activeFilter,
) {
  final settings = ref.read(settingsControllerProvider).settings;
  final shouldRecordFile =
      !entry.isFolder && !settings.showFoldersOnlyInHistory;

  if (activeFilter != null) {
    ref.read(explorerFilterTypeProvider.notifier).state = activeFilter;
  }
  ref.read(explorerControllerProvider.notifier).openDirectory(
        entry.isFolder ? entry.path : p.dirname(entry.path),
        recordRecent: entry.isFolder || !shouldRecordFile,
      );
  context.go(AppRoutes.explorer);
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
