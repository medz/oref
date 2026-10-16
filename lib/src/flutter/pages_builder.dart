import 'dart:async';

import 'package:flutter/widgets.dart';

import '../resources/resource.dart';
import '../shared/shared.dart';
import 'resource_builder.dart';

/// Observes a paginated resource with explicit ownership.
class PagesBuilder<S, T, C extends Object> extends StatelessWidget {
  const PagesBuilder.create({
    super.key,
    required S Function() this._source,
    required FutureOr<List<T>> Function(S, C?, ReadRequest) this._load,
    required C? Function(S, List<T>) this._nextCursor,
    required this.builder,
  }) : _value = null,
       _ref = null,
       _mode = ResourceMode.create;

  const PagesBuilder.value({
    super.key,
    required Pages<S, T, C> this._value,
    required this.builder,
  }) : _source = null,
       _load = null,
       _nextCursor = null,
       _ref = null,
       _mode = ResourceMode.value;

  const PagesBuilder.shared({
    super.key,
    required ResourceRef<Pages<S, T, C>> this._ref,
    required this.builder,
  }) : _value = null,
       _source = null,
       _load = null,
       _nextCursor = null,
       _mode = ResourceMode.shared;

  final ResourceMode _mode;
  final S Function()? _source;
  final FutureOr<List<T>> Function(S, C?, ReadRequest)? _load;
  final C? Function(S, List<T>)? _nextCursor;
  final Pages<S, T, C>? _value;
  final ResourceRef<Pages<S, T, C>>? _ref;
  final Widget Function(BuildContext, PagesState<S, T, C>, Pages<S, T, C>)
  builder;

  @override
  Widget build(BuildContext context) =>
      ResourceBuilder<Pages<S, T, C>, PagesState<S, T, C>>(
        mode: _mode,
        create: () => Pages<S, T, C>(
          source: _source!,
          load: _load!,
          nextCursor: _nextCursor!,
        ),
        update: (pages) => updatePages(
          pages,
          source: _source!,
          load: _load!,
          nextCursor: _nextCursor!,
        ),
        value: _value,
        ref: _ref,
        read: (pages) => pages.state.value,
        builder: builder,
      );
}
