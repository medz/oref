part of '../main.dart';

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding, this.width});

  final Widget child;
  final EdgeInsets? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tint = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.7);

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
