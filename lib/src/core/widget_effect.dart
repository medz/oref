import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'widget_scope.dart';

class WidgetEffect {
  const WidgetEffect({required this.stop, required this.node});

  final void Function() stop;
  final ReactiveNode node;
}

final _store = Expando<WidgetEffect>("oref:widget effect");

WidgetEffect getWidgetEffect(BuildContext context) {
  final cached = _store[context];
  if (cached != null) return cached;

  assert(context is Element, 'oref: The `context` must be an Element');
  final element = context as Element;
  final prevScope = setCurrentScope(getWidgetScope(element).node);
  final prevSub = setCurrentScope(null);

  try {
    ReactiveNode? node;
    final stop = effect(() {
      node ??= getCurrentSub();

      if (element.dirty) {
        element.markNeedsBuild();
      }
    });

    assert(node != null, 'oref: Widget effect initialization failed');
    final e = WidgetEffect(stop: stop, node: node!);
    _store[element] = e;

    return e;
  } finally {
    setCurrentScope(prevScope);
    setCurrentSub(prevSub);
  }
}
