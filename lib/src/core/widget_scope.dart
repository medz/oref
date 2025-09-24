import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

/// Widget effect scope.
///
/// {@template oref.widget-scope}
/// This class provides a way to manage the effect scope of a widget.
///
/// Example:
/// ```dart
/// final scope = useWidgetScope(context);
/// final scope.stop(); // Stop all effects of widget.
/// ```
/// {@endtemplate}
class WidgetScope {
  /// Create a new widget scope.
  ///
  /// {@macro oref.widget-scope}
  const WidgetScope({required void Function() stop, required this.effectScope})
    : _stop = stop;

  final void Function() _stop;
  final EffectScope effectScope;

  T using<T>(T Function() run) {
    final prevScope = setCurrentScope(effectScope);
    try {
      return run();
    } finally {
      setCurrentScope(prevScope);
    }
  }

  void stop() {
    _stop();
    _finalizer.detach(effectScope);
  }
}

final _store = Expando<WidgetScope>("oref:widget effect scope");
final _finalizer = Finalizer<WidgetScope>((scope) => scope.stop());

WidgetScope useWidgetScope(BuildContext context) {
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
    _finalizer.attach(context, e, detach: scope);

    return e;
  } finally {
    setCurrentScope(prevScope);
  }
}
