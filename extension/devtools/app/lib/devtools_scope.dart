part of 'main.dart';

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
