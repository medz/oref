import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #31', () {
    // Issue #31: onEffectDispose should run when the widget is unmounted.
    testWidgets('onEffectDispose runs when widget is unmounted', (
      tester,
    ) async {
      bool disposed = false;
      bool showChild = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, updateState) {
              setState = updateState;
              return showChild
                  ? _EffectDisposeProbe(
                      onDispose: () {
                        disposed = true;
                      },
                    )
                  : const SizedBox();
            },
          ),
        ),
      );

      expect(disposed, isFalse);

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(disposed, isTrue);
    });

    // Issue #31: onEffectDispose should run once after effect re-executions.
    testWidgets(
      'onEffectDispose runs once after multiple effect re-executions',
      (tester) async {
        final count = signal<int>(null, 0);
        int runCount = 0;
        int disposeCount = 0;
        bool showChild = true;
        late StateSetter setState;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, updateState) {
                setState = updateState;
                return showChild
                    ? _EffectReexecProbe(
                        count: count,
                        onRun: () {
                          runCount++;
                        },
                        onDispose: () {
                          disposeCount++;
                        },
                      )
                    : const SizedBox();
              },
            ),
          ),
        );

        expect(runCount, equals(1));
        expect(disposeCount, equals(0));

        count.set(1);
        await tester.pump();

        expect(runCount, equals(2));
        expect(disposeCount, equals(0));

        showChild = false;
        setState(() {});
        await tester.pump();

        expect(disposeCount, equals(1));
      },
    );

    // Issue #31: effect scopes should dispose on widget unmount.
    testWidgets('onScopeDispose runs when widget is unmounted', (tester) async {
      bool disposed = false;
      bool showChild = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, updateState) {
              setState = updateState;
              return showChild
                  ? _ScopeDisposeProbe(
                      onDispose: () {
                        disposed = true;
                      },
                    )
                  : const SizedBox();
            },
          ),
        ),
      );

      expect(disposed, isFalse);

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(disposed, isTrue);
    });

    // Issue #31: timers created in effects should be cancelled on widget unmount.
    testWidgets('timer is cancelled when widget is unmounted', (tester) async {
      Timer? timer;
      bool showChild = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, updateState) {
              setState = updateState;
              return showChild
                  ? _TimerDisposeProbe(
                      onCreate: (created) {
                        timer = created;
                      },
                    )
                  : const SizedBox();
            },
          ),
        ),
      );

      expect(timer, isNotNull);
      expect(timer!.isActive, isTrue);

      showChild = false;
      setState(() {});
      await tester.pump();

      expect(timer!.isActive, isFalse);
    });

    // Issue #31: controllers created in effects should be disposed on widget unmount.
    testWidgets(
      'TextEditingController is disposed when widget is unmounted',
      (tester) async {
        _TestTextController? controller;
        bool showChild = true;
        late StateSetter setState;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, updateState) {
                setState = updateState;
                return showChild
                    ? _ControllerDisposeProbe(
                        onCreate: (created) {
                          controller = created;
                        },
                      )
                    : const SizedBox();
              },
            ),
          ),
        );

        expect(controller, isNotNull);
        expect(controller!.disposed, isFalse);

        showChild = false;
        setState(() {});
        await tester.pump();

        expect(controller!.disposed, isTrue);
      },
    );
  });
}

class _EffectDisposeProbe extends StatelessWidget {
  const _EffectDisposeProbe({required this.onDispose});

  final VoidCallback onDispose;

  @override
  Widget build(BuildContext context) {
    effect(context, () {
      onEffectDispose(onDispose);
    });
    return const SizedBox();
  }
}

class _EffectReexecProbe extends StatelessWidget {
  const _EffectReexecProbe({
    required this.count,
    required this.onRun,
    required this.onDispose,
  });

  final WritableSignal<int> count;
  final VoidCallback onRun;
  final VoidCallback onDispose;

  @override
  Widget build(BuildContext context) {
    effect(context, () {
      count();
      onRun();
      onEffectDispose(onDispose);
    });
    return const SizedBox();
  }
}

class _ScopeDisposeProbe extends StatelessWidget {
  const _ScopeDisposeProbe({required this.onDispose});

  final VoidCallback onDispose;

  @override
  Widget build(BuildContext context) {
    effectScope(context, () {
      onScopeDispose(onDispose);
    });
    return const SizedBox();
  }
}

class _TimerDisposeProbe extends StatelessWidget {
  const _TimerDisposeProbe({required this.onCreate});

  final ValueSetter<Timer> onCreate;

  @override
  Widget build(BuildContext context) {
    effect(context, () {
      final timer = Timer(const Duration(days: 1), () {});
      onCreate(timer);
      onEffectDispose(timer.cancel);
    });
    return const SizedBox();
  }
}

class _ControllerDisposeProbe extends StatelessWidget {
  const _ControllerDisposeProbe({required this.onCreate});

  final ValueSetter<_TestTextController> onCreate;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(context, _TestTextController.new);
    onCreate(controller);
    effect(context, () {
      onEffectDispose(controller.dispose);
    });
    return const SizedBox();
  }
}

class _TestTextController extends TextEditingController {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
