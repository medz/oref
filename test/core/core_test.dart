import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';
import 'package:oref/src/core/alien_adapter.dart';

void main() {
  test('computed is lazy and follows conditional dependencies', () {
    final useLeft = Value(true);
    final left = Value(2);
    final right = Value(10);
    var calculations = 0;
    final current = Computed(() {
      calculations++;
      return useLeft.value ? left.value : right.value;
    });
    expect(calculations, 0);
    final observed = <int>[];
    final subscription = current.subscribe(() => observed.add(current.peek()));
    expect(calculations, 1);
    expect(observed, isEmpty);
    right.value = 11;
    expect(calculations, 1);
    left.value = 3;
    useLeft.value = false;
    left.value = 4;
    expect(observed, [3, 11]);
    subscription.dispose();
    subscription.dispose();
    right.value = 12;
    expect(observed, [3, 11]);
  });

  test('peek and listener reads do not become caller dependencies', () {
    final source = Value(0);
    final other = Value(10);
    final observed = <int>[];
    var parentRuns = 0;
    late Subscription inner;
    final parent = reactiveEffect(() {
      parentRuns++;
      source.peek();
      inner = source.subscribe(() => observed.add(other.value));
    });
    expect(parentRuns, 1);
    source.value = 1;
    other.value = 11;
    expect(observed, [10]);
    expect(parentRuns, 1);
    parent.dispose();
    source.value = 2;
    expect(observed, [10, 11]);
    inner.dispose();
  });

  test('values use identity rather than a custom equality operator', () {
    final initial = _EqualValue(1);
    final value = Value(initial);
    var calls = 0;
    final subscription = value.subscribe(() => calls++);
    value.value = initial;
    expect(calls, 0);
    value.value = _EqualValue(1);
    expect(calls, 1);
    subscription.dispose();
  });

  test('computed equality and nested batch use the native kernel', () {
    final left = Value(1);
    final right = Value(2);
    final sum = Computed(() => left.value + right.value);
    final seen = <int>[];
    final subscription = sum.subscribe(() => seen.add(sum.peek()));
    final result = batch(() {
      left.value = 2;
      batch(() => right.value = 1);
      return 'done';
    });
    expect(result, 'done');
    expect(seen, isEmpty);
    expect(
      () => batch(() {
        left.value = 4;
        throw StateError('changes remain committed');
      }),
      throwsStateError,
    );
    expect(seen, [5]);
    right.value = 2;
    expect(seen, [5, 6]);
    subscription.dispose();
  });

  test('computed errors retain their original object and recover', () {
    final source = Value(1);
    final failure = StateError('calculation');
    var calls = 0;
    final inner = Computed(() {
      calls++;
      if (source.value == 1) throw failure;
      return source.value * 2;
    });
    final outer = Computed(() => inner.value + 1);
    expect(() => outer.value, throwsA(same(failure)));
    expect(() => outer.peek(), throwsA(same(failure)));
    expect(calls, 1);
    batch(() {
      source.value = 2;
      source.value = 1;
    });
    expect(() => outer.peek(), throwsA(same(failure)));
    expect(calls, 2);
    source.value = 3;
    expect(outer.peek(), 7);
  });

  test('listener failures go to their registration zone', () async {
    final source = Value(0);
    final failure = StateError('listener');
    final reported = <Object>[];
    late Subscription subscription;
    runZonedGuarded(() {
      subscription = source.subscribe(() => throw failure);
    }, (error, _) => reported.add(error));
    var laterCalls = 0;
    final later = source.subscribe(() => laterCalls++);
    source.value = 1;
    source.value = 2;
    expect(reported, [same(failure), same(failure)]);
    expect(laterCalls, 2);
    subscription.dispose();
    later.dispose();
  });

  test('a stopped effect does not subscribe to subsequent reads', () {
    final source = Value(0);
    final other = Value(0);
    var calls = 0;
    late Subscription subscription;
    subscription = reactiveEffect(() {
      source.value;
      calls++;
      if (calls > 1) {
        subscription.dispose();
        other.value;
      }
    });
    source.value = 1;
    other.value = 1;
    source.value = 2;
    expect(calls, 2);
  });

  test('observer defers rebuilds and replaces dynamic dependencies', () {
    final useLeft = Value(true);
    final left = Value(1);
    final right = Value(10);
    var builds = 0;
    var invalidations = 0;
    final observer = ReactiveObserver(() => invalidations++);
    int build() {
      builds++;
      return useLeft.value ? left.value : right.value;
    }

    expect(observer.track(build), 1);
    left.value = 2;
    left.value = 3;
    expect(builds, 1);
    expect(invalidations, 1);
    expect(observer.track(build), 3);
    useLeft.value = false;
    expect(observer.track(build), 10);
    left.value = 4;
    expect(invalidations, 2);
    right.value = 11;
    expect(invalidations, 3);
    observer.dispose();
    observer.dispose();
    expect(() => observer.track(build), throwsStateError);
  });

  test('observer native computed comparison avoids false invalidation', () {
    final source = Value(1);
    final parity = Computed(() => source.value.isOdd);
    var invalidations = 0;
    final observer = ReactiveObserver(() => invalidations++);
    expect(observer.track(() => parity.value), isTrue);
    source.value = 3;
    expect(invalidations, 0);
    source.value = 4;
    expect(invalidations, 1);
    expect(observer.track(() => parity.value), isFalse);
    observer.dispose();
  });

  test('observer restores tracking after a throwing builder', () {
    final value = Value(1);
    var invalidations = 0;
    final observer = ReactiveObserver(() => invalidations++);
    expect(
      () => observer.track(() {
        value.value;
        throw StateError('build');
      }),
      throwsStateError,
    );
    value.value = 2;
    expect(invalidations, 1);
    expect(observer.track(() => value.value), 2);
    observer.dispose();
    value.value = 3;
    expect(invalidations, 1);
  });

  test('queued observer disposal cancels its notification', () {
    final value = Value(0);
    var invalidations = 0;
    final observer = ReactiveObserver(() => invalidations++);
    observer.track(() => value.value);
    batch(() {
      value.value = 1;
      observer.dispose();
    });
    expect(invalidations, 0);
  });

  test('a dependency written during tracking schedules a later rebuild', () {
    final source = Value(0);
    var invalidations = 0;
    var builds = 0;
    final observer = ReactiveObserver(() => invalidations++);
    expect(
      observer.track(() {
        builds++;
        final before = source.value;
        source.value = 1;
        return before;
      }),
      0,
    );
    expect(builds, 1);
    expect(invalidations, 1);
    expect(observer.track(() => source.value), 1);
    observer.dispose();
  });
}

class _EqualValue {
  _EqualValue(this.number);
  final int number;

  @override
  bool operator ==(Object other) =>
      other is _EqualValue && other.number == number;

  @override
  int get hashCode => number.hashCode;
}
