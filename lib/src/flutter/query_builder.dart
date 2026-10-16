import 'dart:async';

import 'package:flutter/widgets.dart';

import '../resources/resource.dart';
import '../shared/shared.dart';
import 'resource_builder.dart';

/// Owns, borrows, or shares a query and observes its immutable snapshot.
class QueryBuilder<S, T> extends StatelessWidget {
  const QueryBuilder.create({
    super.key,
    required S Function() this._source,
    required FutureOr<T> Function(S, ReadRequest) this._load,
    required this.builder,
  }) : _value = null,
       _ref = null,
       _mode = ResourceMode.create;

  const QueryBuilder.value({
    super.key,
    required Query<S, T> this._value,
    required this.builder,
  }) : _source = null,
       _load = null,
       _ref = null,
       _mode = ResourceMode.value;

  const QueryBuilder.shared({
    super.key,
    required ResourceRef<Query<S, T>> this._ref,
    required this.builder,
  }) : _value = null,
       _source = null,
       _load = null,
       _mode = ResourceMode.shared;

  final ResourceMode _mode;
  final S Function()? _source;
  final FutureOr<T> Function(S, ReadRequest)? _load;
  final Query<S, T>? _value;
  final ResourceRef<Query<S, T>>? _ref;
  final Widget Function(BuildContext, QueryState<S, T>, Query<S, T>) builder;

  @override
  Widget build(BuildContext context) =>
      ResourceBuilder<Query<S, T>, QueryState<S, T>>(
        mode: _mode,
        create: () => Query<S, T>(source: _source!, load: _load!),
        update: (query) => updateQuery(query, source: _source!, load: _load!),
        value: _value,
        ref: _ref,
        read: (query) => query.state.value,
        builder: builder,
      );
}
