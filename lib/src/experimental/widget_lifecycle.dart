import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/system.dart' as alien;
import 'package:alien_signals/preset_developer.dart' as alien;
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

import '../core/_disposable.dart';

void onMounted(BuildContext context, void Function() callback) {
  final lifecycle = _Lifecycle(context), prevSub = alien.setActiveSub(null);
  try {
    if (lifecycle.shouldRunMountedCallback && context.mounted) {
      callback();
    }
  } finally {
    alien.setActiveSub(prevSub);
  }
}

@Deprecated("We haven't found a better way to do it yet.")
void onUnmounted(BuildContext context, void Function() callback) {
  final lifecycle = _Lifecycle(context);
  lifecycle.unmountedCallbacks.add(callback);
}

void onUpdated(BuildContext context, void Function() callback) {
  final lifecycle = _Lifecycle(context),
      effect = useWidgetEffect(context) as alien.ReactiveNode,
      prevSub = alien.setActiveSub(effect);

  lifecycle.updatedCallbacks.add(callback);
  try {
    onEffectCleanup(lifecycle.update);
  } finally {
    alien.setActiveSub(prevSub);
  }
}

class _Lifecycle extends alien.ReactiveNode implements Disposable {
  static final store = Expando<_Lifecycle>("oref:widget lifecycle");

  _Lifecycle._({required this.context}) : super(flags: 0);

  factory _Lifecycle(BuildContext context) {
    final cached = store[context];
    if (cached != null) return cached;

    final lifecycle = _Lifecycle._(context: context),
        effect = useWidgetEffect(context);
    alien.system.link(lifecycle, effect as alien.ReactiveNode, 0);

    store[context] = lifecycle;
    return lifecycle;
  }

  final BuildContext context;
  late final unmountedCallbacks = <void Function()>[];
  late final updatedCallbacks = <void Function()>[];

  bool shouldRunMountedCallback = true;

  void update() {
    final prevCallbacks = [...updatedCallbacks];

    shouldRunMountedCallback = false;
    unmountedCallbacks.clear();
    updatedCallbacks.clear();

    for (final callback in prevCallbacks) {
      callback();
    }
  }

  @override
  void dispose() {
    final prevCallbacks = [...unmountedCallbacks];
    updatedCallbacks.clear();

    for (final callback in prevCallbacks) {
      callback();
    }
  }
}
