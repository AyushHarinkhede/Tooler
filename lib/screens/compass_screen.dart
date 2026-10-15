import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../services/sensor_service.dart';
import '../widgets_3d/stationery_3d_modal.dart';
import '../widgets_3d/bouncy_tap.dart';

enum CompassDisplayMode {
  compass,
  leveler,
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

  CompassDisplayMode _mode = CompassDisplayMode.compass;
  bool _autoDetectOrientation = false; // Optional auto-switch when tilted upright
  bool _wasBalanced = false;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initSensors();
  }

  void _initSensors() {
    final service = SensorService();
    service.start();
    _sensorSub = service.readingStream.listen((data) {
      if (!mounted) return;

      // Haptic bump when user reaches level
      final bool isBalanced = (data.roll.abs() < 0.6 && data.pitch.abs() < 0.6);
      if (isBalanced && !_wasBalanced && _mode == CompassDisplayMode.leveler) {
        HapticFeedback.mediumImpact();
        SoundService().playSuccess();
      }
      _wasBalanced = isBalanced;

      setState(() {
        _reading = data;
        if (_autoDetectOrientation) {
          if (data.isUpright && _mode != CompassDisplayMode.leveler) {
            _mode = CompassDisplayMode.leveler;
          } else if (!data.isUpright && _mode != CompassDisplayMode.compass) {
            _mode = CompassDisplayMode.compass;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    SensorService().stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _recalibrateSensor() {
    SoundService().playKey();
    HapticFeedback.lightImpact();
    SensorService().recalibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Sensors Zeroed & Re-calibrated! Wave phone in Figure-8.",
          style: widget.theme.fontDisplay(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: widget.theme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCalibrationModal() {
    SoundService().playKey();
    HapticFeedback.mediumImpact();
    Stationery3DModal.show(
      context: context,
      title: "Sensor Calibration",
      subtitle: null,
      theme: widget.theme,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.theme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.theme.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                _AnimatedFigure8Phone(theme: widget.theme),
                const SizedBox(height: 10),
                Text(
                  "Wave in Figure-8",
                  textAlign: TextAlign.center,
                  style: widget.theme.fontDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Move phone 3 to 4 times in the air",
                  textAlign: TextAlign.center,
                  style: widget.theme.fontDisplay(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildMetricChip(
            label: "Magnetic Field Strength",
            val: "${_reading.magneticStrength.toStringAsFixed(1)} µT",
            highlight: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _recalibrateSensor();
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text("Recalibrate Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String val,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? widget.theme.primary : widget.theme.border,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: widget.theme.fontDisplay(
              fontSize: 11,
              color: widget.theme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: widget.theme.fontMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlight ? widget.theme.primary : widget.theme.text,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double activeHeading = _reading.heading;
    final double headingRad = -activeHeading * (math.pi / 180.0);
    final String directionText = _reading.cardinal;

    final bool isLeveler = (_mode == CompassDisplayMode.leveler);

    return Scaffold(
      backgroundColor: widget.theme.bg,
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
                  // 1. Mode Switch (Compass vs Leveler) & Auto Tilt Mode Button
                  Row(
                    children: [
                      Expanded(child: _buildUnifiedModeSwitch(isLeveler)),
                      const SizedBox(width: 8),
                      _buildAutoModeButton(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Primary Readout Card (Matches between both modes with theme color)
                  _buildPrimaryReadoutCard(activeHeading, directionText, isLeveler),

                  const SizedBox(height: 18),

                  // 3. MAIN CIRCLE INSTRUMENT (Precision Dual-Ring Bezel)
                  _buildMainInstrumentCircle(headingRad, isLeveler),

                  const SizedBox(height: 20),

                  // 4. Sensor Fusion Telemetry Dashboard
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

  // --- 1. UNIFIED MODE SELECTOR SWITCH ---
  Widget _buildUnifiedModeSwitch(bool isLeveler) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.theme.border.withValues(alpha: 0.25),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildModeTab(
            title: "Compass",
            icon: Icons.explore_rounded,
            isSelected: !isLeveler,
            onTap: () {
              SoundService().playKey();
              HapticFeedback.selectionClick();
              setState(() => _mode = CompassDisplayMode.compass);
            },
          ),
          const SizedBox(width: 4),
          _buildModeTab(
            title: "Leveler",
            icon: Icons.straighten_rounded,
            isSelected: isLeveler,
            onTap: () {
              SoundService().playKey();
              HapticFeedback.selectionClick();
              setState(() => _mode = CompassDisplayMode.leveler);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? widget.theme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.theme.primary.withValues(alpha: 0.35),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : widget.theme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: widget.theme.fontDisplay(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : widget.theme.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- AUTO ORIENTATION TILT SWITCH BUTTON ---
  Widget _buildAutoModeButton() {
    final bool isActive = _autoDetectOrientation;
    return BouncyTap(
      onTap: () {
        SoundService().playKey();
        HapticFeedback.selectionClick();
        setState(() {
          _autoDetectOrientation = !_autoDetectOrientation;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _autoDetectOrientation ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _autoDetectOrientation
                      ? "Auto Tilt Detection ON: Device switches dynamically!"
                      : "Auto Tilt Detection OFF: Manual mode locked.",
                  style: widget.theme.fontDisplay(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            backgroundColor: widget.theme.primary,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      scaleFraction: 0.90,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? widget.theme.primary : widget.theme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? widget.theme.primary : widget.theme.border,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? widget.theme.primary.withValues(alpha: 0.35)
                  : widget.theme.border.withValues(alpha: 0.25),
              offset: const Offset(0, 3),
              blurRadius: isActive ? 8 : 4,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.screen_rotation_rounded,
              size: 20,
              color: isActive ? Colors.white : widget.theme.primary,
            ),
            const SizedBox(height: 1),
            Text(
              "AUTO",
              style: widget.theme.fontMono(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : widget.theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. PRIMARY READOUT CARD ---
  Widget _buildPrimaryReadoutCard(
    double activeHeading,
    String directionText,
    bool isLeveler,
  ) {
    if (isLeveler) {
      final double roll = _reading.roll;
      final double pitch = _reading.pitch;
      final bool isBalanced = (roll.abs() < 0.6 && pitch.abs() < 0.6);
      final double maxIncline = math.max(roll.abs(), pitch.abs());

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: widget.theme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBalanced
                ? widget.theme.primary
                : widget.theme.border,
            width: isBalanced ? 2.5 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isBalanced
                  ? widget.theme.primary.withValues(alpha: 0.25)
                  : widget.theme.border.withValues(alpha: 0.25),
              offset: const Offset(0, 4),
              blurRadius: isBalanced ? 12 : 6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SURFACE INCLINATION",
                  style: widget.theme.fontMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBalanced ? "0.0° Level" : "${maxIncline.toStringAsFixed(1)}°",
                  style: widget.theme.fontDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.primary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isBalanced
                    ? widget.theme.primary
                    : widget.theme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.theme.primary,
                  width: 1.5,
                ),
              ),
              child: Text(
                isBalanced
                    ? "PERFECT LEVEL ✅"
                    : (roll.abs() > pitch.abs()
                        ? (roll < 0 ? "TILT LEFT ◀" : "TILT RIGHT ▶")
                        : (pitch < 0 ? "TILT BACK ▼" : "TILT FRONT ▲")),
                style: widget.theme.fontDisplay(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isBalanced ? Colors.white : widget.theme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Compass Readout Card
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.theme.border, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: widget.theme.border.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "HEADING (AZIMUTH)",
                style: widget.theme.fontMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${activeHeading.toStringAsFixed(0)}°",
                style: widget.theme.fontDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.primary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "CARDINAL POINT",
                style: widget.theme.fontMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.theme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.theme.primary, width: 1.2),
                ),
                child: Text(
                  directionText.toUpperCase(),
                  style: widget.theme.fontDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: widget.theme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. MAIN CIRCLE INSTRUMENT ---
  Widget _buildMainInstrumentCircle(double headingRad, bool isLeveler) {
    const double dialSize = 300.0;
    final bool isBalanced = (_reading.roll.abs() < 0.6 && _reading.pitch.abs() < 0.6);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: dialSize,
        height: dialSize,
        decoration: BoxDecoration(
          color: widget.theme.cardBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isLeveler && isBalanced
                ? widget.theme.primary
                : widget.theme.border,
            width: isLeveler && isBalanced ? 4.5 : 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLeveler && isBalanced
                  ? widget.theme.primary.withValues(alpha: 0.4)
                  : widget.theme.border.withValues(alpha: 0.35),
              offset: const Offset(0, 6),
              blurRadius: isLeveler && isBalanced ? 18 : 10,
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLeveler) ...[
                // LEVELER VIEW: Bullseye Spirit Level & Crosshair Horizon
                CustomPaint(
                  size: const Size(dialSize, dialSize),
                  painter: _BullseyeLevelerPainter(
                    roll: _reading.roll,
                    pitch: _reading.pitch,
                    theme: widget.theme,
                    pulseProgress: _pulseCtrl.value,
                  ),
                ),
              ] else ...[
                // COMPASS VIEW: Rotating Dial with Degrees
                Transform.rotate(
                  angle: headingRad,
                  child: CustomPaint(
                    size: const Size(dialSize, dialSize),
                    painter: _UnifiedCompassDialPainter(theme: widget.theme),
                  ),
                ),

                // FIXED RETICLE & PLUS CROSSHAIR
                CustomPaint(
                  size: const Size(dialSize, dialSize),
                  painter: _UnifiedPlusCrosshairPainter(theme: widget.theme),
                ),

                // Needle with Primary Theme Tone on North
                Transform.rotate(
                  angle: headingRad,
                  child: CustomPaint(
                    size: const Size(dialSize, dialSize),
                    painter: _UnifiedCompassNeedlePainter(theme: widget.theme),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. TELEMETRY DASHBOARD (With Sensor Calibration Button) ---
  Widget _buildTelemetryDashboard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sensors_rounded,
                    size: 18,
                    color: widget.theme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Sensor Fusion Telemetry",
                    style: widget.theme.fontDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.text,
                    ),
                  ),
                ],
              ),
              BouncyTap(
                onTap: _showCalibrationModal,
                scaleFraction: 0.92,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.theme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: widget.theme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        "Sensor Calibration",
                        style: widget.theme.fontDisplay(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
                label: "Gyro Z Velocity",
                val: "${_reading.gyroZ.toStringAsFixed(1)} °/s",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LIVE ANIMATED FIGURE-8 HAND & SMARTPHONE FOR SENSOR CALIBRATION
// Authentic hand gripping phone traveling a vertical infinity loop in 3D perspective
// =============================================================================
class _AnimatedFigure8Phone extends StatefulWidget {
  final StationeryTheme theme;
  const _AnimatedFigure8Phone({required this.theme});

  @override
  State<_AnimatedFigure8Phone> createState() => _AnimatedFigure8PhoneState();
}

class _AnimatedFigure8PhoneState extends State<_AnimatedFigure8Phone>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(220, 160),
          painter: _Figure8HandPainter(
            progress: _ctrl.value,
            theme: widget.theme,
          ),
        );
      },
    );
  }
}

class _Figure8HandPainter extends CustomPainter {
  final double progress;
  final StationeryTheme theme;

  _Figure8HandPainter({
    required this.progress,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    const double rx = 52.0;
    const double ry = 46.0;

    // 1. Draw dashed/dotted vertical Figure-8 path
    final pathPaint = Paint()
      ..color = theme.primary.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final Path figure8Path = Path();
    const int steps = 100;
    for (int i = 0; i <= steps; i++) {
      final double t = (i / steps) * 2 * math.pi;
      final double px = cx + rx * math.sin(2 * t);
      final double py = cy - ry * math.sin(t);
      if (i == 0) {
        figure8Path.moveTo(px, py);
      } else {
        figure8Path.lineTo(px, py);
      }
    }
    canvas.drawPath(figure8Path, pathPaint);

    // 2. Guide arrows along the Figure-8 path
    final arrowPaint = Paint()
      ..color = theme.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final arrowAngles = [math.pi * 0.25, math.pi * 0.75, math.pi * 1.25, math.pi * 1.75];
    for (final t in arrowAngles) {
      final double px = cx + rx * math.sin(2 * t);
      final double py = cy - ry * math.sin(t);
      // Tangent velocity
      final double dx = 2 * rx * math.cos(2 * t);
      final double dy = -ry * math.cos(t);
      final double angle = math.atan2(dy, dx);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle);
      final arrowPath = Path()
        ..moveTo(-4, -4)
        ..lineTo(3, 0)
        ..lineTo(-4, 4);
      canvas.drawPath(arrowPath, arrowPaint);
      canvas.restore();
    }

    // 3. Current position of hand & phone
    final double currentT = progress * 2 * math.pi;
    final double handX = cx + rx * math.sin(2 * currentT);
    final double handY = cy - ry * math.sin(currentT);

    // Bank / twist angle as phone navigates the 3D figure-8 curve
    final double bankAngle = -0.38 * math.cos(2 * currentT);

    canvas.save();
    canvas.translate(handX, handY);
    canvas.rotate(bankAngle);

    // Phone dimensions
    const double pw = 30.0;
    const double ph = 52.0;

    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: pw, height: ph),
      const Radius.circular(6.5),
    );

    // Drop shadow under phone
    canvas.drawRRect(
      phoneRect.shift(const Offset(2, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.20),
    );

    // 4. Hand behind phone (Sleeve + Wrist + Palm)
    final sleevePaint = Paint()..color = theme.primary;
    final skinPaint = Paint()..color = const Color(0xFFFCD34D); // warm skin tone
    final outlinePaint = Paint()
      ..color = const Color(0xFF1E2235)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Sleeve cuff below phone
    final sleeveRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(3, 38), width: 20, height: 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(sleeveRRect, sleevePaint);
    canvas.drawRRect(sleeveRRect, outlinePaint);

    // Wrist connecting sleeve to hand
    final wristRect = Rect.fromCenter(center: const Offset(3, 28), width: 14, height: 14);
    canvas.drawRect(wristRect, skinPaint);
    canvas.drawRect(wristRect, outlinePaint);

    // Palm behind phone
    final palmRect = Rect.fromCenter(center: const Offset(2, 12), width: 24, height: 24);
    canvas.drawOval(palmRect, skinPaint);
    canvas.drawOval(palmRect, outlinePaint);

    // 5. Phone Body (Hardware Bezel)
    final phoneBodyPaint = Paint()..color = const Color(0xFF1E2235);
    canvas.drawRRect(phoneRect, phoneBodyPaint);

    // Glass Screen with vibrant gradient
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: pw - 4, height: ph - 6),
      const Radius.circular(4.5),
    );
    final screenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.primary.withValues(alpha: 0.85),
          theme.primary,
          const Color(0xFF1E2235),
        ],
      ).createShader(screenRect.outerRect);
    canvas.drawRRect(screenRect, screenPaint);

    // Speaker notch / Dynamic Island pill at top
    canvas.drawLine(
      const Offset(-4, -ph / 2 + 3),
      const Offset(4, -ph / 2 + 3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Glowing Mini Compass Needle on screen
    final needlePaintNorth = Paint()..color = Colors.white;
    final needlePathNorth = Path()
      ..moveTo(0, -9)
      ..lineTo(3.2, 0)
      ..lineTo(-3.2, 0)
      ..close();
    canvas.drawPath(needlePathNorth, needlePaintNorth);

    final needlePaintSouth = Paint()..color = const Color(0xFFFF6B6B);
    final needlePathSouth = Path()
      ..moveTo(0, 9)
      ..lineTo(3.2, 0)
      ..lineTo(-3.2, 0)
      ..close();
    canvas.drawPath(needlePathSouth, needlePaintSouth);

    // Center Needle Pivot
    canvas.drawCircle(Offset.zero, 1.8, Paint()..color = const Color(0xFF1E2235));

    // 6. Fingers holding phone (Wrapping onto front)
    // Thumb on left edge
    final thumbRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(-pw / 2 + 1, 5), width: 6.5, height: 13),
      const Radius.circular(3.2),
    );
    canvas.drawRRect(thumbRRect, skinPaint);
    canvas.drawRRect(thumbRRect, outlinePaint);

    // 3 Fingers overlapping right edge
    for (int i = 0; i < 3; i++) {
      final fingerRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pw / 2 - 1, -6.0 + (i * 8.5)), width: 6.5, height: 7.2),
        const Radius.circular(3.2),
      );
      canvas.drawRRect(fingerRRect, skinPaint);
      canvas.drawRRect(fingerRRect, outlinePaint);
    }

    // Sparkle trail dot
    canvas.drawCircle(
      const Offset(0, -ph / 2 - 4),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Figure8HandPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// =============================================================================
// UNIFIED PAINTER: COMPASS DIAL (DEGREES & CARDINALS AROUND BEZEL)
// Uses widget.theme.primary for North, widget.theme.border for tick marks
// =============================================================================
class _UnifiedCompassDialPainter extends CustomPainter {
  final StationeryTheme theme;
  _UnifiedCompassDialPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 14;

    final Paint tickPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.40)
      ..strokeWidth = 1.2;

    final Paint majorPaint = Paint()
      ..color = theme.border
      ..strokeWidth = 2.0;

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

      // Degree Labels every 30° except cardinals
      if (isMajor && !isCardinal) {
        tp.text = TextSpan(
          text: '$deg°',
          style: GoogleFonts.robotoMono(
            color: theme.textSecondary.withValues(alpha: 0.6),
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        );
        tp.layout();
        final double degTextRad = radius - 20;
        final Offset degPos = Offset(
          center.dx + degTextRad * math.sin(rad) - (tp.width / 2),
          center.dy - degTextRad * math.cos(rad) - (tp.height / 2),
        );
        tp.paint(canvas, degPos);
      }

      // Cardinal Letters (N, E, S, W)
      if (isCardinal) {
        String label = 'N';
        Color color = theme.primary; // Dynamic Theme Accent!
        if (deg == 90) {
          label = 'E';
          color = theme.text;
        } else if (deg == 180) {
          label = 'S';
          color = theme.textSecondary;
        } else if (deg == 270) {
          label = 'W';
          color = theme.text;
        }

        tp.text = TextSpan(
          text: label,
          style: GoogleFonts.robotoMono(
            color: color,
            fontSize: 16,
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
  bool shouldRepaint(covariant _UnifiedCompassDialPainter oldDelegate) => false;
}

// =============================================================================
// UNIFIED PAINTER: PLUS CROSSHAIR RETICLE (CLEAN OPEN CENTER TARGET)
// =============================================================================
class _UnifiedPlusCrosshairPainter extends CustomPainter {
  final StationeryTheme theme;
  _UnifiedPlusCrosshairPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 44;

    final Paint axisPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.55)
      ..strokeWidth = 1.8;

    final Paint accentNorthPaint = Paint()
      ..color = theme.primary
      ..strokeWidth = 3.0;

    final Paint barEndPaint = Paint()
      ..color = theme.border
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Vertical line (Front - Back)
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      axisPaint,
    );

    // North crossbar endpoint in Theme Primary Accent
    canvas.drawLine(
      Offset(center.dx - 12, center.dy - radius),
      Offset(center.dx + 12, center.dy - radius),
      accentNorthPaint,
    );

    // South crossbar endpoint
    canvas.drawLine(
      Offset(center.dx - 12, center.dy + radius),
      Offset(center.dx + 12, center.dy + radius),
      barEndPaint,
    );

    // Horizontal line (Left - Right)
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      axisPaint,
    );

    // Left and Right endpoints
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - 12),
      Offset(center.dx - radius, center.dy + 12),
      barEndPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - 12),
      Offset(center.dx + radius, center.dy + 12),
      barEndPaint,
    );

    // Center Crosshair Reticle Ring (No dot, clean precision ring)
    final Paint ringPaint = Paint()
      ..color = theme.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 14, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _UnifiedPlusCrosshairPainter oldDelegate) => false;
}

// =============================================================================
// UNIFIED PAINTER: COMPASS NEEDLE (THEMED NORTH & SHADED SOUTH)
// =============================================================================
class _UnifiedCompassNeedlePainter extends CustomPainter {
  final StationeryTheme theme;
  _UnifiedCompassNeedlePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double halfLen = (size.width / 2) - 54;

    // North Pointer Left Half (Lighter Theme Primary)
    final Path northLeft = Path()
      ..moveTo(center.dx - 8, center.dy)
      ..lineTo(center.dx, center.dy - halfLen)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(northLeft, Paint()..color = theme.primary);

    // North Pointer Right Half (Deeper Theme Primary Shading)
    final Path northRight = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy - halfLen)
      ..lineTo(center.dx + 8, center.dy)
      ..close();
    canvas.drawPath(
      northRight,
      Paint()..color = Color.alphaBlend(Colors.black.withValues(alpha: 0.2), theme.primary),
    );

    // South Pointer Left Half (Slate / Charcoal)
    final Color southColor = theme.isDark ? const Color(0xFF3F3F46) : const Color(0xFF1E293B);
    final Path southLeft = Path()
      ..moveTo(center.dx - 8, center.dy)
      ..lineTo(center.dx, center.dy + halfLen)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(southLeft, Paint()..color = southColor);

    // South Pointer Right Half (Darker Charcoal)
    final Path southRight = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + halfLen)
      ..lineTo(center.dx + 8, center.dy)
      ..close();
    canvas.drawPath(
      southRight,
      Paint()..color = Color.alphaBlend(Colors.black.withValues(alpha: 0.25), southColor),
    );

    // Center Pivot Cap
    canvas.drawCircle(
      center,
      6.5,
      Paint()..color = theme.isDark ? const Color(0xFF18181B) : Colors.white,
    );
    canvas.drawCircle(
      center,
      6.5,
      Paint()
        ..color = theme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      center,
      3.0,
      Paint()..color = theme.primary,
    );
  }

  @override
  bool shouldRepaint(covariant _UnifiedCompassNeedlePainter oldDelegate) => false;
}

// =============================================================================
// UNIFIED PAINTER: BULLSEYE SURFACE LEVELER (MATCHES COMPASS BEZEL & GEOMETRY)
// Uses Concentric Precision Rings + 2D Liquid Bubble with Primary Theme Glow
// =============================================================================
class _BullseyeLevelerPainter extends CustomPainter {
  final double roll;
  final double pitch;
  final StationeryTheme theme;
  final double pulseProgress;

  _BullseyeLevelerPainter({
    required this.roll,
    required this.pitch,
    required this.theme,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = (size.width / 2) - 14;

    final bool isBalanced = (roll.abs() < 0.6 && pitch.abs() < 0.6);

    // 1. Concentric Calibration Target Rings (10°, 5°, 2°, 0.5° Deadzone)
    final Paint ringPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 10° Outer Ring
    canvas.drawCircle(center, maxRadius * 0.80, ringPaint);
    // 5° Mid Ring
    canvas.drawCircle(center, maxRadius * 0.50, ringPaint);
    // 2° Inner Ring
    canvas.drawCircle(
      center,
      maxRadius * 0.25,
      Paint()
        ..color = theme.primary.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 0.5° Bullseye Deadzone Center
    final Paint deadzonePaint = Paint()
      ..color = isBalanced
          ? theme.primary
          : theme.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isBalanced ? 2.5 : 2.0;

    canvas.drawCircle(center, 16, deadzonePaint);

    if (isBalanced) {
      // Glow pulse when balanced!
      canvas.drawCircle(
        center,
        16 + (pulseProgress * 6),
        Paint()
          ..color = theme.primary.withValues(alpha: 0.25 * (1 - pulseProgress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    // 2. Horizon Crosshair Lines (+)
    final Paint crossPaint = Paint()
      ..color = isBalanced
          ? theme.primary.withValues(alpha: 0.7)
          : theme.border.withValues(alpha: 0.45)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(center.dx - maxRadius * 0.85, center.dy),
      Offset(center.dx + maxRadius * 0.85, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius * 0.85),
      Offset(center.dx, center.dy + maxRadius * 0.85),
      crossPaint,
    );

    // 3. Floating 3D Spirit Bubble Dot
    // Map roll (X) and pitch (Y) [-20°, 20°] to circular travel
    final double maxTravel = maxRadius * 0.75;
    final double normX = (roll / 15.0).clamp(-1.0, 1.0);
    final double normY = (pitch / 15.0).clamp(-1.0, 1.0);

    final double bubbleX = center.dx + normX * maxTravel;
    final double bubbleY = center.dy + normY * maxTravel;
    final Offset bubbleOffset = Offset(bubbleX, bubbleY);

    // Bubble liquid outer halo
    canvas.drawCircle(
      bubbleOffset,
      17,
      Paint()..color = theme.primary.withValues(alpha: 0.28),
    );

    // Bubble primary liquid body
    canvas.drawCircle(
      bubbleOffset,
      13,
      Paint()..color = theme.primary,
    );

    // Bubble internal specular highlight (light reflection)
    canvas.drawCircle(
      Offset(bubbleX - 3.5, bubbleY - 3.5),
      3.5,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    // 4. Center Reference Degree Readout
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    final String label = isBalanced
        ? "0.0° LEVEL"
        : "${math.max(roll.abs(), pitch.abs()).toStringAsFixed(1)}°";

    tp.text = TextSpan(
      text: label,
      style: GoogleFonts.robotoMono(
        color: isBalanced ? theme.primary : theme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy + maxRadius * 0.55));
  }

  @override
  bool shouldRepaint(covariant _BullseyeLevelerPainter oldDelegate) {
    return oldDelegate.roll != roll ||
        oldDelegate.pitch != pitch ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}
