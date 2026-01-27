import 'package:flutter/material.dart';

import '../features/ui_state.dart';
import '../services/oref_service.dart';

class UiScope extends InheritedWidget {
  const UiScope({required this.state, required super.child, super.key});

  final UiState state;

  static UiState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UiScope>();
    assert(scope != null, 'UiScope not found in widget tree.');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(UiScope oldWidget) => state != oldWidget.state;
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
