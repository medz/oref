import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/preset.dart' as preset;
import 'package:alien_signals/system.dart' as system;

/// A reactive value that can be read by a synchronous observer.
///
/// Reading [value] inside a [Computed] or [Effect] tracks the dependency.
abstract interface class Readable<T> {
  T get value;
}

/// A writable reactive value using alien_signals' identity comparison.
///
/// Assigning an identical object does not notify observers, including after an
/// in-place collection mutation. Replace the value or use [trigger] with a read.
/// No additional value cache, equality policy, or notification engine is used.
abstract interface class Signal<T> implements Readable<T> {
  factory Signal(T initialValue) = _Signal<T>;

  @override
  T get value;

  set value(T nextValue);
}

// Keep upstream graph fields off the public interface while using one node,
// not a public wrapper around a callable upstream signal.
final class _Signal<T> extends preset.SignalNode<T> implements Signal<T> {
  _Signal(T initialValue)
    : super(
        flags: system.ReactiveFlags.mutable,
        currentValue: initialValue,
        pendingValue: initialValue,
      );

  @override
  T get value => get();

  @override
  set value(T nextValue) => set(nextValue);
}

/// A lazy, cached, read-only derived value.
///
/// Dynamic dependencies, identity comparison, error caching and recovery follow
/// alien_signals. A failed getter is retried after a tracked dependency changes.
/// This object adds no second cache or dependency graph.
abstract interface class Computed<T> implements Readable<T> {
  factory Computed(T Function() compute) = _Computed<T>;

  /// Provides the last successful value, or null before the first success.
  ///
  /// The previous value remains unchanged after a getter error. A successful
  /// null is indistinguishable from no previous value, as in alien_signals.
  factory Computed.withPrevious(T Function(T? previousValue) compute) =
      _Computed<T>.withPrevious;
}

final class _Computed<T> extends preset.ComputedNode<T> implements Computed<T> {
  _Computed(T Function() compute)
    : super(flags: system.ReactiveFlags.none, getter: (_) => compute());

  _Computed.withPrevious(T Function(T?) compute)
    : super(flags: system.ReactiveFlags.none, getter: compute);

  @override
  T get value => get();
}

/// Registers the current effect run's cleanup synchronously.
///
/// Callbacks run in reverse registration order through one upstream cleanup slot.
/// A cleanup error propagates and stops the remaining callbacks. Calling this
/// after the effect callback returns throws [StateError].
typedef OnCleanup = void Function(void Function() cleanup);

/// A synchronous reactive effect with explicit disposal.
///
/// [callback] runs immediately during construction, then when its tracked
/// dependencies change. Use its [OnCleanup] argument to register a cleanup.
/// The adapter returns that cleanup to alien_signals, which runs it before the
/// next execution and on disposal. Cleanup reads are untracked; nested effects
/// and scopes are disposed before their parent's cleanup.
///
/// Tracking, ownership and cleanup registration are synchronous. A Future is
/// not awaited, reads after `await` are not tracked, and effects created after
/// `await` are not owned by this effect. Handle asynchronous errors and disposal
/// of asynchronous work yourself.
///
/// Callback and cleanup exceptions propagate from alien_signals. A throwing
/// initial callback is not automatically stopped by the upstream factory; the
/// constructor cannot return a handle in that case. Cleanup registrations from
/// any throwing run are not installed, because that run never returns its cleanup
/// to upstream. Self-disposal during a run also follows upstream behavior and
/// does not guarantee execution of cleanup registered by that unfinished run.
/// This wrapper adds no error isolation, setup rollback, or independent owner
/// context.
final class Effect {
  Effect(void Function(OnCleanup onCleanup) callback)
    : _effect = alien.effect(() {
        final cleanups = <void Function()>[];
        var acceptingCleanup = true;
        try {
          callback((nextCleanup) {
            if (!acceptingCleanup) {
              throw StateError('Cleanup must be registered synchronously.');
            }
            cleanups.add(nextCleanup);
          });
          if (cleanups.isEmpty) return null;
          return () {
            for (final cleanup in cleanups.reversed) {
              cleanup();
            }
          };
        } finally {
          acceptingCleanup = false;
        }
      });

  final alien.Effect _effect;
  bool _disposing = false;

  /// Stops the effect using the upstream disposal behavior.
  ///
  /// Repeated disposal after successful cleanup does not run cleanup again.
  /// Cleanup errors propagate and can interrupt upstream disposal traversal.
  /// Recursive calls through this handle while it is stopping are ignored.
  void dispose() {
    if (_disposing) return;
    _disposing = true;
    try {
      _effect();
    } finally {
      _disposing = false;
    }
  }
}

