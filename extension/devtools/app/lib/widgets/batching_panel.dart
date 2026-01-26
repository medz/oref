part of '../main.dart';

class _BatchingPanel extends StatelessWidget {
  const _BatchingPanel();

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final batches =
        controller.snapshot?.batches.toList() ?? const <BatchSample>[];
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

    return _ConnectionGuard(
      child: _PanelScrollView(
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
                      child: Text('${batches.length} batches'),
                    ),
                    const SizedBox(width: 12),
                    _ActionPill(
                      label: 'Export',
                      icon: Icons.download_rounded,
                      onTap: () => _exportData(
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
                _AdaptiveWrap(
                  children: [
                    _MetricTile(
                      label: 'Batches',
                      value: _formatCount(batches.length),
                      trend: _formatDelta(totalWrites, suffix: 'writes'),
                      accent: OrefPalette.coral,
                      icon: Icons.layers_rounded,
                    ),
                    _MetricTile(
                      label: 'Avg duration',
                      value: '${avgDuration}ms',
                      trend: latest == null ? '—' : _formatAge(latest.endedAt),
                      accent: OrefPalette.indigo,
                      icon: Icons.timer_rounded,
                    ),
                    _MetricTile(
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
