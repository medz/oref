import "package:alien_signals/alien_signals.dart" as alien;
import "package:flutter/widgets.dart";

import "memoized.dart";

T Function([T? value, bool nulls]) signal<T>(
  BuildContext context,
  T initialValue,
) {
  return useMemoized(context, () => alien.signal(initialValue));
}
