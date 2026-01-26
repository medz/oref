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
part 'widgets/ui_scope.dart';
part 'nav_items.dart';
part 'panel_info.dart';
part 'sorting.dart';
part 'filters.dart';
part 'status_styles.dart';
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
part 'widgets/performance_list.dart';
part 'widgets/performance_row.dart';
part 'widgets/settings_panel.dart';
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

const double _effectsTimelineDotSize = 14;
const double _effectsTimelineLineWidth = 2;
const double _effectsTimelineHorizontalPadding = 16;
const double _effectsTimelineLineLeft =
    _effectsTimelineHorizontalPadding +
    _effectsTimelineDotSize / 2 -
    _effectsTimelineLineWidth / 2;

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
