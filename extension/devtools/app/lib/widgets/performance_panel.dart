part of '../main.dart';

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel();

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final samples = controller.performance;
    final latest = samples.isNotEmpty ? samples.first : null;

    return _ConnectionGuard(
      child: _PanelScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 12),
                const _GlassPill(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text('Live'),
                ),
                const Spacer(),
                _GlassPill(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text('${samples.length} samples'),
                ),
                const SizedBox(width: 12),
                _ActionPill(
                  label: 'Export',
                  icon: Icons.download_rounded,
                  onTap: () => _exportData(
                    context,
                    'performance',
                    samples.map((sample) => sample.toJson()).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sampled signal throughput and effect costs.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _AdaptiveWrap(
              children: [
                _MetricTile(
                  label: 'Effect avg',
                  value: latest == null
                      ? '—'
                      : _formatDurationUs(latest.avgEffectDurationUs.round()),
                  trend: latest == null ? '—' : '${latest.effectRuns} runs',
                  accent: OrefPalette.pink,
                  icon: Icons.speed_rounded,
                ),
                _MetricTile(
                  label: 'Signal writes',
                  value: latest == null ? '—' : '${latest.signalWrites}',
                  trend: latest == null
                      ? '—'
                      : '${latest.collectionMutations} mutations',
                  accent: OrefPalette.teal,
                  icon: Icons.bolt_rounded,
                ),
                _MetricTile(
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
