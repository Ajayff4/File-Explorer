import 'package:flutter/material.dart';

enum _RangeAction { between, first, last }

/// Overflow menu shared by Explorer and Search for range selection actions.
class SelectionRangeMenu extends StatelessWidget {
  const SelectionRangeMenu({
    required this.onSelectBetween,
    required this.onSelectFirst,
    required this.onSelectLast,
    super.key,
  });

  /// Fills the range between the lowest and highest selected entries.
  /// Pass `null` to disable when fewer than two entries are selected.
  final VoidCallback? onSelectBetween;

  /// Extends the selection from the anchor to the first entry.
  final VoidCallback onSelectFirst;

  /// Extends the selection from the anchor to the last entry.
  final VoidCallback onSelectLast;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RangeAction>(
      tooltip: 'Range selection',
      icon: const Icon(Icons.linear_scale_rounded),
      onSelected: (action) {
        switch (action) {
          case _RangeAction.between:
            onSelectBetween?.call();
            break;
          case _RangeAction.first:
            onSelectFirst();
            break;
          case _RangeAction.last:
            onSelectLast();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _RangeAction.between,
          enabled: onSelectBetween != null,
          child: const _RangeMenuItem(
            icon: Icons.linear_scale_rounded,
            label: 'Select between selected',
          ),
        ),
        const PopupMenuItem(
          value: _RangeAction.first,
          child: _RangeMenuItem(
            icon: Icons.vertical_align_top_rounded,
            label: 'Select first item',
          ),
        ),
        const PopupMenuItem(
          value: _RangeAction.last,
          child: _RangeMenuItem(
            icon: Icons.vertical_align_bottom_rounded,
            label: 'Select last item',
          ),
        ),
      ],
    );
  }
}

class _RangeMenuItem extends StatelessWidget {
  const _RangeMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
