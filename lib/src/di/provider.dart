import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class Provider<T> extends Widget {
  const Provider({
    super.key,
    this.name,
    required this.value,
    required this.child,
  });

  final T? name;
  final T value;
  final Widget child;

  @override
  @internal
  Element createElement() => _ProviderElement(this);
}

class _ProviderElement<T> extends ComponentElement {
  _ProviderElement(Provider<T> super.widget);

  @override
  Provider<T> get widget => super.widget as Provider<T>;

  @override
  Widget build() => widget.child;
}
