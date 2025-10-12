import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset_developer.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "watch.dart";

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
    if (alien.getActiveSub() != null || context == null) {
      return super();
    }

    return watch(context as BuildContext, () => super());
  }
}
