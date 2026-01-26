part of '../main.dart';

class _ComputedHeader extends StatelessWidget {
  const _ComputedHeader({
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChange,
    required this.totalCount,
    required this.filteredCount,
    required this.onExport,
  });

  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onFilterChange;
  final int totalCount;
  final int filteredCount;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Computed', style: textTheme.headlineSmall),
            const SizedBox(width: 12),
            const _GlassPill(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('Live'),
            ),
            const Spacer(),
            _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('$filteredCount / $totalCount'),
            ),
            const SizedBox(width: 12),
            _ActionPill(
              label: 'Export',
              icon: Icons.download_rounded,
              onTap: onExport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Inspect derived state, cache hits, and dependency churn.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _GlassInput(
          controller: controller,
          hintText: 'Search computed values...',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in _signalFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == selectedFilter,
                onTap: () => onFilterChange(filter),
              ),
          ],
        ),
      ],
    );
  }
}
