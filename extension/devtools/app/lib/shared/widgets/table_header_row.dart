import 'package:flutter/material.dart';

class TableHeaderRow extends StatelessWidget {
  const TableHeaderRow({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: child,
    );
  }
}
