part of '../main.dart';

class _UiState {
  _UiState({required this.themeMode, required this.selectedNavLabel});

  final oref.WritableSignal<ThemeMode> themeMode;
  final oref.WritableSignal<String> selectedNavLabel;
}

_UiState _useUiState(BuildContext context) {
  final themeMode = oref.signal(
    context,
    ThemeMode.system,
    debugLabel: 'ui.themeMode',
  );
  final selectedNavLabel = oref.signal(
    context,
    _navItems.first.label,
    debugLabel: 'ui.nav.selected',
  );
  return _UiState(themeMode: themeMode, selectedNavLabel: selectedNavLabel);
}
