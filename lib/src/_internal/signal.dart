final class Signal<T> {
  const Signal(this.oper);

  final T Function([T?, bool]) oper;

  Type typeof() => T;
}
