import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

/// A reactive map that tracks changes to its source map.
class ReactiveMap<K, V> extends MapBase<K, V>
    with Reactive<ReactiveMap<K, V>>
    implements Map<K, V> {
  /// Creates a new [ReactiveMap]
  ReactiveMap(Map<K, V> source) : _source = source;

  /// Creates a widget scoped [ReactiveMap].
  factory ReactiveMap.scoped(BuildContext context, Map<K, V> source) {
    return useMemoized(context, () => ReactiveMap(source));
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

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    track();
    if (!_source.containsKey(key)) {
      final value = ifAbsent();
      _source[key] = value;
      trigger();
      return value;
    }
    trigger();
    return _source[key] as V;
  }
}
