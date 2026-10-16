import 'dart:async';

import 'package:flutter/widgets.dart' hide Action;

import '../resources/resource.dart';
import '../shared/shared.dart';
import 'resource_builder.dart';

/// Observes an explicit action. Creating or borrowing it never runs it.
class ActionBuilder<A, R> extends StatelessWidget {
  const ActionBuilder.create({
    super.key,
    required FutureOr<R> Function(A) this._execute,
    required this.builder,
  }) : _value = null,
       _ref = null,
       _mode = ResourceMode.create;

  const ActionBuilder.value({
    super.key,
    required Action<A, R> this._value,
    required this.builder,
  }) : _execute = null,
       _ref = null,
       _mode = ResourceMode.value;

  const ActionBuilder.shared({
    super.key,
    required ResourceRef<Action<A, R>> this._ref,
    required this.builder,
  }) : _value = null,
       _execute = null,
       _mode = ResourceMode.shared;

  final ResourceMode _mode;
  final FutureOr<R> Function(A)? _execute;
  final Action<A, R>? _value;
  final ResourceRef<Action<A, R>>? _ref;
  final Widget Function(BuildContext, ActionState<R>, Action<A, R>) builder;

  @override
  Widget build(BuildContext context) =>
      ResourceBuilder<Action<A, R>, ActionState<R>>(
        mode: _mode,
        create: () => Action<A, R>(execute: _execute!),
        update: (action) => updateAction(action, execute: _execute!),
        value: _value,
        ref: _ref,
        read: (action) => action.state.value,
        builder: builder,
      );
}
