import 'package:flutter/material.dart';

class SortHeaderCell extends StatelessWidget {
  const SortHeaderCell({
    required this.label,
    required this.isActive,
    required this.ascending,
    required this.onTap,
    required this.style,
    super.key,
  });

  final String label;
  final bool isActive;
  final bool ascending;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final icon = ascending ? Icons.arrow_drop_up : Icons.arrow_drop_down;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: style),
                if (isActive) Icon(icon, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
