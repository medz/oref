part of '../main.dart';

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final String subtitle;
  final List<_InsightRow> primary;
  final List<_InsightRow> secondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: textTheme.bodySmall),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 420;
              final primaryColumn = Column(
                children: [for (final row in primary) row],
              );
              final secondaryColumn = Column(
                children: [for (final row in secondary) row],
              );

              return isStacked
                  ? Column(
                      children: [
                        primaryColumn,
                        const SizedBox(height: 12),
                        secondaryColumn,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: primaryColumn),
                        const SizedBox(width: 16),
                        Expanded(child: secondaryColumn),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}
