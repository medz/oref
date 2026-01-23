import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:alien_signals/preset.dart' as alien_preset;
import 'package:alien_signals/system.dart' as alien_system;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'protocol.dart';

void registerOrefDevToolsServiceExtensions() {
  OrefDevTools._instance._ensureInitialized();
}

void configureOrefDevTools({
  bool? enabled,
  int? sampleIntervalMs,
  int? timelineLimit,
  int? batchLimit,
  int? performanceLimit,
  int? valuePreviewLength,
}) {
  OrefDevTools._instance._configure(
    enabled: enabled,
    sampleIntervalMs: sampleIntervalMs,
    timelineLimit: timelineLimit,
    batchLimit: batchLimit,
    performanceLimit: performanceLimit,
    valuePreviewLength: valuePreviewLength,
  );
}

OrefDevToolsSettings get orefDevToolsSettings =>
    OrefDevTools._instance._settings;

class OrefDevTools {
  OrefDevTools._();

  static final OrefDevTools _instance = OrefDevTools._();

  static bool registerSignal(
    alien_system.ReactiveNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    return _instance._registerSignal(
      node,
      context: context,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugNote: debugNote,
    );
  }

  static void markSignalDisposed(alien_system.ReactiveNode node) {
    _instance._markSignalDisposed(node);
  }

  static void recordSignalWrite(alien_system.ReactiveNode node, Object? value) {
    _instance._recordSignalWrite(node, value);
  }

  static bool registerComputed(
    alien_system.ReactiveNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    return _instance._registerComputed(
      node,
      context: context,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugNote: debugNote,
    );
  }

  static void markComputedDisposed(alien_system.ReactiveNode node) {
    _instance._markComputedDisposed(node);
  }

  static void recordComputedRun(
    alien_system.ReactiveNode node,
    Object? value,
    int durationMs,
  ) {
    _instance._recordComputedRun(node, value, durationMs);
  }

