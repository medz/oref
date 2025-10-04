import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

/// A reactive set that tracks changes to its elements.
class ReactiveSet<T> extends SetBase<T>
    with Reactive<ReactiveSet<T>>
    implements Set<T> {
  ReactiveSet._(this._source);

  /// Creates a new reactive set with the given elements.
  ReactiveSet(Iterable<T> elements) : this._(Set.from(elements));

  /// Creates a new reactive set with the given elements, scoped to the given context.
  factory ReactiveSet.scoped(BuildContext context, Iterable<T> elements) {
    return useMemoized(context, () => ReactiveSet(elements));
  }

  final Set<T> _source;

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

    return result;
  }

  @override
  Set<T> toSet() {
    track();
    return _source.toSet();
  }
}
