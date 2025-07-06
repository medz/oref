import 'dart:async';

import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'global.dart';
import 'system.dart';

enum AsyncStatus {
  idle,
  pending,
  success,
  error;

  @Deprecated('Use AsyncStatus.pending instead, Remove in 2.0.0 version')
  static const loading = pending;
}

class AsyncResult<T> {
  const AsyncResult.idle()
    : status = AsyncStatus.idle,
      error = null,
      data = null;

  const AsyncResult.pending()
    : status = AsyncStatus.pending,
      error = null,
      data = null;

  const AsyncResult.success(T this.data)
    : status = AsyncStatus.success,
      error = null;

  AsyncResult.error(Object error, [StackTrace? stackTrace])
    : status = AsyncStatus.error,
      data = null,
      error = AsyncError(error, stackTrace);

  final AsyncStatus status;
  final AsyncError? error;
  final T? data;

  @override
  bool operator ==(Object other) {
    return other is AsyncResult &&
        runtimeType == other.runtimeType &&
        status == other.status &&
        data == other.data &&
        error == other.error;
  }

  @override
  int get hashCode => Object.hash(status, error, data, runtimeType);
}

class UnrefAsyncResult<T> implements AsyncResult<T> {
  const UnrefAsyncResult(this.getter);

  final AsyncResult<T> Function() getter;

  @override
  AsyncStatus get status => getter().status;

  @override
  T? get data => getter().data;

  @override
  AsyncError? get error => getter().error;
}

AsyncResult<T> createGlobalAsyncResult<T>(
  FutureOr<T> Function() computation, {
  Iterable<void Function()>? watch,
}) {
  final signal = createGlobalSignal(AsyncResult<T>.idle());
  int version = 0;
  effect(() {
    version++;
    if (watch != null && watch.isNotEmpty) {
      for (final track in watch) {
        track();
      }
    }

    final currentVersion = version;
    unawaited(
      Future.microtask(() async {
        if (currentVersion != version) return;
        signal(AsyncResult<T>.pending());
        try {
          final data = await computation();
          if (currentVersion == version) {
            signal(AsyncResult<T>.success(data));
          }
        } catch (e, s) {
          if (currentVersion == version) {
            signal(AsyncResult<T>.error(e, s));
          }
        }
      }),
    );
  });

  return UnrefAsyncResult(signal);
}

AsyncResult<T> useAsyncResult<T>(
  BuildContext context,
  FutureOr<T> Function() computation, {
  Iterable<void Function()>? watch,
}) {
  final signal = useSignal(context, AsyncResult<T>.idle());
  useEffectScope(context, () {
    int version = 0;
    final prevSub = setCurrentSub(null);

    try {
      effect(() {
        version++;
        if (watch != null && watch.isNotEmpty) {
          for (final track in watch) {
            track();
          }
        }

        final currentVersion = version;
        unawaited(
          Future.microtask(() async {
            if (currentVersion != version) return;
            signal(AsyncResult<T>.pending());
            try {
              final data = await computation();
              if (currentVersion == version) {
                signal(AsyncResult<T>.success(data));
              }
            } catch (e, s) {
              if (currentVersion == version) {
                signal(AsyncResult<T>.error(e, s));
              }
            }
          }),
        );
      });
    } finally {
      setCurrentSub(prevSub);
    }
  });

  return UnrefAsyncResult(signal);
}
