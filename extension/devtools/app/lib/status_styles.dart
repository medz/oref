part of 'main.dart';

class _StatusStyle {
  const _StatusStyle(this.color);

  final Color color;
}

const _statusStyles = {
  'Active': _StatusStyle(OrefPalette.lime),
  'Dirty': _StatusStyle(OrefPalette.coral),
  'Disposed': _StatusStyle(Color(0xFF8B97A8)),
};
