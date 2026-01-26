part of '../main.dart';

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.sample});

  final UiPerformanceSample sample;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle.merge(
        style: textTheme.bodyMedium,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                _formatAge(sample.timestamp),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${sample.signalWrites} writes',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${sample.effectRuns} runs',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatDurationUs(sample.avgEffectDurationUs.round()),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${sample.collectionMutations} mutations',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
