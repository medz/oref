import 'dart:convert';

import 'package:flutter/foundation.dart';

class Protocol {
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
  final DevToolsSettings settings;
  final Stats stats;
  final List<SignalSample> signals;
  final List<ComputedSample> computed;
  final List<EffectSample> effects;
  final List<CollectionSample> collections;
  final List<BatchSample> batches;
  final List<TimelineEvent> timeline;
  final List<PerformanceSample> performance;

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
      settings: DevToolsSettings.fromJson(_readMap(json['settings'])),
      stats: Stats.fromJson(_readMap(json['stats'])),
      signals: _readList(json['signals'], SignalSample.fromJson),
      computed: _readList(json['computed'], ComputedSample.fromJson),
      effects: _readList(json['effects'], EffectSample.fromJson),
      collections: _readList(json['collections'], CollectionSample.fromJson),
      batches: _readList(json['batches'], BatchSample.fromJson),
      timeline: _readList(json['timeline'], TimelineEvent.fromJson),
      performance: _readList(json['performance'], PerformanceSample.fromJson),
    );
  }

  static Snapshot empty() => Snapshot(
    protocolVersion: Protocol.version,
    timestamp: 0,
    settings: const DevToolsSettings(),
    stats: const Stats(),
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
class Stats {
  const Stats({
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

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
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
abstract class Sample {
  const Sample({
    required this.id,
    required this.label,
    required this.type,
    required this.status,
    required this.owner,
    required this.scope,
    required this.updatedAt,
    required this.note,
  });

  final int id;
  final String label;
  final String type;
  final String status;
  final String owner;
  final String scope;
  final int updatedAt;
  final String note;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'status': status,
      'owner': owner,
      'scope': scope,
      'updatedAt': updatedAt,
      'note': note,
    };
  }
}

@immutable
class SignalSample extends Sample {
  const SignalSample({
    required this.value,
    required this.listeners,
    required this.dependencies,
    required this.writes,
    required super.id,
    required super.label,
    required super.type,
    required super.status,
    required super.owner,
    required super.scope,
    required super.updatedAt,
    required super.note,
  });

  final String value;
  final int listeners;
  final int dependencies;
  final int writes;

  @override
  Map<String, Object?> toJson() {
    return {
      'value': value,
      'listeners': listeners,
      'dependencies': dependencies,
      'writes': writes,
      ...super.toJson(),
    };
  }

  factory SignalSample.fromJson(Map<String, dynamic> json) {
    return SignalSample(
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
class ComputedSample extends Sample {
  const ComputedSample({
    required this.value,
    required this.listeners,
    required this.dependencies,
    required this.runs,
    required this.lastDurationMs,
    required super.id,
    required super.label,
    required super.type,
    required super.status,
    required super.owner,
    required super.scope,
    required super.updatedAt,
    required super.note,
  });

  final String value;
  final int listeners;
  final int dependencies;
  final int runs;
  final int lastDurationMs;

  @override
  Map<String, Object?> toJson() {
    return {
      'value': value,
      'listeners': listeners,
      'dependencies': dependencies,
      'runs': runs,
      'lastDurationMs': lastDurationMs,
      ...super.toJson(),
    };
  }

  factory ComputedSample.fromJson(Map<String, dynamic> json) {
    return ComputedSample(
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
class EffectSample extends Sample {
  const EffectSample({
    required this.runs,
    required this.lastDurationMs,
    required this.isHot,
    required super.id,
    required super.label,
    required super.type,
    required super.status,
    required super.owner,
    required super.scope,
    required super.updatedAt,
    required super.note,
  });

  final int runs;
  final int lastDurationMs;
  final bool isHot;

  @override
  Map<String, Object?> toJson() {
    return {
      'runs': runs,
      'lastDurationMs': lastDurationMs,
      'isHot': isHot,
      ...super.toJson(),
    };
  }

  factory EffectSample.fromJson(Map<String, dynamic> json) {
    return EffectSample(
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
class CollectionSample extends Sample {
  const CollectionSample({
    required this.operation,
    required this.deltas,
    required this.mutations,
    required super.id,
    required super.label,
    required super.type,
    required super.status,
    required super.owner,
    required super.scope,
    required super.updatedAt,
    required super.note,
  });

  final String operation;
  final List<CollectionDelta> deltas;
  final int mutations;

  @override
  Map<String, Object?> toJson() {
    return {
      'operation': operation,
      'deltas': deltas.map((delta) => delta.toJson()).toList(),
      'mutations': mutations,
      ...super.toJson(),
    };
  }

  factory CollectionSample.fromJson(Map<String, dynamic> json) {
    return CollectionSample(
      id: _readInt(json['id'], fallback: 0),
      label: _readString(json['label']),
      type: _readString(json['type'], fallback: 'Collection'),
      operation: _readString(json['operation'], fallback: 'Idle'),
      owner: _readString(json['owner'], fallback: 'Global'),
      scope: _readString(json['scope'], fallback: 'Global'),
      updatedAt: _readInt(json['updatedAt'], fallback: 0),
      deltas: _readList(json['deltas'], CollectionDelta.fromJson),
      note: _readString(json['note']),
      mutations: _readInt(json['mutations'], fallback: 0),
      status: _readString(json['status'], fallback: 'Active'),
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

@immutable
class PerformanceSample {
  const PerformanceSample({
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

  factory PerformanceSample.fromJson(Map<String, dynamic> json) {
    return PerformanceSample(
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
