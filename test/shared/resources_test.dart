import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart' show Action, ResourceException, ResourceReason;
import 'package:oref/src/core/value.dart';
import 'package:oref/src/resources/resource.dart' as oref;
import 'package:oref/src/shared/shared.dart';

void main() {
  test(
    'a write accepted before binding still pins the shared instance',
    () async {
      final resources = Resources(
        namespace: () => null,
        maxIdle: 0,
        retain: Duration.zero,
      );
      addTearDown(resources.dispose);
      final gate = Completer<int>();
      var created = 0;
      var writes = 0;
      late Future<int> accepted;
      final family = Family<int, Action<int, int>>(
        create: (_) {
          created++;
          final action = Action<int, int>(
            execute: (_) {
              writes++;
              return gate.future;
            },
          );
          accepted = action.run(1);
          return action;
        },
        dispose: (action) => action.dispose(),
      );
      final first = borrowResource(resources, family(1));
      first.release();
      final second = borrowResource(resources, family(1));
      expect(second.value, same(first.value));
      expect(created, 1);
      await expectLater(
        second.value.run(2),
        throwsA(
          isA<ResourceException>().having(
            (error) => error.reason,
            'reason',
            ResourceReason.busy,
          ),
        ),
      );
      expect(writes, 1);
      gate.complete(7);
      expect(await accepted, 7);
      second.release();
    },
  );

  Resources directory({int maxIdle = 4, Duration? retain}) => Resources(
    namespace: () => null,
    maxIdle: maxIdle,
    retain: retain ?? const Duration(minutes: 1),
  );

  test('cache limits are explicit, nonnegative, and accept zero', () {
    expect(() => directory(maxIdle: -1), throwsArgumentError);
    expect(
      () => directory(retain: const Duration(microseconds: -1)),
      throwsArgumentError,
    );
    directory(maxIdle: 0, retain: Duration.zero).dispose();
  });

  test('references are lazy and compare family, key and field identity', () {
    var created = 0;
    final family = Family<(int, String), oref.Query<int, int>>(
      create: (key) {
        created++;
        return oref.Query(source: () => key.$1, load: (id, _) => id);
      },
      dispose: (query) => query.dispose(),
    );
    final same = family((1, 'one'));
    expect(created, 0);
    expect(same, family((1, 'one')));
    expect(same.hashCode, family((1, 'one')).hashCode);
    expect(same, isNot(family((2, 'one'))));
    final fields = family.fieldAck<int>(
      select: (value) => value,
      apply: (_, value) => value,
      write: (_, _) {},
    );
    final otherFields = family.fieldAck<int>(
      select: (value) => value,
      apply: (_, value) => value,
      write: (_, _) {},
    );
    expect(fields((1, 'one')), fields((1, 'one')));
    expect(fields((1, 'one')), isNot(otherFields((1, 'one'))));
    expect(created, 0);
  });

  test('same keys share, independent families and directories do not', () {
    var created = 0;
    Family<int, oref.Query<int, int>> definition() => Family(
      create: (id) {
        created++;
        return oref.Query(source: () => id, load: (id, _) => id);
      },
      dispose: (query) => query.dispose(),
    );
    final family = definition();
    final first = directory();
    final second = directory();
    final a = borrowResource(first, family(1));
    final b = borrowResource(first, family(1));
    final c = borrowResource(second, family(1));
    final d = borrowResource(first, definition()(1));
    expect(identical(a.value, b.value), isTrue);
    expect(identical(a.value, c.value), isFalse);
    expect(identical(a.value, d.value), isFalse);
    expect(created, 3);
    a.release();
    a.release();
    b.release();
    c.release();
    d.release();
    first.dispose();
    second.dispose();
  });

  test(
    'a factory cannot take another directory instance or close its owner',
    () async {
      final query = oref.Query<int, int>(source: () => 1, load: (id, _) => id);
      var disposed = 0;
      final family = Family<int, oref.Query<int, int>>(
        create: (_) => query,
        dispose: (value) {
          disposed++;
          value.dispose();
        },
      );
      final first = directory();
      final second = directory();
      final owned = borrowResource(first, family(1));
      expect(() => borrowResource(second, family(1)), throwsStateError);
      expect(disposed, 0);
      expect(await owned.value.ensureLoaded(), 1);
      owned.release();
      second.dispose();
      expect(disposed, 0);
      first.dispose();
      expect(disposed, 1);
    },
  );

  test(
    'use holds through await and releases even after callback errors',
    () async {
      var disposed = 0;
      final family = Family<int, oref.Query<int, int>>(
        create: (id) => oref.Query(source: () => id, load: (id, _) => id),
        dispose: (query) {
          disposed++;
          query.dispose();
        },
      );
      final resources = directory(maxIdle: 0);
      final gate = Completer<void>();
      late oref.Query<int, int> held;
      final error = StateError('callback');
      final use = resources.use(family(1), (query) async {
        held = query;
        await gate.future;
        throw error;
      });
      final other = borrowResource(resources, family(1));
      expect(identical(held, other.value), isTrue);
      other.release();
      expect(disposed, 0);
      final failed = expectLater(use, throwsA(same(error)));
      gate.complete();
      await failed;
      expect(disposed, 1);
      resources.dispose();
    },
  );

  test(
    'same-key recursive construction fails before a second factory call',
    () {
      final resources = directory();
      var creations = 0;
      late Family<int, oref.Query<int, int>> family;
      family = Family(
        create: (id) {
          creations++;
          borrowResource(resources, family(id));
          return oref.Query(source: () => id, load: (id, _) => id);
        },
        dispose: (query) => query.dispose(),
      );
      expect(() => borrowResource(resources, family(1)), throwsStateError);
      expect(creations, 1);
      resources.dispose();
    },
  );

  test('a factory namespace change cannot overwrite a new namespace entry', () {
    final namespace = Value(0);
    final resources = Resources(
      namespace: () => namespace.value,
      maxIdle: 2,
      retain: const Duration(minutes: 1),
    );
    late Family<int, oref.Query<int, int>> family;
    late ({oref.Query<int, int> value, void Function() release}) current;
    var first = true;
    var disposed = 0;
    family = Family(
      create: (id) {
        final query = oref.Query<int, int>(
          source: () => id,
          load: (id, _) => id,
        );
        if (first) {
          first = false;
          namespace.value = 1;
          current = borrowResource(resources, family(id));
        }
        return query;
      },
      dispose: (query) {
        disposed++;
        query.dispose();
      },
    );
    expect(
      () => borrowResource(resources, family(1)),
      throwsA(
        isA<oref.ResourceException>().having(
          (error) => error.reason,
          'reason',
          oref.ResourceReason.sourceChanged,
        ),
      ),
    );
    expect(disposed, 1);
    final again = borrowResource(resources, family(1));
    expect(identical(current.value, again.value), isTrue);
    current.release();
    again.release();
    resources.dispose();
    expect(disposed, 2);
  });

  for (final zero in ['capacity', 'retention']) {
    test('zero $zero does not cache idle resources', () {
      var created = 0;
      var disposed = 0;
      final family = Family<int, oref.Query<int, int>>(
        create: (id) {
          created++;
          return oref.Query(source: () => id, load: (id, _) => id);
        },
        dispose: (query) {
          disposed++;
          query.dispose();
        },
      );
      final resources = directory(
        maxIdle: zero == 'capacity' ? 0 : 2,
        retain: zero == 'retention' ? Duration.zero : null,
      );
      borrowResource(resources, family(1)).release();
      expect(disposed, 1);
      borrowResource(resources, family(1)).release();
      expect(created, 2);
      expect(disposed, 2);
      resources.dispose();
    });
  }

  test('LRU evicts idle entries while active entries stay alive', () {
    final disposed = <int>[];
    final family = Family<int, oref.Query<int, int>>(
      create: (id) => oref.Query(source: () => id, load: (id, _) => id),
      dispose: (query) {
        disposed.add(
          query.state.peek().hasSource ? query.state.peek().source : -1,
        );
        query.dispose();
      },
    );
    final resources = directory(maxIdle: 2);
    final active = borrowResource(resources, family(9));
    final first = borrowResource(resources, family(1));
    final second = borrowResource(resources, family(2));
    first.release();
    second.release();
    final again = borrowResource(resources, family(1));
    expect(identical(first.value, again.value), isTrue);
    again.release();
    borrowResource(resources, family(3)).release();
    expect(oref.resourceLifecycle(second.value).disposed, isTrue);
    expect(oref.resourceLifecycle(first.value).disposed, isFalse);
    expect(oref.resourceLifecycle(active.value).disposed, isFalse);
    expect(disposed.length, 1);
    active.release();
    resources.dispose();
  });

  test('idle entries expire without another lookup', () async {
    var disposed = 0;
    final family = Family<int, oref.Query<int, int>>(
      create: (id) => oref.Query(source: () => id, load: (id, _) => id),
      dispose: (query) {
        disposed++;
        query.dispose();
      },
    );
    final resources = directory(retain: const Duration(milliseconds: 15));
    final borrowed = borrowResource(resources, family(1));
    borrowed.release();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(disposed, 1);
    expect(oref.resourceLifecycle(borrowed.value).disposed, isTrue);
    resources.dispose();
  });

  test('only one expiry timer is active for the entire directory', () {
    var active = 0;
    var peak = 0;
    runZoned(
      () {
        final resources = directory(maxIdle: 100);
        final family = Family<int, oref.Query<int, int>>(
          create: (id) => oref.Query(source: () => id, load: (id, _) => id),
          dispose: (query) => query.dispose(),
        );
        for (var id = 0; id < 100; id++) {
          borrowResource(resources, family(id)).release();
        }
        expect(active, 1);
        expect(peak, 1);
        resources.dispose();
        expect(active, 0);
      },
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, callback) {
          active++;
          if (active > peak) peak = active;
          late _CountedTimer timer;
          timer = _CountedTimer(
            parent.createTimer(zone, duration, () {
              timer.finish();
              callback();
            }),
            () => active--,
          );
          return timer;
        },
      ),
    );
  });

  test('idle sources pause and resume from their latest input', () async {
    final source = Value(1);
    var loads = 0;
    final family = Family<int, oref.Query<int, int>>(
      create: (_) => oref.Query(
        source: () => source.value,
        load: (id, _) {
          loads++;
          return id;
        },
      ),
      dispose: (query) => query.dispose(),
    );
    final resources = directory();
    final first = borrowResource(resources, family(0));
    expect(await first.value.ensureLoaded(), 1);
    first.release();
    source.value = 2;
    await Future<void>.value();
    expect(loads, 1);
    final next = borrowResource(resources, family(0));
    expect(identical(first.value, next.value), isTrue);
    expect(await next.value.ensureLoaded(), 2);
    expect(loads, 2);
    next.release();
    resources.dispose();
  });

  test('an idle read may finish inside the retention window', () async {
    final result = Completer<int>();
    var loads = 0;
    final family = Family<int, oref.Query<int, int>>(
      create: (id) => oref.Query(
        source: () => id,
        load: (_, _) {
          loads++;
          return result.future;
        },
      ),
      dispose: (query) => query.dispose(),
    );
    final resources = directory();
    final first = borrowResource(resources, family(1));
    final loaded = first.value.ensureLoaded();
    first.release();
    result.complete(7);
    expect(await loaded, 7);
    final next = borrowResource(resources, family(1));
    expect(await next.value.ensureLoaded(), 7);
    expect(loads, 1);
    next.release();
    resources.dispose();
  });

  test(
    'accepted writes pin the same instance after all borrowers leave',
    () async {
      final result = Completer<int>();
      var disposed = 0;
      final family = Family<int, oref.Action<int, int>>(
        create: (_) => oref.Action(execute: (_) => result.future),
        dispose: (action) {
          disposed++;
          action.dispose();
        },
      );
      final resources = directory(maxIdle: 0);
      final first = borrowResource(resources, family(1));
      final write = first.value.run(1);
      first.release();
      expect(disposed, 0);
      final next = borrowResource(resources, family(1));
      expect(identical(first.value, next.value), isTrue);
      await expectLater(
        next.value.run(2),
        throwsA(
          isA<oref.ResourceException>().having(
            (error) => error.reason,
            'reason',
            oref.ResourceReason.busy,
          ),
        ),
      );
      next.release();
      result.complete(9);
      expect(await write, 9);
      expect(disposed, 1);
      resources.dispose();
    },
  );

  test(
    'namespace changes retire old state and accepted writes still settle',
    () async {
      final namespace = Value<Object>(Object());
      final result = Completer<int>();
      final family = Family<int, oref.Action<int, int>>(
        create: (_) => oref.Action(execute: (_) => result.future),
        dispose: (action) => action.dispose(),
      );
      final resources = Resources(
        namespace: () => namespace.value,
        maxIdle: 0,
        retain: Duration.zero,
      );
      final first = borrowResource(resources, family(1));
      final write = first.value.run(1);
      namespace.value = Object();
      final next = borrowResource(resources, family(1));
      expect(identical(first.value, next.value), isFalse);
      expect(oref.resourceLifecycle(first.value).disposed, isTrue);
      first.release();
      result.complete(8);
      expect(await write, 8);
      next.release();
      resources.dispose();
    },
  );

  test(
    'namespace failure and recovery notify and do not revive old entries',
    () async {
      final fail = Value(false);
      final identity = Object();
      final failure = StateError('namespace');
      final resources = Resources(
        namespace: () {
          if (fail.value) throw failure;
          return identity;
        },
        maxIdle: 2,
        retain: const Duration(minutes: 1),
      );
      final family = Family<int, oref.Query<int, int>>(
        create: (id) => oref.Query(source: () => id, load: (id, _) => id),
        dispose: (query) => query.dispose(),
      );
      var notifications = 0;
      final subscription = resourcesRevision(resources).subscribe(() {
        notifications++;
      });
      final first = borrowResource(resources, family(1));
      fail.value = true;
      await expectLater(
        resources.use(family(1), (_) => 1),
        throwsA(same(failure)),
      );
      expect(oref.resourceLifecycle(first.value).disposed, isTrue);
      fail.value = false;
      final next = borrowResource(resources, family(1));
      expect(identical(first.value, next.value), isFalse);
      expect(notifications, 2);
      first.release();
      next.release();
      subscription.dispose();
      resources.dispose();
    },
  );

  test('closed directories do not evaluate namespace or accept work', () async {
    var reads = 0;
    final resources = Resources(
      namespace: () => reads++,
      maxIdle: 0,
      retain: Duration.zero,
    );
    final family = Family<int, oref.Query<int, int>>(
      create: (id) => oref.Query(source: () => id, load: (id, _) => id),
      dispose: (query) => query.dispose(),
    );
    resources.dispose();
    final before = reads;
    await expectLater(
      resources.use(family(1), (_) => 1),
      throwsA(
        isA<oref.ResourceException>().having(
          (error) => error.reason,
          'reason',
          oref.ResourceReason.disposed,
        ),
      ),
    );
    expect(reads, before);
    resources.dispose();
  });
}

final class _CountedTimer implements Timer {
  _CountedTimer(this._timer, this._onFinish);
  final Timer _timer;
  final void Function() _onFinish;
  bool _finished = false;

  void finish() {
    if (_finished) return;
    _finished = true;
    _onFinish();
  }

  @override
  void cancel() {
    _timer.cancel();
    finish();
  }

  @override
  bool get isActive => _timer.isActive;

  @override
  int get tick => _timer.tick;
}
