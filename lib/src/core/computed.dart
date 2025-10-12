import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset_developer.dart" as alien;
import "package:alien_signals/system.dart" as alien show ReactiveNode;
import "package:flutter/widgets.dart";

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

  return useMemoized(
    context,
    () => _OrefComputed<T>(getter: getter, context: context),
  );
}

class _OrefComputed<T> extends alien.PresetComputed<T> {
  _OrefComputed({required super.getter, this.context})
    : super(flags: 0 /* None */);

  final BuildContext? context;

  @override
  T call() {
    final activeSub = alien.getActiveSub();

    // If there's already an active subscription or no context, just use parent behavior
    if (activeSub != null || context == null) {
      return super();
    }

    // When called from a widget context, we need to register this computed
    // as a dependency for the widget to rebuild, but we must NOT wrap
    // the super() call itself in watch() because that would interfere with
    // the computed's internal state management (like previousValue tracking)
    final effect = useWidgetEffect(context as BuildContext);
    final prevSub = alien.setActiveSub(effect as alien.ReactiveNode);
    try {
      // Call super() directly while the widget effect is active
      // This allows the computed to be tracked as a dependency
      // without interfering with its own getter execution
      return super();
    } finally {
      alien.setActiveSub(prevSub);
    }
  }
}
