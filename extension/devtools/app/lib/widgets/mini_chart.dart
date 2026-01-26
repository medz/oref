part of '../main.dart';

class _MiniChart extends StatelessWidget {
  const _MiniChart({
    required this.values,
    required this.icon,
    required this.caption,
    required this.color,
  });

  final List<int> values;
  final IconData icon;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return _ChartPlaceholder(icon: icon, caption: caption);
    }
    final maxValue = values.fold<int>(1, (max, value) {
      return value > max ? value : max;
    });

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barMaxHeight = constraints.maxHeight;
                  final barCount = values.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < barCount; index++) ...[
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: barMaxHeight * (values[index] / maxValue),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        if (index != barCount - 1) const SizedBox(width: 6),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    caption,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
