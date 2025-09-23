import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/widgets.dart';

import '../core/memoized.dart';
import '../core/widget_effect.dart';
import 'reactive.dart';

abstract interface class Ref<T extends Widget, S> {
  void trigger();
}

extension WidgetRef<T extends Widget> on Ref<T, T> {
  T get widget {
    final ref = (this as _ReactiveRef);
    ref.track();

    return ref.cached as T;
  }
}

extension StatefulWidgetRef<T extends StatefulWidget, S extends State<T>>
    on Ref<T, S> {
  T get widget {
    final ref = (this as _ReactiveRef);
    ref.track();

    return ref.cached as T;
  }

  S get state {
    final ref = this as _ReactiveRef;
    ref.track();

    return (ref.element as StatefulElement).state as S;
  }
}

({Ref<T, S> Function<S>(S) infer}) ref<T extends Widget>(BuildContext context) {
  final effect = useWidgetEffect(context);
  assert(
    effect.node == getCurrentSub(),
    'The `ref` is only allowed to be used at the top level of `Widget.build`',
  );

  return useMemoized(
    context,
    () => (
      infer: <S>(S state) {
        assert(
          effect.node == getCurrentSub(),
          'The infer is only allowed to be used at the top level of `Widget.build`',
        );
        assert(
          state is Widget || state is State,
          'Invalid infer type ${state.runtimeType}, expected State<$T> or $T',
        );
        assert(
          () {
            if (state is State) return state.context == context;
            return true;
          }(),
          'Invalid infer ${state.runtimeType}, the state must own the context',
        );

        final widget = state is State ? state.widget : state;
        final ref = useMemoized(
          context,
          () => _ReactiveRef<T, S>(context as Element, widget as T),
        );

        if (context.mounted && ref.cached != (ref.cached = widget as T)) {
          ref.trigger();
        }

        return ref;
      },
    ),
  );
}

class _ReactiveRef<T extends Widget, S> extends Reactive<_ReactiveRef<T, S>>
    implements Ref<T, S> {
  _ReactiveRef(this.element, this.cached);

  T cached;
  final Element element;

  @override
  void track() => super.track();

  @override
  void trigger() => super.trigger();
}
