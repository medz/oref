import 'package:flutter/material.dart';
import 'package:oref/devtools.dart' as devtools;

import '../app/palette.dart';
import '../app/scopes.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/actions.dart';
import '../shared/widgets/adaptive_wrap.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/metric_tile.dart';
import '../shared/widgets/panel.dart';

class BatchingPage extends StatelessWidget {
  const BatchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final batches =
        controller.snapshot?.batches.toList() ?? const <devtools.BatchSample>[];
    batches.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    final latest = batches.isNotEmpty ? batches.first : null;
    final totalWrites = batches.fold<int>(
      0,
      (sum, batch) => sum + batch.writeCount,
    );
    final avgDuration = batches.isEmpty
        ? 0
        : (batches.fold<int>(0, (sum, batch) => sum + batch.durationMs) /
                  batches.length)
              .round();

    return ConnectionGuard(
      child: PanelScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 860;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Batching',
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
                      child: Text('${batches.length} batches'),
                    ),
                    const SizedBox(width: 12),
                    ActionPill(
                      label: 'Export',
                      icon: Icons.download_rounded,
                      onTap: () => exportData(
                        context,
                        'batches',
                        batches.map((batch) => batch.toJson()).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Inspect batched writes and flush timing.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AdaptiveWrap(
                  children: [
                    MetricTile(
                      label: 'Batches',
                      value: formatCount(batches.length),
                      trend: formatDelta(totalWrites, suffix: 'writes'),
                      accent: OrefPalette.coral,
                      icon: Icons.layers_rounded,
                    ),
                    MetricTile(
                      label: 'Avg duration',
                      value: '${avgDuration}ms',
                      trend: latest == null ? '—' : formatAge(latest.endedAt),
                      accent: OrefPalette.indigo,
                      icon: Icons.timer_rounded,
                    ),
                    MetricTile(
                      label: 'Last batch',
                      value: latest == null ? '—' : '${latest.durationMs}ms',
                      trend: latest == null
                          ? '—'
                          : '${latest.writeCount} writes',
                      accent: OrefPalette.teal,
                      icon: Icons.bolt_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _BatchList(batches: batches, isCompact: isCompact),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BatchList extends StatelessWidget {
  const _BatchList({required this.batches, required this.isCompact});

  final List<devtools.BatchSample> batches;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact) const _BatchHeaderRow(),
          if (batches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No batches recorded yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < batches.length; index++) ...[
                    _BatchRow(batch: batches[index], isCompact: isCompact),
                    if (index != batches.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BatchHeaderRow extends StatelessWidget {
  const _BatchHeaderRow();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Batch', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Depth', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Writes', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Duration', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.center,
              child: Text('Ended', style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch, required this.isCompact});

  final devtools.BatchSample batch;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: DefaultTextStyle.merge(
        style: textTheme.bodyMedium,
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batch #${batch.id}'),
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
                        child: Text('Depth ${batch.depth}'),
                      ),
                      GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text('${batch.writeCount} writes'),
                      ),
                      GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text('${batch.durationMs}ms'),
                      ),
                      GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(formatAge(batch.endedAt)),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Batch #${batch.id}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${batch.depth}', textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${batch.writeCount}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${batch.durationMs}ms',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      formatAge(batch.endedAt),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
