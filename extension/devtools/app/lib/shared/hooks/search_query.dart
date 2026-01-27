import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oref/oref.dart' as oref;

class SearchQueryState {
  const SearchQueryState({required this.controller, required this.query});

  final TextEditingController controller;
  final oref.WritableSignal<String> query;
}

class _DebounceHolder {
  Timer? timer;

  void cancel() {
    timer?.cancel();
    timer = null;
  }
}

class _ListenerState {
  _ListenerState(this.listener, this.holder);

  final VoidCallback listener;
  final _DebounceHolder holder;
}

SearchQueryState useSearchQueryState(
  BuildContext context, {
  required String debugLabel,
  String initialValue = '',
  Duration debounce = Duration.zero,
}) {
  final controller = oref.useMemoized(
    context,
    () => TextEditingController(text: initialValue),
  );
  final query = oref.signal(context, initialValue, debugLabel: debugLabel);
  final listenerState = oref.useMemoized(context, () {
    final holder = _DebounceHolder();
    void handle() {
      if (debounce == Duration.zero) {
        query.set(controller.text);
        return;
      }
      holder.cancel();
      holder.timer = Timer(debounce, () {
        query.set(controller.text);
      });
    }

    controller.addListener(handle);
    return _ListenerState(handle, holder);
  });
  oref.onUnmounted(context, () {
    listenerState.holder.cancel();
    controller.removeListener(listenerState.listener);
    controller.dispose();
  });
  return SearchQueryState(controller: controller, query: query);
}
