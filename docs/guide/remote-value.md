# RemoteValue and writable fields

RemoteValue is a remote value that can be read and replaced optimistically.
It displays desired immediately, rejects competing writes, and restores the
previous value if saving fails. Use this for settings, toggles, and model fields.

## Independent value

```dart
import 'package:oref/oref.dart';

Future<void> main() async {
  var stored = false; // In-memory server for this example.
  final newsletter = RemoteValue<String, bool>.ack(
    source: () => 'newsletter',
    read: (key, request) async => stored,
    write: (key, desired) async { stored = desired; },
  );
  try {
    await newsletter.ensureLoaded();
    await newsletter.update((current) => !current);
    print(newsletter.state.value.value); // true
  } finally {
    newsletter.dispose();
  }
}
```

The standard constructor's writer returns a canonical server value. The ack
constructor accepts desired after a write that only acknowledges success.
There is no automatic post-write GET or automatic write retry.

An independent value requires a reliable current value for set/update; neither
operation silently loads it. If unknown, explicitly await ensureLoaded or refresh
before writing. set expresses a desired value; update calculates it from current. A matching Seed supplies initial data once; it cannot
be replayed by rebuilds or later source changes. accept can deliver later
source-tagged authoritative data when neither read nor write is busy.

An independent resource may use identity(source) to keep its value across
transport-token changes. Identity changes clear old value/seed eligibility while
accepted writes retain their lock and original parameters until settlement.

## A field of a Query model

Define the parent and projection once:

```dart
class Item {
  const Item(this.id, this.followed);
  final int id;
  final bool followed;
}

final serverFollowed = <int, bool>{};
final item = Family<int, Query<int, Item>>(
  create: (id) => Query(
    source: () => id,
    load: (id, request) async => Item(id, serverFollowed[id] ?? false),
  ),
  dispose: (query) => query.dispose(),
);
final followed = item.fieldAck<bool>(
  select: (item) => item.followed,
  apply: (item, desired) => Item(item.id, desired),
  write: (id, desired) async { serverFollowed[id] = desired; },
);
```

Place a ResourceScope above the Navigator, then use the field reference:

```dart
RemoteValueBuilder<int, bool>.shared(
  ref: followed(42),
  builder: (context, state, remote) => IconButton(
    onPressed: !state.hasValue || state.pending
        ? null
        : () => remote.update((current) => !current).ignore(),
    icon: Icon(
      state.hasValue && state.value ? Icons.star : Icons.star_outline,
    ),
    tooltip: state.error?.toString(),
  ),
)
```

Query owns the single full model. select reads a field; apply returns a new model
changing only that field. Its select/apply round trip must preserve the requested
field value. field returns a canonical writer; fieldAck uses an acknowledgment.
The field view shares the parent's source, GET, write lock, and directory entry.
It creates no second input subscription, field TTL, or initial seed.

An accepted field write invalidates an old GET. Reads and writes of sibling fields
are busy while the parent write is pending. Optimism, success, and rollback update
the parent model and all affected views together. A token change in the parent's
complete source clears the model and requires another read; fields do not have
independent identity preservation.

Unknown projections can fail without invalidating the loaded parent model.
A field set can supply an explicit desired value while its projection is unknown,
provided the parent model is loaded; update requires a known projected value. A
field's explicit dispose closes that view; it does not free an active parent
write lock. Parent disposal closes its views. See the complete two-route follow
example in the source checkout for sharing, failures, and account switching.
