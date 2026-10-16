import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';
import 'package:oref/src/core/alien_adapter.dart' show reactiveEffect;
import 'package:oref/src/resources/resource.dart' show updatePages;

Matcher reason(ResourceReason reason) =>
    isA<ResourceException>().having((error) => error.reason, 'reason', reason);

void main() {
  for (final throwsAfterChange in [false, true]) {
    test(
      'cursor callback source changes discard its old result (throws=$throwsAfterChange)',
      () async {
        var source = 1;
        final calls = <int>[];
        final pages = Pages<int, int, int>(
          source: () => source,
          load: (input, _, _) {
            calls.add(input);
            return [input];
          },
          nextCursor: (input, _) {
            if (input == 1) {
              source = 2;
              if (throwsAfterChange) throw StateError('old cursor');
            }
            return null;
          },
        );
        addTearDown(pages.dispose);
        await expectLater(
          pages.ensureLoaded(),
          throwsA(reason(ResourceReason.sourceChanged)),
        );
        await Future<void>.delayed(Duration.zero);
        expect(calls, [1, 2]);
        expect(pages.state.peek().source, 2);
        expect(pages.state.peek().items, [2]);
        expect(pages.state.peek().error, isNull);
      },
    );
  }

  test(
    '1000 items across ten pages keep one request per joined attempt',
    () async {
      var requests = 0;
      final pages = Pages<int, int, int>(
        source: () => 100,
        load: (take, cursor, _) {
          requests++;
          final start = cursor ?? 0;
          return List.generate(take, (index) => start + index);
        },
        nextCursor: (_, page) => page.last == 999 ? null : page.last + 1,
      );
      addTearDown(pages.dispose);
      for (var page = 0; page < 10; page++) {
        final operation = page == 0 ? pages.ensureLoaded() : pages.loadMore();
        for (var call = 0; call < 20; call++) {
          final joined = page == 0 ? pages.ensureLoaded() : pages.loadMore();
          expect(identical(joined, operation), isTrue);
        }
        await operation;
      }
      final thousand = pages.state.peek().items;
      expect(thousand, List.generate(1000, (index) => index));
      expect(requests, 10);
      expect(await pages.loadMore(), isEmpty);
      expect(requests, 10);
      await pages.refresh();
      expect(requests, 11);
      expect(pages.state.peek().items, List.generate(100, (index) => index));
      expect(thousand.length, 1000);
      expect(() => thousand.clear(), throwsUnsupportedError);
    },
  );

  test(
    'construction and an early append do not evaluate or subscribe source',
    () async {
      var sources = 0;
      var loads = 0;
      final pages = Pages<int, int, int>(
        source: () => ++sources,
        load: (_, _, _) {
          loads++;
          return [1];
        },
        nextCursor: (_, _) => null,
      );
      expect(sources, 0);
      await expectLater(
        pages.loadMore(),
        throwsA(reason(ResourceReason.notReady)),
      );
      expect(sources, 0);
      expect(loads, 0);
      pages.dispose();
      await expectLater(
        pages.ensureLoaded(),
        throwsA(reason(ResourceReason.disposed)),
      );
      expect(sources, 0);
    },
  );

  test('first read and append share their own futures and publish immutable snapshots', () async {
    final initial = Completer<List<int>>();
    final append = Completer<List<int>>();
    final cursors = <int?>[];
    final pages = Pages<String, int, int>(
      source: () => 'category',
      load: (_, cursor, _) {
        cursors.add(cursor);
        return cursor == null ? initial.future : append.future;
      },
      nextCursor: (_, page) => page.last == 2 ? 2 : null,
    );
    final first = pages.ensureLoaded();
    expect(identical(first, pages.ensureLoaded()), isTrue);
    expect(identical(first, pages.refresh()), isTrue);
    expect(pages.state.peek().phase, PagePhase.initial);
    initial.complete([1, 2]);
    expect(await first, [1, 2]);
    final oldSnapshot = pages.state.peek();
    expect(() => oldSnapshot.items.add(5), throwsUnsupportedError);
    final more = pages.loadMore();
    expect(identical(more, pages.loadMore()), isTrue);
    expect(identical(first, pages.ensureLoaded()), isTrue);
    append.complete([3]);
    expect(await more, [3]);
    expect(pages.state.peek().items, [1, 2, 3]);
    expect(oldSnapshot.items, [1, 2]);
    final lastSnapshot = pages.state.peek();
    expect(await pages.loadMore(), isEmpty);
    expect(pages.state.peek(), same(lastSnapshot));
    expect(cursors, [null, 2]);
    pages.dispose();
  });

  test(
    'refresh supersedes append immediately and rejects its late result',
    () async {
      final gates = <Completer<List<int>>>[];
      final requests = <ReadRequest>[];
      var cancelled = 0;
      final pages = Pages<int, int, int>(
        source: () => 1,
        load: (_, _, request) {
          requests.add(request);
          request.onCancel(() => cancelled++);
          final gate = Completer<List<int>>();
          gates.add(gate);
          return gate.future;
        },
        nextCursor: (_, page) => page.last,
      );
      final first = pages.ensureLoaded();
      await Future<void>.delayed(Duration.zero);
      gates[0].complete([1]);
      await first;
      final append = pages.loadMore();
      final discarded = expectLater(
        append,
        throwsA(reason(ResourceReason.superseded)),
      );
      await Future<void>.delayed(Duration.zero);
      final refresh = pages.refresh();
      await discarded;
      expect(cancelled, 1);
      expect(requests[1].cancelled, isTrue);
      expect(pages.state.peek().phase, PagePhase.refresh);
      await expectLater(pages.loadMore(), throwsA(reason(ResourceReason.busy)));
      await Future<void>.delayed(Duration.zero);
      gates[2].complete([10]);
      expect(await refresh, [10]);
      gates[1].completeError(StateError('late transport failure'));
      await Future<void>.delayed(Duration.zero);
      expect(pages.state.peek().items, [10]);
      expect(pages.state.peek().error, isNull);
      expect(pages.state.peek().nextError, isNull);
      pages.dispose();
    },
  );

  test('append failure keeps its cursor while failed refresh becomes latest attempt', () async {
    var calls = 0;
    final appendError = StateError('append');
    final refreshError = StateError('refresh');
    final cursors = <int?>[];
    final pages = Pages<int, int, int>(
      source: () => 1,
      load: (_, cursor, _) {
        cursors.add(cursor);
        calls++;
        if (calls == 2) throw appendError;
        if (calls == 4) throw refreshError;
        return [calls];
      },
      nextCursor: (_, page) => page.last,
    );
    await pages.ensureLoaded();
    await expectLater(pages.loadMore(), throwsA(same(appendError)));
    expect(pages.state.peek().items, [1]);
    expect(pages.state.peek().error, isNull);
    expect(pages.state.peek().nextError, same(appendError));
    expect(await pages.loadMore(), [3]);
    expect(cursors, [null, 1, 1]);
    expect(pages.state.peek().nextError, isNull);
    final refresh = pages.refresh();
    await expectLater(refresh, throwsA(same(refreshError)));
    expect(pages.state.peek().items, [1, 3]);
    expect(identical(pages.ensureLoaded(), refresh), isTrue);
    await expectLater(pages.ensureLoaded(), throwsA(same(refreshError)));
    expect(calls, 4);
    pages.dispose();
  });

  test(
    'first-page failure requires explicit refresh before appending',
    () async {
      var calls = 0;
      final failure = StateError('initial');
      final pages = Pages<int, int, int>(
        source: () => 1,
        load: (_, _, _) {
          if (++calls == 1) throw failure;
          return [2];
        },
        nextCursor: (_, _) => null,
      );
      final first = pages.ensureLoaded();
      await expectLater(first, throwsA(same(failure)));
      expect(identical(pages.ensureLoaded(), first), isTrue);
      await expectLater(
        pages.loadMore(),
        throwsA(reason(ResourceReason.notReady)),
      );
      expect(calls, 1);
      expect(await pages.refresh(), [2]);
      expect(pages.state.peek().hasLoaded, isTrue);
      pages.dispose();
    },
  );

  test(
    'a source switch discards old results and starts only the new first page',
    () async {
      final category = Value(1);
      final calls = <int>[];
      final gates = <Completer<List<int>>>[];
      final pages = Pages<int, int, int>(
        source: () => category.value,
        load: (source, _, _) {
          calls.add(source);
          final gate = Completer<List<int>>();
          gates.add(gate);
          return gate.future;
        },
        nextCursor: (_, _) => null,
      );
      final first = pages.ensureLoaded();
      final discarded = expectLater(
        first,
        throwsA(reason(ResourceReason.sourceChanged)),
      );
      await Future<void>.delayed(Duration.zero);
      category.value = 2;
      await discarded;
      final second = pages.ensureLoaded();
      await Future<void>.delayed(Duration.zero);
      expect(calls, [1, 2]);
      gates[0].complete([100]);
      gates[1].complete([200]);
      expect(await second, [200]);
      expect(pages.state.peek().source, 2);
      expect(pages.state.peek().items, [200]);
      pages.dispose();
    },
  );

  test(
    'append observes a source change even before batch effects flush',
    () async {
      final category = Value(1);
      final calls = <({int source, int? cursor})>[];
      final pages = Pages<int, int, int>(
        source: () => category.value,
        load: (source, cursor, _) {
          calls.add((source: source, cursor: cursor));
          return [source];
        },
        nextCursor: (_, page) => page.last,
      );
      await pages.ensureLoaded();
      late Future<List<int>> more;
      batch(() {
        category.value = 2;
        more = pages.loadMore();
      });
      await expectLater(more, throwsA(reason(ResourceReason.notReady)));
      expect(await pages.ensureLoaded(), [2]);
      expect(calls, [(source: 1, cursor: null), (source: 2, cursor: null)]);
      pages.dispose();
    },
  );

  test(
    'source failure clears old data and recovers even to the same source',
    () async {
      final available = Value(true);
      final failure = StateError('source');
      var loads = 0;
      final pages = Pages<int, int, int>(
        source: () {
          if (!available.value) throw failure;
          return 1;
        },
        load: (_, _, _) => [++loads],
        nextCursor: (_, _) => null,
      );
      expect(await pages.ensureLoaded(), [1]);
      available.value = false;
      expect(pages.state.peek().hasSource, isFalse);
      expect(pages.state.peek().items, isEmpty);
      expect(pages.state.peek().error, same(failure));
      await expectLater(pages.ensureLoaded(), throwsA(same(failure)));
      available.value = true;
      expect(await pages.ensureLoaded(), [2]);
      expect(loads, 2);
      pages.dispose();
    },
  );

  test(
    'non-advancing and empty cursors fail without changing old pages',
    () async {
      var invalidEmpty = false;
      final pages = Pages<int, int, int>(
        source: () => 1,
        load: (_, cursor, _) => cursor == null
            ? [1]
            : invalidEmpty
            ? []
            : [2],
        nextCursor: (_, _) => 1,
      );
      await pages.ensureLoaded();
      await expectLater(pages.loadMore(), throwsStateError);
      expect(pages.state.peek().items, [1]);
      invalidEmpty = true;
      await expectLater(pages.loadMore(), throwsStateError);
      expect(pages.state.peek().items, [1]);
      expect(pages.state.peek().hasNext, isTrue);
      pages.dispose();
    },
  );

  test('nextCursor failures keep the original error and stack', () async {
    final failure = StateError('cursor');
    final stack = StackTrace.current;
    final pages = Pages<int, int, int>(
      source: () => 1,
      load: (_, _, _) => [1],
      nextCursor: (_, _) => Error.throwWithStackTrace(failure, stack),
    );
    final result = pages.ensureLoaded();
    await expectLater(result, throwsA(same(failure)));
    expect(pages.state.peek().hasLoaded, isFalse);
    expect(pages.state.peek().stackTrace.toString(), stack.toString());
    pages.dispose();
  });

  test(
    'reconfiguration captures the current loader and cursor callback',
    () async {
      final gate = Completer<List<int>>();
      final pages = Pages<int, int, int>(
        source: () => 1,
        load: (_, _, _) => gate.future,
        nextCursor: (_, _) => null,
      );
      final first = pages.ensureLoaded();
      updatePages(
        pages,
        source: () => 1,
        load: (_, _, _) => [20],
        nextCursor: (_, page) => page.last,
      );
      gate.complete([10]);
      expect(await first, [10]);
      expect(pages.state.peek().hasNext, isFalse);
      expect(await pages.refresh(), [20]);
      expect(pages.state.peek().hasNext, isTrue);
      pages.dispose();
    },
  );

  test('disposal invalidates a read before transport completion', () async {
    final gate = Completer<List<int>>();
    var calls = 0;
    final pages = Pages<int, int, int>(
      source: () => ++calls,
      load: (_, _, _) => gate.future,
      nextCursor: (_, _) => null,
    );
    final first = pages.ensureLoaded();
    final discarded = expectLater(
      first,
      throwsA(reason(ResourceReason.disposed)),
    );
    await Future<void>.delayed(Duration.zero);
    final pending = pages.state.peek();
    pages.dispose();
    await discarded;
    gate.completeError(StateError('late'));
    await Future<void>.delayed(Duration.zero);
    expect(pages.state.peek(), same(pending));
    final oldCalls = calls;
    await expectLater(
      pages.refresh(),
      throwsA(reason(ResourceReason.disposed)),
    );
    expect(calls, oldCalls);
  });

  test(
    'append cancellation can switch source without replacing its new read',
    () async {
      final source = Value(1);
      final oldAppend = Completer<List<int>>();
      final calls = <({int source, int? cursor})>[];
      Future<List<int>>? replacement;
      late Pages<int, int, int> pages;
      pages = Pages(
        source: () => source.value,
        load: (input, cursor, request) {
          calls.add((source: input, cursor: cursor));
          if (cursor != null) {
            request.onCancel(() {
              source.value = 2;
              replacement = pages.ensureLoaded();
              replacement!.ignore();
            });
            return oldAppend.future;
          }
          return [input];
        },
        nextCursor: (_, page) => page.last,
      );
      await pages.ensureLoaded();
      final append = pages.loadMore();
      final oldResult = expectLater(
        append,
        throwsA(reason(ResourceReason.superseded)),
      );
      await Future<void>.delayed(Duration.zero);
      final refresh = pages.refresh();
      await expectLater(refresh, throwsA(reason(ResourceReason.sourceChanged)));
      await oldResult;
      expect(await replacement, [2]);
      expect(pages.state.peek().source, 2);
      expect(pages.state.peek().items, [2]);
      expect(calls, [
        (source: 1, cursor: null),
        (source: 1, cursor: 1),
        (source: 2, cursor: null),
      ]);
      oldAppend.complete([99]);
      pages.dispose();
    },
  );

  test(
    'source cancellation can resolve a newer source before automatic reload',
    () async {
      final source = Value(1);
      final gate = Completer<List<int>>();
      final calls = <int>[];
      Future<List<int>>? replacement;
      late Pages<int, int, int> pages;
      pages = Pages(
        source: () => source.value,
        load: (input, _, request) {
          calls.add(input);
          if (input == 1) {
            request.onCancel(() {
              source.value = 3;
              replacement = pages.ensureLoaded();
              replacement!.ignore();
            });
            return gate.future;
          }
          return [input];
        },
        nextCursor: (_, _) => null,
      );
      final first = pages.ensureLoaded();
      final discarded = expectLater(
        first,
        throwsA(reason(ResourceReason.sourceChanged)),
      );
      await Future<void>.delayed(Duration.zero);
      source.value = 2;
      await discarded;
      expect(await replacement, [3]);
      expect(calls, [1, 3]);
      expect(pages.state.peek().source, 3);
      gate.complete([100]);
      pages.dispose();
    },
  );

  test('source-error cancellation recovery preserves the old error and fresh state', () async {
    final available = Value(true);
    final gate = Completer<List<int>>();
    final failure = StateError('source failed');
    var calls = 0;
    Future<List<int>>? replacement;
    late Pages<int, int, int> pages;
    pages = Pages(
      source: () {
        if (!available.value) throw failure;
        return 1;
      },
      load: (_, _, request) {
        if (++calls == 1) {
          request.onCancel(() {
            available.value = true;
            replacement = pages.ensureLoaded();
            replacement!.ignore();
          });
          return gate.future;
        }
        return [20];
      },
      nextCursor: (_, _) => null,
    );
    final first = pages.ensureLoaded();
    final discarded = expectLater(first, throwsA(same(failure)));
    await Future<void>.delayed(Duration.zero);
    available.value = false;
    await discarded;
    expect(await replacement, [20]);
    expect(pages.state.peek().items, [20]);
    expect(pages.state.peek().error, isNull);
    gate.complete([10]);
    pages.dispose();
  });

  test(
    'a source-error listener can recover without changing the failing call',
    () async {
      var available = true;
      final failure = StateError('source failed');
      var calls = 0;
      final pages = Pages<int, int, int>(
        source: () {
          if (!available) throw failure;
          return 1;
        },
        load: (_, _, _) => [++calls],
        nextCursor: (_, _) => null,
      );
      await pages.ensureLoaded();
      Future<List<int>>? recovered;
      final subscription = pages.state.subscribe(() {
        if (identical(pages.state.peek().error, failure)) {
          available = true;
          recovered = pages.refresh();
          recovered!.ignore();
        }
      });
      available = false;
      await expectLater(pages.refresh(), throwsA(same(failure)));
      expect(await recovered, [2]);
      expect(pages.state.peek().error, isNull);
      subscription.dispose();
      pages.dispose();
    },
  );

  test('a native notification failure cannot prevent an accepted read from running', () async {
    final pages = Pages<int, int, int>(
      source: () => 1,
      load: (_, _, _) => [10],
      nextCursor: (_, _) => null,
    );
    final failure = StateError('external effect');
    final reported = <Object>[];
    final watcher = reactiveEffect(() {
      if (pages.state.value.phase == PagePhase.initial) throw failure;
    });
    late Future<List<int>> result;
    runZonedGuarded(() {
      result = pages.ensureLoaded();
    }, (error, _) => reported.add(error));
    expect(await result, [10]);
    expect(pages.state.peek().items, [10]);
    expect(pages.state.peek().phase, PagePhase.idle);
    expect(reported, [same(failure)]);
    watcher.dispose();
    pages.dispose();
  });
}
