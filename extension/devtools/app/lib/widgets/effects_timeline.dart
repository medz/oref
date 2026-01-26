part of '../main.dart';

class _EffectsTimeline extends StatelessWidget {
  const _EffectsTimeline({required this.entries});

  final List<Sample> entries;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Positioned(
            left: _effectsTimelineLineLeft,
            top: 0,
            bottom: 0,
            child: Container(
              width: _effectsTimelineLineWidth,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No effects match the current filters.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _effectsTimelineHorizontalPadding,
                vertical: 16,
              ),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _EffectRow(entry: entries[index]),
                    if (index != entries.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
