import 'package:flutter/material.dart';
import 'package:oref/devtools.dart';
import 'package:oref/oref.dart' as oref;

import '../app/constants.dart';
import '../app/palette.dart';
import '../app/scopes.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/filter_group.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/inline_empty_state.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/panel.dart';

class EffectsPage extends StatelessWidget {
  const EffectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useEffectsState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final entries = samplesByKind(
          controller.snapshot?.samples ?? const <Sample>[],
          'effect',
        );
        final typeFilters = buildFilterOptions(
          entries.map((entry) => entry.type),
        );
        final scopeFilters = buildFilterOptions(
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

        return ConnectionGuard(
          child: PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Effects',
                  description:
                      'Monitor effect lifecycle, timings, and hot paths.',
                  totalCount: entries.length,
                  filteredCount: filtered.length,
                  onExport: () => exportData(
                    context,
                    'effects',
                    filtered.map((entry) => entry.toJson()).toList(),
                  ),
                  children: [
                    FilterGroup(
                      label: 'Type',
                      filters: typeFilters,
                      selectedFilter: state.typeFilter(),
                      onFilterChange: state.typeFilter.set,
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                    ),
                    const SizedBox(height: 12),
                    FilterGroup(
                      label: 'Scope',
                      filters: scopeFilters,
                      selectedFilter: state.scopeFilter(),
                      onFilterChange: state.scopeFilter.set,
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                    ),
                  ],
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

class EffectsState {
  EffectsState({required this.typeFilter, required this.scopeFilter});

  final oref.WritableSignal<String> typeFilter;
  final oref.WritableSignal<String> scopeFilter;
}

EffectsState useEffectsState(BuildContext context) {
  final typeFilter = oref.signal(
    context,
    'All',
    debugLabel: 'effects.typeFilter',
  );
  final scopeFilter = oref.signal(
    context,
    'All',
    debugLabel: 'effects.scopeFilter',
  );
  return EffectsState(typeFilter: typeFilter, scopeFilter: scopeFilter);
}

class _EffectsTimeline extends StatelessWidget {
  const _EffectsTimeline({required this.entries});

  final List<Sample> entries;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Positioned(
            left: effectsTimelineLineLeft,
            top: 0,
            bottom: 0,
            child: Container(
              width: effectsTimelineLineWidth,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          if (entries.isEmpty)
            const InlineEmptyState(
              message: 'No effects match the current filters.',
              padding: EdgeInsets.symmetric(
                horizontal: effectsTimelineHorizontalPadding,
                vertical: 16,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: effectsTimelineHorizontalPadding,
                vertical: 16,
              ),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _EffectRow(entry: entries[index]),
                    if (index != entries.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EffectRow extends StatelessWidget {
  const _EffectRow({required this.entry});

  final Sample entry;

  @override
  Widget build(BuildContext context) {
    final tone = effectColors[entry.type] ?? OrefPalette.teal;
    final runs = entry.runs ?? 0;
    final durationUs = entry.lastDurationUs ?? 0;
    final isHot = durationUs > 16000 || runs >= 8;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: effectsTimelineDotSize,
          height: effectsTimelineDotSize,
          margin: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            color: tone,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: tone.withValues(alpha: 0.4), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (isHot) const _HotBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.note.isEmpty
                      ? 'Last run ${formatAge(entry.updatedAt)}'
                      : entry.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: tone.withValues(alpha: 0.2),
                      child: Text(entry.type),
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
                      child: Text('Runs $runs'),
                    ),
                    GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: durationUs > 16000
                          ? OrefPalette.coral.withValues(alpha: 0.2)
                          : OrefPalette.lime.withValues(alpha: 0.2),
                      child: Text(formatDurationUs(durationUs)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HotBadge extends StatelessWidget {
  const _HotBadge();

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: OrefPalette.coral.withValues(alpha: 0.25),
      child: Text('HOT', style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
