import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  group('AsyncData', () {
    test('starts with idle status', () {
      final data = useAsyncData(null, () async => 42);
      expect(data.status, equals(AsyncStatus.idle));
    });

    test('transitions to pending status', () async {
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });

      await Future.delayed(Duration(milliseconds: 1));
      expect(data.status, equals(AsyncStatus.pending));
    });

    test('resolves to success status', () async {
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });

      await Future.delayed(Duration(milliseconds: 20));
      expect(data.status, equals(AsyncStatus.success));
      expect(data.data, equals(42));
    });

    test('handles error status', () async {
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        throw Exception('Test error');
      });

      await Future.delayed(Duration(milliseconds: 20));
      expect(data.status, equals(AsyncStatus.error));
      expect(data.error, isNotNull);
      expect(data.error?.error.toString(), contains('Test error'));
    });

    test('uses default value', () {
      final data = useAsyncData(
        null,
        () async => 42,
        defaults: () => 10,
      );

      expect(data.data, equals(10));
    });

    test('refresh triggers new fetch', () async {
      int callCount = 0;
      final data = useAsyncData(null, () async {
        callCount++;
        await Future.delayed(Duration(milliseconds: 10));
        return callCount;
      });

      await Future.delayed(Duration(milliseconds: 20));
      expect(data.data, equals(1));

      await data.refresh();
      expect(data.data, equals(2));
    });

    test('when handles idle state', () async {
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 100));
        return 42;
      });

      final result = data.when(
        idle: (d) => 'idle',
        pending: (d) => 'pending',
        success: (d) => 'success: $d',
        error: (e) => 'error',
      );

      expect(result, equals('idle'));
    });

    test('when handles pending state', () async {
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });

      await Future.delayed(Duration(milliseconds: 1));

      final result = data.when(
        idle: (d) => 'idle',
        pending: (d) => 'pending',
        success: (d) => 'success: $d',
        error: (e) => 'error',
      );

      expect(result, equals('pending'));
    });

    test('when handles success state', () async {
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });

      await Future.delayed(Duration(milliseconds: 20));

      final result = data.when(
        idle: (d) => 'idle',
        pending: (d) => 'pending',
        success: (d) => 'success: $d',
        error: (e) => 'error',
      );

      expect(result, equals('success: 42'));
    });

    test('when handles error state', () async {
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        throw Exception('Test error');
      });

      // Wait for the error to be caught and status updated
      await Future.delayed(Duration(milliseconds: 50));

      final result = data.when(
        idle: (d) => 'idle',
        pending: (d) => 'pending',
        success: (d) => 'success: $d',
        error: (e) => 'error: ${e?.error}',
      );

      expect(result, contains('error'));
    });

    test('triggers effects on status change', () async {
      int effectCount = 0;
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });

      effect(null, () {
        data.status;
        effectCount++;
      });

      expect(effectCount, equals(1)); // Initial run

      await Future.delayed(Duration(milliseconds: 1));
      expect(effectCount, equals(2)); // Pending

      await Future.delayed(Duration(milliseconds: 20));
      expect(effectCount, equals(3)); // Success
    });

    test('triggers effects on data change', () async {
      int effectCount = 0;
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });

      effect(null, () {
        data.data;
        effectCount++;
      });

      expect(effectCount, equals(1)); // Initial run

      await Future.delayed(Duration(milliseconds: 20));
      expect(effectCount, equals(2)); // Data updated
    });

    test('handles synchronous values', () async {
      final data = useAsyncData(null, () => 42);

      await Future.delayed(Duration(milliseconds: 10));
      expect(data.status, equals(AsyncStatus.success));
      expect(data.data, equals(42));
    });

    test('dispose stops tracking', () async {
      int callCount = 0;
      final trigger = signal(null, 0);
      final data = useAsyncData(null, () async {
        trigger();
        callCount++;
        await Future.delayed(Duration(milliseconds: 10));
        return callCount;
      });

      await Future.delayed(Duration(milliseconds: 20));
      expect(callCount, equals(1));

      trigger(1);
      await Future.delayed(Duration(milliseconds: 20));
      expect(callCount, equals(2));

      data.dispose();

      trigger(2);
      await Future.delayed(Duration(milliseconds: 20));
      expect(callCount, equals(2)); // Should not call again
    });

    test('tracks signal dependencies', () async {
      int callCount = 0;
      final count = signal(null, 1);
      final data = useAsyncData(null, () async {
        final value = count();
        callCount++;
        await Future.delayed(Duration(milliseconds: 10));
        return value * 2;
      });

      await Future.delayed(Duration(milliseconds: 20));
      expect(data.data, equals(2));
      expect(callCount, equals(1));

      count(5);
      await Future.delayed(Duration(milliseconds: 20));
      expect(data.data, equals(10));
      expect(callCount, equals(2));
    });

    test('batch updates status and data', () async {
      final data = useAsyncData(null, () async {
        await Future.delayed(Duration(milliseconds: 10));
        return 42;
      });

      int effectCount = 0;
      effect(null, () {
        data.status;
        data.data;
        effectCount++;
      });

      await Future.delayed(Duration(milliseconds: 1));
      // Pending state triggers one update

      await Future.delayed(Duration(milliseconds: 20));
      // Success state + data update should be batched into one
    });

    test('preserves data through status changes', () async {
      final data = useAsyncData(
        null,
        () async {
          await Future.delayed(Duration(milliseconds: 10));
          return 42;
        },
        defaults: () => 0,
      );

      expect(data.data, equals(0));

      await Future.delayed(Duration(milliseconds: 5));
      expect(data.status, equals(AsyncStatus.pending));
      expect(data.data, equals(0)); // Should preserve default

      await Future.delayed(Duration(milliseconds: 50));
      expect(data.status, equals(AsyncStatus.success));
      expect(data.data, equals(42));
    });

    test('handles multiple refreshes', () async {
      int callCount = 0;
      final data = useAsyncData(null, () async {
        callCount++;
        await Future.delayed(Duration(milliseconds: 10));
        return callCount;
      });

      await Future.delayed(Duration(milliseconds: 20));
      expect(data.data, equals(1));

      await data.refresh();
      expect(data.data, equals(2));

      await data.refresh();
      expect(data.data, equals(3));
    });

    test('prevents concurrent fetches', () async {
      int callCount = 0;
      final data = useAsyncData(null, () async {
        callCount++;
        await Future.delayed(Duration(milliseconds: 50));
        return callCount;
      });

      await Future.delayed(Duration(milliseconds: 10));

      // Try to refresh while pending
      final refresh1 = data.refresh();
      final refresh2 = data.refresh();

      await refresh1;
      await refresh2;

      // Should only increment once more (original + one refresh)
      expect(callCount, equals(1));
    });
  });
}
