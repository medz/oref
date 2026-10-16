---
layout: home
hero:
  name: Oref
  text: Object-shaped reactive primitives
  tagline: The core-only Oref 3 development API, built on alien_signals.
  actions:
    - theme: brand
      text: Core Guide
      link: /guide/reactive-core
    - theme: alt
      text: Design Record
      link: https://github.com/medz/oref/issues/47
features:
  - title: Values
    details: Readable, Signal, and Computed use ordinary Dart value accessors.
  - title: Effects
    details: Synchronous tracking with explicit cleanup registration and disposal.
  - title: Lifecycle scopes
    details: Group effects and nested scopes without adding another reactive engine.
  - title: Upstream semantics
    details: Keep alien_signals identity comparison, caching, propagation, and synchronous boundaries.
---

This is an unpublished development version. It replaces the old 2.x runtime;
there is no compatibility layer. Flutter integration and upper-level APIs will
be discussed after the core. Read the guide for exception, cleanup, and reentrancy
limitations before using this preview.
