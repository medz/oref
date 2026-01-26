part of '../main.dart';

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.icon, required this.caption});

  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0x3322E3C4), Color(0x226C5CFF)],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 48),
          Positioned(
            bottom: 12,
            right: 12,
            child: _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(caption),
            ),
          ),
        ],
      ),
    );
  }
}
