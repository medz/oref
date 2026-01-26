part of '../main.dart';

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel();

  @override
  Widget build(BuildContext context) {
    final state = _useTimelinePanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final events =
            controller.snapshot?.timeline.toList() ?? const <TimelineEvent>[];
        events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final typeFilters = _buildFilterOptions(
          events.map((event) => event.type),
        );
        final severityFilters = _buildFilterOptions(
          events.map((event) => event.severity),
        );
        final filtered = events.where((event) {
          final matchesType =
              state.typeFilter() == 'All' || event.type == state.typeFilter();
          final matchesSeverity =
              state.severityFilter() == 'All' ||
              event.severity == state.severityFilter();
          return matchesType && matchesSeverity;
        }).toList();

        return _ConnectionGuard(
          child: _PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Timeline',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: 12),
                    const _GlassPill(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text('Live'),
                    ),
                    const Spacer(),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text('${filtered.length} events'),
                    ),
                    const SizedBox(width: 12),
                    _ActionPill(
                      label: 'Export',
                      icon: Icons.download_rounded,
                      onTap: () => _exportData(
                        context,
                        'timeline',
                        filtered.map((event) => event.toJson()).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Correlate signal updates with effects, batches, and collections.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Type',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    for (final filter in typeFilters)
                      _FilterChip(
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
                  children: [
                    Text(
                      'Severity',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    for (final filter in severityFilters)
                      _FilterChip(
                        label: filter,
                        isSelected: filter == state.severityFilter(),
                        onTap: () => state.severityFilter.set(filter),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _TimelineList(events: filtered),
              ],
            ),
          ),
        );
      },
    );
  }
}
