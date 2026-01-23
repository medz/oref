import 'dart:convert';
import 'dart:developer' as developer;

import 'package:alien_signals/preset.dart' as alien_preset;
import 'package:alien_signals/system.dart' as alien_system;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'protocol.dart';

void configure({
  bool? enabled,
  int? sampleIntervalMs,
  int? timelineLimit,
  int? batchLimit,
  int? performanceLimit,
  int? valuePreviewLength,
}) {
  _DevTools._instance._configure(
    enabled: enabled,
    sampleIntervalMs: sampleIntervalMs,
    timelineLimit: timelineLimit,
    batchLimit: batchLimit,
    performanceLimit: performanceLimit,
    valuePreviewLength: valuePreviewLength,
  );
}

DevToolsSettings get settings => _DevTools._instance._settings;

abstract class DevToolsBinding {
  SignalHandle bindSignal(
    alien_preset.SignalNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  });

  ComputedHandle bindComputed(
    alien_preset.ComputedNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  });

  EffectHandle bindEffect(
    alien_preset.EffectNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugType,
    String? debugNote,
  });

  CollectionHandle bindCollection(
    Object collection, {
    BuildContext? context,
    required String type,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  });

  void batchStart();
  void batchEnd();
}

abstract class SignalHandle {
  bool get isNew;
  void write(Object? value);
  void dispose();
}

abstract class ComputedHandle {
  bool get isNew;
  Object? start();
  void finish(Object? token, Object? value);
  void run(Object? value, int durationUs);
  void dispose();
}

abstract class EffectHandle {
  bool get isNew;
  Object? start();
  void finish(Object? token);
  void run(int durationUs);
  void dispose();
}

abstract class CollectionHandle {
  bool get isNew;
  void mutate({
    required String operation,
    required List<CollectionDelta> deltas,
    String? note,
  });
  void dispose();
}

const SignalHandle _noopSignalHandle = _NoopSignalHandle();
const ComputedHandle _noopComputedHandle = _NoopComputedHandle();
const EffectHandle _noopEffectHandle = _NoopEffectHandle();
const CollectionHandle _noopCollectionHandle = _NoopCollectionHandle();

final DevToolsBinding devtools = _DevTools._instance;

class _NoopSignalHandle implements SignalHandle {
  const _NoopSignalHandle();

  @override
  bool get isNew => false;

  @override
  void write(Object? value) {}

  @override
  void dispose() {}
}

class _NoopComputedHandle implements ComputedHandle {
  const _NoopComputedHandle();

  @override
  bool get isNew => false;

  @override
  Object? start() => null;

  @override
  void finish(Object? token, Object? value) {}

  @override
  void run(Object? value, int durationUs) {}

  @override
  void dispose() {}
}

class _NoopEffectHandle implements EffectHandle {
  const _NoopEffectHandle();

  @override
  bool get isNew => false;

  @override
  Object? start() => null;

  @override
  void finish(Object? token) {}

  @override
  void run(int durationUs) {}

  @override
  void dispose() {}
}

class _NoopCollectionHandle implements CollectionHandle {
  const _NoopCollectionHandle();

  @override
  bool get isNew => false;

  @override
  void mutate({
    required String operation,
    required List<CollectionDelta> deltas,
    String? note,
  }) {}

  @override
  void dispose() {}
}

class _SignalHandle implements SignalHandle {
  _SignalHandle(this._devtools, this._node, {required this.isNew});

  final _DevTools _devtools;
  final alien_preset.SignalNode _node;

  @override
  final bool isNew;

  @override
  void write(Object? value) {
    _devtools._recordSignalWrite(_node, value);
  }

  @override
  void dispose() {
    _devtools._markSignalDisposed(_node);
  }
}

class _ComputedHandle implements ComputedHandle {
  _ComputedHandle(this._devtools, this._node, {required this.isNew});

  final _DevTools _devtools;
  final alien_preset.ComputedNode _node;

  @override
  final bool isNew;

  @override
  Object? start() => _devtools._startTiming();

  @override
  void finish(Object? token, Object? value) {
    if (token is! Stopwatch) return;
    token.stop();
    _devtools._recordComputedRun(_node, value, token.elapsedMicroseconds);
  }

