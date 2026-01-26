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
part 'widgets/effects_timeline.dart';
part 'widgets/effect_row.dart';
part 'widgets/effects_panel.dart';
part 'widgets/collections_panel.dart';
part 'widgets/batching_panel.dart';
part 'widgets/timeline_panel.dart';
part 'widgets/performance_panel.dart';
part 'widgets/computed_header.dart';
part 'widgets/computed_list.dart';
part 'widgets/computed_table_header.dart';
part 'widgets/computed_row.dart';
part 'widgets/computed_detail.dart';
part 'widgets/batch_list.dart';
part 'widgets/batch_header_row.dart';
part 'widgets/batch_row.dart';
part 'widgets/timeline_list.dart';
part 'widgets/timeline_event_row.dart';
part 'widgets/overview_panel.dart';
part 'widgets/signals_panel.dart';
part 'widgets/computed_panel.dart';
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
