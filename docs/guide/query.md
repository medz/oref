# Query

Query loads one value for an immutable input. In a widget, use QueryBuilder.create
to create, start, and dispose the local instance. The following fragment assumes
`articleId` is the current widget parameter and imports Material plus
`package:oref/flutter.dart`.

```dart
QueryBuilder<int, String>.create(
  source: () => articleId,
  load: (id, request) async => 'Article $id',
  builder: (context, state, query) => Column(
    children: [
      if (state.pending) const LinearProgressIndicator(),
      if (state.hasValue) Text(state.value),
      if (state.error != null) Text('${state.error}'),
      TextButton(
        onPressed: () => query.refresh().ignore(),
        child: const Text('Refresh'),
      ),
    ],
  ),
)
```

## Inputs and callbacks

source is synchronous. Only Readable reads inside it establish input dependencies.
It should assemble inexpensive values or immutable records; loader reads do not
become inputs. Inputs use Dart `==`, so include every parameter that changes the
result. Replacing a widget's callbacks installs the latest configuration; equal
input does not automatically refetch. Started operations retain their original
input and loader.

Changing the input clears the previous input's value, invalidates its read, and
loads the new input after activation. A normal widget Key is not a request key.
Source errors expose error/stackTrace and clear old display; subsequent valid
inputs can recover.

## Attempts and snapshots

| Member | Meaning |
| --- | --- |
| hasSource / source | A valid resolved input, including nullable input. |
| hasValue / value | A loaded result, including a valid null result. |
| pending | A read is in progress. |
| error / stackTrace | The current read or source failure. |

Reading source/value without the corresponding has flag throws StateError.
Snapshots are immutable and can safely be captured by lazy list closures.

ensureLoaded returns the current read Future or the last attempt, including a
failure. It does not retry failed loads on subscription. refresh starts a new
attempt when no read is pending; repeated pending reads reuse the same Future.
Same-input refresh preserves existing data and keeps it if refresh fails.

## External ownership

A manually constructed Query needs an explicit ensureLoaded/refresh call and
creator-owned disposal. QueryBuilder.value only observes it. Use
QueryBuilder.shared with a stable [Family](./sharing.md) to share it across routes.
For model field writes, use [field or fieldAck](./remote-value.md).
