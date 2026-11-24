import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/holo_3d_security_scanner.dart';
import '../widgets_3d/smooth_radial_gauge.dart';

/// ---------------------------------------------------------------------------
/// TOOLER REAL HARDWARE, OS, PROCESS, NOTIFICATION, TRASH & STORAGE SECURITY
/// - 100% genuine native Android backend via ToolerSecurityEngine &
///   ToolerNotificationListenerService (zero fake/demo data)
/// - Flow: Start Scan -> Live Scan Audit -> Complete -> Ready to Clean & Finish
/// - Security Risk Detection card sits below telemetry & appears strictly after
///   scan completion
/// - Separate Bottom Recycle Bin / Trash cleaner appears strictly after scan
/// - Issues / Junk / Largest / Unopened tabs all support individual select,
///   Select All & permanent deletion
/// - Persistent fingerprint registry guarantees resolved items stay resolved
/// - Sweet animated "Nothing Else to Clean" assurance when cleanable count is 0
/// ---------------------------------------------------------------------------
class SecurityScreen extends StatefulWidget {
  final StationeryTheme theme;

  const SecurityScreen({super.key, required this.theme});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

enum _ScanState { idle, scanning, completed }

class _LiveAuditLog {
  final String stage;
  final String target;
  final String category;
  final String severity; // ok, info, medium, high

  const _LiveAuditLog({
    required this.stage,
    required this.target,
    required this.category,
    required this.severity,
  });
}

class _SecurityScreenState extends State<SecurityScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const MethodChannel _methodChannel =
      MethodChannel('com.tooler.tooler/security_scan');
  static const EventChannel _eventChannel =
      EventChannel('com.tooler.tooler/security_scan_events');

  StreamSubscription<dynamic>? _eventSub;
  Ticker? _waveTicker;
  Duration _lastWaveElapsed = Duration.zero;
  final ValueNotifier<int> _waveFrameNotifier = ValueNotifier<int>(0);
  double _wavePhase = 0.0;
  double _waveEnergy = 0.0;
  bool _isFinishWaveRed = false;

  late final AnimationController _sweetAnimController;
  late final AnimationController _screenRefreshController;
  late final AnimationController _finishWaveController;

  _ScanState _scanState = _ScanState.idle;
  double _scanProgress = 0.0;
  String _currentStage = 'READY';
  int? _securityScore;
  int _selectedResultTab = 0; // 0=Issues, 1=Junk, 2=Largest, 3=Unopened

  // Real Hardware & OS Telemetry + Device Authorities
  String _androidVersion = 'Android';
  int _sdkInt = 0;
  String _securityPatch = '--';
  String _kernelVersion = '--';
  String _device = 'ANDROID DEVICE';
  String _selinuxState = '--';
  bool _isRooted = false;
  bool _isDevMode = false;
  bool _isAdbEnabled = false;
  bool _isDeviceSecure = true;
  bool _hasHttpProxy = false;
  bool _isVpnActive = false;
  String _networkType = '--';
  bool _hasAllFilesAccess = false;
  bool _hasUsageAccess = false;
  bool _hasNotificationAccess = false;

  int _totalRamMb = 0;
  int _availRamMb = 0;
  int _totalStorageBytes = 0;
  int _availStorageBytes = 0;
  int _usedStorageBytes = 0;

  // Live scan counters
  int _liveAppsScanned = 0;
  int _liveFilesScanned = 0;
  int _liveIssuesCount = 0;
  int _liveJunkBytes = 0;
  int _liveBgAppsCount = 0;
  int _liveNotifCount = 0;
  int _liveTrashCount = 0;
  final List<_LiveAuditLog> _liveLogs = [];

  // Real Scan Results
  int _scanDurationMs = 0;
  List<Map<String, dynamic>> _systemWarnings = [];
  List<Map<String, dynamic>> _suspiciousApps = [];
  List<Map<String, dynamic>> _fishyFiles = [];
  List<Map<String, dynamic>> _junkFiles = [];
  List<Map<String, dynamic>> _largestFiles = [];
  List<Map<String, dynamic>> _unopenedFiles = [];
  List<Map<String, dynamic>> _backgroundApps = [];
  List<Map<String, dynamic>> _activeNotifications = [];
  List<Map<String, dynamic>> _trashFiles = [];
  List<String> _protectedFgsRemaining = [];

  // Selections across all 4 result tabs + Recycle Bin
  final Set<String> _selectedIssueKeys = {};
  final Set<String> _selectedJunkPaths = {};
  final Set<String> _selectedLargestPaths = {};
  final Set<String> _selectedUnopenedPaths = {};
  final Set<String> _selectedTrashIds = {};
  bool _showAllJunk = false;

  // Cleanup & Session Counters
  bool _isCleaning = false;
  bool _isMasterCleaning = false;
  bool _isTrashCleaning = false;
  bool _masterSweepDone = false;
  int _totalFreedBytesSession = 0;
  int _totalDeletedCountSession = 0;
  int _lastRamFreedMb = 0;
  int _lastNotifsCleared = 0;
  int _lastKilledBgCount = 0;

  @override
  void initState() {
    super.initState();
    _sweetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _screenRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _finishWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _waveTicker = createTicker((elapsed) {
      if (!mounted) return;
      double dt = 0.016;
      if (_lastWaveElapsed != Duration.zero && elapsed > _lastWaveElapsed) {
        dt = ((elapsed - _lastWaveElapsed).inMicroseconds / 1000000.0)
            .clamp(0.001, 0.05);
      }
      _lastWaveElapsed = elapsed;

      final bool isScanActive = _scanState == _ScanState.scanning;
      final bool isFinishActive =
          _isMasterCleaning || _finishWaveController.isAnimating;
      final bool wavesActive = isScanActive || isFinishActive;

      // Only show waves when scan starts (multi-color) or during finish (red)
      final double targetEnergy = wavesActive ? 1.0 : 0.0;
      final double rate = wavesActive ? 7.5 : 5.2;
      final double factor = 1.0 - math.exp(-rate * dt);
      _waveEnergy += (targetEnergy - _waveEnergy) * factor;
      if (!wavesActive && _waveEnergy < 0.004) {
        _waveEnergy = 0.0;
      }
      if (wavesActive) {
        _isFinishWaveRed = isFinishActive;
      }

      if (_waveEnergy > 0.0) {
        final double angularSpeed =
            isFinishActive ? 3.8 : (2.8 + _waveEnergy * 0.9);
        _wavePhase = (_wavePhase + angularSpeed * dt) % (math.pi * 200.0);
        _waveFrameNotifier.value++;
      }
    })..start();

    WidgetsBinding.instance.addObserver(this);
    _subscribeToScanEvents();
    _fetchSystemSecurityData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveTicker?.dispose();
    _waveFrameNotifier.dispose();
    _sweetAnimController.dispose();
    _screenRefreshController.dispose();
    _finishWaveController.dispose();
    _eventSub?.cancel();
    if (_scanState == _ScanState.scanning) {
      _methodChannel.invokeMethod('cancelScan');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchSystemSecurityData();
    }
  }

