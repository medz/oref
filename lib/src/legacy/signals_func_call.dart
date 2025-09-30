import 'package:oref/oref.dart';

extension SignalsFuncCall<T> on Signal<T> {
  @Deprecated('Use `.value` instead, Remove in 3.0 version.')
  T call() => value;
}

extension WritableSignalFuncCall<T> on WritableSignal<T> {
  @Deprecated('Use `.value` instead, Remove in 3.0 version.')
  T call([T? newValue, bool nulls = false]) {
    if (null is T && (newValue != null || nulls)) {
      value = newValue as T;
    }

    return value;
  }
}
