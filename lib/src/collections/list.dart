import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

import '../core/_element_disposer.dart';
import '../devtools/devtools.dart';
import '../devtools/protocol.dart';

/// A reactive [List] implementation.
class ReactiveList<T> extends ListBase<T>
    with Reactive<ReactiveList<T>>
    implements List<T> {
  /// Create a new [ReactiveList] instance.
  ReactiveList(Iterable<T> elements) : _source = List.from(elements) {
    registerCollection(this, type: 'List');
  }

  /// Created a widget scoped [ReactiveList] instance.
  factory ReactiveList.scoped(BuildContext context, Iterable<T> elements) {
    final list = useMemoized(context, () => ReactiveList(elements));
    registerCollection(list, context: context, type: 'List');
    if (!list._devtoolsDisposerRegistered) {
      registerElementDisposer(context, () => markCollectionDisposed(list));
      list._devtoolsDisposerRegistered = true;
    }
    return list;
  }

  final List<T> _source;
  bool _devtoolsDisposerRegistered = false;

  @override
  int get length {
    track();
    return _source.length;
  }

  @override
  set length(value) {
    _source.length = value;
    trigger();
    recordCollectionMutation(
      this,
      operation: 'Resize',
      deltas: [CollectionDelta(kind: 'update', label: 'length -> $value')],
    );
  }

  @override
  T operator [](int index) {
    track();
    return _source[index];
  }

  @override
  void operator []=(int index, T value) {
    final previous = index < _source.length ? _source[index] : null;
    _source[index] = value;
    trigger();
    recordCollectionMutation(
      this,
      operation: 'Replace',
      deltas: [
        CollectionDelta(
          kind: 'update',
          label: '[$index] ${previous ?? 'null'} -> $value',
        ),
      ],
    );
  }

  @override
  void add(T element) {
    /// Bug - `ListBase.add`: This implementation only works for lists which allow `null` as element.
    ///
    /// So we directly operate on the source.
    _source.add(element);
    trigger();
    recordCollectionMutation(
      this,
      operation: 'Add',
      deltas: [CollectionDelta(kind: 'add', label: element.toString())],
    );
  }

  @override
  void addAll(Iterable<T> iterable) {
    _source.addAll(iterable);
    trigger();
    final preview = iterable.take(3).map((item) => item.toString()).toList();
    final deltaLabel = preview.isEmpty ? 'items' : preview.join(', ');
    recordCollectionMutation(
      this,
      operation: 'Add',
      deltas: [CollectionDelta(kind: 'add', label: deltaLabel)],
      note: iterable.length > preview.length
          ? 'Added ${iterable.length} items'
          : null,
    );
  }

  @override
  void insert(int index, T element) {
    _source.insert(index, element);
    trigger();
    recordCollectionMutation(
      this,
      operation: 'Add',
      deltas: [CollectionDelta(kind: 'add', label: '[$index] $element')],
    );
  }

  @override
  bool remove(Object? element) {
    final result = _source.remove(element);
    trigger();
    if (result) {
      recordCollectionMutation(
        this,
        operation: 'Remove',
        deltas: [CollectionDelta(kind: 'remove', label: element.toString())],
      );
    }
    return result;
  }

  @override
  T removeAt(int index) {
    final result = _source.removeAt(index);
    trigger();
    recordCollectionMutation(
      this,
      operation: 'Remove',
      deltas: [CollectionDelta(kind: 'remove', label: '[$index] $result')],
    );
    return result;
  }

  @override
  void clear() {
    _source.clear();
    trigger();
    recordCollectionMutation(
      this,
      operation: 'Clear',
      deltas: const [CollectionDelta(kind: 'remove', label: 'all items')],
    );
  }
}
