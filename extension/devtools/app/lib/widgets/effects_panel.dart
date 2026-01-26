part of '../main.dart';

class _EffectsPanel extends StatelessWidget {
  const _EffectsPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useEffectsPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final entries = _samplesByKind(
          controller.snapshot?.samples ?? const <Sample>[],
          'effect',
        );
        final typeFilters = _buildFilterOptions(
          entries.map((entry) => entry.type),
        );
        final scopeFilters = _buildFilterOptions(
          entries.map((entry) => entry.scope),
        );
        final filtered = entries.where((entry) {
          final matchesType =
              state.typeFilter() == 'All' || entry.type == state.typeFilter();
          final matchesScope =
              state.scopeFilter() == 'All' ||
              entry.scope == state.scopeFilter();
          return matchesType && matchesScope;
        }).toList();

        return _ConnectionGuard(
          child: _PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EffectsHeader(
                  typeFilter: state.typeFilter(),
                  scopeFilter: state.scopeFilter(),
                  typeFilters: typeFilters,
                  scopeFilters: scopeFilters,
                  onTypeChange: (value) => state.typeFilter.set(value),
                  onScopeChange: (value) => state.scopeFilter.set(value),
                  totalCount: entries.length,
                  filteredCount: filtered.length,
                  onExport: () => _exportData(
                    context,
                    'effects',
                    filtered.map((entry) => entry.toJson()).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _EffectsTimeline(entries: filtered),
              ],
            ),
          ),
        );
      },
    );
  }
}
