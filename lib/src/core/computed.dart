import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";

final class _Mask<T> {
  const _Mask(this.computed);
  final T Function() computed;
}

T Function() computed<T>(
  BuildContext context,
  T Function(T? previousValue) getter,
) {
  final mask = useMemoized(context, () => _Mask(alien.computed<T>(getter)));
  return mask.computed;
}
