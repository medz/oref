import 'package:oref/oref.dart';

extension EffectFuncCall on Effect {
  @Deprecated('Use .dispose() instead, remove in 3.0.0')
  void call() => dispose();
}

extension EffectScopeFuncCall on EffectScope {
  @Deprecated('Use .dispose() instead, remove in 3.0.0')
  void call() => dispose();
}
