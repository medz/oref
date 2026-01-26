part of '../main.dart';

class _DiffToken extends StatelessWidget {
  const _DiffToken({required this.delta});

  final CollectionDelta delta;

  @override
  Widget build(BuildContext context) {
    final style = _deltaStyles[delta.kind] ?? OrefPalette.indigo;
    final prefix = switch (delta.kind) {
      'add' => '+',
      'remove' => '-',
      _ => '±',
    };

    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: style.withValues(alpha: 0.18),
      child: Text('$prefix ${delta.label}'),
    );
  }
}
