part of '../main.dart';

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.activeNodes,
    required this.totalNodes,
    required this.watchedNodes,
    required this.activityRate,
    required this.activityProgress,
  });

  final int activeNodes;
  final int totalNodes;
  final int watchedNodes;
  final int activityRate;
  final double activityProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Snapshot', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Service health and steady-state metrics.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _HealthBar(
            label: 'Active nodes',
            value: totalNodes == 0 ? '—' : '$activeNodes / $totalNodes',
            progress: totalNodes == 0 ? 0 : activeNodes / totalNodes,
            color: OrefPalette.teal,
          ),
          const SizedBox(height: 12),
          _HealthBar(
            label: 'Watched nodes',
            value: totalNodes == 0 ? '—' : '$watchedNodes watched',
            progress: totalNodes == 0 ? 0 : watchedNodes / totalNodes,
            color: OrefPalette.indigo,
          ),
          const SizedBox(height: 12),
          _HealthBar(
            label: 'Update rate',
            value: activityRate == 0 ? '—' : '$activityRate/min',
            progress: activityProgress,
            color: OrefPalette.coral,
          ),
        ],
      ),
    );
  }
}
