[![Oref testing](https://github.com/medz/oref/actions/workflows/test.yml/badge.svg)](https://github.com/medz/oref/actions/workflows/test.yml)
[![Oref version](https://img.shields.io/pub/v/oref)](https://pub.dev/packages/oref)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/medz/oref)

# Oref

A high-performance Flutter state management tool built with [`alien_signals`](https://github.com/medz/alien-signals-dart), Oref is one of the fastest Flutter signals and state management solutions.

## Overview

Much of the pain in state management in Dart & Flutter comes from reacting to changes in given values, because the values themselves are not directly observable. We have to use `StatefulWidget` or other state management tools for state, which use inefficient proactive notifications or a large number of watchers to notify widgets to rebuild, and the boilerplate code is very redundant.

The release of `alien_signals` completely changed Flutter's inefficient state management situation, but Flutter state libraries still require a lot of boilerplate code! Oref completely changes this situation. In Flutter, when a Widget accesses a signal value, if that signal's value changes, the Widget is automatically rebuilt.

```dart
class Counter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = signal(context, 0);
    void increment() => count(count() + 1);

    return Column(children: [
      Text('Count: ${count()}'),
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
  oref: any
```

Or install by running this command:
```bash
flutter pub add oref
```

## Documentation

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/medz/oref)

You can view details through the [API Reference in pub.dev](https://pub.dev/documentation/oref/latest/oref/) or source code comments.

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
