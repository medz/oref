import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'memoized.dart';
import 'widget_scope.dart';

/// {@template oref.widget-effect}
/// Widget effect is a reactive effect that runs in the context of a widget.
///
/// Each Widget has a unique WidgetEffect, which will automatically signal and computed.
/// {@endtemplate}
class WidgetEffect {
  /// {@macro oref.widget-effect}
  const WidgetEffect({required this.stop, required this.node});

  /// The stop function that will be called when the widget is disposed.
  final void Function() stop;

  /// The reactive node that the effect is associated with.
  final ReactiveNode node;

  /// Using a function to run within the context of the widget effect.
  ///
  /// Example:
  /// {@template oref.widget-effect.using}
  /// ```dart
  /// final effect = useWidgetEffect(context);
  /// effect.using(() {
  ///   count(); // Track the count of the widget effect.
  /// });
  /// ```
  /// {@endtemplate}
  T using<T>(T Function() run) {
    final prevSub = setCurrentSub(node);
    try {
      return run();
    } finally {
      setCurrentSub(prevSub);
    }
  }
}

final _store = Expando<WidgetEffect>("oref:widget effect");

/// Use a [ReactiveEffect] to create a widget effect for a given [BuildContext].
///
/// {@macro oref.widget-effect.using}
///
/// Stop widget reactive effect.
/// ```dart
/// final effect = useWidgetEffect(context);
/// effect.stop();
/// ```
/// > After stopping, the Widget will stop collecting signals and responding.
WidgetEffect useWidgetEffect(BuildContext context) {
  final cached = _store[context];
  if (cached != null) return cached;

  assert(context is Element, 'oref: The `context` must be an Element');
  final element = context as Element;
  final scope = useWidgetScope(element);

  return scope.using(() {
    final prevSub = setCurrentSub(null);

    try {
      ReactiveNode? node;
      final stop = effect(() {
        if (!context.mounted) {
          return scope.stop();
        }

        node ??= getCurrentSub();
        resetMemoizedFor(element);

        if (!element.dirty) {
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
