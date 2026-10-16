import 'package:flutter/widgets.dart';

import '../core/alien_adapter.dart';
import 'observed_state.dart';

/// Owns one local object and observes the Readables used by [builder].
class StateBuilder<T> extends StatefulWidget {
  const StateBuilder({
    super.key,
    this.identity,
    required T Function() this._create,
    this.update,
    this.dispose,
    required this.builder,
  }) : _value = null,
       _owned = true;

  /// Borrows [value]. Replacing it only changes this widget's observations.
  const StateBuilder.value({
    super.key,
    required T this._value,
    required this.builder,
  }) : _create = null,
       _owned = false,
       identity = null,
       update = null,
       dispose = null;

  final Object? identity;
  final T Function()? _create;
  final T? _value;
  final bool _owned;
  final void Function(T)? update;
  final void Function(T)? dispose;
  final Widget Function(BuildContext, T) builder;

  @override
  State<StateBuilder<T>> createState() => _StateBuilderState<T>();
}

class _StateBuilderState<T> extends ObservedState<StateBuilder<T>> {
  late T _value;
  void Function(T)? _dispose;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _value = untracked(
      () => widget._owned ? widget._create!() : widget._value as T,
    );
    _dispose = widget._owned ? widget.dispose : null;
  }

  void _release() {
    final dispose = _dispose;
    _dispose = null;
    if (dispose != null) untracked(() => dispose(_value));
  }

  @override
  void didUpdateWidget(covariant StateBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._owned != oldWidget._owned ||
        (widget._owned
            ? widget.identity != oldWidget.identity
            : !identical(widget._value, oldWidget._value))) {
      resetObservation();
      _release();
      _create();
    } else if (widget._owned && widget.update != null) {
      untracked(() => widget.update!(_value));
    }
  }

  @override
  Widget build(BuildContext context) =>
      observe(() => widget.builder(context, _value));

  @override
  void dispose() {
    stopObserving();
    try {
      _release();
    } finally {
      super.dispose();
    }
  }
}
