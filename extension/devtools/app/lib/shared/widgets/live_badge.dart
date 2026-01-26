import 'package:flutter/material.dart';

import 'glass.dart';

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassPill(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text('Live'),
    );
  }
}
