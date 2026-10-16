import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

Matcher reason(ResourceReason reason) =>
    isA<ResourceException>().having((error) => error.reason, 'reason', reason);

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('a source-error listener can recover without changing the failed call error', () async {
    final bad = Value(true);
    final failure = StateError('source');
    final query = Query<int, int>(
      source: () {
        if (bad.value) throw failure;
        return 1;
      },
      load: (source, _) => source,
    );
    addTearDown(query.dispose);
    final subscription = query.state.subscribe(() {
      if (query.state.peek().error != null) bad.value = false;
    });
    addTearDown(subscription.dispose);
    await expectLater(query.ensureLoaded(), throwsA(same(failure)));
    expect(await query.ensureLoaded(), 1);
  });

  test('source-side disposal cannot publish state or start a loader', () async {
    late Query<int, int> query;
    var calls = 0;
    query = Query(
      source: () {
        query.dispose();
        return 1;
      },
      load: (_, _) {
        calls++;
        return 1;
      },
    );
    final before = query.state.peek();
    await expectLater(
      query.ensureLoaded(),
      throwsA(reason(ResourceReason.disposed)),
    );
    expect(query.state.peek(), same(before));
    expect(calls, 0);
  });

  test(
    'construction is lazy; active and completed reads reuse a Future',
    () async {
      var calls = 0;
      final response = Completer<int>();
      final query = Query(
        source: () => 1,
        load: (_, _) {
          calls++;
          return response.future;
        },
      );
      addTearDown(query.dispose);
      expect(calls, 0);
      final first = query.ensureLoaded();
      expect(query.state.peek().pending, isTrue);
      expect(identical(first, query.ensureLoaded()), isTrue);
      expect(identical(first, query.refresh()), isTrue);
      await flush();
      expect(calls, 1);
      response.complete(10);
      expect(await first, 10);
      expect(identical(first, query.ensureLoaded()), isTrue);
    },
  );

  test(
    'failed attempts are cached and refresh preserves the previous model',
    () async {
      final error = StateError('read');
      var fail = true;
      var calls = 0;
      final query = Query<int, int>(
        source: () => 1,
        load: (_, _) {
          calls++;
          if (fail) throw error;
          return calls;
        },
      );
      addTearDown(query.dispose);
      final failed = query.ensureLoaded();
      await expectLater(failed, throwsA(same(error)));
      expect(identical(failed, query.ensureLoaded()), isTrue);
      expect(calls, 1);
      fail = false;
      expect(await query.refresh(), 2);
      final old = query.state.peek();
      fail = true;
      await expectLater(query.refresh(), throwsA(same(error)));
      expect(query.state.peek().value, old.value);
      expect(query.state.peek().error, same(error));
    },
  );

  test('nullable source and value are actual values', () async {
    final query = Query<String?, String?>(
      source: () => null,
      load: (_, _) => null,
    );
    addTearDown(query.dispose);
    expect(() => query.state.peek().source, throwsStateError);
    expect(() => query.state.peek().value, throwsStateError);
    expect(await query.ensureLoaded(), isNull);
    expect(query.state.peek().hasSource, isTrue);
    expect(query.state.peek().hasValue, isTrue);
    expect(query.state.peek().source, isNull);
    expect(query.state.peek().value, isNull);
  });

  test(
    'source changes reject old work and automatically read the new source',
    () async {
      final input = Value('a');
      final responses = <String, Completer<String>>{};
      final query = Query(
        source: () => input.value,
        load: (source, _) => (responses[source] = Completer<String>()).future,
      );
      addTearDown(query.dispose);
      final first = query.ensureLoaded();
      final oldResult = expectLater(
        first,
        throwsA(reason(ResourceReason.sourceChanged)),
      );
      await flush();
      input.value = 'b';
      expect(query.state.peek().hasValue, isFalse);
      final next = query.ensureLoaded();
      await flush();
      responses['a']!.complete('late-a');
      responses['b']!.complete('b');
      await oldResult;
      expect(await next, 'b');
      expect(query.state.peek().value, 'b');
    },
  );

  test('source errors retain their object and stack, then recover', () async {
    final input = Value(false);
    final error = StateError('source');
    final stack = StackTrace.fromString('source-stack');
    final query = Query<int, int>(
      source: () {
        if (input.value) Error.throwWithStackTrace(error, stack);
        return 1;
      },
      load: (source, _) => source,
    );
    addTearDown(query.dispose);
    await query.ensureLoaded();
    input.value = true;
    expect(query.state.peek().hasValue, isFalse);
    expect(query.state.peek().hasSource, isFalse);
    await expectLater(query.ensureLoaded(), throwsA(same(error)));
    expect(query.state.peek().stackTrace.toString(), 'source-stack');
    input.value = false;
    expect(await query.ensureLoaded(), 1);
  });

  test(
    'a source failure cancels a pending read with the original source error',
    () async {
      final bad = Value(false);
      final error = StateError('invalid source');
      final response = Completer<int>();
      final query = Query<int, int>(
        source: () {
          if (bad.value) throw error;
          return 1;
        },
        load: (_, _) => response.future,
      );
      addTearDown(query.dispose);
      final pending = query.ensureLoaded();
      final expected = expectLater(pending, throwsA(same(error)));
      await flush();
      bad.value = true;
      response.complete(2);
      await expected;
      expect(query.state.peek().hasValue, isFalse);
    },
  );

  test(
    'plain source changes discovered at commit start the latest read',
    () async {
      var input = 'a';
      final firstResponse = Completer<String>();
      var calls = 0;
      final query = Query(
        source: () => input,
        load: (source, _) {
          calls++;
          return calls == 1 ? firstResponse.future : Future.value(source);
        },
      );
      addTearDown(query.dispose);
      final old = query.ensureLoaded();
      final rejected = expectLater(
        old,
        throwsA(reason(ResourceReason.sourceChanged)),
      );
      await flush();
      input = 'b';
      firstResponse.complete('old');
      await rejected;
      await flush();
      expect(calls, 2);
      expect(query.state.peek().value, 'b');
    },
  );

  test('dispose rejects reads immediately and executes cancellers in reverse order', () async {
    final calls = <int>[];
    final response = Completer<int>();
    late ReadRequest request;
    var sourceCalls = 0;
    final query = Query<int, int>(
      source: () {
        sourceCalls++;
        return 1;
      },
      load: (_, read) {
        request = read;
        read.onCancel(() => calls.add(1));
        read.onCancel(() => calls.add(2)).dispose();
        read.onCancel(() => calls.add(3));
        return response.future;
      },
    );
    final pending = query.ensureLoaded();
    final rejected = expectLater(
      pending,
      throwsA(reason(ResourceReason.disposed)),
    );
    await flush();
    query.dispose();
    query.dispose();
    expect(request.cancelled, isTrue);
    expect(calls, [3, 1]);
    request.onCancel(() => calls.add(4));
    expect(calls, [3, 1, 4]);
    final count = sourceCalls;
    await expectLater(
      query.refresh(),
      throwsA(reason(ResourceReason.disposed)),
    );
    expect(sourceCalls, count);
    response.complete(100);
    await rejected;
  });

  test(
    'a success listener can refresh without old cleanup clearing new work',
    () async {
      final responses = <Completer<int>>[];
      final query = Query<int, int>(
        source: () => 1,
        load: (_, _) {
          final response = Completer<int>();
          responses.add(response);
          return response.future;
        },
      );
      addTearDown(query.dispose);
      Future<int>? second;
      final subscription = query.state.subscribe(() {
        final state = query.state.peek();
        if (state.hasValue &&
            state.value == 1 &&
            !state.pending &&
            second == null) {
          second = query.refresh();
        }
      });
      addTearDown(subscription.dispose);
      final first = query.ensureLoaded();
      await flush();
      responses[0].complete(1);
      expect(await first, 1);
      await flush();
      expect(query.state.peek().pending, isTrue);
      expect(responses, hasLength(2));
      responses[1].complete(2);
      expect(await second!, 2);
      expect(query.state.peek().pending, isFalse);
    },
  );
}
