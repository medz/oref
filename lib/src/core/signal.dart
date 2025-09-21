import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";

class _Mask<T> {
  const _Mask(this.signal);
  final T Function([T?, bool]) signal;
}

T Function([T? value, bool nulls]) signal<T>(
  BuildContext context,
  T initialValue,
) {
  final mask = useMemoized(
    context,
    () => _Mask<T>(alien.signal<T>(initialValue)),
  );

  return mask.signal;
}
