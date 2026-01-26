part of '../main.dart';

class _SignalList extends StatelessWidget {
  const _SignalList({
    required this.entries,
    required this.selectedId,
    required this.isCompact,
    required this.sortKey,
    required this.sortAscending,
    required this.onSortName,
    required this.onSortUpdated,
    required this.onSelect,
  });

  final List<Sample> entries;
  final int? selectedId;
  final bool isCompact;
  final _SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;
  final ValueChanged<Sample> onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact)
            _SignalTableHeader(
              sortKey: sortKey,
              sortAscending: sortAscending,
              onSortName: onSortName,
              onSortUpdated: onSortUpdated,
            ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No signals match the current filter.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _SignalRow(
                      entry: entries[index],
                      isSelected: selectedId == entries[index].id,
                      isCompact: isCompact,
                      onTap: () => onSelect(entries[index]),
                    ),
                    if (index != entries.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