/// A lifecycle group for synchronously created effects and nested scopes.
///
/// Construction creates an upstream effect scope in the current subscriber.
/// Use [run] to enter it synchronously. Reading a signal in [run] does not turn
/// the scope into an effect or cause its callback to rerun. Effects and scopes
/// created inside [untracked] are not attached to this scope.
///
/// This keeps alien_signals' shared tracking/ownership context; it does not add
/// an independent owner, async context, or reactive execution of its own.
/// Keep computed getters free of side effects: upstream graph failures during
/// reentrant computed disposal can invalidate flag-based liveness detection.
final class ReactiveScope {
  ReactiveScope() {
    _scope = alien.effectScope(() {
      _node = preset.getActiveSub()!;
    });
  }

  late final alien.EffectScope _scope;
  late final system.ReactiveNode _node;
  bool _disposed = false;
  bool _disposing = false;

  // ReactiveFlags and EffectScopeNode are public upstream APIs. A stopped scope
  // can still gain hasChildEffect from callback code continuing after disposal,
  // so checking for flags == none alone would incorrectly allow reentry.
  bool get _isStopped =>
      _disposed ||
      (_node.flags & system.ReactiveFlags.mutable) == system.ReactiveFlags.none;

  /// Executes [callback] once in this scope and returns its result.
  ///
  /// Throws [StateError] if this scope has already been disposed, including by
  /// its parent. Exceptions from [callback] propagate; existing children remain
  /// owned by the scope and can be disposed using its handle. A returned Future
  /// is not awaited: work after `await` needs its own disposal handle.
  ///
  /// If the scope is stopped during this call, children attached by the remaining
  /// synchronous callback are stopped again before return. This adapter guard
  /// does not abort the callback. If both callback and this final disposal throw,
  /// the disposal error takes precedence, following Dart `finally` semantics.
  T run<T>(T Function() callback) {
    if (_isStopped) {
      _disposed = true;
      throw StateError('Cannot run a disposed reactive scope.');
    }
    final previous = preset.setActiveSub(_node);
    try {
      return callback();
    } finally {
      try {
        if (_isStopped) {
          _disposed = true;
          // A reentrant parent rerun can stop this scope while callback keeps
          // executing. Drain children attached by the rest of that synchronous
          // callback before leaving this new reusable-run boundary.
          dispose();
        }
      } finally {
        preset.setActiveSub(previous);
      }
    }
  }

  /// Disposes this scope's currently owned effects and nested scopes.
  ///
  /// Cleanup exceptions propagate and can interrupt upstream traversal.
  /// Recursive calls through this handle while it is stopping are ignored.
  void dispose() {
    if (_disposing) return;
    _disposed = true;
    _disposing = true;
    try {
      _scope();
    } finally {
      _disposing = false;
    }
  }
}

/// Defers effect flushing until the outermost synchronous batch ends.
///
/// Reads see current values inside the batch. The batch is ended in `finally`,
/// including when [callback] throws. There is no rollback; errors raised during
/// the final upstream flush can replace an error from [callback]. Returning a
/// Future ends the batch immediately, not when the Future completes.
T batch<T>(T Function() callback) {
  preset.startBatch();
  try {
    return callback();
  } finally {
    preset.endBatch();
  }
}

/// Runs [callback] without the caller's active upstream subscriber.
///
/// Signal reads do not subscribe the caller. A computed read still tracks its
/// own dependencies. alien_signals uses the active subscriber for both tracking
/// and nested effect/scope ownership, so effects/scopes created here are also
/// detached from the caller and require their own disposal handles.
///
/// The previous subscriber is restored in `finally`. The boundary is synchronous
/// and does not extend across `await` or establish an independent owner context.
T untracked<T>(T Function() callback) {
  final previous = preset.setActiveSub(null);
  try {
    return callback();
  } finally {
    preset.setActiveSub(previous);
  }
}

/// Notifies observers of reactive values read synchronously by [callback].
///
/// Use after an in-place mutation when assigning the identical object would not
/// notify. This delegates to the upstream preset, including its batching and
/// exception behavior. It is not a mutation transaction or a custom-node API.
/// Only reads directly tracked by the temporary subscriber are selected;
/// reading a computed selects that computed, not its transitive dependencies.
/// The caller does not track these reads. Notification still happens when the
/// callback throws, and a flush error can replace that error. Do not create
/// effects or scopes inside this temporary tracking boundary. It does not
/// extend across `await`.
void trigger(void Function() callback) => preset.trigger(callback);
