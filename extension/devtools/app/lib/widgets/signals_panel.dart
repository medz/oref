part of '../main.dart';

class _SignalsPanel extends StatelessWidget {
  const _SignalsPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useSignalsPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        return _ConnectionGuard(
          child: _PanelScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controller = OrefDevToolsScope.of(context);
                final entries = _samplesByKind(
                  controller.snapshot?.samples ?? const <Sample>[],
                  'signal',
                );
                final isSplit = constraints.maxWidth >= 980;
                final filtered = state.filter(entries);
                final selected = entries.firstWhereOrNull(
                  (entry) => entry.id == state.selectedId(),
                );
                final list = _SignalList(
                  entries: filtered,
                  selectedId: selected?.id,
                  isCompact: !isSplit,
                  sortKey: state.sortKey(),
                  sortAscending: state.sortAscending(),
                  onSortName: () => state.toggleSort(_SortKey.name),
                  onSortUpdated: () => state.toggleSort(_SortKey.updated),
                  onSelect: (entry) => state.toggleSelection(entry.id),
                );
                final detail = _SignalDetail(entry: selected);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SignalsHeader(
                      controller: state.searchController,
                      selectedFilter: state.statusFilter(),
                      onFilterChange: (value) => state.statusFilter.set(value),
                      totalCount: entries.length,
                      filteredCount: filtered.length,
                      onExport: () => _exportData(
                        context,
                        'signals',
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
