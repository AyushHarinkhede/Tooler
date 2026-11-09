import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// TOOLER 3D STATIONERY & HARDWARE VECTOR ICONS
/// Resolution-independent, authentic physical 3D vector painters with
/// multi-layer gradients, realistic lighting, specular highlights, and drop shadows.
/// Replaces all text emojis across Tooler with real physical objects.
/// ---------------------------------------------------------------------------

/// 1. 3D CALENDAR MILESTONE (Age Calculator)
class Icon3DCalendarMilestone extends StatelessWidget {
  final double size;
  const Icon3DCalendarMilestone({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CalendarMilestonePainter()),
    );
  }
}

class _CalendarMilestonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 3D Drop Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.18, w * 0.82, h * 0.78),
        Radius.circular(w * 0.12),
      ),
      shadowPaint,
    );

    // Bottom Pages Stack (3D paper thickness)
    final backPagePaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.22, w * 0.8, h * 0.72),
        Radius.circular(w * 0.12),
      ),
      backPagePaint,
    );

    // Front White Paper Page
    final pageRect = Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.8, h * 0.74);
    final pagePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      ).createShader(pageRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pageRect, Radius.circular(w * 0.12)),
      pagePaint,
    );

    // Red Header Banner
    final headerPath = Path()
      ..moveTo(w * 0.08, h * 0.32)
      ..lineTo(w * 0.08, h * 0.26)
      ..arcToPoint(
        Offset(w * 0.2, h * 0.18),
        radius: Radius.circular(w * 0.12),
      )
      ..lineTo(w * 0.76, h * 0.18)
      ..arcToPoint(
        Offset(w * 0.88, h * 0.26),
        radius: Radius.circular(w * 0.12),
      )
      ..lineTo(w * 0.88, h * 0.38)
      ..lineTo(w * 0.08, h * 0.38)
      ..close();

    final headerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFB91C1C)],
      ).createShader(pageRect);
    canvas.drawPath(headerPath, headerPaint);

    // Golden Spiral Rings (Top Binders)
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE047), Color(0xFFCA8A04), Color(0xFFFEF08A)],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.25))
      ..strokeWidth = w * 0.07
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ringShadow = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = w * 0.07
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawRing(double x) {
      canvas.drawLine(
        Offset(x + 1, h * 0.11),
        Offset(x + 1, h * 0.26),
        ringShadow,
      );
      canvas.drawLine(Offset(x, h * 0.10), Offset(x, h * 0.25), ringPaint);
    }

    drawRing(w * 0.26);
    drawRing(w * 0.48);
    drawRing(w * 0.70);

    // Big Bold Star Graphic on Page
    final starPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    final starCenter = Offset(w * 0.48, h * 0.62);
    final starR = w * 0.20;

    final starPath = Path();
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? starR : starR * 0.45;
      final double angle = -math.pi / 2 + (i * math.pi / 5);
      final double x = starCenter.dx + r * math.cos(angle);
      final double y = starCenter.dy + r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);

    // Star Inner Highlight
    final starInner = Paint()..color = const Color(0xFFFEF08A);
    canvas.drawCircle(starCenter, starR * 0.22, starInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. 3D RULER & SCISSORS (Converters)
class Icon3DRulerScissors extends StatelessWidget {
  final double size;
  const Icon3DRulerScissors({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RulerScissorsPainter()),
    );
  }
}

class _RulerScissorsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Tilted 3D Wooden Ruler
    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(-0.45); // -25 degrees

    final rulerRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.95,
      height: h * 0.26,
    );
    final rulerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFD97706)],
      ).createShader(rulerRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rulerRect, const Radius.circular(3)),
      rulerPaint,
    );

    // Brass edge
    final brassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF08A), Color(0xFFCA8A04)],
      ).createShader(Rect.fromLTWH(-w * 0.47, -h * 0.13, w * 0.95, 2.5));
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.47, -h * 0.13, w * 0.95, 2.5),
      brassPaint,
    );

    // Tick marks on ruler
    final tickPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.0;
    for (double tx = -w * 0.42; tx < w * 0.42; tx += 4.5) {
      final double th = (tx.toInt() % 9 == 0) ? 6.0 : 3.5;
      canvas.drawLine(
        Offset(tx, -h * 0.13),
        Offset(tx, -h * 0.13 + th),
        tickPaint,
      );
    }
    canvas.restore();

    // 2. Stainless Steel Scissors Blade (Diagonal Crossing)
    final bladePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF1F5F9), Color(0xFF94A3B8), Color(0xFFCBD5E1)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final blade1 = Path()
      ..moveTo(w * 0.22, h * 0.28)
      ..lineTo(w * 0.82, h * 0.72)
      ..lineTo(w * 0.76, h * 0.78)
      ..lineTo(w * 0.18, h * 0.34)
      ..close();
    canvas.drawPath(blade1, bladePaint);

    // Scissors Handle Loop (Teal / Cyan grip)
    final handlePaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12;
    canvas.drawCircle(Offset(w * 0.18, h * 0.28), w * 0.14, handlePaint);

    final handleInner = Paint()
      ..color = const Color(0xFF14B8A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04;
    canvas.drawCircle(Offset(w * 0.18, h * 0.28), w * 0.14, handleInner);

    // Brass Pivot Screw
    final screwPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(w * 0.48, h * 0.50), w * 0.065, screwPaint);
    final screwSlot = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(w * 0.45, h * 0.50),
      Offset(w * 0.51, h * 0.50),
      screwSlot,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. 3D MECHANICAL STOPWATCH
