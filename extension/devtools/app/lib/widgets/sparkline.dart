part of '../main.dart';

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const bars = [0.3, 0.5, 0.7, 0.4, 0.6, 0.8, 0.5, 0.9];
    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in bars)
            Container(
              width: 10,
              height: 28 * value,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    );
  }
}
