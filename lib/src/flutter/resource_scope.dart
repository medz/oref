import 'package:flutter/widgets.dart';

import '../core/alien_adapter.dart';
import '../core/subscription.dart';
import '../shared/shared.dart';
import 'observed_state.dart';

/// Connects an application-owned resource directory above its Navigator.
class ResourceScope extends StatefulWidget {
  const ResourceScope.create({
    super.key,
    required Resources Function() this._create,
    required this.child,
  }) : _value = null;

  const ResourceScope.value({
    super.key,
    required Resources this._value,
    required this.child,
  }) : _create = null;

  final Resources Function()? _create;
  final Resources? _value;
  final Widget child;

  static Resources of(BuildContext context) =>
      resourceScopeOf(context).resources;

  @override
  State<ResourceScope> createState() => _ResourceScopeState();
}

class _ResourceScopeState extends RebuildState<ResourceScope> {
  late Resources _resources;
  late Subscription _subscription;
  int _revision = 0;
  bool _owned = false;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _owned = widget._create != null;
    _resources = untracked(() => widget._create?.call() ?? widget._value!);
    _subscription = resourcesRevision(_resources).subscribe(() {
      _revision++;
      requestRebuild();
    });
  }

  void _release() {
    _subscription.dispose();
    if (_owned) untracked(_resources.dispose);
  }

  @override
  void didUpdateWidget(covariant ResourceScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget._create != null) != (oldWidget._create != null) ||
        (widget._create == null &&
            !identical(widget._value, oldWidget._value))) {
      _release();
      _revision++;
      _bind();
    }
  }

  @override
  Widget build(BuildContext context) => buildSafely(
    () => ResourceScopeData(
      resources: _resources,
      revision: _revision,
      child: widget.child,
    ),
  );

  @override
  void dispose() {
    try {
      _release();
    } finally {
      super.dispose();
    }
  }
}

// Internal scope data also carries ABA and namespace-error transitions.
class ResourceScopeData extends InheritedWidget {
  const ResourceScopeData({
    super.key,
    required this.resources,
    required this.revision,
    required super.child,
  });

  final Resources resources;
  final int revision;

  @override
  bool updateShouldNotify(ResourceScopeData oldWidget) =>
      !identical(resources, oldWidget.resources) ||
      revision != oldWidget.revision;
}

ResourceScopeData resourceScopeOf(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<ResourceScopeData>();
  if (scope == null) {
    throw FlutterError('A shared resource Builder requires a ResourceScope.');
  }
  return scope;
}
