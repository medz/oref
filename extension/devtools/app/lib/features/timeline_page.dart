import 'package:flutter/material.dart';
import 'package:oref/devtools.dart' as devtools;
import 'package:oref/oref.dart' as oref;

import '../app/constants.dart';
import '../app/palette.dart';
import '../app/scopes.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/actions.dart';
import '../shared/widgets/filter_chip.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/panel.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useTimelineState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final events =
            controller.snapshot?.timeline.toList() ??
            const <devtools.TimelineEvent>[];
        events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final typeFilters = buildFilterOptions(
          events.map((event) => event.type),
        );
        final severityFilters = buildFilterOptions(
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

        return ConnectionGuard(
          child: PanelScrollView(
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
                    const GlassPill(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text('Live'),
                    ),
                    const Spacer(),
                    GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text('${filtered.length} events'),
                    ),
                    const SizedBox(width: 12),
                    ActionPill(
                      label: 'Export',
                      icon: Icons.download_rounded,
                      onTap: () => exportData(
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
                  children: [
                    Text(
                      'Severity',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    for (final filter in severityFilters)
                      FilterChipButton(
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

class TimelineState {
  TimelineState({required this.typeFilter, required this.severityFilter});

  final oref.WritableSignal<String> typeFilter;
  final oref.WritableSignal<String> severityFilter;
}

TimelineState useTimelineState(BuildContext context) {
  final typeFilter = oref.signal(
    context,
    'All',
    debugLabel: 'timeline.typeFilter',
  );
  final severityFilter = oref.signal(
    context,
    'All',
    debugLabel: 'timeline.severityFilter',
  );
  return TimelineState(typeFilter: typeFilter, severityFilter: severityFilter);
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.events});

  final List<devtools.TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: events.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No timeline events yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var index = 0; index < events.length; index++) ...[
                    _TimelineEventRow(event: events[index]),
                    if (index != events.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({required this.event});

  final devtools.TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final tone = timelineColors[event.type] ?? OrefPalette.teal;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  formatTimelineDetail(event),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatAge(event.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
