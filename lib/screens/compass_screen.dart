import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../services/sensor_service.dart';
import '../widgets_3d/stationery_3d_modal.dart';

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

  // Manual fallback mode if user wants to test without physical sensors
  bool _manualOverride = false;
  double _manualHeading = 45.0;

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

  void _showCalibrationModal() {
    SoundService().playClick();
    Stationery3DModal.show(
      context: context,
      title: "Compass Sensor Calibration",
      subtitle: "Calibrate magnetometer & gyroscope",
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
                  "This recalibrates the internal geomagnetic sensor against local electrical interference.",
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
                label: "Accuracy",
                val: _reading.accuracy.name.toUpperCase(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: widget.theme.border, width: 2),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              SoundService().playSuccess();
            },
            child: Text(
              "Done Calibrating",
              style: widget.theme.fontDoodle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({required String label, required String val}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: widget.theme.fontMono(
              fontSize: 10,
              color: widget.theme.text.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: widget.theme.fontDisplay(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: widget.theme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double activeHeading =
        _manualOverride ? _manualHeading : _reading.heading;
    final double headingRad = -activeHeading * math.pi / 180.0;
    final String directionText = _manualOverride
        ? _getDirectionName(_manualHeading)
        : _reading.cardinal;

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
          "Digital Compass",
          style: GoogleFonts.architectsDaughter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: widget.theme.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right),
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
                  // 1. Hardware Sensor Status Badge
                  _buildSensorStatusBadge(),

                  const SizedBox(height: 12),

                  // 2. Heading Degree Readout Card
                  _buildHeadingReadout(activeHeading, directionText),

                  const SizedBox(height: 20),

                  // 3. 3D Rotating Compass Dial with Spirit Bubble Level Center
                  _buildCompassDialWithLevel(headingRad),

                  const SizedBox(height: 20),

                  // 4. Dual-Axis Spirit Level & Pitch/Roll Gauges
                  _buildSpiritLevelGauges(),

                  const SizedBox(height: 16),

                  // 5. Hardware Sensor Telemetry & Calibration Toolbar
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

  // --- HARDWARE SENSOR STATUS BADGE ---
  Widget _buildSensorStatusBadge() {
    final bool synced = _reading.isHardwareSynced && !_manualOverride;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: synced ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: synced ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: synced ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            synced
                ? "HARDWARE SYNCED • GYRO + ACCEL + MAG"
                : "MANUAL / SIMULATION MODE",
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: synced ? const Color(0xFF14532D) : const Color(0xFF78350F),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADING DEGREE READOUT CARD ---
  Widget _buildHeadingReadout(double heading, String directionText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: widget.theme.doodleCard(borderWidth: 2.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${heading.round()}°",
                style: GoogleFonts.architectsDaughter(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                directionText.toUpperCase(),
                style: GoogleFonts.kalam(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.text,
                ),
              ),
            ],
          ),

          // Level Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _reading.isLevel
                  ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                  : const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _reading.isLevel
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _reading.isLevel ? Icons.check_circle : Icons.screen_rotation,
                  size: 16,
                  color: _reading.isLevel
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 4),
                Text(
                  _reading.isLevel ? "LEVEL" : "TILTED",
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _reading.isLevel
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3D ROTATING COMPASS DIAL WITH EMBEDDED SPIRIT LEVEL ---
  Widget _buildCompassDialWithLevel(double headingRad) {
    const double dialSize = 280.0;

    return Center(
      child: Container(
        width: dialSize,
        height: dialSize,
        decoration: BoxDecoration(
          color: widget.theme.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: widget.theme.border, width: 4.0),
          boxShadow: [
            BoxShadow(
              color: widget.theme.border.withValues(alpha: 0.35),
              offset: const Offset(4, 7),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Compass Rose Dial
            Transform.rotate(
              angle: headingRad,
              child: CustomPaint(
                size: const Size(dialSize, dialSize),
                painter: _CompassDialPainter(theme: widget.theme),
              ),
            ),

            // Stationary North/South Needle (School Divider Needle)
            CustomPaint(
              size: const Size(dialSize, dialSize),
              painter: _CompassNeedlePainter(theme: widget.theme),
            ),

            // Real-Time Spirit Bubble Level at Center Pivot
            _buildCenterBubbleLevel(),
          ],
        ),
      ),
    );
  }

  // --- CENTER SPIRIT BUBBLE LEVEL ---
  Widget _buildCenterBubbleLevel() {
    const double levelSize = 64.0;
    // Map pitch & roll [-20°, 20°] to bubble offset [-20px, 20px]
    const double maxOffset = 18.0;
    final double bubbleX =
        (_reading.roll / 20.0).clamp(-1.0, 1.0) * maxOffset;
    final double bubbleY =
        (-_reading.pitch / 20.0).clamp(-1.0, 1.0) * maxOffset;

    final bool isLevel = _reading.isLevel;

    return Container(
      width: levelSize,
      height: levelSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE2E8F0),
        border: Border.all(
          color: isLevel ? const Color(0xFF16A34A) : widget.theme.border,
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Crosshairs
          Container(width: levelSize, height: 1, color: const Color(0xFF94A3B8)),
          Container(width: 1, height: levelSize, color: const Color(0xFF94A3B8)),
          // Bullseye target circle
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isLevel ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                width: 1.5,
              ),
            ),
          ),
          // Moving Spirit Bubble
          Transform.translate(
            offset: Offset(bubbleX, bubbleY),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLevel ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: (isLevel ? const Color(0xFF16A34A) : const Color(0xFFD97706))
                        .withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DUAL-AXIS SPIRIT LEVEL GAUGES ---
  Widget _buildSpiritLevelGauges() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: widget.theme.doodleCard(borderWidth: 2.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DUAL-AXIS ACCELEROMETER TILT",
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.text.withValues(alpha: 0.6),
                ),
              ),
              Text(
                "P: ${_reading.pitch.toStringAsFixed(1)}° | R: ${_reading.roll.toStringAsFixed(1)}°",
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pitch bar gauge
          _buildAxisBar("Pitch (Front/Back)", _reading.pitch / 45.0),
          const SizedBox(height: 6),

          // Roll bar gauge
          _buildAxisBar("Roll (Left/Right)", _reading.roll / 45.0),
        ],
      ),
    );
  }

  Widget _buildAxisBar(String label, double normalized) {
    final clamped = normalized.clamp(-1.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.kalam(fontSize: 11)),
            Text(
              "${(normalized * 45).toStringAsFixed(1)}°",
              style: GoogleFonts.robotoMono(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: widget.theme.border, width: 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Center divider
              Container(width: 1.5, color: widget.theme.border),
              // Indicator fill
              FractionallySizedBox(
                alignment: clamped < 0 ? Alignment.centerRight : Alignment.centerLeft,
                widthFactor: (clamped.abs() / 2).clamp(0.0, 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    color: clamped.abs() < 0.08
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF97316),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HARDWARE SENSOR TELEMETRY & CONTROLS ---
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
                  const Icon(Icons.explore_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    "Sensor Fusion Telemetry",
                    style: GoogleFonts.kalam(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.text,
                    ),
                  ),
                ],
              ),

              // Manual override toggle
              InkWell(
                onTap: () {
                  setState(() => _manualOverride = !_manualOverride);
                  SoundService().playKey();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _manualOverride
                        ? const Color(0xFFFEF08A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: widget.theme.border, width: 1),
                  ),
                  child: Text(
                    _manualOverride ? "Manual Mode" : "Auto Sensor Fusion",
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Real-time sensor stats grid
          Row(
            children: [
              Expanded(
                child: _buildTelemetryStat(
                  title: "Magnetometer",
                  val: "${_reading.magneticStrength.toStringAsFixed(1)} µT",
                  sub: "Earth Field Norm",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryStat(
                  title: "Gyroscope Z",
                  val: "${_reading.gyroZ.toStringAsFixed(1)} °/s",
                  sub: "Angular Turn Rate",
                ),
              ),
            ],
          ),

          if (_manualOverride) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Manual Dial Slider:",
                  style: GoogleFonts.kalam(fontSize: 12),
                ),
                Text(
                  "${_manualHeading.round()}°",
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _manualHeading,
              min: 0,
              max: 360,
              activeColor: widget.theme.primary,
              onChanged: (v) => setState(() => _manualHeading = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryStat({
    required String title,
    required String val,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.architectsDaughter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.kalam(
              fontSize: 9,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  String _getDirectionName(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'North';
    if (heading >= 22.5 && heading < 67.5) return 'Northeast';
    if (heading >= 67.5 && heading < 112.5) return 'East';
    if (heading >= 112.5 && heading < 157.5) return 'Southeast';
    if (heading >= 157.5 && heading < 202.5) return 'South';
    if (heading >= 202.5 && heading < 247.5) return 'Southwest';
    if (heading >= 247.5 && heading < 292.5) return 'West';
    return 'Northwest';
  }
}

// Custom Painter for Compass Rose Dial
class _CompassDialPainter extends CustomPainter {
  final StationeryTheme theme;
  _CompassDialPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 16;

    final Paint tickPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;

    final Paint majorPaint = Paint()
      ..color = theme.border
      ..strokeWidth = 2.5;

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

    for (int deg = 0; deg < 360; deg += 5) {
      final double rad = deg * math.pi / 180.0;
      final bool isCardinal = (deg % 90 == 0);
      final bool isMajor = (deg % 30 == 0);

      final double tickLen = isCardinal ? 14 : (isMajor ? 10 : 5);

      final Offset p1 = Offset(
        center.dx + (radius - tickLen) * math.sin(rad),
        center.dy - (radius - tickLen) * math.cos(rad),
      );
      final Offset p2 = Offset(
        center.dx + radius * math.sin(rad),
        center.dy - radius * math.cos(rad),
      );

      canvas.drawLine(p1, p2, isMajor ? majorPaint : tickPaint);

      // Draw Cardinal Letters (N, E, S, W)
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
        tp.layout();

        final double textRad = (radius - 28);
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

// Custom Painter for Stationery Compass Pointer Needle
class _CompassNeedlePainter extends CustomPainter {
  final StationeryTheme theme;
  _CompassNeedlePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double halfLen = (size.width / 2) - 48;

    // North Pointer (Red Coral Pencil Tip)
    final Path northPath = Path()
      ..moveTo(center.dx - 9, center.dy)
      ..lineTo(center.dx, center.dy - halfLen)
      ..lineTo(center.dx + 9, center.dy)
      ..close();
    final Paint northPaint = Paint()..color = const Color(0xFFFF4757);
    canvas.drawPath(northPath, northPaint);

    // South Pointer (Charcoal Lead Tip)
    final Path southPath = Path()
      ..moveTo(center.dx - 9, center.dy)
      ..lineTo(center.dx, center.dy + halfLen)
      ..lineTo(center.dx + 9, center.dy)
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
