import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../../core/memoized.dart';
import '../reactive.dart';

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
}
