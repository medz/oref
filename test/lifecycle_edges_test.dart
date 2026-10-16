import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/preset.dart' as preset;
import 'package:oref/oref.dart';
import 'package:test/test.dart';

void main() {
  test('scope run drains children created after synchronous disposal', () {
    final scope = ReactiveScope();
    final source = Signal(0);
    var runs = 0, cleaned = 0;
    scope.run(() {
      scope.dispose();
      Effect((onCleanup) {
        source.value;
        runs++;
        onCleanup(() => cleaned++);
      });
    });
    expect(runs, 1); // Disposal does not abort remaining callback code.
    expect(cleaned, 1);
    expect(() => scope.run(() {}), throwsStateError);
    source.value = 1;
    expect(runs, 1);
  });

  test('scope run drains children after its parent is reentrantly rerun', () {
    final source = Signal(0);
    late ReactiveScope owned;
    var parentRuns = 0, childRuns = 0, cleaned = 0;
    final parent = Effect((_) {
      parentRuns++;
      owned = ReactiveScope();
    });
    final previous = owned;
    previous.run(() {
      source.value;
      source.value = 1;
      Effect((onCleanup) {
        source.value;
        childRuns++;
        onCleanup(() => cleaned++);
      });
    });
    expect(parentRuns, 2);
    expect(childRuns, 1);
    expect(cleaned, 1);
    expect(() => previous.run(() {}), throwsStateError);
    parent.dispose();
    source.value = 2;
    expect(childRuns, 1);
  });

  test('scope cleanup cannot reenter a stopped scope', () {
    final scope = ReactiveScope();
    var attempted = false;
    scope.run(() {
      Effect((onCleanup) {
        onCleanup(() {
          attempted = true;
          expect(() => scope.run(() {}), throwsStateError);
        });
      });
    });
    scope.dispose();
    expect(attempted, isTrue);
  });

  test('final drain error wins over callback error and restores context', () {
    final scope = ReactiveScope();
    final callbackError = StateError('callback');
    final cleanupError = StateError('cleanup');
    final previous = preset.getActiveSub();
    expect(
      () => scope.run(() {
        scope.dispose();
        Effect((onCleanup) {
          onCleanup(() => throw cleanupError);
        });
        throw callbackError;
      }),
      throwsA(same(cleanupError)),
    );
    expect(preset.getActiveSub(), same(previous));
    expect(() => scope.run(() {}), throwsStateError);
    scope.dispose();
  });

  test('recursive scope disposal does not unlink a new detached observer', () {
    final scope = ReactiveScope();
    final source = Signal(0);
    var runs = 0;
    late Effect detached;
    scope.run(() {
      source.value;
      Effect((onCleanup) {
        onCleanup(() {
          scope.dispose();
          detached = Effect((_) {
            source.value;
            runs++;
          });
        });
      });
    });
    scope.dispose();
    source.value = 1;
    expect(runs, 2);
    detached.dispose();
  });

  test('recursive parent effect disposal leaves detached observers intact', () {
    final source = Signal(0);
    var runs = 0;
    late Effect parent;
    late Effect detached;
    parent = Effect((_) {
      source.value;
      Effect((onCleanup) {
        onCleanup(() {
          parent.dispose();
          detached = Effect((_) {
            source.value;
            runs++;
          });
        });
      });
    });
    parent.dispose();
    source.value = 1;
    expect(runs, 2);
    detached.dispose();
  });

  test('external scope captures reads instead of the calling effect', () {
    final scope = ReactiveScope();
    final source = Signal(0);
    var parentRuns = 0;
    final parent = Effect((_) {
      parentRuns++;
      scope.run(() => source.value);
    });
    source.value = 1;
    expect(parentRuns, 1);
    parent.dispose();
    scope.dispose();
  });

  test('scope created in an effect propagates direct reads to that parent', () {
    final source = Signal(0);
    var parentRuns = 0;
    final parent = Effect((_) {
      parentRuns++;
      ReactiveScope().run(() => source.value);
    });
    source.value = 1;
    expect(parentRuns, 2);
    parent.dispose();
  });

  test('initial throwing run does not install registered cleanup', () {
    final scope = ReactiveScope();
    var cleaned = 0;
    final error = StateError('initial');
    expect(
      () => scope.run(() {
        Effect((onCleanup) {
          onCleanup(() => cleaned++);
          throw error;
        });
      }),
      throwsA(same(error)),
    );
    scope.dispose();
    expect(cleaned, 0);
  });

  test('throwing rerun does not install that runs registered cleanup', () {
    final source = Signal(0);
    final cleanups = <int>[];
    final error = StateError('rerun');
    final effect = Effect((onCleanup) {
      final value = source.value;
      onCleanup(() => cleanups.add(value));
      if (value == 1) throw error;
    });
    expect(() => source.value = 1, throwsA(same(error)));
    expect(cleanups, [0]);
    effect.dispose();
    expect(cleanups, [0]);
  });

  test(
    'self-disposal does not install unfinished cleanup before next dispose',
    () {
      final source = Signal(0);
      final cleanups = <int>[];
      late Effect effect;
      effect = Effect((onCleanup) {
        final value = source.value;
        onCleanup(() => cleanups.add(value));
        if (value == 1) effect.dispose();
      });
      source.value = 1;
      expect(cleanups, [0]); // The unfinished run returned cleanup after stop.
      effect.dispose(); // Explicitly drain that upstream slot for this test.
      expect(cleanups, [0, 1]);
    },
  );

  test('upstream effect errors interrupt the rest of a batch flush', () {
    final source = Signal(0);
    final error = StateError('effect');
    final first = Effect((_) {
      if (source.value == 1) throw error;
    });
    var secondRuns = 0;
    final second = Effect((_) {
      source.value;
      secondRuns++;
    });
    expect(
      () => batch(() {
        source.value = 1;
      }),
      throwsA(same(error)),
    );
    expect(secondRuns, 1);
    expect(preset.getBatchDepth(), 0);
    first.dispose();
    second.dispose();
  });

  test('reentrant computed disposal has the same known failure as upstream', () {
    // Pin the observed error boundary without pretending to fix the substrate.
    final source = Signal(false);
    late Effect parent;
    late ReactiveScope scope;
    final computed = Computed(() {
      if (source.value) parent.dispose();
      return source.value ? 1 : 0;
    });
    parent = Effect((_) {
      scope = ReactiveScope();
      scope.run(() => computed.value);
    });
    Object? wrappedError;
    try {
      source.value = true;
    } catch (error) {
      wrappedError = error;
    }
    scope.dispose();
    parent.dispose();

    final raw = alien.signal(false);
    late alien.Effect rawParent;
    late alien.EffectScope rawScope;
    final rawComputed = alien.computed((_) {
      if (raw()) rawParent();
      return raw() ? 1 : 0;
    });
    rawParent = alien.effect(() {
      rawScope = alien.effectScope(() {
        rawComputed();
      });
    });
    Object? rawError;
    try {
      raw.set(true);
    } catch (error) {
      rawError = error;
    }
    rawScope();
    rawParent();
    expect(wrappedError.runtimeType, rawError.runtimeType);
  });
}
