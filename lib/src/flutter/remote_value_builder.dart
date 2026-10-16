import 'dart:async';

import 'package:flutter/widgets.dart';

import '../resources/resource.dart';
import '../shared/shared.dart';
import 'resource_builder.dart';

/// Observes an independent remote value or a shared Query field view.
class RemoteValueBuilder<S, T> extends StatelessWidget {
  const RemoteValueBuilder.create({
    super.key,
    required S Function() this._source,
    this._identity,
    this._initial,
    this._read,
    required FutureOr<T> Function(S, T) this._write,
    required this.builder,
  }) : _writeAck = null,
       _value = null,
       _ref = null,
       _mode = ResourceMode.create;

  const RemoteValueBuilder.ack({
    super.key,
    required S Function() this._source,
    this._identity,
    this._initial,
    this._read,
    required FutureOr<void> Function(S, T) write,
    required this.builder,
  }) : _writeAck = write,
       _write = null,
       _value = null,
       _ref = null,
       _mode = ResourceMode.create;

  const RemoteValueBuilder.value({
    super.key,
    required RemoteValue<S, T> this._value,
    required this.builder,
  }) : _source = null,
       _identity = null,
       _initial = null,
       _read = null,
       _write = null,
       _writeAck = null,
       _ref = null,
       _mode = ResourceMode.value;

  const RemoteValueBuilder.shared({
    super.key,
    required ResourceRef<RemoteValue<S, T>> this._ref,
    required this.builder,
  }) : _value = null,
       _source = null,
       _identity = null,
       _initial = null,
       _read = null,
       _write = null,
       _writeAck = null,
       _mode = ResourceMode.shared;

  final ResourceMode _mode;
  final S Function()? _source;
  final Object? Function(S)? _identity;
  final Seed<S, T>? _initial;
  final FutureOr<T> Function(S, ReadRequest)? _read;
  final FutureOr<T> Function(S, T)? _write;
  final FutureOr<void> Function(S, T)? _writeAck;
  final RemoteValue<S, T>? _value;
  final ResourceRef<RemoteValue<S, T>>? _ref;
  final Widget Function(BuildContext, RemoteState<S, T>, RemoteValue<S, T>)
  builder;

  @override
  Widget build(BuildContext context) =>
      ResourceBuilder<RemoteValue<S, T>, RemoteState<S, T>>(
        mode: _mode,
        create: () => _write != null
            ? RemoteValue<S, T>(
                source: _source!,
                identity: _identity,
                initial: _initial,
                read: _read,
                write: _write,
              )
            : RemoteValue<S, T>.ack(
                source: _source!,
                identity: _identity,
                initial: _initial,
                read: _read,
                write: _writeAck!,
              ),
        update: (remote) => updateRemoteValue(
          remote,
          source: _source!,
          identity: _identity,
          read: _read,
          write: _write,
          writeAck: _writeAck,
        ),
        value: _value,
        ref: _ref,
        read: (remote) => remote.state.value,
        builder: builder,
      );
}
