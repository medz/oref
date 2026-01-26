import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

abstract class OrefRuleHarness extends AnalysisRuleTest {
  @override
  void setUp() {
    final flutterPackage = newPackage('flutter');
    flutterPackage.addFile('lib/widgets.dart', r'''
class BuildContext {}

class Widget {}

class StatelessWidget extends Widget {
  Widget build(BuildContext context) => throw UnimplementedError();
}

class StatefulWidget extends Widget {}

class State<T extends StatefulWidget> {
  Widget build(BuildContext context) => throw UnimplementedError();
}
''');

    final orefPackage = newPackage('oref');
    orefPackage.addFile('lib/oref.dart', r'''
import 'package:flutter/widgets.dart';

class Signal<T> {
  T get value => throw UnimplementedError();
  set value(T v) {}
}

class WritableSignal<T> extends Signal<T> {}

class WritableComputed<T> extends Signal<T> {}

Signal<T> signal<T>(BuildContext? context, T value) => Signal<T>();

T computed<T>(BuildContext? context, T Function() compute) => compute();

T writableComputed<T>(BuildContext? context, T Function() compute) => compute();

void effect(BuildContext? context, void Function() fn) {}

void effectScope(BuildContext? context, void Function() fn) {}

T useAsyncData<T>(BuildContext? context, Future<T> Function() fn) =>
    throw UnimplementedError();

T watch<T>(BuildContext context, T Function() fn) => fn();

T useMemoized<T>(BuildContext context, T Function() fn) => fn();

void useWidgetEffect(BuildContext context, void Function() fn) {}

void useWidgetScope(BuildContext context, void Function() fn) {}

void onMounted(BuildContext context, void Function() fn) {}

void onUnmounted(BuildContext context, void Function() fn) {}

class ReactiveList<T> {
  ReactiveList.scoped(BuildContext context);
}

class ReactiveMap<K, V> {
  ReactiveMap.scoped(BuildContext context);
}

class ReactiveSet<T> {
  ReactiveSet.scoped(BuildContext context);
}
''');

    super.setUp();
  }
}
