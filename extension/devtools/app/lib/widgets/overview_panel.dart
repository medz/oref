part of '../main.dart';

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = OrefDevToolsScope.of(context);
    final snapshot = controller.snapshot;
    final samples = snapshot?.samples ?? const <Sample>[];
    final signals = _samplesByKind(samples, 'signal');
    final computed = _samplesByKind(samples, 'computed');
    final effects = _samplesByKind(samples, 'effect');
    final collections = _samplesByKind(samples, 'collection');
    final batches = snapshot?.batches.toList() ?? const <BatchSample>[];
    batches.sort((a, b) => a.endedAt.compareTo(b.endedAt));
    final timelineEvents =
        snapshot?.timeline.toList() ?? const <TimelineEvent>[];
    timelineEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final performance = controller.performance;
    final settings = snapshot?.settings ?? const DevToolsSettings();
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
          '${entry.label} (${_formatDurationUs(entry.lastDurationUs ?? 0)})',
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Signal diagnostics, activity, and collection health in one place.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _AdaptiveWrap(
            children: [
              _MetricTile(
                label: 'Signals',
                value: _formatCount(signals.length),
                trend: _formatDelta(lastSample?.signalWrites, suffix: 'upd'),
                accent: OrefPalette.teal,
                icon: Icons.bubble_chart_rounded,
              ),
              _MetricTile(
                label: 'Computed',
                value: _formatCount(computed.length),
                trend: _formatDelta(lastSample?.computedRuns, suffix: 'runs'),
                accent: OrefPalette.indigo,
                icon: Icons.schema_rounded,
              ),
              _MetricTile(
                label: 'Effects',
                value: _formatCount(effects.length),
                trend: _formatDelta(lastSample?.effectRuns, suffix: 'runs'),
                accent: OrefPalette.pink,
                icon: Icons.auto_awesome_motion_rounded,
              ),
              _MetricTile(
                label: 'Batches',
                value: _formatCount(batches.length),
                trend: _formatDelta(lastSample?.batchWrites, suffix: 'writes'),
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
                  _InsightRow('Last update', _formatAge(snapshot?.timestamp)),
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
          _GlassCard(
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
                        _GradientButton(
                          label: 'Refresh data',
                          onTap: canInteract ? controller.refresh : null,
                        ),
                        _OutlineButton(
                          label: 'Clear history',
                          onTap: canInteract ? controller.clearHistory : null,
                        ),
                      ],
                    ),
                  ],
                );

                final sessionCard = _GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session', style: textTheme.labelLarge),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Status',
                        value: controller.connected ? 'Connected' : 'Offline',
                      ),
                      _InfoRow(
                        label: 'Signals',
                        value: _formatCount(signals.length),
                      ),
                      _InfoRow(
                        label: 'Effects',
                        value: _formatCount(effects.length),
                      ),
                      _InfoRow(
                        label: 'Last update',
                        value: _formatAge(snapshot?.timestamp),
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
                  _GlassCard(
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
                  _GlassCard(
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

              final activityCard = _GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (timelineEvents.isEmpty)
                      Text(
                        controller.isUnavailable
                            ? 'Enable Oref DevTools to capture activity.'
                            : 'No recent activity yet.',
                        style: textTheme.bodyMedium,
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
