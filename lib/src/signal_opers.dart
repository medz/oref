import 'dart:math';

extension SignalNumOpers on num Function([num?, bool]) {
  num operator +(num other) => this() + other;
  num operator -(num other) => this() - other;
  num operator *(num other) => this() * other;
  int operator /(num other) => this() ~/ other;
  num operator %(num other) => this() % other;
  int operator ~/(num other) => this() ~/ other;
  num operator -() => -this();

  num increment([num value = 1]) => this(this + value);
  num decrement([num value = 1]) => this(this - value);
}

extension SignalIntOpers on int Function([int?, bool]) {
  int operator +(int other) => this() + other;
  int operator -(int other) => this() - other;
  int operator *(int other) => this() * other;
  int operator /(num other) => this() ~/ other;
  int operator %(int other) => this() % other;
  int operator ~/(num other) => this() ~/ other;
  int operator &(int other) => this() & other;
  int operator |(int other) => this() | other;
  int operator ^(int other) => this() ^ other;
  int operator <<(int other) => this() << other;
  int operator >>(int other) => this() >> other;
  int operator >>>(int other) => this() >>> other;
  int operator ~() => ~this();
  int operator -() => -this();

  int increment([int value = 1]) => this(this + value);
  int decrement([int value = 1]) => this(this - value);
}

extension SignalDoubleOpers on double Function([double?, bool]) {
  double operator +(double other) => this() + other;
  double operator -(double other) => this() - other;
  double operator *(double other) => this() * other;
  int operator /(num other) => this() ~/ other;
  double operator %(num other) => this() % other;
  int operator ~/(num other) => this() ~/ other;
  double operator -() => -this();

  double increment([double value = 1]) => this(this + value);
  double decrement([double value = 1]) => this(this - value);
}

extension SignalStringOpers on String Function([String?, bool]) {
  String operator +(String other) => this() + other;
}

extension SignalBoolOpers on bool Function([bool?, bool]) {
  bool operator &(bool other) => this() & other;
  bool operator |(bool other) => this() | other;
  bool operator ^(bool other) => this() ^ other;
}

extension SignalIterableOpers<E, T extends Iterable<E>>
    on T Function([T?, bool]) {
  Iterator<E> get iterator => this().iterator;
  int get length => this().length;
  bool get isEmpty => this().isEmpty;
  bool get isNotEmpty => !isEmpty;
  E get first => this().first;
  E get last => this().last;
  E get single => this().single;
  Iterable<(int, E)> get indexed => this().indexed;
  E? get firstOrNull => this().firstOrNull;
  E? get lastOrNull => this().lastOrNull;
  E? get singleOrNull => this().singleOrNull;

  Iterable<E> followedBy(Iterable<E> other) => this().followedBy(other);
  Iterable<E> map(E Function(E) f) => this().map(f);
  Iterable<E> where(bool Function(E) test) => this().where(test);
  Iterable<R> whereType<R>() => this().whereType<R>();
  Iterable<R> expand<R>(Iterable<R> Function(E element) f) => this().expand(f);
  bool contains(Object? element) => this().contains(element);
  E reduce(E Function(E value, E element) combine) => this().reduce(combine);
  R fold<R>(R initialValue, R Function(R previousValue, E element) combine) =>
      this().fold(initialValue, combine);
  bool every(bool Function(E element) test) => this().every(test);
  String join([String separator = '']) => this().join(separator);
  bool any(bool Function(E element) test) => this().any(test);
  Iterable<E> take(int count) => this().take(count);
  Iterable<E> takeWhile(bool Function(E value) test) => this().takeWhile(test);
  Iterable<E> skip(int count) => this().skip(count);
  Iterable<E> skipWhile(bool Function(E value) test) => this().skipWhile(test);
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      this().firstWhere(test, orElse: orElse);
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      this().lastWhere(test, orElse: orElse);
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      this().singleWhere(test, orElse: orElse);
  E elementAt(int index) => this().elementAt(index);
  E? elementAtOrNull(int index) => this().elementAtOrNull(index);
}

extension SignalListOpers<E, T extends List<E>> on T Function([T?, bool]) {
  E operator [](int index) => this()[index];
  void operator []=(int index, E value) {
    this()[index] = value;
  }

  Iterable<E> get reversed => this().reversed;

  set first(E value) => this(this()..first = value);
  set last(E value) => this(this()..last = value);
  set length(int newLength) => this(this()..length = newLength);

  void add(E value) => this(this()..add(value));
  void addAll(Iterable<E> iterable) => this(this()..addAll(iterable));
  void sort([int Function(E a, E b)? compare]) => this(this()..sort(compare));
  void shuffle([Random? random]) => this(this()..shuffle(random));
}
