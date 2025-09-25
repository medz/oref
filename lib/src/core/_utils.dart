import 'package:alien_signals/alien_signals.dart';

(void Function(), ReactiveNode) createEffect(void Function() callback) {
  ReactiveNode? sub;
  final stop = effect(() {
    sub ??= getCurrentSub();
    callback();
  });

  return (stop, sub!);
}
