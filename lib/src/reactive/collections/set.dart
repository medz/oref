import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../../core/memoized.dart';
import '../reactive.dart';

class ReactiveSet<T> extends SetBase<T>
    with Reactive<ReactiveSet<T>>
    implements Set<T> {
  ReactiveSet._(this._source);

  ReactiveSet.global(Iterable<T> elements) : this._(Set.from(elements));

  factory ReactiveSet(BuildContext context, Iterable<T> elements) {
    return useMemoized(context, () => ReactiveSet.global(elements));
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
