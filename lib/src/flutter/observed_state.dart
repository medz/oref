import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/alien_adapter.dart';

/// Keeps scheduling local to this State, including invalidation during build.
abstract class RebuildState<W extends StatefulWidget> extends State<W> {
  bool _requested = false;
  bool _deferred = false;
  bool _building = false;

  void requestRebuild() {
    if (!mounted || _requested) return;
    _requested = true;
    if (_building ||
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks) {
      if (_deferred) return;
      _deferred = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _deferred = false;
        if (mounted && _requested) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  R buildSafely<R>(R Function() build) {
    _requested = false;
    _building = true;
    try {
      return build();
    } finally {
      _building = false;
    }
  }
}

abstract class ObservedState<W extends StatefulWidget> extends RebuildState<W> {
  late ReactiveObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = ReactiveObserver(requestRebuild);
  }

  Widget observe(Widget Function() build) =>
      buildSafely(() => _observer.track(build));

  void resetObservation() {
    _observer.dispose();
    _observer = ReactiveObserver(requestRebuild);
  }

  void stopObserving() => _observer.dispose();

  @override
  void dispose() {
    stopObserving();
    super.dispose();
  }
}
