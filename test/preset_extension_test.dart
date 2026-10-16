import 'package:alien_signals/preset.dart' as preset;
import 'package:alien_signals/system.dart' show ReactiveFlags;
import 'package:oref/oref.dart';
import 'package:test/test.dart';

// Deliberately test-only: one coarse dependency for the entire list, not a
// public collection API or a fine-grained index/key tracking design.
final class _ReactiveList<T> extends preset.SignalNode<List<T>> {
  _ReactiveList()
    : super(
        flags: ReactiveFlags.mutable,
        currentValue: <T>[],
        pendingValue: <T>[],
      ) {
    pendingValue = currentValue;
  }

  int get length => get().length;
  void add(T value) {
    pendingValue.add(value);
    trigger(() {
      get();
    });
  }
}

void main() {
  test('public values are preset nodes, without callable wrappers', () {
    final value = Signal(1);
    final computed = Computed(() => value.value + 1);
    expect(value, isA<preset.SignalNode<int>>());
    expect(computed, isA<preset.ComputedNode<int>>());
    expect(computed.value, 2);
    value.value = 2;
    expect(computed.value, 3);
  });

  test('trigger notifies identical collection values and computed readers', () {
    final list = Signal(<int>[]);
    final length = Computed(() => list.value.length);
    final seen = <int>[];
    final effect = Effect((_) {
      seen.add(length.value);
    });
    list.value.add(1);
    list.value = list.value;
    expect(seen, [0]);
    trigger(() {
      list.value;
    });
    expect(seen, [0, 1]);
    effect.dispose();
  });

  test('multiple reads and nested batches flush once', () {
    final value = Signal(1);
    var runs = 0;
    final effect = Effect((_) {
      value.value;
      runs++;
    });
    batch(() {
      trigger(() {
        value.value;
        value.value;
      });
      batch(() {
        trigger(() {
          value.value;
        });
      });
      expect(runs, 1);
    });
    expect(runs, 2);
    effect.dispose();
  });

  test('trigger reads do not subscribe the surrounding effect', () {
    final value = Signal(0);
    var runs = 0;
    final effect = Effect((_) {
      runs++;
      trigger(() {
        value.value;
      });
    });
    value.value = 1;
    expect(runs, 1);
    effect.dispose();
  });

  test('throwing callback still notifies and restores the subscriber', () {
    final value = Signal(0);
    var runs = 0;
    final effect = Effect((_) {
      value.value;
      runs++;
    });
    final before = preset.getActiveSub();
    expect(
      () => trigger(() {
        value.value;
        throw StateError('callback');
      }),
      throwsStateError,
    );
    expect(runs, 2);
    expect(preset.getActiveSub(), same(before));
    value.value = 1;
    expect(runs, 3);
    effect.dispose();
  });

  test('reading a computed selects it rather than its dependencies', () {
    final value = Signal(1);
    final doubled = Computed(() => value.value * 2);
    var sourceRuns = 0;
    var computedRuns = 0;
    final sourceEffect = Effect((_) {
      value.value;
      sourceRuns++;
    });
    final computedEffect = Effect((_) {
      doubled.value;
      computedRuns++;
    });
    trigger(() {
      doubled.value;
    });
    expect(sourceRuns, 1);
    expect(computedRuns, 2);
    sourceEffect.dispose();
    computedEffect.dispose();
  });

  test(
    'test-only preset collection interoperates with core and scope disposal',
    () {
      final list = _ReactiveList<int>();
      final length = Computed(() => list.length);
      final seen = <int>[];
      final scope = ReactiveScope();
      scope.run(() {
        Effect((_) {
          seen.add(length.value);
        });
      });
      list.add(1);
      batch(() {
        list.add(2);
        list.add(3);
      });
      expect(seen, [0, 1, 3]);
      scope.dispose();
      list.add(4);
      expect(seen, [0, 1, 3]);
      expect(length.value, 4);
    },
  );
}