  @override
  void run(Object? value, int durationUs) {
    _devtools._recordComputedRun(_node, value, durationUs);
  }

  @override
  void dispose() {
    _devtools._markComputedDisposed(_node);
  }
}

class _EffectHandle implements EffectHandle {
  _EffectHandle(this._devtools, this._node, {required this.isNew});

  final _DevTools _devtools;
  final alien_preset.EffectNode _node;

  @override
  final bool isNew;

  @override
  Object? start() => _devtools._startTiming();

  @override
  void finish(Object? token) {
    if (token is! Stopwatch) return;
    token.stop();
    _devtools._recordEffectRun(_node, token.elapsedMicroseconds);
  }

  @override
  void run(int durationUs) {
    _devtools._recordEffectRun(_node, durationUs);
  }

  @override
  void dispose() {
    _devtools._markEffectDisposed(_node);
  }
}

class _CollectionHandle implements CollectionHandle {
  _CollectionHandle(this._devtools, this._collection, {required this.isNew});

  final _DevTools _devtools;
  final Object _collection;

  @override
  final bool isNew;

  @override
  void mutate({
    required String operation,
    required List<CollectionDelta> deltas,
    String? note,
  }) {
    _devtools._recordCollectionMutation(
      _collection,
      operation: operation,
      deltas: deltas,
      note: note,
    );
  }

  @override
  void dispose() {
    _devtools._markCollectionDisposed(_collection);
  }
}

class _DevTools implements DevToolsBinding {
  _DevTools._();

  static final _DevTools _instance = _DevTools._();
  static const int _clientTtlMs = 5000;

  @override
  SignalHandle bindSignal(
    alien_preset.SignalNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    return _bindSignal(
      node,
      context: context,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugNote: debugNote,
    );
  }

  @override
  ComputedHandle bindComputed(
    alien_preset.ComputedNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    return _bindComputed(
      node,
      context: context,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugNote: debugNote,
    );
  }

