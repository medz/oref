import 'dart:async';

import 'package:alien_signals/preset.dart' as alien;
import 'package:alien_signals/system.dart' show ReactiveFlags;

import 'readable.dart';
import 'subscription.dart';

/// Internal untracked scope. Computed values still track their own inputs.
R untracked<R>(R Function() callback) {
  final previous = alien.setActiveSub(null);
  try {
    return callback();
  } finally {
    alien.setActiveSub(previous);
  }
}

/// Internal detached native effect; the caller owns its subscription.
Subscription reactiveEffect(void Function() callback) {
  final node = alien.EffectNode<void>(flags: ReactiveFlags.dirty, fn: callback);
  final subscription = _NativeSubscription(node);
  try {
    untracked(() => alien.run(node));
    return subscription;
  } catch (_) {
    subscription.dispose();
    rethrow;
  }
}

/// The common subscribe adapter for public readable values.
Subscription subscribeReadable<T>(
  Readable<T> readable,
  void Function() listener,
) {
  final zone = Zone.current;
  var first = true;
  return reactiveEffect(() {
    readable.value;
    if (first) {
      first = false;
      return;
    }
    untracked(() => zone.runGuarded(listener));
  });
}

final class _NativeSubscription implements Subscription {
  _NativeSubscription(this._node);

  alien.EffectNode<void>? _node;

  @override
  void dispose() {
    final node = _node;
    if (node == null) return;
    _node = null;
    if (identical(alien.getActiveSub(), node)) {
      alien.setActiveSub(null);
    }
    alien.stop(node);
  }
}

/// Internal deferred observer used by Flutter.
///
/// Only [track] executes the supplied builder. Native propagation calls
/// [onInvalidate] and releases the previous dependencies until the next track.
/// Dependency collection, comparison and cleanup remain native operations.
final class ReactiveObserver implements Subscription {
  ReactiveObserver(void Function() onInvalidate)
    : _onInvalidate = onInvalidate,
      _zone = Zone.current {
    _node = alien.EffectNode<void>(
      flags: ReactiveFlags.watching,
      fn: () {
        final collect = _collect;
        _collect = null;
        if (collect != null) {
          collect();
        } else if (!_disposed) {
          untracked(() => _zone.runGuarded(_onInvalidate));
        }
      },
    );
  }

  final void Function() _onInvalidate;
  final Zone _zone;
  late final alien.EffectNode<void> _node;
  void Function()? _collect;
  bool _disposed = false;
  bool _tracking = false;

  R track<R>(R Function() build) {
    if (_disposed) throw StateError('The observer is disposed.');
    if (_tracking) throw StateError('The observer is already tracking.');
    late R result;
    _tracking = true;
    _collect = () => result = build();
    try {
      _node.flags |= ReactiveFlags.dirty;
      alien.run(_node);
      return result;
    } finally {
      _collect = null;
      _tracking = false;
      // The kernel marks writes to a dependency during its own effect as
      // pending without queueing that active effect. Finish that native check
      // now; only the invalidation callback runs, never the builder again.
      if (!_disposed &&
          (_node.flags & (ReactiveFlags.pending | ReactiveFlags.dirty)) !=
              ReactiveFlags.none) {
        untracked(() => alien.run(_node));
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _collect = null;
    if (identical(alien.getActiveSub(), _node)) {
      alien.setActiveSub(null);
    }
    alien.stop(_node);
  }
}
