import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'widget_scope.dart';

class WidgetEffect {
  const WidgetEffect({required this.stop, required this.node});

  final void Function() stop;
  final ReactiveNode node;

  T scopedUsing<T>(BuildContext context, T Function() run) {
    if (getCurrentScope() != null) {
      return using(run);
    }

    final scope = getWidgetScope(context);
    return scope.using(() => using(run));
  }

  T using<T>(T Function() run) {
    if (getCurrentSub() != null) {
      return run();
    }

    final prevSub = setCurrentSub(node);
    try {
      return run();
    } finally {
      setCurrentSub(prevSub);
    }
  }
}

final _store = Expando<WidgetEffect>("oref:widget effect");

WidgetEffect getWidgetEffect(BuildContext context) {
  final cached = _store[context];
  if (cached != null) return cached;

  assert(context is Element, 'oref: The `context` must be an Element');
  final element = context as Element;
  final scope = getWidgetScope(element);

  return scope.using(() {
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
      setCurrentSub(prevSub);
    }
  });
}
