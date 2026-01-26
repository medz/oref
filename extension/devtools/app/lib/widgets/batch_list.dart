part of '../main.dart';

class _BatchList extends StatelessWidget {
  const _BatchList({required this.batches, required this.isCompact});

  final List<BatchSample> batches;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact) const _BatchHeaderRow(),
          if (batches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No batches recorded yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < batches.length; index++) ...[
                    _BatchRow(batch: batches[index], isCompact: isCompact),
                    if (index != batches.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
