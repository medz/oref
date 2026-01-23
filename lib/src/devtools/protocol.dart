import 'dart:convert';

import 'package:flutter/foundation.dart';

class Protocol {
  static const int version = 2;

  static const String servicePrefix = 'ext.oref';
  static const String snapshotService = '$servicePrefix.snapshot';
  static const String settingsService = '$servicePrefix.settings';
  static const String updateSettingsService = '$servicePrefix.updateSettings';
  static const String clearService = '$servicePrefix.clear';
}

@immutable
class Snapshot {
  const Snapshot({
    required this.protocolVersion,
    required this.timestamp,
    required this.settings,
    required this.samples,
    required this.batches,
    required this.timeline,
  });

  final int protocolVersion;
  final int timestamp;
  final DevToolsSettings settings;
  final List<Sample> samples;
  final List<BatchSample> batches;
  final List<TimelineEvent> timeline;

  Map<String, Object?> toJson() {
    return {
      'protocolVersion': protocolVersion,
      'timestamp': timestamp,
      'settings': settings.toJson(),
      'samples': samples.map((entry) => entry.toJson()).toList(),
      'batches': batches.map((entry) => entry.toJson()).toList(),
      'timeline': timeline.map((event) => event.toJson()).toList(),
    };
  }

  factory Snapshot.fromJson(Map<String, dynamic> json) {
    return Snapshot(
      protocolVersion: _readInt(json['protocolVersion'], fallback: 0),
      timestamp: _readInt(json['timestamp'], fallback: 0),
      settings: DevToolsSettings.fromJson(_readMap(json['settings'])),
      samples: _readList(json['samples'], Sample.fromJson),
      batches: _readList(json['batches'], BatchSample.fromJson),
      timeline: _readList(json['timeline'], TimelineEvent.fromJson),
    );
  }

  static Snapshot empty() => Snapshot(
    protocolVersion: Protocol.version,
    timestamp: 0,
    settings: const DevToolsSettings(),
    samples: const [],
    batches: const [],
    timeline: const [],
  );

  static Snapshot? tryParse(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return Snapshot.fromJson(decoded);
      }
      if (decoded is Map) {
        return Snapshot.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }
}

@immutable
class DevToolsSettings {
  const DevToolsSettings({
    this.enabled = true,
    this.sampleIntervalMs = 1000,
    this.timelineLimit = 200,
    this.batchLimit = 120,
    this.performanceLimit = 180,
    this.valuePreviewLength = 120,
  });

  final bool enabled;
  final int sampleIntervalMs;
  final int timelineLimit;
  final int batchLimit;
  final int performanceLimit;
  final int valuePreviewLength;

  DevToolsSettings copyWith({
    bool? enabled,
    int? sampleIntervalMs,
    int? timelineLimit,
    int? batchLimit,
    int? performanceLimit,
    int? valuePreviewLength,
  }) {
    return DevToolsSettings(
      enabled: enabled ?? this.enabled,
      sampleIntervalMs: sampleIntervalMs ?? this.sampleIntervalMs,
      timelineLimit: timelineLimit ?? this.timelineLimit,
      batchLimit: batchLimit ?? this.batchLimit,
      performanceLimit: performanceLimit ?? this.performanceLimit,
      valuePreviewLength: valuePreviewLength ?? this.valuePreviewLength,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'sampleIntervalMs': sampleIntervalMs,
      'timelineLimit': timelineLimit,
      'batchLimit': batchLimit,
      'performanceLimit': performanceLimit,
      'valuePreviewLength': valuePreviewLength,
    };
  }

  factory DevToolsSettings.fromJson(Map<String, dynamic> json) {
    return DevToolsSettings(
      enabled: _readBool(json['enabled'], fallback: true),
      sampleIntervalMs: _readInt(json['sampleIntervalMs'], fallback: 1000),
      timelineLimit: _readInt(json['timelineLimit'], fallback: 200),
      batchLimit: _readInt(json['batchLimit'], fallback: 120),
      performanceLimit: _readInt(json['performanceLimit'], fallback: 180),
      valuePreviewLength: _readInt(json['valuePreviewLength'], fallback: 120),
    );
  }

  static DevToolsSettings mergeArgs(
    DevToolsSettings current,
    Map<String, String> args,
  ) {
    return current.copyWith(
      enabled: _parseBool(args['enabled']),
      sampleIntervalMs: _parseInt(args['sampleIntervalMs']),
      timelineLimit: _parseInt(args['timelineLimit']),
      batchLimit: _parseInt(args['batchLimit']),
      performanceLimit: _parseInt(args['performanceLimit']),
      valuePreviewLength: _parseInt(args['valuePreviewLength']),
    );
  }
}

@immutable
class Sample {
  const Sample({
    required this.id,
    required this.kind,
    required this.label,
    required this.type,
    required this.owner,
    required this.scope,
    required this.updatedAt,
    required this.note,
    this.status,
    this.value,
    this.listeners,
    this.dependencies,
    this.writes,
    this.runs,
    this.lastDurationMs,
    this.operation,
    this.deltas,
    this.mutations,
  });

