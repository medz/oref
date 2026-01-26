import 'package:flutter/material.dart';

import 'actions.dart';
import 'glass.dart';
import 'live_badge.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.description,
    this.filteredCount,
    this.totalCount,
    this.onExport,
    this.exportLabel = 'Export',
    this.countText,
    this.showLiveBadge = true,
    this.children = const <Widget>[],
  }) : assert(
         countText != null ||
             (filteredCount == null && totalCount == null) ||
             (filteredCount != null && totalCount != null),
         'Provide countText or both filteredCount and totalCount.',
       );

  final String title;
  final String description;
  final int? filteredCount;
  final int? totalCount;
  final VoidCallback? onExport;
  final String exportLabel;
  final String? countText;
  final bool showLiveBadge;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const headerPillPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final showCountPill =
        countText != null || (filteredCount != null && totalCount != null);
    final showExport = onExport != null;

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
            if (showCountPill)
              GlassPill(
                padding: headerPillPadding,
                child: Text(countText ?? '$filteredCount / $totalCount'),
              ),
            if (showCountPill && showExport) const SizedBox(width: 12),
            if (showExport)
              ActionPill(
                label: exportLabel,
                icon: Icons.download_rounded,
                onTap: onExport,
                padding: headerPillPadding,
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
