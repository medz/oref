part of '../main.dart';

class _CollectionsPanel extends StatelessWidget {
  const _CollectionsPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useCollectionsPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final entries = _samplesByKind(
          controller.snapshot?.samples ?? const <Sample>[],
          'collection',
        );
        final typeFilters = _buildFilterOptions(
          entries.map((entry) => entry.type),
        );
        final opFilters = _buildFilterOptions(
          entries.map((entry) => entry.operation ?? 'Idle'),
        );
        final filtered = state.filter(entries);

        return _ConnectionGuard(
          child: _PanelScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 860;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CollectionsHeader(
                      controller: state.searchController,
                      typeFilter: state.typeFilter(),
                      opFilter: state.opFilter(),
                      typeFilters: typeFilters,
                      opFilters: opFilters,
                      onTypeChange: (value) => state.typeFilter.set(value),
                      onOpChange: (value) => state.opFilter.set(value),
                      totalCount: entries.length,
                      filteredCount: filtered.length,
                      onExport: () => _exportData(
                        context,
                        'collections',
                        filtered.map((entry) => entry.toJson()).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CollectionsList(
                      entries: filtered,
                      isCompact: isCompact,
                      sortKey: state.sortKey(),
                      sortAscending: state.sortAscending(),
                      onSortName: () => state.toggleSort(_SortKey.name),
                      onSortUpdated: () => state.toggleSort(_SortKey.updated),
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
