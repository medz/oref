# Flutter observation and ownership

Import `package:oref/flutter.dart` for core APIs and Flutter adapters together.
Watch observes Readable.value reads in its synchronous builder. StateBuilder
combines once-per-identity object creation and the same automatic observation.
Only Flutter's build executes the builder; signal propagation requests a rebuild.

## StateBuilder

create runs once per Element/identity. update applies new ordinary parameters to
the same object on widget updates. Identity change first detaches observations,
then disposes the old object and creates another. The disposer is captured at
creation, so a newer callback cannot release the old object with new parameters.
create/update/dispose execute untracked. StateBuilder.value borrows its object.

A normal Value or Computed needs no dispose callback. Resources, subscriptions,
timers, and native controllers require actual explicit cleanup.

## Resource builders

QueryBuilder, PagesBuilder, ActionBuilder, and RemoteValueBuilder receive
(context, immutableState, resource). Capture the immutable snapshot in lazy UI
closures; use the resource for actions.

| Constructor | Responsibility |
| --- | --- |
| create / RemoteValueBuilder.ack | Own, activate reads in a microtask, and dispose. |
| value | Observe only; never activate, reconfigure, or dispose. |
| shared | Borrow through ResourceScope, activate reads, and return the borrow. |

Actions never auto-run. Remote values activate even without a reader, establishing
source/seed state with zero HTTP. Owned builders replace their source and
execution callbacks on updates, then reevaluate input; equal source does not
repeat a read. initial data is consumed only once. Started work keeps its accepted
callbacks. Stop observation before disposal/returning the borrow.

Read InheritedWidget services in the page's build/didChangeDependencies and pass
them to the adapter as ordinary parameters. Async business callbacks receive no
BuildContext. Check context.mounted before UI continuation after await.

## Native controller integration

Controller properties are not Readable values. Use native listeners when
connecting them to business state; the following snippet shows all cleanup.
Import Material and Oref's Flutter entrypoint.

```dart
class NameEditor extends StatefulWidget {
  const NameEditor({super.key});

  @override
  State<NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<NameEditor> {
  final controller = TextEditingController();
  final name = Value('');

  @override
  void initState() {
    super.initState();
    controller.addListener(_sync);
  }

  void _sync() => name.value = controller.text;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(controller: controller),
      Watch(builder: (_) => Text('Entered: ${name.value}')),
    ],
  );

  @override
  void dispose() {
    controller.removeListener(_sync);
    controller.dispose();
    super.dispose();
  }
}
```

A resource snapshot notification may rebuild its whole builder, including pending
changes. Oref does not promise automatic field-level rebuild filtering. Use stable
child widgets and deliberate Watch boundaries where a measured UI needs them.
