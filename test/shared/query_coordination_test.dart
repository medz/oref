import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/src/core/value.dart';
import 'package:oref/src/resources/resource.dart' as oref;
import 'package:oref/src/shared/shared.dart';

typedef _Model = ({int id, bool followed});

void main() {
  test(
    'a cancelling GET cannot make an accepted write publish an old source',
    () async {
      final source = Value(1);
      final writer = Completer<void>();
      final refreshResult = Completer<_Model>();
      var reads = 0;
      final writtenSources = <int>[];
      final query = oref.Query<int, _Model>(
        source: () => source.value,
        load: (id, request) {
          reads++;
          if (reads == 2) {
            request.onCancel(() => source.value = 2);
            return refreshResult.future;
          }
          return (id: id, followed: false);
        },
      );
      addTearDown(query.dispose);
      final field = query.fieldAck<bool>(
        select: (model) => model.followed,
        apply: (model, value) => (id: model.id, followed: value),
        write: (input, _) {
          writtenSources.add(input);
          return writer.future;
        },
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
      final write = field.set(true);
      final during = query.state.peek();
      writer.complete();
      expect(await write, isTrue);
      await interrupted;
      refreshResult.complete((id: 1, followed: false));
      expect(writtenSources, [1]);
      expect(during.source, 2);
      expect(during.hasValue, isFalse);
      expect((await query.ensureLoaded()).id, 2);
    },
  );

  test(
    'a source-clear listener can start the next read without being replaced',
    () async {
      final source = Value(1);
      final query = oref.Query<int, int>(
        source: () => source.value,
        load: (id, _) => id,
      );
      addTearDown(query.dispose);
      await query.ensureLoaded();
      Future<int>? fromListener;
      final subscription = query.state.subscribe(() {
        final state = query.state.peek();
        if (state.hasSource && state.source == 2 && !state.hasValue) {
          fromListener ??= query.ensureLoaded();
        }
      });
      addTearDown(subscription.dispose);
      source.value = 2;
      final joined = query.ensureLoaded();
      final reused = identical(fromListener, joined);
      expect(await joined, 2);
      expect(reused, isTrue);
      expect(await fromListener, 2);
    },
  );

  test('a writer source change does not start a new GET after the last lease leaves', () async {
    final source = Value(1);
    final written = Completer<void>();
    var reads = 0;
    final family = Family<int, oref.Query<int, _Model>>(
      create: (_) => oref.Query(
        source: () => source.value,
        load: (id, _) {
          reads++;
          return (id: id, followed: false);
        },
      ),
      dispose: (query) => query.dispose(),
    );
    final field = family.fieldAck<bool>(
      select: (model) => model.followed,
      apply: (model, value) => (id: model.id, followed: value),
      write: (_, _) => written.future,
    );
    final resources = Resources(
      namespace: () => null,
      maxIdle: 1,
      retain: const Duration(minutes: 1),
    );
    addTearDown(resources.dispose);
    final borrowed = borrowResource(resources, field(0));
    await borrowed.value.ensureLoaded();
    final write = borrowed.value.set(true);
    source.value = 2;
    borrowed.release();
    written.complete();
    expect(await write, isTrue);
    await Future<void>.value();
    final whileIdle = reads;
    final current = borrowResource(resources, family(0));
    expect((await current.value.ensureLoaded()).id, 2);
    current.release();
    expect(whileIdle, 1);
    expect(reads, 2);
  });
}
