import 'dart:async';

import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import 'computed.dart';
import 'core.dart';
import 'effect.dart';
import 'global_reactive.dart';
import 'signal.dart';

enum AsyncStatus { idle, loading, success, error }

abstract interface class AsyncResult<T> {
  AsyncStatus get status;
  AsyncError? get error;
  T? get data;
}

class AsyncResultImpl<T> implements AsyncResult<T> {
  const AsyncResultImpl({
    required AsyncStatus Function([AsyncStatus? status, bool nulls]) status,
    required AsyncError? Function([AsyncError? error, bool nulls]) error,
    required T? Function([T? data, bool nulls]) data,
  }) : _status = status,
       _error = error,
       _data = data;

  final AsyncStatus Function([AsyncStatus? status, bool nulls]) _status;
  final AsyncError? Function([AsyncError? error, bool nulls]) _error;
  final T? Function([T? data, bool nulls]) _data;

  @override
  AsyncStatus get status => _status();

  @override
  AsyncError? get error => _error();

  @override
  T? get data => _data();

  set error(AsyncError? error) {
    batch(() {
      _status(AsyncStatus.error);
      _error(error);
      _data(null, true);
    });
  }

  set data(T? data) {
    batch(() {
      _status(AsyncStatus.success);
      _error(null, true);
      _data(data);
    });
  }
}

AsyncResult<R> createGlobalAsyncComputed<T, R>(
  T Function(T? prevValue) watch,
  FutureOr<R> Function(T value) future,
) {
  final status = createGlobalSignal<AsyncStatus>(AsyncStatus.idle);
  final signal = AsyncResultImpl<R>(
    status: status,
    error: createGlobalSignal<AsyncError?>(null),
    data: createGlobalSignal<R?>(null),
  );
  final computed = createGlobalComputed(watch);
  int currentVersion = 0;

  effect(() {
    final value = computed();
    final version = currentVersion++;
    unawaited(
      Future.sync(() async {
        if (currentVersion != version) return;
        status(AsyncStatus.loading);
        try {
          final data = await future(value);
          if (currentVersion != version) return;
          signal.data = data;
        } catch (e, s) {
          if (currentVersion != version) return;
          signal.error = AsyncError(e, s);
        }
      }),
    );
  });

  return signal;
}

AsyncResult<R> useAsyncComputed<T, R>(
  BuildContext context,
  T Function(T? prevValue) watch,
  FutureOr<R> Function(T value) future,
) {
  final status = useSignal<AsyncStatus>(context, AsyncStatus.idle);
  final signal = untrack(
    useComputed(
      context,
      (_) => AsyncResultImpl<R>(
        status: status,
        error: useSignal<AsyncError?>(context, null),
        data: useSignal<R?>(context, null),
      ),
    ),
  );

  final computed = useComputed(context, watch);
  final currentVersion = useSignal(context, 0);

  useEffect(context, () {
    final value = computed();
    final version = untrack(() {
      final version = currentVersion();
      currentVersion(version + 1);
      return version;
    });

    unawaited(
      Future.sync(() async {
        if (untrack(currentVersion) != version) return;
        status(AsyncStatus.loading);
        try {
          final data = await future(value);
          if (untrack(currentVersion) != version) return;
          signal.data = data;
        } catch (e, s) {
          if (untrack(currentVersion) != version) return;
          signal.error = AsyncError(e, s);
        }
      }),
    );
  });

  return signal;
}