class Icon3DStopwatch extends StatelessWidget {
  final double size;
  const Icon3DStopwatch({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StopwatchPainter()),
    );
  }
}

class _StopwatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.54);
    final r = w * 0.38;

    // Top Pusher Button & Ring
    final ringPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06;
    canvas.drawCircle(Offset(w * 0.5, h * 0.12), w * 0.10, ringPaint);

    // Crown Stem
    final stemPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.12, w * 0.12, h * 0.08), stemPaint);

    // Beveled Outer Chrome Rim Shadow
    canvas.drawCircle(
      center.translate(1.5, 2.0),
      r,
      Paint()..color = const Color(0x40000000),
    );

    // Outer Chrome Rim
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFF475569), Color(0xFFF8FAFC)],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, rimPaint);

    // Dial Face (Porcelain White)
    final dialPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.82));
    canvas.drawCircle(center, r * 0.82, dialPaint);

    // Dial Ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 12; i++) {
      final double angle = i * math.pi / 6;
      final double innerR = (i % 3 == 0) ? r * 0.64 : r * 0.72;
      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(angle), center.dy + innerR * math.sin(angle)),
        Offset(center.dx + r * 0.80 * math.cos(angle), center.dy + r * 0.80 * math.sin(angle)),
        tickPaint,
      );
    }

    // Red Sweeping Hand (at 10 past)
    final handPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const handAngle = -math.pi / 3; // 60 deg
    canvas.drawLine(
      center,
      Offset(center.dx + r * 0.65 * math.cos(handAngle), center.dy + r * 0.65 * math.sin(handAngle)),
      handPaint,
    );

    // Central Cap
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFF1E293B));

    // Glass Crystal Reflection Glint
    final glintPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x80FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.8));
    final glintPath = Path()
      ..moveTo(center.dx - r * 0.6, center.dy - r * 0.2)
      ..arcToPoint(
        Offset(center.dx + r * 0.2, center.dy - r * 0.6),
        radius: Radius.circular(r * 0.8),
      )
      ..close();
    canvas.drawPath(glintPath, glintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. 3D HOURGLASS (Timer)
class Icon3DHourglass extends StatelessWidget {
  final double size;
  const Icon3DHourglass({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HourglassPainter()),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top & Bottom Mahogany Wood Plinths
    final woodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9A3412), Color(0xFF7C2D12), Color(0xFF431407)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Top Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.08, w * 0.70, h * 0.10), const Radius.circular(3)),
      woodPaint,
    );
    // Bottom Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.82, w * 0.70, h * 0.10), const Radius.circular(3)),
      woodPaint,
    );

    // Side Brass Supporting Struts
    final strutPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE047), Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(w * 0.20, h * 0.18), Offset(w * 0.20, h * 0.82), strutPaint);
    canvas.drawLine(Offset(w * 0.80, h * 0.18), Offset(w * 0.80, h * 0.82), strutPaint);

    // Glass Bulb Silhouette
    final glassPath = Path()
      ..moveTo(w * 0.25, h * 0.18)
      ..lineTo(w * 0.75, h * 0.18)
      ..cubicTo(w * 0.75, h * 0.38, w * 0.56, h * 0.46, w * 0.54, h * 0.50)
      ..cubicTo(w * 0.56, h * 0.54, w * 0.75, h * 0.62, w * 0.75, h * 0.82)
      ..lineTo(w * 0.25, h * 0.82)
      ..cubicTo(w * 0.25, h * 0.62, w * 0.44, h * 0.54, w * 0.46, h * 0.50)
      ..cubicTo(w * 0.44, h * 0.46, w * 0.25, h * 0.38, w * 0.25, h * 0.18)
      ..close();

    final glassPaint = Paint()
      ..color = const Color(0x33BAE6FD)
      ..style = PaintingStyle.fill;
    canvas.drawPath(glassPath, glassPaint);

    final glassOutline = Paint()
      ..color = const Color(0x8838BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(glassPath, glassOutline);

    // Golden Falling Sand
    final sandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE047), Color(0xFFF59E0B), Color(0xFFD97706)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Top Chamber Sand (Depleting cone)
    final topSand = Path()
      ..moveTo(w * 0.32, h * 0.32)
      ..lineTo(w * 0.68, h * 0.32)
      ..lineTo(w * 0.50, h * 0.48)
      ..close();
    canvas.drawPath(topSand, sandPaint);

    // Falling Sand Stream
    final streamPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.5, h * 0.48), Offset(w * 0.5, h * 0.72), streamPaint);

    // Bottom Chamber Sand (Accumulated Mound)
    final bottomSand = Path()
      ..moveTo(w * 0.28, h * 0.82)
      ..lineTo(w * 0.72, h * 0.82)
      ..cubicTo(w * 0.68, h * 0.70, w * 0.55, h * 0.66, w * 0.50, h * 0.66)
      ..cubicTo(w * 0.45, h * 0.66, w * 0.32, h * 0.70, w * 0.28, h * 0.82)
      ..close();
    canvas.drawPath(bottomSand, sandPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. 3D GOLD RING & CALIPER (Sizer Tools)
class Icon3DCaliperRing extends StatelessWidget {
  final double size;
  const Icon3DCaliperRing({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CaliperRingPainter()),
    );
  }
}

