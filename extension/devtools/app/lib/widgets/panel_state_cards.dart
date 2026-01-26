part of '../main.dart';

class _ConnectionGuard extends StatelessWidget {
  const _ConnectionGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    if (!controller.connected) {
      return const _PanelStateCard(
        icon: Icons.link_off_rounded,
        title: 'No app connected',
        message: 'Run your Flutter app and open DevTools to connect.',
      );
    }
    if (controller.isUnavailable) {
      return const _PanelStateCard(
        icon: Icons.extension_off_rounded,
        title: 'DevTools not active',
        message:
            'Diagnostics auto-register after the first signal/computed/effect '
            'in debug mode. Interact with the app to activate.',
      );
    }
    if (controller.isConnecting && controller.snapshot == null) {
      return const _PanelLoadingCard();
    }
    if (controller.hasError && controller.snapshot == null) {
      return _PanelStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Connection error',
        message: controller.errorMessage ?? 'Unable to reach the VM service.',
      );
    }
    return child;
  }
}

class _PanelStateCard extends StatelessWidget {
  const _PanelStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassCard(
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

class _PanelLoadingCard extends StatelessWidget {
  const _PanelLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassCard(
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
