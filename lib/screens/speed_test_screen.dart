import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/network_speed_service.dart';
import '../widgets_3d/bouncy_tap.dart';

/// ---------------------------------------------------------------------------
/// TOOLER HARDWARE SPEED TEST & RADIO TELEMETRY SCREEN
/// - 180° Half-Circular Precision Speedometer Gauge
/// - Real-time Multi-CDN Download, Upload, Ping & Jitter Testing
/// - Deep Wi-Fi Hardware Telemetry (SSID, Band GHz, Channel, Link Speed, Generation)
/// - Deep Cellular 5G/4G Telemetry (NR State, Frequency, RSRP, SINR, Cell ID)
/// - Nearest Cell Tower Distance Estimation (Timing Advance & RF Propagation)
/// - "Refresh Network" (Socket purge & Airplane mode radio re-register)
/// - "Force 5G" / Hidden Phone Info Engineering Menu Launcher
/// - Complete Preferred Network Modes Explainer (NR only, NR/LTE, etc.)
/// ---------------------------------------------------------------------------

class SpeedTestScreen extends StatefulWidget {
  final StationeryTheme theme;

  const SpeedTestScreen({super.key, required this.theme});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> with SingleTickerProviderStateMixin {
  final NetworkSpeedService _speedService = NetworkSpeedService();

  NetworkTelemetry _telemetry = const NetworkTelemetry();
  Timer? _telemetryTimer;
  StreamSubscription<Map<String, dynamic>>? _testSub;

  SpeedTestStage _stage = SpeedTestStage.idle;
  double _currentSpeedMbps = 0.0;
  double _downloadMbps = 0.0;
  double _uploadMbps = 0.0;
  int _pingMs = 0;
  int _jitterMs = 0;
  double _testProgress = 0.0;
  SpeedTestResult? _lastResult;
  double _bestSpeedMbps = 0.0;

  bool _isMBsUnit = false; // False = Mbps, True = MB/s

  late final AnimationController _needleAnimController;
  late Animation<double> _needleAnimation;
  double _needleValue = 0.0;

  @override
  void initState() {
    super.initState();

    _needleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _needleAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _needleAnimController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _needleValue = _needleAnimation.value;
        });
      });

    _fetchTelemetry();
    _loadBestSpeed();

    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_speedService.isTestRunning) {
        _fetchTelemetry(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _testSub?.cancel();
    _speedService.cancelTest();
    _needleAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchTelemetry({bool silent = false}) async {
    final t = await _speedService.getTelemetry();
    if (mounted) {
      setState(() {
        _telemetry = t;
      });
    }
  }

  Future<void> _loadBestSpeed() async {
    final b = await _speedService.getBestSpeed();
    if (mounted) {
      setState(() {
        _bestSpeedMbps = b;
      });
    }
  }

  void _animateNeedleTo(double targetSpeedMbps) {
    _needleAnimation = Tween<double>(
      begin: _needleValue,
      end: targetSpeedMbps,
    ).animate(CurvedAnimation(parent: _needleAnimController, curve: Curves.easeOutCubic));
    _needleAnimController.forward(from: 0.0);
  }

  void _startSpeedTest() {
    SoundService().playSpecialClick();
    _testSub?.cancel();

    setState(() {
      _stage = SpeedTestStage.pinging;
      _currentSpeedMbps = 0.0;
      _downloadMbps = 0.0;
      _uploadMbps = 0.0;
      _pingMs = 0;
      _jitterMs = 0;
      _testProgress = 0.0;
      _lastResult = null;
    });

    _testSub = _speedService.runSpeedTest().listen((event) {
      if (!mounted) return;
      setState(() {
        _stage = event['stage'] as SpeedTestStage;
        _pingMs = event['pingMs'] as int? ?? _pingMs;
        _jitterMs = event['jitterMs'] as int? ?? _jitterMs;
        _downloadMbps = event['downloadMbps'] as double? ?? _downloadMbps;
        _uploadMbps = event['uploadMbps'] as double? ?? _uploadMbps;
        _testProgress = event['progress'] as double? ?? _testProgress;
        _currentSpeedMbps = event['currentSpeed'] as double? ?? 0.0;

        if (event['result'] != null) {
          _lastResult = event['result'] as SpeedTestResult;
          _bestSpeedMbps = math.max(_bestSpeedMbps, _lastResult!.downloadMbps);
          SoundService().playSuccess();
        }
      });
      _animateNeedleTo(_currentSpeedMbps);
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _stage = SpeedTestStage.error;
        });
      }
    });
  }

  void _stopSpeedTest() {
    SoundService().playTap();
    _speedService.cancelTest();
    _testSub?.cancel();
    setState(() {
      _stage = SpeedTestStage.idle;
      _currentSpeedMbps = 0.0;
      _testProgress = 0.0;
    });
    _animateNeedleTo(0.0);
  }

  Future<void> _handleRefreshNetwork() async {
    SoundService().playSpecialClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: widget.theme.border, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.theme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh_rounded, color: widget.theme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Turbo Refresh Network',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: widget.theme.text,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flushes local DNS sockets, resets carrier bearer sessions, and opens Airplane Mode quick settings.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.theme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.theme.lavenderBubble.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.theme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flight_takeoff_rounded, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Toggle Airplane mode ON for 3s then OFF to force your phone to reconnect to the nearest 5G tower!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: widget.theme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _speedService.refreshNetwork();
              _fetchTelemetry();
            },
            child: Text('Open & Refresh', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLaunchRadioInfo() async {
    SoundService().playSpecialClick();
    final launched = await _speedService.launchRadioInfoMenu();
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dial *#*#4636#*#* on your phone dialer to open Phone Info directly.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: widget.theme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              _buildTopHeader(theme),

              const SizedBox(height: 16),

              // Hero Half-Circular Speedometer Gauge
              _buildHalfSpeedometerCard(theme),

              const SizedBox(height: 16),

              // Network Type & Hardware Telemetry (WiFi vs Cellular)
              _buildHardwareTelemetryCard(theme),

              const SizedBox(height: 16),

              // Nearest Cell Tower Distance & RF Signal Specs
              _buildNearestTowerCard(theme),

              const SizedBox(height: 16),

              // Force 5G / Phone Info Engineering Menu & Modes Explainer
              _buildForce5gSection(theme),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Navigation Bar with Quick Refresh Network Action
  Widget _buildTopHeader(StationeryTheme theme) {
    return Row(
      children: [
        BouncyTap(
          onTap: () {
            SoundService().playTap();
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: theme.border, width: 1.2),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18, color: theme.text),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speed Test',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: theme.text,
                ),
              ),
              Text(
                'Wi-Fi, 5G NR Radio & Nearest Tower',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // "Refresh Network" Quick Action Button
        BouncyTap(
          onTap: _handleRefreshNetwork,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'Refresh',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Hero Half-Circular Arc Speedometer Card
  Widget _buildHalfSpeedometerCard(StationeryTheme theme) {
    final isTesting = _stage == SpeedTestStage.pinging ||
        _stage == SpeedTestStage.downloading ||
        _stage == SpeedTestStage.uploading;

    final displaySpeed = _isMBsUnit ? (_needleValue / 8.0) : _needleValue;
    final unitLabel = _isMBsUnit ? 'MB/s' : 'Mbps';

    String stageLabel;
    Color stageColor;
    switch (_stage) {
      case SpeedTestStage.idle:
        stageLabel = 'READY FOR SPEED TEST';
        stageColor = theme.primary;
        break;
      case SpeedTestStage.pinging:
        stageLabel = 'MEASURING LATENCY & JITTER';
        stageColor = const Color(0xFFF59E0B);
        break;
      case SpeedTestStage.downloading:
        stageLabel = 'STREAMING DOWNLOAD (CHUNKS)';
        stageColor = const Color(0xFF10B981);
        break;
      case SpeedTestStage.uploading:
        stageLabel = 'TESTING UPLOAD BANDWIDTH';
        stageColor = const Color(0xFF8B5CF6);
        break;
      case SpeedTestStage.completed:
        stageLabel = 'TEST COMPLETED';
        stageColor = const Color(0xFF10B981);
        break;
      case SpeedTestStage.error:
        stageLabel = 'CONNECTION TIMEOUT';
        stageColor = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isTesting ? stageColor.withValues(alpha: 0.5) : theme.border,
          width: 1.5,
        ),
        boxShadow: isTesting
            ? [
                BoxShadow(
                  color: stageColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          // Stage pill badge & Unit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: stageColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stageLabel,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: stageColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Unit Toggle (Mbps <-> MB/s)
              BouncyTap(
                onTap: () {
                  SoundService().playTap();
                  setState(() => _isMBsUnit = !_isMBsUnit);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Text(
                    _isMBsUnit ? 'MB/s (MegaBytes)' : 'Mbps (MegaBits)',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Half-Circular Arc Speedometer Visual
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _HalfSpeedometerGaugePainter(
                speedMbps: _needleValue,
                maxSpeedMbps: 1000.0,
                arcColor: stageColor,
                trackColor: theme.border.withValues(alpha: 0.6),
                needleColor: theme.text,
              ),
              child: Align(
                alignment: const Alignment(0, 0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displaySpeed.toStringAsFixed(1),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.8,
                        color: theme.text,
                      ),
                    ),
                    Text(
                      unitLabel,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: stageColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Latency Metrics Grid (Ping, Jitter, Download, Upload)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('PING', '$_pingMs ms', Icons.network_ping_rounded, const Color(0xFFF59E0B), theme),
                _buildMetricDivider(theme),
                _buildMetricCol('JITTER', '$_jitterMs ms', Icons.compare_arrows_rounded, const Color(0xFF3B82F6), theme),
                _buildMetricDivider(theme),
                _buildMetricCol(
                  'DOWNLOAD',
                  '${_downloadMbps.toStringAsFixed(1)} M',
                  Icons.arrow_downward_rounded,
                  const Color(0xFF10B981),
                  theme,
                ),
                _buildMetricDivider(theme),
                _buildMetricCol(
                  'UPLOAD',
                  '${_uploadMbps.toStringAsFixed(1)} M',
                  Icons.arrow_upward_rounded,
                  const Color(0xFF8B5CF6),
                  theme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Primary Speed Test Trigger Action
          BouncyTap(
            onTap: isTesting ? _stopSpeedTest : _startSpeedTest,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isTesting
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [theme.primary, const Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isTesting ? const Color(0xFFEF4444) : theme.primary).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isTesting ? Icons.stop_rounded : Icons.speed_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isTesting ? 'STOP TEST' : 'START SPEED TEST',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_bestSpeedMbps > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Personal Best: ${_bestSpeedMbps.toStringAsFixed(1)} Mbps • Ultra HD 4K Ready',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon, Color color, StationeryTheme theme) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: theme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider(StationeryTheme theme) {
    return Container(width: 1, height: 26, color: theme.border);
  }

  /// 3. Hardware Wi-Fi & Cellular Telemetry Card
  Widget _buildHardwareTelemetryCard(StationeryTheme theme) {
    final isWifi = _telemetry.connectionType == 'WIFI';
    final wifi = _telemetry.wifi;
    final cell = _telemetry.cellular;

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
              Row(
                children: [
                  Icon(
                    isWifi ? Icons.wifi_rounded : Icons.cell_tower_rounded,
                    size: 20,
                    color: isWifi ? const Color(0xFF10B981) : theme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isWifi ? 'WI-FI TELEMETRY' : 'CELLULAR RADIO 5G/4G',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isWifi ? const Color(0xFF10B981) : theme.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isWifi ? wifi.band : (cell.is5G ? '5G SA ACTIVE' : '4G LTE-A'),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isWifi ? const Color(0xFF10B981) : theme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Two Column Hardware Specs Grid
          if (isWifi) ...[
            _buildSpecRow('SSID Network', wifi.ssid, 'Wi-Fi Gen', wifi.wifiStandard, theme),
            const SizedBox(height: 8),
            _buildSpecRow('Frequency Band', '${wifi.frequencyMhz} MHz (${wifi.band})', 'Channel', 'Ch ${wifi.channel}', theme),
            const SizedBox(height: 8),
            _buildSpecRow('Link Speed', '${wifi.linkSpeedMbps} Mbps (Rx: ${wifi.rxLinkSpeedMbps})', 'Signal RSSI', '${wifi.rssi} dBm (${wifi.signalPercent}%)', theme),
            const SizedBox(height: 8),
            _buildSpecRow('IPv4 Local', wifi.ipAddress, 'Gateway', wifi.gateway, theme),
          ] else ...[
            _buildSpecRow('Carrier', cell.carrier, 'Radio Tech', cell.networkType, theme),
            const SizedBox(height: 8),
            _buildSpecRow('5G NR State', cell.nrState, 'NR Frequency', cell.nrFrequency, theme),
            const SizedBox(height: 8),
            _buildSpecRow('Operating Band', cell.bandName, 'Signal Quality', '${cell.rsrp} dBm (RSRQ: ${cell.rsrq})', theme),
            const SizedBox(height: 8),
            _buildSpecRow('Cell Identifiers', 'CID: ${cell.cid} • PCI: ${cell.pci}', 'TAC / Area', 'TAC: ${cell.tac}', theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow(String lbl1, String val1, String lbl2, String val2, StationeryTheme theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lbl1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val1,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: theme.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lbl2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val2,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: theme.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Nearest Cell Tower Distance & RF Propagation Card
  Widget _buildNearestTowerCard(StationeryTheme theme) {
    final cell = _telemetry.cellular;
    final distanceMeters = cell.estimatedTowerDistanceMeters;

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
              const Icon(Icons.radar_rounded, size: 20, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'NEAREST CELL TOWER DISTANCE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.cell_tower_rounded, color: Color(0xFF10B981), size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          distanceMeters < 1000 ? '$distanceMeters' : (distanceMeters / 1000.0).toStringAsFixed(2),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceMeters < 1000 ? 'meters away' : 'kilometers',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cell.towerProximity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calculated via Timing Advance (TA=${cell.timingAdvance}) & 3GPP RF propagation path-loss algorithms.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5. "Force 5G" / Hidden Phone Info Engineering Menu & Modes Explainer
  Widget _buildForce5gSection(StationeryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.35), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.five_g_rounded, size: 24, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    'FORCE 5G & RADIO INFO',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ENGINEERING',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Lock your phone onto 5G Standalone (NR only) so it never drops back to 4G LTE. Launch the hidden Android radio menu directly below.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          // Direct System RadioInfo Launcher Button
          BouncyTap(
            onTap: _handleLaunchRadioInfo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'OPEN PHONE INFO (FORCE 5G MENU)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Network Modes Guide
          Text(
            'Preferred Network Modes Explained:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.text,
            ),
          ),

          const SizedBox(height: 10),

          // Interactive Mode Cards
          _buildModeExplainerCard(
            title: 'NR only (Force 5G Only)',
            badge: 'Lock 5G Standalone',
            badgeColor: const Color(0xFF10B981),
            desc: 'Phone stays strictly on 5G SA. It will NEVER drop to 4G/LTE even in weak signal areas. Gigabit speed locked.',
            caution: 'Notice: If your carrier lacks VoNR in your city, regular cellular voice calls may fail.',
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildModeExplainerCard(
            title: 'NR/LTE (Recommended 5G + 4G)',
            badge: 'Best Daily Driver',
            badgeColor: const Color(0xFF3B82F6),
            desc: 'Enables 5G SA & NSA with instant 4G VoLTE fallback. Zero call drops with blazing 5G data speeds (Jio & Airtel).',
            caution: null,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildModeExplainerCard(
            title: 'LTE only (Force 4G Only)',
            badge: 'Battery Saver',
            badgeColor: const Color(0xFFF59E0B),
            desc: 'Disables 5G modem battery drain completely. Ideal for long road trips where 5G reception fluctuates.',
            caution: null,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildModeExplainerCard(
            title: 'NR/LTE/GSM/WCDMA',
            badge: 'Global Auto Roaming',
            badgeColor: theme.textSecondary,
            desc: 'Default factory setting with 2G/3G legacy fallback. Best for remote village travel with older towers.',
            caution: null,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _buildModeExplainerCard(
            title: 'GSM only (2G Only)',
            badge: 'Ultra Battery Saver',
            badgeColor: const Color(0xFFEF4444),
            desc: 'Forces 2G radio only. At 5% battery, this mode lets phone last 12+ hours for emergency calls & SMS.',
            caution: null,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildModeExplainerCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required String desc,
    String? caution,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
          if (caution != null) ...[
            const SizedBox(height: 4),
            Text(
              caution,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CUSTOM PAINTER: 180° HALF-CIRCULAR SPEEDOMETER GAUGE
/// ---------------------------------------------------------------------------
class _HalfSpeedometerGaugePainter extends CustomPainter {
  final double speedMbps;
  final double maxSpeedMbps;
  final Color arcColor;
  final Color trackColor;
  final Color needleColor;

  _HalfSpeedometerGaugePainter({
    required this.speedMbps,
    required this.maxSpeedMbps,
    required this.arcColor,
    required this.trackColor,
    required this.needleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = size.height * 0.78;
    const strokeWidth = 12.0;

    // Background track arc (180 degrees, from math.pi to 2 * math.pi)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // Active speed progress arc
    final speedFrac = (speedMbps / maxSpeedMbps).clamp(0.0, 1.0);
    final sweepAngle = math.pi * speedFrac;

    if (sweepAngle > 0.01) {
      final activePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF3B82F6),
            arcColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        sweepAngle,
        false,
        activePaint,
      );
    }

    // Ticks & Milestone Labels (0, 10, 50, 100, 250, 500, 1000)
    final milestones = [
      {'speed': 0.0, 'label': '0'},
      {'speed': 50.0, 'label': '50'},
      {'speed': 100.0, 'label': '100'},
      {'speed': 250.0, 'label': '250'},
      {'speed': 500.0, 'label': '500'},
      {'speed': 1000.0, 'label': '1G'},
    ];

    for (final m in milestones) {
      final s = m['speed'] as double;
      final frac = (s / maxSpeedMbps).clamp(0.0, 1.0);
      final angle = math.pi + (math.pi * frac);

      final tickOuter = Offset(
        center.dx + (radius + 8) * math.cos(angle),
        center.dy + (radius + 8) * math.sin(angle),
      );
      final tickInner = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = (speedMbps >= s ? arcColor : trackColor)
        ..strokeWidth = 2.0;
      canvas.drawLine(tickInner, tickOuter, tickPaint);
    }

    // Dynamic Needle
    final needleAngle = math.pi + sweepAngle;
    final needleTip = Offset(
      center.dx + (radius - 16) * math.cos(needleAngle),
      center.dy + (radius - 16) * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = arcColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTip, needlePaint);

    // Center pivot knob
    final knobPaint = Paint()..color = needleColor;
    canvas.drawCircle(center, 6.0, knobPaint);

    final knobInner = Paint()..color = arcColor;
    canvas.drawCircle(center, 3.0, knobInner);
  }

  @override
  bool shouldRepaint(covariant _HalfSpeedometerGaugePainter oldDelegate) {
    return oldDelegate.speedMbps != speedMbps ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.trackColor != trackColor;
  }
}
