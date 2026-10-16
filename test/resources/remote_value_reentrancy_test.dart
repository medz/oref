import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';
import 'package:oref/src/resources/resource.dart' show resourceLifecycle;

void main() {
  for (final throwsAfterDispose in [false, true]) {
    test(
      'a historical projection settles once when disposed (throws=$throwsAfterDispose)',
      () async {
        final query = Query<int, int>(source: () => 1, load: (_, _) => 10);
        addTearDown(query.dispose);
        await query.ensureLoaded();
        var disposeHistorical = false;
        late RemoteValue<int, int> field;
        field = query.fieldAck<int>(
          select: (value) {
            if (disposeHistorical && value == 10) {
              field.dispose();
              if (throwsAfterDispose) throw StateError('historical projection');
            }
            return value;
          },
          apply: (_, value) => value,
          write: (_, _) {},
        );
        final result = field.ensureLoaded();
        final rejected = expectLater(
          result,
          throwsA(
            isA<ResourceException>().having(
              (error) => error.reason,
              'reason',
              ResourceReason.disposed,
            ),
          ),
        );
        disposeHistorical = true;
        field.accept(const Seed(source: 1, value: 20));
        await rejected;
        await Future<void>.delayed(Duration.zero);
        expect(field.state.peek().value, 20);
      },
    );
  }

  test('a field selector cannot publish after disposing its view', () async {
    final query = Query<int, int>(source: () => 1, load: (_, _) => 10);
    addTearDown(query.dispose);
    late RemoteValue<int, int> field;
    late RemoteState<int, int> last;
    field = query.fieldAck<int>(
      select: (value) {
        last = field.state.peek();
        field.dispose();
        return value;
      },
      apply: (_, value) => value,
      write: (_, _) {},
    );

    await query.ensureLoaded();
    expect(field.state.peek(), same(last));
    expect(field.state.peek().hasValue, isFalse);
  });

  test(
    'a field selector cannot overwrite a reentrant accepted model',
    () async {
      final query = Query<int, int>(source: () => 1, load: (_, _) => 10);
      addTearDown(query.dispose);
      var selections = 0;
      late RemoteValue<int, int> field;
      field = query.fieldAck<int>(
        select: (value) {
          selections++;
          if (value == 10) field.accept(const Seed(source: 1, value: 20));
          return value;
        },
        apply: (_, value) => value,
        write: (_, _) {},
      );

      await query.ensureLoaded();
      expect(query.state.peek().value, 20);
      expect(field.state.peek().value, 20);
      expect(await field.ensureLoaded(), 20);
      expect(selections, 2);
    },
  );

  test('a reentrant refresh keeps a completed projection cached', () async {
    final query = Query<int, int>(source: () => 1, load: (_, _) => 10);
    addTearDown(query.dispose);
    var selections = 0;
    Future<int>? refreshed;
    final field = query.fieldAck<int>(
      select: (value) {
        selections++;
        refreshed = query.refresh();
        return value;
      },
      apply: (_, value) => value,
      write: (_, _) {},
    );

    await query.ensureLoaded();
    await refreshed;
    expect(field.state.peek().value, 10);
    expect(await field.ensureLoaded(), 10);
    expect(selections, 1);
  });

  test('an idle writer retains token revalidation for the next read', () async {
    final source = Value((id: 1, token: 'old'));
    final gate = Completer<int>();
    final reads = <String>[];
    final remote = RemoteValue<({int id, String token}), int>(
      source: () => source.value,
      identity: (input) => input.id,
      initial: const Seed(source: (id: 1, token: 'old'), value: 10),
      read: (input, _) {
        reads.add(input.token);
        return 30;
      },
      write: (_, _) => gate.future,
    );
    addTearDown(remote.dispose);
    await remote.ensureLoaded();
    final write = remote.set(20);
    source.value = (id: 1, token: 'new');
    resourceLifecycle(remote).pauseSource();
    gate.complete(21);
    expect(await write, 21);
    expect(reads, isEmpty);
    expect(remote.state.peek().value, 21);

    resourceLifecycle(remote).resumeSource();
    expect(await remote.ensureLoaded(), 30);
    expect(reads, ['new']);
  });
}
