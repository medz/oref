import 'package:flutter/material.dart';

import 'actions.dart';
import 'glass.dart';
import 'live_badge.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.description,
    required this.filteredCount,
    required this.totalCount,
    required this.onExport,
    this.exportLabel = 'Export',
    this.countText,
    this.showLiveBadge = true,
    this.children = const <Widget>[],
  });

  final String title;
  final String description;
  final int filteredCount;
  final int totalCount;
  final VoidCallback onExport;
  final String exportLabel;
  final String? countText;
  final bool showLiveBadge;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: textTheme.headlineSmall),
            if (showLiveBadge) ...[
              const SizedBox(width: 12),
              const LiveBadge(),
            ],
            const Spacer(),
            GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(countText ?? '$filteredCount / $totalCount'),
            ),
            const SizedBox(width: 12),
            ActionPill(
              label: exportLabel,
              icon: Icons.download_rounded,
              onTap: onExport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(description, style: textTheme.bodyMedium),
        if (children.isNotEmpty) ...[const SizedBox(height: 12), ...children],
      ],
    );
  }
}
