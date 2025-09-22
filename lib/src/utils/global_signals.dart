import 'package:alien_signals/alien_signals.dart' as alien;

final class GlobalSignals {
  const GlobalSignals._();

  static const create = alien.signal;
  static const computed = alien.computed;
  static const effect = alien.effect;
  static const effectScope = alien.effectScope;
}
