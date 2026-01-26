part of '../main.dart';

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyles[status] ?? _statusStyles['Active']!;
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: style.color.withValues(alpha: 0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(status),
        ],
      ),
    );
  }
}
