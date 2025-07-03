import 'package:flutter/widgets.dart';

import 'core.dart';
import 'effect.dart';

T Function([T? value, bool nulls]) useSignal<T>(
  BuildContext context,
  T initialValue,
) {
  final prevContext = setCurrentContext(context);
  try {
    autoMarkNeedsBuild(context);
  } finally {
    setCurrentContext(prevContext);
  }
}
