[![Oref testing](https://github.com/medz/oref/actions/workflows/test.yml/badge.svg)](https://github.com/medz/oref/actions/workflows/test.yml)
[![Oref version](https://img.shields.io/pub/v/oref)](https://pub.dev/packages/oref)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

# Oref

A high-performance Flutter state management tool built with [`alien_signals`](https://github.com/medz/alien-signals-dart), Oref is one of the fastest Flutter signals and state management solutions<sup>the other being [Solidart](https://github.com/nank1ro/solidart)</sup>.

## Overview

Much of the pain in state management in Dart & Flutter comes from reacting to changes in given values, because the values themselves are not directly observable. We have to use `StatefulWidget` or other state management tools for state, which use inefficient proactive notifications or a large number of watchers to notify widgets to rebuild, and the boilerplate code is very redundant.

Fortunately, there were later pioneers like `signals` built by [Rody Davis](https://github.com/rodydavis) and `Solidart` by [Alexandru Mariuti](https://github.com/nank1ro) who first brought signals to Flutter. However, they also faced a problem: requiring developers to abandon `StatelessWidget` and adopt their specific base classes or watchers.

The release of `alien_signals` completely changed Flutter's inefficient state management situation, but Flutter state libraries still require a lot of boilerplate code! Oref completely changes this situation. In Flutter, when a Widget accesses a signal value, if that signal's value changes, the Widget is automatically rebuilt.

```dart
class Counter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);
    void increment() => count(count() + 1);

    return Column(children: [
      Text('Count: ${context.watch(count)}'),
      TextButton(
        onPressed: increment,
        child: Text('click me'),
      )
    ]);
  }
}
```

Signals are magically injected into the BuildContext to provide optimal performance and ergonomic design. In the example above, we access `count()` to get the current value of the signal and complete the responsive binding with the current `Counter`. When the count value is updated, it automatically notifies the Counter to rebuild.

## Installation

You can install by editing your `pubspec.yaml` file:
```yaml
dependencies:
  oref: latest
```

Or install by running this command:
```bash
flutter pub add oref
```

## Example

Let's use signals in a real-world scenario. We'll build a todo list application where you can add and remove items from the todo list. We'll start by modeling the state. We first need a signal containing a list of todos, which we can represent with an "array":

```dart
import "package:oref/oref.dart";

final todos = createGlobalSignal([
  "Buy groceries",
  "Walk the dog"
]);
```

To allow users to enter text for new todos, we also need a signal that indicates we'll soon connect to a form element. Now, we can already use this signal to create a function that adds todos to our list.

```dart
({
  TextEditingController controller,
  void Function() insert
}) useTodo(BuildContext context) {
  final controller = useComputed(context, (_) => TextEditingController());

  void insert() {
    todos([...todos(), controller.text]);
    controller.clear();
  }

  return (controller: untrack(controller), insert: insert);
}
```

> [!TIP]
> A signal only updates when you assign a new value to it. If the value you assign to a signal equals its current value, it won't update.
> ```dart
> final count = useSignal(context, 0);
> count(0); // Nothing happens - the value is already 0
> count(1); // Updates - the value is different
> ```

The last feature we want to add is the ability to remove todos from the list. For this, we'll add a function to remove a given todo from the todos array:

```dart
void removeTodo(String todo) {
  todos(todos.where((e) => e != todo));
}
```

### Building UI

Now that we've modeled the application's state, it's time to connect a beautiful UI that users can interact with.

```dart
class TodosWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final todo = useTodo(context);
    return Column(
      children: [
        TextFormField(controller: todo.controller),
        TextButton(onPressed: todo.insert, child: const Text("Add")),
        for (final item in todos())
        ListTile(
          title: Text(item),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => removeTodo(item),
          ),
        );
      ],
    );
  }
}
```

And there we have it - a fully functional todo application!

## Documentation

> TODO

Oref doesn't have a dedicated documentation website, but you can view details through the [API Reference in pub.dev](https://pub.dev/documentation/oref/latest/oref/) or source code comments.

## Sponsors

Oref is an [MIT licensed](https://github.com/medz/spry/blob/main/LICENSE) open source project with its ongoing development made possible entirely by the support of these awesome backers. If you'd like to join them, please consider [sponsoring Seven(@medz)](https://github.com/sponsors/medz) development.

<p align="center">
  <a target="_blank" href="https://github.com/sponsors/medz">
    <img alt="sponsors" src="https://cdn.jsdelivr.net/gh/medz/public/sponsors.tiers.svg">
  </a>
</p>

## Contributing

Thank you to all the people who already contributed to Oref!

[![Contributors](https://contrib.rocks/image?repo=medz/oref)](https://github.com/medz/oref/graphs/contributors)
