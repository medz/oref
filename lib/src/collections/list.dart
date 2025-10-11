import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

/// A reactive [List] implementation.
class ReactiveList<T> extends ListBase<T>
    with Reactive<ReactiveList<T>>
    implements List<T> {
  ReactiveList._(this._source);

  /// Create a new [ReactiveList] instance.
  ReactiveList(Iterable<T> elements) : this._(List.from(elements));

  /// Created a widget scoped [ReactiveList] instance.
  factory ReactiveList.scoped(BuildContext context, Iterable<T> elements) {
    return useMemoized(context, () => ReactiveList(elements));
  }

  final List<T> _source;

  @override
  int get length {
    track();
    return _source.length;
  }

  @override
  set length(value) {
    _source.length = value;
    trigger();
  }

  @override
  T operator [](int index) {
    track();
    return _source[index];
  }

  @override
  void operator []=(int index, T value) {
    _source[index] = value;
    trigger();
  }

  @override
  void add(T element) {
    /// Bug - `ListBase.add`: This implementation only works for lists which allow `null` as element.
    ///
    /// So we directly operate on the source.
    _source.add(element);
    trigger();
  }

  @override
  void addAll(Iterable<T> iterable) {
    _source.addAll(iterable);
    trigger();
  }

  @override
  void insert(int index, T element) {
    _source.insert(index, element);
    trigger();
  }

  @override
  bool remove(Object? value) {
    final result = _source.remove(value);
    trigger();
    return result;
  }

  @override
  T removeAt(int index) {
    final result = _source.removeAt(index);
    trigger();
    return result;
  }

  @override
  void clear() {
    _source.clear();
    trigger();
  }
}
