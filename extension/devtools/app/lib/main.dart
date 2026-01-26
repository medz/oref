import 'dart:convert';
import 'dart:ui';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oref/devtools.dart';
import 'package:oref/oref.dart' as oref;

import 'oref_service.dart';

part 'shell.dart';
part 'hooks/use_collections_panel_state.dart';
part 'hooks/use_computed_panel_state.dart';
part 'hooks/use_effects_panel_state.dart';
part 'hooks/use_settings_panel_state.dart';
part 'hooks/use_signals_panel_state.dart';
part 'hooks/use_timeline_panel_state.dart';
part 'hooks/use_ui_state.dart';
part 'utils/helpers.dart';
part 'widgets/adaptive_wrap.dart';
part 'widgets/action_buttons.dart';
part 'widgets/action_pill.dart';
part 'widgets/filter_chip.dart';
part 'widgets/glass_card.dart';
part 'widgets/glass_input.dart';
part 'widgets/glass_pill.dart';
part 'widgets/insight_card.dart';
part 'widgets/insight_row.dart';
part 'widgets/health_card.dart';
part 'widgets/health_bar.dart';
part 'widgets/chart_placeholder.dart';
part 'widgets/mini_chart.dart';
part 'widgets/sparkline.dart';
part 'widgets/timeline_row.dart';
part 'widgets/info_row.dart';
part 'widgets/hot_badge.dart';
part 'widgets/diff_token.dart';
part 'widgets/metric_tile.dart';
part 'widgets/signals_header.dart';
part 'widgets/signal_list.dart';
part 'widgets/signal_table_header.dart';
part 'widgets/signal_row.dart';
part 'widgets/signal_detail.dart';
part 'widgets/collections_header.dart';
part 'widgets/collections_list.dart';
part 'widgets/collections_header_row.dart';
part 'widgets/collection_row.dart';
part 'widgets/effects_header.dart';
part 'widgets/panel_placeholder.dart';
part 'widgets/panel_scroll_view.dart';
part 'widgets/panel_state_cards.dart';
part 'widgets/sort_header_cell.dart';
part 'widgets/status_badge.dart';

void main() {
  runApp(const DevToolsExtension(child: OrefDevToolsApp()));
}

class OrefDevToolsApp extends StatelessWidget {
  const OrefDevToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final uiState = _useUiState(context);
    return _UiScope(
      state: uiState,
      child: oref.SignalBuilder(
        builder: (context) {
          final mode = uiState.themeMode();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Oref DevTools',
            theme: OrefTheme.light(),
            darkTheme: OrefTheme.dark(),
            themeMode: mode,
            home: const _DevToolsShell(),
          );
        },
      ),
    );
  }
}

class OrefDevToolsScope extends InheritedNotifier<OrefDevToolsController> {
  const OrefDevToolsScope({
    super.key,
    required OrefDevToolsController controller,
    required super.child,
  }) : super(notifier: controller);

  static OrefDevToolsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OrefDevToolsScope>();
    assert(scope != null, 'OrefDevToolsScope not found in widget tree.');
    return scope!.notifier!;
  }
}

class _UiScope extends InheritedWidget {
  const _UiScope({required this.state, required super.child});

  final _UiState state;

  static _UiState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_UiScope>();
    assert(scope != null, '_UiScope not found in widget tree.');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(_UiScope oldWidget) => state != oldWidget.state;
}

class OrefTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: OrefPalette.teal,
      brightness: brightness,
    );
    final scheme = baseScheme.copyWith(
      primary: OrefPalette.teal,
      onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
      secondary: OrefPalette.indigo,
      onSecondary: Colors.white,
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: brightness == Brightness.dark
          ? const Color(0xFF141B22)
          : const Color(0xFFFFFFFF),
      onSurface: brightness == Brightness.dark
          ? const Color(0xFFEAF2F8)
          : const Color(0xFF11161D),
    );

    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.spaceGroteskTextTheme(baseTextTheme).copyWith(
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.4),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.4),
      bodySmall: baseTextTheme.bodySmall?.copyWith(height: 1.3),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      useMaterial3: true,
      dividerColor: brightness == Brightness.dark
          ? const Color(0xFF24313B)
          : const Color(0xFFE1E6EC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(color: Colors.transparent, elevation: 0),
    );
  }
}

