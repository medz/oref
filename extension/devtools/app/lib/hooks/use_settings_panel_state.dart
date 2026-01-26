part of '../main.dart';

class _SettingsPanelStateData {
  _SettingsPanelStateData({required this.isEditing, required this.draft});

  final oref.WritableSignal<bool> isEditing;
  final oref.WritableSignal<DevToolsSettings> draft;
}

_SettingsPanelStateData _useSettingsPanelState(BuildContext context) {
  final isEditing = oref.signal(context, false, debugLabel: 'settings.editing');
  final draft = oref.signal(
    context,
    const DevToolsSettings(),
    debugLabel: 'settings.draft',
  );
  return _SettingsPanelStateData(isEditing: isEditing, draft: draft);
}
