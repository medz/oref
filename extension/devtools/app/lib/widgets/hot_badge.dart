part of '../main.dart';

class _HotBadge extends StatelessWidget {
  const _HotBadge();

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: OrefPalette.coral.withValues(alpha: 0.25),
      child: Text('HOT', style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
