import 'dart:async';

import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/widgets.dart';

import '../core/batch.dart';
import '../core/effect.dart';
import '../core/signal.dart';
import '../core/untrack.dart';
import '../core/watch.dart';

enum AsyncStatus { idle, pending, success, error }

abstract interface class AsyncData<T> {
  abstract AsyncStatus status;
  abstract AsyncError? error;
  abstract T? data;

  void stop();
  Future<T?> refresh();

  R when<R>({
    BuildContext? context,
    required R Function(T?) idle,
    required R Function() pending,
    required R Function(T? data) success,
    required R Function(AsyncError? error) error,
  });
}

AsyncData<T> useAsyncData<T>(
  BuildContext? context,
  ValueGetter<FutureOr<T>> handler, {
  ValueGetter<T?>? defaults,
}) {
  final executor = _AsyncDataExecutor<T>(
    data: signal<T?>(context, defaults != null ? untrack(defaults) : null),
    error: signal<AsyncError?>(context, null),
    status: signal(context, AsyncStatus.idle),
    handler: handler,
  );

  executor.ensureInitialized(context);

  return _AsyncDataImpl(executor, context);
}

typedef _Signal<T> = T Function([T?, bool]);

class _AsyncDataExecutor<T> {
  static final store = Expando<alien.ReactiveNode>('oref:async_data');

  _AsyncDataExecutor({
    required this.data,
    required this.error,
    required this.status,
    required this.handler,
  });

  final _Signal<T?> data;
  final _Signal<AsyncError?> error;
  final _Signal<AsyncStatus> status;
  final ValueGetter<FutureOr<T>> handler;

  late final VoidCallback stop;
  late final alien.ReactiveNode node;

  bool isInitialized = false;
  late Completer<T?> completer = Completer.sync()..complete(null);

  void ensureInitialized(BuildContext? context) {
    stop = effect(context, () {
      if (!isInitialized) {
        isInitialized = true;
        if (context != null) {
          store[context] = alien.getCurrentSub()!;
        } else {
          node = alien.getCurrentSub()!;
        }
      }

      Future.microtask(schedule);
    });

    if (context != null) {
      node = store[context]!;
    }
  }

  void schedule() async {
    if (untrack(status) == AsyncStatus.pending) {
      return;
    } else if (completer.isCompleted) {
      completer = Completer();
    }

    status(AsyncStatus.pending);

    try {
      final result = await scoped(handler);
      batch(() {
        this
          ..data(result)
          ..status(AsyncStatus.success);
      });

      completer.complete(result);
    } catch (error, stackTrace) {
      batch(() {
        this
          ..error(AsyncError(error, stackTrace))
          ..status(AsyncStatus.error);
      });

      completer.completeError(error, stackTrace);
    }
  }

  Future<R> scoped<R>(FutureOr<R> Function() run) async {
    final prevSub = alien.setCurrentSub(node);
    try {
      return await run();
    } finally {
      alien.setCurrentSub(prevSub);
    }
  }
}

class _AsyncDataImpl<T> implements AsyncData<T> {
  _AsyncDataImpl(this.executor, this.context);

  final _AsyncDataExecutor<T> executor;
  final BuildContext? context;

  @override
  T? get data => executor.data();

  @override
  set data(T? value) => executor.data(value, true);

  @override
  AsyncError? get error => executor.error();

  @override
  set error(AsyncError? value) => executor.error(value, true);

  @override
  AsyncStatus get status => executor.status();

  @override
  set status(AsyncStatus value) => executor.status(value);

  @override
  Future<T?> refresh() async {
    if (executor.completer.isCompleted) {
      executor.schedule();
    }

    return executor.completer.future;
  }

  @override
  void stop() => executor.stop();

  @override
  R when<R>({
    BuildContext? context,
    required R Function(T?) idle,
    required R Function() pending,
    required R Function(T? data) success,
    required R Function(AsyncError? error) error,
  }) {
    context ??= this.context;
    R builder() => switch (status) {
      AsyncStatus.idle => idle(data),
      AsyncStatus.pending => pending(),
      AsyncStatus.success => success(data),
      AsyncStatus.error => error(this.error),
    };
    if (context != null) {
      return watch(context, builder);
    }

    return builder();
  }
}
