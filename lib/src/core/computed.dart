import 'package:alien_signals/preset.dart' as alien;
import 'package:alien_signals/system.dart' show ReactiveFlags;

import 'alien_adapter.dart';
import 'readable.dart';
import 'subscription.dart';

/// A lazy calculation with the kernel's caching and dynamic dependencies.
class Computed<T> implements Readable<T> {
  Computed(T Function() calculate)
    : _node = alien.ComputedNode<T>(
        flags: ReactiveFlags.none,
        getter: (_) => calculate(),
      );

  final alien.ComputedNode<T> _node;

  @override
  T get value => _node.get();

  @override
  T peek() => untracked(_node.get);

  @override
  Subscription subscribe(void Function() listener) =>
      subscribeReadable(this, listener);
}
