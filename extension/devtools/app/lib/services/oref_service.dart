import 'dart:async';
import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:oref/devtools.dart' as oref;
import 'package:vm_service/vm_service.dart';

enum OrefServiceStatus { disconnected, connecting, unavailable, ready, error }

class UiPerformanceSample {
  const UiPerformanceSample({
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
    required this.avgEffectDurationUs,
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
  final double avgEffectDurationUs;

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
      'avgEffectDurationUs': avgEffectDurationUs,
    };
  }
}

class _SnapshotTotals {
  const _SnapshotTotals({
    required this.signalCount,
    required this.computedCount,
    required this.effectCount,
    required this.collectionCount,
    required this.signalWrites,
    required this.computedRuns,
    required this.effectRuns,
    required this.collectionMutations,
    required this.batchWrites,
    required this.avgEffectDurationUs,
  });

  final int signalCount;
  final int computedCount;
  final int effectCount;
  final int collectionCount;
  final int signalWrites;
  final int computedRuns;
  final int effectRuns;
  final int collectionMutations;
  final int batchWrites;
  final double avgEffectDurationUs;
}

class OrefDevToolsController extends ChangeNotifier {
  OrefDevToolsController({Duration pollInterval = const Duration(seconds: 1)})
    : _pollInterval = pollInterval {
    _connectionListener = _handleConnection;
    serviceManager.connectedState.addListener(_connectionListener);
    _handleConnection();
  }

  Duration _pollInterval;
  late final VoidCallback _connectionListener;

  oref.Snapshot? snapshot;
  List<UiPerformanceSample> performance = const [];
  OrefServiceStatus status = .disconnected;
  String? errorMessage;

  Timer? _pollTimer;
  Timer? _retryTimer;
  _SnapshotTotals? _lastTotals;

  bool get connected => serviceManager.connectedState.value.connected;
  bool get isReady => status == .ready;
  bool get isUnavailable => status == .unavailable;
  bool get isConnecting => status == .connecting;
  bool get hasError => status == .error;

  Future<void> refresh() async {
    await _fetchSnapshot();
  }