  @override
  EffectHandle bindEffect(
    alien_preset.EffectNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugType,
    String? debugNote,
  }) {
    return _bindEffect(
      node,
      context: context,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugType: debugType,
      debugNote: debugNote,
    );
  }

  @override
  CollectionHandle bindCollection(
    Object collection, {
    BuildContext? context,
    required String type,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    return _bindCollection(
      collection,
      context: context,
      type: type,
      debugLabel: debugLabel,
      debugOwner: debugOwner,
      debugScope: debugScope,
      debugNote: debugNote,
    );
  }

  @override
  void batchStart() => _recordBatchStart();

  @override
  void batchEnd() => _recordBatchEnd();

  final Expando<int> _signalIds = Expando<int>('oref_signal');
  final Expando<int> _computedIds = Expando<int>('oref_computed');
  final Expando<int> _effectIds = Expando<int>('oref_effect');
  final Expando<int> _collectionIds = Expando<int>('oref_collection');

  final Map<int, _SignalRecord> _signals = {};
  final Map<int, _ComputedRecord> _computed = {};
  final Map<int, _EffectRecord> _effects = {};
  final Map<int, _CollectionRecord> _collections = {};

  final List<TimelineEvent> _timeline = [];
  final List<BatchSample> _batches = [];
  final List<_BatchSession> _batchStack = [];

  int _nextSignalId = 1;
  int _nextComputedId = 1;
  int _nextEffectId = 1;
  int _nextCollectionId = 1;
  int _nextTimelineId = 1;
  int _nextBatchId = 1;

  bool _initialized = false;
  bool _extensionsRegistered = false;
  int? _lastClientSeenMs;
  DevToolsSettings _settings = const DevToolsSettings();

  bool _canRegister() {
    if (!_initialized) {
      _ensureInitialized();
    }
    return _initialized && _settings.enabled;
  }

  bool _shouldTrackEvents() {
    if (!_canRegister()) return false;
    final lastSeen = _lastClientSeenMs;
    if (lastSeen == null) return false;
    return (_nowMs() - lastSeen) <= _clientTtlMs;
  }

  void _markClientSeen() {
    _lastClientSeenMs = _nowMs();
  }

  Object? _startTiming() {
    if (!_shouldTrackEvents()) return null;
    return Stopwatch()..start();
  }

  void _ensureInitialized() {
    if (_initialized) return;
    if (kReleaseMode) return;
    _initialized = true;
    _registerExtensions();
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
  }

  SignalHandle _bindSignal(
    alien_preset.SignalNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    if (!_canRegister()) return _noopSignalHandle;
    final existing = _signalIds[node];
    if (existing != null) {
      final record = _signals[existing];
      if (record != null) {
        if (debugLabel != null) record.label = debugLabel;
        if (debugOwner != null || context != null) {
          record.owner = _describeOwner(debugOwner, context);
        }
        if (debugScope != null || context != null) {
          record.scope = _describeScope(debugScope, context);
        }
        if (debugNote != null) record.note = debugNote;
        record.type = _describeNodeType(node, fallback: 'Signal');
      }
      return _SignalHandle(this, node, isNew: false);
    }

    final id = _nextSignalId++;
    _signalIds[node] = id;
    final record = _SignalRecord(
      id: id,
      node: WeakReference<alien_preset.SignalNode>(node),
      label: debugLabel ?? 'signal#$id',
      owner: _describeOwner(debugOwner, context),
      scope: _describeScope(debugScope, context),
      type: _describeNodeType(node, fallback: 'Signal'),
      createdAt: _nowMs(),
      note: debugNote ?? '',
    );
    record.updatedAt = record.createdAt;
    record.value = _previewValue(node.currentValue);
    _signals[id] = record;
    return _SignalHandle(this, node, isNew: true);
  }

  void _markSignalDisposed(alien_preset.SignalNode node) {
    final id = _signalIds[node];
    if (id == null) return;
    _signals[id]?.disposed = true;
  }

  void _recordSignalWrite(alien_preset.SignalNode node, Object? value) {
    if (!_canRegister()) return;
    final id = _signalIds[node] ?? _ensureSignalRecord(node);
    if (id == -1) return;
    final record = _signals[id];
    if (record == null) return;
    record.value = _previewValue(value);
    record.updatedAt = _nowMs();
    record.writes++;

    if (!_shouldTrackEvents()) return;
    _timeline.add(
      TimelineEvent(
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
      if (_batchStack.isNotEmpty) {
        _batchStack.last.writeCount++;
      }
    }
  }

  ComputedHandle _bindComputed(
    alien_preset.ComputedNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    if (!_canRegister()) return _noopComputedHandle;
    final existing = _computedIds[node];
    if (existing != null) {
      final record = _computed[existing];
      if (record != null) {
        if (debugLabel != null) record.label = debugLabel;
        if (debugOwner != null || context != null) {
          record.owner = _describeOwner(debugOwner, context);
        }
        if (debugScope != null || context != null) {
          record.scope = _describeScope(debugScope, context);
        }
        if (debugNote != null) record.note = debugNote;
        record.type = _describeNodeType(node, fallback: 'Computed');
      }
      return _ComputedHandle(this, node, isNew: false);
    }

    final id = _nextComputedId++;
    _computedIds[node] = id;
    final record = _ComputedRecord(
      id: id,
      node: WeakReference<alien_preset.ComputedNode>(node),
      label: debugLabel ?? 'computed#$id',
      owner: _describeOwner(debugOwner, context),
      scope: _describeScope(debugScope, context),
      type: _describeNodeType(node, fallback: 'Computed'),
      createdAt: _nowMs(),
      note: debugNote ?? '',
    );
    record.updatedAt = record.createdAt;
    final currentValue = node.currentValue;
    if (currentValue != null) {
      record.value = _previewValue(currentValue);
    }
    _computed[id] = record;
    return _ComputedHandle(this, node, isNew: true);
  }

  void _markComputedDisposed(alien_preset.ComputedNode node) {
    final id = _computedIds[node];
    if (id == null) return;
    _computed[id]?.disposed = true;
  }

  void _recordComputedRun(
    alien_preset.ComputedNode node,
    Object? value,
    int durationUs,
  ) {
    if (!_canRegister()) return;
    final id = _computedIds[node] ?? _ensureComputedRecord(node);
    if (id == -1) return;
    final record = _computed[id];
    if (record == null) return;
    record.value = _previewValue(value);
    record.updatedAt = _nowMs();
    record.runs++;
    record.lastDurationUs = durationUs;

    if (!_shouldTrackEvents()) return;
    _timeline.add(
      TimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.updatedAt,
        type: 'computed',
        title: record.label,
        detail: 'Recomputed',
        severity: durationUs > 16000 ? 'warn' : 'info',
        durationUs: durationUs,
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);
  }

  EffectHandle _bindEffect(
    alien_preset.EffectNode node, {
    BuildContext? context,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugType,
    String? debugNote,
  }) {
    if (!_canRegister()) return _noopEffectHandle;
    final existing = _effectIds[node];
    if (existing != null) {
      final record = _effects[existing];
      if (record != null) {
        if (debugLabel != null) record.label = debugLabel;
        if (debugOwner != null || context != null) {
          record.owner = _describeOwner(debugOwner, context);
        }
        if (debugScope != null || context != null) {
          record.scope = _describeScope(debugScope, context);
        }
        if (debugNote != null) record.note = debugNote;
        if (debugType != null) record.type = debugType;
      }
      return _EffectHandle(this, node, isNew: false);
    }

    final id = _nextEffectId++;
    _effectIds[node] = id;
    final record = _EffectRecord(
      id: id,
      node: WeakReference<alien_preset.EffectNode>(node),
      label: debugLabel ?? 'effect#$id',
      owner: _describeOwner(debugOwner, context),
      scope: _describeScope(debugScope, context),
      type: debugType ?? 'Effect',
      createdAt: _nowMs(),
      note: debugNote ?? '',
    );
    record.updatedAt = record.createdAt;
    _effects[id] = record;
    return _EffectHandle(this, node, isNew: true);
  }

  void _recordEffectRun(alien_preset.EffectNode node, int durationUs) {
    if (!_canRegister()) return;
    final id = _effectIds[node] ?? _ensureEffectRecord(node);
    if (id == -1) return;
    final record = _effects[id];
    if (record == null) return;
    record.updatedAt = _nowMs();
    record.runs++;
    record.lastDurationUs = durationUs;

    if (!_shouldTrackEvents()) return;
    _timeline.add(
      TimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.updatedAt,
        type: 'effect',
        title: record.label,
        detail: 'Ran',
        severity: durationUs > 16000 ? 'warn' : 'info',
        durationUs: durationUs,
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);
  }

  void _markEffectDisposed(alien_preset.EffectNode node) {
    final id = _effectIds[node];
    if (id == null) return;
    _effects[id]?.disposed = true;
  }

  CollectionHandle _bindCollection(
    Object collection, {
    BuildContext? context,
    required String type,
    String? debugLabel,
    Object? debugOwner,
    String? debugScope,
    String? debugNote,
  }) {
    if (!_canRegister()) return _noopCollectionHandle;
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
      return _CollectionHandle(this, collection, isNew: false);
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
    return _CollectionHandle(this, collection, isNew: true);
  }

  void _markCollectionDisposed(Object collection) {
    final id = _collectionIds[collection];
    if (id == null) return;
    _collections[id]?.disposed = true;
  }

  void _recordCollectionMutation(
    Object collection, {
    required String operation,
    required List<CollectionDelta> deltas,
    String? note,
  }) {
    if (!_canRegister()) return;
    final id =
        _collectionIds[collection] ?? _ensureCollectionRecord(collection);
    if (id == -1) return;
    final record = _collections[id];
    if (record == null) return;
    record.operation = operation;
    record.updatedAt = _nowMs();
    record.deltas = deltas;
    record.mutations++;
    if (note != null) record.note = note;

    if (!_shouldTrackEvents()) return;
    _timeline.add(
      TimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.updatedAt,
        type: 'collection',
        title: record.label,
        detail: 'Mutation',
        severity: 'info',
        operation: operation,
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);
  }

  void _recordBatchStart() {
    if (!_shouldTrackEvents()) return;
    final session = _BatchSession(
      id: _nextBatchId++,
      depth: _batchStack.length + 1,
      startedAt: _nowMs(),
    );
    _batchStack.add(session);
  }

  void _recordBatchEnd() {
    if (!_shouldTrackEvents()) return;
    if (_batchStack.isEmpty) return;
    final session = _batchStack.removeLast();
    session.endedAt = _nowMs();
    final endedAt = session.endedAt ?? session.startedAt;
    final record = BatchSample(
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
      TimelineEvent(
        id: _nextTimelineId++,
        timestamp: record.endedAt,
        type: 'batch',
        title: 'Batch #${record.id}',
        detail: 'Batch',
        severity: record.durationMs > 16 ? 'warn' : 'info',
        durationUs: record.durationMs * 1000,
        writeCount: record.writeCount,
      ),
    );
    _trimList(_timeline, _settings.timelineLimit);
  }

  Snapshot _snapshot() {
    if (!_initialized) {
      return Snapshot(
        protocolVersion: Protocol.version,
        timestamp: _nowMs(),
        settings: _settings,
        samples: const [],
        batches: const [],
        timeline: const [],
      );
    }

    _purgeCollected();
    final samples = <Sample>[
      ..._signals.values.map(_signalToSample),
      ..._computed.values.map(_computedToSample),
      ..._effects.values.map(_effectToSample),
      ..._collections.values.map(_collectionToSample),
    ];
    return Snapshot(
      protocolVersion: Protocol.version,
      timestamp: _nowMs(),
      settings: _settings,
      samples: samples,
      batches: List<BatchSample>.from(_batches),
      timeline: List<TimelineEvent>.from(_timeline),
    );
  }

  void _clearHistory() {
    _timeline.clear();
    _batches.clear();
  }

  void _registerExtensions() {
    if (_extensionsRegistered) return;
    _extensionsRegistered = true;

    try {
      developer.registerExtension(Protocol.snapshotService, (
        method,
        params,
      ) async {
        _markClientSeen();
        final payload = jsonEncode(_snapshot().toJson());
        return developer.ServiceExtensionResponse.result(payload);
      });
      developer.registerExtension(Protocol.settingsService, (
        method,
        params,
      ) async {
        _markClientSeen();
        final payload = jsonEncode(_settings.toJson());
        return developer.ServiceExtensionResponse.result(payload);
      });
      developer.registerExtension(Protocol.updateSettingsService, (
        method,
        params,
      ) async {
        _markClientSeen();
        final merged = DevToolsSettings.mergeArgs(_settings, params);
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
      developer.registerExtension(Protocol.clearService, (
        method,
        params,
      ) async {
        _markClientSeen();
        _clearHistory();
        final payload = jsonEncode({'cleared': true});
        return developer.ServiceExtensionResponse.result(payload);
      });
    } catch (_) {
      // Ignore duplicate extension registration.
    }
  }

  Sample _signalToSample(_SignalRecord record) {
    final node = record.node.target;
    if (node == null) {
      record.disposed = true;
    }
    return Sample(
      id: record.id,
      kind: 'signal',
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

  Sample _computedToSample(_ComputedRecord record) {
    final node = record.node.target;
    if (node == null) {
      record.disposed = true;
    }
    return Sample(
      id: record.id,
      kind: 'computed',
      label: record.label,
      owner: record.owner,
      scope: record.scope,
      type: record.type,
      value: record.value,
      status: _statusForNode(node, record.disposed),
      updatedAt: record.updatedAt,
      runs: record.runs,
      lastDurationUs: record.lastDurationUs,
      listeners: node == null ? 0 : _countSubs(node),
      dependencies: node == null ? 0 : _countDeps(node),
      note: record.note,
    );
  }

  Sample _effectToSample(_EffectRecord record) {
    final node = record.node.target;
    if (node == null) {
      record.disposed = true;
    }
    return Sample(
      id: record.id,
      kind: 'effect',
      label: record.label,
      owner: record.owner,
      scope: record.scope,
      type: record.type,
      updatedAt: record.updatedAt,
      runs: record.runs,
      lastDurationUs: record.lastDurationUs,
      status: record.disposed ? 'Disposed' : 'Active',
      note: record.note,
    );
  }

  Sample _collectionToSample(_CollectionRecord record) {
    final collection = record.collection.target;
    if (collection == null) {
      record.disposed = true;
    }
    return Sample(
      id: record.id,
      kind: 'collection',
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

  int _ensureSignalRecord(alien_preset.SignalNode node) {
    final existing = _signalIds[node];
    if (existing != null) return existing;
    if (!_canRegister()) return -1;
    final id = _nextSignalId++;
    _signalIds[node] = id;
    final record = _SignalRecord(
      id: id,
      node: WeakReference<alien_preset.SignalNode>(node),
      label: 'signal#$id',
      owner: 'Global',
      scope: 'Global',
      type: _describeNodeType(node, fallback: 'Signal'),
      createdAt: _nowMs(),
      note: '',
    );
    record.updatedAt = record.createdAt;
    record.value = _previewValue(node.currentValue);
    _signals[id] = record;
    return id;
  }

  int _ensureComputedRecord(alien_preset.ComputedNode node) {
    final existing = _computedIds[node];
    if (existing != null) return existing;
    if (!_canRegister()) return -1;
    final id = _nextComputedId++;
    _computedIds[node] = id;
    final record = _ComputedRecord(
      id: id,
      node: WeakReference<alien_preset.ComputedNode>(node),
      label: 'computed#$id',
      owner: 'Global',
      scope: 'Global',
      type: _describeNodeType(node, fallback: 'Computed'),
      createdAt: _nowMs(),
      note: '',
    );
    record.updatedAt = record.createdAt;
    final currentValue = node.currentValue;
    if (currentValue != null) {
      record.value = _previewValue(currentValue);
    }
    _computed[id] = record;
    return id;
  }

  int _ensureEffectRecord(alien_preset.EffectNode node) {
    final existing = _effectIds[node];
    if (existing != null) return existing;
    if (!_canRegister()) return -1;
    final id = _nextEffectId++;
    _effectIds[node] = id;
    final record = _EffectRecord(
      id: id,
      node: WeakReference<alien_preset.EffectNode>(node),
      label: 'effect#$id',
      owner: 'Global',
      scope: 'Global',
      type: 'Effect',
      createdAt: _nowMs(),
      note: '',
    );
    record.updatedAt = record.createdAt;
    _effects[id] = record;
    return id;
  }

  int _ensureCollectionRecord(Object collection) {
    final existing = _collectionIds[collection];
    if (existing != null) return existing;
    if (!_canRegister()) return -1;
    final id = _nextCollectionId++;
    _collectionIds[collection] = id;
    final record = _CollectionRecord(
      id: id,
      collection: WeakReference<Object>(collection),
      label: 'collection#$id',
      owner: 'Global',
      scope: 'Global',
      type: 'Collection',
      createdAt: _nowMs(),
      note: '',
    );
    record.updatedAt = record.createdAt;
    _collections[id] = record;
    return id;
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
  final WeakReference<alien_preset.SignalNode> node;
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
  final WeakReference<alien_preset.ComputedNode> node;
  final int createdAt;
  String label;
  String owner;
  String scope;
  String type;
  String value = '';
  String note;
  int updatedAt = 0;
  int runs = 0;
  int lastDurationUs = 0;
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
  final WeakReference<alien_preset.EffectNode> node;
  final int createdAt;
  String label;
  String owner;
  String scope;
  String type;
  String note;
  int updatedAt = 0;
  int runs = 0;
  int lastDurationUs = 0;
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
  List<CollectionDelta> deltas = const [];
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
  if (text.length <= _DevTools._instance._settings.valuePreviewLength) {
    return text;
  }
  final limit = _DevTools._instance._settings.valuePreviewLength;
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

String _formatDurationUs(int durationUs) {
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

void _trimList<T>(List<T> list, int limit) {
  if (list.length <= limit) return;
  list.removeRange(0, list.length - limit);
}
