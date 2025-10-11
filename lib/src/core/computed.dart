import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset_developer.dart" as alien;
import "package:alien_signals/system.dart" as alien show ReactiveNode;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "widget_effect.dart";

typedef Computed<T> = alien.Computed<T>;

// Use Expando to store computed instances per context to persist across rebuilds
// This is necessary because memoized values are reset when reactive dependencies change
final _computedStore = Expando<Map<int, _OrefComputed>>("oref:computed");
int _nextComputedId = 0;

Computed<T> computed<T>(
  BuildContext? context,
  T Function(T? previousValue) getter,
) {
  if (context == null) {
    return _OrefComputed<T>(getter: getter);
  }

  // Get or create the computed map for this context
  final map = _computedStore[context] ??= {};

  // Use memoized to generate a stable ID for this computed call site
  final id = useMemoized(context, () => _nextComputedId++);

  // Get or create the computed instance using the ID
  final existing = map[id];
  if (existing != null && existing is _OrefComputed<T>) {
    return existing;
  }

  final computed = _OrefComputed<T>(getter: getter, context: context);
  map[id] = computed;
  return computed;
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
