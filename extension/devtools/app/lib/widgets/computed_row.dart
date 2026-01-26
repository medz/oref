part of '../main.dart';

class _ComputedRow extends StatelessWidget {
  const _ComputedRow({
    required this.entry,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final Sample entry;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlight = isSelected
        ? OrefPalette.indigo.withValues(alpha: 0.2)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: highlight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? OrefPalette.indigo.withValues(alpha: 0.4)
                  : colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.label),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatusBadge(status: entry.status ?? 'Active'),
                        _GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text('${entry.runs ?? 0} runs'),
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
                    const SizedBox(height: 8),
                    Text(
                      entry.value ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(entry.label, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            entry.owner,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.center,
                        child: _StatusBadge(status: entry.status ?? 'Active'),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${entry.runs ?? 0}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatAge(entry.updatedAt),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
