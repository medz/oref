# Reactive core preview

This core-only development API follows [design issue #47](https://github.com/medz/oref/issues/47).
It replaces the old 2.x implementation with object-shaped primitives over
`alien_signals` 2.3.5. There is no compatibility layer. Flutter integration and
upper-level state APIs will be discussed after this core; they are not implemented
here. This development version has not been released.

## Values

```dart
import 'package:oref/oref.dart';

final count = Signal(0);
final doubled = Computed(() => count.value * 2);
Readable<int> readOnly = doubled;

count.value++;
print(readOnly.value); // 2
```

`Readable<T>` exposes a tracked `value` getter. `Signal<T>` also has a setter.
`Computed<T>` is lazy and caches through the upstream computed node. Conditional
reads change dependencies normally. There is no second value cache or graph.

Both signal and computed change detection use upstream `identical`, not `==` or
deep equality. Mutating the same List/Map and assigning it back does not notify
observers. Replace it with a new instance, or call `trigger` with a read of the
value after mutation. There is no custom `notify` API.

Use `Computed<T>.withPrevious((previous) => ...)` when the computation needs the
upstream previous-value argument. It receives the last successful value, or null
before the first successful computation. A successful null cannot be distinguished
from an initial null through this argument. Getter errors are cached and rethrown
until a tracked dependency changes; a retry keeps the last successful value.

Signals and computed values do not expose a new disposal protocol. Their dependency
and cache lifetimes remain upstream behavior; keeping a computed object can retain
its last value or error. Do not assume an unobserved computed has no cache or edges.

## Effects and cleanup

```dart
final logging = Effect((onCleanup) {
  print('Count: ${count.value}');
  onCleanup(() => print('End this run'));
}); // Runs immediately.

count.value = 1; // Cleans up the old run, then executes the next run.
logging.dispose();
```

An effect runs synchronously on construction and tracks reads performed during
its callback. It delegates reruns and nested ownership to `alien_signals`.

The Dart adapter collects synchronous `onCleanup` registrations into one upstream
cleanup function. Multiple registrations run in reverse order, so a later resource
is released first. This order is an adapter policy, not an extra upstream feature.
Registration after the effect callback returns throws `StateError`.

Upstream invokes the cleanup before a rerun and on disposal, outside tracking.
Nested effects and scopes are stopped before their parent's cleanup. Repeated
successful disposal does not invoke the same cleanup again. A thrown cleanup error
propagates and stops the remaining callbacks; the adapter does not catch, retry, or
continue them. Upstream disposal traversal can also be interrupted by such an error.
Callbacks should release their resources without throwing where possible.
Explicit `.dispose()` calls ignore recursive calls through the same handle while
it is already stopping. This small adapter guard prevents double traversal from
those recursive calls; it does not change automatic upstream parent disposal.
Do not recursively dispose an ancestor from cleanup invoked by upstream parent
traversal, which can still corrupt upstream links in 2.3.5.

A throwing initial effect callback follows the upstream factory: it propagates
and does not automatically roll back the partially created effect. Its constructor
cannot return a disposal handle on failure. A containing `ReactiveScope` gives the
caller a handle to dispose the owned work. Cleanup registrations made by a callback
that throws are not returned to upstream, so they are not installed. This applies
to failed reruns as well as initial failures. Disposing an effect during its own
active callback also does not guarantee cleanup registered by that unfinished run.
This preview
does not promise setup rollback or error isolation.

## Lifecycle scopes

```dart
final scope = ReactiveScope();
try {
  scope.run(() {
    Effect((onCleanup) {
      print(doubled.value);
    });
  });
  // Other synchronous setup may also be entered through scope.run(...).
} finally {
  scope.dispose();
}
```

Construction creates a real upstream `effectScope` in the current subscriber.
`run` temporarily enters that same scope, invokes its callback once, returns the
callback result, and restores the previous subscriber in `finally`. The scope does
not rerun because its callback read a signal. Synchronously created nested effects
and scopes follow upstream ownership and are disposed together.

`run` rejects an already disposed scope, including one stopped by its parent.
A callback error does not dispose the scope automatically: the previously created
scope handle remains available for explicit cleanup. If a scope is stopped while
`run` is still executing, the adapter drains children attached by the remaining
synchronous callback before returning. It does not abort callback code or prevent
those children's initial runs. This is a reusable-run adapter guard, not an
upstream guarantee. If both the callback and this final disposal throw, the final
disposal error takes precedence; the previous context is still restored.

Scopes capture their upstream ownership at construction. Entering a scope created
outside an effect captures direct reads in that scope, not in the calling effect.
Conversely, reads through a scope created inside an effect can invalidate the
owning parent. Repeated direct reads in a long-lived scope may accumulate upstream
links as propagation cycles advance; dispose the scope when finished. There is no
separate owner context, Zone-based ownership, or new reactive engine.

Keep computed getters free of side effects. In upstream 2.3.5, a computed getter
that disposes its observing parent during dirty checking can throw an internal
null-check error and alter a stopped scope's flags. This also reproduces with raw
`effectScope`; the adapter does not repair the graph or guarantee scope liveness
detection after that substrate failure. This usage guidance is not a new runtime
write prohibition. Avoid arbitrary cyclic or reentrant mutations during derived
computation.

## Synchronous boundaries

```dart
final answer = batch(() {
  count.value = 2;
  count.value = 3;
  return doubled.value;
});

final snapshot = untracked(() => doubled.value);
```

`batch` wraps upstream `startBatch` / `endBatch`. Nested batches flush when the
outermost synchronous batch ends, and reads inside a batch see current values.
The `finally` still ends the batch if the callback throws. It is not a rollback
transaction. A flush error can replace a callback error, following Dart `finally`
and upstream exception behavior; other queued effects are not guaranteed to run.

`untracked` temporarily clears the active subscriber and restores it in `finally`.
A computed read still tracks its own computation. In 2.3.5, tracking and nested
ownership use the same subscriber: effects or scopes created inside `untracked`
are detached from the caller and need their own disposal handles. It does not
preserve an independent owner.

All these boundaries are synchronous. Returning a Future does not keep a batch or
scope active while awaiting it. Reads and new effects after `await` are not tracked
or owned by the earlier callback. Register cleanup before returning and manage
asynchronous errors, cancellation, and later-created effects explicitly.

## Scope of this implementation

The object primitives interoperate with the same upstream runtime. This core does
not implement implicit Flutter widget tracking, hooks, async resources, mutable
collection wrappers, or developer tooling. Old 2.x APIs, examples, and related tests
have been removed and replaced with core documentation and semantic coverage.

There are no Query, Pages, RemoteValue, shared catalogs, resource builders, or
upper-level state-management protocols. No release or merge is included.

Implementation references:

- [alien_signals 2.3.5 surface](https://github.com/medz/alien-signals-dart/blob/2.3.5/lib/src/surface.dart)
- [alien_signals 2.3.5 preset](https://github.com/medz/alien-signals-dart/blob/2.3.5/lib/src/preset.dart)

## Preset-backed values and explicit triggering

`Signal` and `Computed` are factory interfaces backed directly by private
subclasses of the upstream `SignalNode` and `ComputedNode`. Each value is itself
a preset node, not a wrapper around a callable surface signal. Their public
interfaces retain `.value` and do not advertise mutable graph fields. As with
any Dart interface, a deliberate cast to upstream node types can still access
those fields; this is API encapsulation, not a security boundary.

The former concrete final value classes are now abstract interface classes with
factory constructors. Existing construction and reads/writes are unchanged.
They still cannot be extended outside the library; implementing their public
interfaces is now possible. An implementation of `Readable` or `Signal` alone
does not automatically acquire tracking: its getter must use the upstream graph.

```dart
final items = Signal(<String>[]);
final effect = Effect((_) => print(items.value.length));
items.value.add('new item');
trigger(() { items.value; });
effect.dispose();
```

`trigger` delegates to the upstream preset. It selects reactive values read in
its synchronous callback and notifies their observers, even when the same
object remains stored. It respects the surrounding batch and does not subscribe
the calling observer to those reads. Reading a computed selects that computed,
not all its transitive dependencies. Callback failure still triggers notification
in upstream's `finally`; a flushing error can replace the callback error. Do not
create effects or scopes in this temporary subscriber context, and do not expect
it to survive `await`.

A test-only coarse `ReactiveList` probe subclasses upstream `SignalNode`, uses
its tracked `get`, and triggers after mutation. It interoperates with Oref
computeds, effects, batching and scope disposal. This proves the extension path,
not a public collection API or fine-grained key/index tracking contract. No raw
node, graph mutation, queue or scheduling APIs are re-exported from Oref.

### Lifecycle migration boundary

`Effect` and `ReactiveScope` still use upstream surface factories for creation
and ownership attachment. Upstream 2.3.5 hides `hasChildEffect` from its public
preset entry point. Its factories both link a child and set this parent marker;
linking alone loses nested cleanup/disposal semantics. Direct initialization
would require a private import, a copied flag literal, or a new upstream public
attachment helper. Oref does none of those. A future upstream helper that links
an effect/scope to the current parent and marks child ownership could enable
that migration without duplicating ownership policy. All existing lifecycle
adapters and their documented error/reentrancy limits remain unchanged.
