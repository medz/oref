part of '../main.dart';

class _ComputedPanel extends StatelessWidget {
  const _ComputedPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useComputedPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        return _ConnectionGuard(
          child: _PanelScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controller = OrefDevToolsScope.of(context);
                final entries = _samplesByKind(
                  controller.snapshot?.samples ?? const <Sample>[],
                  'computed',
                );
                final isSplit = constraints.maxWidth >= 980;
                final filtered = state.filter(entries);
                final selected = entries.firstWhereOrNull(
                  (entry) => entry.id == state.selectedId(),
                );
                final list = _ComputedList(
                  entries: filtered,
                  selectedId: selected?.id,
                  isCompact: !isSplit,
                  sortKey: state.sortKey(),
                  sortAscending: state.sortAscending(),
                  onSortName: () => state.toggleSort(_SortKey.name),
                  onSortUpdated: () => state.toggleSort(_SortKey.updated),
                  onSelect: (entry) => state.toggleSelection(entry.id),
                );
                final detail = _ComputedDetail(entry: selected);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ComputedHeader(
                      controller: state.searchController,
                      selectedFilter: state.statusFilter(),
                      onFilterChange: (value) => state.statusFilter.set(value),
                      totalCount: entries.length,
                      filteredCount: filtered.length,
                      onExport: () => _exportData(
                        context,
                        'computed',
                        filtered.map((entry) => entry.toJson()).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isSplit)
                      selected == null
                          ? list
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: list),
                                const SizedBox(width: 20),
                                SizedBox(width: 320, child: detail),
                              ],
                            )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          list,
                          if (selected != null) ...[
                            const SizedBox(height: 16),
                            detail,
                          ],
                        ],
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
