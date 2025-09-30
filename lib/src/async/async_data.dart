import 'dart:async';

import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/system.dart' as alien;
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart' as oref;

enum AsyncStatus { idle, pending, success, error }

abstract interface class AsyncData<T> {
  abstract AsyncStatus status;
  abstract AsyncError? error;
  abstract T? data;

  void dispose();
  Future<T?> refresh();

  R when<R>({
    BuildContext? context,
    required R Function(T?) idle,
    required R Function(T?) pending,
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
    data: oref.signal<T?>(
      context,
      defaults != null ? oref.untrack(defaults) : null,
    ),
    error: oref.signal<AsyncError?>(context, null),
    status: oref.signal(context, AsyncStatus.idle),
    handler: handler,
  );

  executor.ensureInitialized(context);

  return _AsyncDataImpl(executor, context);
}

class _AsyncDataExecutor<T> {
  _AsyncDataExecutor({
    required this.data,
    required this.error,
    required this.status,
    required this.handler,
  });

  final oref.WritableSignal<T?> data;
  final oref.WritableSignal<AsyncError?> error;
  final oref.WritableSignal<AsyncStatus> status;
  final ValueGetter<FutureOr<T>> handler;

  late final alien.ReactiveNode node;

  bool isInitialized = false;
  late Completer<T?> completer = Completer.sync()..complete(null);

  void ensureInitialized(BuildContext? context) {
    final effect = oref.effect(context, () {
      if (!isInitialized) {
        isInitialized = true;
      }

      Future.microtask(schedule);
    });

    if (context != null) {
      node = effect as alien.ReactiveNode;
    }
  }

  void schedule() async {
    if (oref.untrack(status.call) == AsyncStatus.pending) {
      return;
    } else if (completer.isCompleted) {
      completer = Completer();
    }

    status(AsyncStatus.pending);

    try {
      final result = await scoped(handler);
      oref.batch(() {
        data(result);
        status(AsyncStatus.success);
      });

      completer.complete(result);
    } catch (error, stackTrace) {
      oref.batch(() {
        this.error(AsyncError(error, stackTrace));
        status(AsyncStatus.error);
      });

      completer.completeError(error, stackTrace);
    }
  }

  Future<R> scoped<R>(FutureOr<R> Function() run) async {
    final prevSub = alien.setActiveSub(node);
    try {
      return await run();
    } finally {
      alien.setActiveSub(prevSub);
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
  set status(AsyncStatus value) => executor.status(value, true);

  @override
  Future<T?> refresh() async {
    if (executor.completer.isCompleted) {
      executor.schedule();
    }

    return executor.completer.future;
  }

  @override
  void dispose() {
    (executor.node as oref.Effect).dispose();
  }

  @override
  R when<R>({
    BuildContext? context,
    required R Function(T?) idle,
    required R Function(T?) pending,
    required R Function(T? data) success,
    required R Function(AsyncError? error) error,
  }) {
    context ??= this.context;
    R builder() => switch (status) {
      AsyncStatus.idle => idle(data),
      AsyncStatus.pending => pending(data),
      AsyncStatus.success => success(data),
      AsyncStatus.error => error(this.error),
    };
    if (context != null) {
      return oref.watch(context, builder);
    }

    return builder();
  }
}