  static bool registerEffect(
    alien_system.ReactiveNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugType,
    String? debugNote,
  }) {
    return _instance._registerEffect(
      node,
      context: context,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugType: debugType,
      debugNote: debugNote,
    );
  }

  static void recordEffectRun(alien_system.ReactiveNode node, int durationMs) {
    _instance._recordEffectRun(node, durationMs);
  }

  static void markEffectDisposed(alien_system.ReactiveNode node) {
    _instance._markEffectDisposed(node);
  }

  static bool registerCollection(
    Object collection, {
    BuildContext? context,
    required String type,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    return _instance._registerCollection(
      collection,
      context: context,
      type: type,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugNote: debugNote,
    );
  }

  static void markCollectionDisposed(Object collection) {
    _instance._markCollectionDisposed(collection);
  }

  static void recordCollectionMutation(
    Object collection, {
    required String operation,
    required List<OrefCollectionDelta> deltas,
    String? note,
  }) {
    _instance._recordCollectionMutation(
      collection,
      operation: operation,
      deltas: deltas,
      note: note,
    );
  }

  static void recordBatchStart() {
    _instance._recordBatchStart();
  }

  static void recordBatchEnd() {
    _instance._recordBatchEnd();
  }

  static OrefSnapshot snapshot() => _instance._snapshot();

  static void clearHistory() => _instance._clearHistory();

  final Expando<int> _signalIds = Expando<int>('oref_signal');
  final Expando<int> _computedIds = Expando<int>('oref_computed');
  final Expando<int> _effectIds = Expando<int>('oref_effect');
  final Expando<int> _collectionIds = Expando<int>('oref_collection');

  final Map<int, _SignalRecord> _signals = {};
  final Map<int, _ComputedRecord> _computed = {};
  final Map<int, _EffectRecord> _effects = {};
  final Map<int, _CollectionRecord> _collections = {};

  final List<OrefTimelineEvent> _timeline = [];
  final List<OrefBatch> _batches = [];
  final List<OrefPerformanceSample> _performance = [];

  final List<_BatchSession> _batchStack = [];

  int _nextSignalId = 1;
  int _nextComputedId = 1;
  int _nextEffectId = 1;
  int _nextCollectionId = 1;
  int _nextTimelineId = 1;
  int _nextBatchId = 1;

  bool _initialized = false;
  bool _extensionsRegistered = false;
  OrefDevToolsSettings _settings = const OrefDevToolsSettings();
  Timer? _samplingTimer;

  int _signalWrites = 0;
  int _computedRuns = 0;
  int _effectRuns = 0;
  int _collectionMutations = 0;
  int _batchWrites = 0;
  int _effectDurationTotalMs = 0;
  int _effectDurationCount = 0;

  bool _shouldTrack() {
    if (!_initialized) {
      _ensureInitialized();
    }
    return _initialized && _settings.enabled;
  }

  void _ensureInitialized() {
    if (_initialized) return;
    if (kReleaseMode) return;
    _initialized = true;
    _registerExtensions();
    _startSampling();
  }

  void _configure({
    bool? enabled,
    int? sampleIntervalMs,
    int? timelineLimit,
    int? batchLimit,
    int? performanceLimit,
    int? valuePreviewLength,
  }) {
    final updated = _settings.copyWith(
      enabled: enabled,
      sampleIntervalMs: sampleIntervalMs,
      timelineLimit: timelineLimit,
      batchLimit: batchLimit,
      performanceLimit: performanceLimit,
      valuePreviewLength: valuePreviewLength,
    );
    _settings = updated;
    if (_settings.enabled) {
      _startSampling();
    } else {
      _samplingTimer?.cancel();
      _samplingTimer = null;
    }
  }

  bool _registerSignal(
    alien_system.ReactiveNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    if (!_shouldTrack()) return false;
    final existing = _signalIds[node];
    if (existing != null) return false;

    final id = _nextSignalId++;
    _signalIds[node] = id;
    final record = _SignalRecord(
      id: id,
      node: WeakReference<alien_system.ReactiveNode>(node),
      label: debugLabel ?? 'signal#$id',
      owner: _describeOwner(debugOwner, context),
      scope: _describeScope(debugScope, context),
      type: _describeNodeType(node, fallback: 'Signal'),
      createdAt: _nowMs(),
      note: debugNote ?? '',
    );
    record.updatedAt = record.createdAt;
    if (node case alien_preset.SignalNode(:final currentValue)) {
      record.value = _previewValue(currentValue);
    }
    _signals[id] = record;
    return true;
  }

  void _markSignalDisposed(alien_system.ReactiveNode node) {
    final id = _signalIds[node];
    if (id == null) return;
    _signals[id]?.disposed = true;
  }

  void _recordSignalWrite(alien_system.ReactiveNode node, Object? value) {
    if (!_shouldTrack()) return;
    final record = _signals[_signalIds[node] ?? _registerSignalFallback(node)];
    if (record == null) return;
    record.value = _previewValue(value);
    record.updatedAt = _nowMs();
    record.writes++;
    _signalWrites++;

    _timeline.add(
      OrefTimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.updatedAt,
        type: 'signal',
        title: record.label,
        detail: 'Updated value',
        severity: 'info',
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);

    if (alien_preset.getBatchDepth() > 0) {
      _batchWrites++;
      if (_batchStack.isNotEmpty) {
        _batchStack.last.writeCount++;
      }
    }
  }

  bool _registerComputed(
    alien_system.ReactiveNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    if (!_shouldTrack()) return false;
    final existing = _computedIds[node];
    if (existing != null) return false;

    final id = _nextComputedId++;
    _computedIds[node] = id;
    final record = _ComputedRecord(
      id: id,
      node: WeakReference<alien_system.ReactiveNode>(node),
      label: debugLabel ?? 'computed#$id',
      owner: _describeOwner(debugOwner, context),
      scope: _describeScope(debugScope, context),
      type: _describeNodeType(node, fallback: 'Computed'),
      createdAt: _nowMs(),
      note: debugNote ?? '',
    );
    record.updatedAt = record.createdAt;
    if (node case alien_preset.ComputedNode(:final currentValue)) {
      if (currentValue != null) {
        record.value = _previewValue(currentValue);
      }
    }
    _computed[id] = record;
    return true;
  }

  void _markComputedDisposed(alien_system.ReactiveNode node) {
    final id = _computedIds[node];
    if (id == null) return;
    _computed[id]?.disposed = true;
  }

  void _recordComputedRun(
    alien_system.ReactiveNode node,
    Object? value,
    int durationMs,
  ) {
    if (!_shouldTrack()) return;
    final record =
        _computed[_computedIds[node] ?? _registerComputedFallback(node)];
    if (record == null) return;
    record.value = _previewValue(value);
    record.updatedAt = _nowMs();
    record.runs++;
    record.lastDurationMs = durationMs;
    _computedRuns++;

    _timeline.add(
      OrefTimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.updatedAt,
        type: 'computed',
        title: record.label,
        detail: 'Recomputed in ${durationMs}ms',
        severity: durationMs > 16 ? 'warn' : 'info',
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);
  }

  bool _registerEffect(
    alien_system.ReactiveNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugType,
    String? debugNote,
  }) {
    if (!_shouldTrack()) return false;
    final existing = _effectIds[node];
    if (existing != null) return false;

    final id = _nextEffectId++;
    _effectIds[node] = id;
    final record = _EffectRecord(
      id: id,
      node: WeakReference<alien_system.ReactiveNode>(node),
      label: debugLabel ?? 'effect#$id',
      owner: _describeOwner(debugOwner, context),
      scope: _describeScope(debugScope, context),
      type: debugType ?? 'Effect',
      createdAt: _nowMs(),
      note: debugNote ?? '',
    );
    record.updatedAt = record.createdAt;
    _effects[id] = record;
    return true;
  }

  void _recordEffectRun(alien_system.ReactiveNode node, int durationMs) {
    if (!_shouldTrack()) return;
    final record = _effects[_effectIds[node] ?? _registerEffectFallback(node)];
    if (record == null) return;
    record.updatedAt = _nowMs();
    record.runs++;
    record.lastDurationMs = durationMs;
    record.isHot = durationMs > 16 || record.runs >= 8;
    _effectRuns++;
    _effectDurationTotalMs += durationMs;
    _effectDurationCount++;

    _timeline.add(
      OrefTimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.updatedAt,
        type: 'effect',
        title: record.label,
        detail: 'Ran in ${durationMs}ms',
        severity: durationMs > 16 ? 'warn' : 'info',
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);
  }

  void _markEffectDisposed(alien_system.ReactiveNode node) {
    final id = _effectIds[node];
    if (id == null) return;
    _effects[id]?.disposed = true;
  }

  bool _registerCollection(
    Object collection, {
    BuildContext? context,
    required String type,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    if (!_shouldTrack()) return false;
    final existing = _collectionIds[collection];
    if (existing != null) {
      final record = _collections[existing];
      if (record != null) {
        if (record.type != type) record.type = type;
        if (debugLabel != null) record.label = debugLabel;
        if (debugOwner != null || context != null) {
          record.owner = _describeOwner(debugOwner, context);
        }
        if (debugScope != null || context != null) {
          record.scope = _describeScope(debugScope, context);
        }
        if (debugNote != null) record.note = debugNote;
      }
      return false;
    }

    final id = _nextCollectionId++;
    _collectionIds[collection] = id;
    final record = _CollectionRecord(
      id: id,
      collection: WeakReference<Object>(collection),
      label: debugLabel ?? 'collection#$id',
      owner: _describeOwner(debugOwner, context),
      scope: _describeScope(debugScope, context),
      type: type,
      createdAt: _nowMs(),
      note: debugNote ?? '',
    );
    record.updatedAt = record.createdAt;
    _collections[id] = record;
    return true;
  }

  void _markCollectionDisposed(Object collection) {
    final id = _collectionIds[collection];
    if (id == null) return;
    _collections[id]?.disposed = true;
  }

  void _recordCollectionMutation(
    Object collection, {
    required String operation,
    required List<OrefCollectionDelta> deltas,
    String? note,
  }) {
    if (!_shouldTrack()) return;
    final record =
        _collections[_collectionIds[collection] ??
            _registerCollectionFallback(collection)];
    if (record == null) return;
    record.operation = operation;
    record.updatedAt = _nowMs();
    record.deltas = deltas;
    record.mutations++;
    if (note != null) record.note = note;
    _collectionMutations++;

    _timeline.add(
      OrefTimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.updatedAt,
        type: 'collection',
        title: record.label,
        detail: '$operation mutation',
        severity: 'info',
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);
  }

  void _recordBatchStart() {
    if (!_shouldTrack()) return;
    final session = _BatchSession(
      id: _nextBatchId++,
      depth: _batchStack.length + 1,
      startedAt: _nowMs(),
    );
    _batchStack.add(session);
  }

  void _recordBatchEnd() {
    if (!_shouldTrack()) return;
    if (_batchStack.isEmpty) return;
    final session = _batchStack.removeLast();
    session.endedAt = _nowMs();
    final endedAt = session.endedAt ?? session.startedAt;
    final record = OrefBatch(
      id: session.id,
      depth: session.depth,
      startedAt: session.startedAt,
      endedAt: endedAt,
      durationMs: endedAt - session.startedAt,
      writeCount: session.writeCount,
    );
    _batches.add(record);
    _trimList(_batches, _settings.batchLimit);

    _timeline.add(
      OrefTimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.endedAt,
        type: 'batch',
        title: 'Batch #${record.id}',
        detail: '${record.writeCount} writes in ${record.durationMs}ms',
        severity: record.durationMs > 16 ? 'warn' : 'info',
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);
  }

  OrefSnapshot _snapshot() {
    if (!_initialized) {
      return OrefSnapshot(
        protocolVersion: OrefDevToolsProtocol.version,
        timestamp: _nowMs(),
        settings: _settings,
        stats: const OrefStats(),
        signals: const [],
        computed: const [],
        effects: const [],
        collections: const [],
        batches: const [],
        timeline: const [],
        performance: const [],
      );
    }

    _purgeCollected();
    return OrefSnapshot(
      protocolVersion: OrefDevToolsProtocol.version,
      timestamp: _nowMs(),
      settings: _settings,
      stats: _buildStats(),
      signals: _signals.values.map(_signalToProtocol).toList(),
      computed: _computed.values.map(_computedToProtocol).toList(),
      effects: _effects.values.map(_effectToProtocol).toList(),
      collections: _collections.values.map(_collectionToProtocol).toList(),
      batches: List<OrefBatch>.from(_batches),
      timeline: List<OrefTimelineEvent>.from(_timeline),
      performance: List<OrefPerformanceSample>.from(_performance),
    );
  }

  void _clearHistory() {
    _timeline.clear();
    _batches.clear();
    _performance.clear();
    _signalWrites = 0;
    _computedRuns = 0;
    _effectRuns = 0;
    _collectionMutations = 0;
    _batchWrites = 0;
    _effectDurationTotalMs = 0;
    _effectDurationCount = 0;
  }

  void _registerExtensions() {
    if (_extensionsRegistered) return;
    _extensionsRegistered = true;

    try {
      developer.registerExtension(OrefDevToolsProtocol.snapshotService, (
        method,
        params,
      ) async {
        final payload = jsonEncode(_snapshot().toJson());
        return developer.ServiceExtensionResponse.result(payload);
      });
      developer.registerExtension(OrefDevToolsProtocol.settingsService, (
        method,
        params,
      ) async {
        final payload = jsonEncode(_settings.toJson());
        return developer.ServiceExtensionResponse.result(payload);
      });
      developer.registerExtension(OrefDevToolsProtocol.updateSettingsService, (
        method,
        params,
      ) async {
        final merged = OrefDevToolsSettings.mergeArgs(_settings, params);
        _configure(
          enabled: merged.enabled,
          sampleIntervalMs: merged.sampleIntervalMs,
          timelineLimit: merged.timelineLimit,
          batchLimit: merged.batchLimit,
          performanceLimit: merged.performanceLimit,
          valuePreviewLength: merged.valuePreviewLength,
        );
        final payload = jsonEncode(_settings.toJson());
        return developer.ServiceExtensionResponse.result(payload);
      });
      developer.registerExtension(OrefDevToolsProtocol.clearService, (
        method,
        params,
      ) async {
        _clearHistory();
        final payload = jsonEncode({'cleared': true});
        return developer.ServiceExtensionResponse.result(payload);
      });
    } catch (_) {
      // Ignore duplicate extension registration.
    }
  }

  void _startSampling() {
    _samplingTimer?.cancel();
    if (!_settings.enabled) return;
    _samplingTimer = Timer.periodic(
      Duration(milliseconds: _settings.sampleIntervalMs),
      (_) => _recordPerformanceSample(),
    );
  }

  void _recordPerformanceSample() {
    if (!_shouldTrack()) return;
    final now = _nowMs();
    final avgEffect = _effectDurationCount == 0
        ? 0.0
        : _effectDurationTotalMs / _effectDurationCount;
    final sample = OrefPerformanceSample(
      timestamp: now,
      signalCount: _signals.length,
      computedCount: _computed.length,
      effectCount: _effects.length,
      collectionCount: _collections.length,
      signalWrites: _signalWrites,
      computedRuns: _computedRuns,
      effectRuns: _effectRuns,
      collectionMutations: _collectionMutations,
      batchWrites: _batchWrites,
      avgEffectDurationMs: avgEffect,
    );
    _performance.add(sample);
    _trimList(_performance, _settings.performanceLimit);

    _signalWrites = 0;
    _computedRuns = 0;
    _effectRuns = 0;
    _collectionMutations = 0;
    _batchWrites = 0;
    _effectDurationTotalMs = 0;
    _effectDurationCount = 0;
  }

  OrefStats _buildStats() {
    return OrefStats(
      signals: _signals.length,
      computed: _computed.length,
      effects: _effects.length,
      collections: _collections.length,
      batches: _batches.length,
      timelineEvents: _timeline.length,
      signalWrites: _signalWrites,
      effectRuns: _effectRuns,
      computedRuns: _computedRuns,
      collectionMutations: _collectionMutations,
    );
  }

  OrefSignal _signalToProtocol(_SignalRecord record) {
    final node = record.node.target;
    if (node == null) {
      record.disposed = true;
    }
    return OrefSignal(
      id: record.id,
      label: record.label,
      owner: record.owner,
      scope: record.scope,
      type: record.type,
      value: record.value,
      status: _statusForNode(node, record.disposed),
      updatedAt: record.updatedAt,
      writes: record.writes,
      listeners: node == null ? 0 : _countSubs(node),
      dependencies: node == null ? 0 : _countDeps(node),
      note: record.note,
    );
  }

  OrefComputed _computedToProtocol(_ComputedRecord record) {
    final node = record.node.target;
    if (node == null) {
      record.disposed = true;
    }
    return OrefComputed(
      id: record.id,
      label: record.label,
      owner: record.owner,
      scope: record.scope,
      type: record.type,
      value: record.value,
      status: _statusForNode(node, record.disposed),
      updatedAt: record.updatedAt,
      runs: record.runs,
      lastDurationMs: record.lastDurationMs,
      listeners: node == null ? 0 : _countSubs(node),
      dependencies: node == null ? 0 : _countDeps(node),
      note: record.note,
    );
  }

  OrefEffect _effectToProtocol(_EffectRecord record) {
    final node = record.node.target;
    if (node == null) {
      record.disposed = true;
    }
    return OrefEffect(
      id: record.id,
      label: record.label,
      owner: record.owner,
      scope: record.scope,
      type: record.type,
      updatedAt: record.updatedAt,
      runs: record.runs,
      lastDurationMs: record.lastDurationMs,
      isHot: record.isHot,
      status: record.disposed ? 'Disposed' : 'Active',
      note: record.note,
    );
  }

  OrefCollection _collectionToProtocol(_CollectionRecord record) {
    final collection = record.collection.target;
    if (collection == null) {
      record.disposed = true;
    }
    return OrefCollection(
      id: record.id,
      label: record.label,
      owner: record.owner,
      scope: record.scope,
      type: record.type,
      operation: record.operation,
      updatedAt: record.updatedAt,
      deltas: record.deltas,
      note: record.note,
      mutations: record.mutations,
      status: record.disposed ? 'Disposed' : 'Active',
    );
  }

  int _registerSignalFallback(alien_system.ReactiveNode node) {
    _registerSignal(node);
    return _signalIds[node] ?? -1;
  }

  int _registerComputedFallback(alien_system.ReactiveNode node) {
    _registerComputed(node);
    return _computedIds[node] ?? -1;
  }

  int _registerEffectFallback(alien_system.ReactiveNode node) {
    _registerEffect(node);
    return _effectIds[node] ?? -1;
  }

  int _registerCollectionFallback(Object collection) {
    _registerCollection(collection, type: 'Collection');
    return _collectionIds[collection] ?? -1;
  }

  void _purgeCollected() {
    _signals.removeWhere((_, record) => record.node.target == null);
    _computed.removeWhere((_, record) => record.node.target == null);
    _effects.removeWhere((_, record) => record.node.target == null);
    _collections.removeWhere((_, record) => record.collection.target == null);
  }
}

