# Futures, errors, and cancellation

Every asynchronous resource operation returns a native Future. Success contains
the business result; source/loader/writer/execute/update failures preserve their
original error object and stack trace. Explicit callers must await and catch,
register onError, or deliberately ignore the Future when UI renders state.error.
Automatic starts ignore their Future errors but keep error/stackTrace in state.

```dart
try {
  await remote.update((current) => !current);
} on ResourceException catch (error) {
  if (error.reason != ResourceReason.busy) rethrow;
  // A competing operation already owns this instance's write lock.
} catch (error, stackTrace) {
  // Report the original business failure to your application's error UI/log.
  print('$error\n$stackTrace');
}
```

| ResourceReason | Meaning |
| --- | --- |
| busy | Another write owns the resource or parent model lock. |
| disposed | The resource/directory no longer accepts work. |
| notReady | The required current value or first page is unknown. |
| noReader | Explicit refresh has no reader. |
| sourceChanged | The operation or delivered data belongs to an old source. |
| superseded | A newer read replaced this read. |

Control rejection produced by the current resource itself does not overwrite its
business error. An accepted writer can delegate to another resource; any error
that writer returns, including ResourceException, is its business failure and
triggers error publication and rollback where applicable. Ignore only
control reasons expected for the specific call. A caught resource error does not
mean transport has stopped. accept is synchronous and throws directly; operation
methods deliver synchronous callback failures through their Future.

## Physical request cancellation

ReadRequest exposes reason (initial, refresh, append), cancelled, and onCancel.
Register the HTTP client's request-specific abort function and dispose that
registration in finally. The following is an adapter fragment for a client with
startRequest/abort/result methods; connect those names to your real transport:

```dart
load: (source, request) async {
  final call = client.startRequest(source);
  final cancellation = request.onCancel(call.abort);
  try {
    return await call.result;
  } finally {
    cancellation.dispose();
  }
},
```

Late registration invokes immediately if already cancelled. Registrations and
cancellation are idempotent. Oref invalidates stale results even without transport
abort, but the physical HTTP request can still consume bandwidth.

## Lifetime and retry cost

Disposal rejects new work, invalidates reads, and prevents further publication.
Accepted writes still settle; do not retry a non-idempotent write automatically
after an ambiguous timeout. ensureLoaded caches failed attempts; refresh is the
explicit retry. Search debounce belongs before the source Value and needs its
Timer disposed by its owner. No automatic retry, polling, or focus refetch is
enabled by default.
