part of '../main.dart';

class _EffectsPanelStateData {
  _EffectsPanelStateData({required this.typeFilter, required this.scopeFilter});

  final oref.WritableSignal<String> typeFilter;
  final oref.WritableSignal<String> scopeFilter;
}

_EffectsPanelStateData _useEffectsPanelState(BuildContext context) {
  final typeFilter = oref.signal(
    context,
    'All',
    debugLabel: 'effects.typeFilter',
  );
  final scopeFilter = oref.signal(
    context,
    'All',
    debugLabel: 'effects.scopeFilter',
  );
  return _EffectsPanelStateData(
    typeFilter: typeFilter,
    scopeFilter: scopeFilter,
  );
}
