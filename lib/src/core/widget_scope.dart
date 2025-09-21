import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

class WidgetScope {
  const WidgetScope({required this.stop, required this.effectScope});

  final void Function() stop;
  final EffectScope effectScope;

  T using<T>(T Function() run) {
    final prevScope = setCurrentScope(effectScope);
    try {
      return run();
    } finally {
      setCurrentScope(prevScope);
    }
  }
}

final _store = Expando<WidgetScope>("oref:widget effect scope");

WidgetScope getWidgetScope(BuildContext context) {
  final cached = _store[context];
  if (cached != null) return cached;

  final prevScope = setCurrentScope(null);
  try {
    EffectScope? scope;
    final stop = effectScope(() {
      scope ??= getCurrentScope();
    });

    assert(scope != null, "oref: Widget scope initialization failed");

    final e = WidgetScope(stop: stop, effectScope: scope!);
    _store[context] = e;

    return e;
  } finally {
    setCurrentScope(prevScope);
  }
}
