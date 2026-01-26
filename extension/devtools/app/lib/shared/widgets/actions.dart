import 'package:flutter/material.dart';

import '../../app/palette.dart';
import 'glass.dart';

class ActionPill extends StatelessWidget {
  const ActionPill({
    required this.label,
    required this.icon,
    this.iconOnly = false,
    this.onTap,
    this.padding,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool iconOnly;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final resolvedPadding = iconOnly ? const EdgeInsets.all(10) : padding;
    final content = GlassPill(
      padding: resolvedPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          if (!iconOnly) ...[
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ],
      ),
    );

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: iconOnly ? Tooltip(message: label, child: content) : content,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [OrefPalette.teal, OrefPalette.indigo],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6622E3C4),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
        ),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  const OutlineButton({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = Theme.of(context).colorScheme.onSurface;
    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ),
    );
  }
}
