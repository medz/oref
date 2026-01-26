part of '../main.dart';

class _PerformanceList extends StatelessWidget {
  const _PerformanceList({required this.samples});

  final List<UiPerformanceSample> samples;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: samples.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No performance samples yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var index = 0; index < samples.length; index++) ...[
                    _PerformanceRow(sample: samples[index]),
                    if (index != samples.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}
