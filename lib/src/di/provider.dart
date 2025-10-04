import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

import '_dependency.dart';

class Provider<T> extends Widget {
  const Provider({
    super.key,
    required this.value,
    required this.child,
    this.name,
  });

  final Symbol? name;
  final T value;
  final Widget child;

  @override
  @internal
  Element createElement() => _ProviderElement(this);
}

class _ProviderElement<T> extends ComponentElement {
  _ProviderElement(Provider<T> super.widget);

  late final Dependency dependency;

  @override
  Provider<T> get widget => super.widget as Provider<T>;

  @override
  Widget build() => widget.child;

  @override
  void update(Provider<T> newWidget) {
    if ((widget.value is! Signal<T> && widget.value != newWidget.value) ||
        ((widget.name != null || newWidget.name != null) &&
            widget.value != newWidget.value)) {
      dependency.markNeedsBuild();
    }

    super.update(newWidget);
  }
}
