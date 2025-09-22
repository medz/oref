import 'dart:collection';

import '../reactive.dart';

class ReactiveList<T> extends ListBase<T>
    with Reactive<ReactiveList<T>>
    implements List<T> {
  ReactiveList._(this._source);

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
