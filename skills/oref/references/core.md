# Values and Flutter

```dart
final count = Value(0);
final doubled = Computed(() => count.value * 2);
count.value++;
final snapshot = doubled.peek();
```

Value uses one native signal; Computed is lazy and tracks its own synchronous
reads. peek avoids subscribing its caller. Replace collections with immutable
instances; writes use identity comparison. batch groups synchronous writes and
does not extend across await.

subscribe returns a Subscription and does not call the listener at registration.
Dispose it at its creator's lifecycle boundary. Listener reads do not become new
dependencies. Value and Computed have no public disposal requirement.

```dart
StateBuilder<Value<int>>(
  create: () => Value(0),
  builder: (context, count) => TextButton(
    onPressed: () => count.value++,
    child: Text('${count.value}'),
  ),
)
```

StateBuilder.builder tracks Readable reads. Creation happens once per
Element/identity; create/update/dispose run untracked. update applies ordinary
widget parameters to the same object. Identity changes detach observation and
call the old captured disposer before creating the new object. value borrows;
Watch observes existing state.

Show actual cleanup for timers, controllers, resources, and subscriptions,
including removing controller listeners. Controller.text is not a Readable;
use native Flutter listeners or ValueListenableBuilder.

Lazy list closures should capture the immutable state supplied by the resource
builder. Their later reads happen outside the builder's tracking scope. A
resource notification may rebuild its whole builder; use stable child widgets
or explicit observation boundaries when real UI cost requires it.
