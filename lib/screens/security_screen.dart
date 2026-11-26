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
/// TOOLER REAL HARDWARE & SOFTWARE DEEP SECURITY AUDIT SCREEN
/// - 100% genuine native Android backend via ToolerSecurityEngine (Kotlin)
/// - Out-of-this-world True-3D Holographic Scanner & Volumetric 3D Waves
/// - Live Scan Audit stream shown STRICTLY while scan is active
/// - Actionable Threat/Fishy/App/System findings & user-controlled Junk Clean
/// - Largest Storage Files viewer (Protected — display only, never deleted)
/// - Unopened / Untouched Files detector via real POSIX Os.lstat() timestamps
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
  double _waveEnergy = 0.58;

  _ScanState _scanState = _ScanState.idle;
  double _scanProgress = 0.0;
  String _currentStage = 'READY';
  int? _securityScore;
  int _selectedResultTab = 0; // 0=Issues, 1=Junk, 2=Largest, 3=Unopened

  // Real Hardware & OS Telemetry
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

  int _totalRamMb = 0;
  int _availRamMb = 0;
  int _totalStorageBytes = 0;
  int _availStorageBytes = 0;
  int _usedStorageBytes = 0;

  // Live scan counters (streaming real counts)
  int _liveAppsScanned = 0;
  int _liveFilesScanned = 0;
  int _liveIssuesCount = 0;
  int _liveJunkBytes = 0;
  final List<_LiveAuditLog> _liveLogs = [];

  // Real Scan Results
  int _scanDurationMs = 0;
  List<Map<String, dynamic>> _systemWarnings = [];
  List<Map<String, dynamic>> _suspiciousApps = [];
  List<Map<String, dynamic>> _fishyFiles = [];
  List<Map<String, dynamic>> _junkFiles = [];
  List<Map<String, dynamic>> _largestFiles = [];
  List<Map<String, dynamic>> _unopenedFiles = [];

  // Junk selection & cleaning feedback
  final Set<String> _selectedJunkPaths = {};
  bool _isCleaning = false;
  int _totalFreedBytesSession = 0;
  int _totalDeletedCountSession = 0;

  @override
  void initState() {
    super.initState();
    _waveTicker = createTicker((elapsed) {
      if (!mounted) return;
      double dt = 0.016;
      if (_lastWaveElapsed != Duration.zero && elapsed > _lastWaveElapsed) {
        dt = ((elapsed - _lastWaveElapsed).inMicroseconds / 1000000.0)
            .clamp(0.001, 0.05);
      }
      _lastWaveElapsed = elapsed;

      final bool isScanning = _scanState == _ScanState.scanning;
      final double targetEnergy = isScanning ? 1.0 : 0.58;
      final double factor = 1.0 - math.exp(-4.5 * dt);
      _waveEnergy += (targetEnergy - _waveEnergy) * factor;

      final double angularSpeed = 1.35 + (_waveEnergy * 1.95);
      _wavePhase = (_wavePhase + angularSpeed * dt) % (math.pi * 200.0);
      _waveFrameNotifier.value++;
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
            _scanProgress = (map['progress'] as num?)?.toDouble() ?? _scanProgress;
            _currentStage = map['stage'] as String? ?? 'SCANNING';
            _liveAppsScanned = (map['appsScanned'] as num?)?.toInt() ?? _liveAppsScanned;
            _liveFilesScanned = (map['filesScanned'] as num?)?.toInt() ?? _liveFilesScanned;
            _liveIssuesCount = (map['issuesCount'] as num?)?.toInt() ?? _liveIssuesCount;
            _liveJunkBytes = (map['junkBytes'] as num?)?.toInt() ?? _liveJunkBytes;

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

          SoundService().playSuccess();
          setState(() {
            _scanState = _ScanState.completed;
            _scanProgress = 1.0;
            _securityScore = (map['securityScore'] as num?)?.toInt() ?? 100;
            _scanDurationMs = (map['durationMs'] as num?)?.toInt() ?? 0;
            _liveAppsScanned = (map['appsScanned'] as num?)?.toInt() ?? _liveAppsScanned;
            _liveFilesScanned = (map['filesScanned'] as num?)?.toInt() ?? _liveFilesScanned;
            _hasAllFilesAccess = map['hasAllFilesAccess'] as bool? ?? _hasAllFilesAccess;

            _systemWarnings = warnings;
            _suspiciousApps = apps;
            _fishyFiles = fishy;
            _junkFiles = junk;
            _largestFiles = largest;
            _unopenedFiles = unopened;

            // Pre-select all detected junk for easy 1-tap clean (never largest/unopened!)
            _selectedJunkPaths
              ..clear()
              ..addAll(junk.map((e) => e['path'] as String? ?? '').where((p) => p.isNotEmpty));

            // Clear live logs since Live Scan Audit hides after scan
            _liveLogs.clear();

            // Auto-focus the most relevant tab
            final issueCount = warnings.length + apps.length + fishy.length;
            if (issueCount > 0) {
              _selectedResultTab = 0;
            } else if (junk.isNotEmpty) {
              _selectedResultTab = 1;
            } else if (largest.isNotEmpty) {
              _selectedResultTab = 2;
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
    _hasAllFilesAccess = res['hasAllFilesAccess'] as bool? ?? _hasAllFilesAccess;
    _totalRamMb = (res['totalRamMb'] as num?)?.toInt() ?? _totalRamMb;
    _availRamMb = (res['availRamMb'] as num?)?.toInt() ?? _availRamMb;
    _totalStorageBytes = (res['totalStorageBytes'] as num?)?.toInt() ?? _totalStorageBytes;
    _availStorageBytes = (res['availStorageBytes'] as num?)?.toInt() ?? _availStorageBytes;
    _usedStorageBytes = (res['usedStorageBytes'] as num?)?.toInt() ?? _usedStorageBytes;
  }

  Future<void> _startOrStopScan() async {
    if (_scanState == _ScanState.scanning) {
      SoundService().playTap();
      await _methodChannel.invokeMethod('cancelScan');
      setState(() {
        _scanState = _ScanState.idle;
        _liveLogs.clear();
      });
      return;
    }

    SoundService().playClick();
    setState(() {
      _scanState = _ScanState.scanning;
      _scanProgress = 0.02;
      _currentStage = 'INITIALIZING';
      _liveAppsScanned = 0;
      _liveFilesScanned = 0;
      _liveIssuesCount = 0;
      _liveJunkBytes = 0;
      _liveLogs.clear();
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

  Future<void> _cleanSelectedJunk() async {
    if (_isCleaning || _selectedJunkPaths.isEmpty) return;
    SoundService().playClick();
    setState(() => _isCleaning = true);

    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'deleteFiles',
        {'paths': _selectedJunkPaths.toList()},
      );
      if (res != null && mounted) {
        final deletedPaths = (res['deletedPaths'] as List? ?? [])
            .map((e) => e.toString())
            .toSet();
        final freedBytes = (res['freedBytes'] as num?)?.toInt() ?? 0;
        final deletedCount = (res['deletedCount'] as num?)?.toInt() ?? 0;
        final newRam = (res['availRamMb'] as num?)?.toInt();

        SoundService().playSuccess();
        setState(() {
          _junkFiles.removeWhere((f) => deletedPaths.contains(f['path']));
          _selectedJunkPaths.removeAll(deletedPaths);
          _totalFreedBytesSession += freedBytes;
          _totalDeletedCountSession += deletedCount;
          if (newRam != null && newRam > 0) _availRamMb = newRam;
          _recomputeScore();
        });

        _showSnack(
          deletedCount > 0
              ? 'Cleaned $deletedCount junk files • Freed ${_formatBytes(freedBytes)}'
              : 'Selected files are protected by Android system',
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCleaning = false);
      _fetchSystemSecurityData();
    }
  }

  Future<void> _deleteSingleFile({
    required String path,
    required String name,
    required bool isFishy,
    required bool isUnopened,
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
            child: Text('Cancel', style: TextStyle(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        {'paths': [path]},
      );
      if (res != null && mounted) {
        final deletedCount = (res['deletedCount'] as num?)?.toInt() ?? 0;
        final freedBytes = (res['freedBytes'] as num?)?.toInt() ?? 0;
        if (deletedCount > 0) {
          SoundService().playSuccess();
          setState(() {
            if (isFishy) _fishyFiles.removeWhere((f) => f['path'] == path);
            if (isUnopened) _unopenedFiles.removeWhere((f) => f['path'] == path);
            _largestFiles.removeWhere((f) => f['path'] == path);
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

  Future<void> _showFileInspectorSheet(Map<String, dynamic> fileItem, {required bool isProtectedLarge}) async {
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
    final name = details?['name'] as String? ?? fileItem['name'] as String? ?? 'File';
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
                if (isProtectedLarge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VIEW ONLY',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0EA5E9),
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
                style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: theme.text),
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
                style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: theme.primary),
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
          Text(k, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: theme.textSecondary)),
          Text(v, style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w700, color: theme.text)),
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
    final remJunk = _junkFiles.fold<int>(0, (s, e) => s + ((e['sizeBytes'] as num?)?.toInt() ?? 0));
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
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get _totalIssues =>
      _systemWarnings.length + _suspiciousApps.length + _fishyFiles.length;

  int get _totalJunkBytes =>
      _junkFiles.fold<int>(0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

  int get _selectedJunkBytes => _junkFiles
      .where((e) => _selectedJunkPaths.contains(e['path']))
      .fold<int>(0, (sum, e) => sum + ((e['sizeBytes'] as num?)?.toInt() ?? 0));

  HoloScannerMode get _scannerMode {
    if (_scanState == _ScanState.scanning) return HoloScannerMode.scanning;
    if (_scanState == _ScanState.idle) return HoloScannerMode.idle;
    final hasHigh = _systemWarnings.any((e) => e['severity'] == 'HIGH') ||
        _suspiciousApps.any((e) => e['severity'] == 'HIGH') ||
        _fishyFiles.any((e) => e['severity'] == 'HIGH');
    if (hasHigh) return HoloScannerMode.threat;
    if (_totalIssues > 0 || _totalJunkBytes > 25 * 1024 * 1024) {
      return HoloScannerMode.warning;
    }
    return HoloScannerMode.clean;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isScanning = _scanState == _ScanState.scanning;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Real Security Status Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildTopStatusBanner(theme),
              ),

              // Optional 1-tap Deep Storage Permission Banner (only if not yet granted)
              if (!_hasAllFilesAccess) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildStorageAccessBanner(theme),
                ),
              ],

              const SizedBox(height: 10),

              // 2. INDEPENDENT FLOATING RADIAL SECURITY BAR & MULTI-COLOR FLOWING WAVES
              _buildSecurityRadialBarCard(theme, isScanning),

              const SizedBox(height: 10),

              // 3. Primary Scan Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildActionButton(theme),
              ),

              // 4. LIVE SCAN AUDIT — STRICTLY VISIBLE ONLY WHILE SCANNING!
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: isScanning
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                        child: _buildLiveScanAuditPanel(theme),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 18),

              // 5. Real Hardware RAM & Storage Telemetry Strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildHardwareTelemetryCard(theme),
              ),

              // 6. Categorized Real Scan Findings (After Scan Completes)
              if (_scanState == _ScanState.completed) ...[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildScanResultsHub(theme),
                ),
              ],

              const SizedBox(height: 18),

              // 7. Real Hardware, Kernel & Network Integrity Matrix
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildSystemIntegrityCard(theme),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP STATUS BANNER
  // ===========================================================================
  Widget _buildTopStatusBanner(StationeryTheme theme) {
    final mode = _scannerMode;
    final Color statusColor;
    final IconData icon;
    final String title;
    final String subtitle;

    switch (mode) {
      case HoloScannerMode.scanning:
        statusColor = const Color(0xFF06B6D4);
        icon = Icons.radar_rounded;
        title = 'REAL-TIME DEEP AUDIT ACTIVE';
        subtitle = 'Scanning $_liveAppsScanned apps • $_liveFilesScanned files live';
        break;
      case HoloScannerMode.threat:
        statusColor = const Color(0xFFF43F5E);
        icon = Icons.gpp_bad_rounded;
        title = '$_totalIssues SECURITY RISKS DETECTED';
        subtitle = 'Review flagged apps, fishy files & warnings below';
        break;
      case HoloScannerMode.warning:
        statusColor = const Color(0xFFF59E0B);
        icon = Icons.gpp_maybe_rounded;
        title = _totalIssues > 0
            ? '$_totalIssues ITEMS NEED ATTENTION'
            : '${_formatBytes(_totalJunkBytes)} JUNK READY TO CLEAN';
        subtitle = 'Scanned $_liveAppsScanned apps & $_liveFilesScanned files in ${(_scanDurationMs / 1000.0).toStringAsFixed(1)}s';
        break;
      case HoloScannerMode.clean:
        statusColor = const Color(0xFF10B981);
        icon = Icons.verified_user_rounded;
        title = 'DEVICE VERIFIED & CLEAN';
        subtitle = 'Audited $_liveAppsScanned apps & $_liveFilesScanned real files • 0 threats';
        break;
      case HoloScannerMode.idle:
        statusColor = theme.primary;
        icon = Icons.shield_outlined;
        title = 'HARDWARE & SOFTWARE GUARD';
        subtitle = 'Real kernel, malware, fishy docs, junk & storage monitor';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.32), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.13),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
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

  Widget _buildStorageAccessBanner(StationeryTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_special_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enable All Files Access to deeply scan Downloads, Documents, Largest & Unopened files.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          BouncyTap(
            onTap: _requestAllFilesAccess,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'ALLOW',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. INDEPENDENT FLOATING RADIAL SECURITY BAR & MULTI-COLOR AURORA WAVES
  // ===========================================================================
  Widget _buildSecurityRadialBarCard(StationeryTheme theme, bool isScanning) {
    Color statusColor;
    if (isScanning) {
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
        : (_scannerMode == HoloScannerMode.threat
            ? 'THREATS FOUND'
            : (_scannerMode == HoloScannerMode.warning
                ? 'REVIEW ISSUES'
                : (_scannerMode == HoloScannerMode.clean
                    ? 'VERIFIED SAFE'
                    : 'READY')));

    return BouncyTap(
      onTap: _startOrStopScan,
      scaleFraction: 0.98,
      child: SizedBox(
        width: double.infinity,
        height: 284,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Multi-Color Non-Circular Flowing Aurora Waves (Edge-to-Edge)
            Positioned.fill(
              child: RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _waveFrameNotifier,
                  builder: (context, _, __) {
                    return CustomPaint(
                      painter: _SecurityMultiColorWavePainter(
                        wavePhase: _wavePhase,
                        waveEnergy: _waveEnergy,
                        isScanning: isScanning,
                        theme: theme,
                        statusColor: statusColor,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Independent Larger Silky Smooth Radial Bar Gauge (Noise-Meter Grade)
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
                width: 138,
                height: 138,
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
                child: Column(
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                              width: 1),
                        ),
                        child: Text(
                          statusBadge,
                          style: theme.fontMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                              width: 1),
                        ),
                        child: Text(
                          statusBadge,
                          style: theme.fontMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.55),
                              width: 1),
                        ),
                        child: Text(
                          "READY",
                          style: theme.fontMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
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
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ACTION BUTTON
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
                : [btnColor, Color.lerp(btnColor, const Color(0xFF06B6D4), 0.32)!],
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
  // 4. LIVE SCAN AUDIT PANEL (SHOWN ONLY WHILE SCANNING)
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
          // Live real counters row
          Row(
            children: [
              _miniLiveCounter('APPS', '$_liveAppsScanned', theme.text, theme),
              _miniLiveCounter('FILES', '$_liveFilesScanned', const Color(0xFF06B6D4), theme),
              _miniLiveCounter(
                'ISSUES',
                '$_liveIssuesCount',
                _liveIssuesCount > 0 ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                theme,
              ),
              _miniLiveCounter('JUNK', _formatBytes(_liveJunkBytes), const Color(0xFFF59E0B), theme),
            ],
          ),
          const SizedBox(height: 12),
          // Scrolling real audit stream
          Container(
            height: 168,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: _liveLogs.isEmpty
                ? Center(
                    child: Text(
                      'Initializing hardware & filesystem engine...',
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
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                                fontWeight: idx == 0 ? FontWeight.w700 : FontWeight.w500,
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

  Widget _miniLiveCounter(String label, String value, Color valColor, StationeryTheme theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: valColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. REAL HARDWARE RAM & STORAGE TELEMETRY CARD
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
  // 6. CATEGORIZED REAL FINDINGS HUB (ISSUES / JUNK / LARGEST / UNOPENED)
  // ===========================================================================
  Widget _buildScanResultsHub(StationeryTheme theme) {
    final tabs = [
      ('Issues', _totalIssues, _totalIssues > 0 ? const Color(0xFFF43F5E) : const Color(0xFF10B981)),
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
          // Segmented 4-tab pill bar
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? badgeColor.withValues(alpha: 0.16) : theme.bg,
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: selected ? 0.25 : 0.12),
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

  // --- TAB 0: REAL THREATS, SUSPICIOUS APPS, FISHY FILES & SYSTEM WARNINGS ---
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_suspiciousApps.isNotEmpty) ...[
          _subSectionLabel('SUSPICIOUS / HIGH-RISK APPS (${_suspiciousApps.length})', const Color(0xFFF43F5E)),
          const SizedBox(height: 8),
          ..._suspiciousApps.map((app) => _buildSuspiciousAppCard(app, theme)),
          const SizedBox(height: 12),
        ],
        if (_fishyFiles.isNotEmpty) ...[
          _subSectionLabel('FISHY, SPOOFED & EXECUTABLE FILES (${_fishyFiles.length})', const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          ..._fishyFiles.map((file) => _buildFishyFileCard(file, theme)),
          const SizedBox(height: 12),
        ],
        if (_systemWarnings.isNotEmpty) ...[
          _subSectionLabel('SYSTEM & HARDWARE WARNINGS (${_systemWarnings.length})', const Color(0xFF0EA5E9)),
          const SizedBox(height: 8),
          ..._systemWarnings.map((w) => _buildSystemWarningCard(w, theme)),
        ],
      ],
    );
  }

  Widget _buildSuspiciousAppCard(Map<String, dynamic> app, StationeryTheme theme) {
    final name = app['name'] as String? ?? 'Unknown App';
    final pkg = app['packageName'] as String? ?? '';
    final sev = app['severity'] as String? ?? 'MEDIUM';
    final installer = app['installer'] as String? ?? 'Unknown';
    final reasons = (app['reasons'] as List? ?? []).map((e) => e.toString()).toList();
    final color = sev == 'HIGH' ? const Color(0xFFF43F5E) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.android_rounded, color: color, size: 20),
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
                onTap: () => _methodChannel.invokeMethod('openAppSettings', {'packageName': pkg}),
              ),
              const SizedBox(width: 8),
              _smallActionChip(
                label: 'UNINSTALL',
                color: const Color(0xFFF43F5E),
                onTap: () => _methodChannel.invokeMethod('uninstallApp', {'packageName': pkg}),
              ),
            ],
          ),
        ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: theme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _smallActionChip(
                label: 'INSPECT SHA-256',
                color: theme.primary,
                onTap: () => _showFileInspectorSheet(file, isProtectedLarge: false),
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
    );
  }

  Widget _buildSystemWarningCard(Map<String, dynamic> w, StationeryTheme theme) {
    final title = w['title'] as String? ?? 'Warning';
    final detail = w['detail'] as String? ?? '';
    final sev = w['severity'] as String? ?? 'MEDIUM';
    final actionType = w['actionType'] as String? ?? 'info';
    final color = sev == 'HIGH'
        ? const Color(0xFFF43F5E)
        : (sev == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF0EA5E9));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: theme.textSecondary),
          ),
          if (actionType != 'info') ...[
            const SizedBox(height: 8),
            _smallActionChip(
              label: 'OPEN SYSTEM SETTINGS',
              color: color,
              onTap: () => _methodChannel.invokeMethod('openSystemSetting', {'type': actionType}),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 1: REAL CLEANABLE CACHE & JUNK FILES ---
  Widget _buildJunkTab(StationeryTheme theme) {
    if (_junkFiles.isEmpty) {
      return _emptyStateCard(
        icon: Icons.cleaning_services_rounded,
        color: const Color(0xFF10B981),
        title: 'Zero Junk or Residual Cache Found',
        subtitle: 'App caches, .tmp/.log/.bak files & zero-byte orphans are completely clean.',
        theme: theme,
      );
    }

    final allSelected = _selectedJunkPaths.length == _junkFiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_junkFiles.length} CLEANABLE • ${_formatBytes(_totalJunkBytes)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFF59E0B),
              ),
            ),
            GestureDetector(
              onTap: () {
                SoundService().playTap();
                setState(() {
                  if (allSelected) {
                    _selectedJunkPaths.clear();
                  } else {
                    _selectedJunkPaths.addAll(
                      _junkFiles.map((e) => e['path'] as String? ?? '').where((p) => p.isNotEmpty),
                    );
                  }
                });
              },
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
        ),
        const SizedBox(height: 10),
        BouncyTap(
          onTap: (_isCleaning || _selectedJunkPaths.isEmpty) ? null : _cleanSelectedJunk,
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
                    ? 'CLEANING REAL FILES...'
                    : 'CLEAN ${_selectedJunkPaths.length} SELECTED (${_formatBytes(_selectedJunkBytes)})',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ..._junkFiles.take(40).map((f) {
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
                  color: checked ? const Color(0xFF10B981).withValues(alpha: 0.45) : theme.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: checked ? const Color(0xFF10B981) : theme.textSecondary,
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
      ],
    );
  }

  // --- TAB 2: LARGEST STORAGE FILES (STRICTLY PROTECTED / DISPLAY ONLY!) ---
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
            : 'Tap ALLOW above so Tooler can list your heaviest storage files without deleting them.',
        theme: theme,
      );
    }

    final maxBytes = ((_largestFiles.first['sizeBytes'] as num?)?.toInt() ?? 1).clamp(1, 1 << 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PROTECTED VIEW ONLY — Heavy files are shown for storage insight and are NEVER auto-deleted.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: theme.text,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ..._largestFiles.map((file) {
          final name = file['name'] as String? ?? '';
          final folder = file['folder'] as String? ?? 'Storage';
          final ext = file['extension'] as String? ?? 'FILE';
          final size = (file['sizeBytes'] as num?)?.toInt() ?? 0;
          final ratio = (size / maxBytes).clamp(0.06, 1.0);

          return InkWell(
            onTap: () => _showFileInspectorSheet(file, isProtectedLarge: true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                              '/$folder • Tap to inspect',
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0EA5E9),
                        ),
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
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF0EA5E9)),
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

  // --- TAB 3: UNOPENED / UNTOUCHED FILES (REAL POSIX ATIME == MTIME) ---
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETECTED VIA REAL POSIX FILE ACCESS TIMESTAMPS (${_unopenedFiles.length})',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFA855F7),
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
          final accent = neverOpened ? const Color(0xFFA855F7) : const Color(0xFFF59E0B);

          return InkWell(
            onTap: () => _showFileInspectorSheet(file, isProtectedLarge: false),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.drafts_outlined, color: accent, size: 18),
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
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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

  // ===========================================================================
  // 7. REAL HARDWARE & FIRMWARE INTEGRITY MATRIX
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
          _specRow('Operating System', '$_androidVersion (API $_sdkInt)', theme),
          _specRow('Security Patch', _securityPatch, theme),
          _specRow('Kernel Version', _kernelVersion, theme),
          _specRow('SELinux Policy', _selinuxState, theme,
              highlight: _selinuxState.contains('Permissive') ? const Color(0xFFF43F5E) : const Color(0xFF10B981)),
          _specRow('Root / SU Status', _isRooted ? 'Detected (Risk)' : 'Clean (Unrooted)', theme,
              highlight: _isRooted ? const Color(0xFFF43F5E) : const Color(0xFF10B981)),
          _specRow('Screen Lock Guard', _isDeviceSecure ? 'Protected' : 'Unsecured', theme,
              highlight: _isDeviceSecure ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
          _specRow('USB Debugging (ADB)', _isAdbEnabled ? 'Enabled (Open)' : 'Closed', theme,
              highlight: _isAdbEnabled ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
          _specRow('Developer Options', _isDevMode ? 'Enabled' : 'Disabled', theme),
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

  Widget _specRow(String label, String value, StationeryTheme theme, {Color? highlight}) {
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

  // ===========================================================================
  // SHARED SMALL UI HELPERS
  // ===========================================================================
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

/// Multi-Color Flowing Aurora Wave Painter for Security Scanner.
/// Renders non-circular, intertwined sinusoidal energy ribbons and crest sparks
/// using the full UI color palette with soft edge fade across the hover page.
class _SecurityMultiColorWavePainter extends CustomPainter {
  final double wavePhase;
  final double waveEnergy;
  final bool isScanning;
  final StationeryTheme theme;
  final Color statusColor;

  const _SecurityMultiColorWavePainter({
    required this.wavePhase,
    required this.waveEnergy,
    required this.isScanning,
    required this.theme,
    required this.statusColor,
  });

  List<Color> _uiSpectrum() => [
        theme.primary,
        const Color(0xFF06B6D4), // Cyan
        const Color(0xFFA855F7), // Lilac Violet
        const Color(0xFF10B981), // Emerald
        const Color(0xFFF59E0B), // Warm Amber
        const Color(0xFF0EA5E9), // Sky Blue
        const Color(0xFFFB7185), // Blush Rose
      ];

  double _strandY(
    int i,
    double t,
    double centerY,
    double width,
    double env,
  ) {
    const double twoPi = math.pi * 2.0;
    final double spread = (i - 2.5) * 14.0 * (0.45 + 0.55 * env);
    final double crossTilt =
        (i.isEven ? 1.0 : -1.0) * (16.0 + (i % 3) * 8.0) * (t - 0.5) * env;
    final double f1 = 1.35 + (i % 3) * 0.52;
    final double f2 = 2.65 + (i % 2) * 0.90;
    final double dir = i.isEven ? 1.0 : -1.0;
    final double phase1 = wavePhase * dir * (0.85 + i * 0.14) + i * 1.12;
    final double phase2 = wavePhase * -dir * 0.65 + i * 2.05;
    final double amp =
        (19.0 + (i % 3) * 8.0) * (0.64 + 0.54 * waveEnergy) * env;

    return centerY +
        spread +
        crossTilt +
        math.sin(t * twoPi * f1 + phase1) * amp +
        math.cos(t * twoPi * f2 + phase2) * (amp * 0.42);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final List<Color> uiColors = _uiSpectrum();
    final Rect bounds = Offset.zero & size;
    const int segs = 72;
    const int strandCount = 6;
    final bool isDark = theme.isDark;

    // Precompute points for all 6 sinusoidal wave strands
    final List<List<Offset>> strands = List.generate(strandCount, (i) {
      return List.generate(segs + 1, (s) {
        final double t = s / segs;
        final double env = math.pow(math.sin(t * math.pi), 0.72).toDouble();
        final double x = t * size.width;
        final double y = _strandY(i, t, centerY, size.width, env);
        return Offset(x, y);
      });
    });

    // 1. Translucent Multi-Color Ribbon Veils between counter-phase pairs (i, i+3)
    for (int i = 0; i < 3; i++) {
      final List<Offset> topPts = strands[i];
      final List<Offset> botPts = strands[i + 3];
      final Path ribbonPath = Path()..moveTo(topPts.first.dx, topPts.first.dy);
      for (int s = 1; s < topPts.length; s++) {
        ribbonPath.lineTo(topPts[s].dx, topPts[s].dy);
      }
      for (int s = botPts.length - 1; s >= 0; s--) {
        ribbonPath.lineTo(botPts[s].dx, botPts[s].dy);
      }
      ribbonPath.close();

      final Color c0 = uiColors[i % uiColors.length];
      final Color c1 = uiColors[(i + 2) % uiColors.length];
      final Color c2 = uiColors[(i + 4) % uiColors.length];
      final double ribbonAlpha =
          (isDark ? 0.11 : 0.09) * (0.72 + 0.45 * waveEnergy);

      final Paint ribbonPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            c0.withValues(alpha: ribbonAlpha),
            c1.withValues(alpha: ribbonAlpha * 1.15),
            c2.withValues(alpha: ribbonAlpha),
            Colors.transparent,
          ],
          stops: const [0.0, 0.16, 0.50, 0.84, 1.0],
        ).createShader(bounds)
        ..style = PaintingStyle.fill;

      canvas.drawPath(ribbonPath, ribbonPaint);
    }

    // 2. Glowing Multi-Color Wave Filaments (Bloom + Crisp Core)
    for (int i = 0; i < strandCount; i++) {
      final List<Offset> pts = strands[i];
      final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int s = 1; s < pts.length; s++) {
        path.lineTo(pts[s].dx, pts[s].dy);
      }

      final Color c0 = uiColors[i % uiColors.length];
      final Color c1 = uiColors[(i + 2) % uiColors.length];
      final Color c2 = uiColors[(i + 4) % uiColors.length];
      final Color c3 = uiColors[(i + 6) % uiColors.length];

      final double bloomAlpha =
          (isDark ? 0.30 : 0.22) * (0.68 + 0.48 * waveEnergy);
      final double coreAlpha =
          (isDark ? 0.64 : 0.56) * (0.70 + 0.42 * waveEnergy);

      final Shader bloomShader = LinearGradient(
        colors: [
          Colors.transparent,
          c0.withValues(alpha: bloomAlpha),
          c1.withValues(alpha: bloomAlpha),
          c2.withValues(alpha: bloomAlpha),
          c3.withValues(alpha: bloomAlpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.12, 0.38, 0.62, 0.88, 1.0],
      ).createShader(bounds);

      canvas.drawPath(
        path,
        Paint()
          ..shader = bloomShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = isScanning ? 6.2 : 4.6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
      );

      final Shader coreShader = LinearGradient(
        colors: [
          Colors.transparent,
          c0.withValues(alpha: coreAlpha),
          c1.withValues(alpha: coreAlpha),
          c2.withValues(alpha: coreAlpha),
          c3.withValues(alpha: coreAlpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.12, 0.38, 0.62, 0.88, 1.0],
      ).createShader(bounds);

      canvas.drawPath(
        path,
        Paint()
          ..shader = coreShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = (i < 3 ? 2.0 : 1.45) + (isScanning ? 0.45 : 0.0)
          ..strokeCap = StrokeCap.round,
      );
    }

    // 3. Wave-Crest Energy Motes riding smoothly along the colorful ribbons
    const int moteCount = 12;
    for (int k = 0; k < moteCount; k++) {
      final int strandIdx = k % strandCount;
      final double speed = 0.042 + (k % 3) * 0.014;
      final double t = ((wavePhase * speed) + (k / moteCount)) % 1.0;
      final double fade = math.sin(t * math.pi).clamp(0.0, 1.0);
      final double env = math.pow(fade, 0.72).toDouble();
      final double x = t * size.width;
      final double y = _strandY(strandIdx, t, centerY, size.width, env);
      final Offset pos = Offset(x, y);

      final Color moteColor =
          k == 0 && isScanning ? statusColor : uiColors[k % uiColors.length];
      final double alpha = fade * (0.48 + 0.42 * waveEnergy);
      final double r = 1.6 + (k % 3) * 0.55;

      canvas.drawCircle(
        pos,
        r * 2.5,
        Paint()
          ..color = moteColor.withValues(alpha: alpha * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = Color.lerp(moteColor, Colors.white, isDark ? 0.35 : 0.15)!
              .withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SecurityMultiColorWavePainter oldDelegate) =>
      oldDelegate.wavePhase != wavePhase ||
      (oldDelegate.waveEnergy - waveEnergy).abs() > 0.002 ||
      oldDelegate.isScanning != isScanning ||
      oldDelegate.statusColor != statusColor ||
      oldDelegate.theme.isDark != theme.isDark ||
      oldDelegate.theme.primary != theme.primary;
}
