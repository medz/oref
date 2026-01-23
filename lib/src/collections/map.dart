import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

import '../core/_element_disposer.dart';
import '../devtools/devtools.dart';

/// A reactive map that tracks changes to its source map.
class ReactiveMap<K, V> extends MapBase<K, V>
    with Reactive<ReactiveMap<K, V>>
    implements Map<K, V> {
  /// Creates a new [ReactiveMap]
  ReactiveMap(Map<K, V> source) : _source = source {
    OrefDevTools.registerCollection(this, type: 'Map');
  }

  /// Creates a widget scoped [ReactiveMap].
  factory ReactiveMap.scoped(BuildContext context, Map<K, V> source) {
    final map = useMemoized(context, () => ReactiveMap(source));
    OrefDevTools.registerCollection(map, context: context, type: 'Map');
    if (!map._devtoolsDisposerRegistered) {
      registerElementDisposer(
        context,
        () => OrefDevTools.markCollectionDisposed(map),
      );
      map._devtoolsDisposerRegistered = true;
    }
    return map;
  }

  final Map<K, V> _source;
  bool _devtoolsDisposerRegistered = false;

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
    final exists = _source.containsKey(key);
    final previous = _source[key];
    _source[key] = value;
    trigger();
    OrefDevTools.recordCollectionMutation(
      this,
      operation: exists ? 'Replace' : 'Add',
      deltas: [
        OrefCollectionDelta(
          kind: exists ? 'update' : 'add',
          label: exists
              ? '$key: ${previous ?? 'null'} -> $value'
              : '$key: $value',
        ),
      ],
    );
  }

  @override
  void clear() {
    _source.clear();
    trigger();
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Clear',
      deltas: const [OrefCollectionDelta(kind: 'remove', label: 'all entries')],
    );
  }

  @override
  V? remove(Object? key) {
    final existed = _source.containsKey(key);
    final result = _source.remove(key);
    trigger();
    if (existed) {
      OrefDevTools.recordCollectionMutation(
        this,
        operation: 'Remove',
        deltas: [OrefCollectionDelta(kind: 'remove', label: '$key')],
      );
    }
    return result;
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    bool shouldTrigger = false;
    final result = _source.putIfAbsent(key, () {
      shouldTrigger = true;
      return ifAbsent();
    });

    if (shouldTrigger) {
      trigger();
      OrefDevTools.recordCollectionMutation(
        this,
        operation: 'Add',
        deltas: [OrefCollectionDelta(kind: 'add', label: '$key: $result')],
      );
    }
    track();
    return result;
  }
}
