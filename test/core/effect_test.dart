import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('Effect', () {
    test('runs immediately on creation', () {
      int runCount = 0;
      effect(null, () {
        runCount++;
      });

      expect(runCount, equals(1));
    });

    test('tracks signal dependencies', () {
      int runCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        runCount++;
      });

      expect(runCount, equals(1));

      count(1);
      expect(runCount, equals(2));

      count(2);
      expect(runCount, equals(3));
    });

    test('stops when disposed', () {
      int runCount = 0;
      final count = signal(null, 0);

      final Effect(:dispose) = effect(null, () {
        count();
        runCount++;
      });

      expect(runCount, equals(1));

      count(1);
      expect(runCount, equals(2));

      dispose();

      count(2);
      expect(runCount, equals(2)); // Should not run after dispose
    });

    test('tracks multiple signals', () {
      int runCount = 0;
      final a = signal(null, 0);
      final b = signal(null, 0);

      effect(null, () {
        a();
        b();
        runCount++;
      });

      expect(runCount, equals(1));

      a(1);
      expect(runCount, equals(2));

      b(1);
      expect(runCount, equals(3));
    });

    test('tracks computed values', () {
      int runCount = 0;
      final count = signal(null, 5);
      final doubled = computed(null, (_) => count() * 2);

      effect(null, () {
        doubled();
        runCount++;
      });

      expect(runCount, equals(1));

      count(10);
      expect(runCount, equals(2));
    });

    test('onEffectDispose callback runs on dispose', () {
      bool disposed = false;
      final count = signal(null, 0);

      final Effect(:dispose) = effect(null, () {
        count();
        onEffectDispose(() {
          disposed = true;
        });
      });

      expect(disposed, isFalse);

      dispose();
      expect(disposed, isTrue);
    });

    test('onEffectCleanup runs before re-execution', () {
      int cleanupCount = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        onEffectCleanup(() {
          cleanupCount++;
        });
      });

      expect(cleanupCount, equals(0));

      count(1);
      expect(cleanupCount, equals(1));

      count(2);
      expect(cleanupCount, equals(2));
    });

    test('onEffectCleanup and onEffectDispose work together', () {
      int cleanupCount = 0;
      bool disposed = false;
      final count = signal(null, 0);

      final Effect(:dispose) = effect(null, () {
        count();
        onEffectCleanup(() {
          cleanupCount++;
        });
        onEffectDispose(() {
          disposed = true;
        });
      });

      expect(cleanupCount, equals(0));
      expect(disposed, isFalse);

      count(1);
      expect(cleanupCount, equals(1));
      expect(disposed, isFalse);

      dispose();
      expect(cleanupCount, equals(1)); // Cleanup doesn't run on dispose
      expect(disposed, isTrue);
    });

    test('conditional dependencies', () {
      int runCount = 0;
      final condition = signal(null, true);
      final a = signal(null, 1);
      final b = signal(null, 2);

      effect(null, () {
        condition() ? a() : b();
        runCount++;
      });

      expect(runCount, equals(1));

      a(10);
      expect(runCount, equals(2));

      b(20); // Should not trigger
      expect(runCount, equals(2));

      condition(false);
      expect(runCount, equals(3));

      a(30); // Should not trigger now
      expect(runCount, equals(3));

      b(40);
      expect(runCount, equals(4));
    });

    test('nested effects', () {
      int outerRuns = 0;
      int innerRuns = 0;
      final outer = signal(null, 0);
      final inner = signal(null, 0);

      effect(null, () {
        outer();
        outerRuns++;

        effect(null, () {
          inner();
          innerRuns++;
        });
      });

      expect(outerRuns, equals(1));
      expect(innerRuns, equals(1));

      inner(1);
      expect(outerRuns, equals(1));
      expect(innerRuns, equals(2));

      outer(1);
      expect(outerRuns, equals(2));
      expect(innerRuns, equals(3)); // New inner effect created
    });

    test('effect with detach option', () {
      int parentRuns = 0;
      int childRuns = 0;
      final parent = signal(null, 0);
      final child = signal(null, 0);

      effect(null, () {
        parent();
        parentRuns++;

        effect(null, () {
          child();
          childRuns++;
        }, detach: true);
      });

      expect(parentRuns, equals(1));
      expect(childRuns, equals(1));

      child(1);
      expect(childRuns, equals(2));

      parent(1);
      expect(parentRuns, equals(2));
      expect(childRuns, equals(3)); // New detached effect created
    });

    test('multiple effects on same signal', () {
      int effect1Count = 0;
      int effect2Count = 0;
      final count = signal(null, 0);

      effect(null, () {
        count();
        effect1Count++;
      });

      effect(null, () {
        count();
        effect2Count++;
      });

      expect(effect1Count, equals(1));
      expect(effect2Count, equals(1));

      count(1);
      expect(effect1Count, equals(2));
      expect(effect2Count, equals(2));
    });

    test('effect with side effects', () {
      final values = <int>[];
      final count = signal(null, 0);

      effect(null, () {
        values.add(count());
      });

      expect(values, equals([0]));

      count(1);
      expect(values, equals([0, 1]));

      count(2);
      expect(values, equals([0, 1, 2]));
    });
  });
}
