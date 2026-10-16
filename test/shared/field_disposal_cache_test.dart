import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/src/resources/resource.dart' as oref;
import 'package:oref/src/shared/shared.dart';

typedef _Model = ({bool followed, int count});

void main() {
  test('disposing a derived view recreates its view without bypassing the parent lock', () async {
    final writer = Completer<void>();
    var writes = 0;
    final family = Family<int, oref.Query<int, _Model>>(
      create: (id) => oref.Query(
        source: () => id,
        load: (_, _) => (followed: false, count: 1),
      ),
      dispose: (query) => query.dispose(),
    );
    final field = family.fieldAck<bool>(
      select: (model) => model.followed,
      apply: (model, value) => (followed: value, count: model.count),
      write: (_, _) {
        writes++;
        return writer.future;
      },
    );
    final resources = Resources(
      namespace: () => null,
      maxIdle: 1,
      retain: const Duration(minutes: 1),
    );
    addTearDown(resources.dispose);
    final first = borrowResource(resources, field(1));
    await first.value.ensureLoaded();
    final write = first.value.set(true);
    first.value.dispose();
    final next = borrowResource(resources, field(1));
    expect(identical(first.value, next.value), isFalse);
    expect(next.value.state.peek().pending, isTrue);
    await expectLater(
      next.value.set(false),
      throwsA(
        isA<oref.ResourceException>().having(
          (error) => error.reason,
          'reason',
          oref.ResourceReason.busy,
        ),
      ),
    );
    writer.complete();
    expect(await write, isTrue);
    expect(next.value.state.peek().pending, isFalse);
    expect(next.value.state.peek().value, isTrue);
    expect(writes, 1);
    first.release();
    next.release();
  });

  test(
    'a failed field write restores the previous failed GET future',
    () async {
      final getError = StateError('GET');
      final postError = StateError('POST');
      var failGet = false;
      final query = oref.Query<int, _Model>(
        source: () => 1,
        load: (_, _) {
          if (failGet) throw getError;
          return (followed: false, count: 1);
        },
      );
      addTearDown(query.dispose);
      final field = query.fieldAck<bool>(
        select: (model) => model.followed,
        apply: (model, value) => (followed: value, count: model.count),
        write: (_, _) => throw postError,
      );
      await field.ensureLoaded();
      failGet = true;
      final failedGet = query.refresh();
      await expectLater(failedGet, throwsA(same(getError)));
      await expectLater(field.set(true), throwsA(same(postError)));
      final restored = query.ensureLoaded();
      final sameAttempt = identical(failedGet, restored);
      await expectLater(restored, throwsA(same(getError)));
      expect(sameAttempt, isTrue);
      expect(query.state.peek().error, same(getError));
      expect(field.state.peek().error, same(postError));
    },
  );

  test(
    'a failed write does not restore its cancelled pending GET future',
    () async {
      final get = Completer<_Model>();
      final postError = StateError('POST');
      var reads = 0;
      final query = oref.Query<int, _Model>(
        source: () => 1,
        load: (_, _) {
          reads++;
          if (reads == 2) return get.future;
          return (followed: false, count: 1);
        },
      );
      addTearDown(query.dispose);
      final field = query.fieldAck<bool>(
        select: (model) => model.followed,
        apply: (model, value) => (followed: value, count: model.count),
        write: (_, _) => throw postError,
      );
      await field.ensureLoaded();
      final refresh = query.refresh();
      final interrupted = expectLater(
        refresh,
        throwsA(
          isA<oref.ResourceException>().having(
            (error) => error.reason,
            'reason',
            oref.ResourceReason.superseded,
          ),
        ),
      );
      await Future<void>.value();
      await expectLater(field.set(true), throwsA(same(postError)));
      await interrupted;
      get.complete((followed: false, count: 1));
      final restored = query.ensureLoaded();
      expect(identical(restored, refresh), isFalse);
      expect(await restored, (followed: false, count: 1));
    },
  );
}
