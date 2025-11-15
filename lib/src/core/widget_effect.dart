import 'package:alien_signals/preset.dart' as alien;
import 'package:alien_signals/system.dart' as alien;
import 'package:flutter/widgets.dart';

import 'effect.dart';
import 'memoized.dart';
import 'widget_scope.dart';

final _store = Expando<Effect>("oref:widget effect");

/// Use a [ReactiveEffect] to create a widget effect for a given [BuildContext].
///
/// {@macro oref.core.widget_effect.using}
///
/// Stop widget reactive effect.
/// ```dart
/// final effect = useWidgetEffect(context);
/// effect.stop();
/// ```
/// > After stopping, the Widget will stop collecting signals and responding.
Effect useWidgetEffect(BuildContext context) {
  final cached = _store[context];
  if (cached != null) return cached;

  assert(context is Element, 'oref: The `context` must be an Element');
  final element = context as Element,
      scope = useWidgetScope(element),
      prevSub = alien.setActiveSub(scope as alien.ReactiveNode);
  try {
    final e = effect(null, () {
      resetMemoizedCursor(element);
      if (!element.mounted) {
        scope();
      } else if (!element.dirty) {
        element.markNeedsBuild();
      }
    }, detach: false);
    _store[element] = e;

    return e;
  } finally {
    alien.setActiveSub(prevSub);
  }
}
