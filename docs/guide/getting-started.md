# Getting started

**These guides describe 3.0.0-dev.1, an unpublished development API.** The
published pub.dev package has a different API. Use a local checkout for evaluation;
configure a consuming project's path dependency to that checkout. Run
`flutter pub get` at the repository root before running examples.

Requires Dart 3.13+ and Flutter 3.47+.

## One package, two entrypoints

Use `package:oref/oref.dart` for business code and pure Dart resource tests. It
contains no Flutter imports. Use `package:oref/flutter.dart` for the same API plus
widgets. This package currently still requires the Flutter SDK to resolve.
When using Material and Oref's Action together, hide Flutter's Action or prefix
one of the imports.

## Local state

```dart
import 'package:flutter/material.dart' hide Action;
import 'package:oref/flutter.dart';

class Counter extends StatelessWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) => StateBuilder<Value<int>>(
    create: () => Value(0),
    builder: (context, count) => FilledButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    ),
  );
}
```

StateBuilder creates the Value once and observes reads inside its builder. A
normal parent rebuild does not recreate the Value. Use Watch for state that
already exists. See [local state](./local-state.md).

## Pick a resource

| Need | API |
| --- | --- |
| Load a result | [Query](./query.md) |
| Load pages | [Pages](./pages.md) |
| Submit a command | [Action](./action.md) |
| Change a remote value or model field | [RemoteValue](./remote-value.md) |
| Reuse the same instance across routes | [Family and Resources](./sharing.md) |

Resources are ordinary Dart objects; constructors do not start HTTP. Owning and
shared Flutter builders start reads after mounting. A value builder only borrows
an external resource. The complete runnable example is in
`example/lib/shared_follow.dart` in this source checkout.

Continue with [Flutter ownership](./flutter.md) and
[Future errors and cancellation](./errors.md).
