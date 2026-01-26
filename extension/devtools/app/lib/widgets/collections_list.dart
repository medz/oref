part of '../main.dart';

class _CollectionsList extends StatelessWidget {
  const _CollectionsList({
    required this.entries,
    required this.isCompact,
    required this.sortKey,
    required this.sortAscending,
    required this.onSortName,
    required this.onSortUpdated,
  });

  final List<Sample> entries;
  final bool isCompact;
  final _SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact)
            _CollectionsHeaderRow(
              sortKey: sortKey,
              sortAscending: sortAscending,
              onSortName: onSortName,
              onSortUpdated: onSortUpdated,
            ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No collection mutations match the current filters.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _CollectionRow(entry: entries[index], isCompact: isCompact),
                    if (index != entries.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
