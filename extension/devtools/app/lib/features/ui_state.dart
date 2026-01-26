import 'package:flutter/material.dart';
import 'package:oref/oref.dart' as oref;

import '../app/constants.dart';

class UiState {
  UiState({required this.themeMode, required this.selectedNavLabel});

  final oref.WritableSignal<ThemeMode> themeMode;
  final oref.WritableSignal<String> selectedNavLabel;
}

UiState useUiState(BuildContext context) {
  final themeMode = oref.signal(
    context,
    ThemeMode.system,
    debugLabel: 'ui.themeMode',
  );
  final selectedNavLabel = oref.signal(
    context,
    navItems.first.label,
    debugLabel: 'ui.nav.selected',
  );
  return UiState(themeMode: themeMode, selectedNavLabel: selectedNavLabel);
}
