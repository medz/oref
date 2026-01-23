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
    OrefDevTools.registerCollection(this, type: 'List');
  }

  /// Created a widget scoped [ReactiveList] instance.
  factory ReactiveList.scoped(BuildContext context, Iterable<T> elements) {
    final list = useMemoized(context, () => ReactiveList(elements));
    OrefDevTools.registerCollection(list, context: context, type: 'List');
    if (!list._devtoolsDisposerRegistered) {
      registerElementDisposer(
        context,
        () => OrefDevTools.markCollectionDisposed(list),
      );
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
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Resize',
      deltas: [OrefCollectionDelta(kind: 'update', label: 'length -> $value')],
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
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Replace',
      deltas: [
        OrefCollectionDelta(
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
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Add',
      deltas: [OrefCollectionDelta(kind: 'add', label: element.toString())],
    );
  }

  @override
  void addAll(Iterable<T> iterable) {
    _source.addAll(iterable);
    trigger();
    final preview = iterable.take(3).map((item) => item.toString()).toList();
    final deltaLabel = preview.isEmpty ? 'items' : preview.join(', ');
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Add',
      deltas: [OrefCollectionDelta(kind: 'add', label: deltaLabel)],
      note: iterable.length > preview.length
          ? 'Added ${iterable.length} items'
          : null,
    );
  }

  @override
  void insert(int index, T element) {
    _source.insert(index, element);
    trigger();
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Add',
      deltas: [OrefCollectionDelta(kind: 'add', label: '[$index] $element')],
    );
  }

  @override
  bool remove(Object? element) {
    final result = _source.remove(element);
    trigger();
    if (result) {
      OrefDevTools.recordCollectionMutation(
        this,
        operation: 'Remove',
        deltas: [
          OrefCollectionDelta(kind: 'remove', label: element.toString()),
        ],
      );
    }
    return result;
  }

  @override
  T removeAt(int index) {
    final result = _source.removeAt(index);
    trigger();
    OrefDevTools.recordCollectionMutation(
      this,
      operation: 'Remove',
      deltas: [OrefCollectionDelta(kind: 'remove', label: '[$index] $result')],
    );
    return result;
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
