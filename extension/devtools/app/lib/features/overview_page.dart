import 'package:flutter/material.dart';
import 'package:oref/devtools.dart' as devtools;

import '../app/constants.dart';
import '../app/palette.dart';
import '../app/scopes.dart';
import '../services/oref_service.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/adaptive_wrap.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/inline_empty_state.dart';
import '../shared/widgets/info_row.dart';
import '../shared/widgets/metric_tile.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/panel.dart';
import 'overview/widgets/overview_actions.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = OrefDevToolsScope.of(context);
    final snapshot = controller.snapshot;
    final samples = snapshot?.samples ?? const <devtools.Sample>[];
    final signals = samplesByKind(samples, 'signal');
    final computed = samplesByKind(samples, 'computed');
    final effects = samplesByKind(samples, 'effect');
    final collections = samplesByKind(samples, 'collection');
    final batches =
        snapshot?.batches.toList() ?? const <devtools.BatchSample>[];
    batches.sort((a, b) => a.endedAt.compareTo(b.endedAt));
    final timelineEvents =
        snapshot?.timeline.toList() ?? const <devtools.TimelineEvent>[];
    timelineEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final performance = controller.performance;
    final settings = snapshot?.settings ?? const devtools.DevToolsSettings();
    final canInteract = controller.connected;

    String summarizeTop<T>(
      List<T> entries,
      int Function(T entry) score,
      String Function(T entry) label,
    ) {
      final active = entries.where((entry) => score(entry) > 0).toList();
      if (active.isEmpty) return '—';
      active.sort((a, b) => score(b).compareTo(score(a)));
      return active.take(2).map(label).join(' · ');
    }

    List<int> tail(List<int> values, int count) {
      if (values.length <= count) return values;
      return values.sublist(values.length - count);
    }

    final topSignals = summarizeTop(
      signals,
      (entry) => entry.writes ?? 0,
      (entry) => '${entry.label} (${entry.writes ?? 0})',
    );
    final topComputed = summarizeTop(
      computed,
      (entry) => entry.runs ?? 0,
      (entry) => '${entry.label} (${entry.runs ?? 0})',
    );
    final hotEffects = summarizeTop(
      effects,
      (entry) => entry.lastDurationUs ?? 0,
      (entry) =>
          '${entry.label} (${formatDurationUs(entry.lastDurationUs ?? 0)})',
    );
    final busyCollections = summarizeTop(
      collections,
      (entry) => entry.mutations ?? 0,
      (entry) => '${entry.label} (${entry.mutations ?? 0})',
    );

    final totalNodes = signals.length + computed.length + effects.length;
    final activeNodes =
        signals.where((entry) => entry.status != 'Disposed').length +
        computed.where((entry) => entry.status != 'Disposed').length +
        effects.where((entry) => entry.status != 'Disposed').length;
    final watchedNodes =
        signals.where((entry) => (entry.listeners ?? 0) > 0).length +
        computed.where((entry) => (entry.listeners ?? 0) > 0).length;

    int activityScore(UiPerformanceSample sample) {
      return sample.signalWrites +
          sample.computedRuns +
          sample.effectRuns +
          sample.collectionMutations;
    }

    final lastSample = performance.isNotEmpty ? performance.first : null;
    final lastActivity = lastSample == null ? 0 : activityScore(lastSample);
    final maxActivity = performance.isEmpty
        ? 0
        : performance
              .map(activityScore)
              .reduce((value, element) => value > element ? value : element);
    final activityProgress = maxActivity == 0
        ? 0.0
        : lastActivity / maxActivity;
    final activityRate = settings.sampleIntervalMs == 0
        ? 0
        : (lastActivity * 60000 / settings.sampleIntervalMs).round();

    final signalPulseValues = tail(
      performance
          .map((sample) => sample.signalWrites)
          .toList()
          .reversed
          .toList(),
      12,
    );
    final batchPulseValues = tail(
      batches.map((batch) => batch.writeCount).toList(),
      12,
    );

    return PanelScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Overview',
            description:
                'Signal diagnostics, activity, and collection health in one place.',
            totalCount: samples.length,
            filteredCount: samples.length,
            countText: '${samples.length} samples',
            showLiveBadge: false,
            onExport: () => exportData(
              context,
              'overview',
              snapshot?.toJson() ?? const <String, Object?>{},
            ),
          ),
          const SizedBox(height: 16),
          AdaptiveWrap(
            children: [
              MetricTile(
                label: 'Signals',
                value: formatCount(signals.length),
                trend: formatDelta(lastSample?.signalWrites, suffix: 'upd'),
                accent: OrefPalette.teal,
                icon: Icons.bubble_chart_rounded,
              ),
              MetricTile(
                label: 'Computed',
                value: formatCount(computed.length),
                trend: formatDelta(lastSample?.computedRuns, suffix: 'runs'),
                accent: OrefPalette.indigo,
                icon: Icons.schema_rounded,
              ),
              MetricTile(
                label: 'Effects',
                value: formatCount(effects.length),
                trend: formatDelta(lastSample?.effectRuns, suffix: 'runs'),
                accent: OrefPalette.pink,
                icon: Icons.auto_awesome_motion_rounded,
              ),
              MetricTile(
                label: 'Batches',
                value: formatCount(batches.length),
                trend: formatDelta(lastSample?.batchWrites, suffix: 'writes'),
                accent: OrefPalette.coral,
                icon: Icons.layers_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 980;
              final insightCard = _InsightCard(
                title: 'Insights',
                subtitle: 'Highlights from the latest signal activity.',
                primary: [
                  _InsightRow('Most updated', topSignals),
                  _InsightRow('Hot effects', hotEffects),
                  _InsightRow('Busy collections', busyCollections),
                ],
                secondary: [
                  _InsightRow('Computed churn', topComputed),
                  _InsightRow(
                    'Active nodes',
                    totalNodes == 0 ? '—' : '$activeNodes / $totalNodes',
                  ),
                  _InsightRow('Last update', formatAge(snapshot?.timestamp)),
                ],
              );
              final healthCard = _HealthCard(
                activeNodes: activeNodes,
                totalNodes: totalNodes,
                watchedNodes: watchedNodes,
                activityRate: activityRate,
                activityProgress: activityProgress,
              );

              return isStacked
                  ? Column(
                      children: [
                        insightCard,
                        const SizedBox(height: 20),
                        healthCard,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: insightCard),
                        const SizedBox(width: 20),
                        Expanded(child: healthCard),
                      ],
                    );
            },
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 860;
                final connectionInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Streaming updates from the active Flutter isolate. '
                      'Refresh to sync the latest snapshot or clear the '
                      'history for a new pass.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        GradientButton(
                          label: 'Refresh data',
                          onTap: canInteract ? controller.refresh : null,
                        ),
                        OutlineButton(
                          label: 'Clear history',
                          onTap: canInteract ? controller.clearHistory : null,
                        ),
                      ],
                    ),
                  ],
                );

                final sessionCard = GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session', style: textTheme.labelLarge),
                      const SizedBox(height: 12),
                      InfoRow(
                        label: 'Status',
                        value: controller.connected ? 'Connected' : 'Offline',
                      ),
                      InfoRow(
                        label: 'Signals',
                        value: formatCount(signals.length),
                      ),
                      InfoRow(
                        label: 'Effects',
                        value: formatCount(effects.length),
                      ),
                      InfoRow(
                        label: 'Last update',
                        value: formatAge(snapshot?.timestamp),
                      ),
                    ],
                  ),
                );

                return isStacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          connectionInfo,
                          const SizedBox(height: 20),
                          sessionCard,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: connectionInfo),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: sessionCard),
                        ],
                      );
              },
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 980;
              final leftColumn = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Signal Pulse', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _MiniChart(
                          values: signalPulseValues,
                          icon: Icons.stacked_line_chart_rounded,
                          caption: signalPulseValues.isEmpty
                              ? 'Awaiting samples'
                              : '${signalPulseValues.last} writes / sample',
                          color: OrefPalette.teal,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Track how signals refresh across the frame '
                          'timeline and spot hot paths early.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch Heatmap', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _MiniChart(
                          values: batchPulseValues,
                          icon: Icons.grid_view_rounded,
                          caption: batchPulseValues.isEmpty
                              ? 'No batches recorded'
                              : '${batchPulseValues.last} writes last batch',
                          color: OrefPalette.indigo,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Spot dense write bursts and their scopes.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final activityCard = GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (timelineEvents.isEmpty)
                      InlineEmptyState(
                        message: controller.isUnavailable
                            ? 'Enable Oref DevTools to capture activity.'
                            : 'No recent activity yet.',
                        padding: EdgeInsets.zero,
                      )
                    else
                      for (final event in timelineEvents.take(6))
                        _TimelineRow(event: event),
                  ],
                ),
              );

              return isStacked
                  ? Column(
                      children: [
                        leftColumn,
                        const SizedBox(height: 20),
                        activityCard,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: leftColumn),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: activityCard),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final String subtitle;
  final List<_InsightRow> primary;
  final List<_InsightRow> secondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: textTheme.bodySmall),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 420;
              final primaryColumn = Column(
                children: [for (final row in primary) row],
              );
              final secondaryColumn = Column(
                children: [for (final row in secondary) row],
              );

              return isStacked
                  ? Column(
                      children: [
                        primaryColumn,
                        const SizedBox(height: 12),
                        secondaryColumn,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: primaryColumn),
                        const SizedBox(width: 16),
                        Expanded(child: secondaryColumn),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DefaultTextStyle.merge(
        style: textTheme.bodySmall,
        child: Row(
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return GlassCard(
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

class _HealthBar extends StatelessWidget {
  const _HealthBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: textTheme.bodySmall)),
            Text(value, style: textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  height: 8,
                  width: constraints.maxWidth * clamped,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({
    required this.values,
    required this.icon,
    required this.caption,
    required this.color,
  });

  final List<int> values;
  final IconData icon;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return _ChartPlaceholder(icon: icon, caption: caption);
    }
    final maxValue = values.fold<int>(1, (max, value) {
      return value > max ? value : max;
    });

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barMaxHeight = constraints.maxHeight;
                  final barCount = values.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < barCount; index++) ...[
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: barMaxHeight * (values[index] / maxValue),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        if (index != barCount - 1) const SizedBox(width: 6),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    caption,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.icon, required this.caption});

  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0x3322E3C4), Color(0x226C5CFF)],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 48),
          Positioned(
            bottom: 12,
            right: 12,
            child: GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(caption),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});

  final devtools.TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: timelineColors[event.type] ?? OrefPalette.teal,
              shape: BoxShape.circle,
            ),
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
                Text(
                  '${event.detail} · ${formatAge(event.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
