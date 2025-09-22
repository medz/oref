import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:flutter/material.dart';

import '../core/memoized.dart';

/// Creates a reference to a widget that can be used to update the widget's value.
final class Ref<T extends Widget> {
  const Ref._(this._signal);

  final T Function([T?, bool]) _signal;

  /// Returns the reactive reference widget.
  T get widget => _signal();
}

/// Widget reference utils on [T] extends [Widget]
extension WidgetRef<T extends Widget> on T {
  /// {@template oref.use-ref}
  /// Lookup a widget reference.
  ///
  /// Return a Ref object that will automatically reactive to updates in the props value of the Widget.
  ///
  /// Example:
  /// ```dart
  /// class FullName extends StatelessWidget {
  ///   const FullName(this.firstName);
  ///
  ///   final String firstName;
  ///
  ///   Widget build(BuildContext context) {
  ///     final lastName = signal(context , "Du");
  ///     final ref = useRef(context);
  ///     final full = computed(() => ref.widget.firstName + lastName());
  ///     //...
  ///   }
  /// }
  /// ```
  ///
  /// ### Why need a widget reference?
  ///
  /// In Flutter, widget updates aren't automatically collected into the reactive system.
  /// Therefore, if you use widget properties directly in an effect or computed method,
  /// external updates to those properties won't trigger.
  ///
  /// Therefore, we need a way to make the widget itself reactive.
  /// {@endtemplate}
  Ref<T> useRef(BuildContext context) => _upsert(context, this);
}

/// Widget reference utils on [T] extends [StatefulWidget] of State.
extension StateRef<T extends StatefulWidget> on State<T> {
  /// {@macro oref.use-ref}
  Ref<T> useRef([BuildContext? context]) =>
      _upsert(context ?? this.context, widget);
}

Ref<T> _upsert<T extends Widget>(BuildContext context, T widget) {
  final ref = useMemoized(context, () => Ref._(alien.signal(widget)));
  if (ref.widget != widget) {
    ref._signal(widget);
  }

  return ref;
}
