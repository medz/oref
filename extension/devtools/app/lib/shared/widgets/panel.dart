import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/palette.dart';
import '../../app/scopes.dart';
import 'glass.dart';

class PanelScrollView extends StatelessWidget {
  const PanelScrollView({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

class PanelPlaceholder extends StatelessWidget {
  const PanelPlaceholder({required this.info, required this.icon, super.key});

  final PanelInfo info;
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
              GlassPill(
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
              final bulletCard = GlassCard(
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

              final previewCard = GlassCard(
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

class ConnectionGuard extends StatelessWidget {
  const ConnectionGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    if (!controller.connected) {
      return const PanelStateCard(
        icon: Icons.link_off_rounded,
        title: 'No app connected',
        message: 'Run your Flutter app and open DevTools to connect.',
      );
    }
    if (controller.isUnavailable) {
      return const PanelStateCard(
        icon: Icons.extension_off_rounded,
        title: 'DevTools not active',
        message:
            'Diagnostics auto-register after the first signal/computed/effect '
            'in debug mode. Interact with the app to activate.',
      );
    }
    if (controller.isConnecting && controller.snapshot == null) {
      return const PanelLoadingCard();
    }
    if (controller.hasError && controller.snapshot == null) {
      return PanelStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Connection error',
        message: controller.errorMessage ?? 'Unable to reach the VM service.',
      );
    }
    return child;
  }
}

class PanelStateCard extends StatelessWidget {
  const PanelStateCard({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: OrefPalette.coral),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class PanelLoadingCard extends StatelessWidget {
  const PanelLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Connecting to Oref diagnostics...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
