import 'package:flutter/material.dart';
import 'package:oref/oref.dart' as oref;

class SearchQueryState {
  const SearchQueryState({required this.controller, required this.query});

  final TextEditingController controller;
  final oref.WritableSignal<String> query;
}

SearchQueryState useSearchQueryState(
  BuildContext context, {
  required String debugLabel,
  String initialValue = '',
}) {
  final controller = oref.useMemoized(
    context,
    () => TextEditingController(text: initialValue),
  );
  final query = oref.signal(context, initialValue, debugLabel: debugLabel);
  final listener = oref.useMemoized(context, () {
    void handle() {
      query.set(controller.text);
    }

    controller.addListener(handle);
    return handle;
  });
  oref.onUnmounted(context, () {
    controller.removeListener(listener);
    controller.dispose();
  });
  return SearchQueryState(controller: controller, query: query);
}
