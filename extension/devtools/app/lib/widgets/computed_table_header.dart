part of '../main.dart';

class _ComputedTableHeader extends StatelessWidget {
  const _ComputedTableHeader({
    required this.sortKey,
    required this.sortAscending,
    required this.onSortName,
    required this.onSortUpdated,
  });

  final _SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _SortHeaderCell(
              label: 'Computed',
              isActive: sortKey == _SortKey.name,
              ascending: sortAscending,
              onTap: onSortName,
              style: labelStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Value', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Status', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Runs', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: _SortHeaderCell(
              label: 'Updated',
              isActive: sortKey == _SortKey.updated,
              ascending: sortAscending,
              onTap: onSortUpdated,
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}
