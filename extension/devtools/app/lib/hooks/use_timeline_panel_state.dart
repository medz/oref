part of '../main.dart';

class _TimelinePanelStateData {
  _TimelinePanelStateData({
    required this.typeFilter,
    required this.severityFilter,
  });

  final oref.WritableSignal<String> typeFilter;
  final oref.WritableSignal<String> severityFilter;
}

_TimelinePanelStateData _useTimelinePanelState(BuildContext context) {
  final typeFilter = oref.signal(
    context,
    'All',
    debugLabel: 'timeline.typeFilter',
  );
  final severityFilter = oref.signal(
    context,
    'All',
    debugLabel: 'timeline.severityFilter',
  );
  return _TimelinePanelStateData(
    typeFilter: typeFilter,
    severityFilter: severityFilter,
  );
}