class _CaliperRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 3D Polished Gold Ring (Tilted Oval)
    final ringCenter = Offset(w * 0.48, h * 0.56);
    final ringShadow = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(
      Rect.fromCenter(center: ringCenter.translate(1, 2), width: w * 0.64, height: h * 0.52),
      ringShadow,
    );

    // Outer Gold Torus
    final outerRing = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFEF08A),
          Color(0xFFF59E0B),
          Color(0xFFB45309),
          Color(0xFFFEF08A),
          Color(0xFFCA8A04),
          Color(0xFFFEF08A),
        ],
      ).createShader(Rect.fromCircle(center: ringCenter, radius: w * 0.32))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13;
    canvas.drawOval(
      Rect.fromCenter(center: ringCenter, width: w * 0.60, height: h * 0.48),
      outerRing,
    );

    // Faceted Diamond Gem at Top of Ring
    final gemCenter = Offset(ringCenter.dx, ringCenter.dy - h * 0.26);
    final gemPath = Path()
      ..moveTo(gemCenter.dx, gemCenter.dy - h * 0.12)
      ..lineTo(gemCenter.dx + w * 0.10, gemCenter.dy)
      ..lineTo(gemCenter.dx, gemCenter.dy + h * 0.08)
      ..lineTo(gemCenter.dx - w * 0.10, gemCenter.dy)
      ..close();

    final gemPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(gemPath, gemPaint);

    // Gem Specular Sparkle
    canvas.drawCircle(gemCenter.translate(-1, -2), 1.5, Paint()..color = Colors.white);

    // 2. Stainless Caliper Jaw Overlay (Left Gauge)
    final caliperPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFF64748B)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.10, h * 0.20), Offset(w * 0.10, h * 0.85), caliperPaint);
    canvas.drawLine(Offset(w * 0.10, h * 0.20), Offset(w * 0.26, h * 0.20), caliperPaint);
    canvas.drawLine(Offset(w * 0.10, h * 0.85), Offset(w * 0.26, h * 0.85), caliperPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. 3D TALLY COUNTER (Custom Counters)
class Icon3DTallyCounter extends StatelessWidget {
  final double size;
  const Icon3DTallyCounter({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TallyCounterPainter()),
    );
  }
}

class _TallyCounterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.56);

    // Plunger Push Button on Top
    final plungerPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.08, w * 0.16, h * 0.12), const Radius.circular(2)),
      plungerPaint,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.09), w * 0.10, Paint()..color = const Color(0xFF94A3B8));

    // Chrome Housing Dome
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCBD5E1), Color(0xFF64748B), Color(0xFF334155), Color(0xFFF1F5F9)],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.38));
    canvas.drawCircle(center, w * 0.36, bodyPaint);

    // 4-Digit Display Window (Deep recessed black slot)
    final windowRect = Rect.fromCenter(center: center, width: w * 0.56, height: h * 0.22);
    final windowPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(2)),
      windowPaint,
    );

    // White Digits "0842"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '0842',
        style: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));

    // Side Reset Knob Wheel
    canvas.drawCircle(Offset(w * 0.88, center.dy), w * 0.08, Paint()..color = const Color(0xFF475569));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7. 3D CLIPBOARD CHECKLIST (Tasks)
class Icon3DClipboard extends StatelessWidget {
  final double size;
  const Icon3DClipboard({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ClipboardPainter()),
    );
  }
}

