part of '../main.dart';

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.entry, required this.isCompact});

  final Sample entry;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final tone =
        _collectionOpColors[entry.operation ?? 'Idle'] ?? OrefPalette.teal;
    final textTheme = Theme.of(context).textTheme;

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: DefaultTextStyle.merge(
        style: textTheme.bodyMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(entry.type),
                      ),
                      _GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: tone.withValues(alpha: 0.22),
                        child: Text(entry.operation ?? 'Idle'),
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
                        child: Text(_formatAge(entry.updatedAt)),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(entry.label, textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(entry.type, textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: _GlassPill(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: tone.withValues(alpha: 0.22),
                        child: Text(entry.operation ?? 'Idle'),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(entry.scope, textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatAge(entry.updatedAt),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final delta in entry.deltas ?? const [])
                  _DiffToken(delta: delta),
              ],
            ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(entry.note, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