  void _subscribeToScanEvents() {
    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      (rawEvent) {
        if (!mounted || rawEvent is! Map) return;
        final map = Map<String, dynamic>.from(rawEvent);
        final type = map['type'] as String? ?? '';

        if (type == 'progress') {
          setState(() {
            _scanState = _ScanState.scanning;
            _scanProgress =
                (map['progress'] as num?)?.toDouble() ?? _scanProgress;
            _currentStage = map['stage'] as String? ?? 'SCANNING';
            _liveAppsScanned =
                (map['appsScanned'] as num?)?.toInt() ?? _liveAppsScanned;
            _liveFilesScanned =
                (map['filesScanned'] as num?)?.toInt() ?? _liveFilesScanned;
            _liveIssuesCount =
                (map['issuesCount'] as num?)?.toInt() ?? _liveIssuesCount;
            _liveJunkBytes =
                (map['junkBytes'] as num?)?.toInt() ?? _liveJunkBytes;
            _liveBgAppsCount =
                (map['bgAppsCount'] as num?)?.toInt() ?? _liveBgAppsCount;
            _liveNotifCount =
                (map['notifCount'] as num?)?.toInt() ?? _liveNotifCount;
            _liveTrashCount =
                (map['trashCount'] as num?)?.toInt() ?? _liveTrashCount;

            final target = map['target'] as String? ?? '';
            if (target.isNotEmpty) {
              _liveLogs.insert(
                0,
                _LiveAuditLog(
                  stage: _currentStage,
                  target: target,
                  category: map['category'] as String? ?? 'Audit',
                  severity: map['severity'] as String? ?? 'info',
                ),
              );
              if (_liveLogs.length > 35) {
                _liveLogs.removeLast();
              }
            }
          });
        } else if (type == 'complete') {
          final sysMap = map['systemInfo'] is Map
              ? Map<String, dynamic>.from(map['systemInfo'] as Map)
              : null;
          if (sysMap != null) _applySystemInfo(sysMap);

          final warnings = _castMapList(map['systemWarnings']);
          final apps = _castMapList(map['suspiciousApps']);
          final fishy = _castMapList(map['fishyFiles']);
          final junk = _castMapList(map['junkFiles']);
          final largest = _castMapList(map['largestFiles']);
          final unopened = _castMapList(map['unopenedFiles']);
          final bgApps = _castMapList(map['backgroundApps']);
          final notifs = _castMapList(map['activeNotifications']);
          final trash = _castMapList(map['trashFiles']);

          SoundService().playSuccess();
          setState(() {
            _scanState = _ScanState.completed;
            _scanProgress = 1.0;
            _securityScore = (map['securityScore'] as num?)?.toInt() ?? 100;
            _scanDurationMs = (map['durationMs'] as num?)?.toInt() ?? 0;
            _liveAppsScanned =
                (map['appsScanned'] as num?)?.toInt() ?? _liveAppsScanned;
            _liveFilesScanned =
                (map['filesScanned'] as num?)?.toInt() ?? _liveFilesScanned;
            _hasAllFilesAccess =
                map['hasAllFilesAccess'] as bool? ?? _hasAllFilesAccess;
            _hasUsageAccess =
                map['hasUsageAccess'] as bool? ?? _hasUsageAccess;
            _hasNotificationAccess =
                map['hasNotificationAccess'] as bool? ?? _hasNotificationAccess;

            _systemWarnings = warnings;
            _suspiciousApps = apps;
            _fishyFiles = fishy;
            _junkFiles = junk;
            _largestFiles = largest;
            _unopenedFiles = unopened;
            _backgroundApps = bgApps;
            _activeNotifications = notifs;
            _trashFiles = trash;
            _protectedFgsRemaining = [];
            _masterSweepDone = false;
            _showAllJunk = false;

            _selectedIssueKeys.clear();
            _selectedLargestPaths.clear();
            _selectedUnopenedPaths.clear();

            _selectedJunkPaths
              ..clear()
              ..addAll(junk
                  .map((e) => e['path'] as String? ?? '')
                  .where((p) => p.isNotEmpty));

            _selectedTrashIds
              ..clear()
              ..addAll(trash
                  .map((e) => e['id']?.toString() ?? '')
                  .where((id) => id.isNotEmpty));

            _liveLogs.clear();

            final issueCount = warnings.length + apps.length + fishy.length;
            if (issueCount > 0) {
              _selectedResultTab = 0;
            } else if (junk.isNotEmpty) {
              _selectedResultTab = 1;
            } else if (largest.isNotEmpty) {
              _selectedResultTab = 2;
            } else if (unopened.isNotEmpty) {
              _selectedResultTab = 3;
            } else {
              _selectedResultTab = 0;
            }
          });
        } else if (type == 'error') {
          setState(() {
            _scanState = _ScanState.idle;
            _liveLogs.clear();
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _scanState = _ScanState.idle;
          });
        }
      },
    );
  }

  List<Map<String, dynamic>> _castMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> _fetchSystemSecurityData() async {
    try {
      final res = await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>('getSecurityInfo');
      if (res != null && mounted) {
        setState(() {
          _applySystemInfo(Map<String, dynamic>.from(res));
        });
      }
    } catch (_) {}
  }

  void _applySystemInfo(Map<String, dynamic> res) {
    _androidVersion = res['androidVersion'] as String? ?? _androidVersion;
    _sdkInt = (res['sdkInt'] as num?)?.toInt() ?? _sdkInt;
    _securityPatch = res['securityPatch'] as String? ?? _securityPatch;
    _kernelVersion = res['kernelVersion'] as String? ?? _kernelVersion;
    _device = res['device'] as String? ?? _device;
    _selinuxState = res['selinuxState'] as String? ?? _selinuxState;
    _isRooted = res['isRooted'] as bool? ?? _isRooted;
    _isDevMode = res['isDevMode'] as bool? ?? _isDevMode;
    _isAdbEnabled = res['isAdbEnabled'] as bool? ?? _isAdbEnabled;
    _isDeviceSecure = res['isDeviceSecure'] as bool? ?? _isDeviceSecure;
    _hasHttpProxy = res['hasHttpProxy'] as bool? ?? _hasHttpProxy;
    _isVpnActive = res['isVpnActive'] as bool? ?? _isVpnActive;
    _networkType = res['networkType'] as String? ?? _networkType;
    _hasAllFilesAccess =
        res['hasAllFilesAccess'] as bool? ?? _hasAllFilesAccess;
    _hasUsageAccess = res['hasUsageAccess'] as bool? ?? _hasUsageAccess;
    _hasNotificationAccess =
        res['hasNotificationAccess'] as bool? ?? _hasNotificationAccess;
    _totalRamMb = (res['totalRamMb'] as num?)?.toInt() ?? _totalRamMb;
    _availRamMb = (res['availRamMb'] as num?)?.toInt() ?? _availRamMb;
    _totalStorageBytes =
        (res['totalStorageBytes'] as num?)?.toInt() ?? _totalStorageBytes;
    _availStorageBytes =
        (res['availStorageBytes'] as num?)?.toInt() ?? _availStorageBytes;
    _usedStorageBytes =
        (res['usedStorageBytes'] as num?)?.toInt() ?? _usedStorageBytes;
  }

  Future<void> _startOrStopScan() async {
    if (_scanState == _ScanState.scanning) {
      SoundService().playTap();
      try {
        await _methodChannel.invokeMethod('cancelScan');
      } catch (_) {}
      setState(() {
        _scanState = _ScanState.idle;
        _liveLogs.clear();
      });
      return;
    }

    SoundService().playClick();
    _finishWaveController.stop();
    _finishWaveController.reset();
    setState(() {
      _scanState = _ScanState.scanning;
      _scanProgress = 0.02;
      _currentStage = 'INITIALIZING';
      _isFinishWaveRed = false;
      _liveAppsScanned = 0;
      _liveFilesScanned = 0;
      _liveIssuesCount = 0;
      _liveJunkBytes = 0;
      _liveBgAppsCount = 0;
      _liveNotifCount = 0;
      _liveTrashCount = 0;
      _liveLogs.clear();
      _masterSweepDone = false;
      _protectedFgsRemaining = [];
    });

    try {
      await _methodChannel.invokeMethod('startDeepScan');
    } catch (_) {
      if (mounted) {
        setState(() => _scanState = _ScanState.idle);
      }
    }
  }

  Future<void> _requestAllFilesAccess() async {
    SoundService().playTap();
    try {
      await _methodChannel.invokeMethod('requestAllFilesAccess');
    } catch (_) {}
  }

  Future<void> _requestUsageAccess() async {
    SoundService().playTap();
    try {
      await _methodChannel.invokeMethod('requestUsageAccess');
    } catch (_) {}
  }

  Future<void> _requestNotificationAccess() async {
    SoundService().playTap();
    try {
      await _methodChannel.invokeMethod('requestNotificationAccess');
    } catch (_) {}
  }

  /// Master 1-Click Clean & Finish:
  /// Kills active/cached BG apps, reclaims RAM, flushes display & image render caches
  /// with visual screen refresh sweep, clears notification shade, deletes junk +
  /// fishy threat files, and locks cleaned fingerprints so resolved items don't repeat.
  Future<void> _runMasterCleanAndFinish() async {
    if (_isMasterCleaning) return;
    SoundService().playClick();
    setState(() {
      _isMasterCleaning = true;
      _isFinishWaveRed = true;
    });

    // Trigger Red Finish Border Waves + Image/Frame Purge + Screen Refresh Sweep
    _finishWaveController.forward(from: 0.0);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _screenRefreshController.forward(from: 0.0);

    final junkPaths = _junkFiles
        .map((e) => e['path'] as String? ?? '')
        .where((p) => p.isNotEmpty)
        .toList();
    final fishyPaths = _fishyFiles
        .map((e) => e['path'] as String? ?? '')
        .where((p) => p.isNotEmpty)
        .toList();
    final bgPackages = _backgroundApps
        .map((e) => e['packageName'] as String? ?? '')
        .where((p) => p.isNotEmpty)
        .toList();

    final resolvedFps = <String>[
      ..._junkFiles
          .map((e) => e['fingerprint'] as String? ?? '')
          .where((s) => s.isNotEmpty),
      ..._fishyFiles
          .map((e) => e['fingerprint'] as String? ?? '')
          .where((s) => s.isNotEmpty),
    ];

    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'cleanMasterSweep',
        {
          'junkPaths': junkPaths,
          'fishyPaths': fishyPaths,
          'bgPackages': bgPackages,
          'clearNotifications': _activeNotifications.isNotEmpty || _hasNotificationAccess,
          'resolvedFingerprints': resolvedFps,
        },
      );

      if (res != null && mounted) {
        final deletedJunkPaths = (res['deletedJunkPaths'] as List? ?? [])
            .map((e) => e.toString())
            .toSet();
        final deletedFishyPaths = (res['deletedFishyPaths'] as List? ?? [])
            .map((e) => e.toString())
            .toSet();
        final freedBytes = (res['freedBytes'] as num?)?.toInt() ?? 0;
        final delJunkCount = (res['deletedJunkCount'] as num?)?.toInt() ?? 0;
        final delFishyCount = (res['deletedFishyCount'] as num?)?.toInt() ?? 0;
        final killedCount = (res['killedBgCount'] as num?)?.toInt() ?? 0;
        final killedPkgs = (res['killedPackages'] as List? ?? [])
            .map((e) => e.toString())
            .toSet();
        final protectedFgs = (res['protectedFgsPackages'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        final ramFreedMb = (res['ramFreedMb'] as num?)?.toInt() ?? 0;
        final notifsCleared =
            (res['notificationsCleared'] as num?)?.toInt() ?? 0;
        final newRam = (res['availRamMb'] as num?)?.toInt();
        final newStorage = (res['availStorageBytes'] as num?)?.toInt();

        SoundService().playSuccess();
        setState(() {
          _junkFiles.removeWhere((f) => deletedJunkPaths.contains(f['path']));
          _selectedJunkPaths.removeAll(deletedJunkPaths);
          _fishyFiles.removeWhere((f) => deletedFishyPaths.contains(f['path']));
          _backgroundApps
              .removeWhere((b) => killedPkgs.contains(b['packageName']));
          if (notifsCleared > 0 || res['notificationListenerConnected'] == true) {
            _activeNotifications.clear();
          }
          _protectedFgsRemaining = protectedFgs;
          _totalFreedBytesSession += freedBytes;
          _totalDeletedCountSession += (delJunkCount + delFishyCount);
          _lastRamFreedMb = ramFreedMb;
          _lastNotifsCleared = notifsCleared;
          _lastKilledBgCount = killedCount;
          _masterSweepDone = true;
          if (newRam != null && newRam > 0) _availRamMb = newRam;
          if (newStorage != null && newStorage > 0) {
            _availStorageBytes = newStorage;
            if (_totalStorageBytes >= newStorage) {
              _usedStorageBytes = _totalStorageBytes - newStorage;
            }
          }
          _recomputeScore();
        });

        final parts = <String>[
          if (killedCount > 0) '$killedCount BG apps stopped',
          if (ramFreedMb > 0) '$ramFreedMb MB RAM reclaimed',
          if (notifsCleared > 0) '$notifsCleared notifications cleared',
          if (delJunkCount + delFishyCount > 0)
            '${delJunkCount + delFishyCount} files (${_formatBytes(freedBytes)}) deleted',
          'Display refreshed',
        ];
        _showSnack(parts.join(' • '));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isMasterCleaning = false);
      _fetchSystemSecurityData();
    }
  }

  /// Empties Trash / Recycle Bin items permanently after user confirmation.
  Future<void> _cleanSelectedRecycleBin() async {
    if (_isTrashCleaning || _selectedTrashIds.isEmpty) return;

    final selectedItems = _trashFiles
        .where((e) => _selectedTrashIds.contains(e['id']?.toString() ?? ''))
        .toList();
    if (selectedItems.isEmpty) return;

    final totalSelBytes = selectedItems.fold<int>(
        0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

    final confirm = await _confirmPermanentDelete(
      title: 'Empty Recycle Bin Permanently?',
      subtitle:
          'This will permanently delete ${selectedItems.length} trashed files (${_formatBytes(totalSelBytes)}) from device Trash & MediaStore. They cannot be recovered.',
      confirmLabel: 'Empty Trash',
    );
    if (confirm != true) return;

    SoundService().playClick();
    setState(() {
      _isTrashCleaning = true;
      _isFinishWaveRed = true;
    });
    _finishWaveController.forward(from: 0.0);
    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'cleanRecycleBin',
        {'items': selectedItems},
      );
      if (res != null && mounted) {
        final deletedIds = (res['deletedIds'] as List? ?? [])
            .map((e) => e.toString())
            .toSet();
        final deletedCount = (res['deletedCount'] as num?)?.toInt() ?? 0;
        final freedBytes = (res['freedBytes'] as num?)?.toInt() ?? 0;
        final newRam = (res['availRamMb'] as num?)?.toInt();
        final newStorage = (res['availStorageBytes'] as num?)?.toInt();

        SoundService().playSuccess();
        setState(() {
          _trashFiles.removeWhere((e) => deletedIds.contains(e['id']?.toString()));
          _selectedTrashIds.removeAll(deletedIds);
          _totalFreedBytesSession += freedBytes;
          _totalDeletedCountSession += deletedCount;
          if (newRam != null && newRam > 0) _availRamMb = newRam;
          if (newStorage != null && newStorage > 0) {
            _availStorageBytes = newStorage;
          }
        });

        _showSnack(
          deletedCount > 0
              ? 'Recycle Bin emptied: $deletedCount items • Freed ${_formatBytes(freedBytes)}'
              : 'Some trashed items require All Files Access or OS confirmation',
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isTrashCleaning = false);
      _fetchSystemSecurityData();
    }
  }

  /// Generic permanent batch file deletion helper shared across Junk, Largest & Unopened.
  Future<void> _deleteFileBatch({
    required Set<String> selectedPaths,
    required List<Map<String, dynamic>> sourceList,
    required String itemLabel,
    bool requireConfirm = true,
  }) async {
    if (_isCleaning || selectedPaths.isEmpty) return;

    final selectedItems = sourceList
        .where((e) => selectedPaths.contains(e['path'] as String? ?? ''))
        .toList();
    if (selectedItems.isEmpty) return;

    final totalBytes = selectedItems.fold<int>(
        0, (s, e) => s + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

    if (requireConfirm) {
      final confirm = await _confirmPermanentDelete(
        title: 'Delete ${selectedItems.length} $itemLabel Permanently?',
        subtitle:
            'Total size: ${_formatBytes(totalBytes)}. Selected files will be permanently erased from device storage.',
        confirmLabel: 'Delete Permanently',
      );
      if (confirm != true) return;
    }

    SoundService().playClick();
    setState(() => _isCleaning = true);

    try {
      final paths = selectedPaths.toList();
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'deleteFiles',
        {'paths': paths},
      );
      if (res != null && mounted) {
        final deletedPaths = (res['deletedPaths'] as List? ?? [])
            .map((e) => e.toString())
            .toSet();
        final freedBytes = (res['freedBytes'] as num?)?.toInt() ?? 0;
        final deletedCount = (res['deletedCount'] as num?)?.toInt() ?? 0;
        final newRam = (res['availRamMb'] as num?)?.toInt();
        final newStorage = (res['availStorageBytes'] as num?)?.toInt();

        // Mark deleted file fingerprints as resolved so identical paths don't nag
        final deletedFps = sourceList
            .where((f) => deletedPaths.contains(f['path']))
            .map((f) => f['fingerprint'] as String? ?? '')
            .where((fp) => fp.isNotEmpty)
            .toList();
        if (deletedFps.isNotEmpty) {
          await _methodChannel.invokeMethod(
            'markResolvedFingerprints',
            {'fingerprints': deletedFps},
          );
        }

        SoundService().playSuccess();
        setState(() {
          _junkFiles.removeWhere((f) => deletedPaths.contains(f['path']));
          _largestFiles.removeWhere((f) => deletedPaths.contains(f['path']));
          _unopenedFiles.removeWhere((f) => deletedPaths.contains(f['path']));
          _fishyFiles.removeWhere((f) => deletedPaths.contains(f['path']));
          _selectedJunkPaths.removeAll(deletedPaths);
          _selectedLargestPaths.removeAll(deletedPaths);
          _selectedUnopenedPaths.removeAll(deletedPaths);
          _totalFreedBytesSession += freedBytes;
          _totalDeletedCountSession += deletedCount;
          if (newRam != null && newRam > 0) _availRamMb = newRam;
          if (newStorage != null && newStorage > 0) {
            _availStorageBytes = newStorage;
          }
          _recomputeScore();
        });

        _showSnack(
          deletedCount > 0
              ? 'Deleted $deletedCount $itemLabel • Freed ${_formatBytes(freedBytes)}'
              : 'Selected files are protected by Android system (enable All Files Access)',
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCleaning = false);
      _fetchSystemSecurityData();
    }
  }

  /// Batch resolve/delete for selected items in the Issues tab (Fishy files + Apps + Warnings).
  Future<void> _resolveSelectedIssues() async {
    if (_isCleaning || _selectedIssueKeys.isEmpty) return;

    final selectedFishyPaths = <String>[];
    final selectedFps = <String>[];
    final selectedAppPkgs = <String>[];

    for (final f in _fishyFiles) {
      final path = f['path'] as String? ?? '';
      final key = 'file:$path';
      if (_selectedIssueKeys.contains(key) && path.isNotEmpty) {
        selectedFishyPaths.add(path);
        final fp = f['fingerprint'] as String? ?? '';
        if (fp.isNotEmpty) selectedFps.add(fp);
      }
    }
    for (final a in _suspiciousApps) {
      final pkg = a['packageName'] as String? ?? '';
      final key = 'app:$pkg';
      if (_selectedIssueKeys.contains(key) && pkg.isNotEmpty) {
        selectedAppPkgs.add(pkg);
        final fp = a['fingerprint'] as String? ?? '';
        if (fp.isNotEmpty) selectedFps.add(fp);
      }
    }
    for (final w in _systemWarnings) {
      final id = w['id'] as String? ?? '';
      final key = 'sys:$id';
      if (_selectedIssueKeys.contains(key) && id.isNotEmpty) {
        final fp = w['fingerprint'] as String? ?? '';
        if (fp.isNotEmpty) selectedFps.add(fp);
      }
    }

    if (selectedFishyPaths.isNotEmpty) {
      final confirm = await _confirmPermanentDelete(
        title: 'Delete & Resolve Selected Issues?',
        subtitle:
            'This will permanently delete ${selectedFishyPaths.length} risky file(s) and resolve selected warnings so they do not re-appear.',
        confirmLabel: 'Clean & Resolve',
      );
      if (confirm != true) return;
    }

    SoundService().playClick();
    setState(() => _isCleaning = true);
    try {
      int deletedCount = 0;
      int freedBytes = 0;
      Set<String> deletedPaths = {};

      if (selectedFishyPaths.isNotEmpty) {
        final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
          'deleteFiles',
          {'paths': selectedFishyPaths},
        );
        if (res != null) {
          deletedPaths = (res['deletedPaths'] as List? ?? [])
              .map((e) => e.toString())
              .toSet();
          deletedCount = (res['deletedCount'] as num?)?.toInt() ?? 0;
          freedBytes = (res['freedBytes'] as num?)?.toInt() ?? 0;
        }
      }

      if (selectedFps.isNotEmpty) {
        await _methodChannel.invokeMethod(
          'markResolvedFingerprints',
          {'fingerprints': selectedFps},
        );
      }

      if (selectedAppPkgs.isNotEmpty) {
        // Trigger system uninstall flow for the first selected suspicious app
        await _methodChannel.invokeMethod(
          'uninstallApp',
          {'packageName': selectedAppPkgs.first},
        );
      }

      if (mounted) {
        SoundService().playSuccess();
        setState(() {
          _fishyFiles.removeWhere((f) =>
              deletedPaths.contains(f['path']) ||
              _selectedIssueKeys.contains('file:${f['path']}'));
          _systemWarnings
              .removeWhere((w) => _selectedIssueKeys.contains('sys:${w['id']}'));
          _suspiciousApps.removeWhere(
              (a) => _selectedIssueKeys.contains('app:${a['packageName']}'));
          _selectedIssueKeys.clear();
          _totalFreedBytesSession += freedBytes;
          _totalDeletedCountSession += deletedCount;
          _recomputeScore();
        });
        _showSnack(
          deletedCount > 0
              ? 'Resolved issues • Permanently deleted $deletedCount files (${_formatBytes(freedBytes)})'
              : 'Selected issues marked resolved and suppressed permanently',
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCleaning = false);
      _fetchSystemSecurityData();
    }
  }

  Future<bool?> _confirmPermanentDelete({
    required String title,
    required String subtitle,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: widget.theme.text,
          ),
        ),
        content: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: widget.theme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSingleFile({
    required String path,
    required String name,
    required bool isFishy,
    required bool isUnopened,
    bool isLargest = false,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete File Permanently?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: widget.theme.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF43F5E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              path,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: widget.theme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'deleteFiles',
        {
          'paths': [path]
        },
      );
      if (res != null && mounted) {
        final deletedCount = (res['deletedCount'] as num?)?.toInt() ?? 0;
        final freedBytes = (res['freedBytes'] as num?)?.toInt() ?? 0;
        if (deletedCount > 0) {
          SoundService().playSuccess();
          setState(() {
            if (isFishy) _fishyFiles.removeWhere((f) => f['path'] == path);
            if (isUnopened) {
              _unopenedFiles.removeWhere((f) => f['path'] == path);
              _selectedUnopenedPaths.remove(path);
            }
            if (isLargest) {
              _largestFiles.removeWhere((f) => f['path'] == path);
              _selectedLargestPaths.remove(path);
            }
            _totalFreedBytesSession += freedBytes;
            _totalDeletedCountSession += deletedCount;
            _recomputeScore();
          });
          _showSnack('Deleted $name (${_formatBytes(freedBytes)} freed)');
          _fetchSystemSecurityData();
        } else {
          _showSnack('Could not delete file — check Deep Storage permission');
        }
      }
    } catch (_) {}
  }

  Future<void> _showFileInspectorSheet(Map<String, dynamic> fileItem) async {
    final path = fileItem['path'] as String? ?? '';
    if (path.isEmpty) return;

    SoundService().playTap();
    Map<String, dynamic>? details;
    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'inspectFile',
        {'path': path},
      );
      if (res != null) details = Map<String, dynamic>.from(res);
    } catch (_) {}

    if (!mounted) return;
    final theme = widget.theme;
    final name =
        details?['name'] as String? ?? fileItem['name'] as String? ?? 'File';
    final sizeBytes = (details?['sizeBytes'] as num?)?.toInt() ??
        (fileItem['sizeBytes'] as num?)?.toInt() ??
        0;
    final sha256 = details?['sha256'] as String? ?? 'Unavailable';
    final modMs = (details?['lastModifiedMs'] as num?)?.toInt() ?? 0;
    final accMs = (details?['lastAccessedMs'] as num?)?.toInt() ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: theme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _inspectRow('Exact Size', _formatBytes(sizeBytes), theme),
            _inspectRow('Modified', _formatDate(modMs), theme),
            _inspectRow('Last Accessed', _formatDate(accMs), theme),
            const SizedBox(height: 8),
            Text(
              'FULL PATH',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border),
              ),
              child: SelectableText(
                path,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5, color: theme.text),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'SHA-256 CHECKSUM',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border),
              ),
              child: SelectableText(
                sha256,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5, color: theme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inspectRow(String k, String v, StationeryTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: theme.textSecondary)),
          Text(v,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: theme.text)),
        ],
      ),
    );
  }

  void _recomputeScore() {
    int score = 100;
    for (final w in _systemWarnings) {
      final s = w['severity'] as String? ?? 'LOW';
      score -= s == 'HIGH' ? 18 : (s == 'MEDIUM' ? 9 : 4);
    }
    for (final a in _suspiciousApps) {
      score -= (a['severity'] == 'HIGH') ? 14 : 6;
    }
    for (final f in _fishyFiles) {
      final s = f['severity'] as String? ?? 'LOW';
      score -= s == 'HIGH' ? 12 : (s == 'MEDIUM' ? 4 : 1);
    }
    final remJunk = _junkFiles.fold<int>(
        0, (s, e) => s + ((e['sizeBytes'] as num?)?.toInt() ?? 0));
    if (remJunk > 200 * 1024 * 1024) {
      score -= 6;
    } else if (remJunk > 25 * 1024 * 1024) {
      score -= 3;
    }
    _securityScore = score.clamp(12, 100);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get _totalIssues =>
      _systemWarnings.length + _suspiciousApps.length + _fishyFiles.length;

  int get _totalJunkBytes => _junkFiles.fold<int>(
      0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

  int get _totalTrashBytes => _trashFiles.fold<int>(
      0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

  int get _selectedJunkBytes => _junkFiles
      .where((e) => _selectedJunkPaths.contains(e['path']))
      .fold<int>(0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

  int get _selectedLargestBytes => _largestFiles
      .where((e) => _selectedLargestPaths.contains(e['path']))
      .fold<int>(0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

  int get _selectedUnopenedBytes => _unopenedFiles
      .where((e) => _selectedUnopenedPaths.contains(e['path']))
      .fold<int>(0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

  int get _selectedTrashBytes => _trashFiles
      .where((e) => _selectedTrashIds.contains(e['id']?.toString() ?? ''))
      .fold<int>(0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

  /// Number of cleanable clutter items handled by Master Clean & Finish
  int get _masterCleanableCount =>
      _backgroundApps.length +
      _activeNotifications.length +
      _junkFiles.length +
      _fishyFiles.length;

  HoloScannerMode get _scannerMode {
    if (_scanState == _ScanState.scanning) return HoloScannerMode.scanning;
    if (_scanState == _ScanState.idle) return HoloScannerMode.idle;
    final hasHigh = _systemWarnings.any((e) => e['severity'] == 'HIGH') ||
        _suspiciousApps.any((e) => e['severity'] == 'HIGH') ||
        _fishyFiles.any((e) => e['severity'] == 'HIGH');
    if (hasHigh) return HoloScannerMode.threat;
    if (_totalIssues > 0 ||
        _totalJunkBytes > 25 * 1024 * 1024 ||
        _backgroundApps.isNotEmpty ||
        _activeNotifications.isNotEmpty) {
      return HoloScannerMode.warning;
    }
    return HoloScannerMode.clean;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isScanning = _scanState == _ScanState.scanning;
    final isCompleted = _scanState == _ScanState.completed;

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. UNBOXED HERO RADIAL GAUGE + MULTI-COLOR AURORA WAVES AT TOP
                  _buildSecurityRadialBarCard(theme, isScanning),

                  const SizedBox(height: 10),

                  // 2. PRIMARY SCAN BUTTON (Scan -> Stop -> Fresh Scan)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildActionButton(theme),
                  ),

                  // 3. LIVE SCAN AUDIT PANEL (STRICTLY WHILE SCANNING)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: isScanning
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                            child: _buildLiveScanAuditPanel(theme),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // 4. DEVICE AUTHORITY BAR (All Files, Usage Access, Notifications)
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildAuthorityCard(theme),
                  ),

                  // 5. AFTER SCAN COMPLETES: MASTER CLEAN & FINISH OR "NOTHING ELSE" SWEET CARD
                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _masterCleanableCount > 0
                          ? _buildMasterCleanFinishHub(theme)
                          : _buildNothingElseSweetCard(theme),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 6. REAL HARDWARE RAM & STORAGE TELEMETRY
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildHardwareTelemetryCard(theme),
                  ),

                  // 7. SECURITY RISK DETECTION (MOVED DOWN & STRICTLY SHOWN ONLY AFTER SCAN COMPLETES!)
                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildSecurityRiskDetectionCard(theme),
                    ),
                    const SizedBox(height: 16),
                    // 8. CATEGORIZED DEEP FINDINGS (Issues / Junk / Largest / Unopened)
                    // All 4 tabs allow user Select, Select All & Permanent Delete!
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildScanResultsHub(theme),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 9. HARDWARE & OS INTEGRITY MATRIX
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildSystemIntegrityCard(theme),
                  ),

                  // 10. DEDICATED RECYCLE BIN / TRASH CLEANER AT THE BOTTOM
                  // STRICTLY SHOWN ONLY AFTER SCAN COMPLETES (NEVER BEFORE!)
                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildRecycleBinSection(theme),
                    ),
                  ],

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Screen Refresh Sweep Overlay (runs briefly during Master Clean & Finish)
          AnimatedBuilder(
            animation: _screenRefreshController,
            builder: (context, _) {
              final v = _screenRefreshController.value;
              if (!_screenRefreshController.isAnimating && v == 0.0) {
                return const SizedBox.shrink();
              }
              if (!_screenRefreshController.isAnimating) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ScreenRefreshSweepPainter(
                      progress: v,
                      primary: theme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. UNBOXED HERO RADIAL GAUGE + CIRCLE-BORDER RADIATING / CONTRACTING WAVES
  // ===========================================================================
  Widget _buildSecurityRadialBarCard(StationeryTheme theme, bool isScanning) {
    final bool isFinishActive =
        _isMasterCleaning || _finishWaveController.isAnimating;

    Color statusColor;
    if (isFinishActive) {
      statusColor = const Color(0xFFF43F5E);
    } else if (isScanning) {
      statusColor = const Color(0xFF06B6D4);
    } else if (_scannerMode == HoloScannerMode.threat) {
      statusColor = const Color(0xFFF43F5E);
    } else if (_scannerMode == HoloScannerMode.warning) {
      statusColor = const Color(0xFFF59E0B);
    } else if (_scannerMode == HoloScannerMode.clean) {
      statusColor = const Color(0xFF10B981);
    } else {
      statusColor = theme.primary;
    }

    final double barProgress = isScanning
        ? _scanProgress.clamp(0.02, 1.0)
        : (_scanState == _ScanState.completed
            ? ((_securityScore ?? 100) / 100.0).clamp(0.0, 1.0)
            : 0.0);

    final String statusBadge = isScanning
        ? 'SCANNING'
        : (isFinishActive
            ? 'FINISHING'
            : (_scannerMode == HoloScannerMode.threat
                ? 'THREATS FOUND'
                : (_scannerMode == HoloScannerMode.warning
                    ? 'READY TO CLEAN'
                    : (_scannerMode == HoloScannerMode.clean
                        ? 'VERIFIED SAFE'
                        : 'READY'))));

    return BouncyTap(
      onTap: _startOrStopScan,
      scaleFraction: 0.98,
      child: SizedBox(
        width: double.infinity,
        height: 304,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _waveFrameNotifier,
                  builder: (context, _, __) {
                    return CustomPaint(
                      key: const ValueKey('security_border_waves'),
                      painter: SecurityBorderWavePainter(
                        wavePhase: _wavePhase,
                        waveEnergy: _waveEnergy,
                        isScanning: isScanning,
                        isFinishMode: _isFinishWaveRed,
                        gaugeSize: 264.0,
                        theme: theme,
                        statusColor: statusColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            SmoothRadialGauge(
              size: 264,
              progress: barProgress,
              gaugeColor: statusColor,
              primaryColor: theme.primary,
              trackColor: theme.border.withValues(
                alpha: theme.isDark ? 0.45 : 0.65,
              ),
              smoothDamping: true,
              enableAutoPeakHold: true,
              center: Container(
                width: 158,
                height: 158,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.bg.withValues(alpha: 0.84),
                      theme.bg.withValues(alpha: 0.48),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.68, 1.0],
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    if (isScanning) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "${(barProgress * 100).toInt()}",
                            style: theme.fontDisplay(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            "%",
                            style: theme.fontMono(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _badgePill(statusBadge, statusColor, theme),
                      const SizedBox(height: 4),
                      Text(
                        "$_liveAppsScanned Apps • $_liveFilesScanned Files",
                        style: theme.fontMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                    ] else if (_scanState == _ScanState.completed) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "${_securityScore ?? 100}",
                            style: theme.fontDisplay(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            "/100",
                            style: theme.fontMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _badgePill(statusBadge, statusColor, theme),
                      const SizedBox(height: 4),
                      Text(
                        "$_liveAppsScanned Apps & $_liveFilesScanned Files",
                        style: theme.fontMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.shield_outlined, size: 46, color: statusColor),
                      const SizedBox(height: 6),
                      _badgePill("READY", statusColor, theme),
                      const SizedBox(height: 5),
                      Text(
                        "DEEP AUDIT",
                        style: theme.fontMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgePill(String text, Color statusColor, StationeryTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        style: theme.fontMono(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. PRIMARY ACTION BUTTON
  // ===========================================================================
  Widget _buildActionButton(StationeryTheme theme) {
    final isScanning = _scanState == _ScanState.scanning;
    final btnColor = isScanning
        ? const Color(0xFFF43F5E)
        : (_scannerMode == HoloScannerMode.clean
            ? const Color(0xFF10B981)
            : theme.primary);

    return BouncyTap(
      onTap: _startOrStopScan,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isScanning
                ? [const Color(0xFFF43F5E), const Color(0xFFE11D48)]
                : [
                    btnColor,
                    Color.lerp(btnColor, const Color(0xFF06B6D4), 0.32)!
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: btnColor.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isScanning
                    ? Icons.stop_circle_outlined
                    : (_scanState == _ScanState.completed
                        ? Icons.restart_alt_rounded
                        : Icons.radar_rounded),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                isScanning
                    ? 'STOP ACTIVE SCAN'
                    : (_scanState == _ScanState.completed
                        ? 'RUN FRESH DEEP SCAN'
                        : 'START REAL DEEP SCAN'),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. LIVE SCAN AUDIT PANEL (SHOWN STRICTLY WHILE SCANNING)
  // ===========================================================================
  Widget _buildLiveScanAuditPanel(StationeryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF06B6D4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE SCAN AUDIT',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: const Color(0xFF06B6D4),
                ),
              ),
              const Spacer(),
              Text(
                _currentStage,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniLiveCounter('APPS', '$_liveAppsScanned', theme.text, theme),
              _miniLiveCounter('FILES', '$_liveFilesScanned',
                  const Color(0xFF06B6D4), theme),
              _miniLiveCounter(
                'BG RAM',
                '$_liveBgAppsCount',
                const Color(0xFFA855F7),
                theme,
              ),
              _miniLiveCounter(
                'ISSUES',
                '$_liveIssuesCount',
                _liveIssuesCount > 0
                    ? const Color(0xFFF43F5E)
                    : const Color(0xFF10B981),
                theme,
              ),
              _miniLiveCounter(
                'JUNK',
                _formatBytes(_liveJunkBytes),
                const Color(0xFFF59E0B),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 164,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: _liveLogs.isEmpty
                ? Center(
                    child: Text(
                      'Initializing offline hardware, APIs & filesystem engine...',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        color: theme.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _liveLogs.length.clamp(0, 7),
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, idx) {
                      final log = _liveLogs[idx];
                      final color = log.severity == 'high'
                          ? const Color(0xFFF43F5E)
                          : (log.severity == 'medium'
                              ? const Color(0xFFF59E0B)
                              : (log.severity == 'ok'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF06B6D4)));
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.category.toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.target,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight:
                                    idx == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: idx == 0 ? theme.text : theme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniLiveCounter(
      String label, String value, Color valColor, StationeryTheme theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: valColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. DEVICE AUTHORITY BAR (Full Files / Usage / Notifications Access)
  // ===========================================================================
  Widget _buildAuthorityCard(StationeryTheme theme) {
    final grantedCount = (_hasAllFilesAccess ? 1 : 0) +
        (_hasUsageAccess ? 1 : 0) +
        (_hasNotificationAccess ? 1 : 0);
    final allGranted = grantedCount == 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allGranted
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : theme.border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allGranted
                    ? Icons.verified_user_rounded
                    : Icons.admin_panel_settings_rounded,
                size: 17,
                color: allGranted ? const Color(0xFF10B981) : theme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allGranted
                      ? 'FULL DEVICE AUTHORITY ACTIVE (OFFLINE + OS APIs)'
                      : 'DEVICE SCAN & CLEAN AUTHORITY ($grantedCount/3 GRANTED)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: allGranted
                        ? const Color(0xFF10B981)
                        : theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _authorityPill(
                  label: 'All Files',
                  granted: _hasAllFilesAccess,
                  onTap: _requestAllFilesAccess,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _authorityPill(
                  label: 'Active Apps',
                  granted: _hasUsageAccess,
                  onTap: _requestUsageAccess,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _authorityPill(
                  label: 'Notifications',
                  granted: _hasNotificationAccess,
                  onTap: _requestNotificationAccess,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _authorityPill({
    required String label,
    required bool granted,
    required VoidCallback onTap,
    required StationeryTheme theme,
  }) {
    final c = granted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: c.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              granted ? Icons.check_circle_rounded : Icons.lock_open_rounded,
              size: 13,
              color: c,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: granted ? c : theme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5A. READY TO CLEAN & FINISH (ONE-TAP DEEP CLEANER HUB)
  // ===========================================================================
  Widget _buildMasterCleanFinishHub(StationeryTheme theme) {
    final bgCount = _backgroundApps.length;
    final notifCount = _activeNotifications.length;
    final junkCount = _junkFiles.length;
    final threatCount = _fishyFiles.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cleaning_services_rounded,
                    color: theme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY TO CLEAN & FINISH',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: theme.primary,
                      ),
                    ),
                    Text(
                      'Kill BG apps, clear RAM, refresh screen, wipe alerts & junk in 1 click',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _cleanTargetChip(
                icon: Icons.memory_rounded,
                label: 'Active BG & RAM',
                value: '$bgCount apps',
                color: const Color(0xFFA855F7),
                theme: theme,
              ),
              _cleanTargetChip(
                icon: Icons.notifications_off_rounded,
                label: 'Notifications',
                value: '$notifCount active',
                color: const Color(0xFF0EA5E9),
                theme: theme,
              ),
              _cleanTargetChip(
                icon: Icons.delete_sweep_rounded,
                label: 'Deep Junk',
                value: '$junkCount (${_formatBytes(_totalJunkBytes)})',
                color: const Color(0xFFF59E0B),
                theme: theme,
              ),
              _cleanTargetChip(
                icon: Icons.bug_report_rounded,
                label: 'Risky Files',
                value: '$threatCount threats',
                color: const Color(0xFFF43F5E),
                theme: theme,
              ),
              _cleanTargetChip(
                icon: Icons.refresh_rounded,
                label: 'Screen Refresh',
                value: 'GPU & Frame Sync',
                color: const Color(0xFF10B981),
                theme: theme,
              ),
            ],
          ),
          if (_backgroundApps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'DETECTED ACTIVE & CACHED BACKGROUND APPS',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ..._backgroundApps.take(5).map((bg) {
              final appName = bg['appName'] as String? ?? 'App';
              final pkg = bg['packageName'] as String? ?? '';
              final isFgs = bg['isForegroundService'] == true;
              final memMb = (bg['estimatedRamMb'] as num?)?.toInt() ?? 0;
              final label = bg['statusLabel'] as String? ?? 'Running';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isFgs
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                        : theme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFgs ? Icons.bolt_rounded : Icons.apps_rounded,
                      size: 16,
                      color: isFgs
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFA855F7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.text,
                            ),
                          ),
                          Text(
                            '$label${memMb > 0 ? " • $memMb MB RAM" : ""}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFgs)
                      _smallActionChip(
                        label: 'STOP APP',
                        color: const Color(0xFFF59E0B),
                        onTap: () => _methodChannel.invokeMethod(
                            'openAppSettings', {'packageName': pkg}),
                      ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          BouncyTap(
            onTap: _isMasterCleaning ? null : _runMasterCleanAndFinish,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.34),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.done_all_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isMasterCleaning
                          ? 'CLEANING & REFRESHING...'
                          : 'CLEAN & FINISH ($_masterCleanableCount)',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cleanTargetChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required StationeryTheme theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5B. NOTHING ELSE LEFT / ALL CLEAN SWEET ANIMATED CARD
  // ===========================================================================
  Widget _buildNothingElseSweetCard(StationeryTheme theme) {
    return AnimatedBuilder(
      animation: _sweetAnimController,
      builder: (context, _) {
        final t = _sweetAnimController.value;
        final pulse = 0.94 + (math.sin(t * math.pi) * 0.08);
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.45),
              width: 1.4,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.10),
                theme.cardBg,
                const Color(0xFF06B6D4).withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Column(
            children: [
              Transform.scale(
                scale: pulse,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    painter: _SweetShieldSparklePainter(
                      progress: t,
                      primaryColor: const Color(0xFF10B981),
                      accentColor: const Color(0xFF06B6D4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'NOTHING ELSE TO CLEAN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _masterSweepDone
                    ? 'Device cleanup finished! $_lastKilledBgCount BG apps stopped, $_lastRamFreedMb MB RAM freed, $_lastNotifsCleared alerts cleared & display refreshed.'
                    : 'Nothing else found on this scan — background clutter, notifications, junk & resolved threats are already completely clean.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              if (_protectedFgsRemaining.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OS-PROTECTED ACTIVE APPS (${_protectedFgsRemaining.length})',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Android requires tapping Stop inside App Info for active foreground services:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _protectedFgsRemaining
                            .map(
                              (pkg) => _smallActionChip(
                                label: 'STOP ${pkg.split('.').last.toUpperCase()}',
                                color: const Color(0xFFF59E0B),
                                onTap: () => _methodChannel.invokeMethod(
                                    'openAppSettings', {'packageName': pkg}),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 6. REAL HARDWARE RAM & STORAGE TELEMETRY CARD
  // ===========================================================================
  Widget _buildHardwareTelemetryCard(StationeryTheme theme) {
    final ramUsedRatio = _totalRamMb > 0
        ? ((_totalRamMb - _availRamMb) / _totalRamMb).clamp(0.0, 1.0)
        : 0.0;
    final storageUsedRatio = _totalStorageBytes > 0
        ? (_usedStorageBytes / _totalStorageBytes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REAL HARDWARE TELEMETRY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: theme.textSecondary,
                ),
              ),
              if (_totalFreedBytesSession > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'FREED ${_formatBytes(_totalFreedBytesSession)} ($_totalDeletedCountSession)',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _telemetryGauge(
                  title: 'RAM FREE',
                  bigVal: _totalRamMb > 0
                      ? '${(_availRamMb / 1024.0).toStringAsFixed(1)} GB'
                      : '--',
                  subVal: _totalRamMb > 0
                      ? 'of ${(_totalRamMb / 1024.0).toStringAsFixed(0)} GB total'
                      : 'Reading hardware...',
                  ratio: ramUsedRatio,
                  color: const Color(0xFFA855F7),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _telemetryGauge(
                  title: 'STORAGE FREE',
                  bigVal: _totalStorageBytes > 0
                      ? _formatBytes(_availStorageBytes)
                      : '--',
                  subVal: _totalStorageBytes > 0
                      ? 'of ${_formatBytes(_totalStorageBytes)}'
                      : 'Reading StatFs...',
                  ratio: storageUsedRatio,
                  color: const Color(0xFF0EA5E9),
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _telemetryGauge({
    required String title,
    required String bigVal,
    required String subVal,
    required double ratio,
    required Color color,
    required StationeryTheme theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bigVal,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: theme.text,
            ),
          ),
          Text(
            subVal,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4.5,
              backgroundColor: theme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. SHIFTED SECURITY RISK DETECTION CARD (SHOWN STRICTLY AFTER SCAN COMPLETES!)
  // ===========================================================================
  Widget _buildSecurityRiskDetectionCard(StationeryTheme theme) {
    final mode = _scannerMode;
    final Color statusColor;
    final IconData icon;
    final String title;
    final String subtitle;

    if (mode == HoloScannerMode.threat) {
      statusColor = const Color(0xFFF43F5E);
      icon = Icons.gpp_bad_rounded;
      title = '$_totalIssues SECURITY RISKS DETECTED';
      subtitle = 'Review flagged apps, fishy files & system warnings below';
    } else if (_totalIssues > 0) {
      statusColor = const Color(0xFFF59E0B);
      icon = Icons.gpp_maybe_rounded;
      title = '$_totalIssues SECURITY RISKS DETECTED';
      subtitle =
          'Audited $_liveAppsScanned apps & $_liveFilesScanned files in ${(_scanDurationMs / 1000.0).toStringAsFixed(1)}s';
    } else if (_totalJunkBytes > 0 || _backgroundApps.isNotEmpty) {
      statusColor = const Color(0xFF06B6D4);
      icon = Icons.cleaning_services_rounded;
      title = 'SECURITY RISK DETECTION: 0 THREATS';
      subtitle =
          'System clean from malware — use Clean & Finish above for clutter';
    } else {
      statusColor = const Color(0xFF10B981);
      icon = Icons.verified_user_rounded;
      title = 'SECURITY RISK DETECTION: SAFE';
      subtitle =
          'Audited $_liveAppsScanned apps & $_liveFilesScanned real files • 0 risks';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.38), width: 1.3),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. CATEGORIZED REAL FINDINGS HUB (ISSUES / JUNK / LARGEST / UNOPENED)
  //    ALL 4 TABS SUPPORT INDIVIDUAL SELECT, SELECT ALL & PERMANENT DELETE
  // ===========================================================================
  Widget _buildScanResultsHub(StationeryTheme theme) {
    final tabs = [
      (
        'Issues',
        _totalIssues,
        _totalIssues > 0 ? const Color(0xFFF43F5E) : const Color(0xFF10B981)
      ),
      ('Junk', _junkFiles.length, const Color(0xFFF59E0B)),
      ('Largest', _largestFiles.length, const Color(0xFF0EA5E9)),
      ('Unopened', _unopenedFiles.length, const Color(0xFFA855F7)),
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = _selectedResultTab == i;
                final (label, count, badgeColor) = tabs[i];
                return Padding(
                  padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                  child: BouncyTap(
                    onTap: () {
                      SoundService().playTap();
                      setState(() => _selectedResultTab = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? badgeColor.withValues(alpha: 0.16)
                            : theme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? badgeColor : theme.border,
                          width: selected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? badgeColor : theme.text,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(
                                  alpha: selected ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          if (_selectedResultTab == 0) _buildIssuesTab(theme),
          if (_selectedResultTab == 1) _buildJunkTab(theme),
          if (_selectedResultTab == 2) _buildLargestFilesTab(theme),
          if (_selectedResultTab == 3) _buildUnopenedFilesTab(theme),
        ],
      ),
    );
  }

  List<String> _allIssueSelectionKeys() {
    final keys = <String>[];
    for (final a in _suspiciousApps) {
      final pkg = a['packageName'] as String? ?? '';
      if (pkg.isNotEmpty) keys.add('app:$pkg');
    }
    for (final f in _fishyFiles) {
      final path = f['path'] as String? ?? '';
      if (path.isNotEmpty) keys.add('file:$path');
    }
    for (final w in _systemWarnings) {
      final id = w['id'] as String? ?? '';
      if (id.isNotEmpty) keys.add('sys:$id');
    }
    return keys;
  }

  // --- TAB 0: ISSUES WITH SELECT / SELECT ALL / DELETE-RESOLVE ---
  Widget _buildIssuesTab(StationeryTheme theme) {
    if (_totalIssues == 0) {
      return _emptyStateCard(
        icon: Icons.verified_rounded,
        color: const Color(0xFF10B981),
        title: 'Zero Threats, Fishy Files or Warnings',
        subtitle:
            'Audited $_liveAppsScanned installed apps, file magic headers & kernel policies — everything looks clean.',
        theme: theme,
      );
    }

    final allKeys = _allIssueSelectionKeys();
    final allSelected =
        allKeys.isNotEmpty && _selectedIssueKeys.length == allKeys.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selectionHeaderBar(
          summary: '$_totalIssues ISSUES DETECTED',
          summaryColor: const Color(0xFFF43F5E),
          allSelected: allSelected,
          onToggleAll: () {
            SoundService().playTap();
            setState(() {
              if (allSelected) {
                _selectedIssueKeys.clear();
              } else {
                _selectedIssueKeys.addAll(allKeys);
              }
            });
          },
          theme: theme,
        ),
        const SizedBox(height: 8),
        BouncyTap(
          onTap: (_isCleaning || _selectedIssueKeys.isEmpty)
              ? null
              : _resolveSelectedIssues,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _selectedIssueKeys.isEmpty
                  ? theme.border
                  : const Color(0xFFF43F5E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _isCleaning
                    ? 'CLEANING ISSUES...'
                    : 'DELETE / RESOLVE ${_selectedIssueKeys.length} SELECTED',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_suspiciousApps.isNotEmpty) ...[
          _subSectionLabel(
              'SUSPICIOUS / HIGH-RISK APPS (${_suspiciousApps.length})',
              const Color(0xFFF43F5E)),
          const SizedBox(height: 8),
          ..._suspiciousApps.map((app) => _buildSuspiciousAppCard(app, theme)),
          const SizedBox(height: 12),
        ],
        if (_fishyFiles.isNotEmpty) ...[
          _subSectionLabel(
              'FISHY, SPOOFED & EXECUTABLE FILES (${_fishyFiles.length})',
              const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          ..._fishyFiles.map((file) => _buildFishyFileCard(file, theme)),
          const SizedBox(height: 12),
        ],
        if (_systemWarnings.isNotEmpty) ...[
          _subSectionLabel('SYSTEM & HARDWARE WARNINGS (${_systemWarnings.length})',
              const Color(0xFF0EA5E9)),
          const SizedBox(height: 8),
          ..._systemWarnings.map((w) => _buildSystemWarningCard(w, theme)),
        ],
      ],
    );
  }

  Widget _buildSuspiciousAppCard(
      Map<String, dynamic> app, StationeryTheme theme) {
    final name = app['name'] as String? ?? 'Unknown App';
    final pkg = app['packageName'] as String? ?? '';
    final sev = app['severity'] as String? ?? 'MEDIUM';
    final installer = app['installer'] as String? ?? 'Unknown';
    final reasons =
        (app['reasons'] as List? ?? []).map((e) => e.toString()).toList();
    final color =
        sev == 'HIGH' ? const Color(0xFFF43F5E) : const Color(0xFFF59E0B);
    final selKey = 'app:$pkg';
    final checked = _selectedIssueKeys.contains(selKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (checked) {
            _selectedIssueKeys.remove(selKey);
          } else {
            _selectedIssueKeys.add(selKey);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: checked ? color : color.withValues(alpha: 0.4),
              width: checked ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: checked ? color : theme.textSecondary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Icon(Icons.android_rounded, color: color, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.text,
                        ),
                      ),
                      Text(
                        '$pkg • Source: $installer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _severityPill(sev, color),
              ],
            ),
            const SizedBox(height: 8),
            ...reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $r',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _smallActionChip(
                  label: 'APP INFO',
                  color: theme.primary,
                  onTap: () => _methodChannel
                      .invokeMethod('openAppSettings', {'packageName': pkg}),
                ),
                const SizedBox(width: 8),
                _smallActionChip(
                  label: 'UNINSTALL',
                  color: const Color(0xFFF43F5E),
                  onTap: () => _methodChannel
                      .invokeMethod('uninstallApp', {'packageName': pkg}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFishyFileCard(Map<String, dynamic> file, StationeryTheme theme) {
    final name = file['name'] as String? ?? 'Unknown';
    final path = file['path'] as String? ?? '';
    final sev = file['severity'] as String? ?? 'MEDIUM';
    final threatType = file['threatType'] as String? ?? 'Suspicious File';
    final detail = file['detail'] as String? ?? '';
    final sizeBytes = (file['sizeBytes'] as num?)?.toInt() ?? 0;
    final color = sev == 'HIGH'
        ? const Color(0xFFF43F5E)
        : (sev == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF0EA5E9));
    final selKey = 'file:$path';
    final checked = _selectedIssueKeys.contains(selKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (checked) {
            _selectedIssueKeys.remove(selKey);
          } else {
            _selectedIssueKeys.add(selKey);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: checked ? color : color.withValues(alpha: 0.4),
              width: checked ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: checked ? color : theme.textSecondary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Icon(Icons.bug_report_rounded, color: color, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                ),
                _severityPill(sev, color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$threatType • ${_formatBytes(sizeBytes)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: theme.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _smallActionChip(
                  label: 'INSPECT SHA-256',
                  color: theme.primary,
                  onTap: () => _showFileInspectorSheet(file),
                ),
                const SizedBox(width: 8),
                _smallActionChip(
                  label: 'DELETE FILE',
                  color: const Color(0xFFF43F5E),
                  onTap: () => _deleteSingleFile(
                    path: path,
                    name: name,
                    isFishy: true,
                    isUnopened: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemWarningCard(
      Map<String, dynamic> w, StationeryTheme theme) {
    final id = w['id'] as String? ?? '';
    final title = w['title'] as String? ?? 'Warning';
    final detail = w['detail'] as String? ?? '';
    final sev = w['severity'] as String? ?? 'MEDIUM';
    final actionType = w['actionType'] as String? ?? 'info';
    final color = sev == 'HIGH'
        ? const Color(0xFFF43F5E)
        : (sev == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF0EA5E9));
    final selKey = 'sys:$id';
    final checked = _selectedIssueKeys.contains(selKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (checked) {
            _selectedIssueKeys.remove(selKey);
          } else {
            _selectedIssueKeys.add(selKey);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: checked ? color : color.withValues(alpha: 0.35),
              width: checked ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: checked ? color : theme.textSecondary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Icon(Icons.shield_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                ),
                _severityPill(sev, color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: theme.textSecondary),
            ),
            if (actionType != 'info') ...[
              const SizedBox(height: 8),
              _smallActionChip(
                label: 'OPEN SYSTEM SETTINGS',
                color: color,
                onTap: () => _methodChannel
                    .invokeMethod('openSystemSetting', {'type': actionType}),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 1: JUNK FILES WITH SELECT / SELECT ALL / PERMANENT DELETE ---
  Widget _buildJunkTab(StationeryTheme theme) {
    if (_junkFiles.isEmpty) {
      return _emptyStateCard(
        icon: Icons.cleaning_services_rounded,
        color: const Color(0xFF10B981),
        title: 'Zero Junk or Residual Cache Found',
        subtitle:
            'App caches, .tmp/.log/.bak files & zero-byte orphans are completely clean.',
        theme: theme,
      );
    }

    final allSelected = _selectedJunkPaths.length == _junkFiles.length;
    final visibleItems = _showAllJunk ? _junkFiles : _junkFiles.take(40).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selectionHeaderBar(
          summary:
              '${_junkFiles.length} CLEANABLE • ${_formatBytes(_totalJunkBytes)}',
          summaryColor: const Color(0xFFF59E0B),
          allSelected: allSelected,
          onToggleAll: () {
            SoundService().playTap();
            setState(() {
              if (allSelected) {
                _selectedJunkPaths.clear();
              } else {
                _selectedJunkPaths.addAll(_junkFiles
                    .map((e) => e['path'] as String? ?? '')
                    .where((p) => p.isNotEmpty));
              }
            });
          },
          theme: theme,
        ),
        const SizedBox(height: 10),
        BouncyTap(
          onTap: (_isCleaning || _selectedJunkPaths.isEmpty)
              ? null
              : () => _deleteFileBatch(
                    selectedPaths: _selectedJunkPaths,
                    sourceList: _junkFiles,
                    itemLabel: 'junk files',
                    requireConfirm: false,
                  ),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _selectedJunkPaths.isEmpty
                  ? theme.border
                  : const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _isCleaning
                    ? 'DELETING PERMANENTLY...'
                    : 'DELETE ${_selectedJunkPaths.length} SELECTED (${_formatBytes(_selectedJunkBytes)})',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...visibleItems.map((f) {
          final path = f['path'] as String? ?? '';
          final name = f['name'] as String? ?? '';
          final cat = f['category'] as String? ?? 'Junk';
          final folder = f['folder'] as String? ?? '';
          final size = (f['sizeBytes'] as num?)?.toInt() ?? 0;
          final checked = _selectedJunkPaths.contains(path);

          return InkWell(
            onTap: () {
              setState(() {
                if (checked) {
                  _selectedJunkPaths.remove(path);
                } else {
                  _selectedJunkPaths.add(path);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: checked
                      ? const Color(0xFF10B981).withValues(alpha: 0.45)
                      : theme.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: checked
                        ? const Color(0xFF10B981)
                        : theme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          '$cat • /$folder',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatBytes(size),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (!_showAllJunk && _junkFiles.length > 40)
          TextButton(
            onPressed: () => setState(() => _showAllJunk = true),
            child: Text(
              'SHOW ALL ${_junkFiles.length} JUNK FILES',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: theme.primary,
              ),
            ),
          ),
      ],
    );
  }

  // --- TAB 2: LARGEST STORAGE FILES WITH SELECT, SELECT ALL & PERMANENT DELETE ---
  Widget _buildLargestFilesTab(StationeryTheme theme) {
    if (_largestFiles.isEmpty) {
      return _emptyStateCard(
        icon: Icons.storage_rounded,
        color: const Color(0xFF0EA5E9),
        title: _hasAllFilesAccess
            ? 'No Files Over 1 MB Found'
            : 'Allow Deep Storage Access to See Largest Files',
        subtitle: _hasAllFilesAccess
            ? 'Your scanned folders contain no large files above 1 MB.'
            : 'Tap All Files above so Tooler can scan and let you manage your heaviest files.',
        theme: theme,
      );
    }

    final maxBytes =
        ((_largestFiles.first['sizeBytes'] as num?)?.toInt() ?? 1).clamp(1, 1 << 60);
    final allSelected = _selectedLargestPaths.length == _largestFiles.length;
    final totalLargestBytes = _largestFiles.fold<int>(
        0, (s, e) => s + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selectionHeaderBar(
          summary:
              '${_largestFiles.length} LARGE FILES • ${_formatBytes(totalLargestBytes)}',
          summaryColor: const Color(0xFF0EA5E9),
          allSelected: allSelected,
          onToggleAll: () {
            SoundService().playTap();
            setState(() {
              if (allSelected) {
                _selectedLargestPaths.clear();
              } else {
                _selectedLargestPaths.addAll(_largestFiles
                    .map((e) => e['path'] as String? ?? '')
                    .where((p) => p.isNotEmpty));
              }
            });
          },
          theme: theme,
        ),
        const SizedBox(height: 10),
        BouncyTap(
          onTap: (_isCleaning || _selectedLargestPaths.isEmpty)
              ? null
              : () => _deleteFileBatch(
                    selectedPaths: _selectedLargestPaths,
                    sourceList: _largestFiles,
                    itemLabel: 'large files',
                    requireConfirm: true,
                  ),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _selectedLargestPaths.isEmpty
                  ? theme.border
                  : const Color(0xFFF43F5E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _isCleaning
                    ? 'DELETING PERMANENTLY...'
                    : 'DELETE ${_selectedLargestPaths.length} SELECTED (${_formatBytes(_selectedLargestBytes)})',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ..._largestFiles.map((file) {
          final name = file['name'] as String? ?? '';
          final path = file['path'] as String? ?? '';
          final folder = file['folder'] as String? ?? 'Storage';
          final ext = file['extension'] as String? ?? 'FILE';
          final size = (file['sizeBytes'] as num?)?.toInt() ?? 0;
          final ratio = (size / maxBytes).clamp(0.06, 1.0);
          final checked = _selectedLargestPaths.contains(path);

          return InkWell(
            onTap: () {
              setState(() {
                if (checked) {
                  _selectedLargestPaths.remove(path);
                } else {
                  _selectedLargestPaths.add(path);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: checked
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.65)
                      : theme.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        checked
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: checked
                            ? const Color(0xFF0EA5E9)
                            : theme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ext.length > 5 ? ext.substring(0, 5) : ext,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.text,
                              ),
                            ),
                            Text(
                              '/$folder',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatBytes(size),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0EA5E9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => _showFileInspectorSheet(file),
                            child: Text(
                              'INSPECT',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 3.5,
                      backgroundColor: theme.border,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF0EA5E9)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- TAB 3: UNOPENED FILES WITH SELECT, SELECT ALL & PERMANENT DELETE ---
  Widget _buildUnopenedFilesTab(StationeryTheme theme) {
    if (_unopenedFiles.isEmpty) {
      return _emptyStateCard(
        icon: Icons.mark_email_unread_outlined,
        color: const Color(0xFFA855F7),
        title: _hasAllFilesAccess
            ? 'No Unopened Forgotten Files Found'
            : 'Allow Deep Storage Access for Unopened Files',
        subtitle: _hasAllFilesAccess
            ? 'All your documents & downloads appear to have been opened recently.'
            : 'Enable All Files Access to detect files downloaded/saved that you never opened.',
        theme: theme,
      );
    }

    final allSelected = _selectedUnopenedPaths.length == _unopenedFiles.length;
    final totalUnopenedBytes = _unopenedFiles.fold<int>(
        0, (s, e) => s + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _selectionHeaderBar(
          summary:
              '${_unopenedFiles.length} UNOPENED • ${_formatBytes(totalUnopenedBytes)}',
          summaryColor: const Color(0xFFA855F7),
          allSelected: allSelected,
          onToggleAll: () {
            SoundService().playTap();
            setState(() {
              if (allSelected) {
                _selectedUnopenedPaths.clear();
              } else {
                _selectedUnopenedPaths.addAll(_unopenedFiles
                    .map((e) => e['path'] as String? ?? '')
                    .where((p) => p.isNotEmpty));
              }
            });
          },
          theme: theme,
        ),
        const SizedBox(height: 10),
        BouncyTap(
          onTap: (_isCleaning || _selectedUnopenedPaths.isEmpty)
              ? null
              : () => _deleteFileBatch(
                    selectedPaths: _selectedUnopenedPaths,
                    sourceList: _unopenedFiles,
                    itemLabel: 'unopened files',
                    requireConfirm: true,
                  ),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _selectedUnopenedPaths.isEmpty
                  ? theme.border
                  : const Color(0xFFF43F5E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _isCleaning
                    ? 'DELETING PERMANENTLY...'
                    : 'DELETE ${_selectedUnopenedPaths.length} SELECTED (${_formatBytes(_selectedUnopenedBytes)})',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ..._unopenedFiles.map((file) {
          final name = file['name'] as String? ?? '';
          final path = file['path'] as String? ?? '';
          final folder = file['folder'] as String? ?? 'Storage';
          final size = (file['sizeBytes'] as num?)?.toInt() ?? 0;
          final ageDays = (file['ageDays'] as num?)?.toInt() ?? 1;
          final badge = file['statusLabel'] as String? ?? 'Never Opened';
          final neverOpened = file['neverOpened'] as bool? ?? true;
          final accent =
              neverOpened ? const Color(0xFFA855F7) : const Color(0xFFF59E0B);
          final checked = _selectedUnopenedPaths.contains(path);

          return InkWell(
            onTap: () {
              setState(() {
                if (checked) {
                  _selectedUnopenedPaths.remove(path);
                } else {
                  _selectedUnopenedPaths.add(path);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: checked ? accent.withValues(alpha: 0.65) : theme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: checked ? accent : theme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.drafts_outlined, color: accent, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                badge.toUpperCase(),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '/$folder • ${ageDays}d old',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatBytes(size),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () => _deleteSingleFile(
                          path: path,
                          name: name,
                          isFishy: false,
                          isUnopened: true,
                        ),
                        child: Text(
                          'DELETE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF43F5E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _selectionHeaderBar({
    required String summary,
    required Color summaryColor,
    required bool allSelected,
    required VoidCallback onToggleAll,
    required StationeryTheme theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          summary,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: summaryColor,
          ),
        ),
        GestureDetector(
          onTap: onToggleAll,
          child: Text(
            allSelected ? 'DESELECT ALL' : 'SELECT ALL',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: theme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 9. REAL HARDWARE & FIRMWARE INTEGRITY MATRIX
  // ===========================================================================
  Widget _buildSystemIntegrityCard(StationeryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory_rounded, size: 16, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                'HARDWARE & OS SECURITY MATRIX',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _specRow(
              'Operating System', '$_androidVersion (API $_sdkInt)', theme),
          _specRow('Security Patch', _securityPatch, theme),
          _specRow('Kernel Version', _kernelVersion, theme),
          _specRow(
            'SELinux Policy',
            _selinuxState,
            theme,
            highlight: _selinuxState.contains('Permissive')
                ? const Color(0xFFF43F5E)
                : const Color(0xFF10B981),
          ),
          _specRow(
            'Root / SU Status',
            _isRooted ? 'Detected (Risk)' : 'Clean (Unrooted)',
            theme,
            highlight: _isRooted
                ? const Color(0xFFF43F5E)
                : const Color(0xFF10B981),
          ),
          _specRow(
            'Screen Lock Guard',
            _isDeviceSecure ? 'Protected' : 'Unsecured',
            theme,
            highlight: _isDeviceSecure
                ? const Color(0xFF10B981)
                : const Color(0xFFF43F5E),
          ),
          _specRow(
            'USB Debugging (ADB)',
            _isAdbEnabled ? 'Enabled (Open)' : 'Closed',
            theme,
            highlight: _isAdbEnabled
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981),
          ),
          _specRow(
              'Developer Options', _isDevMode ? 'Enabled' : 'Disabled', theme),
          _specRow(
            'Network / Proxy',
            _hasHttpProxy
                ? 'HTTP Proxy Active'
                : '$_networkType${_isVpnActive ? " • VPN" : ""}',
            theme,
            highlight: _hasHttpProxy ? const Color(0xFFF59E0B) : null,
          ),
          _specRow('Hardware Identity', _device, theme),
        ],
      ),
    );
  }

  // ===========================================================================
  // 10. DEDICATED BOTTOM RECYCLE BIN & TRASH CLEANER
  //     STRICTLY SHOWN ONLY AFTER SCAN COMPLETES (NEVER BEFORE!)
  // ===========================================================================
  Widget _buildRecycleBinSection(StationeryTheme theme) {
    final allSelected =
        _trashFiles.isNotEmpty && _selectedTrashIds.length == _trashFiles.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _trashFiles.isEmpty
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : const Color(0xFFF43F5E).withValues(alpha: 0.45),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_trashFiles.isEmpty
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF43F5E))
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  size: 20,
                  color: _trashFiles.isEmpty
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF43F5E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECYCLE BIN & TRASH CLEANER',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _trashFiles.isEmpty
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF43F5E),
                      ),
                    ),
                    Text(
                      _trashFiles.isEmpty
                          ? 'Files Trash & MediaStore Recycle Bin are empty'
                          : '${_trashFiles.length} trashed files • ${_formatBytes(_totalTrashBytes)} waiting to erase',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_trashFiles.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    'RECYCLE BIN IS COMPLETELY CLEAN',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            _selectionHeaderBar(
              summary:
                  '${_trashFiles.length} TRASHED FILES • ${_formatBytes(_totalTrashBytes)}',
              summaryColor: const Color(0xFFF43F5E),
              allSelected: allSelected,
              onToggleAll: () {
                SoundService().playTap();
                setState(() {
                  if (allSelected) {
                    _selectedTrashIds.clear();
                  } else {
                    _selectedTrashIds.addAll(_trashFiles
                        .map((e) => e['id']?.toString() ?? '')
                        .where((id) => id.isNotEmpty));
                  }
                });
              },
              theme: theme,
            ),
            const SizedBox(height: 8),
            ..._trashFiles.take(15).map((item) {
              final id = item['id']?.toString() ?? '';
              final name = item['name'] as String? ?? 'Trashed file';
              final source = item['source'] as String? ?? 'Trash';
              final size = (item['sizeBytes'] as num?)?.toInt() ?? 0;
              final checked = _selectedTrashIds.contains(id);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (checked) {
                      _selectedTrashIds.remove(id);
                    } else {
                      _selectedTrashIds.add(id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: checked
                          ? const Color(0xFFF43F5E).withValues(alpha: 0.45)
                          : theme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        checked
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        color: checked
                            ? const Color(0xFFF43F5E)
                            : theme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: theme.text,
                              ),
                            ),
                            Text(
                              source,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatBytes(size),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF43F5E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            BouncyTap(
              onTap: (_isTrashCleaning || _selectedTrashIds.isEmpty)
                  ? null
                  : _cleanSelectedRecycleBin,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _selectedTrashIds.isEmpty
                      ? theme.border
                      : const Color(0xFFF43F5E),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    _isTrashCleaning
                        ? 'EMPTYING RECYCLE BIN...'
                        : 'CLEAN RECYCLE BIN (${_selectedTrashIds.length} • ${_formatBytes(_selectedTrashBytes)})',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, StationeryTheme theme,
      {Color? highlight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: highlight ?? theme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subSectionLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }

  Widget _severityPill(String sev, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        sev,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _smallActionChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _emptyStateCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required StationeryTheme theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024.0).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024.0 * 1024.0)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024.0 * 1024.0 * 1024.0)).toStringAsFixed(2)} GB';
  }

  String _formatDate(int epochMs) {
    if (epochMs <= 0) return 'Unknown';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d $hh:$mm';
  }
}

/// Animated sweet emerald shield + orbiting stars painter displayed when
/// there is nothing left to clean.
class _SweetShieldSparklePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  const _SweetShieldSparklePainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;

    // Soft pulsing aura halo
    canvas.drawCircle(
      center,
      radius * (1.18 + progress * 0.14),
      Paint()
        ..color = primaryColor.withValues(alpha: 0.14 * (1.0 - progress * 0.4))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Shield contour path
    final shield = Path()
      ..moveTo(center.dx, center.dy - radius * 0.92)
      ..quadraticBezierTo(center.dx + radius * 0.78, center.dy - radius * 0.72,
          center.dx + radius * 0.78, center.dy - radius * 0.18)
      ..quadraticBezierTo(center.dx + radius * 0.74, center.dy + radius * 0.56,
          center.dx, center.dy + radius * 0.96)
      ..quadraticBezierTo(center.dx - radius * 0.74, center.dy + radius * 0.56,
          center.dx - radius * 0.78, center.dy - radius * 0.18)
      ..quadraticBezierTo(center.dx - radius * 0.78, center.dy - radius * 0.72,
          center.dx, center.dy - radius * 0.92)
      ..close();

    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.25),
            accentColor.withValues(alpha: 0.18),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      shield,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );

    // Crisp check stroke inside shield
    final check = Path()
      ..moveTo(center.dx - radius * 0.30, center.dy + radius * 0.02)
      ..lineTo(center.dx - radius * 0.06, center.dy + radius * 0.28)
      ..lineTo(center.dx + radius * 0.34, center.dy - radius * 0.24);
    canvas.drawPath(
      check,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Sweet floating 4-point sparkles
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + (progress * 0.7);
      final dist = radius * 1.15;
      final p = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );
      final r = (i.isEven ? 3.5 : 2.5) * (0.75 + 0.35 * math.sin(progress * math.pi + i));
      final sparkColor = i.isEven ? primaryColor : accentColor;
      canvas.drawCircle(p, r, Paint()..color = sparkColor.withValues(alpha: 0.85));
    }
  }

  @override
  bool shouldRepaint(covariant _SweetShieldSparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Luminous screen-refresh sweep wave rendered during Master Clean & Finish.
class _ScreenRefreshSweepPainter extends CustomPainter {
  final double progress;
  final Color primary;

  const _ScreenRefreshSweepPainter({
    required this.progress,
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    const bandHeight = 140.0;
    final rect = Rect.fromLTWH(0, y - bandHeight / 2, size.width, bandHeight);
    final fade = math.sin(progress * math.pi).clamp(0.0, 1.0);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF06B6D4).withValues(alpha: 0.20 * fade),
            primary.withValues(alpha: 0.24 * fade),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ScreenRefreshSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Circle-Border Radial & Contracting Wave Painter for Security Scanner.
/// Emits harmonic waves surging outward AND inward directly from the circular
/// gauge border — active strictly during Deep Scan (multi-color) and Finish (red).
class SecurityBorderWavePainter extends CustomPainter {
  final double wavePhase;
  final double waveEnergy;
  final bool isScanning;
  final bool isFinishMode;
  final double gaugeSize;
  final StationeryTheme theme;
  final Color statusColor;

  const SecurityBorderWavePainter({
    required this.wavePhase,
    required this.waveEnergy,
    required this.isScanning,
    required this.isFinishMode,
    required this.gaugeSize,
    required this.theme,
    required this.statusColor,
  });

  List<Color> _activePalette() {
    if (isFinishMode) {
      return const [
        Color(0xFFEF4444), // Red
        Color(0xFFF43F5E), // Crimson Rose
        Color(0xFFDC2626), // Deep Red
        Color(0xFFFB7185), // Bright Coral Red
        Color(0xFFE11D48), // Ruby Red
        Color(0xFFEF4444),
      ];
    }
    return [
      theme.primary,
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFA855F7), // Lilac Violet
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Warm Amber
      const Color(0xFF0EA5E9), // Sky Blue
      const Color(0xFFFB7185), // Blush Rose
      theme.primary,
    ];
  }

  List<Color> _rotatedPalette(List<Color> base, int shift) {
    final core = base.sublist(0, base.length - 1);
    final rotated = List<Color>.generate(
      core.length,
      (idx) => core[(idx + shift) % core.length],
    );
    rotated.add(rotated.first);
    return rotated;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (waveEnergy <= 0.004) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double borderR = (gaugeSize / 2.0) - 18.0; // Exact ring border radius
    final double maxRadius = (size.height / 2.0) - 4.0;
    final List<Color> palette = _activePalette();
    final bool isDark = theme.isDark;
    const double twoPi = math.pi * 2.0;
    const int segs = 144;
    const int strandCount = 4;

    // 1. Bidirectional Border Pulse Ripples (2 expanding outward, 2 pulling inward)
    const int pulseCount = 4;
    for (int p = 0; p < pulseCount; p++) {
      final bool isOutward = p.isEven;
      final double t = ((wavePhase * 0.22) + (p / pulseCount)) % 1.0;
      final double fade = math.sin(t * math.pi).clamp(0.0, 1.0) * waveEnergy;
      if (fade <= 0.01) continue;

      final double travel = t * (isOutward ? 32.0 : 34.0) * waveEnergy;
      final double baseR = isOutward ? (borderR + travel) : (borderR - travel);
      final double clampedBaseR = baseR.clamp(56.0, maxRadius - 4.0);

      final Path ripple = Path();
      final double rippleAmp = (3.5 + (p % 2) * 1.5) * (1.0 - t * 0.45);
      for (int s = 0; s <= 96; s++) {
        final double theta = (s / 96) * twoPi;
        final double wobble =
            math.sin(theta * (6 + p) + wavePhase * (isOutward ? 1.5 : -1.5)) *
                rippleAmp;
        final double r = (clampedBaseR + wobble).clamp(52.0, maxRadius);
        final Offset pt = Offset(
          center.dx + r * math.cos(theta),
          center.dy + r * math.sin(theta),
        );
        if (s == 0) {
          ripple.moveTo(pt.dx, pt.dy);
        } else {
          ripple.lineTo(pt.dx, pt.dy);
        }
      }
      ripple.close();

      final List<Color> ringColors = _rotatedPalette(palette, p)
          .map((c) => c.withValues(alpha: (isDark ? 0.42 : 0.34) * fade))
          .toList();

      final Rect shaderBounds =
          Rect.fromCircle(center: center, radius: borderR + 36.0);

      canvas.drawPath(
        ripple,
        Paint()
          ..shader = SweepGradient(
            colors: ringColors,
            transform: GradientRotation(wavePhase * (isOutward ? 0.35 : -0.35)),
          ).createShader(shaderBounds)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 - (t * 1.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }

    // 2. Undulating Closed Circle-Border Waves (crossing outside <-> inside border)
    final Rect shaderBounds =
        Rect.fromCircle(center: center, radius: borderR + 36.0);

    for (int i = 0; i < strandCount; i++) {
      final Path path = Path();
      final double dir1 = i.isEven ? 1.0 : -1.0;
      final double dir2 = i.isEven ? -0.78 : 0.85;
      final double amp = (17.0 + (i % 2) * 7.0) * waveEnergy;
      final double surge =
          math.sin(wavePhase * 1.45 + i * 1.25) * 10.5 * waveEnergy;

      for (int s = 0; s <= segs; s++) {
        final double theta = (s / segs) * twoPi;
        final double w1 =
            math.sin(theta * (5 + i) + wavePhase * dir1 * (0.95 + i * 0.12));
        final double w2 =
            math.cos(theta * (8 - i) + wavePhase * dir2 + i * 1.4);
        final double delta = (w1 * 0.62 + w2 * 0.38) * amp + surge;
        final double r = (borderR + delta).clamp(58.0, maxRadius);
        final Offset pt = Offset(
          center.dx + r * math.cos(theta),
          center.dy + r * math.sin(theta),
        );
        if (s == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();

      final double bloomAlpha = (isDark ? 0.34 : 0.25) * waveEnergy;
      final double coreAlpha = (isDark ? 0.72 : 0.62) * waveEnergy;
      final List<Color> strandPalette = _rotatedPalette(palette, i * 2);

      final Shader bloomShader = SweepGradient(
        colors: strandPalette
            .map((c) => c.withValues(alpha: bloomAlpha))
            .toList(),
        transform: GradientRotation(wavePhase * 0.25 * dir1),
      ).createShader(shaderBounds);

      canvas.drawPath(
        path,
        Paint()
          ..shader = bloomShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5),
      );

      final Shader coreShader = SweepGradient(
        colors:
            strandPalette.map((c) => c.withValues(alpha: coreAlpha)).toList(),
        transform: GradientRotation(wavePhase * 0.25 * dir1),
      ).createShader(shaderBounds);

      canvas.drawPath(
        path,
        Paint()
          ..shader = coreShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = i < 2 ? 2.1 : 1.5,
      );
    }

    // 3. Crest Energy Motes orbiting across outer & inner wave peaks
    const int moteCount = 10;
    for (int k = 0; k < moteCount; k++) {
      final int strandIdx = k % strandCount;
      final double dir1 = strandIdx.isEven ? 1.0 : -1.0;
      final double dir2 = strandIdx.isEven ? -0.78 : 0.85;
      final double amp = (17.0 + (strandIdx % 2) * 7.0) * waveEnergy;
      final double surge =
          math.sin(wavePhase * 1.45 + strandIdx * 1.25) * 10.5 * waveEnergy;

      final double theta =
          ((wavePhase * (0.28 + (k % 3) * 0.08) * dir1) +
                  (k * twoPi / moteCount)) %
              twoPi;
      final double w1 = math.sin(
          theta * (5 + strandIdx) + wavePhase * dir1 * (0.95 + strandIdx * 0.12));
      final double w2 =
          math.cos(theta * (8 - strandIdx) + wavePhase * dir2 + strandIdx * 1.4);
      final double r =
          (borderR + ((w1 * 0.62 + w2 * 0.38) * amp + surge)).clamp(58.0, maxRadius);
      final Offset pos = Offset(
        center.dx + r * math.cos(theta),
        center.dy + r * math.sin(theta),
      );

      final Color moteColor = palette[k % (palette.length - 1)];
      final double mAlpha = (0.55 + 0.35 * math.sin(wavePhase * 2 + k)) * waveEnergy;
      final double dotR = 1.7 + (k % 2) * 0.6;

      canvas.drawCircle(
        pos,
        dotR * 2.5,
        Paint()
          ..color = moteColor.withValues(alpha: mAlpha * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
      canvas.drawCircle(
        pos,
        dotR,
        Paint()
          ..color = Color.lerp(moteColor, Colors.white, isDark ? 0.35 : 0.15)!
              .withValues(alpha: mAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SecurityBorderWavePainter oldDelegate) =>
      oldDelegate.wavePhase != wavePhase ||
      (oldDelegate.waveEnergy - waveEnergy).abs() > 0.002 ||
      oldDelegate.isScanning != isScanning ||
      oldDelegate.isFinishMode != isFinishMode ||
      oldDelegate.gaugeSize != gaugeSize ||
      oldDelegate.statusColor != statusColor ||
      oldDelegate.theme.isDark != theme.isDark ||
      oldDelegate.theme.primary != theme.primary;
}
