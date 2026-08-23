import 'package:flutter_riverpod/legacy.dart';

enum ExplorerViewMode { list, grid }

final explorerViewModeProvider = StateProvider<ExplorerViewMode>((ref) {
  return ExplorerViewMode.grid;
});
