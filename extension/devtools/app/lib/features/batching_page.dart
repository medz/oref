import 'package:flutter/material.dart';
import 'package:oref/devtools.dart' as devtools;

import '../app/palette.dart';
import '../app/scopes.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/adaptive_wrap.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/inline_empty_state.dart';
import '../shared/widgets/metric_tile.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/panel.dart';
import '../shared/widgets/table_header_row.dart';

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
                PageHeader(
                  title: 'Batching',
                  description: 'Inspect batched writes and flush timing.',
                  totalCount: batches.length,
                  filteredCount: batches.length,
                  countText: '${batches.length} batches',
                  onExport: () => exportData(
                    context,
                    'batches',
                    batches.map((batch) => batch.toJson()).toList(),
                  ),
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
            const InlineEmptyState(
              message: 'No batches recorded yet.',
              padding: EdgeInsets.all(16),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var index = 0; index < batches.length; index++) ...[
                    _BatchRow(batch: batches[index], isCompact: isCompact),
                    if (index != batches.length - 1) const SizedBox(height: 12),
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

    return TableHeaderRow(
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