class OrefPalette {
  static const Color teal = Color(0xFF22E3C4);
  static const Color tealDark = Color(0xFF14B6A1);
  static const Color indigo = Color(0xFF6C5CFF);
  static const Color coral = Color(0xFFFF8C6B);
  static const Color lime = Color(0xFFB5FF6D);
  static const Color pink = Color(0xFFFF71C6);
  static const Color deepBlue = Color(0xFF0C141C);
  static const Color lightBlue = Color(0xFFE7F3FF);
}

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

class _SignalsPanel extends StatelessWidget {
  const _SignalsPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useSignalsPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        return _ConnectionGuard(
          child: _PanelScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controller = OrefDevToolsScope.of(context);
                final entries = _samplesByKind(
                  controller.snapshot?.samples ?? const <Sample>[],
                  'signal',
                );
                final isSplit = constraints.maxWidth >= 980;
                final filtered = state.filter(entries);
                final selected = entries.firstWhereOrNull(
                  (entry) => entry.id == state.selectedId(),
                );
                final list = _SignalList(
                  entries: filtered,
                  selectedId: selected?.id,
                  isCompact: !isSplit,
                  sortKey: state.sortKey(),
                  sortAscending: state.sortAscending(),
                  onSortName: () => state.toggleSort(_SortKey.name),
                  onSortUpdated: () => state.toggleSort(_SortKey.updated),
                  onSelect: (entry) => state.toggleSelection(entry.id),
                );
                final detail = _SignalDetail(entry: selected);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SignalsHeader(
                      controller: state.searchController,
                      selectedFilter: state.statusFilter(),
                      onFilterChange: (value) => state.statusFilter.set(value),
                      totalCount: entries.length,
                      filteredCount: filtered.length,
                      onExport: () => _exportData(
                        context,
                        'signals',
                        filtered.map((entry) => entry.toJson()).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isSplit)
                      selected == null
                          ? list
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: list),
                                const SizedBox(width: 20),
                                SizedBox(width: 320, child: detail),
                              ],
                            )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          list,
                          if (selected != null) ...[
                            const SizedBox(height: 16),
                            detail,
                          ],
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ComputedPanel extends StatelessWidget {
  const _ComputedPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useComputedPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        return _ConnectionGuard(
          child: _PanelScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controller = OrefDevToolsScope.of(context);
                final entries = _samplesByKind(
                  controller.snapshot?.samples ?? const <Sample>[],
                  'computed',
                );
                final isSplit = constraints.maxWidth >= 980;
                final filtered = state.filter(entries);
                final selected = entries.firstWhereOrNull(
                  (entry) => entry.id == state.selectedId(),
                );
                final list = _ComputedList(
                  entries: filtered,
                  selectedId: selected?.id,
                  isCompact: !isSplit,
                  sortKey: state.sortKey(),
                  sortAscending: state.sortAscending(),
                  onSortName: () => state.toggleSort(_SortKey.name),
                  onSortUpdated: () => state.toggleSort(_SortKey.updated),
                  onSelect: (entry) => state.toggleSelection(entry.id),
                );
                final detail = _ComputedDetail(entry: selected);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ComputedHeader(
                      controller: state.searchController,
                      selectedFilter: state.statusFilter(),
                      onFilterChange: (value) => state.statusFilter.set(value),
                      totalCount: entries.length,
                      filteredCount: filtered.length,
                      onExport: () => _exportData(
                        context,
                        'computed',
                        filtered.map((entry) => entry.toJson()).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isSplit)
                      selected == null
                          ? list
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: list),
                                const SizedBox(width: 20),
                                SizedBox(width: 320, child: detail),
                              ],
                            )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          list,
                          if (selected != null) ...[
                            const SizedBox(height: 16),
                            detail,
                          ],
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ComputedHeader extends StatelessWidget {
  const _ComputedHeader({
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChange,
    required this.totalCount,
    required this.filteredCount,
    required this.onExport,
  });

  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onFilterChange;
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
            Text('Computed', style: textTheme.headlineSmall),
            const SizedBox(width: 12),
            const _GlassPill(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('Live'),
            ),
            const Spacer(),
            _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('$filteredCount / $totalCount'),
            ),
            const SizedBox(width: 12),
            _ActionPill(
              label: 'Export',
              icon: Icons.download_rounded,
              onTap: onExport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Inspect derived state, cache hits, and dependency churn.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _GlassInput(
          controller: controller,
          hintText: 'Search computed values...',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in _signalFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == selectedFilter,
                onTap: () => onFilterChange(filter),
              ),
          ],
        ),
      ],
    );
  }
}

