import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

import '../core/_element_disposer.dart';
import '../devtools/devtools.dart';

/// A reactive set that tracks changes to its elements.
class ReactiveSet<T> extends SetBase<T>
    with Reactive<ReactiveSet<T>>
    implements Set<T> {
  /// Creates a new reactive set with the given elements.
  ReactiveSet(Iterable<T> elements) : _source = Set.from(elements) {
    OrefDevTools.registerCollection(this, type: 'Set');
  }

  /// Creates a new reactive set with the given elements, scoped to the given context.
  factory ReactiveSet.scoped(BuildContext context, Iterable<T> elements) {
    final set = useMemoized(context, () => ReactiveSet(elements));
    OrefDevTools.registerCollection(set, context: context, type: 'Set');
    if (!set._devtoolsDisposerRegistered) {
      registerElementDisposer(
        context,
        () => OrefDevTools.markCollectionDisposed(set),
      );
      set._devtoolsDisposerRegistered = true;
    }
    return set;
  }

  final Set<T> _source;
  bool _devtoolsDisposerRegistered = false;

  @override
  Iterator<T> get iterator {
    track();
    return _source.iterator;
  }

  @override
  int get length {
    track();
    return _source.length;
  }

  @override
  bool add(T value) {
    final result = _source.add(value);
    trigger();
    if (result) {
      OrefDevTools.recordCollectionMutation(
        this,
        operation: 'Add',
        deltas: [OrefCollectionDelta(kind: 'add', label: value.toString())],
      );
    }

    return result;
  }

  @override
  bool contains(Object? element) {
    track();
    return _source.contains(element);
  }

  @override
  T? lookup(Object? element) {
    track();
    return _source.lookup(element);
  }

  @override
  bool remove(Object? value) {
    final result = _source.remove(value);
    trigger();
    if (result) {
      OrefDevTools.recordCollectionMutation(
        this,
        operation: 'Remove',
        deltas: [OrefCollectionDelta(kind: 'remove', label: value.toString())],
      );
    }

    return result;
  }

  @override
  Set<T> toSet() {
    track();
    return _source.toSet();
  }

  @override
  void addAll(Iterable<T> elements) {
    for (final element in elements) {
      _source.add(element);
    }
    trigger();
    final preview = elements.take(3).map((item) => item.toString()).toList();
    final deltaLabel = preview.isEmpty ? 'items' : preview.join(', ');
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Add',
      deltas: [OrefCollectionDelta(kind: 'add', label: deltaLabel)],
      note: elements.length > preview.length
          ? 'Added ${elements.length} items'
          : null,
    );
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    for (final element in elements) {
      _source.remove(element);
    }
    trigger();
    final preview = elements.take(3).map((item) => item.toString()).toList();
    final deltaLabel = preview.isEmpty ? 'items' : preview.join(', ');
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Remove',
      deltas: [OrefCollectionDelta(kind: 'remove', label: deltaLabel)],
      note: elements.length > preview.length
          ? 'Removed ${elements.length} items'
          : null,
    );
  }

  @override
  void clear() {
    _source.clear();
    trigger();
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Clear',
      deltas: const [OrefCollectionDelta(kind: 'remove', label: 'all items')],
    );
  }
}
