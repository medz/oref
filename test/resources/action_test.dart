import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';
import 'package:oref/src/resources/resource.dart' show updateAction;

Matcher reason(ResourceReason reason) =>
    isA<ResourceException>().having((error) => error.reason, 'reason', reason);

void main() {
  test(
    'one accepted write rejects duplicate arguments rather than merging',
    () async {
      final gate = Completer<int>();
      final calls = <String>[];
      final action = Action<String, int>(
        execute: (arguments) {
          calls.add(arguments);
          return gate.future;
        },
      );
      expect(action.state.peek().hasValue, isFalse);
      expect(() => action.state.peek().value, throwsStateError);
      final first = action.run('same');
      expect(action.state.peek().pending, isTrue);
      await expectLater(
        action.run('same'),
        throwsA(reason(ResourceReason.busy)),
      );
      expect(calls, ['same']);
      gate.complete(42);
      expect(await first, 42);
      expect(action.state.peek().value, 42);
      expect(action.state.peek().pending, isFalse);
      action.dispose();
    },
  );

  test(
    'new writes clear previous values and errors, including nullable results',
    () async {
      var attempt = 0;
      final failure = StateError('write');
      final action = Action<void, int?>(
        execute: (_) {
          attempt++;
          if (attempt == 2) throw failure;
          return attempt == 1 ? 1 : null;
        },
      );
      expect(await action.run(null), 1);
      final rejected = action.run(null);
      expect(action.state.peek().hasValue, isFalse);
      expect(action.state.peek().error, isNull);
      await expectLater(rejected, throwsA(same(failure)));
      expect(action.state.peek().error, same(failure));
      expect(action.state.peek().hasValue, isFalse);
      final accepted = action.run(null);
      expect(action.state.peek().error, isNull);
      expect(await accepted, isNull);
      expect(action.state.peek().hasValue, isTrue);
      expect(action.state.peek().value, isNull);
      action.dispose();
    },
  );

  test(
    'accepted writes run after dispose and keep the original error and stack',
    () async {
      final gate = Completer<int>();
      final failure = StateError('server rejected');
      final stack = StackTrace.current;
      var calls = 0;
      final action = Action<int, int>(
        execute: (_) {
          calls++;
          return gate.future;
        },
      );
      final result = action.run(1);
      final pendingSnapshot = action.state.peek();
      action.dispose();
      action.dispose();
      await expectLater(
        action.run(2),
        throwsA(reason(ResourceReason.disposed)),
      );
      expect(calls, 1);
      final observed = result.then<void>(
        (_) => fail('Expected failure'),
        onError: (Object error, StackTrace trace) {
          expect(error, same(failure));
          expect(trace.toString(), stack.toString());
        },
      );
      gate.completeError(failure, stack);
      await observed;
      expect(action.state.peek(), same(pendingSnapshot));
    },
  );

  test(
    'pending-state disposal does not cancel an accepted synchronous writer',
    () async {
      var calls = 0;
      final action = Action<int, int>(
        execute: (value) {
          calls++;
          return value + 1;
        },
      );
      final subscription = action.state.subscribe(() {
        if (action.state.peek().pending) action.dispose();
      });
      expect(await action.run(5), 6);
      expect(calls, 1);
      expect(action.state.peek().pending, isTrue);
      subscription.dispose();
    },
  );

  test('a terminal-state listener can start the next operation', () async {
    final gates = [Completer<int>(), Completer<int>()];
    var calls = 0;
    final action = Action<int, int>(execute: (_) => gates[calls++].future);
    Future<int>? next;
    final subscription = action.state.subscribe(() {
      final state = action.state.peek();
      if (state.hasValue && state.value == 1) next = action.run(2);
    });
    final first = action.run(1);
    await Future<void>.delayed(Duration.zero);
    gates[0].complete(1);
    expect(await first, 1);
    expect(next, isNotNull);
    expect(action.state.peek().pending, isTrue);
    gates[1].complete(2);
    expect(await next, 2);
    expect(action.state.peek().value, 2);
    subscription.dispose();
    action.dispose();
  });

  test('reconfiguration only affects operations accepted afterwards', () async {
    final gate = Completer<int>();
    final action = Action<int, int>(execute: (_) => gate.future);
    final first = action.run(1);
    updateAction(action, execute: (value) => value * 10);
    gate.complete(3);
    expect(await first, 3);
    expect(await action.run(2), 20);
    action.dispose();
  });

  test('writer reads do not subscribe a calling effect', () async {
    final value = Value(1);
    final action = Action<void, int>(execute: (_) => value.value);
    expect(await action.run(null), 1);
    value.value = 2;
    await Future<void>.delayed(Duration.zero);
    expect(action.state.peek().value, 1);
    action.dispose();
  });

  test(
    'accepted writes keep their result when a nonreactive namespace changes',
    () async {
      var namespace = Object();
      final resources = Resources(
        namespace: () => namespace,
        maxIdle: 1,
        retain: const Duration(minutes: 1),
      );
      final gate = Completer<int>();
      final family = Family<int, Action<int, int>>(
        create: (_) => Action(execute: (_) => gate.future),
        dispose: (action) => action.dispose(),
      );
      late Action<int, int> accepted;
      final result = resources.use(family(1), (action) {
        accepted = action;
        return action.run(1);
      });
      await Future<void>.delayed(Duration.zero);
      final pending = accepted.state.peek();
      namespace = Object();
      gate.complete(42);
      expect(await result, 42);
      expect(accepted.state.peek(), same(pending));
      await expectLater(
        accepted.run(2),
        throwsA(reason(ResourceReason.disposed)),
      );
      resources.dispose();
    },
  );
}
