part of '../main.dart';

class _PanelPlaceholder extends StatelessWidget {
  const _PanelPlaceholder({required this.info, required this.icon});

  final _PanelInfo info;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassPill(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: OrefPalette.indigo.withValues(alpha: 0.2),
                child: const Text('UI in progress'),
              ),
              const Spacer(),
              Icon(icon, size: 28, color: OrefPalette.teal),
            ],
          ),
          const SizedBox(height: 16),
          Text(info.title, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(info.description, style: textTheme.bodyLarge),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 860;
              final bulletCard = _GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What you will get', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (final bullet in info.bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8),
                            const SizedBox(width: 8),
                            Expanded(child: Text(bullet)),
                          ],
                        ),
                      ),
                  ],
                ),
              );

              final previewCard = _GlassCard(
                padding: const EdgeInsets.all(20),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x2222E3C4), Color(0x116C5CFF)],
                    ),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.grid_view_rounded, size: 48),
                  ),
                ),
              );

              return isStacked
                  ? Column(
                      children: [
                        bulletCard,
                        const SizedBox(height: 20),
                        previewCard,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 3, child: bulletCard),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: previewCard),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}