class _ClipboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Hardboard Base (Rich Walnut Brown)
    final boardRect = Rect.fromLTWH(w * 0.12, h * 0.14, w * 0.76, h * 0.80);
    final boardPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB45309), Color(0xFF92400E), Color(0xFF78350F)],
      ).createShader(boardRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(5)),
      boardPaint,
    );

    // Lined Notepad Sheet
    final sheetRect = Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.64, h * 0.68);
    final sheetPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
      ).createShader(sheetRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheetRect, const Radius.circular(3)),
      sheetPaint,
    );

    // Lined Rules & Green Checked Marks
    final linePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;
    final checkPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    void drawTaskLine(double y, bool checked) {
      canvas.drawLine(Offset(w * 0.38, y), Offset(w * 0.74, y), linePaint);
      if (checked) {
        final tickPath = Path()
          ..moveTo(w * 0.24, y)
          ..lineTo(w * 0.28, y + 3)
          ..lineTo(w * 0.34, y - 4);
        canvas.drawPath(tickPath, checkPaint);
      }
    }

    drawTaskLine(h * 0.40, true);
    drawTaskLine(h * 0.54, true);
    drawTaskLine(h * 0.68, false);

    // Heavy Duty Spring Metal Clamp at Top
    final clampPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFCBD5E1), Color(0xFF64748B), Color(0xFFE2E8F0)],
      ).createShader(Rect.fromLTWH(w * 0.30, h * 0.08, w * 0.40, h * 0.14));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.30, h * 0.08, w * 0.40, h * 0.14), const Radius.circular(3)),
      clampPaint,
    );
    // Clamp Hole
    canvas.drawCircle(Offset(w * 0.50, h * 0.12), w * 0.04, Paint()..color = const Color(0xFF334155));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 8. 3D GOLD & SILVER COINS (Currency)
class Icon3DGoldCoins extends StatelessWidget {
  final double size;
  const Icon3DGoldCoins({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoldCoinsPainter()),
    );
  }
}

