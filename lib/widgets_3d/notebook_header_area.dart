import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// REAL NOTEBOOK TOP INDEX & HEADER AREA
/// Replicates the authentic top blank margin of a real paper notebook:
/// - Left: Hand-lettered "Tooler" Subject Title
/// - Right: Real Printed Notebook Date / Page Window (Page No, Day, Date, Time)
/// - Bottom: Double Red Rule Line separating index area from notebook page
/// ---------------------------------------------------------------------------

class NotebookHeaderArea extends StatefulWidget {
  final StationeryTheme theme;
  final VoidCallback onThemeToggle;

  const NotebookHeaderArea({
    super.key,
    required this.theme,
    required this.onThemeToggle,
  });

  @override
  State<NotebookHeaderArea> createState() => _NotebookHeaderAreaState();
}

class _NotebookHeaderAreaState extends State<NotebookHeaderArea> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Live real-time clock update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayStr = DateFormat('EEEE').format(_now).toUpperCase();
    final dateStr = DateFormat('dd / MM / yyyy').format(_now);
    final timeStr = DateFormat('hh:mm:ss a').format(_now);

    return Column(
      children: [
        // 1. Blank Header Strip
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Hand-lettered "Tooler" Subject Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Tooler",
                        style: GoogleFonts.patrickHand(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: widget.theme.text,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Small ink doodle star
                      CustomPaint(
                        size: const Size(14, 14),
                        painter: _InkStarPainter(color: widget.theme.primary),
                      ),
                    ],
                  ),
                  Text(
                    "DAILY DOODLE DESK",
                    style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: widget.theme.text.withValues(alpha: 0.5),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

              // Right: Real Notebook Printed Date & Page Window
              InkWell(
                onTap: () {
                  SoundService().playClick();
                  widget.onThemeToggle();
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.theme.cardBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.7), // Red margin ink
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: PAGE NO & Theme Dot
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "PAGE NO: ",
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          Text(
                            "01",
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Theme Indicator Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: widget.theme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              widget.theme.mode == StationeryThemeMode.classicDoodle
                                  ? "CREAM"
                                  : widget.theme.mode == StationeryThemeMode.blueprintChalkboard
                                      ? "NAVY"
                                      : "NEON",
                              style: GoogleFonts.robotoMono(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: widget.theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // DATE ROW
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "DATE: ",
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.text,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // DAY & TIME ROW
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "DAY: ",
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          Text(
                            "$dayStr  •  $timeStr",
                            style: GoogleFonts.robotoMono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Double Red Margin Rule (Separates Index from Ruled Lines)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Container(
                height: 1.5,
                color: const Color(0xFFEF4444).withValues(alpha: 0.65),
              ),
              const SizedBox(height: 2.5),
              Container(
                height: 1.0,
                color: const Color(0xFFEF4444).withValues(alpha: 0.40),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Draws a tiny hand-sketched 5-point ink doodle star
class _InkStarPainter extends CustomPainter {
  final Color color;
  _InkStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final r = w * 0.45;

    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a = -math.pi / 2 + (i * 4 * math.pi / 5);
      final pt = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _InkStarPainter oldDelegate) => oldDelegate.color != color;
}
