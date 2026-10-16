---
layout: home
hero:
  name: Oref 3
  text: Values and resources for Flutter
  tagline: Explicit inputs, shared instances, and clear ownership. Unpublished 3.0.0-dev.1 development API.
  actions:
    - theme: brand
      text: Get started
      link: /guide/getting-started
    - theme: alt
      text: Shared resources
      link: /guide/sharing
features:
  - title: Local values
    details: Value and Computed with automatic observation in Watch and StateBuilder.
  - title: Read and write resources
    details: Query, Pages, Action, and RemoteValue describe distinct execution protocols.
  - title: Writable model fields
    details: Share one Query model, optimistic updates, rollback, and a parent write lock.
  - title: Explicit lifetimes
    details: Own, borrow, or share through a bounded resource directory above Navigator.
---

## Development version

These pages describe **3.0.0-dev.1**, which has not been published. Use this source
checkout to evaluate the API; the current pub.dev package differs.

One package provides `oref.dart` for Dart state/resources and `flutter.dart` for
the same API plus widgets. The reactive foundation is alien_signals.

Start with [local state](/guide/local-state), load a [query](/guide/query), or read
about [ownership](/guide/flutter) and [session sharing](/guide/sharing).

The source checkout includes a complete two-route follow example with a fake
server, optimistic field changes, rollback, and account switching.