class _GoldCoinsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Back Silver Coin
    final silverCenter = Offset(w * 0.62, h * 0.44);
    final silverR = w * 0.30;
    final silverPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF1F5F9), Color(0xFF94A3B8), Color(0xFF475569)],
      ).createShader(Rect.fromCircle(center: silverCenter, radius: silverR));
    canvas.drawCircle(silverCenter, silverR, silverPaint);

    final silverInner = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(silverCenter, silverR * 0.8, silverInner);

    // 2. Front Gold Bullion Coin with Milled Bevel
    final goldCenter = Offset(w * 0.40, h * 0.58);
    final goldR = w * 0.33;

    // Coin Drop Shadow
    canvas.drawCircle(
      goldCenter.translate(1.5, 2.0),
      goldR,
      Paint()..color = const Color(0x33000000),
    );

    // Outer Ridged Ring
    final goldPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFEF08A),
          Color(0xFFF59E0B),
          Color(0xFFB45309),
          Color(0xFFFEF08A),
          Color(0xFFCA8A04),
          Color(0xFFFEF08A),
        ],
      ).createShader(Rect.fromCircle(center: goldCenter, radius: goldR));
    canvas.drawCircle(goldCenter, goldR, goldPaint);

    // Inner Face
    final facePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFDE047), Color(0xFFEAB308), Color(0xFFCA8A04)],
      ).createShader(Rect.fromCircle(center: goldCenter, radius: goldR * 0.82));
    canvas.drawCircle(goldCenter, goldR * 0.82, facePaint);

    // Embossed Currency Symbol (₹ / $)
    final symPainter = TextPainter(
      text: const TextSpan(
        text: '₹',
        style: TextStyle(
          color: Color(0xFF78350F),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    symPainter.paint(canvas, Offset(goldCenter.dx - symPainter.width / 2, goldCenter.dy - symPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 9. 3D GAMING DICE (Games Arcade)
class Icon3DDiceArcade extends StatelessWidget {
  final double size;
  const Icon3DDiceArcade({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DiceArcadePainter()),
    );
  }
}

class _DiceArcadePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Isometric 3D Die
    // Top Face (Rhombus)
    final topFace = Path()
      ..moveTo(w * 0.50, h * 0.12)
      ..lineTo(w * 0.84, h * 0.30)
      ..lineTo(w * 0.50, h * 0.48)
      ..lineTo(w * 0.16, h * 0.30)
      ..close();
    final topPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawPath(topFace, topPaint);

    // Left Face (Shaded)
    final leftFace = Path()
      ..moveTo(w * 0.16, h * 0.30)
      ..lineTo(w * 0.50, h * 0.48)
      ..lineTo(w * 0.50, h * 0.88)
      ..lineTo(w * 0.16, h * 0.70)
      ..close();
    final leftPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawPath(leftFace, leftPaint);

    // Right Face (Deep Shadow)
    final rightFace = Path()
      ..moveTo(w * 0.50, h * 0.48)
      ..lineTo(w * 0.84, h * 0.30)
      ..lineTo(w * 0.84, h * 0.70)
      ..lineTo(w * 0.50, h * 0.88)
      ..close();
    final rightPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawPath(rightFace, rightPaint);

    // Borders
    final edgePaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(topFace, edgePaint);
    canvas.drawPath(leftFace, edgePaint);
    canvas.drawPath(rightFace, edgePaint);

    // Red Center Pip on Top Face (Value 1)
    canvas.drawCircle(Offset(w * 0.50, h * 0.30), 2.5, Paint()..color = const Color(0xFFEF4444));

    // Two Pips on Left Face
    final pipPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(w * 0.30, h * 0.48), 1.8, pipPaint);
    canvas.drawCircle(Offset(w * 0.38, h * 0.68), 1.8, pipPaint);

    // Three Pips on Right Face
    canvas.drawCircle(Offset(w * 0.60, h * 0.52), 1.8, pipPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.60), 1.8, pipPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.68), 1.8, pipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 10. 3D DESKTOP GLOBE (Web Browser)
class Icon3DGlobe extends StatelessWidget {
  final double size;
  const Icon3DGlobe({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlobePainter()),
    );
  }
}

class _GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.48, h * 0.42);
    final r = w * 0.32;

    // Turned Wooden Base
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9A3412), Color(0xFF7C2D12), Color(0xFF431407)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.84, w * 0.44, h * 0.10), const Radius.circular(3)),
      basePaint,
    );

    // Vertical Stem
    canvas.drawRect(Rect.fromLTWH(w * 0.46, h * 0.74, w * 0.08, h * 0.12), Paint()..color = const Color(0xFFB45309));

    // Curved Brass Meridian Arc
    final arcPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE047), Color(0xFFCA8A04), Color(0xFF854D0E)],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 1.18),
      -math.pi * 0.8,
      math.pi * 1.15,
      false,
      arcPaint,
    );

    // Ocean Globe Sphere (Sapphire Blue Gradient)
    final oceanPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1E3A8A)],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, oceanPaint);

    // Continents (Emerald Green landmasses)
    final landPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    // Landmass 1 (North/South continent)
    final landPath1 = Path()
      ..moveTo(center.dx - r * 0.5, center.dy - r * 0.4)
      ..cubicTo(center.dx - r * 0.2, center.dy - r * 0.6, center.dx + r * 0.2, center.dy - r * 0.3, center.dx, center.dy)
      ..cubicTo(center.dx - r * 0.1, center.dy + r * 0.4, center.dx - r * 0.5, center.dy + r * 0.3, center.dx - r * 0.4, center.dy + r * 0.1)
      ..close();
    canvas.drawPath(landPath1, landPaint);

    // Landmass 2 (East continent)
    final landPath2 = Path()
      ..moveTo(center.dx + r * 0.2, center.dy - r * 0.2)
      ..cubicTo(center.dx + r * 0.6, center.dy - r * 0.4, center.dx + r * 0.7, center.dy + r * 0.2, center.dx + r * 0.4, center.dy + r * 0.3)
      ..close();
    canvas.drawPath(landPath2, landPaint);

    // Latitude / Longitude Line (Faint glass white)
    final gridPaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(Rect.fromCenter(center: center, width: r * 1.9, height: r * 0.6), gridPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 11. 3D MARINER COMPASS (Digital Compass)
class Icon3DCompass extends StatelessWidget {
  final double size;
  const Icon3DCompass({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarinerCompassPainter()),
    );
  }
}

