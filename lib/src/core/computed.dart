import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset_developer.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";
import "watch.dart";

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
  T get value {
    if (alien.getActiveSub() != null || context == null) {
      return super.value;
    }

    return watch(context as BuildContext, () => super.value);
  }
}
