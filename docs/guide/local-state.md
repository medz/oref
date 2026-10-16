# Local state

Value stores synchronous state. Computed lazily derives another value and tracks
its own dependencies. Read `.value` inside Watch or StateBuilder.builder to
observe it; use `.peek()` to read without subscribing the caller.

```dart
import 'package:oref/oref.dart';

void main() {
  final price = Value(12);
  final quantity = Value(2);
  final total = Computed(() => price.value * quantity.value);
  final subscription = total.subscribe(() => print(total.peek()));
  try {
    batch(() {
      price.value = 15;
      quantity.value = 3;
    });
    print(total.value); // 45
  } finally {
    subscription.dispose();
  }
}
```

## Collections and equality

Changes use the underlying kernel's identity comparison. Resource source inputs
separately use Dart `==`. Replace collections with a fresh immutable instance:

```dart
final ids = Value<List<int>>(const [1]);
ids.value = List<int>.unmodifiable([...ids.value, 2]);
```

Mutating the existing List or Map in place does not notify observers. Plain
formatting or a one-use length normally does not need another Computed.

## Subscriptions and batching

subscribe does not invoke the listener at registration. Its listener runs
untracked and exceptions go to the registration Zone. The creator owns the
returned Subscription and disposes it. Value and Computed have no public dispose
requirement; native controllers and external subscriptions do.

batch only wraps synchronous changes, ends even if its callback throws, and does
not provide rollback or include work after await. Computed dependencies are
dynamic; changing a branch replaces the previous branch's observed inputs.

## Flutter observation

Watch observes existing values. StateBuilder creates one local object, observes
its builder, and can explicitly update/dispose that object. It also accepts a
record of ordinary objects; it does not require a Store base class.
Read [Flutter lifecycle](./flutter.md) for identities, borrowed state, and native
controller integration.
