import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset_developer.dart" as alien;
import "package:flutter/widgets.dart";

import "context.dart";
import "memoized.dart";
import "widget_effect.dart";

typedef Computed<T> = alien.Computed<T>;

Computed<T> computed<T>(
  BuildContext? context,
  T Function(T? previousValue) getter,
) {
  if (context == null) {
    return _OrefComputed<T>(getter: getter);
  }

  return useMemoized(context, () => _OrefComputed<T>(getter: getter, context: context));
}

class _OrefComputed<T> extends alien.PresetComputed<T> {
  _OrefComputed({required super.getter, this.context}) : super(flags: 0 /* None */);

  final BuildContext? context;
  bool _subscribed = false;

  @override
  T call() {
    // If we're in a widget context and not already in an effect, wrap in widget effect
    if (context != null && alien.getActiveSub() == null) {
      final effect = useWidgetEffect(context!);
      final prevSub = alien.setActiveSub(effect as alien.ReactiveNode);
      try {
        return super.call();
      } finally {
        alien.setActiveSub(prevSub);
      }
    }

    return super.call();
  }
}
