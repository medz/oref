part of '../main.dart';

class _EffectRow extends StatelessWidget {
  const _EffectRow({required this.entry});

  final Sample entry;

  @override
  Widget build(BuildContext context) {
    final tone = _effectColors[entry.type] ?? OrefPalette.teal;
    final runs = entry.runs ?? 0;
    final durationUs = entry.lastDurationUs ?? 0;
    final isHot = durationUs > 16000 || runs >= 8;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _effectsTimelineDotSize,
          height: _effectsTimelineDotSize,
          margin: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            color: tone,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: tone.withValues(alpha: 0.4), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (isHot) const _HotBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.note.isEmpty
                      ? 'Last run ${_formatAge(entry.updatedAt)}'
                      : entry.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: tone.withValues(alpha: 0.2),
                      child: Text(entry.type),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(entry.scope),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text('Runs $runs'),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: durationUs > 16000
                          ? OrefPalette.coral.withValues(alpha: 0.2)
                          : OrefPalette.lime.withValues(alpha: 0.2),
                      child: Text(_formatDurationUs(durationUs)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