  final int id;
  final String kind;
  final String label;
  final String type;
  final String owner;
  final String scope;
  final int updatedAt;
  final String note;
  final String? status;
  final String? value;
  final int? listeners;
  final int? dependencies;
  final int? writes;
  final int? runs;
  final int? lastDurationMs;
  final String? operation;
  final List<CollectionDelta>? deltas;
  final int? mutations;

  Map<String, Object?> toJson() {
    final data = <String, Object?>{
      'id': id,
      'kind': kind,
      'label': label,
      'type': type,
      'owner': owner,
      'scope': scope,
      'updatedAt': updatedAt,
      'note': note,
    };
    if (status != null) data['status'] = status;
    if (value != null) data['value'] = value;
    if (listeners != null) data['listeners'] = listeners;
    if (dependencies != null) data['dependencies'] = dependencies;
    if (writes != null) data['writes'] = writes;
    if (runs != null) data['runs'] = runs;
    if (lastDurationMs != null) data['lastDurationMs'] = lastDurationMs;
    if (operation != null) data['operation'] = operation;
    if (deltas != null) {
      data['deltas'] = deltas!.map((delta) => delta.toJson()).toList();
    }
    if (mutations != null) data['mutations'] = mutations;
    return data;
  }

  factory Sample.fromJson(Map<String, dynamic> json) {
    final deltasValue = json['deltas'];
    return Sample(
      id: _readInt(json['id'], fallback: 0),
      kind: _readString(json['kind']),
      label: _readString(json['label']),
      type: _readString(json['type']),
      owner: _readString(json['owner'], fallback: 'Global'),
      scope: _readString(json['scope'], fallback: 'Global'),
      updatedAt: _readInt(json['updatedAt'], fallback: 0),
      note: _readString(json['note']),
      status: _readOptionalString(json, 'status'),
      value: _readOptionalString(json, 'value'),
      listeners: _readOptionalInt(json, 'listeners'),
      dependencies: _readOptionalInt(json, 'dependencies'),
      writes: _readOptionalInt(json, 'writes'),
      runs: _readOptionalInt(json, 'runs'),
      lastDurationMs: _readOptionalInt(json, 'lastDurationMs'),
      operation: _readOptionalString(json, 'operation'),
      deltas: deltasValue == null
          ? null
          : _readList(deltasValue, CollectionDelta.fromJson),
      mutations: _readOptionalInt(json, 'mutations'),
    );
  }
}

@immutable
class CollectionDelta {
  const CollectionDelta({required this.kind, required this.label});

  final String kind;
  final String label;

  Map<String, Object?> toJson() => {'kind': kind, 'label': label};

  factory CollectionDelta.fromJson(Map<String, dynamic> json) {
    return CollectionDelta(
      kind: _readString(json['kind'], fallback: 'update'),
      label: _readString(json['label']),
    );
  }
}

@immutable
class BatchSample {
  const BatchSample({
    required this.id,
    required this.depth,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    required this.writeCount,
  });

  final int id;
  final int depth;
  final int startedAt;
  final int endedAt;
  final int durationMs;
  final int writeCount;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'depth': depth,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'durationMs': durationMs,
      'writeCount': writeCount,
    };
  }

  factory BatchSample.fromJson(Map<String, dynamic> json) {
    return BatchSample(
      id: _readInt(json['id'], fallback: 0),
      depth: _readInt(json['depth'], fallback: 0),
      startedAt: _readInt(json['startedAt'], fallback: 0),
      endedAt: _readInt(json['endedAt'], fallback: 0),
      durationMs: _readInt(json['durationMs'], fallback: 0),
      writeCount: _readInt(json['writeCount'], fallback: 0),
    );
  }
}

@immutable
class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.detail,
    required this.severity,
  });

  final int id;
  final int timestamp;
  final String type;
  final String title;
  final String detail;
  final String severity;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'type': type,
      'title': title,
      'detail': detail,
      'severity': severity,
    };
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: _readInt(json['id'], fallback: 0),
      timestamp: _readInt(json['timestamp'], fallback: 0),
      type: _readString(json['type'], fallback: 'event'),
      title: _readString(json['title']),
      detail: _readString(json['detail']),
      severity: _readString(json['severity'], fallback: 'info'),
    );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

int _readInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _readBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is String) {
    final lowered = value.toLowerCase();
    if (lowered == 'true') return true;
    if (lowered == 'false') return false;
  }
  return fallback;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<T> _readList<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(parser)
        .toList();
  }
  return <T>[];
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) return null;
  final value = json[key];
  if (value == null) return null;
  return _readString(value);
}

int? _readOptionalInt(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) return null;
  final value = json[key];
  if (value == null) return null;
  return _readInt(value, fallback: 0);
}

bool? _parseBool(String? value) {
  if (value == null) return null;
  if (value.toLowerCase() == 'true') return true;
  if (value.toLowerCase() == 'false') return false;
  return null;
}

int? _parseInt(String? value) {
  if (value == null) return null;
  return int.tryParse(value);
}