class _SignalRecord {
  _SignalRecord({
    required this.id,
    required this.node,
    required this.label,
    required this.owner,
    required this.scope,
    required this.type,
    required this.createdAt,
    required this.note,
  });

  final int id;
  final WeakReference<alien_system.ReactiveNode> node;
  final int createdAt;
  String label;
  String owner;
  String scope;
  String type;
  String value = '';
  String note;
  int updatedAt = 0;
  int writes = 0;
  bool disposed = false;
}

class _ComputedRecord {
  _ComputedRecord({
    required this.id,
    required this.node,
    required this.label,
    required this.owner,
    required this.scope,
    required this.type,
    required this.createdAt,
    required this.note,
  });

  final int id;
  final WeakReference<alien_system.ReactiveNode> node;
  final int createdAt;
  String label;
  String owner;
  String scope;
  String type;
  String value = '';
  String note;
  int updatedAt = 0;
  int runs = 0;
  int lastDurationMs = 0;
  bool disposed = false;
}

class _EffectRecord {
  _EffectRecord({
    required this.id,
    required this.node,
    required this.label,
    required this.owner,
    required this.scope,
    required this.type,
    required this.createdAt,
    required this.note,
  });

  final int id;
  final WeakReference<alien_system.ReactiveNode> node;
  final int createdAt;
  String label;
  String owner;
  String scope;
  String type;
  String note;
  int updatedAt = 0;
  int runs = 0;
  int lastDurationMs = 0;
  bool isHot = false;
  bool disposed = false;
}

