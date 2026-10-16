import 'package:alien_signals/preset.dart' as alien;
import 'package:alien_signals/system.dart' show ReactiveFlags;

import 'alien_adapter.dart';
import 'readable.dart';
import 'subscription.dart';

/// A synchronous value. Changes use the kernel's [identical] comparison.
class Value<T> implements Readable<T> {
  Value(T initial)
    : _node = alien.SignalNode<T>(
        flags: ReactiveFlags.mutable,
        currentValue: initial,
        pendingValue: initial,
      );

  final alien.SignalNode<T> _node;

  @override
  T get value => _node.get();

  set value(T next) => _node.set(next);

  @override
  T peek() => untracked(_node.get);

  @override
  Subscription subscribe(void Function() listener) =>
      subscribeReadable(this, listener);
}
