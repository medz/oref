import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/material.dart';

import '../core/memoized.dart';

final class Ref<T extends Widget> {
  const Ref._(this._signal);

  final T Function([T?, bool]) _signal;

  T get widget => _signal();
}

extension WidgetRef<T extends Widget> on T {
  Ref<T> useRef(BuildContext context) => _upsert(context, this);
}

extension StateRef<T extends StatefulWidget> on State<T> {
  Ref<T> useRef() => _upsert(context, widget);
}

Ref<T> _upsert<T extends Widget>(BuildContext context, T widget) {
  final ref = useMemoized(context, () => Ref._(alien.signal(widget)));
  if (ref.widget != widget) {
    ref._signal(widget);
  }

  return ref;
}
