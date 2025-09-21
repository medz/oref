import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'memoized.dart';

void Function() useEffectScope(
  BuildContext context,
  void Function() run, {
  bool detach = false,
}) {
  if (!detach) {
    return useMemoized(context, () => effectScope(run));
  }

  final prevScope = setCurrentScope(null);
  try {
    return useMemoized(context, () => effectScope(run));
  } finally {
    setCurrentScope(prevScope);
  }
}
