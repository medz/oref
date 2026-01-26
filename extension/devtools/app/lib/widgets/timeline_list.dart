part of '../main.dart';

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: events.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No timeline events yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var index = 0; index < events.length; index++) ...[
                    _TimelineEventRow(event: events[index]),
                    if (index != events.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}
