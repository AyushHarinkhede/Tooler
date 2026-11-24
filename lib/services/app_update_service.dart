import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppUpdateStatus {
  idle,
  checking,
  downloading,
  replacing,
  ready,
  installing,
  needsPermission,
  error,
}

class AppUpdateService extends ChangeNotifier {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static const MethodChannel _methodChannel =
      MethodChannel('com.tooler.tooler/app_updater');
  static const EventChannel _eventChannel =
      EventChannel('com.tooler.tooler/app_updater_events');

  static const String githubRepoUrl =
      'https://github.com/AyushHarinkhede/Tooler';

  StreamSubscription<dynamic>? _eventSub;

  AppUpdateStatus _status = AppUpdateStatus.idle;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = -1;
  String _message = '';
  String _apkPath = '';

  AppUpdateStatus get status => _status;
  double get progress => _progress;
  int get receivedBytes => _receivedBytes;
  int get totalBytes => _totalBytes;
  String get message => _message;
  String get apkPath => _apkPath;

  int get percent => (_progress * 100.0).round().clamp(0, 100);

  bool get isBusy =>
      _status == AppUpdateStatus.checking ||
      _status == AppUpdateStatus.downloading ||
      _status == AppUpdateStatus.replacing ||
      _status == AppUpdateStatus.ready;

  void ensureListening() {
    if (_eventSub != null) return;
    try {
      _eventSub = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is! Map) return;
          final rawStatus = (event['status'] as String?) ?? 'idle';
          _status = _parseStatus(rawStatus);
          _progress = ((event['progress'] as num?)?.toDouble() ?? 0.0)
              .clamp(0.0, 1.0);
          _receivedBytes = (event['receivedBytes'] as num?)?.toInt() ?? 0;
          _totalBytes = (event['totalBytes'] as num?)?.toInt() ?? -1;
          _message = (event['message'] as String?) ?? '';
          _apkPath = (event['apkPath'] as String?) ?? _apkPath;
          notifyListeners();
        },
        onError: (_) {},
      );
    } catch (_) {
      // EventChannel unavailable in headless widget tests
    }
  }

  AppUpdateStatus _parseStatus(String raw) {
    switch (raw) {
      case 'checking':
        return AppUpdateStatus.checking;
      case 'downloading':
        return AppUpdateStatus.downloading;
      case 'replacing':
        return AppUpdateStatus.replacing;
      case 'ready':
        return AppUpdateStatus.ready;
      case 'installing':
        return AppUpdateStatus.installing;
      case 'needs_permission':
        return AppUpdateStatus.needsPermission;
      case 'error':
        return AppUpdateStatus.error;
      default:
        return AppUpdateStatus.idle;
    }
  }

  Future<bool> startUpdate() async {
    ensureListening();
    _status = AppUpdateStatus.checking;
    _progress = 0.02;
    _receivedBytes = 0;
    _totalBytes = -1;
    _message = 'Connecting to GitHub...';
    notifyListeners();

    try {
      final res = await _methodChannel.invokeMethod<bool>('startUpdate');
      return res ?? true;
    } on MissingPluginException {
      _status = AppUpdateStatus.error;
      _progress = 0.0;
      _message = 'Android native updater is only supported on Android devices.';
      notifyListeners();
      return false;
    } catch (e) {
      _status = AppUpdateStatus.error;
      _progress = 0.0;
      _message = 'Failed to start update: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> launchPendingInstall() async {
    ensureListening();
    try {
      final ok =
          await _methodChannel.invokeMethod<bool>('launchPendingInstall');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openInstallPermissionSettings() async {
    try {
      final ok = await _methodChannel
          .invokeMethod<bool>('openInstallPermissionSettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canInstallUnknownPackages() async {
    try {
      final ok = await _methodChannel
          .invokeMethod<bool>('canInstallUnknownPackages');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  String formatBytesProgress() {
    if (_receivedBytes <= 0) return '';
    final recMb = (_receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    if (_totalBytes > 0) {
      final totMb = (_totalBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$recMb / $totMb MB';
    }
    return '$recMb MB';
  }

  @visibleForTesting
  void resetForTest() {
    _status = AppUpdateStatus.idle;
    _progress = 0.0;
    _receivedBytes = 0;
    _totalBytes = -1;
    _message = '';
    _apkPath = '';
    notifyListeners();
  }
}