class _MarinerCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.54);
    final r = w * 0.38;

    // Top Brass Lanyard Ring
    final ringPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF08A), Color(0xFFCA8A04)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w * 0.5, h * 0.12), w * 0.10, ringPaint);

    // Antique Brass Case Outer Rim
    final brassPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFEF08A),
          Color(0xFFD97706),
          Color(0xFF78350F),
          Color(0xFFFEF08A),
          Color(0xFFB45309),
          Color(0xFFFEF08A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, brassPaint);

    // Parchment Dial Face
    final dialPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.8));
    canvas.drawCircle(center, r * 0.8, dialPaint);

    // 8-Point Compass Star Rose
    final starPaint = Paint()..color = const Color(0xFF92400E);
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + r * 0.25 * math.cos(angle - 0.3), center.dy + r * 0.25 * math.sin(angle - 0.3))
        ..lineTo(center.dx + r * 0.70 * math.cos(angle), center.dy + r * 0.70 * math.sin(angle))
        ..close();
      canvas.drawPath(path, starPaint);
    }

    // 3D Magnetic Needle (North Red, South Silver)
    // North Arrow
    final northPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 3, center.dy)
      ..lineTo(center.dx, center.dy - r * 0.72)
      ..close();
    canvas.drawPath(northPath, Paint()..color = const Color(0xFFDC2626));

    final northPathRight = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + 3, center.dy)
      ..lineTo(center.dx, center.dy - r * 0.72)
      ..close();
    canvas.drawPath(northPathRight, Paint()..color = const Color(0xFFEF4444));

    // South Arrow
    final southPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 3, center.dy)
      ..lineTo(center.dx, center.dy + r * 0.72)
      ..close();
    canvas.drawPath(southPath, Paint()..color = const Color(0xFF94A3B8));

    final southPathRight = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + 3, center.dy)
      ..lineTo(center.dx, center.dy + r * 0.72)
      ..close();
    canvas.drawPath(southPathRight, Paint()..color = const Color(0xFFCBD5E1));

    // Center Brass Pivot Cap
    canvas.drawCircle(center, 3.0, Paint()..color = const Color(0xFFB45309));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 12. 3D COMBINATION PADLOCK (Password Generator)
class Icon3DPadlock extends StatelessWidget {
  final double size;
  const Icon3DPadlock({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PadlockPainter()),
    );
  }
}

class _PadlockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Hardened Chrome Steel U-Shackle
    final shacklePath = Path()
      ..moveTo(w * 0.30, h * 0.44)
      ..lineTo(w * 0.30, h * 0.24)
      ..arcToPoint(
        Offset(w * 0.70, h * 0.24),
        radius: Radius.circular(w * 0.20),
      )
      ..lineTo(w * 0.70, h * 0.44);

    final shacklePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFCBD5E1), Color(0xFF64748B), Color(0xFFF1F5F9)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(shacklePath, shacklePaint);

    // Heavy Brass Lock Body
    final bodyRect = Rect.fromLTWH(w * 0.20, h * 0.40, w * 0.60, h * 0.48);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFEF08A), Color(0xFFEAB308), Color(0xFFB45309), Color(0xFF78350F)],
      ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(6)),
      bodyPaint,
    );

    // 3 Combination Rotary Dials
    void drawDial(double y) {
      final dialRect = Rect.fromCenter(center: Offset(w * 0.50, y), width: w * 0.38, height: h * 0.09);
      canvas.drawRRect(
        RRect.fromRectAndRadius(dialRect, const Radius.circular(2)),
        Paint()..color = const Color(0xFF1E293B),
      );
      // Dial Tick Marks
      canvas.drawLine(Offset(w * 0.42, y - 2), Offset(w * 0.42, y + 2), Paint()..color = Colors.white);
      canvas.drawLine(Offset(w * 0.50, y - 2), Offset(w * 0.50, y + 2), Paint()..color = const Color(0xFFFDE047));
      canvas.drawLine(Offset(w * 0.58, y - 2), Offset(w * 0.58, y + 2), Paint()..color = Colors.white);
    }

    drawDial(h * 0.51);
    drawDial(h * 0.63);
    drawDial(h * 0.75);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 13. 3D INTERLOCKING GEARS (Settings)
class Icon3DGears extends StatelessWidget {
  final double size;
  const Icon3DGears({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GearsPainter()),
    );
  }
}

class _GearsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Big Brass Gear (Bottom-Left)
    final gear1Center = Offset(w * 0.40, h * 0.60);
    _drawGear(canvas, gear1Center, w * 0.28, 8, const [Color(0xFFFDE047), Color(0xFFD97706), Color(0xFF78350F)]);

    // Small Steel Gear (Top-Right)
    final gear2Center = Offset(w * 0.72, h * 0.36);
    _drawGear(canvas, gear2Center, w * 0.20, 6, const [Color(0xFFF1F5F9), Color(0xFF64748B), Color(0xFF334155)]);
  }

  void _drawGear(Canvas canvas, Offset center, double r, int teeth, List<Color> colors) {
    final path = Path();
    for (int i = 0; i < teeth; i++) {
      final double a = (i * math.pi * 2) / teeth;
      final double halfStep = (math.pi) / teeth;
      final double outerR = r * 1.25;

      final p1 = Offset(center.dx + r * math.cos(a - halfStep * 0.6), center.dy + r * math.sin(a - halfStep * 0.6));
      final p2 = Offset(center.dx + outerR * math.cos(a - halfStep * 0.3), center.dy + outerR * math.sin(a - halfStep * 0.3));
      final p3 = Offset(center.dx + outerR * math.cos(a + halfStep * 0.3), center.dy + outerR * math.sin(a + halfStep * 0.3));
      final p4 = Offset(center.dx + r * math.cos(a + halfStep * 0.6), center.dy + r * math.sin(a + halfStep * 0.6));

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p3.dx, p3.dy);
      path.lineTo(p4.dx, p4.dy);
    }
    path.close();

    final gearPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.3));
    canvas.drawPath(path, gearPaint);

    // Center Axle Hole
    canvas.drawCircle(center, r * 0.40, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(center, r * 0.25, Paint()..color = const Color(0xFFF8FAFC));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 14. 3D PAPER TAPE ROLL (History)
class Icon3DPaperTape extends StatelessWidget {
  final double size;
  const Icon3DPaperTape({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PaperTapePainter()),
    );
  }
}

