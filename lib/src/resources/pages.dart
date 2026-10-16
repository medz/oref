part of 'resource.dart';

/// The single active stage of a paginated resource.
enum PagePhase { idle, initial, refresh, append }

/// An immutable cumulative list and its current request status.
class PagesState<S, T, C extends Object> {
  const PagesState._({
    this.hasSource = false,
    this._source,
    required this.items,
    this.hasLoaded = false,
    this.phase = PagePhase.idle,
    this.hasNext = false,
    this.error,
    this.stackTrace,
    this.nextError,
    this.nextStackTrace,
  });

  final bool hasSource;
  final Object? _source;
  final List<T> items;
  final bool hasLoaded;
  final PagePhase phase;
  final bool hasNext;
  final Object? error;
  final StackTrace? stackTrace;
  final Object? nextError;
  final StackTrace? nextStackTrace;

  S get source {
    if (!hasSource) throw StateError('The pages have no source.');
    return _source as S;
  }
}

/// First-page refresh and cursor pagination with stale-result rejection.
class Pages<S, T, C extends Object> {
  Pages({
    required S Function() source,
    required this._load,
    required this._nextCursor,
  }) {
    _source = _Source<S>(
      source: source,
      control: _control,
      changed: _sourceChanged,
      failed: _sourceFailed,
    );
    _control.pause = _source.pause;
    _control.resume = _source.resume;
  }

  final _control = _ResourceControl();
  late final _Source<S> _source;
  FutureOr<List<T>> Function(S, C?, ReadRequest) _load;
  C? Function(S, List<T>) _nextCursor;
  final _state = Value<PagesState<S, T, C>>(
    PagesState<S, T, C>._(items: List<T>.unmodifiable([])),
  );
  _ReadOperation<List<T>>? _active;
  Future<List<T>>? _attempt;
  C? _cursor;
  int _epoch = 0;

  Readable<PagesState<S, T, C>> get state => _state;

  /// Joins or returns the latest first-page attempt, including a failed one.
  Future<List<T>> ensureLoaded() {
    final failure = _resolve();
    if (failure != null) return failure;
    return _attempt ?? _start(ReadReason.initial);
  }

  /// Refreshes one first page, superseding a pending append.
  Future<List<T>> refresh() {
    final failure = _resolve();
    if (failure != null) return failure;
    final active = _active;
    if (active != null) {
      if (active.request.reason != ReadReason.append) return active.future;
      return _start(ReadReason.refresh, superseded: active);
    }
    return _start(ReadReason.refresh);
  }

  /// Appends a page, sharing a pending append and treating the end as success.
  Future<List<T>> loadMore() {
    try {
      _control.check();
    } on Object catch (error, stackTrace) {
      return Future<List<T>>.error(error, stackTrace);
    }
    // An append must not activate an otherwise unused resource.
    if (!_source.active) {
      return Future<List<T>>.error(
        const ResourceException(ResourceReason.notReady),
      );
    }
    final failure = _resolve();
    if (failure != null) return failure;
    final current = _state.peek();
    if (!current.hasLoaded) {
      // A synchronous source change may precede its native effect delivery.
      if (_attempt == null) _start(ReadReason.initial).ignore();
      return Future<List<T>>.error(
        const ResourceException(ResourceReason.notReady),
      );
    }
    final active = _active;
    if (active != null) {
      if (active.request.reason == ReadReason.append) return active.future;
      return Future<List<T>>.error(
        const ResourceException(ResourceReason.busy),
      );
    }
    if (_cursor == null) {
      return Future<List<T>>.value(List<T>.unmodifiable([]));
    }
    return _start(ReadReason.append);
  }

  Future<List<T>>? _resolve() {
    try {
      _control.check();
      if (!_source.resolve()) {
        return Future<List<T>>.error(_source.error!, _source.stackTrace);
      }
      return null;
    } on Object catch (error, stackTrace) {
      return Future<List<T>>.error(error, stackTrace);
    }
  }

