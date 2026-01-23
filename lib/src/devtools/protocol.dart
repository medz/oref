import 'dart:convert';

import 'package:flutter/foundation.dart';

class OrefDevToolsProtocol {
  static const int version = 1;

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
    required this.stats,
    required this.signals,
    required this.computed,
    required this.effects,
    required this.collections,
    required this.batches,
    required this.timeline,
    required this.performance,
  });

  final int protocolVersion;
  final int timestamp;
  final OrefDevToolsSettings settings;
  final OrefStats stats;
  final List<OrefSignal> signals;
  final List<OrefComputed> computed;
  final List<OrefEffect> effects;
  final List<OrefCollection> collections;
  final List<OrefBatch> batches;
  final List<OrefTimelineEvent> timeline;
  final List<OrefPerformanceSample> performance;

  Map<String, Object?> toJson() {
    return {
      'protocolVersion': protocolVersion,
      'timestamp': timestamp,
      'settings': settings.toJson(),
      'stats': stats.toJson(),
      'signals': signals.map((signal) => signal.toJson()).toList(),
      'computed': computed.map((entry) => entry.toJson()).toList(),
      'effects': effects.map((entry) => entry.toJson()).toList(),
      'collections': collections.map((entry) => entry.toJson()).toList(),
      'batches': batches.map((entry) => entry.toJson()).toList(),
      'timeline': timeline.map((event) => event.toJson()).toList(),
      'performance': performance.map((sample) => sample.toJson()).toList(),
    };
  }

  factory Snapshot.fromJson(Map<String, dynamic> json) {
    return Snapshot(
      protocolVersion: _readInt(json['protocolVersion'], fallback: 0),
      timestamp: _readInt(json['timestamp'], fallback: 0),
      settings: OrefDevToolsSettings.fromJson(_readMap(json['settings'])),
      stats: OrefStats.fromJson(_readMap(json['stats'])),
      signals: _readList(json['signals'], OrefSignal.fromJson),
      computed: _readList(json['computed'], OrefComputed.fromJson),
      effects: _readList(json['effects'], OrefEffect.fromJson),
      collections: _readList(json['collections'], OrefCollection.fromJson),
      batches: _readList(json['batches'], OrefBatch.fromJson),
      timeline: _readList(json['timeline'], OrefTimelineEvent.fromJson),
      performance: _readList(
        json['performance'],
        OrefPerformanceSample.fromJson,
      ),
    );
  }

  static Snapshot empty() => Snapshot(
    protocolVersion: OrefDevToolsProtocol.version,
    timestamp: 0,
    settings: const OrefDevToolsSettings(),
    stats: const OrefStats(),
    signals: const [],
    computed: const [],
    effects: const [],
    collections: const [],
    batches: const [],
    timeline: const [],
    performance: const [],
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
class OrefStats {
  const OrefStats({
    this.signals = 0,
    this.computed = 0,
    this.effects = 0,
    this.collections = 0,
    this.batches = 0,
    this.timelineEvents = 0,
    this.signalWrites = 0,
    this.effectRuns = 0,
    this.computedRuns = 0,
    this.collectionMutations = 0,
  });

  final int signals;
  final int computed;
  final int effects;
  final int collections;
  final int batches;
  final int timelineEvents;
  final int signalWrites;
  final int effectRuns;
  final int computedRuns;
  final int collectionMutations;

  Map<String, Object?> toJson() {
    return {
      'signals': signals,
      'computed': computed,
      'effects': effects,
      'collections': collections,
      'batches': batches,
      'timelineEvents': timelineEvents,
      'signalWrites': signalWrites,
      'effectRuns': effectRuns,
      'computedRuns': computedRuns,
      'collectionMutations': collectionMutations,
    };
  }

  factory OrefStats.fromJson(Map<String, dynamic> json) {
    return OrefStats(
      signals: _readInt(json['signals'], fallback: 0),
      computed: _readInt(json['computed'], fallback: 0),
      effects: _readInt(json['effects'], fallback: 0),
      collections: _readInt(json['collections'], fallback: 0),
      batches: _readInt(json['batches'], fallback: 0),
      timelineEvents: _readInt(json['timelineEvents'], fallback: 0),
      signalWrites: _readInt(json['signalWrites'], fallback: 0),
      effectRuns: _readInt(json['effectRuns'], fallback: 0),
      computedRuns: _readInt(json['computedRuns'], fallback: 0),
      collectionMutations: _readInt(json['collectionMutations'], fallback: 0),
    );
  }
}

@immutable
class OrefDevToolsSettings {
  const OrefDevToolsSettings({
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

  OrefDevToolsSettings copyWith({
    bool? enabled,
    int? sampleIntervalMs,
    int? timelineLimit,
    int? batchLimit,
    int? performanceLimit,
    int? valuePreviewLength,
  }) {
    return OrefDevToolsSettings(
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

  factory OrefDevToolsSettings.fromJson(Map<String, dynamic> json) {
    return OrefDevToolsSettings(
      enabled: _readBool(json['enabled'], fallback: true),
      sampleIntervalMs: _readInt(json['sampleIntervalMs'], fallback: 1000),
      timelineLimit: _readInt(json['timelineLimit'], fallback: 200),
      batchLimit: _readInt(json['batchLimit'], fallback: 120),
      performanceLimit: _readInt(json['performanceLimit'], fallback: 180),
      valuePreviewLength: _readInt(json['valuePreviewLength'], fallback: 120),
    );
  }

  static OrefDevToolsSettings mergeArgs(
    OrefDevToolsSettings current,
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
class OrefSignal {
  const OrefSignal({
    required this.id,
    required this.label,
    required this.value,
    required this.type,
    required this.status,
    required this.owner,
    required this.scope,
    required this.updatedAt,
    required this.listeners,
    required this.dependencies,
    required this.note,
    required this.writes,
  });

  final int id;
  final String label;
  final String value;
  final String type;
  final String status;
  final String owner;
  final String scope;
  final int updatedAt;
  final int listeners;
  final int dependencies;
  final String note;
  final int writes;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'type': type,
      'status': status,
      'owner': owner,
      'scope': scope,
      'updatedAt': updatedAt,
      'listeners': listeners,
      'dependencies': dependencies,
      'note': note,
      'writes': writes,
    };
  }

  factory OrefSignal.fromJson(Map<String, dynamic> json) {
    return OrefSignal(
      id: _readInt(json['id'], fallback: 0),
      label: _readString(json['label']),
      value: _readString(json['value']),
      type: _readString(json['type']),
      status: _readString(json['status'], fallback: 'Active'),
      owner: _readString(json['owner'], fallback: 'Global'),
      scope: _readString(json['scope'], fallback: 'Global'),
      updatedAt: _readInt(json['updatedAt'], fallback: 0),
      listeners: _readInt(json['listeners'], fallback: 0),
      dependencies: _readInt(json['dependencies'], fallback: 0),
      note: _readString(json['note']),
      writes: _readInt(json['writes'], fallback: 0),
    );
  }
}

@immutable
class OrefComputed {
  const OrefComputed({
    required this.id,
    required this.label,
    required this.value,
    required this.type,
    required this.status,
    required this.owner,
    required this.scope,
    required this.updatedAt,
    required this.listeners,
    required this.dependencies,
    required this.note,
    required this.runs,
    required this.lastDurationMs,
  });

  final int id;
  final String label;
  final String value;
  final String type;
  final String status;
  final String owner;
  final String scope;
  final int updatedAt;
  final int listeners;
  final int dependencies;
  final String note;
  final int runs;
  final int lastDurationMs;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'value': value,
      'type': type,
      'status': status,
      'owner': owner,
      'scope': scope,
      'updatedAt': updatedAt,
      'listeners': listeners,
      'dependencies': dependencies,
      'note': note,
      'runs': runs,
      'lastDurationMs': lastDurationMs,
    };
  }

  factory OrefComputed.fromJson(Map<String, dynamic> json) {
    return OrefComputed(
      id: _readInt(json['id'], fallback: 0),
      label: _readString(json['label']),
      value: _readString(json['value']),
      type: _readString(json['type']),
      status: _readString(json['status'], fallback: 'Active'),
      owner: _readString(json['owner'], fallback: 'Global'),
      scope: _readString(json['scope'], fallback: 'Global'),
      updatedAt: _readInt(json['updatedAt'], fallback: 0),
      listeners: _readInt(json['listeners'], fallback: 0),
      dependencies: _readInt(json['dependencies'], fallback: 0),
      note: _readString(json['note']),
      runs: _readInt(json['runs'], fallback: 0),
      lastDurationMs: _readInt(json['lastDurationMs'], fallback: 0),
    );
  }
}

@immutable
class OrefEffect {
  const OrefEffect({
    required this.id,
    required this.label,
    required this.type,
    required this.scope,
    required this.owner,
    required this.updatedAt,
    required this.runs,
    required this.lastDurationMs,
    required this.isHot,
    required this.status,
    required this.note,
  });

  final int id;
  final String label;
  final String type;
  final String scope;
  final String owner;
  final int updatedAt;
  final int runs;
  final int lastDurationMs;
  final bool isHot;
  final String status;
  final String note;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'scope': scope,
      'owner': owner,
      'updatedAt': updatedAt,
      'runs': runs,
      'lastDurationMs': lastDurationMs,
      'isHot': isHot,
      'status': status,
      'note': note,
    };
  }

  factory OrefEffect.fromJson(Map<String, dynamic> json) {
    return OrefEffect(
      id: _readInt(json['id'], fallback: 0),
      label: _readString(json['label']),
      type: _readString(json['type'], fallback: 'Effect'),
      scope: _readString(json['scope'], fallback: 'Global'),
      owner: _readString(json['owner'], fallback: 'Global'),
      updatedAt: _readInt(json['updatedAt'], fallback: 0),
      runs: _readInt(json['runs'], fallback: 0),
      lastDurationMs: _readInt(json['lastDurationMs'], fallback: 0),
      isHot: _readBool(json['isHot'], fallback: false),
      status: _readString(json['status'], fallback: 'Active'),
      note: _readString(json['note']),
    );
  }
}

@immutable
class OrefCollection {
  const OrefCollection({
    required this.id,
    required this.label,
    required this.type,
    required this.operation,
    required this.owner,
    required this.scope,
    required this.updatedAt,
    required this.deltas,
    required this.note,
    required this.mutations,
    required this.status,
  });

  final int id;
  final String label;
  final String type;
  final String operation;
  final String owner;
  final String scope;
  final int updatedAt;
  final List<OrefCollectionDelta> deltas;
  final String note;
  final int mutations;
  final String status;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'operation': operation,
      'owner': owner,
      'scope': scope,
      'updatedAt': updatedAt,
      'deltas': deltas.map((delta) => delta.toJson()).toList(),
      'note': note,
      'mutations': mutations,
      'status': status,
    };
  }

  factory OrefCollection.fromJson(Map<String, dynamic> json) {
    return OrefCollection(
      id: _readInt(json['id'], fallback: 0),
      label: _readString(json['label']),
      type: _readString(json['type'], fallback: 'Collection'),
      operation: _readString(json['operation'], fallback: 'Idle'),
      owner: _readString(json['owner'], fallback: 'Global'),
      scope: _readString(json['scope'], fallback: 'Global'),
      updatedAt: _readInt(json['updatedAt'], fallback: 0),
      deltas: _readList(json['deltas'], OrefCollectionDelta.fromJson),
      note: _readString(json['note']),
      mutations: _readInt(json['mutations'], fallback: 0),
      status: _readString(json['status'], fallback: 'Active'),
    );
  }
}

