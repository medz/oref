# Action

Action represents an explicit operation such as submitting a form or uploading a
file. It starts only when run(arguments) is called. Constructing a resource,
mounting an ActionBuilder, or subscribing to state never executes it.

With Material, import `package:flutter/material.dart` with `hide Action` and use
`package:oref/flutter.dart` for Oref's types.

```dart
ActionBuilder<String, String>.create(
  execute: (name) async => 'Saved $name',
  builder: (context, state, action) => Column(
    children: [
      FilledButton(
        onPressed: state.pending ? null : () => action.run('Ada').ignore(),
        child: Text(state.pending ? 'Saving…' : 'Save'),
      ),
      if (state.hasValue) Text(state.value),
      if (state.error != null) Text('${state.error}'),
    ],
  ),
)
```

An accepted operation captures its immutable arguments. Include account identity,
token, and other required values in that snapshot. A closure that reads global
authentication after await does not preserve the original session automatically.

One instance accepts at most one write. A competing run returns a Future error
with ResourceReason.busy, without executing, merging, or queuing another write.
A new run clears the previous value/error, sets pending, and then publishes a
result or the original business error. hasValue distinguishes a successful null
result from a run that has no result.

For navigation or other continuation, await run and handle errors normally; after
await, check the relevant widget/session lifetime before showing UI. The example
uses ignore because its builder displays the error.

Disposal forbids new operations and state publication. An already accepted write
continues and settles its original Future; Oref does not undo a server effect.
Sharing an Action uses the same [directory rules](./sharing.md).
For optimistic state replacement, use [RemoteValue](./remote-value.md).
