import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';
import 'package:oref/src/core/alien_adapter.dart' show reactiveEffect;
import 'package:oref/src/resources/resource.dart'
    show resourceLifecycle, updateRemoteValue;

Matcher reason(ResourceReason reason) =>
    isA<ResourceException>().having((error) => error.reason, 'reason', reason);

typedef Input = ({int id, String token});

void main() {
  for (final failure in <Object>[
    StateError('transform failed'),
    const ResourceException(ResourceReason.busy),
  ]) {
    test(
      'a transform callback records its own $failure without a write',
      () async {
        var writes = 0;
        final stack = StackTrace.current;
        final remote = RemoteValue<int, int>(
          source: () => 1,
          initial: const Seed(source: 1, value: 10),
          write: (_, value) {
            writes++;
            return value;
          },
        );
        addTearDown(remote.dispose);
        await remote.ensureLoaded();
        await remote
            .update((_) => Error.throwWithStackTrace(failure, stack))
            .then<void>(
              (_) => fail('Expected the callback error'),
              onError: (Object error, StackTrace trace) {
                expect(error, same(failure));
                expect(trace.toString(), stack.toString());
              },
            );
        expect(remote.state.peek().error, same(failure));
        expect(remote.state.peek().stackTrace.toString(), stack.toString());
        expect(remote.state.peek().value, 10);
        expect(remote.state.peek().pending, isFalse);
        expect(writes, 0);
        expect(await remote.update((value) => value + 1), 11);
        expect(remote.state.peek().error, isNull);
      },
    );
  }

  test('a transform failure cannot be recorded into a new source', () async {
    var source = 1;
    final failure = StateError('old transform');
    final remote = RemoteValue<int, int>(
      source: () => source,
      initial: const Seed(source: 1, value: 10),
      write: (_, value) => value,
    );
    addTearDown(remote.dispose);
    await remote.ensureLoaded();
    await expectLater(
      remote.update((_) {
        source = 2;
        throw failure;
      }),
      throwsA(same(failure)),
    );
    expect(remote.state.peek().source, 2);
    expect(remote.state.peek().hasValue, isFalse);
    expect(remote.state.peek().error, isNull);
  });

  test(
    'seeded nullable values work without a reader and equal sets are no-ops',
    () async {
      var writes = 0;
      var sources = 0;
      final remote = RemoteValue<int, String?>(
        source: () {
          sources++;
          return 1;
        },
        initial: const Seed(source: 1, value: null),
        write: (_, value) {
          writes++;
          return value?.toUpperCase();
        },
      );
      expect(sources, 0);
      expect(await remote.ensureLoaded(), isNull);
      expect(remote.state.peek().hasValue, isTrue);
      expect(await remote.set(null), isNull);
      expect(writes, 0);
      await expectLater(
        remote.refresh(),
        throwsA(reason(ResourceReason.noReader)),
      );
      expect(await remote.set('name'), 'NAME');
      expect(remote.state.peek().value, 'NAME');
      expect(writes, 1);
      remote.dispose();
    },
  );

  test('unseeded writes do not implicitly fetch an unknown value', () async {
    var reads = 0;
    final remote = RemoteValue<int, bool>.ack(
      source: () => 1,
      read: (_, _) {
        reads++;
        return false;
      },
      write: (_, _) {},
    );
    await expectLater(
      remote.update((value) => !value),
      throwsA(reason(ResourceReason.notReady)),
    );
    expect(reads, 0);
    expect(await remote.ensureLoaded(), isFalse);
    expect(await remote.update((value) => !value), isTrue);
    remote.dispose();
  });

  test(
    'read attempts coalesce and failed refresh stays the latest attempt',
    () async {
      var reads = 0;
      final failure = StateError('read');
      final reasons = <ReadReason>[];
      final gate = Completer<int>();
      final remote = RemoteValue<int, int>(
        source: () => 1,
        read: (_, request) {
          reasons.add(request.reason);
          reads++;
          if (reads == 1) return gate.future;
          if (reads == 2) throw failure;
          return 3;
        },
        write: (_, value) => value,
      );
      final first = remote.ensureLoaded();
      expect(identical(first, remote.ensureLoaded()), isTrue);
      expect(identical(first, remote.refresh()), isTrue);
      gate.complete(1);
      expect(await first, 1);
      final refresh = remote.refresh();
      await expectLater(refresh, throwsA(same(failure)));
      expect(remote.state.peek().value, 1);
      expect(remote.state.peek().error, same(failure));
      expect(identical(remote.ensureLoaded(), refresh), isTrue);
      await expectLater(remote.ensureLoaded(), throwsA(same(failure)));
      expect(await remote.refresh(), 3);
      expect(reasons, [
        ReadReason.initial,
        ReadReason.refresh,
        ReadReason.refresh,
      ]);
      remote.dispose();
    },
  );

  test('optimistic writes reject competing work and restore the exact before value', () async {
    final gate = Completer<void>();
    final failure = StateError('write');
    final before = <int>[1];
    final desired = <int>[2];
    var writes = 0;
    var transforms = 0;
    final remote = RemoteValue<int, List<int>>.ack(
      source: () => 1,
      initial: Seed(source: 1, value: before),
      read: (_, _) => before,
      write: (_, value) {
        writes++;
        return gate.future;
      },
    );
    await remote.ensureLoaded();
    final result = remote.set(desired);
    expect(remote.state.peek().value, same(desired));
    expect(remote.state.peek().pending, isTrue);
    await expectLater(
      remote.update((value) {
        transforms++;
        return value;
      }),
      throwsA(reason(ResourceReason.busy)),
    );
    await expectLater(remote.refresh(), throwsA(reason(ResourceReason.busy)));
    await expectLater(
      remote.ensureLoaded(),
      throwsA(reason(ResourceReason.busy)),
    );
    expect(transforms, 0);
    final rejected = expectLater(result, throwsA(same(failure)));
    gate.completeError(failure);
    await rejected;
    expect(remote.state.peek().value, same(before));
    expect(remote.state.peek().error, same(failure));
    expect(remote.state.peek().pending, isFalse);
    expect(writes, 1);
    expect(await remote.ensureLoaded(), same(before));
    remote.dispose();
  });

  test(
    'write supersedes an old read and rejects its late transport response',
    () async {
      final readGate = Completer<int>();
      final writeGate = Completer<int>();
      var cancelled = 0;
      final remote = RemoteValue<int, int>(
        source: () => 1,
        initial: const Seed(source: 1, value: 10),
        read: (_, request) {
          request.onCancel(() => cancelled++);
          return readGate.future;
        },
        write: (_, _) => writeGate.future,
      );
      await remote.ensureLoaded();
      final refresh = remote.refresh();
      final discarded = expectLater(
        refresh,
        throwsA(reason(ResourceReason.superseded)),
      );
      await Future<void>.delayed(Duration.zero);
      final write = remote.set(20);
      await discarded;
      expect(cancelled, 1);
      readGate.complete(5);
      writeGate.complete(21);
      expect(await write, 21);
      expect(remote.state.peek().value, 21);
      expect(remote.state.peek().loading, isFalse);
      remote.dispose();
    },
  );

  test(
    'token refresh preserves identity and accepted writes use the old token',
    () async {
      final input = Value<Input>((id: 1, token: 'old'));
      final gate = Completer<void>();
      final writes = <Input>[];
      final reads = <Input>[];
      final remote = RemoteValue<Input, int>.ack(
        source: () => input.value,
        identity: (source) => source.id,
        initial: const Seed(source: (id: 1, token: 'old'), value: 10),
        read: (source, _) {
          reads.add(source);
          return 30;
        },
        write: (source, _) {
          writes.add(source);
          return gate.future;
        },
      );
      await remote.ensureLoaded();
      final write = remote.set(20);
      input.value = (id: 1, token: 'new');
      expect(remote.state.peek().value, 20);
      expect(remote.state.peek().pending, isTrue);
      gate.complete();
      expect(await write, 20);
      expect(writes, [(id: 1, token: 'old')]);
      expect(await remote.ensureLoaded(), 30);
      expect(reads, [(id: 1, token: 'new')]);
      remote.dispose();
    },
  );

  test(
    'new identity cannot receive old optimistic, canonical or rollback values',
    () async {
      final input = Value<Input>((id: 1, token: 'a'));
      final gate = Completer<int>();
      final reads = <Input>[];
      final remote = RemoteValue<Input, int>(
        source: () => input.value,
        identity: (source) => source.id,
        initial: const Seed(source: (id: 1, token: 'a'), value: 10),
        read: (source, _) {
          reads.add(source);
          return source.id * 100;
        },
        write: (_, _) => gate.future,
      );
      await remote.ensureLoaded();
      final write = remote.set(20);
      input.value = (id: 2, token: 'b');
      expect(remote.state.peek().hasValue, isFalse);
      expect(remote.state.peek().pending, isTrue);
      await expectLater(remote.set(200), throwsA(reason(ResourceReason.busy)));
      gate.complete(21);
      expect(await write, 21);
      expect(await remote.ensureLoaded(), 200);
      expect(remote.state.peek().source.id, 2);
      expect(remote.state.peek().value, 200);
      expect(remote.state.peek().pending, isFalse);
      expect(reads, [(id: 2, token: 'b')]);
      remote.dispose();
    },
  );

  test('A to B to A still rejects the old A rollback', () async {
    final id = Value(1);
    final gate = Completer<void>();
    final failure = StateError('old write');
    final remote = RemoteValue<int, int>.ack(
      source: () => id.value,
      initial: const Seed(source: 1, value: 10),
      read: (_, _) => 100,
      write: (_, _) => gate.future,
    );
    await remote.ensureLoaded();
    final write = remote.set(20);
    id.value = 2;
    id.value = 1;
    expect(remote.state.peek().hasValue, isFalse);
    final rejected = expectLater(write, throwsA(same(failure)));
    gate.completeError(failure);
    await rejected;
    expect(await remote.ensureLoaded(), 100);
    expect(remote.state.peek().value, 100);
    expect(remote.state.peek().error, isNull);
    remote.dispose();
  });

  test('source failure preserves the write result and clears pending on settlement', () async {
    final available = Value(true);
    final sourceError = StateError('source');
    final gate = Completer<int>();
    final remote = RemoteValue<int, int>(
      source: () {
        if (!available.value) throw sourceError;
        return 1;
      },
      initial: const Seed(source: 1, value: 10),
      write: (_, _) => gate.future,
    );
    await remote.ensureLoaded();
    final write = remote.set(20);
    available.value = false;
    expect(remote.state.peek().hasValue, isFalse);
    expect(remote.state.peek().pending, isTrue);
    gate.complete(21);
    expect(await write, 21);
    expect(remote.state.peek().pending, isFalse);
    expect(remote.state.peek().hasSource, isFalse);
    expect(remote.state.peek().error, same(sourceError));
    available.value = true;
    await expectLater(
      remote.ensureLoaded(),
      throwsA(reason(ResourceReason.notReady)),
    );
    expect(remote.state.peek().hasValue, isFalse);
    remote.dispose();
  });

  test('accepted writes continue after pending-state disposal', () async {
    var calls = 0;
    final remote = RemoteValue<int, int>.ack(
      source: () => 1,
      initial: const Seed(source: 1, value: 1),
      write: (_, _) {
        calls++;
      },
    );
    await remote.ensureLoaded();
    final subscription = remote.state.subscribe(() {
      if (remote.state.peek().pending) remote.dispose();
    });
    expect(await remote.set(2), 2);
    expect(calls, 1);
    expect(remote.state.peek().pending, isTrue);
    await expectLater(
      remote.ensureLoaded(),
      throwsA(reason(ResourceReason.disposed)),
    );
    subscription.dispose();
  });

  test(
    'update rejects reentrant work and a transform that changes source',
    () async {
      final input = Value(1);
      var writes = 0;
      final remote = RemoteValue<int, int>.ack(
        source: () => input.value,
        initial: const Seed(source: 1, value: 10),
        write: (_, _) => writes++,
      );
      await remote.ensureLoaded();
      Future<int>? nested;
      expect(
        await remote.update((value) {
          nested = remote.set(30);
          nested!.ignore();
          return value;
        }),
        10,
      );
      await expectLater(nested!, throwsA(reason(ResourceReason.busy)));
      await expectLater(
        remote.update((_) {
          input.value = 2;
          return 20;
        }),
        throwsStateError,
      );
      expect(writes, 0);
      expect(remote.state.peek().hasValue, isFalse);
      remote.dispose();
    },
  );

  test(
    'accept checks source and busy reads without issuing requests',
    () async {
      final gate = Completer<int>();
      final remote = RemoteValue<int, int>(
        source: () => 1,
        read: (_, _) => gate.future,
        write: (_, value) => value,
      );
      expect(remote.accept(const Seed(source: 1, value: 5)), 5);
      expect(await remote.ensureLoaded(), 5);
      expect(
        () => remote.accept(const Seed(source: 2, value: 6)),
        throwsA(reason(ResourceReason.sourceChanged)),
      );
      final read = remote.refresh();
      expect(
        () => remote.accept(const Seed(source: 1, value: 6)),
        throwsA(reason(ResourceReason.busy)),
      );
      gate.complete(7);
      expect(await read, 7);
      remote.dispose();
    },
  );

  test(
    'a failed first source consumes the seed and recovery reads afresh',
    () async {
      final available = Value(false);
      final failure = StateError('source');
      var reads = 0;
      final remote = RemoteValue<int, int>(
        source: () {
          if (!available.value) throw failure;
          return 1;
        },
        initial: const Seed(source: 1, value: 1),
        read: (_, _) => ++reads + 10,
        write: (_, value) => value,
      );
      await expectLater(remote.ensureLoaded(), throwsA(same(failure)));
      available.value = true;
      expect(await remote.ensureLoaded(), 11);
      expect(reads, 1);
      remote.dispose();
    },
  );

  test(
    'idle completion refuses stale data without starting background reads',
    () async {
      final input = Value(1);
      final gate = Completer<int>();
      var reads = 0;
      final remote = RemoteValue<int, int>(
        source: () => input.value,
        read: (_, _) {
          reads++;
          return reads == 1 ? gate.future : 20;
        },
        write: (_, value) => value,
      );
      final first = remote.ensureLoaded();
      final discarded = expectLater(
        first,
        throwsA(reason(ResourceReason.sourceChanged)),
      );
      await Future<void>.delayed(Duration.zero);
      resourceLifecycle(remote).pauseSource();
      input.value = 2;
      gate.complete(10);
      await discarded;
      expect(reads, 1);
      expect(remote.state.peek().hasValue, isFalse);
      resourceLifecycle(remote).resumeSource();
      expect(await remote.ensureLoaded(), 20);
      remote.dispose();
    },
  );

  test('reconfiguration does not replace an already accepted writer', () async {
    final gate = Completer<int>();
    final remote = RemoteValue<int, int>(
      source: () => 1,
      initial: const Seed(source: 1, value: 1),
      write: (_, _) => gate.future,
    );
    await remote.ensureLoaded();
    final first = remote.set(2);
    updateRemoteValue(remote, source: () => 1, write: (_, value) => value * 10);
    gate.complete(3);
    expect(await first, 3);
    expect(await remote.set(4), 40);
    remote.dispose();
  });

  test('a source-change listener can refresh without being replaced by an automatic read', () async {
    final source = Value(1);
    var reads = 0;
    final remote = RemoteValue<int, int>(
      source: () => source.value,
      read: (input, _) {
        reads++;
        return input * 10;
      },
      write: (_, value) => value,
    );
    await remote.ensureLoaded();
    Future<int>? resumed;
    final subscription = remote.state.subscribe(() {
      final state = remote.state.peek();
      if (state.hasSource &&
          state.source == 2 &&
          !state.hasValue &&
          !state.loading) {
        resumed = remote.refresh();
        resumed!.ignore();
      }
    });
    source.value = 2;
    expect(await resumed, 20);
    expect(reads, 2);
    subscription.dispose();
    remote.dispose();
  });

  test(
    'a cancelled GET can change identity without an old preview overwriting it',
    () async {
      final source = Value(1);
      final readGate = Completer<int>();
      final writeGate = Completer<int>();
      final writes = <int>[];
      final remote = RemoteValue<int, int>(
        source: () => source.value,
        initial: const Seed(source: 1, value: 10),
        read: (input, request) {
          if (input == 1) {
            request.onCancel(() => source.value = 2);
            return readGate.future;
          }
          return 200;
        },
        write: (input, _) {
          writes.add(input);
          return writeGate.future;
        },
      );
      await remote.ensureLoaded();
      final refresh = remote.refresh();
      final discarded = expectLater(
        refresh,
        throwsA(reason(ResourceReason.superseded)),
      );
      await Future<void>.delayed(Duration.zero);
      final write = remote.set(20);
      await discarded;
      expect(remote.state.peek().source, 2);
      expect(remote.state.peek().hasValue, isFalse);
      expect(remote.state.peek().pending, isTrue);
      writeGate.complete(21);
      expect(await write, 21);
      expect(await remote.ensureLoaded(), 200);
      expect(writes, [1]);
      readGate.complete(5);
      remote.dispose();
    },
  );

  test('source cancellation can adopt a seed without an automatic read replacing it', () async {
    final source = Value(1);
    final gate = Completer<int>();
    var reads = 0;
    late RemoteValue<int, int> remote;
    remote = RemoteValue(
      source: () => source.value,
      read: (_, request) {
        reads++;
        request.onCancel(() {
          remote.accept(const Seed(source: 2, value: 20));
        });
        return gate.future;
      },
      write: (_, value) => value,
    );
    final first = remote.ensureLoaded();
    final discarded = expectLater(
      first,
      throwsA(reason(ResourceReason.sourceChanged)),
    );
    await Future<void>.delayed(Duration.zero);
    source.value = 2;
    await discarded;
    expect(await remote.ensureLoaded(), 20);
    expect(remote.state.peek().value, 20);
    expect(reads, 1);
    gate.complete(10);
    remote.dispose();
  });

  test('source-error cancellation recovery preserves the old error and fresh value', () async {
    final available = Value(true);
    final failure = StateError('source failed');
    final gate = Completer<int>();
    var reads = 0;
    Future<int>? replacement;
    late RemoteValue<int, int> remote;
    remote = RemoteValue(
      source: () {
        if (!available.value) throw failure;
        return 1;
      },
      read: (_, request) {
        if (++reads == 1) {
          request.onCancel(() {
            available.value = true;
            replacement = remote.ensureLoaded();
            replacement!.ignore();
          });
          return gate.future;
        }
        return 20;
      },
      write: (_, value) => value,
    );
    final first = remote.ensureLoaded();
    final discarded = expectLater(first, throwsA(same(failure)));
    await Future<void>.delayed(Duration.zero);
    available.value = false;
    await discarded;
    expect(await replacement, 20);
    expect(remote.state.peek().error, isNull);
    expect(remote.state.peek().value, 20);
    gate.complete(10);
    remote.dispose();
  });

  test(
    'a source-error listener can recover without changing the failing call',
    () async {
      var available = true;
      final failure = StateError('source failed');
      var reads = 0;
      final remote = RemoteValue<int, int>(
        source: () {
          if (!available) throw failure;
          return 1;
        },
        read: (_, _) => ++reads,
        write: (_, value) => value,
      );
      await remote.ensureLoaded();
      Future<int>? recovered;
      final subscription = remote.state.subscribe(() {
        if (identical(remote.state.peek().error, failure)) {
          available = true;
          recovered = remote.refresh();
          recovered!.ignore();
        }
      });
      available = false;
      await expectLater(remote.refresh(), throwsA(same(failure)));
      expect(await recovered, 2);
      expect(remote.state.peek().error, isNull);
      subscription.dispose();
      remote.dispose();
    },
  );

  test('a failed write restores the preceding failed GET attempt', () async {
    final readError = StateError('GET failed');
    final writeError = StateError('POST failed');
    final remote = RemoteValue<int, int>(
      source: () => 1,
      initial: const Seed(source: 1, value: 10),
      read: (_, _) => throw readError,
      write: (_, _) => throw writeError,
    );
    await remote.ensureLoaded();
    final refresh = remote.refresh();
    await expectLater(refresh, throwsA(same(readError)));
    await expectLater(remote.set(20), throwsA(same(writeError)));
    expect(remote.state.peek().value, 10);
    expect(remote.state.peek().error, same(writeError));
    expect(identical(remote.ensureLoaded(), refresh), isTrue);
    await expectLater(remote.ensureLoaded(), throwsA(same(readError)));
    remote.dispose();
  });

  test(
    'a paused last consumer does not start queued GET when a writer settles',
    () async {
      final source = Value<Input>((id: 1, token: 'old'));
      final gate = Completer<int>();
      var reads = 0;
      final remote = RemoteValue<Input, int>(
        source: () => source.value,
        identity: (input) => input.id,
        initial: const Seed(source: (id: 1, token: 'old'), value: 10),
        read: (_, _) {
          reads++;
          return 30;
        },
        write: (_, _) => gate.future,
      );
      await remote.ensureLoaded();
      final write = remote.set(20);
      source.value = (id: 1, token: 'new');
      resourceLifecycle(remote).pauseSource();
      gate.complete(21);
      expect(await write, 21);
      await Future<void>.delayed(Duration.zero);
      expect(reads, 0);
      expect(remote.state.peek().value, 21);
      expect(remote.state.peek().pending, isFalse);
      remote.dispose();
    },
  );

  test(
    'source-side disposal at settlement keeps the accepted writer result',
    () async {
      var closeOnRead = false;
      final gate = Completer<int>();
      late RemoteValue<int, int> remote;
      remote = RemoteValue(
        source: () {
          if (closeOnRead) remote.dispose();
          return 1;
        },
        initial: const Seed(source: 1, value: 10),
        write: (_, _) => gate.future,
      );
      await remote.ensureLoaded();
      final write = remote.set(20);
      final pending = remote.state.peek();
      closeOnRead = true;
      gate.complete(21);
      expect(await write, 21);
      expect(remote.state.peek(), same(pending));
      expect(resourceLifecycle(remote).writing, isFalse);
    },
  );

  test(
    'an update that changes source A to B to A still cannot be accepted',
    () async {
      final source = Value(1);
      var writes = 0;
      final remote = RemoteValue<int, int>.ack(
        source: () => source.value,
        initial: const Seed(source: 1, value: 10),
        write: (_, _) => writes++,
      );
      await remote.ensureLoaded();
      await expectLater(
        remote.update((_) {
          source.value = 2;
          source.value = 1;
          return 20;
        }),
        throwsStateError,
      );
      expect(writes, 0);
      expect(remote.state.peek().hasValue, isFalse);
      remote.dispose();
    },
  );

  test(
    'a native preview notification failure does not replace a writer result',
    () async {
      final remote = RemoteValue<int, int>.ack(
        source: () => 1,
        initial: const Seed(source: 1, value: 10),
        write: (_, _) {},
      );
      await remote.ensureLoaded();
      final failure = StateError('external effect');
      final reported = <Object>[];
      final watcher = reactiveEffect(() {
        if (remote.state.value.pending) throw failure;
      });
      late Future<int> result;
      runZonedGuarded(() {
        result = remote.set(20);
      }, (error, _) => reported.add(error));
      expect(await result, 20);
      expect(remote.state.peek().value, 20);
      expect(remote.state.peek().pending, isFalse);
      expect(resourceLifecycle(remote).writing, isFalse);
      expect(reported, [same(failure)]);
      watcher.dispose();
      remote.dispose();
    },
  );
}
