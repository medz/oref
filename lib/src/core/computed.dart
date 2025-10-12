import "package:alien_signals/alien_signals.dart" as alien;
import "package:alien_signals/preset_developer.dart" as alien;
import "package:flutter/widgets.dart";

import "context.dart";
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

  return useMemoized(context, () => _OrefComputed<T>(getter: getter));
}

class _OrefComputed<T> extends alien.PresetComputed<T> {
  _OrefComputed({required super.getter}) : super(flags: 0 /* None */);

  @override
  T call() {
    if (alien.getActiveSub() == null) {
      if (getActiveContext() case final Element element) {
        return watch(element, super.call);
      }
    }

    return super();
  }
}
