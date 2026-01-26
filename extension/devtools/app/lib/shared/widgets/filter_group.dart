import 'package:flutter/material.dart';

import 'filter_chip.dart';

class FilterGroup extends StatelessWidget {
  const FilterGroup({
    required this.label,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChange,
    this.spacing = 8,
    this.runSpacing = 8,
    this.crossAxisAlignment,
    super.key,
  });

  final String label;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChange;
  final double spacing;
  final double runSpacing;
  final WrapCrossAlignment? crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      crossAxisAlignment: crossAxisAlignment ?? WrapCrossAlignment.start,
      children: [
        Text(label, style: textTheme.labelMedium),
        for (final filter in filters)
          FilterChipButton(
            label: filter,
            isSelected: filter == selectedFilter,
            onTap: () => onFilterChange(filter),
          ),
      ],
    );
  }
}
