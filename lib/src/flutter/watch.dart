import 'package:flutter/widgets.dart';

import 'observed_state.dart';

/// Rebuilds when the Readable values read synchronously by [builder] change.
class Watch extends StatefulWidget {
  const Watch({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<Watch> createState() => _WatchState();
}

class _WatchState extends ObservedState<Watch> {
  @override
  Widget build(BuildContext context) => observe(() => widget.builder(context));
}
