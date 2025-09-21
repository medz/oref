import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

class WidgetScope {
  const WidgetScope({required this.stop, required this.node});

  final void Function() stop;
  final ReactiveNode node;
}

final _store = Expando<WidgetScope>("oref:widget scope");

WidgetScope getWidgetScope(BuildContext context) {
  final cached = _store[context];
  if (cached != null) return cached;

  late final ReactiveNode node;
  final stop = effectScope(() {
    final scope = getCurrentScope();
    assert(scope != null, "WidgetScope must be created within a scope");

    node = scope!;
  });

  final scope = WidgetScope(stop: stop, node: node);
  _store[context] = scope;

  return scope;
}
