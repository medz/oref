import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/system.dart" as alien;
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
    // If we're in a widget context and haven't subscribed yet, subscribe once
    if (context != null && !_subscribed && alien.getActiveSub() == null) {
      _subscribed = true;
      final effect = useWidgetEffect(context!);
      alien.system.link(this, effect as alien.ReactiveNode, 0);
    }

    return super();
  }
}
