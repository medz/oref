import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/system.dart' as alien;
import 'package:alien_signals/preset_developer.dart' as alien;
import 'package:flutter/widgets.dart';

import '_disposable.dart';
import '_warn.dart';
import 'memoized.dart';
import 'widget_scope.dart';

typedef Effect = alien.Effect;

/// Creates a reactive effect that automatically tracks its dependencies and re-runs when they change.
///
/// An effect is a reactive computation that automatically tracks any reactive values (signals or computed values)
/// accessed during its execution. The effect will re-run whenever any of its tracked dependencies change.
///
/// The [run] function will be executed:
/// 1. Immediately when the effect is created
/// 2. Whenever any of its tracked dependencies change
///
/// Returns a cleanup function that can be called to dispose of the effect and stop tracking.
///
/// Example:
/// ```dart
/// final count = signal(context, 0);
/// final stop = effect(context, () {
///   print(count());
/// }); // Print 0
///
/// count(1); // Print 1
///
/// stop();
/// count(2); // No output
/// ```
alien.Effect effect(
  BuildContext? context,
  void Function() callback, {
  bool detach = false,
}) {
  if (context == null) {
    return _createEffect(callback: callback, detach: detach);
  }

  final e = useMemoized(context, () {
    if (detach || alien.getActiveSub() != null) {
      return _createEffect(callback: callback, detach: detach);
    }

    final scope = useWidgetScope(context);
    final prevSub = alien.setActiveSub(scope as alien.ReactiveNode);
    try {
      return _createEffect(callback: callback, detach: false);
    } finally {
      alien.setActiveSub(prevSub);
    }
  });

  assert(() {
    e.fn = () {
      e.cleanup?.call();
      e.cleanup = null;
      callback();
    };
    return true;
  }());

  return e;
}

void onEffectDispose(void Function() callback, {bool failSilently = false}) {
  final sub = alien.getActiveSub();
  if (sub is _OrefEffect) {
    sub.onDispose = callback;
  } else if (!failSilently) {
    warn(
      '`onEffectDispose()` was called when there was no active effect to assign the callback to.',
    );
  }
}

void onEffectCleanup(void Function() callback, {bool failSilently = false}) {
  final sub = alien.getActiveSub();
  if (sub is _OrefEffect) {
    sub.cleanup = callback;
  } else if (!failSilently) {
    warn(
      '`onEffectCleanup()` was called when there was no active effect to assign the callback to.',
    );
  }
}

_OrefEffect _createEffect({
  BuildContext? context,
  required void Function() callback,
  required bool detach,
}) {
  late final _OrefEffect effect;
  void withCleanup() {
    effect.cleanup?.call();
    effect.cleanup = null;

    callback();
  }

  effect = _OrefEffect(withCleanup);
  if (context != null) {
    _OrefEffect.finalizer.attach(context, effect, detach: effect);
  }

  final prevSub = alien.setActiveSub(effect);
  if (prevSub != null && !detach) {
    alien.system.link(effect, prevSub, 0);
  }

  try {
    callback();
    return effect;
  } finally {
    alien.setActiveSub(prevSub);
  }
}

class _OrefEffect extends alien.PresetEffect implements Disposable {
  static final finalizer = Finalizer<_OrefEffect>((effect) => effect.dispose());

  _OrefEffect(this.fn) : super(flags: 2 /* Watching */, callback: fn);

  VoidCallback fn;

  @override
  VoidCallback get callback => fn;

  void Function()? onDispose;
  void Function()? cleanup;

  @override
  void dispose() {
    onDispose?.call();
    onDispose = null;
    for (alien.Link? link = deps; link != null; link = link.nextDep) {
      if (link.dep case final Disposable disposable) {
        disposable.dispose();
      }
    }

    super.dispose();
    finalizer.detach(this);
  }
}
