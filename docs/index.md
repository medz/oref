---
layout: home
hero:
  name: Oref
  text: Signals for Flutter, without the ceremony
  tagline: Lightweight reactive primitives that rebuild only what matters.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: Core Concepts
      link: /guide/core-concepts
features:
  - title: Signal-first API
    details: "Create reactive values with `signal()` and update via `.set(...)`."
  - title: Computed + effects
    details: "Derive values with `computed()` and react with `effect()`."
  - title: Async data built-in
    details: "`useAsyncData()` handles loading, success, and error states."
  - title: Collections helpers
    details: "Reactive List/Map/Set wrappers for complex UI state."
---

<p class="section-kicker">Why Oref</p>

<div class="section-grid">
  <div class="section-card">
    <h3>Predictable reactivity</h3>
    <p>Reads track dependencies, writes notify subscribers. Nothing hidden.</p>
  </div>
  <div class="section-card">
    <h3>Widget-first ergonomics</h3>
    <p>Signals live with widgets. Use <code>SignalBuilder</code> to scope rebuilds.</p>
  </div>
  <div class="section-card">
    <h3>Composable primitives</h3>
    <p>Signals, computed values, effects, and batching compose cleanly.</p>
  </div>
</div>

## 3-Step Quick Start

### 1. Install

```bash
flutter pub add oref
```

### 2. Create a signal

```dart
final count = signal(context, 0);
```

### 3. Derive and update

```dart
final doubled = computed(context, (_) => count() * 2);
count.set(count() + 1);
```

<div class="callout">
  <strong>Need recipes?</strong>
  <p>Check the guides for patterns like async data, batching, and collections.</p>
</div>

## Recipes to Explore

<div class="section-grid">
  <div class="section-card">
    <h3>Form state</h3>
    <p>Keep input state and validation derived from signals.</p>
  </div>
  <div class="section-card">
    <h3>List filtering</h3>
    <p>Use computed values to derive filtered views from large lists.</p>
  </div>
  <div class="section-card">
    <h3>Async loading</h3>
    <p>Handle loading and errors with <code>useAsyncData()</code>.</p>
  </div>
</div>

Ready to dive in? Start with **Getting Started**.