class _ComputedList extends StatelessWidget {
  const _ComputedList({
    required this.entries,
    required this.selectedId,
    required this.isCompact,
    required this.sortKey,
    required this.sortAscending,
    required this.onSortName,
    required this.onSortUpdated,
    required this.onSelect,
  });

  final List<Sample> entries;
  final int? selectedId;
  final bool isCompact;
  final _SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;
  final ValueChanged<Sample> onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact)
            _ComputedTableHeader(
              sortKey: sortKey,
              sortAscending: sortAscending,
              onSortName: onSortName,
              onSortUpdated: onSortUpdated,
            ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No computed values match the current filter.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _ComputedRow(
                      entry: entries[index],
                      isSelected: selectedId == entries[index].id,
                      isCompact: isCompact,
                      onTap: () => onSelect(entries[index]),
                    ),
                    if (index != entries.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComputedTableHeader extends StatelessWidget {
  const _ComputedTableHeader({
    required this.sortKey,
    required this.sortAscending,
    required this.onSortName,
    required this.onSortUpdated,
  });

  final _SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;

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
            flex: 3,
            child: _SortHeaderCell(
              label: 'Name',
              isActive: sortKey == _SortKey.name,
              ascending: sortAscending,
              onTap: onSortName,
              style: labelStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Value', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Status', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Runs', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: _SortHeaderCell(
              label: 'Updated',
              isActive: sortKey == _SortKey.updated,
              ascending: sortAscending,
              onTap: onSortUpdated,
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComputedRow extends StatelessWidget {
  const _ComputedRow({
    required this.entry,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final Sample entry;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlight = isSelected
        ? OrefPalette.indigo.withValues(alpha: 0.2)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: highlight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? OrefPalette.indigo.withValues(alpha: 0.4)
                  : colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.label),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatusBadge(status: entry.status ?? 'Active'),
                        _GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text('${entry.runs ?? 0} runs'),
                        ),
                        _GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(_formatAge(entry.updatedAt)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.value ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(entry.label, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            entry.owner,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.center,
                        child: _StatusBadge(status: entry.status ?? 'Active'),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${entry.runs ?? 0}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatAge(entry.updatedAt),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ComputedDetail extends StatelessWidget {
  const _ComputedDetail({required this.entry});

  final Sample? entry;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Select a computed value to view details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry!.label, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _StatusBadge(status: entry!.status ?? 'Active'),
          const SizedBox(height: 16),
          _InfoRow(label: 'Owner', value: entry!.owner),
          _InfoRow(label: 'Scope', value: entry!.scope),
          _InfoRow(label: 'Type', value: entry!.type),
          _InfoRow(label: 'Value', value: entry!.value ?? ''),
          _InfoRow(label: 'Updated', value: _formatAge(entry!.updatedAt)),
          _InfoRow(label: 'Runs', value: '${entry!.runs ?? 0}'),
          _InfoRow(
            label: 'Last run',
            value: _formatDurationUs(entry!.lastDurationUs ?? 0),
          ),
          _InfoRow(label: 'Listeners', value: '${entry!.listeners ?? 0}'),
          _InfoRow(label: 'Deps', value: '${entry!.dependencies ?? 0}'),
          if (entry!.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(entry!.note, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _EffectsPanel extends StatelessWidget {
  const _EffectsPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useEffectsPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final entries = _samplesByKind(
          controller.snapshot?.samples ?? const <Sample>[],
          'effect',
        );
        final typeFilters = _buildFilterOptions(
          entries.map((entry) => entry.type),
        );
        final scopeFilters = _buildFilterOptions(
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

        return _ConnectionGuard(
          child: _PanelScrollView(
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
                  onExport: () => _exportData(
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

class _CollectionsPanel extends StatelessWidget {
  const _CollectionsPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useCollectionsPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final entries = _samplesByKind(
          controller.snapshot?.samples ?? const <Sample>[],
          'collection',
        );
        final typeFilters = _buildFilterOptions(
          entries.map((entry) => entry.type),
        );
        final opFilters = _buildFilterOptions(
          entries.map((entry) => entry.operation ?? 'Idle'),
        );
        final filtered = state.filter(entries);

        return _ConnectionGuard(
          child: _PanelScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 860;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CollectionsHeader(
                      controller: state.searchController,
                      typeFilter: state.typeFilter(),
                      opFilter: state.opFilter(),
                      typeFilters: typeFilters,
                      opFilters: opFilters,
                      onTypeChange: (value) => state.typeFilter.set(value),
                      onOpChange: (value) => state.opFilter.set(value),
                      totalCount: entries.length,
                      filteredCount: filtered.length,
                      onExport: () => _exportData(
                        context,
                        'collections',
                        filtered.map((entry) => entry.toJson()).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CollectionsList(
                      entries: filtered,
                      isCompact: isCompact,
                      sortKey: state.sortKey(),
                      sortAscending: state.sortAscending(),
                      onSortName: () => state.toggleSort(_SortKey.name),
                      onSortUpdated: () => state.toggleSort(_SortKey.updated),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

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

class _BatchList extends StatelessWidget {
  const _BatchList({required this.batches, required this.isCompact});

  final List<BatchSample> batches;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
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

  final BatchSample batch;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _GlassCard(
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
                      _GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text('Depth ${batch.depth}'),
                      ),
                      _GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text('${batch.writeCount} writes'),
                      ),
                      _GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text('${batch.durationMs}ms'),
                      ),
                      _GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(_formatAge(batch.endedAt)),
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
                      _formatAge(batch.endedAt),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel();

  @override
  Widget build(BuildContext context) {
    final state = _useTimelinePanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final events =
            controller.snapshot?.timeline.toList() ?? const <TimelineEvent>[];
        events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final typeFilters = _buildFilterOptions(
          events.map((event) => event.type),
        );
        final severityFilters = _buildFilterOptions(
          events.map((event) => event.severity),
        );
        final filtered = events.where((event) {
          final matchesType =
              state.typeFilter() == 'All' || event.type == state.typeFilter();
          final matchesSeverity =
              state.severityFilter() == 'All' ||
              event.severity == state.severityFilter();
          return matchesType && matchesSeverity;
        }).toList();

        return _ConnectionGuard(
          child: _PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Timeline',
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
                      child: Text('${filtered.length} events'),
                    ),
                    const SizedBox(width: 12),
                    _ActionPill(
                      label: 'Export',
                      icon: Icons.download_rounded,
                      onTap: () => _exportData(
                        context,
                        'timeline',
                        filtered.map((event) => event.toJson()).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Correlate signal updates with effects, batches, and collections.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Type',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    for (final filter in typeFilters)
                      _FilterChip(
                        label: filter,
                        isSelected: filter == state.typeFilter(),
                        onTap: () => state.typeFilter.set(filter),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Severity',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    for (final filter in severityFilters)
                      _FilterChip(
                        label: filter,
                        isSelected: filter == state.severityFilter(),
                        onTap: () => state.severityFilter.set(filter),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _TimelineList(events: filtered),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: events.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No timeline events yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var index = 0; index < events.length; index++) ...[
                    _TimelineEventRow(event: events[index]),
                    if (index != events.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final tone = _timelineColors[event.type] ?? OrefPalette.teal;
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
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
                const SizedBox(height: 4),
                Text(
                  _formatTimelineDetail(event),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatAge(event.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

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

class _PerformanceList extends StatelessWidget {
  const _PerformanceList({required this.samples});

  final List<UiPerformanceSample> samples;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: samples.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No performance samples yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle.merge(
        style: textTheme.bodyMedium,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                _formatAge(sample.timestamp),
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
                _formatDurationUs(sample.avgEffectDurationUs.round()),
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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    final state = _useSettingsPanelState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final uiState = _UiScope.of(context);
        final themeMode = uiState.themeMode();
        final current =
            controller.snapshot?.settings ?? const DevToolsSettings();
        var draft = state.draft();
        if (!state.isEditing() && draft != current) {
          state.draft.set(current);
          draft = current;
        }

        return _ConnectionGuard(
          child: _PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    _ActionPill(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      onTap: controller.refresh,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tune how diagnostics are collected.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto_rounded),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_rounded),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) {
                          uiState.themeMode.set(selection.first);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sampling',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: draft.enabled,
                        onChanged: (value) {
                          state.isEditing.set(true);
                          state.draft.set(draft.copyWith(enabled: value));
                          controller.updateSettings(state.draft());
                          state.isEditing.set(false);
                        },
                        title: const Text('Enable sampling'),
                        subtitle: Text(
                          'Collect timeline and performance samples.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sample interval (${draft.sampleIntervalMs}ms)',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Slider(
                        value: draft.sampleIntervalMs.toDouble(),
                        min: 250,
                        max: 5000,
                        divisions: 19,
                        label: '${draft.sampleIntervalMs}ms',
                        onChanged: (value) {
                          state.isEditing.set(true);
                          state.draft.set(
                            draft.copyWith(sampleIntervalMs: value.round()),
                          );
                        },
                        onChangeEnd: (_) async {
                          await controller.updateSettings(state.draft());
                          if (!context.mounted) return;
                          state.isEditing.set(false);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Retention',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Timeline limit (${draft.timelineLimit})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Slider(
                        value: draft.timelineLimit.toDouble(),
                        min: 50,
                        max: 500,
                        divisions: 9,
                        label: draft.timelineLimit.toString(),
                        onChanged: (value) {
                          state.isEditing.set(true);
                          state.draft.set(
                            draft.copyWith(timelineLimit: value.round()),
                          );
                        },
                        onChangeEnd: (_) async {
                          await controller.updateSettings(state.draft());
                          if (!context.mounted) return;
                          state.isEditing.set(false);
                        },
                      ),
                      Text(
                        'Batch limit (${draft.batchLimit})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Slider(
                        value: draft.batchLimit.toDouble(),
                        min: 20,
                        max: 300,
                        divisions: 14,
                        label: draft.batchLimit.toString(),
                        onChanged: (value) {
                          state.isEditing.set(true);
                          state.draft.set(
                            draft.copyWith(batchLimit: value.round()),
                          );
                        },
                        onChangeEnd: (_) async {
                          await controller.updateSettings(state.draft());
                          if (!context.mounted) return;
                          state.isEditing.set(false);
                        },
                      ),
                      Text(
                        'Performance samples (${draft.performanceLimit})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Slider(
                        value: draft.performanceLimit.toDouble(),
                        min: 30,
                        max: 300,
                        divisions: 9,
                        label: draft.performanceLimit.toString(),
                        onChanged: (value) {
                          state.isEditing.set(true);
                          state.draft.set(
                            draft.copyWith(performanceLimit: value.round()),
                          );
                        },
                        onChangeEnd: (_) async {
                          await controller.updateSettings(state.draft());
                          if (!context.mounted) return;
                          state.isEditing.set(false);
                        },
                      ),
                      Text(
                        'Value preview (${draft.valuePreviewLength} chars)',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Slider(
                        value: draft.valuePreviewLength.toDouble(),
                        min: 40,
                        max: 240,
                        divisions: 10,
                        label: draft.valuePreviewLength.toString(),
                        onChanged: (value) {
                          state.isEditing.set(true);
                          state.draft.set(
                            draft.copyWith(valuePreviewLength: value.round()),
                          );
                        },
                        onChangeEnd: (_) async {
                          await controller.updateSettings(state.draft());
                          if (!context.mounted) return;
                          state.isEditing.set(false);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Clear cached diagnostics and restart sampling.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      _ActionPill(
                        label: 'Clear history',
                        icon: Icons.delete_sweep_rounded,
                        onTap: controller.clearHistory,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const double _effectsTimelineDotSize = 14;
const double _effectsTimelineLineWidth = 2;
const double _effectsTimelineHorizontalPadding = 16;
const double _effectsTimelineLineLeft =
    _effectsTimelineHorizontalPadding +
    _effectsTimelineDotSize / 2 -
    _effectsTimelineLineWidth / 2;

class _EffectsTimeline extends StatelessWidget {
  const _EffectsTimeline({required this.entries});

  final List<Sample> entries;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Positioned(
            left: _effectsTimelineLineLeft,
            top: 0,
            bottom: 0,
            child: Container(
              width: _effectsTimelineLineWidth,
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
                horizontal: _effectsTimelineHorizontalPadding,
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
    final tone = _effectColors[entry.type] ?? OrefPalette.teal;
    final runs = entry.runs ?? 0;
    final durationUs = entry.lastDurationUs ?? 0;
    final isHot = durationUs > 16000 || runs >= 8;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _effectsTimelineDotSize,
          height: _effectsTimelineDotSize,
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
          child: _GlassCard(
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
                      ? 'Last run ${_formatAge(entry.updatedAt)}'
                      : entry.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: tone.withValues(alpha: 0.2),
                      child: Text(entry.type),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(entry.scope),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text('Runs $runs'),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: durationUs > 16000
                          ? OrefPalette.coral.withValues(alpha: 0.2)
                          : OrefPalette.lime.withValues(alpha: 0.2),
                      child: Text(_formatDurationUs(durationUs)),
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

class _NavItemData {
  const _NavItemData(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _navItems = [
  _NavItemData('Overview', Icons.dashboard_rounded),
  _NavItemData('Signals', Icons.bubble_chart_rounded),
  _NavItemData('Computed', Icons.schema_rounded),
  _NavItemData('Effects', Icons.auto_awesome_motion_rounded),
  _NavItemData('Collections', Icons.grid_view_rounded),
  _NavItemData('Batching', Icons.layers_rounded),
  _NavItemData('Timeline', Icons.timeline_rounded),
];

const _utilityItems = [_NavItemData('Performance', Icons.speed_rounded)];

const _settingsItem = _NavItemData('Settings', Icons.tune_rounded);

const _navDisplayItems = [..._navItems, ..._utilityItems];

const _allNavItems = [..._navDisplayItems, _settingsItem];

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

enum _SortKey { name, updated }

class _StatusStyle {
  const _StatusStyle(this.color);

  final Color color;
}

const _signalFilters = ['All', 'Active', 'Dirty', 'Disposed'];

const _statusStyles = {
  'Active': _StatusStyle(OrefPalette.lime),
  'Dirty': _StatusStyle(OrefPalette.coral),
  'Disposed': _StatusStyle(Color(0xFF8B97A8)),
};

const _effectColors = {
  'UI': OrefPalette.teal,
  'Network': OrefPalette.indigo,
  'Persist': OrefPalette.coral,
  'Analytics': OrefPalette.pink,
  'Effect': OrefPalette.teal,
};

const _collectionOpColors = {
  'Add': OrefPalette.lime,
  'Remove': OrefPalette.coral,
  'Replace': OrefPalette.indigo,
  'Clear': OrefPalette.pink,
  'Resize': OrefPalette.indigo,
};

const _deltaStyles = {
  'add': OrefPalette.lime,
  'remove': OrefPalette.coral,
  'update': OrefPalette.indigo,
};

const _timelineColors = {
  'signal': OrefPalette.teal,
  'computed': OrefPalette.indigo,
  'effect': OrefPalette.pink,
  'collection': OrefPalette.coral,
  'batch': OrefPalette.lime,
};