class _PaperTapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Rolled Paper Coil
    final rollPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.15, w * 0.45, h * 0.7), rollPaint);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.22, h * 0.35, w * 0.2, h * 0.3),
      Paint()..color = const Color(0xFF78350F),
    );

    // Unrolling Tape Strip
    final stripPath = Path()
      ..moveTo(w * 0.32, h * 0.18)
      ..lineTo(w * 0.88, h * 0.18)
      ..lineTo(w * 0.82, h * 0.75)
      ..lineTo(w * 0.88, h * 0.82)
      ..lineTo(w * 0.32, h * 0.82)
      ..close();
    canvas.drawPath(stripPath, rollPaint);

    // Faint Math Lines on Tape
    final linePaint = Paint()
      ..color = const Color(0x66B45309)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.45, h * 0.35), Offset(w * 0.78, h * 0.35), linePaint);
    canvas.drawLine(Offset(w * 0.45, h * 0.50), Offset(w * 0.78, h * 0.50), linePaint);
    canvas.drawLine(Offset(w * 0.45, h * 0.65), Offset(w * 0.78, h * 0.65), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 15. 3D CHEMICAL FLASK (Scientific Mode)
class Icon3DFasciaFlask extends StatelessWidget {
  final double size;
  const Icon3DFasciaFlask({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FasciaFlaskPainter()),
    );
  }
}

class _FasciaFlaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Erlenmeyer Flask Body
    final flaskPath = Path()
      ..moveTo(w * 0.40, h * 0.15)
      ..lineTo(w * 0.60, h * 0.15)
      ..lineTo(w * 0.60, h * 0.38)
      ..lineTo(w * 0.88, h * 0.82)
      ..cubicTo(w * 0.88, h * 0.88, w * 0.78, h * 0.90, w * 0.50, h * 0.90)
      ..cubicTo(w * 0.22, h * 0.90, w * 0.12, h * 0.88, w * 0.12, h * 0.82)
      ..lineTo(w * 0.40, h * 0.38)
      ..close();

    // Glass wall
    final glassPaint = Paint()
      ..color = const Color(0x3360A5FA)
      ..style = PaintingStyle.fill;
    canvas.drawPath(flaskPath, glassPaint);

    final rimPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(flaskPath, rimPaint);

    // Glowing Chemical Liquid in Bottom
    final liquidPath = Path()
      ..moveTo(w * 0.25, h * 0.65)
      ..cubicTo(w * 0.40, h * 0.60, w * 0.60, h * 0.70, w * 0.75, h * 0.65)
      ..lineTo(w * 0.84, h * 0.82)
      ..cubicTo(w * 0.80, h * 0.88, w * 0.60, h * 0.88, w * 0.50, h * 0.88)
      ..cubicTo(w * 0.40, h * 0.88, w * 0.20, h * 0.88, w * 0.16, h * 0.82)
      ..close();

    final liquidPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF059669)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(liquidPath, liquidPaint);

    // Floating Bubble
    canvas.drawCircle(Offset(w * 0.52, h * 0.55), 1.5, Paint()..color = const Color(0xFF6EE7B7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 16. 3D SCISSORS (Standalone)
class Icon3DScissors extends StatelessWidget {
  final double size;
  const Icon3DScissors({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ScissorsPainter()),
    );
  }
}

class _ScissorsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bladePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF8FAFC), Color(0xFF94A3B8), Color(0xFF64748B)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Blade 1
    final p1 = Path()
      ..moveTo(w * 0.25, h * 0.70)
      ..lineTo(w * 0.85, h * 0.25)
      ..lineTo(w * 0.80, h * 0.18)
      ..lineTo(w * 0.20, h * 0.64)
      ..close();
    canvas.drawPath(p1, bladePaint);

    // Blade 2
    final p2 = Path()
      ..moveTo(w * 0.25, h * 0.30)
      ..lineTo(w * 0.85, h * 0.75)
      ..lineTo(w * 0.80, h * 0.82)
      ..lineTo(w * 0.20, h * 0.36)
      ..close();
    canvas.drawPath(p2, bladePaint);

    // Red & Blue Finger Loops
    final loop1 = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.14;
    canvas.drawCircle(Offset(w * 0.20, h * 0.28), w * 0.14, loop1);

    final loop2 = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.14;
    canvas.drawCircle(Offset(w * 0.20, h * 0.72), w * 0.14, loop2);

    // Center Brass Screw
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.08, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.04, Paint()..color = const Color(0xFF78350F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 17. 3D WOODEN RULER (Standalone)
class Icon3DRuler extends StatelessWidget {
  final double size;
  const Icon3DRuler({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RulerPainter()),
    );
  }
}

