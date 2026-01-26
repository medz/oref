part of '../main.dart';

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
