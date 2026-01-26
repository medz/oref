part of '../main.dart';

class _ComputedDetail extends StatelessWidget {
  const _ComputedDetail({required this.entry});

  final Sample? entry;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Select a computed value to view details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry!.label, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _StatusBadge(status: entry!.status ?? 'Active'),
          const SizedBox(height: 16),
          _InfoRow(label: 'Owner', value: entry!.owner),
          _InfoRow(label: 'Scope', value: entry!.scope),
          _InfoRow(label: 'Type', value: entry!.type),
          _InfoRow(label: 'Value', value: entry!.value ?? ''),
          _InfoRow(label: 'Updated', value: _formatAge(entry!.updatedAt)),
          _InfoRow(label: 'Runs', value: '${entry!.runs ?? 0}'),
          _InfoRow(
            label: 'Last run',
            value: _formatDurationUs(entry!.lastDurationUs ?? 0),
          ),
          _InfoRow(label: 'Listeners', value: '${entry!.listeners ?? 0}'),
          _InfoRow(label: 'Deps', value: '${entry!.dependencies ?? 0}'),
          if (entry!.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(entry!.note, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