  Future<void> updateSettings(oref.DevToolsSettings settings) async {
    if (!connected) return;
    try {
      await _callExtension(
        oref.Protocol.updateSettingsService,
        args: _encodeArgs(settings.toJson()),
      );
      final nextInterval = Duration(milliseconds: settings.sampleIntervalMs);
      if (_pollInterval != nextInterval) {
        _pollInterval = nextInterval;
        _startPolling();
      }
      await _fetchSnapshot();
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> clearHistory() async {
    if (!connected) return;
    try {
      await _callExtension(oref.Protocol.clearService);
      performance = const [];
      _lastTotals = null;
      await _fetchSnapshot();
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> reloadSettings() async {
    if (!connected) return;
    try {
      final payload = await _callExtension(oref.Protocol.settingsService);
      final settings = oref.DevToolsSettings.fromJson(payload);
      if (snapshot != null) {
        snapshot = oref.Snapshot(
          protocolVersion: snapshot!.protocolVersion,
          timestamp: snapshot!.timestamp,
          settings: settings,
          samples: snapshot!.samples,
          batches: snapshot!.batches,
          timeline: snapshot!.timeline,
        );
        notifyListeners();
      }
    } catch (error) {
      _setError(error);
    }
  }

  @override
  void dispose() {
    serviceManager.connectedState.removeListener(_connectionListener);
    _pollTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _resetPerformance() {
    performance = const [];
    _lastTotals = null;
  }

  void _updatePerformance(oref.Snapshot snapshot) {
    final totals = _collectTotals(snapshot);
    final previous = _lastTotals;
    int delta(int current, int? before) {
      if (before == null) return current;
      if (current < before) return 0;
      return current - before;
    }

    final sample = UiPerformanceSample(
      timestamp: snapshot.timestamp,
      signalCount: totals.signalCount,
      computedCount: totals.computedCount,
      effectCount: totals.effectCount,
      collectionCount: totals.collectionCount,
      signalWrites: delta(totals.signalWrites, previous?.signalWrites),
      computedRuns: delta(totals.computedRuns, previous?.computedRuns),
      effectRuns: delta(totals.effectRuns, previous?.effectRuns),
      collectionMutations: delta(
        totals.collectionMutations,
        previous?.collectionMutations,
      ),
      batchWrites: delta(totals.batchWrites, previous?.batchWrites),
      avgEffectDurationUs: totals.avgEffectDurationUs,
    );

    final next = [sample, ...performance];
    final limit = snapshot.settings.performanceLimit;
    if (limit > 0 && next.length > limit) {
      next.removeRange(limit, next.length);
    }
    performance = next;
    _lastTotals = totals;
  }

  _SnapshotTotals _collectTotals(oref.Snapshot snapshot) {
    int signalCount = 0;
    int computedCount = 0;
    int effectCount = 0;
    int collectionCount = 0;
    int signalWrites = 0;
    int computedRuns = 0;
    int effectRuns = 0;
    int collectionMutations = 0;
    int batchWrites = 0;
    int effectDurationSum = 0;
    int effectDurationCount = 0;

    for (final sample in snapshot.samples) {
      switch (sample.kind) {
        case 'signal':
          signalCount++;
          signalWrites += sample.writes ?? 0;
          break;
        case 'computed':
          computedCount++;
          computedRuns += sample.runs ?? 0;
          break;
        case 'effect':
          effectCount++;
          effectRuns += sample.runs ?? 0;
          final duration = sample.lastDurationUs;
          if (duration != null && duration > 0) {
            effectDurationSum += duration;
            effectDurationCount++;
          }
          break;
        case 'collection':
          collectionCount++;
          collectionMutations += sample.mutations ?? 0;
          break;
        default:
          break;
      }
    }

    for (final batch in snapshot.batches) {
      batchWrites += batch.writeCount;
    }

    final avgEffectDurationUs = effectDurationCount == 0
        ? 0.0
        : effectDurationSum / effectDurationCount;

    return _SnapshotTotals(
      signalCount: signalCount,
      computedCount: computedCount,
      effectCount: effectCount,
      collectionCount: collectionCount,
      signalWrites: signalWrites,
      computedRuns: computedRuns,
      effectRuns: effectRuns,
      collectionMutations: collectionMutations,
      batchWrites: batchWrites,
      avgEffectDurationUs: avgEffectDurationUs,
    );
  }

  void _handleConnection() {
    if (!connected) {
      status = .disconnected;
      _pollTimer?.cancel();
      _retryTimer?.cancel();
      _resetPerformance();
      notifyListeners();
      return;
    }

    status = .connecting;
    errorMessage = null;
    _startPolling();
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchSnapshot());
    unawaited(_fetchSnapshot());
  }

  Future<void> _fetchSnapshot() async {
    if (!connected) return;
    try {
      final payload = await _callExtension(oref.Protocol.snapshotService);
      snapshot = oref.Snapshot.fromJson(payload);
      _updatePerformance(snapshot!);
      status = .ready;
      errorMessage = null;
      notifyListeners();
    } catch (error) {
      if (_isMissingExtension(error)) {
        status = .unavailable;
        errorMessage = null;
        _resetPerformance();
        _scheduleRetry();
        notifyListeners();
        return;
      }
      _setError(error);
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 3), _fetchSnapshot);
  }

  void _setError(Object error) {
    status = .error;
    errorMessage = error.toString();
    notifyListeners();
  }

  Future<Map<String, dynamic>> _callExtension(
    String method, {
    Map<String, String>? args,
  }) async {
    final response = await serviceManager.callServiceExtensionOnMainIsolate(
      method,
      args: args,
    );
    final json = response.json ?? <String, dynamic>{};
    final result = json['result'];
    if (result is String) {
      final decoded = jsonDecode(result);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    if (result is Map<String, dynamic>) return result;
    if (result is Map) return Map<String, dynamic>.from(result);
    return json;
  }
}

bool _isMissingExtension(Object error) {
  if (error is RPCError) {
    final message = error.message.toLowerCase();
    return message.contains('method not found') ||
        message.contains('service extension') ||
        message.contains('extension');
  }
  final text = error.toString().toLowerCase();
  return text.contains('method not found') ||
      text.contains('service extension') ||
      text.contains('extension');
}

Map<String, String> _encodeArgs(Map<String, Object?> args) {
  return args.map((key, value) => MapEntry(key, value.toString()));
}
