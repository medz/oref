import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/alien_adapter.dart';
import '../resources/resource.dart';
import '../shared/shared.dart';
import 'observed_state.dart';
import 'resource_scope.dart';

enum ResourceMode { create, value, shared }

/// The common ownership and observation protocol behind the typed adapters.
class ResourceBuilder<R extends Object, S> extends StatefulWidget {
  const ResourceBuilder({
    super.key,
    required this.mode,
    this.create,
    this.update,
    this.value,
    this.ref,
    required this.read,
    required this.builder,
  });

  final ResourceMode mode;
  final R Function()? create;
  final void Function(R)? update;
  final R? value;
  final ResourceRef<R>? ref;
  final S Function(R) read;
  final Widget Function(BuildContext, S, R) builder;

  @override
  State<ResourceBuilder<R, S>> createState() => _ResourceBuilderState<R, S>();
}

class _ResourceBuilderState<R extends Object, S>
    extends ObservedState<ResourceBuilder<R, S>> {
  R? _resource;
  void Function()? _release;
  Resources? _directory;
  int? _revision;
  ResourceRef<R>? _ref;

  @override
  void initState() {
    super.initState();
    if (widget.mode != ResourceMode.shared) _bind();
  }

  void _bind([ResourceScopeData? scope]) {
    untracked(() {
      switch (widget.mode) {
        case ResourceMode.create:
          final resource = widget.create!();
          _resource = resource;
          _release = () => disposeResource(resource);
        case ResourceMode.value:
          _resource = widget.value as R;
          _release = null;
        case ResourceMode.shared:
          final lease = borrowResource(scope!.resources, widget.ref!);
          _resource = lease.value;
          _release = lease.release;
          _directory = scope.resources;
          _revision = scope.revision;
          _ref = widget.ref;
      }
    });
    if (widget.mode != ResourceMode.value) {
      final resource = _resource!;
      scheduleMicrotask(() {
        if (mounted && identical(_resource, resource)) {
          untracked(() => activateResource(resource));
        }
      });
    }
  }

  void _unbind() {
    resetObservation();
    final release = _release;
    _release = null;
    _resource = null;
    _directory = null;
    _revision = null;
    _ref = null;
    if (release != null) untracked(release);
  }

  void _bindShared() {
    final scope = resourceScopeOf(context);
    if (_resource != null &&
        identical(_directory, scope.resources) &&
        _revision == scope.revision &&
        _ref == widget.ref) {
      return;
    }
    _unbind();
    _bind(scope);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.mode == ResourceMode.shared) _bindShared();
  }

  @override
  void didUpdateWidget(covariant ResourceBuilder<R, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode ||
        (widget.mode == ResourceMode.value &&
            !identical(widget.value, oldWidget.value))) {
      _unbind();
      if (widget.mode == ResourceMode.shared) {
        _bindShared();
      } else {
        _bind();
      }
    } else if (widget.mode == ResourceMode.shared) {
      _bindShared();
    } else if (widget.mode == ResourceMode.create) {
      untracked(() => widget.update!(_resource!));
    }
  }

  @override
  Widget build(BuildContext context) => observe(() {
    final resource = _resource!;
    return widget.builder(context, widget.read(resource), resource);
  });

  @override
  void dispose() {
    stopObserving();
    final release = _release;
    _release = null;
    _resource = null;
    try {
      if (release != null) untracked(release);
    } finally {
      super.dispose();
    }
  }
}
