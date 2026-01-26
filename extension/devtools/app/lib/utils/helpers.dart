part of '../main.dart';

List<Sample> _samplesByKind(List<Sample> samples, String kind) {
  return samples.where((sample) => sample.kind == kind).toList();
}

String _formatAge(int? timestamp) {
  if (timestamp == null || timestamp == 0) return '—';
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  final diff = now - timestamp;
  if (diff < 0) return 'just now';
  if (diff < 1000) return '${diff}ms ago';
  final seconds = diff ~/ 1000;
  if (seconds < 60) return '${seconds}s ago';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m ago';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}h ago';
  final days = hours ~/ 24;
  return '${days}d ago';
}

String _formatDurationUs(int durationUs) {
  if (durationUs <= 0) return '<1us';
  if (durationUs < 1000) return '${durationUs}us';
  final ms = durationUs / 1000;
  if (ms < 10) {
    return '${ms.toStringAsFixed(2)}ms';
  }
  if (ms < 100) {
    return '${ms.toStringAsFixed(1)}ms';
  }
  return '${ms.round()}ms';
}

String _formatTimelineDetail(TimelineEvent event) {
  final durationUs = event.durationUs;
  switch (event.type) {
    case 'computed':
      return durationUs == null
          ? event.detail
          : 'Recomputed in ${_formatDurationUs(durationUs)}';
    case 'effect':
      return durationUs == null
          ? event.detail
          : 'Ran in ${_formatDurationUs(durationUs)}';
    case 'collection':
      final op = event.operation;
      return op == null ? event.detail : '$op mutation';
    case 'batch':
      if (durationUs == null && event.writeCount == null) return event.detail;
      final duration = durationUs == null ? '' : _formatDurationUs(durationUs);
      final writes = event.writeCount == null
          ? ''
          : '${event.writeCount} writes';
      if (duration.isEmpty) return writes;
      if (writes.isEmpty) return 'Batch in $duration';
      return '$writes in $duration';
    default:
      return event.detail;
  }
}

String _formatCount(int? value) {
  if (value == null) return '—';
  return value.toString();
}

String _formatDelta(int? value, {String suffix = ''}) {
  if (value == null) return '—';
  if (value == 0) return 'idle';
  final label = value > 0 ? '+$value' : value.toString();
  return suffix.isEmpty ? label : '$label $suffix';
}

int _compareSort(
  _SortKey key,
  bool ascending,
  String nameA,
  String nameB,
  int updatedA,
  int updatedB,
  int idA,
  int idB,
) {
  int result;
  if (key == _SortKey.name) {
    result = nameA.toLowerCase().compareTo(nameB.toLowerCase());
  } else {
    result = updatedA.compareTo(updatedB);
  }
  if (result == 0) {
    result = idA.compareTo(idB);
  }
  return ascending ? result : -result;
}

Future<void> _exportData(
  BuildContext context,
  String label,
  Object data,
) async {
  if (data is Iterable && data.isEmpty) {
    _showToast(context, 'No $label data to export.');
    return;
  }
  if (data is Map && data.isEmpty) {
    _showToast(context, 'No $label data to export.');
    return;
  }
  final payload = const JsonEncoder.withIndent('  ').convert(data);
  await Clipboard.setData(ClipboardData(text: payload));
  if (!context.mounted) return;
  _showToast(context, 'Copied $label JSON to clipboard.');
}

void _showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

List<String> _buildFilterOptions(Iterable<String> values) {
  final unique = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) unique.add(trimmed);
  }
  final sorted = unique.toList()..sort();
  return ['All', ...sorted];
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
