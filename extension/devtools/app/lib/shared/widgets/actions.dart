import 'package:flutter/material.dart';

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
