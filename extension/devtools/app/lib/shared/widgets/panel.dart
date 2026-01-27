import 'package:flutter/material.dart';

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