class _CollectionRecord {
  _CollectionRecord({
    required this.id,
    required this.collection,
    required this.label,
    required this.owner,
    required this.scope,
    required this.type,
    required this.createdAt,
    required this.note,
  });

  final int id;
  final WeakReference<Object> collection;
  final int createdAt;
  String label;
  String owner;
  String scope;
  String type;
  String operation = 'Idle';
  List<OrefCollectionDelta> deltas = const [];
  String note;
  int updatedAt = 0;
  int mutations = 0;
  bool disposed = false;
}

class _BatchSession {
  _BatchSession({
    required this.id,
    required this.depth,
    required this.startedAt,
  });

  final int id;
  final int depth;
  final int startedAt;
  int? endedAt;
  int writeCount = 0;
}

String _describeOwner(Object? owner, BuildContext? context) {
  if (owner != null) return owner.toString();
  if (context is Element) return context.widget.runtimeType.toString();
  return 'Global';
}

String _describeScope(String? scope, BuildContext? context) {
  if (scope != null) return scope;
  if (context is Element) {
    return context.widget.key?.toString() ??
        context.widget.runtimeType.toString();
  }
  return 'Global';
}

String _previewValue(Object? value) {
  final text = value == null ? 'null' : value.toString();
  if (text.length <= OrefDevTools._instance._settings.valuePreviewLength) {
    return text;
  }
  final limit = OrefDevTools._instance._settings.valuePreviewLength;
  return '${text.substring(0, limit)}...';
}

