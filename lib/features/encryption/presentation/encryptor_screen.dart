import 'package:file_explorer/features/encryption/data/encryption_repository.dart';
import 'package:file_explorer/features/encryption/presentation/encryption_actions.dart';
import 'package:file_explorer/features/encryption/presentation/widgets/encrypted_file_tiles.dart';
import 'package:file_explorer/features/explorer/presentation/controllers/explorer_controller.dart';
import 'package:file_explorer/features/transfers/domain/entities/transfer_task.dart';
import 'package:file_explorer/features/transfers/presentation/controllers/transfer_controller.dart';
import 'package:file_explorer/shared/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EncryptorScreen extends ConsumerStatefulWidget {
  const EncryptorScreen({super.key});

  @override
  ConsumerState<EncryptorScreen> createState() => _EncryptorScreenState();
}

class _EncryptorScreenState extends ConsumerState<EncryptorScreen> {
  final Set<String> _selectedPaths = {};
  bool _selectionMode = false;
  bool _grid = false;

  List<EncryptedFileEntry> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    final root = _primaryRoot(ref.read(explorerControllerProvider));
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await scanEncryptedFiles(root);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _selectionMode = false;
        _selectedPaths.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  String _primaryRoot(ExplorerState state) {
    final volumes = state.volumes.value ?? const [];
    for (final volume in volumes) {
      if (volume.isPrimary) return volume.path;
    }
    return volumes.isNotEmpty ? volumes.first.path : '/';
  }

  Future<void> _decrypt(EncryptedFileEntry item) async {
    await decryptPathWithDialog(context, ref, item.path);
  }

  Future<void> _decryptSelected() async {
    final paths = _selectedPaths.toList();
    _exitSelection();
    await decryptPathsWithDialog(context, ref, paths);
  }

  void _enterSelection(EncryptedFileEntry item) {
    setState(() {
      _selectionMode = true;
      _selectedPaths.add(item.path);
    });
  }

  void _onItemTap(EncryptedFileEntry item) {
    if (!_selectionMode) {
      _decrypt(item);
      return;
    }
    setState(() {
      if (!_selectedPaths.add(item.path)) {
        _selectedPaths.remove(item.path);
      }
      if (_selectedPaths.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedPaths.length == _items.length) {
        _selectedPaths.clear();
      } else {
        _selectedPaths.addAll(_items.map((e) => e.path));
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedPaths.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _items.isNotEmpty && _selectedPaths.length == _items.length;

    ref.listen<TransferState>(transferControllerProvider, (previous, next) {
      final previousById = {
        for (final task in previous?.tasks ?? const <TransferTask>[])
          task.id: task.status,
      };
      final encryptionFinished = next.tasks.any((task) {
        final isEncryptionTask = task.operation == TransferOperation.encrypt ||
            task.operation == TransferOperation.decrypt;
        return isEncryptionTask &&
            task.status == TransferTaskStatus.completed &&
            previousById[task.id] != TransferTaskStatus.completed;
      });
      if (encryptionFinished) {
        _scan();
      }
    });

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
          _selectionMode ? '${_selectedPaths.length} selected' : 'Encryptor',
        ),
        actions: _selectionMode
            ? [
                IconButton(
                  tooltip: allSelected ? 'Clear selection' : 'Select all',
                  onPressed: _toggleSelectAll,
                  icon: Icon(
                    allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Decrypt selected',
                  onPressed: _selectedPaths.isEmpty ? null : _decryptSelected,
                  icon: const Icon(Icons.lock_open_rounded),
                ),
              ]
            : [
                if (_items.isNotEmpty)
                  IconButton(
                    tooltip: _grid ? 'List view' : 'Grid view',
                    onPressed: () => setState(() => _grid = !_grid),
                    icon: Icon(
                      _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    ),
                  ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _scan,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              const Icon(Icons.error_outline_rounded, size: 42),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('No encrypted files found'),
          ],
        ),
      );
    }
    return _grid ? _buildGrid() : _buildList();
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _items[index];
        return EncryptedFileListTile(
          item: item,
          selectionMode: _selectionMode,
          selected: _selectedPaths.contains(item.path),
          onTap: () => _onItemTap(item),
          onLongPress: () => _enterSelection(item),
        );
      },
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = (constraints.maxWidth / 92).floor().clamp(4, 8);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisExtent: 114,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final item = _items[index];
            return EncryptedFileGridTile(
              item: item,
              selectionMode: _selectionMode,
              selected: _selectedPaths.contains(item.path),
              onTap: () => _onItemTap(item),
              onLongPress: () => _enterSelection(item),
            );
          },
        );
      },
    );
  }
}
