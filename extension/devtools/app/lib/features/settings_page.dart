import 'package:flutter/material.dart';
import 'package:oref/devtools.dart' as devtools;
import 'package:oref/oref.dart' as oref;

import '../app/scopes.dart';
import '../shared/widgets/actions.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/panel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useSettingsState(context);

    return oref.SignalBuilder(
      builder: (context) {
        final controller = OrefDevToolsScope.of(context);
        final uiState = UiScope.of(context);
        final themeMode = uiState.themeMode();
        final current =
            controller.snapshot?.settings ?? const devtools.DevToolsSettings();
        var draft = state.draft();
        if (!state.isEditing() && draft != current) {
          state.draft.set(current);
          draft = current;
        }

        return ConnectionGuard(
          child: PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Settings',
                  description: 'Tune how diagnostics are collected.',
                  totalCount: 0,
                  filteredCount: 0,
                  countText: controller.connected ? 'Connected' : 'Offline',
                  showLiveBadge: false,
                  exportLabel: 'Refresh',
                  onExport: controller.refresh,
                ),
                const SizedBox(height: 16),
                GlassCard(
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
                GlassCard(
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
                GlassCard(
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
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Clear cached diagnostics and restart sampling.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      ActionPill(
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

class SettingsState {
  SettingsState({required this.isEditing, required this.draft});

  final oref.WritableSignal<bool> isEditing;
  final oref.WritableSignal<devtools.DevToolsSettings> draft;
}

SettingsState useSettingsState(BuildContext context) {
  final isEditing = oref.signal(context, false, debugLabel: 'settings.editing');
  final draft = oref.signal(
    context,
    const devtools.DevToolsSettings(),
    debugLabel: 'settings.draft',
  );
  return SettingsState(isEditing: isEditing, draft: draft);
}
