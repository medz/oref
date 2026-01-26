import 'package:flutter/material.dart';
import 'package:oref/devtools.dart';
import 'package:oref/oref.dart' as oref;

import '../app/constants.dart';
import '../app/palette.dart';
import '../app/scopes.dart';
import '../shared/hooks/search_query.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/filter_chip.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/panel.dart';
import '../shared/widgets/sort_header_cell.dart';
import '../shared/widgets/table_header_row.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useCollectionsState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final entries = samplesByKind(
          controller.snapshot?.samples ?? const <Sample>[],
          'collection',
        );
        final typeFilters = buildFilterOptions(
          entries.map((entry) => entry.type),
        );
        final opFilters = buildFilterOptions(
          entries.map((entry) => entry.operation ?? 'Idle'),
        );
        final filtered = state.filter(entries);

        return ConnectionGuard(
          child: PanelScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 860;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(
                      title: 'Collections',
                      description:
                          'Inspect reactive list, map, and set mutations.',
                      totalCount: entries.length,
                      filteredCount: filtered.length,
                      onExport: () => exportData(
                        context,
                        'collections',
                        filtered.map((entry) => entry.toJson()).toList(),
                      ),
                      children: [
                        GlassInput(
                          controller: state.searchController,
                          hintText: 'Search collections...',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Type',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            for (final filter in typeFilters)
                              FilterChipButton(
                                label: filter,
                                isSelected: filter == state.typeFilter(),
                                onTap: () => state.typeFilter.set(filter),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Op',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            for (final filter in opFilters)
                              FilterChipButton(
                                label: filter,
                                isSelected: filter == state.opFilter(),
                                onTap: () => state.opFilter.set(filter),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CollectionsList(
                      entries: filtered,
                      isCompact: isCompact,
                      sortKey: state.sortKey(),
                      sortAscending: state.sortAscending(),
                      onSortName: () => state.toggleSort(SortKey.name),
                      onSortUpdated: () => state.toggleSort(SortKey.updated),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class CollectionsState {
  CollectionsState({
    required this.searchController,
    required this.searchQuery,
    required this.typeFilter,
    required this.opFilter,
    required this.sortKey,
    required this.sortAscending,
  });

  final TextEditingController searchController;
  final oref.WritableSignal<String> searchQuery;
  final oref.WritableSignal<String> typeFilter;
  final oref.WritableSignal<String> opFilter;
  final oref.WritableSignal<SortKey> sortKey;
  final oref.WritableSignal<bool> sortAscending;

  void toggleSort(SortKey key) {
    if (sortKey() == key) {
      sortAscending.set(!sortAscending());
    } else {
      sortKey.set(key);
      sortAscending.set(key == SortKey.name);
    }
  }

  List<Sample> filter(List<Sample> entries) {
    final query = searchQuery().trim().toLowerCase();
    final currentType = typeFilter();
    final currentOp = opFilter();
    final currentSortKey = sortKey();
    final ascending = sortAscending();
    final filtered = entries.where((entry) {
      final matchesQuery =
          query.isEmpty || entry.label.toLowerCase().contains(query);
      final matchesType = currentType == 'All' || entry.type == currentType;
      final matchesOp =
          currentOp == 'All' || (entry.operation ?? 'Idle') == currentOp;
      return matchesQuery && matchesType && matchesOp;
    }).toList();
    filtered.sort(
      (a, b) => compareSort(
        currentSortKey,
        ascending,
        a.label,
        b.label,
        a.updatedAt,
        b.updatedAt,
        a.id,
        b.id,
      ),
    );
    return filtered;
  }
}

CollectionsState useCollectionsState(BuildContext context) {
  final searchState = useSearchQueryState(
    context,
    debugLabel: 'collections.search',
  );
  final typeFilter = oref.signal(
    context,
    'All',
    debugLabel: 'collections.typeFilter',
  );
  final opFilter = oref.signal(
    context,
    'All',
    debugLabel: 'collections.opFilter',
  );
  final sortKey = oref.signal(
    context,
    SortKey.updated,
    debugLabel: 'collections.sortKey',
  );
  final sortAscending = oref.signal(
    context,
    false,
    debugLabel: 'collections.sortAscending',
  );
  return CollectionsState(
    searchController: searchState.controller,
    searchQuery: searchState.query,
    typeFilter: typeFilter,
    opFilter: opFilter,
    sortKey: sortKey,
    sortAscending: sortAscending,
  );
}

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
  final SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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

class _CollectionsHeaderRow extends StatelessWidget {
  const _CollectionsHeaderRow({
    required this.sortKey,
    required this.sortAscending,
    required this.onSortName,
    required this.onSortUpdated,
  });

  final SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return TableHeaderRow(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SortHeaderCell(
              label: 'Collection',
              isActive: sortKey == SortKey.name,
              ascending: sortAscending,
              onTap: onSortName,
              style: labelStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Type', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Op', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Scope', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: SortHeaderCell(
              label: 'Updated',
              isActive: sortKey == SortKey.updated,
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

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.entry, required this.isCompact});

  final Sample entry;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final tone =
        collectionOpColors[entry.operation ?? 'Idle'] ?? OrefPalette.teal;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: DefaultTextStyle.merge(
        style: textTheme.bodyMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(entry.type),
                      ),
                      GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: tone.withValues(alpha: 0.22),
                        child: Text(entry.operation ?? 'Idle'),
                      ),
                      GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(entry.scope),
                      ),
                      GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(formatAge(entry.updatedAt)),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(entry.label, textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(entry.type, textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: tone.withValues(alpha: 0.22),
                        child: Text(entry.operation ?? 'Idle'),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(entry.scope, textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      formatAge(entry.updatedAt),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final delta in entry.deltas ?? const [])
                  _DiffToken(delta: delta),
              ],
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(entry.note, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiffToken extends StatelessWidget {
  const _DiffToken({required this.delta});

  final CollectionDelta delta;

  @override
  Widget build(BuildContext context) {
    final style = deltaStyles[delta.kind] ?? OrefPalette.indigo;
    final prefix = switch (delta.kind) {
      'add' => '+',
      'remove' => '-',
      _ => '±',
    };

    return GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: style.withValues(alpha: 0.18),
      child: Text('$prefix ${delta.label}'),
    );
  }
}
