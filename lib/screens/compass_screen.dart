import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

class CompassScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CompassScreen({super.key, required this.theme});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> with SingleTickerProviderStateMixin {
  double _heading = 45.0; // Heading degrees
  double _tiltX = 2.0;
  double _tiltY = -1.5;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animController.addListener(() {
      setState(() {
        // Subtle natural magnetic wobble
        _heading = (45.0 + math.sin(_animController.value * math.pi * 2) * 4.0) % 360;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

  void _manualAdjust(double delta) {
    SoundService().playKey();
    setState(() {
      _heading = (_heading + delta) % 360;
      if (_heading < 0) _heading += 360;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double headingRad = -_heading * math.pi / 180.0;
    final String directionText = _getDirectionName(_heading);

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
          "Digital Compass 🧭",
          style: widget.theme.fontDisplay(fontSize: 22),
        ),
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Heading Degree Readout Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: widget.theme.doodleCard(borderWidth: 2.5),
                    child: Column(
                      children: [
                        Text(
                          "${_heading.round()}° $directionText",
                          style: widget.theme.fontDisplay(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Level Tilt: X: ${_tiltX.toStringAsFixed(1)}°, Y: ${_tiltY.toStringAsFixed(1)}°",
                          style: widget.theme.fontMono(
                            fontSize: 12,
                            color: widget.theme.text.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3D Rotating Compass Dial
                  Center(
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        color: widget.theme.cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.theme.border, width: 4.5),
                        boxShadow: [
                          BoxShadow(
                            color: widget.theme.border.withOpacity(0.35),
                            offset: const Offset(4, 7),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating Rose Dial
                          Transform.rotate(
                            angle: headingRad,
                            child: CustomPaint(
                              size: const Size(270, 270),
                              painter: _CompassDialPainter(theme: widget.theme),
                            ),
                          ),

                          // Stationary Divider Needle (School Compass Needle)
                          CustomPaint(
                            size: const Size(270, 270),
                            painter: _CompassNeedlePainter(theme: widget.theme),
                          ),

                          // Center metallic pivot pin
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC99700), // Brass pin
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Interactive Heading Calibrator Slider
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: widget.theme.doodleCard(borderWidth: 2.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Manual Heading Adjust",
                              style: widget.theme.fontDisplay(fontSize: 15),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _manualAdjust(-15),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _manualAdjust(15),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Slider(
                          value: _heading,
                          min: 0,
                          max: 360,
                          activeColor: widget.theme.primary,
                          onChanged: (val) {
                            setState(() => _heading = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final StationeryTheme theme;
  _CompassDialPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 16;

    final Paint tickPaint = Paint()
      ..color = theme.border.withOpacity(0.4)
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
        if (deg == 90) { label = 'E'; color = theme.text; }
        if (deg == 180) { label = 'S'; color = theme.text; }
        if (deg == 270) { label = 'W'; color = theme.text; }

        tp.text = TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 16,
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

class _CompassNeedlePainter extends CustomPainter {
  final StationeryTheme theme;
  _CompassNeedlePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double halfLen = (size.width / 2) - 48;

    // North Pointer (Red Coral Pencil Tip)
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
    final Paint southPaint = Paint()..color = const Color(0xFF2F3542);
    canvas.drawPath(southPath, southPaint);

    // Border around needle
    final Paint borderPaint = Paint()
      ..color = theme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(northPath, borderPaint);
    canvas.drawPath(southPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) => false;
}
