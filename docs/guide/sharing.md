# Sharing and sessions

Family defines how to create a resource for an immutable key. Define it once.
family(key) is a lazy ResourceRef; it creates no instance and sends no request.
Resources shares instances by namespace, Family identity, and key equality.
Different directories or Family objects are independent.

```dart
final article = Family<int, Query<int, String>>(
  create: (id) => Query(
    source: () => id,
    load: (id, request) async => 'Article $id',
  ),
  dispose: (query) => query.dispose(),
);

Widget app() => ResourceScope.create(
  create: () => Resources(
    namespace: () => null,
    maxIdle: 32,
    retain: const Duration(minutes: 2),
  ),
  child: MaterialApp(
    home: QueryBuilder<int, String>.shared(
      ref: article(42),
      builder: (context, state, query) => Scaffold(
        body: Center(child: Text(state.hasValue ? state.value : 'Loading…')),
      ),
    ),
  ),
);
```

The scope is above MaterialApp's Navigator, so additional routes can use the same
article reference and directory. Rebuilding with an equal ref keeps the instance
and subscription. The example's limits are application choices, not defaults.
maxIdle and retain are required and nonnegative; zero disables idle retention.

## Ownership and memory

ResourceScope.create owns and closes its directory. ResourceScope.value borrows
an external one, whose owner must close it. Resource builders borrow with shared;
value only observes a known external instance; create owns a local one.

Last-borrow release pauses automatic source observation and enters bounded idle
retention. TTL/LRU eviction closes the entry and invalidates reads. Active UI and
unfinished writes are outside maxIdle. One unfinished write pins its original
instance and lock, even if the UI leaves and reenters. It cannot create another
same-key instance to bypass pending.

## Session identity

```dart
typedef Session = ({Object identity, String token});
final session = Value<Session>((identity: Object(), token: 'demo-token'));

// A new login or logout creates a new identity, even for the same account.
session.value = (identity: Object(), token: 'another-demo-token');

// Token refresh within one session keeps its identity.
session.value = (identity: session.value.identity, token: 'refreshed-demo-token');
```

Use session.value.identity as the directory namespace. Keep token and request
parameters in each resource's source. Namespace changes automatically rebind
mounted shared builders, even when refs are equal. Old reads become invalid;
accepted writes finish using their captured inputs and cannot update the new UI.
An account ID alone cannot distinguish two logins by the same account.

## Outside widgets

resources.use(ref, callback) holds a borrow until the callback's Future settles,
and releases it in finally. Call use again after login navigation instead of
reusing a captured old-session object. Applications own and dispose manually
created directories. The runnable example demonstrates explicit external
ownership through ResourceScope.value.
