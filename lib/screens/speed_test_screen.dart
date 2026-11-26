import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/network_speed_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/smooth_radial_gauge.dart';

/// ---------------------------------------------------------------------------
/// TOOLER HARDWARE SPEED TEST & RADIO TELEMETRY SCREEN
/// - Silky-Smooth Circular Radial Speedometer Gauge (Noise Meter architecture)
/// - Real-time Multi-CDN Download, Upload, Ping & Jitter Testing
/// - Direct In-App "Refresh Network" (Zero intrusive settings dialogs)
/// - Direct In-App "Force 5G" & Preferred Network Modes Selector
/// - Live 5G/4G Cellular Telemetry & Accurate Nearest Cell Tower Triangulation
/// ---------------------------------------------------------------------------

class SpeedTestScreen extends StatefulWidget {
  final StationeryTheme theme;

  const SpeedTestScreen({super.key, required this.theme});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen>
    with SingleTickerProviderStateMixin {
  final NetworkSpeedService _speedService = NetworkSpeedService();

  NetworkTelemetry _telemetry = const NetworkTelemetry();
  Timer? _telemetryTimer;
  StreamSubscription<Map<String, dynamic>>? _testSub;

  SpeedTestStage _stage = SpeedTestStage.idle;
  double _displaySpeedMbps = 0.0;
  double _targetSpeedMbps = 0.0;
  double _peakHoldSpeedMbps = 0.0;
  DateTime _peakHoldUpdatedAt = DateTime.now();

  double _downloadMbps = 0.0;
  double _uploadMbps = 0.0;
  int _pingMs = 0;
  int _jitterMs = 0;
  double _testProgress = 0.0;

  // 60/120fps display damper ticker (reproduced from noise meter)
  Ticker? _gaugeTicker;
  Duration _lastTickerElapsed = Duration.zero;

  // Preferred Network Modes: 'LOCK_5G', 'BATTERY_SAVER', 'ULTRA_SAVER', 'GLOBAL_AUTO'
  String _selectedNetworkMode = 'LOCK_5G';
  bool _isRefreshingNetwork = false;

  @override
  void initState() {
    super.initState();

    // Zero-jitter 60/120fps exponential damper from Noise Meter
    _gaugeTicker = createTicker((elapsed) {
      if (!mounted) return;
      final dt = ((elapsed - _lastTickerElapsed).inMicroseconds / 1000000.0)
          .clamp(0.001, 0.05);
      _lastTickerElapsed = elapsed;

      final bool rising = _targetSpeedMbps > _displaySpeedMbps;
      final double speed = rising ? 12.0 : 6.5;
      final double factor = 1.0 - math.exp(-speed * dt);
      final double nextSpeed =
          _displaySpeedMbps + (_targetSpeedMbps - _displaySpeedMbps) * factor;

      double nextPeak = _peakHoldSpeedMbps;
      if (nextSpeed >= nextPeak) {
        nextPeak = nextSpeed;
        _peakHoldUpdatedAt = DateTime.now();
      } else if (DateTime.now()
              .difference(_peakHoldUpdatedAt)
              .inMilliseconds >
          1800) {
        nextPeak = math.max(nextSpeed, nextPeak - 35.0 * dt);
      }

      if ((nextSpeed - _displaySpeedMbps).abs() > 0.04 ||
          (nextPeak - _peakHoldSpeedMbps).abs() > 0.04) {
        setState(() {
          _displaySpeedMbps = nextSpeed;
          _peakHoldSpeedMbps = nextPeak;
        });
      }
    });
    _gaugeTicker?.start();

    _fetchTelemetry();

    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_speedService.isTestRunning) {
        _fetchTelemetry(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _gaugeTicker?.dispose();
    _telemetryTimer?.cancel();
    _testSub?.cancel();
    _speedService.cancelTest();
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

  static double speedToFraction(double mbps, double maxMbps) {
    if (mbps <= 0.0) return 0.0;
    if (mbps >= maxMbps) return 1.0;
    // Calibrated perceptual progression so low and high speeds look dynamic
    if (mbps <= 100.0) {
      return (mbps / 100.0) * 0.60;
    } else {
      return 0.60 + ((mbps - 100.0) / (maxMbps - 100.0)) * 0.40;
    }
  }

  void _startSpeedTest() {
    SoundService().playSpecialClick();
    _testSub?.cancel();

    setState(() {
      _stage = SpeedTestStage.pinging;
      _targetSpeedMbps = 0.0;
      _downloadMbps = 0.0;
      _uploadMbps = 0.0;
      _pingMs = 0;
      _jitterMs = 0;
      _testProgress = 0.0;
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
        _targetSpeedMbps = event['currentSpeed'] as double? ?? 0.0;

        if (event['result'] != null) {
          SoundService().playSuccess();
        }
      });
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _stage = SpeedTestStage.error;
          _targetSpeedMbps = 0.0;
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
      _targetSpeedMbps = 0.0;
      _testProgress = 0.0;
    });
  }

  /// In-App Network Refresh: flushes local sockets, resets radio session in-place
  /// (Does NOT throw user out to system settings)
  Future<void> _handleRefreshNetwork() async {
    if (_isRefreshingNetwork) return;
    SoundService().playSpecialClick();

    setState(() {
      _isRefreshingNetwork = true;
    });

    await _speedService.refreshNetwork();
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    await _fetchTelemetry();
    if (!mounted) return;
    setState(() {
      _isRefreshingNetwork = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cellular radio bearer & network sockets refreshed!',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// In-App Preferred Network Mode Selection & Force 5G
  Future<void> _selectNetworkMode(String modeKey) async {
    SoundService().playTap();
    setState(() {
      _selectedNetworkMode = modeKey;
    });

    String technicalMode = 'AUTO';
    String message = 'Global Auto Roaming enabled';
    if (modeKey == 'LOCK_5G') {
      technicalMode = 'NR_ONLY';
      message = 'Locked to 5G Standalone (NR Only)';
    } else if (modeKey == 'BATTERY_SAVER') {
      technicalMode = 'LTE_ONLY';
      message = 'Battery Saver: 4G LTE Only Active';
    } else if (modeKey == 'ULTRA_SAVER') {
      technicalMode = 'GSM_ONLY';
      message = 'Ultra Battery Saver: 2G GSM Only Active';
    }

    await _speedService.setPreferredNetworkMode(technicalMode);
    if (!mounted) return;

    _fetchTelemetry();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
        backgroundColor: widget.theme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Circular Radial Speedometer Card (Noise Meter style)
              _buildRadialSpeedometerCard(theme),

              const SizedBox(height: 14),

              // 2. Refresh Network & Force 5G Actions + Preferred Network Modes
              _buildNetworkActionsAndModes(theme),

              const SizedBox(height: 14),

              // 3. Cellular Radio 5G/4G Telemetry Card
              _buildCellularRadioCard(theme),

              const SizedBox(height: 14),

              // 4. Nearest Cell Tower Distance & Precision Triangulation Card
              _buildNearestTowerCard(theme),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HERO INDEPENDENT RADIAL SPEEDOMETER (NOISE METER ARCHITECTURE)
  // ===========================================================================
  Widget _buildRadialSpeedometerCard(StationeryTheme theme) {
    final isTesting = _stage == SpeedTestStage.pinging ||
        _stage == SpeedTestStage.downloading ||
        _stage == SpeedTestStage.uploading;

    Color stageColor;
    String stageText;
    switch (_stage) {
      case SpeedTestStage.idle:
        stageColor = theme.primary;
        stageText = 'READY';
        break;
      case SpeedTestStage.pinging:
        stageColor = const Color(0xFFF59E0B);
        stageText = 'PING LATENCY';
        break;
      case SpeedTestStage.downloading:
        stageColor = const Color(0xFF10B981);
        stageText = 'DOWNLOADING';
        break;
      case SpeedTestStage.uploading:
        stageColor = const Color(0xFF8B5CF6);
        stageText = 'UPLOADING';
        break;
      case SpeedTestStage.completed:
        stageColor = const Color(0xFF10B981);
        stageText = 'COMPLETED';
        break;
      case SpeedTestStage.error:
        stageColor = const Color(0xFFEF4444);
        stageText = 'TIMEOUT';
        break;
    }

    final double speedProgress =
        speedToFraction(_displaySpeedMbps, 1000.0).clamp(0.0, 1.0);
    final double peakProgress =
        speedToFraction(_peakHoldSpeedMbps, 1000.0).clamp(0.0, 1.0);

    return Column(
      children: [
        const SizedBox(height: 6),
        // Independent Larger Floating Radial Speedometer (Zero Container / Zero Border)
        Center(
          child: SmoothRadialGauge(
            size: 264,
            progress: speedProgress,
            externalPeakProgress: peakProgress,
            gaugeColor: stageColor,
            primaryColor: theme.primary,
            trackColor: theme.border.withValues(
              alpha: theme.isDark ? 0.45 : 0.65,
            ),
            smoothDamping: false,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displaySpeedMbps.toStringAsFixed(1),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: theme.text,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mbps',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: stageColor,
                      ),
                    ),
                    if (isTesting) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: stageColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stageText,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: stageColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Latency Metrics Grid (Ping, Jitter, Download, Upload)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isTesting ? stageColor.withValues(alpha: 0.45) : theme.border,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCol('PING', '$_pingMs ms', Icons.network_ping_rounded,
                  const Color(0xFFF59E0B), theme),
              _buildMetricDivider(theme),
              _buildMetricCol('JITTER', '$_jitterMs ms',
                  Icons.compare_arrows_rounded, const Color(0xFF3B82F6), theme),
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

        const SizedBox(height: 12),

        // Primary Speed Test Trigger Action (Clean UI Theme Color)
        BouncyTap(
          onTap: isTesting ? _stopSpeedTest : _startSpeedTest,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isTesting ? const Color(0xFFEF4444) : theme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isTesting ? const Color(0xFFEF4444) : theme.primary)
                      .withValues(alpha: 0.30),
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
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  isTesting ? 'STOP TEST' : 'START SPEED TEST',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon, Color color,
      StationeryTheme theme) {
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

  // ===========================================================================
  // 2. REFRESH NETWORK & FORCE 5G ACTIONS + PREFERRED NETWORK MODES
  // ===========================================================================
  Widget _buildNetworkActionsAndModes(StationeryTheme theme) {
    final is5gLocked = _selectedNetworkMode == 'LOCK_5G';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row with Refresh Network & Force 5G buttons side by side
          Row(
            children: [
              // A. Refresh Network Button (In-app, no external settings thrown)
              Expanded(
                child: BouncyTap(
                  onTap: _isRefreshingNetwork ? null : _handleRefreshNetwork,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isRefreshingNetwork)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Color(0xFF10B981),
                            ),
                          )
                        else
                          const Icon(Icons.refresh_rounded,
                              size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          _isRefreshingNetwork
                              ? 'Refreshing...'
                              : 'Refresh Network',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // B. Force 5G Toggle Action Button
              Expanded(
                child: BouncyTap(
                  onTap: () => _selectNetworkMode(
                      is5gLocked ? 'GLOBAL_AUTO' : 'LOCK_5G'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: is5gLocked
                          ? const Color(0xFF10B981)
                          : theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: is5gLocked
                            ? const Color(0xFF10B981)
                            : theme.primary.withValues(alpha: 0.35),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.five_g_rounded,
                          size: 18,
                          color: is5gLocked ? Colors.white : theme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          is5gLocked ? '5G Locked (SA)' : 'Force 5G',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: is5gLocked ? Colors.white : theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Preferred Network Modes Grid (4 distinct modes with meaning & network badges)
          Row(
            children: [
              Expanded(
                child: _buildNetworkModeTile(
                  modeKey: 'LOCK_5G',
                  title: 'Lock 5G',
                  meaning: '5G Standalone (NR)',
                  genBadge: '5G',
                  techAcronym: 'NR only',
                  accentColor: const Color(0xFF10B981),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNetworkModeTile(
                  modeKey: 'BATTERY_SAVER',
                  title: 'Battery Saver',
                  meaning: '4G LTE Stable',
                  genBadge: '4G',
                  techAcronym: 'LTE only',
                  accentColor: const Color(0xFFF59E0B),
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildNetworkModeTile(
                  modeKey: 'ULTRA_SAVER',
                  title: 'Ultra Saver',
                  meaning: 'Low Power Emergency',
                  genBadge: '2G',
                  techAcronym: 'GSM only',
                  accentColor: const Color(0xFFEF4444),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNetworkModeTile(
                  modeKey: 'GLOBAL_AUTO',
                  title: 'Auto Roaming',
                  meaning: 'Best Coverage',
                  genBadge: '5G/4G/2G',
                  techAcronym: 'NR/LTE/GSM',
                  accentColor: const Color(0xFF3B82F6),
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkModeTile({
    required String modeKey,
    required String title,
    required String meaning,
    required String genBadge,
    required String techAcronym,
    required Color accentColor,
    required StationeryTheme theme,
  }) {
    final isSelected = _selectedNetworkMode == modeKey;

    return BouncyTap(
      onTap: () => _selectNetworkMode(modeKey),
      scaleFraction: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : theme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : theme.border,
            width: isSelected ? 1.3 : 1.0,
          ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? accentColor : theme.text,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    genBadge,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              meaning,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              techAcronym,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? accentColor
                    : theme.textSecondary.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. CELLULAR RADIO 5G/4G TELEMETRY CARD
  // ===========================================================================
  Widget _buildCellularRadioCard(StationeryTheme theme) {
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
                    Icons.cell_tower_rounded,
                    size: 19,
                    color: theme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CELLULAR RADIO 5G/4G',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cell.is5G ? '5G SA ACTIVE' : '4G LTE-A',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: theme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildSpecRow(
              'Carrier', cell.carrier, 'Radio Tech', cell.networkType, theme),
          const SizedBox(height: 7),
          _buildSpecRow('5G NR State', cell.nrState, 'NR Frequency',
              cell.nrFrequency, theme),
          const SizedBox(height: 7),
          _buildSpecRow('Operating Band', cell.bandName, 'Signal Quality',
              '${cell.rsrp} dBm (RSRQ: ${cell.rsrq})', theme),
          const SizedBox(height: 7),
          _buildSpecRow('Cell Identifiers', 'CID: ${cell.cid} • PCI: ${cell.pci}',
              'TAC / Area', 'TAC: ${cell.tac}', theme),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String lbl1, String val1, String lbl2, String val2,
      StationeryTheme theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lbl1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val1,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
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
        const SizedBox(width: 7),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lbl2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val2,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
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

  // ===========================================================================
  // 4. NEAREST CELL TOWER DISTANCE & RF TRIANGULATION CARD
  // ===========================================================================
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
              const Icon(Icons.radar_rounded,
                  size: 19, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'NEAREST CELL TOWER DISTANCE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.cell_tower_rounded,
                    color: Color(0xFF10B981), size: 28),
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
                          distanceMeters < 1000
                              ? '$distanceMeters'
                              : (distanceMeters / 1000.0).toStringAsFixed(2),
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
                    const SizedBox(height: 2),
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.near_me_rounded,
                    size: 13, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${cell.sector} · Timing Advance: TA=${cell.timingAdvance} · 3GPP 38.901 RF Path-Loss',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
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
}
