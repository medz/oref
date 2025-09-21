import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

import 'memoized.dart';

void Function() effectScope(
  BuildContext context,
  void Function() run, {
  bool detach = false,
}) {
  if (!detach) {
    return useMemoized(context, () => alien.effectScope(run));
  }

  final prevScope = alien.setCurrentScope(null);
  try {
    return useMemoized(context, () => alien.effectScope(run));
  } finally {
    alien.setCurrentScope(prevScope);
  }
}
