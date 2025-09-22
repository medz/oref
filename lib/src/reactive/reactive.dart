import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

final class _Wrap<T> {
  const _Wrap(this.value);
  final T value;
}

abstract mixin class Reactive<T extends Reactive<T>> {
  late final _signal = alien.signal(_Wrap(this as T));

  @protected
  void track() => _signal();

  @protected
  void trigger() => _signal(_Wrap(this as T));

  T call() => _signal().value;
}