@immutable
class OrefCollectionDelta {
  const OrefCollectionDelta({required this.kind, required this.label});

  final String kind;
  final String label;

  Map<String, Object?> toJson() => {'kind': kind, 'label': label};

  factory OrefCollectionDelta.fromJson(Map<String, dynamic> json) {
    return OrefCollectionDelta(
      kind: _readString(json['kind'], fallback: 'update'),
      label: _readString(json['label']),
    );
  }
}

@immutable
class OrefBatch {
  const OrefBatch({
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

  factory OrefBatch.fromJson(Map<String, dynamic> json) {
    return OrefBatch(
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
class OrefTimelineEvent {
  const OrefTimelineEvent({
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

  factory OrefTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrefTimelineEvent(
      id: _readInt(json['id'], fallback: 0),
      timestamp: _readInt(json['timestamp'], fallback: 0),
      type: _readString(json['type'], fallback: 'event'),
      title: _readString(json['title']),
      detail: _readString(json['detail']),
      severity: _readString(json['severity'], fallback: 'info'),
    );
  }
}

@immutable
class OrefPerformanceSample {
  const OrefPerformanceSample({
    required this.timestamp,
    required this.signalCount,
    required this.computedCount,
    required this.effectCount,
    required this.collectionCount,
    required this.signalWrites,
    required this.computedRuns,
    required this.effectRuns,
    required this.collectionMutations,
    required this.batchWrites,
    required this.avgEffectDurationMs,
  });

  final int timestamp;
  final int signalCount;
  final int computedCount;
  final int effectCount;
  final int collectionCount;
  final int signalWrites;
  final int computedRuns;
  final int effectRuns;
  final int collectionMutations;
  final int batchWrites;
  final double avgEffectDurationMs;

  Map<String, Object?> toJson() {
    return {
      'timestamp': timestamp,
      'signalCount': signalCount,
      'computedCount': computedCount,
      'effectCount': effectCount,
      'collectionCount': collectionCount,
      'signalWrites': signalWrites,
      'computedRuns': computedRuns,
      'effectRuns': effectRuns,
      'collectionMutations': collectionMutations,
      'batchWrites': batchWrites,
      'avgEffectDurationMs': avgEffectDurationMs,
    };
  }

  factory OrefPerformanceSample.fromJson(Map<String, dynamic> json) {
    return OrefPerformanceSample(
      timestamp: _readInt(json['timestamp'], fallback: 0),
      signalCount: _readInt(json['signalCount'], fallback: 0),
      computedCount: _readInt(json['computedCount'], fallback: 0),
      effectCount: _readInt(json['effectCount'], fallback: 0),
      collectionCount: _readInt(json['collectionCount'], fallback: 0),
      signalWrites: _readInt(json['signalWrites'], fallback: 0),
      computedRuns: _readInt(json['computedRuns'], fallback: 0),
      effectRuns: _readInt(json['effectRuns'], fallback: 0),
      collectionMutations: _readInt(json['collectionMutations'], fallback: 0),
      batchWrites: _readInt(json['batchWrites'], fallback: 0),
      avgEffectDurationMs: _readDouble(
        json['avgEffectDurationMs'],
        fallback: 0,
      ),
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

double _readDouble(Object? value, {required double fallback}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
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
