import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

import 'context.dart';
import 'effect_scope.dart';

final _store = Expando<alien.EffectScope>("oref:widget effect scope");

alien.EffectScope useWidgetScope(BuildContext context) {
  setActiveContext(context);
  final cached = _store[context];
  if (cached != null) return cached;

  final scope = effectScope(null, _noop, detach: true);
  _store[context] = scope;

  return scope;
}

void _noop() {}
