import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/src/core/value.dart';
import 'package:oref/src/resources/resource.dart' as oref;
import 'package:oref/src/shared/shared.dart';

typedef _Item = ({bool followed, String title});

void main() {
  test(
    'field references share the parent lease, view, read and idle entry',
    () async {
      var created = 0;
      var reads = 0;
      var disposed = 0;
      final family = Family<int, oref.Query<int, _Item>>(
        create: (id) {
          created++;
          return oref.Query(
            source: () => id,
            load: (_, _) {
              reads++;
              return (followed: false, title: 'one');
            },
          );
        },
        dispose: (query) {
          disposed++;
          query.dispose();
        },
      );
      final followed = family.fieldAck<bool>(
        select: (item) => item.followed,
        apply: (item, value) => (followed: value, title: item.title),
        write: (_, _) {},
      );
      final resources = Resources(
        namespace: () => null,
        maxIdle: 1,
        retain: const Duration(minutes: 1),
      );
      final detail = borrowResource(resources, family(1));
      final field = borrowResource(resources, followed(1));
      expect(await field.value.ensureLoaded(), isFalse);
      expect(await detail.value.ensureLoaded(), (
        followed: false,
        title: 'one',
      ));
      expect(reads, 1);
      detail.release();
      field.release();
      expect(disposed, 0);
      final next = borrowResource(resources, followed(1));
      expect(identical(next.value, field.value), isTrue);
      expect(await next.value.ensureLoaded(), isFalse);
      expect(created, 1);
      expect(reads, 1);
      next.release();
      resources.dispose();
      expect(disposed, 1);
    },
  );

  test(
    'a field write pins the parent without an extra directory entry',
    () async {
      final result = Completer<void>();
      var disposed = 0;
      final family = Family<int, oref.Query<int, _Item>>(
        create: (id) => oref.Query(
          source: () => id,
          load: (_, _) => (followed: false, title: 'one'),
        ),
        dispose: (query) {
          disposed++;
          query.dispose();
        },
      );
      final followed = family.fieldAck<bool>(
        select: (item) => item.followed,
        apply: (item, value) => (followed: value, title: item.title),
        write: (_, _) => result.future,
      );
      final resources = Resources(
        namespace: () => null,
        maxIdle: 0,
        retain: Duration.zero,
      );
      final first = borrowResource(resources, followed(1));
      await first.value.ensureLoaded();
      final written = first.value.set(true);
      first.release();
      expect(disposed, 0);
      final parent = borrowResource(resources, family(1));
      expect(parent.value.state.peek().value.followed, isTrue);
      final next = borrowResource(resources, followed(1));
      expect(identical(first.value, next.value), isTrue);
      expect(next.value.state.peek().pending, isTrue);
      parent.release();
      next.release();
      result.complete();
      expect(await written, isTrue);
      expect(disposed, 1);
      resources.dispose();
    },
  );

  test(
    'owner guard retires an old source before namespace effect order matters',
    () async {
      final identity = Value<Object>(Object());
      final readIdentities = <Object>[];
      oref.Query<Object, Object> create() => oref.Query(
        source: () => identity.value,
        load: (source, _) {
          readIdentities.add(source);
          return source;
        },
      );
      // This source subscribes before the directory subscribes to identity.
      final early = create();
      final firstIdentity = await early.ensureLoaded();
      var first = true;
      final family = Family<int, oref.Query<Object, Object>>(
        create: (_) {
          if (first) {
            first = false;
            return early;
          }
          return create();
        },
        dispose: (query) => query.dispose(),
      );
      final resources = Resources(
        namespace: () => identity.value,
        maxIdle: 2,
        retain: const Duration(minutes: 1),
      );
      final old = borrowResource(resources, family(1));
      final nextIdentity = Object();
      identity.value = nextIdentity;
      await Future<void>.value();
      expect(readIdentities, [firstIdentity]);
      expect(oref.resourceLifecycle(old.value).disposed, isTrue);
      final current = borrowResource(resources, family(1));
      expect(await current.value.ensureLoaded(), same(nextIdentity));
      expect(readIdentities, [firstIdentity, nextIdentity]);
      old.release();
      current.release();
      resources.dispose();
    },
  );

  test(
    'namespace failure cannot escape an earlier source notification',
    () async {
      final failed = Value(false);
      final identity = Object();
      final failure = StateError('namespace unavailable');
      final query = oref.Query<Object, int>(
        source: () {
          failed.value;
          return identity;
        },
        load: (_, _) => 1,
      );
      await query.ensureLoaded();
      final family = Family<int, oref.Query<Object, int>>(
        create: (_) => query,
        dispose: (value) => value.dispose(),
      );
      final resources = Resources(
        namespace: () {
          if (failed.value) throw failure;
          return identity;
        },
        maxIdle: 1,
        retain: const Duration(minutes: 1),
      );
      addTearDown(resources.dispose);
      final borrowed = borrowResource(resources, family(1));
      expect(() => failed.value = true, returnsNormally);
      expect(oref.resourceLifecycle(query).disposed, isTrue);
      await expectLater(
        resources.use(family(1), (_) => 1),
        throwsA(same(failure)),
      );
      borrowed.release();
    },
  );
}
