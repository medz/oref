import 'package:flutter/material.dart';

class AdaptiveWrap extends StatelessWidget {
  const AdaptiveWrap({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minItemWidth = 220.0;
        const maxColumns = 4;
        const spacing = 16.0;
        const runSpacing = 16.0;
        final available = constraints.maxWidth;
        final rawColumns = (available / (minItemWidth + spacing)).floor();
        final columns = rawColumns.clamp(1, maxColumns);
        final width =
            (available - (columns - 1) * spacing) / columns.toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
