import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

class WidgetScope {
  const WidgetScope({required this.stop, required this.node});

  final void Function() stop;
  final EffectScope node;
}

final _store = Expando<WidgetScope>("oref:widget effect scope");

WidgetScope getWidgetScope(BuildContext context) {
  final cached = _store[context];
  if (cached != null) return cached;

  final prevScope = setCurrentScope(null);
  try {
    EffectScope? node;
    final stop = effectScope(() {
      node ??= getCurrentScope();
    });

    assert(node != null, "oref: Widget scope initialization failed");

    final scope = WidgetScope(stop: stop, node: node!);
    _store[context] = scope;

    return scope;
  } finally {
    setCurrentScope(prevScope);
  }
}