String _describeNodeType(
  alien_system.ReactiveNode node, {
  required String fallback,
}) {
  final raw = node.runtimeType.toString();
  final genericStart = raw.indexOf('<');
  final genericEnd = raw.lastIndexOf('>');
  if (genericStart != -1 && genericEnd > genericStart) {
    final generic = raw.substring(genericStart + 1, genericEnd).trim();
    if (generic.isNotEmpty) return generic;
  }
  if (raw.startsWith('_')) return fallback;
  return raw;
}

String _statusForNode(alien_system.ReactiveNode? node, bool disposed) {
  if (disposed || node == null) return 'Disposed';
  final flags = node.flags;
  if ((flags & alien_system.ReactiveFlags.dirty) !=
          alien_system.ReactiveFlags.none ||
      (flags & alien_system.ReactiveFlags.pending) !=
          alien_system.ReactiveFlags.none) {
    return 'Dirty';
  }
  return 'Active';
}

int _countDeps(alien_system.ReactiveNode node) {
  int count = 0;
  for (alien_system.Link? link = node.deps; link != null; link = link.nextDep) {
    count++;
  }
  return count;
}

int _countSubs(alien_system.ReactiveNode node) {
  int count = 0;
  for (alien_system.Link? link = node.subs; link != null; link = link.nextSub) {
    count++;
  }
  return count;
}

int _nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;

void _trimList<T>(List<T> list, int limit) {
  if (list.length <= limit) return;
  list.removeRange(0, list.length - limit);
}
