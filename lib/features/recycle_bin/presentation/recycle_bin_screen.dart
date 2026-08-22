import 'package:file_explorer/features/recycle_bin/domain/entities/trash_item.dart';
import 'package:file_explorer/features/recycle_bin/presentation/controllers/recycle_bin_controller.dart';
import 'package:file_explorer/features/recycle_bin/presentation/widgets/trash_item_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({required this.rootPath, super.key});

  final String rootPath;

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recycleBinControllerProvider.notifier).load(widget.rootPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recycleBinControllerProvider);
    final controller = ref.read(recycleBinControllerProvider.notifier);
    final isGrid = ref.watch(recycleBinGridViewProvider);
    final selectedItems = state.items
        .where((item) => _selectedIds.contains(item.id))
        .toList(growable: false);
    final allSelected =
        state.items.isNotEmpty && _selectedIds.length == state.items.length;

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Exit selection',
                onPressed: _exitSelection,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        title: Text(
          _selectionMode ? '${_selectedIds.length} selected' : 'Recycle bin',
        ),
        actions: _selectionMode
            ? [
                IconButton(
                  tooltip: allSelected ? 'Clear selection' : 'Select all',
                  onPressed: () => _toggleSelectAll(state.items, allSelected),
                  icon: Icon(
                    allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Restore selected',
                  onPressed: selectedItems.isEmpty
                      ? null
                      : () => _restoreSelected(controller, selectedItems),
                  icon: const Icon(Icons.restore_rounded),
                ),
                IconButton(
                  tooltip: 'Delete selected',
                  onPressed: selectedItems.isEmpty
                      ? null
                      : () => _deleteSelected(controller, selectedItems),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ]
            : [
                if (state.items.isNotEmpty) ...[
                  IconButton(
                    tooltip: isGrid ? 'List view' : 'Grid view',
                    onPressed: () => ref
                        .read(recycleBinGridViewProvider.notifier)
                        .state = !isGrid,
                    icon: Icon(
                      isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Empty recycle bin',
                    onPressed: () => _confirmEmpty(context, controller),
                    icon: const Icon(Icons.delete_sweep_rounded),
                  ),
                ],
              ],
      ),
      body: switch (state) {
        RecycleBinState(loading: true) =>
          const Center(child: CircularProgressIndicator()),
        RecycleBinState(error: final error?) => Center(child: Text(error)),
        RecycleBinState(items: final items) => items.isEmpty
            ? const _EmptyView()
            : isGrid
                ? _buildGrid(items)
                : _buildList(items),
      },
    );
  }

  Widget _buildList(List<TrashItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return TrashItemListTile(
          item: item,
          selectionMode: _selectionMode,
          selected: _selectedIds.contains(item.id),
          onTap: () => _onItemTap(item),
          onLongPress: () => _enterSelection(item),
          onRestore: () => ref
              .read(recycleBinControllerProvider.notifier)
              .restore(item),
          onDelete: () => ref
              .read(recycleBinControllerProvider.notifier)
              .deletePermanently(item),
        );
      },
    );
  }

  Widget _buildGrid(List<TrashItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = (constraints.maxWidth / 92).floor().clamp(4, 8);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisExtent: 114,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return TrashItemGridTile(
              item: item,
              selectionMode: _selectionMode,
              selected: _selectedIds.contains(item.id),
              onTap: () => _onItemTap(item),
              onLongPress: () => _enterSelection(item),
            );
          },
        );
      },
    );
  }

  void _enterSelection(TrashItem item) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(item.id);
    });
  }

  void _onItemTap(TrashItem item) {
    if (!_selectionMode) return;
    setState(() {
      if (!_selectedIds.add(item.id)) {
        _selectedIds.remove(item.id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _toggleSelectAll(List<TrashItem> items, bool allSelected) {
    setState(() {
      if (allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(items.map((item) => item.id));
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _restoreSelected(
    RecycleBinController controller,
    List<TrashItem> items,
  ) async {
    _exitSelection();
    await controller.restoreMany(items);
  }

  Future<void> _deleteSelected(
    RecycleBinController controller,
    List<TrashItem> items,
  ) async {
    final confirmed = await _confirmPermanentDelete(context, items.length);
    if (confirmed != true) return;
    _exitSelection();
    await controller.deleteMany(items);
  }

  Future<bool?> _confirmPermanentDelete(
    BuildContext context,
    int count,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count item${count == 1 ? '' : 's'}?'),
        content: const Text(
          'This permanently deletes the selected items and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEmpty(
    BuildContext context,
    RecycleBinController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty recycle bin?'),
        content: const Text(
          'This permanently deletes everything in the recycle bin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empty'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.emptyTrash();
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('Recycle bin is empty'),
        ],
      ),
    );
  }
}
