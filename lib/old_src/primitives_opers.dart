extension SignalNumOpers on num Function([num?, bool]) {
  num operator +(num other) => this() + other;
  num operator -(num other) => this() - other;
  num operator *(num other) => this() * other;
  int operator /(num other) => this() ~/ other;
  num operator %(num other) => this() % other;
  int operator ~/(num other) => this() ~/ other;
  num operator -() => -this();
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
}

extension SignalDoubleOpers on double Function([double?, bool]) {
  double operator +(double other) => this() + other;
  double operator -(double other) => this() - other;
  double operator *(double other) => this() * other;
  int operator /(num other) => this() ~/ other;
  double operator %(num other) => this() % other;
  int operator ~/(num other) => this() ~/ other;
  double operator -() => -this();
}

extension SignalStringOpers on String Function([String?, bool]) {
  String operator +(String other) => this() + other;
  String operator [](int index) => this()[index];
  int codeUnitAt(int index) => this().codeUnitAt(index);
  int get length => this().length;
  bool endsWith(String other) => this().endsWith(other);
  bool startsWith(Pattern pattern, [int index = 0]) =>
      this().startsWith(pattern, index);
  int indexOf(Pattern pattern, [int start = 0]) =>
      this().indexOf(pattern, start);
  int lastIndexOf(Pattern pattern, [int? start]) =>
      this().lastIndexOf(pattern, start);
  bool get isEmpty => this().isEmpty;
  bool get isNotEmpty => !isEmpty;
  String substring(int start, [int? end]) => this().substring(start, end);
  String trim() => this().trim();
  String trimLeft() => this().trimLeft();
  String trimRight() => this().trimRight();
  String operator *(int times) => this() * times;
  String padLeft(int width, [String padding = ' ']) =>
      this().padLeft(width, padding);
  String padRight(int width, [String padding = ' ']) =>
      this().padRight(width, padding);
  bool contains(Pattern other, [int startIndex = 0]) =>
      this().contains(other, startIndex);
  String replaceFirst(Pattern from, String to, [int startIndex = 0]) =>
      this().replaceFirst(from, to, startIndex);
  String replaceFirstMapped(
    Pattern from,
    String Function(Match match) replace, [
    int startIndex = 0,
  ]) => this().replaceFirstMapped(from, replace, startIndex);
  String replaceAll(Pattern from, String replace) =>
      this().replaceAll(from, replace);
  String replaceAllMapped(Pattern from, String Function(Match match) replace) =>
      this().replaceAllMapped(from, replace);
  String replaceRange(int start, int? end, String replacement) =>
      this().replaceRange(start, end, replacement);
  List<String> split(Pattern pattern) => this().split(pattern);
  String splitMapJoin(
    Pattern pattern, {
    String Function(Match)? onMatch,
    String Function(String)? onNonMatch,
  }) => this().splitMapJoin(pattern, onMatch: onMatch, onNonMatch: onNonMatch);
  List<int> get codeUnits => this().codeUnits;
  Runes get runes => this().runes;
  String toLowerCase() => this().toLowerCase();
  String toUpperCase() => this().toUpperCase();
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

// extension SignalListOpers<E, T extends List<E>> on T Function([T?, bool]) {
//   /// The object at the given [index] in the list.
//   ///
//   /// The [index] must be a valid index of this list,
//   /// which means that `index` must be non-negative and
//   /// less than [length].
//   E operator [](int index) => this()[index];

//   /// Sets the value at the given [index] in the list to [value].
//   ///
//   /// The [index] must be a valid index of this list,
//   /// which means that `index` must be non-negative and
//   /// less than [length].
//   void operator []=(int index, E value) {
//     untrack(this)[index] = value;
//     triggerSignal(this);
//   }

//   /// The first element of the list.
//   set first(E value) {
//     untrack(this).first = value;
//     triggerSignal(this);
//   }

//   /// The last element of the list.
//   set last(E value) {
//     untrack(this).last = value;
//     triggerSignal(this);
//   }

//   // TODO: Dart bug.
//   // set length(int newLength) {
//   //   untrack(this).length = newLength;
//   //   triggerSignal(this);
//   // }

//   void add(E value) {
//     untrack(this).add(value);
//     triggerSignal(this);
//   }

//   void addAll(Iterable<E> iterable) {
//     untrack(this).addAll(iterable);
//     triggerSignal(this);
//   }

//   Iterable<E> get reversed => this().reversed;

//   void sort([int Function(E a, E b)? compare]) {
//     untrack(this).sort(compare);
//     triggerSignal(this);
//   }

//   void shuffle([Random? random]) {
//     untrack(this).shuffle(random);
//     triggerSignal(this);
//   }

//   void clear() {
//     final list = untrack(this);
//     if (list.isEmpty) return;

//     list.clear();
//     triggerSignal(this);
//   }

//   void insert(int index, E element) {
//     untrack(this).insert(index, element);
//     triggerSignal(this);
//   }

//   void insertAll(int index, Iterable<E> iterable) {
//     untrack(this).insertAll(index, iterable);
//     triggerSignal(this);
//   }

//   void setAll(int index, Iterable<E> iterable) {
//     untrack(this).setAll(index, iterable);
//     triggerSignal(this);
//   }

//   bool remove(Object? value) {
//     try {
//       return untrack(this).remove(value);
//     } finally {
//       triggerSignal(this);
//     }
//   }

//   E removeAt(int index) {
//     try {
//       return untrack(this).removeAt(index);
//     } finally {
//       triggerSignal(this);
//     }
//   }

//   E removeLast() {
//     try {
//       return untrack(this).removeLast();
//     } finally {
//       triggerSignal(this);
//     }
//   }

//   void removeWhere(bool Function(E element) test) {
//     untrack(this).removeWhere(test);
//     triggerSignal(this);
//   }

//   void retainWhere(bool Function(E element) test) {
//     untrack(this).retainWhere(test);
//     triggerSignal(this);
//   }

//   List<E> operator +(List<E> other) => this() + other;
//   List<E> sublist(int start, [int? end]) => this().sublist(start, end);
//   Iterable<E> getRange(int start, int end) => this().getRange(start, end);
//   void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
//     untrack(this).setRange(start, end, iterable, skipCount);
//     triggerSignal(this);
//   }

//   void removeRange(int start, int end) {
//     untrack(this).removeRange(start, end);
//     triggerSignal(this);
//   }

//   void fillRange(int start, int end, [E? fillValue]) {
//     untrack(this).fillRange(start, end, fillValue);
//     triggerSignal(this);
//   }

//   void replaceRange(int start, int end, Iterable<E> replacements) {
//     untrack(this).replaceRange(start, end, replacements);
//     triggerSignal(this);
//   }

//   Map<int, E> asMap() => this().asMap();
// }
