import 'package:flutter/material.dart';

import '../app/palette.dart';
import '../app/scopes.dart';
import '../services/oref_service.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/adaptive_wrap.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/inline_empty_state.dart';
import '../shared/widgets/metric_tile.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/panel.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final samples = controller.performance;
    final latest = samples.isNotEmpty ? samples.first : null;

    return ConnectionGuard(
      child: PanelScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Performance',
              description: 'Sampled signal throughput and effect costs.',
              totalCount: samples.length,
              filteredCount: samples.length,
              countText: '${samples.length} samples',
              onExport: () => exportData(
                context,
                'performance',
                samples.map((sample) => sample.toJson()).toList(),
              ),
            ),
            const SizedBox(height: 16),
            AdaptiveWrap(
              children: [
                MetricTile(
                  label: 'Effect avg',
                  value: latest == null
                      ? '—'
                      : formatDurationUs(latest.avgEffectDurationUs.round()),
                  trend: latest == null ? '—' : '${latest.effectRuns} runs',
                  accent: OrefPalette.pink,
                  icon: Icons.speed_rounded,
                ),
                MetricTile(
                  label: 'Signal writes',
                  value: latest == null ? '—' : '${latest.signalWrites}',
                  trend: latest == null
                      ? '—'
                      : '${latest.collectionMutations} mutations',
                  accent: OrefPalette.teal,
                  icon: Icons.bolt_rounded,
                ),
                MetricTile(
                  label: 'Collections',
                  value: latest == null ? '—' : '${latest.collectionCount}',
                  trend: latest == null ? '—' : '${latest.batchWrites} batched',
                  accent: OrefPalette.indigo,
                  icon: Icons.grid_view_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PerformanceList(samples: samples),
          ],
        ),
      ),
    );
  }
}

class _PerformanceList extends StatelessWidget {
  const _PerformanceList({required this.samples});

  final List<UiPerformanceSample> samples;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: samples.isEmpty
          ? const InlineEmptyState(
              message: 'No performance samples yet.',
              padding: EdgeInsets.all(16),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var index = 0; index < samples.length; index++) ...[
                    _PerformanceRow(sample: samples[index]),
                    if (index != samples.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.sample});

  final UiPerformanceSample sample;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle.merge(
        style: textTheme.bodyMedium,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                formatAge(sample.timestamp),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${sample.signalWrites} writes',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${sample.effectRuns} runs',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatDurationUs(sample.avgEffectDurationUs.round()),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${sample.collectionMutations} mutations',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
