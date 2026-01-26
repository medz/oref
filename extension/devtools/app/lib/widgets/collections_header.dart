part of '../main.dart';

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({
    required this.controller,
    required this.typeFilter,
    required this.opFilter,
    required this.typeFilters,
    required this.opFilters,
    required this.onTypeChange,
    required this.onOpChange,
    required this.totalCount,
    required this.filteredCount,
    required this.onExport,
  });

  final TextEditingController controller;
  final String typeFilter;
  final String opFilter;
  final List<String> typeFilters;
  final List<String> opFilters;
  final ValueChanged<String> onTypeChange;
  final ValueChanged<String> onOpChange;
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
            Text('Collections', style: textTheme.headlineSmall),
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
          'Inspect reactive list, map, and set mutations.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _GlassInput(controller: controller, hintText: 'Search collections...'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Type', style: textTheme.labelMedium),
            for (final filter in typeFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == typeFilter,
                onTap: () => onTypeChange(filter),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Op', style: textTheme.labelMedium),
            for (final filter in opFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == opFilter,
                onTap: () => onOpChange(filter),
              ),
          ],
        ),
      ],
    );
  }
}
