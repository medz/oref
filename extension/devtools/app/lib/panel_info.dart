part of 'main.dart';

class _PanelInfo {
  const _PanelInfo({
    required this.title,
    required this.description,
    required this.bullets,
  });

  final String title;
  final String description;
  final List<String> bullets;
}

const _panelInfo = {
  'Computed': _PanelInfo(
    title: 'Computed',
    description: 'Understand derived state and cache behavior.',
    bullets: [
      'Dependency graph preview',
      'Cache hit / miss ratio',
      'Invalidation cascade list',
    ],
  ),
  'Effects': _PanelInfo(
    title: 'Effects',
    description: 'Track effect execution and lifecycle changes.',
    bullets: [
      'Timeline with rerun counts',
      'Execution duration stats',
      'Dispose + scope diagnostics',
    ],
  ),
  'Collections': _PanelInfo(
    title: 'Collections',
    description: 'Audit reactive lists, maps, and sets.',
    bullets: [
      'Mutation history',
      'Diff view for changes',
      'Batch operations overview',
    ],
  ),
  'Batching': _PanelInfo(
    title: 'Batching',
    description: 'Inspect batched writes and flush timing.',
    bullets: [
      'Grouped updates per frame',
      'Longest batch duration',
      'Hot write sources',
    ],
  ),
  'Timeline': _PanelInfo(
    title: 'Timeline',
    description: 'Correlate signal updates with frame rendering.',
    bullets: [
      'Frame markers + signal spikes',
      'CPU / UI jank overlay',
      'Exportable diagnostics',
    ],
  ),
  'Performance': _PanelInfo(
    title: 'Performance',
    description: 'Track frame costs and signal churn hotspots.',
    bullets: [
      'Frame budget + jank markers',
      'Top signal recomputes',
      'Slow effects callouts',
    ],
  ),
  'Settings': _PanelInfo(
    title: 'Settings',
    description: 'Tune how diagnostics are collected.',
    bullets: [
      'Sampling frequency',
      'Auto capture thresholds',
      'Export + privacy controls',
    ],
  ),
};
