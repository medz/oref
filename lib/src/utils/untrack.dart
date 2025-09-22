import 'package:alien_signals/alien_signals.dart';

T untrack<T>(T Function() getter) {
  final prevSub = setCurrentSub(null);
  try {
    return getter();
  } finally {
    setCurrentSub(prevSub);
  }
}
