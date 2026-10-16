import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

typedef Model = ({bool? followed, int count});
Matcher reason(ResourceReason reason) =>
    isA<ResourceException>().having((error) => error.reason, 'reason', reason);
Future<void> flush() => Future<void>.delayed(Duration.zero);

RemoteValue<S, bool> followField<S>(
  Query<S, Model> parent,
  FutureOr<void> Function(S, bool) write,
) => parent.fieldAck<bool>(
  select: (model) => model.followed ?? (throw StateError('unknown')),
  apply: (model, desired) => (followed: desired, count: model.count),
  write: write,
);

void main() {
  for (final duringApply in [false, true]) {
    test(
      'a field callback ResourceException is a recorded failure (apply=$duringApply)',
      () async {
        const failure = ResourceException(ResourceReason.busy);
        final stack = StackTrace.current;
        var writes = 0;
        final query = Query<int, int>(source: () => 1, load: (_, _) => 10);
        addTearDown(query.dispose);
        final field = query.fieldAck<int>(
          select: (model) => model,
          apply: (_, value) =>
              duringApply ? Error.throwWithStackTrace(failure, stack) : value,
          write: (_, _) {
            writes++;
          },
        );
        await field.ensureLoaded();
        final result = duringApply
            ? field.set(11)
            : field.update((_) => Error.throwWithStackTrace(failure, stack));
        await result.then<void>(
          (_) => fail('Expected the callback error'),
          onError: (Object error, StackTrace trace) {
            expect(error, same(failure));
            expect(trace.toString(), stack.toString());
          },
        );
        expect(field.state.peek().error, same(failure));
        expect(field.state.peek().stackTrace.toString(), stack.toString());
        expect(field.state.peek().value, 10);
        expect(field.state.peek().pending, isFalse);
        expect(query.state.peek().error, isNull);
        expect(writes, 0);
      },
    );
  }

  test(
    'a failed field transform cannot publish its error into a new source',
    () async {
      var source = 1;
      final failure = StateError('old transform');
      final query = Query<int, int>(
        source: () => source,
        load: (input, _) => input,
      );
      addTearDown(query.dispose);
      final field = query.fieldAck<int>(
        select: (model) => model,
        apply: (_, value) => value,
        write: (_, _) {},
      );
      await field.ensureLoaded();
      await expectLater(
        field.update((_) {
          source = 2;
          throw failure;
        }),
        throwsA(same(failure)),
      );
      expect(field.state.peek().source, 2);
      expect(field.state.peek().hasValue, isFalse);
      expect(field.state.peek().error, isNull);
    },
  );

  test(
    'an accepted writer preserves a delegated ResourceException as its error',
    () async {
      const failure = ResourceException(ResourceReason.busy);
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, _) => (followed: false, count: 1),
      );
      addTearDown(query.dispose);
      final follow = followField(query, (_, _) => throw failure);
      await follow.ensureLoaded();
      await expectLater(follow.set(true), throwsA(same(failure)));
      expect(query.state.peek().value.followed, isFalse);
      expect(query.state.peek().error, isNull);
      expect(follow.state.peek().error, same(failure));
    },
  );

  test(
    'one read supplies parent and field; projection futures are cached',
    () async {
      var reads = 0;
      var selections = 0;
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, _) {
          reads++;
          return (followed: false, count: 4);
        },
      );
      addTearDown(query.dispose);
      final follow = query.fieldAck<bool>(
        select: (model) {
          selections++;
          return model.followed!;
        },
        apply: (model, value) => (followed: value, count: model.count),
        write: (_, _) {},
      );
      final first = follow.ensureLoaded();
      expect(identical(first, follow.ensureLoaded()), isTrue);
      await query.ensureLoaded();
      expect(await first, isFalse);
      expect(identical(first, follow.ensureLoaded()), isTrue);
      expect(reads, 1);
      expect(selections, 1);
    },
  );

  test('optimism, ack and rollback update the one parent model', () async {
    final responses = <Completer<void>>[];
    final failure = StateError('write');
    final query = Query<int, Model>(
      source: () => 1,
      load: (_, _) => (followed: false, count: 7),
    );
    addTearDown(query.dispose);
    final follow = followField(query, (_, _) {
      final response = Completer<void>();
      responses.add(response);
      return response.future;
    });
    await follow.ensureLoaded();
    final first = follow.update((value) => !value);
    expect(query.state.peek().value, (followed: true, count: 7));
    expect(follow.state.peek().value, isTrue);
    expect(follow.state.peek().pending, isTrue);
    await flush();
    responses[0].complete();
    expect(await first, isTrue);
    expect((await query.ensureLoaded()).followed, isTrue);
    expect(await follow.ensureLoaded(), isTrue);
    final second = follow.set(false);
    final rejected = expectLater(second, throwsA(same(failure)));
    expect(query.state.peek().value.followed, isFalse);
    await flush();
    responses[1].completeError(failure);
    await rejected;
    expect(query.state.peek().value.followed, isTrue);
    expect(follow.state.peek().value, isTrue);
    expect(follow.state.peek().pending, isFalse);
    expect(follow.state.peek().error, same(failure));
    expect(query.state.peek().error, isNull);
  });

  test(
    'all fields share a lock; writes and reads reject busy without HTTP',
    () async {
      var reads = 0;
      var writes = 0;
      final response = Completer<void>();
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, _) {
          reads++;
          return (followed: false, count: 1);
        },
      );
      addTearDown(query.dispose);
      final follow = followField(query, (_, _) {
        writes++;
        return response.future;
      });
      final count = query.fieldAck<int>(
        select: (m) => m.count,
        apply: (m, v) => (followed: m.followed, count: v),
        write: (_, _) {
          writes++;
        },
      );
      await follow.ensureLoaded();
      final pending = follow.set(true);
      expect(count.state.peek().pending, isTrue);
      await expectLater(count.set(2), throwsA(reason(ResourceReason.busy)));
      await expectLater(follow.set(true), throwsA(reason(ResourceReason.busy)));
      await expectLater(query.refresh(), throwsA(reason(ResourceReason.busy)));
      await expectLater(follow.refresh(), throwsA(reason(ResourceReason.busy)));
      await expectLater(
        query.ensureLoaded(),
        throwsA(reason(ResourceReason.busy)),
      );
      expect(reads, 1);
      expect(writes, 1);
      response.complete();
      await pending;
    },
  );

  test(
    'a write supersedes pending GET and late data cannot overwrite it',
    () async {
      var reads = 0;
      final oldRead = Completer<Model>();
      final ack = Completer<void>();
      late ReadRequest request;
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, read) {
          reads++;
          if (reads == 1) return (followed: false, count: 1);
          request = read;
          return oldRead.future;
        },
      );
      addTearDown(query.dispose);
      final follow = followField(query, (_, _) => ack.future);
      await follow.ensureLoaded();
      final refreshing = query.refresh();
      final superseded = expectLater(
        refreshing,
        throwsA(reason(ResourceReason.superseded)),
      );
      await flush();
      final write = follow.set(true);
      expect(request.cancelled, isTrue);
      ack.complete();
      await write;
      await superseded;
      oldRead.complete((followed: false, count: 50));
      await flush();
      expect(query.state.peek().value, (followed: true, count: 1));
      expect((await query.ensureLoaded()).followed, isTrue);
      expect(reads, 2);
    },
  );

  test(
    'unknown projection does not fail parent or automatically retry',
    () async {
      var reads = 0;
      var writes = 0;
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, _) {
          reads++;
          return (followed: null, count: 1);
        },
      );
      addTearDown(query.dispose);
      final follow = followField(query, (_, _) {
        writes++;
      });
      final unknown = follow.ensureLoaded();
      await expectLater(unknown, throwsStateError);
      expect(identical(unknown, follow.ensureLoaded()), isTrue);
      expect(query.state.peek().hasValue, isTrue);
      expect(query.state.peek().error, isNull);
      expect(follow.state.peek().hasValue, isFalse);
      var transformed = false;
      await expectLater(
        follow.update((value) {
          transformed = true;
          return !value;
        }),
        throwsA(reason(ResourceReason.notReady)),
      );
      expect(transformed, isFalse);
      expect(reads, 1);
      expect(writes, 0);
      expect(await follow.set(true), isTrue);
      expect(query.state.peek().value.followed, isTrue);
      expect(reads, 1);
      expect(writes, 1);
    },
  );

  test('unknown explicit set rolls back to unknown on failure', () async {
    final failure = StateError('write');
    final query = Query<int, Model>(
      source: () => 1,
      load: (_, _) => (followed: null, count: 1),
    );
    addTearDown(query.dispose);
    final follow = followField(query, (_, _) => throw failure);
    await query.ensureLoaded();
    await expectLater(follow.set(true), throwsA(same(failure)));
    expect(query.state.peek().value.followed, isNull);
    expect(follow.state.peek().hasValue, isFalse);
  });

  test('idle equal value skips apply and POST', () async {
    var applies = 0;
    var writes = 0;
    final query = Query<int, Model>(
      source: () => 1,
      load: (_, _) => (followed: false, count: 1),
    );
    addTearDown(query.dispose);
    final follow = query.fieldAck<bool>(
      select: (m) => m.followed!,
      apply: (m, v) {
        applies++;
        return (followed: v, count: m.count);
      },
      write: (_, _) {
        writes++;
      },
    );
    await follow.ensureLoaded();
    expect(await follow.set(false), isFalse);
    expect(applies, 0);
    expect(writes, 0);
  });

  test(
    'a parent model is required and update never implicitly reads',
    () async {
      var reads = 0;
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, _) {
          reads++;
          return (followed: false, count: 1);
        },
      );
      addTearDown(query.dispose);
      final follow = followField(query, (_, _) {});
      await expectLater(
        follow.set(true),
        throwsA(reason(ResourceReason.notReady)),
      );
      await expectLater(
        follow.update((v) => !v),
        throwsA(reason(ResourceReason.notReady)),
      );
      expect(reads, 0);
    },
  );

  test(
    'canonical values replace preview; canonical apply errors roll back',
    () async {
      var broken = false;
      final failure = StateError('apply');
      final query = Query<int, int>(source: () => 1, load: (_, _) => 1);
      addTearDown(query.dispose);
      final remote = query.field<int>(
        select: (v) => v,
        apply: (_, v) {
          if (broken && v == 3) throw failure;
          return v;
        },
        write: (_, _) => 3,
      );
      await remote.ensureLoaded();
      expect(await remote.set(2), 3);
      expect(query.state.peek().value, 3);
      broken = true;
      await expectLater(remote.set(4), throwsA(same(failure)));
      expect(query.state.peek().value, 3);
      expect(remote.state.peek().pending, isFalse);
    },
  );

  test('cross-field preparation reentry is busy and does not write', () async {
    final query = Query<int, Model>(
      source: () => 1,
      load: (_, _) => (followed: false, count: 1),
    );
    addTearDown(query.dispose);
    final follow = followField(query, (_, _) {});
    var otherWrites = 0;
    final count = query.fieldAck<int>(
      select: (m) => m.count,
      apply: (m, v) => (followed: m.followed, count: v),
      write: (_, _) {
        otherWrites++;
      },
    );
    await query.ensureLoaded();
    Future<void>? rejected;
    await follow.update((value) {
      rejected = expectLater(
        count.set(2),
        throwsA(reason(ResourceReason.busy)),
      );
      return !value;
    });
    await rejected;
    expect(otherWrites, 0);
    expect(query.state.peek().value, (followed: true, count: 1));
  });

  test('changing source in a transform never sends the write', () async {
    final input = Value(1);
    var writes = 0;
    final query = Query<int, Model>(
      source: () => input.value,
      load: (_, _) => (followed: false, count: 1),
    );
    addTearDown(query.dispose);
    final follow = followField(query, (_, _) {
      writes++;
    });
    await query.ensureLoaded();
    await expectLater(
      follow.update((value) {
        input.value = 2;
        return !value;
      }),
      throwsStateError,
    );
    expect(writes, 0);
  });

  test('token changes clear the model, pin old write and read only after settlement', () async {
    final input = Value((identity: 1, token: 'old'));
    final captured = <String>[];
    final ack = Completer<void>();
    var reads = 0;
    final query = Query<({int identity, String token}), Model>(
      source: () => input.value,
      load: (_, _) {
        reads++;
        return (followed: false, count: reads);
      },
    );
    addTearDown(query.dispose);
    final follow = followField(query, (source, _) {
      captured.add(source.token);
      return ack.future;
    });
    await follow.ensureLoaded();
    final write = follow.set(true);
    input.value = (identity: 1, token: 'new');
    expect(follow.state.peek().hasValue, isFalse);
    expect(follow.state.peek().pending, isTrue);
    await flush();
    expect(captured, ['old']);
    expect(reads, 1);
    ack.complete();
    expect(await write, isTrue);
    await flush();
    expect(reads, 2);
    expect(query.state.peek().value.followed, isFalse);
    expect(follow.state.peek().pending, isFalse);
  });

  test(
    'accepted writes run after disposal but cannot publish or roll back',
    () async {
      final response = Completer<void>();
      var writes = 0;
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, _) => (followed: false, count: 1),
      );
      final follow = followField(query, (_, _) {
        writes++;
        return response.future;
      });
      await follow.ensureLoaded();
      final write = follow.set(true);
      final snapshot = query.state.peek();
      query.dispose();
      await flush();
      expect(writes, 1);
      response.complete();
      expect(await write, isTrue);
      expect(query.state.peek(), same(snapshot));
      await expectLater(
        follow.set(false),
        throwsA(reason(ResourceReason.disposed)),
      );
    },
  );

  test(
    'disposing a view rejects its projected read without disposing parent',
    () async {
      final response = Completer<Model>();
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, _) => response.future,
      );
      addTearDown(query.dispose);
      final follow = followField(query, (_, _) {});
      final read = follow.ensureLoaded();
      final rejected = expectLater(
        read,
        throwsA(reason(ResourceReason.disposed)),
      );
      follow.dispose();
      response.complete((followed: true, count: 1));
      await rejected;
      expect((await query.ensureLoaded()).followed, isTrue);
    },
  );

  test(
    'accept patches one field and updates the parent cached model',
    () async {
      final query = Query<int, Model>(
        source: () => 1,
        load: (_, _) => (followed: false, count: 5),
      );
      addTearDown(query.dispose);
      final follow = followField(query, (_, _) {});
      await follow.ensureLoaded();
      expect(follow.accept(const Seed(source: 1, value: true)), isTrue);
      expect(await query.ensureLoaded(), (followed: true, count: 5));
      expect(
        () => follow.accept(const Seed(source: 2, value: false)),
        throwsA(reason(ResourceReason.sourceChanged)),
      );
    },
  );

  test('read error and field write error remain distinct; successful GET clears them', () async {
    var failRead = false;
    final readError = StateError('GET');
    final writeError = StateError('POST');
    final query = Query<int, Model>(
      source: () => 1,
      load: (_, _) {
        if (failRead) throw readError;
        return (followed: false, count: 1);
      },
    );
    addTearDown(query.dispose);
    final follow = followField(query, (_, _) => throw writeError);
    await follow.ensureLoaded();
    failRead = true;
    await expectLater(query.refresh(), throwsA(same(readError)));
    await expectLater(follow.set(true), throwsA(same(writeError)));
    expect(query.state.peek().error, same(readError));
    expect(follow.state.peek().error, same(writeError));
    failRead = false;
    await query.refresh();
    expect(query.state.peek().error, isNull);
    expect(follow.state.peek().error, isNull);
  });
}
