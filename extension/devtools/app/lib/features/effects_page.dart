import 'package:flutter/material.dart';
import 'package:oref/devtools.dart';
import 'package:oref/oref.dart' as oref;

import '../app/constants.dart';
import '../app/palette.dart';
import '../app/scopes.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/actions.dart';
import '../shared/widgets/filter_chip.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/live_badge.dart';
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
                _EffectsHeader(
                  typeFilter: state.typeFilter(),
                  scopeFilter: state.scopeFilter(),
                  typeFilters: typeFilters,
                  scopeFilters: scopeFilters,
                  onTypeChange: (value) => state.typeFilter.set(value),
                  onScopeChange: (value) => state.scopeFilter.set(value),
                  totalCount: entries.length,
                  filteredCount: filtered.length,
                  onExport: () => exportData(
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
            const LiveBadge(),
            const Spacer(),
            GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('$filteredCount / $totalCount'),
            ),
            const SizedBox(width: 12),
            ActionPill(
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
              FilterChipButton(
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
              FilterChipButton(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No effects match the current filters.',
                style: Theme.of(context).textTheme.bodyMedium,
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
