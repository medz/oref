import 'package:flutter/material.dart';

class InlineEmptyState extends StatelessWidget {
  const InlineEmptyState({
    required this.message,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final String message;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
