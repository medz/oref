import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/system.dart' as alien;
import 'package:alien_signals/preset.dart' as alien;
import 'package:flutter/widgets.dart';

import '_warn.dart';
import '_element_disposer.dart';
import 'memoized.dart';
import 'widget_scope.dart';
import '../devtools/devtools.dart';

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
/// count.set(1); // Print 1
///
/// stop();
/// count.set(2); // No output
/// ```
alien.Effect effect(
  BuildContext? context,
  void Function() callback, {
  bool detach = false,
  String? debugLabel,
  Object? debugOwner,
  String? debugScope,
  String? debugType,
  String? debugNote,
}) {
  if (context == null) {
    return _createEffect(
      callback: callback,
      detach: detach,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugType: debugType,
      debugNote: debugNote,
    );
  }

  final e = useMemoized(context, () {
    if (detach || alien.getActiveSub() != null) {
      return _createEffect(
        context: context,
        callback: callback,
        detach: detach,
        debugLabel: debugLabel,
        debugOwner: debugOwner,
        debugScope: debugScope,
        debugType: debugType,
        debugNote: debugNote,
      );
    }

    final scope = useWidgetScope(context);
    final prevSub = alien.setActiveSub(scope as alien.ReactiveNode);
    try {
      return _createEffect(
        context: context,
        callback: callback,
        detach: false,
        debugLabel: debugLabel,
        debugOwner: debugOwner,
        debugScope: debugScope,
        debugType: debugType,
        debugNote: debugNote,
      );
    } finally {
      alien.setActiveSub(prevSub);
    }
  });

  assert(() {
    e.callback = _wrapEffectCallback(() => e, callback);
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
  String? debugLabel,
  Object? debugOwner,
  String? debugScope,
  String? debugType,
  String? debugNote,
}) {
  late final _OrefEffect effect;
  late final VoidCallback run;
  run = _wrapEffectCallback(() => effect, callback);
  effect = _OrefEffect(run);
  if (context != null) {
    _OrefEffect.finalizer.attach(context, effect, detach: effect);
    registerElementDisposer(context, effect.call);
  }

  final handle = devtools.bindEffect(
    effect,
    context: context,
    debugLabel: debugLabel,
    debugOwner: debugOwner,
    debugScope: debugScope,
    debugType: debugType,
    debugNote: debugNote,
  );
  effect.attachDevTools(handle);

  final prevSub = alien.setActiveSub(effect);
  if (prevSub != null && !detach) {
    alien.link(effect, prevSub, 0);
  }

  try {
    run();
    return effect;
  } finally {
    alien.setActiveSub(prevSub);
    effect.flags &= -5 /*~ReactiveFlags.recursedCheck*/;
  }
}

class _OrefEffect extends alien.EffectNode implements alien.Effect {
  static final finalizer = Finalizer<_OrefEffect>((stop) => stop());

  _OrefEffect(this.callback)
    : super(
        flags: alien.ReactiveFlags.watching | alien.ReactiveFlags.recursedCheck,
        fn: callback,
      );

  VoidCallback callback;
  void Function()? onDispose;
  void Function()? cleanup;
  EffectHandle? _devtools;

  void attachDevTools(EffectHandle handle) {
    _devtools = handle;
  }

  @override
  VoidCallback get fn => callback;

  @override
  void call() {
    _devtools?.dispose();
    onDispose?.call();
    onDispose = null;
    for (alien.Link? link = deps; link != null; link = link.nextDep) {
      switch (link.dep) {
        case alien.EffectScope scope:
          scope();
          break;
        case alien.Effect effect:
          effect();
          break;
        case alien.EffectNode node:
          alien.stop(node);
          break;
      }
    }

    alien.stop(this);
    finalizer.detach(this);
  }
}

VoidCallback _wrapEffectCallback(
  _OrefEffect Function() effectGetter,
  VoidCallback callback,
) {
  return () {
    final effect = effectGetter();
    effect.cleanup?.call();
    effect.cleanup = null;
    final stopwatch = Stopwatch()..start();
    try {
      callback();
    } finally {
      stopwatch.stop();
      effect._devtools?.run(stopwatch.elapsedMilliseconds);
    }
  };
}