  Future<List<T>> _start(
    ReadReason reason, {
    _ReadOperation<List<T>>? superseded,
  }) {
    try {
      _control.check();
    } on Object catch (error, stackTrace) {
      return Future<List<T>>.error(error, stackTrace);
    }
    final operation = _ReadOperation<List<T>>(reason);
    final source = _source.value;
    final load = _load;
    final nextCursor = _nextCursor;
    final cursor = reason == ReadReason.append ? _cursor : null;
    final previous = _state.peek();
    _active = operation;
    if (reason != ReadReason.append) _attempt = operation.future;
    Zone.current.runGuarded(
      () => batch(() {
        _publish(
          _state,
          PagesState<S, T, C>._(
            hasSource: true,
            source: source,
            items: previous.items,
            hasLoaded: previous.hasLoaded,
            hasNext: previous.hasNext,
            phase: switch (reason) {
              ReadReason.initial => PagePhase.initial,
              ReadReason.refresh => PagePhase.refresh,
              ReadReason.append => PagePhase.append,
            },
            error: reason == ReadReason.append ? previous.error : null,
            stackTrace: reason == ReadReason.append
                ? previous.stackTrace
                : null,
          ),
        );
        // Cancellation callbacks see the replacement operation already installed.
        superseded?.invalidate(ResourceReason.superseded);
      }),
    );
    scheduleMicrotask(() {
      if (!_isCurrent(operation)) return;
      try {
        _control.check();
      } on Object {
        _invalidate(ResourceReason.disposed);
        return;
      }
      if (!_isCurrent(operation)) return;
      Future<List<T>>.sync(
        () => untracked(() => load(source, cursor, operation.request)),
      ).then<void>(
        (page) => _settle(operation, source, cursor, nextCursor, result: page),
        onError: (Object error, StackTrace stackTrace) => _settle(
          operation,
          source,
          cursor,
          nextCursor,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    });
    return operation.future;
  }

  bool _isCurrent(_ReadOperation<List<T>> operation) =>
      !_control.closed && identical(_active, operation) && !operation.finished;

  bool _resolveCurrent(_ReadOperation<List<T>> operation) {
    try {
      _source.resolve();
    } on Object catch (failure, trace) {
      if (_isCurrent(operation)) {
        _active = null;
        operation.failSource(failure, trace);
      }
      return false;
    }
    if (_isCurrent(operation)) return true;
    if (!_control.closed &&
        !_source.paused &&
        _source.hasValue &&
        _attempt == null) {
      _start(ReadReason.initial).ignore();
    }
    return false;
  }

  void _settle(
    _ReadOperation<List<T>> operation,
    S source,
    C? cursor,
    C? Function(S, List<T>) nextCursor, {
    List<T>? result,
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      if (!_isCurrent(operation)) return;
      try {
        _control.check();
      } on Object {
        _invalidate(ResourceReason.disposed);
        return;
      }
      if (!_isCurrent(operation)) return;
      if (!_resolveCurrent(operation)) return;
      List<T>? page;
      C? next;
      if (error == null) {
        try {
          page = List<T>.unmodifiable(result!);
          next = untracked(() => nextCursor(source, page!));
          if (next != null && (page.isEmpty || next == cursor)) {
            throw StateError('The page cursor did not advance.');
          }
        } on Object catch (failure, trace) {
          error = failure;
          stackTrace = trace;
        }
        if (!_isCurrent(operation) || !_resolveCurrent(operation)) return;
      }
      if (!_isCurrent(operation)) return;
      _active = null;
      final previous = _state.peek();
      final append = operation.request.reason == ReadReason.append;
      if (error == null) {
        final loaded = page!;
        _cursor = next;
        _publish(
          _state,
          PagesState<S, T, C>._(
            hasSource: true,
            source: source,
            items: append
                ? List<T>.unmodifiable([...previous.items, ...loaded])
                : loaded,
            hasLoaded: true,
            hasNext: next != null,
            error: append ? previous.error : null,
            stackTrace: append ? previous.stackTrace : null,
          ),
        );
        operation.complete(loaded);
      } else {
        _publish(
          _state,
          PagesState<S, T, C>._(
            hasSource: true,
            source: source,
            items: previous.items,
            hasLoaded: previous.hasLoaded,
            hasNext: previous.hasNext,
            error: append ? previous.error : error,
            stackTrace: append ? previous.stackTrace : stackTrace,
            nextError: append ? error : previous.nextError,
            nextStackTrace: append ? stackTrace : previous.nextStackTrace,
          ),
        );
        operation.completeError(error, stackTrace!);
      }
    } finally {
      operation.finish();
    }
  }

  void _invalidate(ResourceReason reason) {
    final operation = _active;
    _active = null;
    operation?.invalidate(reason);
  }

  void _sourceChanged(bool automatic) {
    final epoch = ++_epoch;
    final source = _source.value;
    final previous = _active;
    _active = null;
    _attempt = null;
    _cursor = null;
    Zone.current.runGuarded(
      () => batch(() {
        _publish(
          _state,
          PagesState<S, T, C>._(
            hasSource: true,
            source: source,
            items: List<T>.unmodifiable([]),
          ),
        );
        previous?.invalidate(ResourceReason.sourceChanged);
      }),
    );
    if (automatic &&
        epoch == _epoch &&
        !_control.closed &&
        !_source.paused &&
        _source.hasValue &&
        _active == null &&
        _attempt == null) {
      _start(ReadReason.initial).ignore();
    }
  }

  void _sourceFailed(Object error, StackTrace stackTrace) {
    _epoch++;
    final operation = _active;
    _active = null;
    _attempt = null;
    _cursor = null;
    Zone.current.runGuarded(
      () => batch(() {
        _publish(
          _state,
          PagesState<S, T, C>._(
            items: List<T>.unmodifiable([]),
            error: error,
            stackTrace: stackTrace,
          ),
        );
        operation?.failSource(error, stackTrace);
      }),
    );
  }

  void dispose() {
    if (_control.closed) return;
    _control.close();
    _invalidate(ResourceReason.disposed);
    _source.dispose();
  }
}

/// Internal configuration hook for the owning Flutter adapter.
void updatePages<S, T, C extends Object>(
  Pages<S, T, C> pages, {
  required S Function() source,
  required FutureOr<List<T>> Function(S, C?, ReadRequest) load,
  required C? Function(S, List<T>) nextCursor,
}) {
  pages._load = load;
  pages._nextCursor = nextCursor;
  pages._source.replace(source);
}
