import 'dart:async';
import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:oref/devtools.dart';
import 'package:vm_service/vm_service.dart';

enum OrefServiceStatus { disconnected, connecting, unavailable, ready, error }

class OrefDevToolsController extends ChangeNotifier {
  OrefDevToolsController({Duration pollInterval = const Duration(seconds: 1)})
    : _pollInterval = pollInterval {
    _connectionListener = _handleConnection;
    serviceManager.connectedState.addListener(_connectionListener);
    _handleConnection();
  }

  final Duration _pollInterval;
  late final VoidCallback _connectionListener;

  Snapshot? snapshot;
  OrefServiceStatus status = OrefServiceStatus.disconnected;
  String? errorMessage;

  Timer? _pollTimer;
  Timer? _retryTimer;

  bool get connected => serviceManager.connectedState.value.connected;
  bool get isReady => status == OrefServiceStatus.ready;
  bool get isUnavailable => status == OrefServiceStatus.unavailable;
  bool get isConnecting => status == OrefServiceStatus.connecting;
  bool get hasError => status == OrefServiceStatus.error;

  Future<void> refresh() async {
    await _fetchSnapshot();
  }

  Future<void> updateSettings(OrefDevToolsSettings settings) async {
    if (!connected) return;
    try {
      await _callExtension(
        OrefDevToolsProtocol.updateSettingsService,
        args: _encodeArgs(settings.toJson()),
      );
      await _fetchSnapshot();
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> clearHistory() async {
    if (!connected) return;
    try {
      await _callExtension(OrefDevToolsProtocol.clearService);
      await _fetchSnapshot();
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> reloadSettings() async {
    if (!connected) return;
    try {
      final payload = await _callExtension(
        OrefDevToolsProtocol.settingsService,
      );
      final settings = OrefDevToolsSettings.fromJson(payload);
      if (snapshot != null) {
        snapshot = Snapshot(
          protocolVersion: snapshot!.protocolVersion,
          timestamp: snapshot!.timestamp,
          settings: settings,
          stats: snapshot!.stats,
          signals: snapshot!.signals,
          computed: snapshot!.computed,
          effects: snapshot!.effects,
          collections: snapshot!.collections,
          batches: snapshot!.batches,
          timeline: snapshot!.timeline,
          performance: snapshot!.performance,
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

  void _handleConnection() {
    if (!connected) {
      status = OrefServiceStatus.disconnected;
      _pollTimer?.cancel();
      _retryTimer?.cancel();
      notifyListeners();
      return;
    }

    status = OrefServiceStatus.connecting;
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
      final payload = await _callExtension(
        OrefDevToolsProtocol.snapshotService,
      );
      snapshot = Snapshot.fromJson(payload);
      status = OrefServiceStatus.ready;
      errorMessage = null;
      notifyListeners();
    } catch (error) {
      if (_isMissingExtension(error)) {
        status = OrefServiceStatus.unavailable;
        errorMessage = null;
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
    status = OrefServiceStatus.error;
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