class _RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final rect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.9, height: h * 0.44);
    final woodPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(rect);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), woodPaint);

    // Brass edge strip
    canvas.drawRect(
      Rect.fromLTWH(w * 0.05, h * 0.28, w * 0.9, 2.5),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFFEF08A), Color(0xFFCA8A04)]).createShader(rect),
    );

    // Engraved ticks
    final tickPaint = Paint()..color = const Color(0xFF78350F)..strokeWidth = 1.0;
    for (double tx = w * 0.10; tx <= w * 0.90; tx += w * 0.09) {
      canvas.drawLine(Offset(tx, h * 0.28), Offset(tx, h * 0.44), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 18. 3D ERASER (Standalone)
class Icon3DEraser extends StatelessWidget {
  final double size;
  const Icon3DEraser({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EraserPainter()),
    );
  }
}

class _EraserPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pink Rubber Left Side
    final pinkPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDA4AF), Color(0xFFFB7185), Color(0xFFE11D48)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final pinkPath = Path()
      ..moveTo(w * 0.12, h * 0.45)
      ..lineTo(w * 0.35, h * 0.22)
      ..lineTo(w * 0.55, h * 0.22)
      ..lineTo(w * 0.35, h * 0.78)
      ..lineTo(w * 0.12, h * 0.78)
      ..close();
    canvas.drawPath(pinkPath, pinkPaint);

    // Blue Vinyl Right Side
    final bluePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF93C5FD), Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final bluePath = Path()
      ..moveTo(w * 0.55, h * 0.22)
      ..lineTo(w * 0.88, h * 0.22)
      ..lineTo(w * 0.88, h * 0.55)
      ..lineTo(w * 0.68, h * 0.78)
      ..lineTo(w * 0.35, h * 0.78)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // White Center Cardboard Sleeve
    final sleevePaint = Paint()..color = Colors.white;
    final sleevePath = Path()
      ..moveTo(w * 0.40, h * 0.22)
      ..lineTo(w * 0.65, h * 0.22)
      ..lineTo(w * 0.52, h * 0.78)
      ..lineTo(w * 0.28, h * 0.78)
      ..close();
    canvas.drawPath(sleevePath, sleevePaint);

    // Outline
    final border = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(pinkPath, border);
    canvas.drawPath(bluePath, border);
    canvas.drawPath(sleevePath, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 19. 3D PENCIL (Standalone)
class Icon3DPencil extends StatelessWidget {
  final double size;
  const Icon3DPencil({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PencilPainter()),
    );
  }
}

class _PencilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(-0.785); // 45 deg

    // Hexagonal Yellow Barrel
    final r1 = Rect.fromLTWH(-w * 0.15, -h * 0.30, w * 0.30, h * 0.50);
    canvas.drawRect(
      r1,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFEF08A), Color(0xFFFBBF24), Color(0xFFD97706)],
        ).createShader(r1),
    );

    // Sharpened Wood Cone (Bottom)
    final woodPath = Path()
      ..moveTo(-w * 0.15, h * 0.20)
      ..lineTo(w * 0.15, h * 0.20)
      ..lineTo(0, h * 0.45)
      ..close();
    canvas.drawPath(woodPath, Paint()..color = const Color(0xFFFED7AA));

    // Graphite Point
    final leadPath = Path()
      ..moveTo(-w * 0.06, h * 0.34)
      ..lineTo(w * 0.06, h * 0.34)
      ..lineTo(0, h * 0.45)
      ..close();
    canvas.drawPath(leadPath, Paint()..color = const Color(0xFF1E293B));

    // Silver Ferrule
    final ferruleRect = Rect.fromLTWH(-w * 0.15, -h * 0.38, w * 0.30, h * 0.08);
    canvas.drawRect(
      ferruleRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFFF8FAFC)],
        ).createShader(ferruleRect),
    );

    // Pink Eraser Dome
    final eraserRect = Rect.fromLTWH(-w * 0.15, -h * 0.48, w * 0.30, h * 0.10);
    canvas.drawRRect(
      RRect.fromRectAndCorners(eraserRect, topLeft: const Radius.circular(5), topRight: const Radius.circular(5)),
      Paint()..color = const Color(0xFFFB7185),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
