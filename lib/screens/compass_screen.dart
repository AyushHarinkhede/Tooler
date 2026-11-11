import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../services/sensor_service.dart';
import '../widgets_3d/stationery_3d_modal.dart';

enum CompassDisplayMode {
  autoDetect,
  lockCompass,
  lockLeveler,
}

class CompassScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CompassScreen({super.key, required this.theme});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<CompassReading>? _sensorSub;
  CompassReading _reading = CompassReading.empty;

  CompassDisplayMode _mode = CompassDisplayMode.autoDetect;

  // Manual fallback mode if testing on emulator
  final bool _manualOverride = false;
  final double _manualHeading = 45.0;
  final double _manualPitch = 0.0;
  final double _manualRoll = 0.0;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initSensors();
  }

  void _initSensors() {
    final service = SensorService();
    service.start();
    _sensorSub = service.readingStream.listen((data) {
      if (mounted && !_manualOverride) {
        setState(() => _reading = data);
      }
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    SensorService().stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Determines whether to display Compass or Leveler
  bool get _shouldShowLeveler {
    if (_mode == CompassDisplayMode.lockLeveler) return true;
    if (_mode == CompassDisplayMode.lockCompass) return false;
    // In Auto Mode: show Leveler when phone is straight/upright, Compass when flat
    return _reading.isUpright;
  }

  void _recalibrateSensor() {
    SoundService().playClick();
    SensorService().recalibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Sensors Zeroed & Re-calibrated! Wave phone in Figure-8."),
        backgroundColor: widget.theme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCalibrationModal() {
    SoundService().playClick();
    Stationery3DModal.show(
      context: context,
      title: "Compass Sensor Calibration",
      subtitle: "Calibrate magnetometer & accelerometer",
      theme: widget.theme,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.theme.border, width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.screen_rotation_rounded, size: 48, color: Color(0xFF2563EB)),
                const SizedBox(height: 10),
                Text(
                  "Wave your phone smoothly in a Figure-8 motion in the air 3 to 4 times.",
                  textAlign: TextAlign.center,
                  style: widget.theme.fontDoodle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "This recalibrates the geomagnetic sensor against local electrical interference and locks true heading.",
                  textAlign: TextAlign.center,
                  style: widget.theme.fontDoodle(
                    fontSize: 12,
                    color: widget.theme.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip(
                label: "Magnetic Field",
                val: "${_reading.magneticStrength.toStringAsFixed(1)} µT",
              ),
              _buildMetricChip(
                label: "Sensor State",
                val: _reading.accuracy.name.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _recalibrateSensor();
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Zero & Re-Calibrate Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({required String label, required String val}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.kalam(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.7))),
          Text(val, style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double activeHeading = _manualOverride ? _manualHeading : _reading.heading;
    final double headingRad = -activeHeading * (math.pi / 180.0);
    final String directionText = _reading.cardinal;

    final isLevelerActive = _shouldShowLeveler;

    return Scaffold(
      backgroundColor: widget.theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isLevelerActive ? "Precision Spirit Level" : "Digital Precision Compass",
          style: GoogleFonts.architectsDaughter(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: widget.theme.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Calibrate Sensors",
            onPressed: _showCalibrationModal,
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // 1. Mode Selector Toolbar (Auto vs Lock Compass vs Lock Leveler)
                  _buildModeSelectorToolbar(),

                  const SizedBox(height: 12),

                  // 2. Dynamic Status Banner (Flat / Straight & Orientation)
                  _buildOrientationStatusBanner(isLevelerActive),

                  const SizedBox(height: 14),

                  // 3. Primary Readout Card (Degrees, Direction, or Tilt Angle)
                  _buildReadoutCard(activeHeading, directionText, isLevelerActive),

                  const SizedBox(height: 18),

                  // 4. MAIN CIRCLE INSTRUMENT:
                  // Shows Compass with Plus Bar (+ Front/Back, Left/Right, NO DOT) when flat
                  // Shows Spirit Level Line & Bubble Dot when straight/upright
                  _buildMainInstrumentCircle(headingRad, isLevelerActive),

                  const SizedBox(height: 20),

                  // 5. Navigation Direction Coordinates & Quick Controls
                  _buildInstrumentCoordinatesBar(isLevelerActive),

                  const SizedBox(height: 16),

                  // 6. Sensor Fusion Telemetry Dashboard
                  _buildTelemetryDashboard(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. MODE SELECTOR TOOLBAR ---
  Widget _buildModeSelectorToolbar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.theme.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.theme.border.withValues(alpha: 0.2),
            offset: const Offset(2, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildModeButton("🔄 Auto", CompassDisplayMode.autoDetect),
          const SizedBox(width: 4),
          _buildModeButton("🧭 Compass", CompassDisplayMode.lockCompass),
          const SizedBox(width: 4),
          _buildModeButton("⚖️ Leveler", CompassDisplayMode.lockLeveler),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, CompassDisplayMode mode) {
    final bool isSelected = (_mode == mode);
    return Expanded(
      child: InkWell(
        onTap: () {
          SoundService().playClick();
          setState(() => _mode = mode);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.theme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : widget.theme.text,
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. ORIENTATION STATUS BANNER ---
  Widget _buildOrientationStatusBanner(bool isLevelerActive) {
    final bool isUpright = _reading.isUpright;
    final String modeLabel = _mode == CompassDisplayMode.autoDetect
        ? "Auto Detect: ${isUpright ? '📱 Straight/Upright' : '📱 Flat Horizontal'}"
        : (_mode == CompassDisplayMode.lockCompass ? "🔒 Compass Locked" : "🔒 Leveler Locked");

    final Color statusColor = isLevelerActive
        ? (_reading.roll.abs() < 1.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
        : const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isLevelerActive ? Icons.straighten_rounded : Icons.explore_outlined,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Text(
                modeLabel,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          Text(
            isLevelerActive
                ? (_reading.roll.abs() < 1.0 ? "PERFECT LEVEL ✅" : "TILTED 📐")
                : "TILT-COMPENSATED 🧭",
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. DYNAMIC READOUT CARD ---
  Widget _buildReadoutCard(double activeHeading, String directionText, bool isLevelerActive) {
    if (isLevelerActive) {
      final double rollAngle = _reading.roll;
      final bool isBalanced = rollAngle.abs() < 0.6;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: widget.theme.doodleCard(borderWidth: 2.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "HORIZON INCLINE",
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.text.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  isBalanced
                      ? "0.0° Level"
                      : "${rollAngle > 0 ? '+' : ''}${rollAngle.toStringAsFixed(1)}°",
                  style: GoogleFonts.architectsDaughter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isBalanced ? const Color(0xFF10B981) : const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isBalanced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isBalanced
                    ? "BALANCED"
                    : (rollAngle < 0 ? "TILTED LEFT" : "TILTED RIGHT"),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Compass Readout
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: widget.theme.doodleCard(borderWidth: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "HEADING (AZIMUTH)",
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.text.withValues(alpha: 0.6),
                ),
              ),
              Text(
                "${activeHeading.toStringAsFixed(0)}°",
                style: GoogleFonts.architectsDaughter(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF4757),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "CARDINAL POINT",
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.text.withValues(alpha: 0.6),
                ),
              ),
              Text(
                directionText.toUpperCase(),
                style: GoogleFonts.architectsDaughter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. MAIN CIRCLE INSTRUMENT ---
  Widget _buildMainInstrumentCircle(double headingRad, bool isLevelerActive) {
    const double dialSize = 290.0;

    return Center(
      child: Container(
        width: dialSize,
        height: dialSize,
        decoration: BoxDecoration(
          color: widget.theme.cardBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isLevelerActive && _reading.roll.abs() < 0.6
                ? const Color(0xFF10B981)
                : widget.theme.border,
            width: 4.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isLevelerActive && _reading.roll.abs() < 0.6
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : widget.theme.border.withValues(alpha: 0.35),
              offset: const Offset(4, 7),
              blurRadius: isLevelerActive && _reading.roll.abs() < 0.6 ? 12 : 0,
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLevelerActive) ...[
                // LEVELER VIEW (Spirit Horizon Line with Sliding Bubble Dot)
                CustomPaint(
                  size: const Size(dialSize, dialSize),
                  painter: _SpiritLevelInstrumentPainter(
                    roll: _manualOverride ? _manualRoll : _reading.roll,
                    pitch: _manualOverride ? _manualPitch : _reading.pitch,
                    theme: widget.theme,
                  ),
                ),
              ] else ...[
                // COMPASS VIEW: Rotating Dial with Degrees
                Transform.rotate(
                  angle: headingRad,
                  child: CustomPaint(
                    size: const Size(dialSize, dialSize),
                    painter: _CompassDialPainter(theme: widget.theme),
                  ),
                ),

                // FIXED PLUS BAR (+) - Vertical (Front/Back) & Horizontal (Left/Right) with End Points
                // NO DOT AT CENTER!
                CustomPaint(
                  size: const Size(dialSize, dialSize),
                  painter: _CompassPlusBarPainter(theme: widget.theme),
                ),

                // Stationery North/South Pointer Needle
                Transform.rotate(
                  angle: headingRad,
                  child: CustomPaint(
                    size: const Size(dialSize, dialSize),
                    painter: _CompassNeedlePainter(theme: widget.theme),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. INSTRUMENT COORDINATES & STATUS BAR ---
  Widget _buildInstrumentCoordinatesBar(bool isLevelerActive) {
    if (isLevelerActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: widget.theme.doodleCard(borderWidth: 2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAxisIndicator("Lateral Roll", _reading.roll, "°"),
            Container(width: 1.5, height: 26, color: widget.theme.border),
            _buildAxisIndicator("Plumb Pitch", _reading.pitch, "°"),
          ],
        ),
      );
    }

    // Compass Axis Reference Points (Front, Back, Left, Right)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: widget.theme.doodleCard(borderWidth: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDirBadge("▲ FRONT", "Heading Forward", const Color(0xFFFF4757)),
          _buildDirBadge("◀ LEFT", "West 90° Port", widget.theme.primary),
          _buildDirBadge("RIGHT ▶", "East 90° Stbd", widget.theme.secondary),
          _buildDirBadge("▼ BACK", "Reverse Azimuth", const Color(0xFF1E293B)),
        ],
      ),
    );
  }

  Widget _buildDirBadge(String label, String sub, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 8.5,
            color: widget.theme.text.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildAxisIndicator(String label, double val, String unit) {
    final bool nearZero = val.abs() < 1.0;
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.robotoMono(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.7)),
        ),
        Text(
          "${val > 0 ? '+' : ''}${val.toStringAsFixed(1)}$unit",
          style: GoogleFonts.robotoMono(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: nearZero ? const Color(0xFF10B981) : widget.theme.primary,
          ),
        ),
      ],
    );
  }

  // --- 6. TELEMETRY DASHBOARD ---
  Widget _buildTelemetryDashboard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: widget.theme.doodleCard(borderWidth: 2.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    "Sensor Fusion & Calibration",
                    style: GoogleFonts.kalam(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.text,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _recalibrateSensor,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.primary, width: 1.2),
                  ),
                  child: Text(
                    "Re-Zero 🔄",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip(
                label: "Magnetic Vector",
                val: "${_reading.magneticStrength.toStringAsFixed(1)} µT",
              ),
              _buildMetricChip(
                label: "Gyro Z Speed",
                val: "${_reading.gyroZ.toStringAsFixed(1)} °/s",
              ),
              _buildMetricChip(
                label: "Accuracy",
                val: _reading.accuracy.name.toUpperCase(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: COMPASS DIAL (DEGREES & CARDINALS AROUND EDGE)
// =============================================================================
class _CompassDialPainter extends CustomPainter {
  final StationeryTheme theme;
  _CompassDialPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 14;

    final Paint tickPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;

    final Paint majorPaint = Paint()
      ..color = theme.border
      ..strokeWidth = 2.2;

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

    for (int deg = 0; deg < 360; deg += 5) {
      final double rad = deg * math.pi / 180.0;
      final bool isCardinal = (deg % 90 == 0);
      final bool isMajor = (deg % 30 == 0);

      final double tickLen = isCardinal ? 14 : (isMajor ? 9 : 5);

      final Offset p1 = Offset(
        center.dx + (radius - tickLen) * math.sin(rad),
        center.dy - (radius - tickLen) * math.cos(rad),
      );
      final Offset p2 = Offset(
        center.dx + radius * math.sin(rad),
        center.dy - radius * math.cos(rad),
      );

      canvas.drawLine(p1, p2, isMajor ? majorPaint : tickPaint);

      // Cardinal Letters (N, E, S, W)
      if (isCardinal) {
        String label = 'N';
        Color color = const Color(0xFFFF4757);
        if (deg == 90) {
          label = 'E';
          color = theme.text;
        }
        if (deg == 180) {
          label = 'S';
          color = theme.text;
        }
        if (deg == 270) {
          label = 'W';
          color = theme.text;
        }

        tp.text = TextSpan(
          text: label,
          style: GoogleFonts.architectsDaughter(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        );
        tp.layout();

        final double textRad = (radius - 24);
        final Offset tpPos = Offset(
          center.dx + textRad * math.sin(rad) - (tp.width / 2),
          center.dy - textRad * math.cos(rad) - (tp.height / 2),
        );
        tp.paint(canvas, tpPos);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) => false;
}

// =============================================================================
// CUSTOM PAINTER: PLUS BAR (+) CARRYING VERTICAL (FRONT-BACK) & HORIZONTAL (LEFT-RIGHT)
// NO DOT AT CENTER!
// =============================================================================
class _CompassPlusBarPainter extends CustomPainter {
  final StationeryTheme theme;
  _CompassPlusBarPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 40;

    // Crosshair axis paint
    final Paint axisPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.50)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square;

    final Paint accentFrontPaint = Paint()
      ..color = const Color(0xFFFF4757)
      ..strokeWidth = 3.0;

    final Paint barEndPaint = Paint()
      ..color = theme.border
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // 1. VERTICAL LINE (FRONT - BACK)
    // Top is Front (toward phone top), Bottom is Back
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      axisPaint,
    );

    // Front bar end point (crossbar on top)
    canvas.drawLine(
      Offset(center.dx - 12, center.dy - radius),
      Offset(center.dx + 12, center.dy - radius),
      accentFrontPaint,
    );

    // Back bar end point (crossbar on bottom)
    canvas.drawLine(
      Offset(center.dx - 12, center.dy + radius),
      Offset(center.dx + 12, center.dy + radius),
      barEndPaint,
    );

    // 2. HORIZONTAL LINE (LEFT - RIGHT)
    // Left is Left (Port), Right is Right (Starboard)
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      axisPaint,
    );

    // Left bar end point (crossbar on left)
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - 12),
      Offset(center.dx - radius, center.dy + 12),
      barEndPaint,
    );

    // Right bar end point (crossbar on right)
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - 12),
      Offset(center.dx + radius, center.dy + 12),
      barEndPaint,
    );

    // 3. Tick marks along the Plus Bar (+)
    final Paint tickPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;

    for (double step = 30; step < radius; step += 30) {
      // Ticks on vertical line
      canvas.drawLine(Offset(center.dx - 4, center.dy - step), Offset(center.dx + 4, center.dy - step), tickPaint);
      canvas.drawLine(Offset(center.dx - 4, center.dy + step), Offset(center.dx + 4, center.dy + step), tickPaint);

      // Ticks on horizontal line
      canvas.drawLine(Offset(center.dx - step, center.dy - 4), Offset(center.dx - step, center.dy + 4), tickPaint);
      canvas.drawLine(Offset(center.dx + step, center.dy - 4), Offset(center.dx + step, center.dy + 4), tickPaint);
    }

    // 4. Center Crosshair Reticle Ring (NO DOT! Clean open target ring)
    final Paint ringPaint = Paint()
      ..color = theme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 12, ringPaint);

    // 5. Direction Labels painted directly onto the ends
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, Offset pos, Color color) {
      tp.text = TextSpan(
        text: text,
        style: GoogleFonts.robotoMono(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(pos.dx - (tp.width / 2), pos.dy - (tp.height / 2)));
    }

    drawLabel("▲ FRONT", Offset(center.dx, center.dy - radius - 12), const Color(0xFFFF4757));
    drawLabel("▼ BACK", Offset(center.dx, center.dy + radius + 12), theme.text);
    drawLabel("◀ LEFT", Offset(center.dx - radius - 18, center.dy), theme.text);
    drawLabel("RIGHT ▶", Offset(center.dx + radius + 20, center.dy), theme.text);
  }

  @override
  bool shouldRepaint(covariant _CompassPlusBarPainter oldDelegate) => false;
}

// =============================================================================
// CUSTOM PAINTER: COMPASS POINTER NEEDLE
// =============================================================================
class _CompassNeedlePainter extends CustomPainter {
  final StationeryTheme theme;
  _CompassNeedlePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double halfLen = (size.width / 2) - 52;

    // North Pointer (Red Coral Needle Tip)
    final Path northPath = Path()
      ..moveTo(center.dx - 8, center.dy)
      ..lineTo(center.dx, center.dy - halfLen)
      ..lineTo(center.dx + 8, center.dy)
      ..close();
    final Paint northPaint = Paint()..color = const Color(0xFFFF4757);
    canvas.drawPath(northPath, northPaint);

    // South Pointer (Charcoal Lead Tip)
    final Path southPath = Path()
      ..moveTo(center.dx - 8, center.dy)
      ..lineTo(center.dx, center.dy + halfLen)
      ..lineTo(center.dx + 8, center.dy)
      ..close();
    final Paint southPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawPath(southPath, southPaint);

    // Border around needle
    final Paint borderPaint = Paint()
      ..color = theme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(northPath, borderPaint);
    canvas.drawPath(southPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) => false;
}

// =============================================================================
// CUSTOM PAINTER: PRECISION SPIRIT LEVEL INSTRUMENT (LEVELER)
// Shows Horizon Line + Sliding Bubble Dot
// =============================================================================
class _SpiritLevelInstrumentPainter extends CustomPainter {
  final double roll;
  final double pitch;
  final StationeryTheme theme;

  _SpiritLevelInstrumentPainter({
    required this.roll,
    required this.pitch,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double tubeWidth = size.width - 50;
    const double tubeHeight = 36.0;

    final bool isBalanced = roll.abs() < 0.6;
    final Color activeColor = isBalanced ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    // 1. Vertical Plumb Line (Pitch)
    final Paint plumbPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx, 20),
      Offset(center.dx, size.height - 20),
      plumbPaint,
    );

    // 2. Horizon Level Spirit Tube (Background Bar)
    final Rect tubeRect = Rect.fromCenter(
      center: center,
      width: tubeWidth,
      height: tubeHeight,
    );
    final RRect tubeRRect = RRect.fromRectAndRadius(tubeRect, const Radius.circular(18));

    // Tube background fill
    final Paint tubeBgPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(tubeRRect, tubeBgPaint);

    // Tube border
    final Paint tubeBorderPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(tubeRRect, tubeBorderPaint);

    // Center Reference Goalposts (| |)
    const double goalWidth = 26.0;
    final Paint goalPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(center.dx - goalWidth / 2, center.dy - tubeHeight / 2),
      Offset(center.dx - goalWidth / 2, center.dy + tubeHeight / 2),
      goalPaint,
    );
    canvas.drawLine(
      Offset(center.dx + goalWidth / 2, center.dy - tubeHeight / 2),
      Offset(center.dx + goalWidth / 2, center.dy + tubeHeight / 2),
      goalPaint,
    );

    // Graduation ticks along the tube
    final Paint tickPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;

    for (int deg = -20; deg <= 20; deg += 5) {
      if (deg == 0) continue;
      final double xPos = center.dx + (deg / 20.0) * (tubeWidth / 2 - 20);
      final double tickH = (deg % 10 == 0) ? 14 : 8;
      canvas.drawLine(
        Offset(xPos, center.dy - tickH / 2),
        Offset(xPos, center.dy + tickH / 2),
        tickPaint,
      );
    }

    // 3. Sliding Spirit Bubble Dot
    // Map roll angle [-25°, 25°] to tube horizontal range
    final double maxBubbleTravel = (tubeWidth / 2) - 20;
    final double normalizedRoll = (roll / 20.0).clamp(-1.0, 1.0);
    final double bubbleX = center.dx + normalizedRoll * maxBubbleTravel;

    // Bubble Glow & Shadow
    canvas.drawCircle(
      Offset(bubbleX, center.dy),
      14,
      Paint()..color = activeColor.withValues(alpha: 0.35),
    );

    // Bubble Body (Vibrant Dot)
    final Paint bubblePaint = Paint()..color = activeColor;
    canvas.drawCircle(Offset(bubbleX, center.dy), 11, bubblePaint);

    // Bubble Inner Highlight
    final Paint highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(bubbleX - 3, center.dy - 3), 3.5, highlightPaint);

    // 4. Degree readout badge below level line
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    final String label = isBalanced
        ? "0.0° LEVEL"
        : "${roll > 0 ? '+' : ''}${roll.toStringAsFixed(1)}°";

    tp.text = TextSpan(
      text: label,
      style: GoogleFonts.robotoMono(
        color: activeColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy + 40));
  }

  @override
  bool shouldRepaint(covariant _SpiritLevelInstrumentPainter oldDelegate) {
    return oldDelegate.roll != roll || oldDelegate.pitch != pitch;
  }
}
