import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../../core/memoized.dart';
import '../reactive.dart';

class ReactiveMap<K, V> extends MapBase<K, V>
    with Reactive<ReactiveMap<K, V>>
    implements Map<K, V> {
  ReactiveMap.global(Map<K, V> source) : _source = source;

  factory ReactiveMap(BuildContext context, Map<K, V> source) {
    return useMemoized(context, () => ReactiveMap.global(source));
  }

  final Map<K, V> _source;

  @override
  Iterable<K> get keys {
    track();
    return _source.keys;
  }

  @override
  V? operator [](Object? key) {
    track();
    return _source[key];
  }

  @override
  void operator []=(K key, V value) {
    _source[key] = value;
    trigger();
  }

  @override
  void clear() {
    _source.clear();
    trigger();
  }

  @override
  V? remove(Object? key) {
    final result = _source.remove(key);
    trigger();
    return result;
  }
}
