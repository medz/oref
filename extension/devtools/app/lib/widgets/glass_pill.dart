part of '../main.dart';

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tint =
        color ??
        (brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.9));

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.labelMedium,
            child: child,
          ),
        ),
      ),
    );
  }
}
