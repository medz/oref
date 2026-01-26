part of '../main.dart';

class _EffectsHeader extends StatelessWidget {
  const _EffectsHeader({
    required this.typeFilter,
    required this.scopeFilter,
    required this.typeFilters,
    required this.scopeFilters,
    required this.onTypeChange,
    required this.onScopeChange,
    required this.totalCount,
    required this.filteredCount,
    required this.onExport,
  });

  final String typeFilter;
  final String scopeFilter;
  final List<String> typeFilters;
  final List<String> scopeFilters;
  final ValueChanged<String> onTypeChange;
  final ValueChanged<String> onScopeChange;
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
            Text('Effects', style: textTheme.headlineSmall),
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
          'Monitor effect lifecycle, timings, and hot paths.',
          style: textTheme.bodyMedium,
        ),
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
            Text('Scope', style: textTheme.labelMedium),
            for (final filter in scopeFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == scopeFilter,
                onTap: () => onScopeChange(filter),
              ),
          ],
        ),
      ],
    );
  }
}
