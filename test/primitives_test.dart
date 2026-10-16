import 'dart:async';

import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/preset.dart' as preset;
import 'package:test/test.dart';
import 'package:oref/oref.dart';

class EqualValue {
  EqualValue(this.number);
  final int number;
  @override
  bool operator ==(Object other) =>
      other is EqualValue && other.number == number;
  @override
  int get hashCode => number.hashCode;
}

void main() {
  group('value objects', () {
    test(
      'signals expose tracked read/write and Readable accepts both values',
      () {
        final count = Signal(1);
        final doubled = Computed(() => count.value * 2);
        final List<Readable<int>> values = [count, doubled];
        final seen = <List<int>>[];
        final effect = Effect(
          (_) => seen.add([for (final value in values) value.value]),
        );
        count.value = 2;
        effect.dispose();
        count.value = 3;
        expect(seen, [
          [1, 2],
          [2, 4],
        ]);
        expect(doubled.value, 6);
      },
    );

    test('signal comparison is identical, not operator ==', () {
      final first = EqualValue(1);
      final signal = Signal(first);
      var runs = 0;
      final effect = Effect((_) {
        signal.value;
        runs++;
      });
      signal.value = first;
      expect(runs, 1);
      signal.value = EqualValue(1);
      expect(runs, 2);
      effect.dispose();
    });

    test('in-place collection mutation does not invent a notification', () {
      final list = Signal(<int>[]);
      var runs = 0;
      final effect = Effect((_) {
        list.value;
        runs++;
      });
      list.value.add(1);
      list.value = list.value;
      expect(runs, 1);
      list.value = [...list.value];
      expect(runs, 2);
      effect.dispose();
    });

    test('computed is lazy and caches until a dependency changes', () {
      final source = Signal(1);
      var runs = 0;
      final derived = Computed(() {
        runs++;
        return source.value * 2;
      });
      expect(runs, 0);
      expect(derived.value, 2);
      expect(derived.value, 2);
      expect(runs, 1);
      source.value = 3;
      expect(runs, 1);
      expect(derived.value, 6);
      expect(runs, 2);
    });

    test('computed result comparison follows upstream identity semantics', () {
      final source = Signal(0);
      final derived = Computed(() {
        source.value;
        return EqualValue(1);
      });
      var runs = 0;
      final effect = Effect((_) {
        derived.value;
        runs++;
      });
      source.value++;
      expect(runs, 2);
      effect.dispose();
    });

    test('conditional dependencies release the unused branch', () {
      final left = Signal(1), right = Signal(10), chooseLeft = Signal(true);
      final derived = Computed(
        () => chooseLeft.value ? left.value : right.value,
      );
      final seen = <int>[];
      final effect = Effect((_) => seen.add(derived.value));
      chooseLeft.value = false;
      left.value = 2;
      right.value = 11;
      expect(seen, [1, 10, 11]);
      effect.dispose();
    });

    test('computed errors cache and retry with the last successful value', () {
      final source = Signal(1);
      final error = StateError('compute');
      final previous = <int?>[];
      final derived = Computed<int>.withPrevious((value) {
        previous.add(value);
        if (source.value == 2) throw error;
        return source.value;
      });
      expect(derived.value, 1);
      source.value = 2;
      expect(() => derived.value, throwsA(same(error)));
      expect(() => derived.value, throwsA(same(error)));
      expect(previous, [null, 1]);
      source.value = 3;
      expect(derived.value, 3);
      expect(previous, [null, 1, 1]);
    });

    test('nullable computed values are supported', () {
      final value = Signal<int?>(null);
      final computed = Computed(() => value.value);
      expect(computed.value, isNull);
      value.value = 1;
      expect(computed.value, 1);
    });
  });

  group('effects and scopes', () {
    test(
      'effect runs synchronously and cleans in reverse registration order',
      () {
        final count = Signal(0);
        final events = <String>[];
        final effect = Effect((onCleanup) {
          events.add('run:${count.value}');
          onCleanup(() => events.add('first'));
          onCleanup(() => events.add('second'));
        });
        expect(events, ['run:0']);
        count.value = 1;
        effect.dispose();
        effect.dispose();
        expect(events, [
          'run:0',
          'second',
          'first',
          'run:1',
          'second',
          'first',
        ]);
      },
    );

    test('cleanup reads are not tracked', () {
      final source = Signal(0), cleanupRead = Signal(0);
      var runs = 0;
      final effect = Effect((onCleanup) {
        source.value;
        runs++;
        onCleanup(() {
          cleanupRead.value;
        });
      });
      source.value = 1;
      cleanupRead.value = 1;
      expect(runs, 2);
      effect.dispose();
    });

    test('parent rerun stops old children before parent cleanup', () {
      final source = Signal(0), childSource = Signal(0);
      final events = <String>[];
      final parent = Effect((onCleanup) {
        events.add('parent:${source.value}');
        Effect((onCleanup) {
          events.add('child:${childSource.value}');
          onCleanup(() => events.add('child cleanup'));
        });
        onCleanup(() => events.add('parent cleanup'));
      });
      source.value = 1;
      expect(events, [
        'parent:0',
        'child:0',
        'child cleanup',
        'parent cleanup',
        'parent:1',
        'child:0',
      ]);
      parent.dispose();
      final length = events.length;
      childSource.value = 1;
      expect(events.length, length);
    });

    test(
      'scope run returns values, does not rerun, and groups multiple runs',
      () {
        final source = Signal(0);
        final scope = ReactiveScope();
        var setups = 0, effects = 0;
        expect(
          scope.run(() {
            setups++;
            source.value;
            return 42;
          }),
          42,
        );
        scope.run(() {
          Effect((_) {
            source.value;
            effects++;
          });
        });
        scope.run(() {
          Effect((_) {
            source.value;
            effects++;
          });
        });
        source.value = 1;
        expect(setups, 1);
        expect(effects, 4);
        scope.dispose();
        scope.dispose();
        source.value = 2;
        expect(effects, 4);
        expect(() => scope.run(() {}), throwsStateError);
      },
    );

    test('nested scopes stop with their parent and cannot be reentered', () {
      final parent = ReactiveScope();
      late ReactiveScope child;
      final source = Signal(0);
      var runs = 0;
      parent.run(() {
        child = ReactiveScope();
        child.run(() {
          Effect((_) {
            source.value;
            runs++;
          });
        });
      });
      parent.dispose();
      source.value = 1;
      expect(runs, 1);
      expect(() => child.run(() {}), throwsStateError);
    });

    test('scope nested in an effect stops before the parent reruns', () {
      final source = Signal(0);
      final scopes = <ReactiveScope>[];
      var cleaned = 0;
      final parent = Effect((_) {
        source.value;
        final scope = ReactiveScope();
        scopes.add(scope);
        scope.run(() {
          Effect((onCleanup) => onCleanup(() => cleaned++));
        });
      });
      source.value = 1;
      expect(cleaned, 1);
      expect(() => scopes.first.run(() {}), throwsStateError);
      parent.dispose();
      expect(cleaned, 2);
    });

    test(
      'a throwing scope run restores context and retains a disposal handle',
      () {
        final scope = ReactiveScope();
        final source = Signal(0);
        var runs = 0;
        final error = StateError('setup');
        final previous = preset.getActiveSub();
        expect(
          () => scope.run(() {
            Effect((_) {
              source.value;
              runs++;
            });
            throw error;
          }),
          throwsA(same(error)),
        );
        expect(preset.getActiveSub(), same(previous));
        source.value = 1;
        expect(runs, 2);
        scope.dispose();
        source.value = 2;
        expect(runs, 2);
      },
    );

    test('initial effect failure retains upstream behavior within a scope', () {
      final scope = ReactiveScope();
      final source = Signal(0);
      final error = StateError('initial');
      var runs = 0;
      scope.run(() {
        expect(
          () => Effect((_) {
            source.value;
            runs++;
            if (runs == 1) throw error;
          }),
          throwsA(same(error)),
        );
      });
      source.value = 1;
      expect(
        runs,
        2,
      ); // Upstream does not roll back the failing initial effect.
      scope.dispose();
      source.value = 2;
      expect(runs, 2);
    });

    test(
      'cleanup failure propagates and does not promise remaining cleanup',
      () {
        final error = StateError('cleanup');
        final events = <String>[];
        final effect = Effect((onCleanup) {
          onCleanup(() => events.add('earlier'));
          onCleanup(() {
            events.add('latest');
            throw error;
          });
        });
        expect(effect.dispose, throwsA(same(error)));
        effect.dispose();
        expect(events, ['latest']);
      },
    );

    test('cleanup cannot be registered after its effect callback returns', () {
      late OnCleanup register;
      final effect = Effect((onCleanup) {
        register = onCleanup;
      });
      expect(() => register(() {}), throwsStateError);
      effect.dispose();
    });
  });

  group('synchronous boundaries', () {
    test('nested batch flushes once and reads current derived values', () {
      final count = Signal(0);
      final derived = Computed(() => count.value * 2);
      final seen = <int>[];
      final effect = Effect((_) => seen.add(derived.value));
      final result = batch(() {
        count.value = 1;
        batch(() {
          count.value = 2;
        });
        expect(seen, [0]);
        return derived.value;
      });
      expect(result, 4);
      expect(seen, [0, 4]);
      effect.dispose();
    });

    test('batch ends and flushes when callback throws without rollback', () {
      final count = Signal(0);
      final seen = <int>[];
      final effect = Effect((_) => seen.add(count.value));
      final error = StateError('batch');
      expect(
        () => batch(() {
          count.value = 1;
          throw error;
        }),
        throwsA(same(error)),
      );
      expect(preset.getBatchDepth(), 0);
      expect(seen, [0, 1]);
      effect.dispose();
    });

    test('untracked restores the previous subscriber after an error', () {
      final source = Signal(0), ignored = Signal(0);
      var runs = 0;
      final effect = Effect((_) {
        expect(
          () => untracked(() {
            ignored.value;
            throw StateError('read');
          }),
          throwsStateError,
        );
        source.value;
        runs++;
      });
      ignored.value = 1;
      expect(runs, 1);
      source.value = 1;
      expect(runs, 2);
      effect.dispose();
    });

    test('untracked computed reads retain the computed own dependencies', () {
      final source = Signal(0);
      final computed = Computed(() => source.value + 1);
      var runs = 0;
      final effect = Effect((_) {
        untracked(() => computed.value);
        runs++;
      });
      source.value = 1;
      expect(runs, 1);
      expect(computed.value, 2);
      effect.dispose();
    });

    test(
      'untracked leaves effects and scopes outside the caller ownership',
      () {
        final source = Signal(0);
        late Effect detached;
        late ReactiveScope detachedScope;
        var runs = 0;
        final parent = ReactiveScope();
        parent.run(() {
          untracked(() {
            detached = Effect((_) {
              source.value;
              runs++;
            });
            detachedScope = ReactiveScope();
            detachedScope.run(() {
              Effect((_) {
                source.value;
                runs++;
              });
            });
          });
        });
        parent.dispose();
        source.value = 1;
        expect(runs, 4);
        detached.dispose();
        detachedScope.dispose();
      },
    );

    test('batch ends before awaiting a returned Future', () async {
      final source = Signal(0);
      final seen = <int>[];
      final effect = Effect((_) => seen.add(source.value));
      final gate = Completer<void>();
      final future = batch(() async {
        source.value = 1;
        await gate.future;
        source.value = 2;
        source.value = 3;
      });
      expect(seen, [0, 1]);
      gate.complete();
      await future;
      expect(seen, [0, 1, 2, 3]);
      effect.dispose();
    });

    test('effect tracking and scope ownership do not cross await', () async {
      final before = Signal(0), after = Signal(0);
      final scope = ReactiveScope();
      final gate = Completer<void>();
      late Future<void> continuation;
      late Effect detached;
      var runs = 0, detachedRuns = 0;
      scope.run(() {
        Effect((_) {
          before.value;
          runs++;
          continuation = () async {
            await gate.future;
            after.value;
            detached = Effect((_) {
              after.value;
              detachedRuns++;
            });
          }();
        });
      });
      gate.complete();
      await continuation;
      after.value = 1;
      expect(runs, 1);
      scope.dispose();
      after.value = 2;
      expect(detachedRuns, 3);
      detached.dispose();
    });
  });

  test('value objects interoperate with the upstream runtime', () {
    final fresh = Signal(1);
    final old = alien.signal<int>(2);
    final derived = Computed(() => fresh.value + old());
    final seen = <int>[];
    final stop = alien.effect(() => seen.add(derived.value));
    batch(() {
      fresh.value = 3;
      old.set(4);
    });
    expect(seen, [3, 7]);
    stop();
    final objectEffect = Effect((_) => seen.add(old()));
    old.set(5);
    objectEffect.dispose();
    expect(seen, [3, 7, 4, 5]);
  });
}
