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
part 'color_maps.dart';
part 'effects_timeline_constants.dart';
part 'palette.dart';
part 'theme.dart';
part 'devtools_scope.dart';
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
