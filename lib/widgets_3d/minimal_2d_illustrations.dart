import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// MINIMAL 2D LINE-ART ILLUSTRATIONS (Zero Emojis, 100% Vector Canvas Art)
/// Inspired directly by reference images:
/// - Charcoal line art (1.6px rounded stroke)
/// - Soft Lilac/Lavender circular & organic accent backdrops (#EDE9FE / #F3E8FF)
/// - Crisp, modern, aesthetic 2D graphics
/// ---------------------------------------------------------------------------

class Minimal2DHeroDesk extends StatelessWidget {
  final double width;
  final double height;
  final Color? accentColor;
  final bool isDark;

  const Minimal2DHeroDesk({
    super.key,
    this.width = 160,
    this.height = 110,
    this.accentColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _HeroDeskPainter(
          accentColor: accentColor ?? const Color(0xFFA855F7),
          isDark: isDark,
        ),
      ),
    );
  }
}

class _HeroDeskPainter extends CustomPainter {
  final Color accentColor;
  final bool isDark;

  _HeroDeskPainter({
    required this.accentColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Virtual design canvas 400 x 320
    final scale = size.width / 400.0;
    canvas.save();
    canvas.scale(scale, scale);

    final outlinePaint = Paint()
      ..color = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF181829)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinPaint = Paint()
      ..color = isDark ? const Color(0xFFE4E4E7) : const Color(0xFF181829)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final darkFill = Paint()
      ..color = isDark ? const Color(0xFF27272A) : const Color(0xFF181829)
      ..style = PaintingStyle.fill;

    final skinFill = Paint()
      ..color = isDark ? const Color(0xFF1E1E24) : Colors.white
      ..style = PaintingStyle.fill;

    final pantsFill = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final pantsBackFill = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.85 : 0.75)
      ..style = PaintingStyle.fill;

    final lightAccentFill = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.22 : 0.14)
      ..style = PaintingStyle.fill;

    final midAccentFill = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.45 : 0.35)
      ..style = PaintingStyle.fill;

    // 0. Soft Ambient Background Glow (seamless, no harsh clipping)
    final ambientGlow = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.12 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(200, 180), width: 320, height: 210),
      ambientGlow,
    );

    // 1. Ambient Floating Accents
    canvas.drawCircle(const Offset(45, 85), 4.5, pantsFill);
    canvas.drawCircle(const Offset(165, 45), 3.0, midAccentFill);
    canvas.drawCircle(const Offset(178, 65), 2.0, darkFill);
    canvas.drawCircle(const Offset(310, 80), 2.5, darkFill);
    canvas.drawCircle(const Offset(355, 115), 3.5, midAccentFill);

    // Mini 3x3 dot matrix cluster
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        canvas.drawCircle(
          Offset(305.0 + c * 7.0, 175.0 + r * 7.0),
          1.8,
          midAccentFill,
        );
      }
    }

    // 2. Floor Baseline
    canvas.drawLine(const Offset(25, 285), const Offset(375, 285), outlinePaint);

    // 3. Stool / Office Chair (behind desk)
    // Backrest
    final backrest = RRect.fromRectAndRadius(
      const Rect.fromLTWH(58, 162, 12, 34),
      const Radius.circular(6),
    );
    canvas.drawRRect(backrest, lightAccentFill);
    canvas.drawRRect(backrest, outlinePaint);

    // Seat cushion
    final seat = RRect.fromRectAndRadius(
      const Rect.fromLTWH(62, 196, 56, 11),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(seat, lightAccentFill);
    canvas.drawRRect(seat, outlinePaint);

    // Vertical Stem & Casters
    canvas.drawLine(const Offset(86, 207), const Offset(86, 265), outlinePaint);
    canvas.drawLine(const Offset(86, 218), const Offset(74, 218), outlinePaint);
    canvas.drawCircle(const Offset(72, 218), 2.5, darkFill);

    final casters = Path()
      ..moveTo(58, 278)
      ..lineTo(86, 265)
      ..lineTo(114, 278);
    canvas.drawPath(casters, outlinePaint);
    canvas.drawCircle(const Offset(56, 281), 4, darkFill);
    canvas.drawCircle(const Offset(86, 281), 4, darkFill);
    canvas.drawCircle(const Offset(116, 281), 4, darkFill);

    // 4. Character Legs / Trousers in accentColor
    // Back Leg
    final backLeg = Path()
      ..moveTo(100, 188)
      ..lineTo(155, 188)
      ..cubicTo(162, 188, 166, 194, 165, 204)
      ..lineTo(158, 248)
      ..cubicTo(158, 258, 163, 262, 172, 262)
      ..lineTo(188, 262)
      ..cubicTo(196, 262, 198, 256, 197, 248)
      ..lineTo(192, 198)
      ..cubicTo(190, 188, 182, 178, 168, 178)
      ..lineTo(115, 178)
      ..close();
    canvas.drawPath(backLeg, pantsBackFill);
    canvas.drawPath(backLeg, outlinePaint);

    // Front Leg
    final frontLeg = Path()
      ..moveTo(85, 188)
      ..lineTo(140, 188)
      ..cubicTo(148, 188, 152, 194, 150, 204)
      ..lineTo(142, 248)
      ..cubicTo(141, 258, 146, 262, 155, 262)
      ..lineTo(172, 262)
      ..cubicTo(180, 262, 182, 256, 181, 248)
      ..lineTo(176, 198)
      ..cubicTo(174, 188, 166, 178, 150, 178)
      ..lineTo(98, 178)
      ..close();
    canvas.drawPath(frontLeg, pantsFill);
    canvas.drawPath(frontLeg, outlinePaint);

    // Knee fold
    final kneeFold = Path()
      ..moveTo(148, 196)
      ..quadraticBezierTo(146, 204, 148, 212);
    canvas.drawPath(kneeFold, thinPaint);

    // 5. White Sneakers with black sole
    // Back Sneaker
    final backShoe = Path()
      ..moveTo(172, 262)
      ..lineTo(185, 262)
      ..cubicTo(192, 262, 200, 268, 218, 280)
      ..cubicTo(223, 283, 222, 285, 215, 285)
      ..lineTo(178, 285)
      ..cubicTo(172, 285, 170, 280, 170, 274)
      ..close();
    canvas.drawPath(backShoe, skinFill);
    canvas.drawPath(backShoe, outlinePaint);
    canvas.drawLine(const Offset(172, 282), const Offset(218, 282), outlinePaint);

    // Front Sneaker
    final frontShoe = Path()
      ..moveTo(155, 262)
      ..lineTo(168, 262)
      ..cubicTo(175, 262, 183, 268, 202, 280)
      ..cubicTo(206, 283, 205, 285, 198, 285)
      ..lineTo(160, 285)
      ..cubicTo(155, 285, 153, 280, 153, 274)
      ..close();
    canvas.drawPath(frontShoe, skinFill);
    canvas.drawPath(frontShoe, outlinePaint);
    canvas.drawLine(const Offset(155, 282), const Offset(202, 282), outlinePaint);

    // 6. Character Torso in Black Sweater
    final torso = Path()
      ..moveTo(72, 172)
      ..cubicTo(68, 155, 76, 128, 92, 118)
      ..cubicTo(104, 110, 118, 112, 125, 120)
      ..cubicTo(130, 125, 132, 145, 130, 172)
      ..close();
    canvas.drawPath(torso, darkFill);
    canvas.drawPath(torso, outlinePaint);

    // 7. Arms typing on laptop
    // Left arm
    final leftArm = Path()
      ..moveTo(88, 122)
      ..cubicTo(78, 125, 72, 138, 74, 154)
      ..cubicTo(76, 164, 84, 168, 94, 164)
      ..lineTo(162, 150)
      ..cubicTo(170, 148, 172, 144, 168, 138)
      ..lineTo(126, 135)
      ..cubicTo(118, 133, 110, 125, 102, 118)
      ..close();
    canvas.drawPath(leftArm, darkFill);
    canvas.drawPath(leftArm, outlinePaint);
    // Left hand
    final leftHand = Path()
      ..moveTo(160, 148)
      ..cubicTo(168, 148, 175, 146, 180, 144)
      ..cubicTo(182, 142, 180, 138, 175, 138)
      ..lineTo(160, 140)
      ..close();
    canvas.drawPath(leftHand, skinFill);
    canvas.drawPath(leftHand, outlinePaint);

    // Right arm
    final rightArm = Path()
      ..moveTo(100, 120)
      ..cubicTo(95, 130, 92, 144, 95, 158)
      ..cubicTo(96, 166, 104, 168, 112, 165)
      ..lineTo(175, 152)
      ..cubicTo(182, 150, 184, 146, 180, 140)
      ..lineTo(140, 137)
      ..close();
    canvas.drawPath(rightArm, darkFill);
    canvas.drawPath(rightArm, outlinePaint);
    // Right hand
    final rightHand = Path()
      ..moveTo(172, 150)
      ..cubicTo(180, 150, 186, 148, 190, 146)
      ..cubicTo(192, 144, 190, 140, 185, 140)
      ..lineTo(172, 142)
      ..close();
    canvas.drawPath(rightHand, skinFill);
    canvas.drawPath(rightHand, outlinePaint);

    // 8. Neck & Collar
    final neck = Path()
      ..moveTo(104, 104)
      ..lineTo(104, 116)
      ..lineTo(118, 116)
      ..lineTo(118, 104)
      ..close();
    canvas.drawPath(neck, skinFill);
    canvas.drawPath(neck, outlinePaint);
    final collar = Path()
      ..moveTo(102, 114)
      ..quadraticBezierTo(112, 120, 122, 114);
    canvas.drawPath(collar, skinFill);
    canvas.drawPath(collar, outlinePaint);

    // 9. Head & Features
    final head = Path()
      ..moveTo(106, 98)
      ..cubicTo(100, 94, 100, 82, 106, 74)
      ..cubicTo(112, 66, 126, 62, 134, 66)
      ..cubicTo(142, 70, 144, 82, 142, 92)
      ..cubicTo(140, 100, 132, 106, 122, 106)
      ..cubicTo(114, 106, 108, 102, 106, 98)
      ..close();
    canvas.drawPath(head, skinFill);
    canvas.drawPath(head, outlinePaint);

    // Facial lines
    final brow = Path()
      ..moveTo(127, 75)
      ..quadraticBezierTo(132, 73, 136, 75);
    canvas.drawPath(brow, outlinePaint);
    canvas.drawCircle(const Offset(132, 79), 1.6, darkFill);
    final nose = Path()
      ..moveTo(136, 82)
      ..lineTo(139, 85)
      ..lineTo(135, 86);
    canvas.drawPath(nose, thinPaint);
    final smile = Path()
      ..moveTo(130, 91)
      ..quadraticBezierTo(134, 94, 137, 91);
    canvas.drawPath(smile, thinPaint);
    final ear = Path()
      ..moveTo(110, 84)
      ..cubicTo(108, 81, 108, 89, 112, 90);
    canvas.drawPath(ear, thinPaint);

    // Hair
    final hair = Path()
      ..moveTo(104, 84)
      ..cubicTo(100, 74, 104, 62, 116, 56)
      ..cubicTo(128, 50, 144, 54, 148, 64)
      ..cubicTo(151, 72, 146, 78, 141, 78)
      ..cubicTo(136, 78, 135, 74, 128, 72)
      ..cubicTo(120, 70, 114, 74, 112, 82)
      ..cubicTo(109, 88, 106, 88, 104, 84)
      ..close();
    canvas.drawPath(hair, darkFill);
    canvas.drawPath(hair, outlinePaint);

    // 10. Desk & Accessories
    final table = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 148, 232, 10),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(table, lightAccentFill);
    canvas.drawRRect(table, outlinePaint);

    canvas.drawLine(const Offset(50, 158), const Offset(50, 285), outlinePaint);
    canvas.drawLine(const Offset(254, 158), const Offset(254, 285), outlinePaint);
    canvas.drawLine(const Offset(112, 158), const Offset(112, 285), outlinePaint);

    // Steaming Mug in accentColor
    final mug = RRect.fromRectAndRadius(
      const Rect.fromLTWH(65, 132, 14, 16),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(mug, pantsFill);
    canvas.drawRRect(mug, outlinePaint);
    final mugHandle = Path()
      ..moveTo(65, 136)
      ..cubicTo(59, 136, 59, 144, 65, 144);
    canvas.drawPath(mugHandle, outlinePaint);
    final steam1 = Path()..moveTo(69, 126)..quadraticBezierTo(71, 123, 69, 120);
    final steam2 = Path()..moveTo(74, 127)..quadraticBezierTo(76, 124, 74, 121);
    canvas.drawPath(steam1, thinPaint);
    canvas.drawPath(steam2, thinPaint);

    // Laptop
    final laptopBase = Path()
      ..moveTo(168, 148)
      ..lineTo(222, 148)
      ..lineTo(218, 145)
      ..lineTo(172, 145)
      ..close();
    canvas.drawPath(laptopBase, darkFill);
    canvas.drawPath(laptopBase, outlinePaint);

    final laptopLid = Path()
      ..moveTo(215, 145)
      ..lineTo(238, 108)
      ..cubicTo(239, 106, 237, 105, 234, 105)
      ..lineTo(198, 105)
      ..cubicTo(195, 105, 194, 106, 193, 108)
      ..lineTo(172, 145)
      ..close();
    canvas.drawPath(laptopLid, darkFill);
    canvas.drawPath(laptopLid, outlinePaint);

    final screenGlow = Path()
      ..moveTo(199, 108)
      ..lineTo(233, 108)
      ..lineTo(212, 142)
      ..lineTo(178, 142)
      ..close();
    canvas.drawPath(screenGlow, lightAccentFill);
    canvas.drawCircle(const Offset(216, 122), 2.8, skinFill);

    // Succulent Pot on right
    final pot = Path()
      ..moveTo(235, 135)
      ..lineTo(247, 135)
      ..lineTo(245, 148)
      ..lineTo(237, 148)
      ..close();
    canvas.drawPath(pot, skinFill);
    canvas.drawPath(pot, outlinePaint);

    final leaf1 = Path()
      ..moveTo(241, 135)
      ..cubicTo(238, 128, 240, 122, 242, 122)
      ..cubicTo(244, 122, 246, 128, 243, 135)
      ..close();
    canvas.drawPath(leaf1, pantsFill);
    canvas.drawPath(leaf1, outlinePaint);

    final leaf2 = Path()
      ..moveTo(239, 135)
      ..cubicTo(233, 132, 235, 126, 237, 126)
      ..cubicTo(240, 126, 241, 132, 240, 135)
      ..close();
    canvas.drawPath(leaf2, midAccentFill);
    canvas.drawPath(leaf2, outlinePaint);

    final leaf3 = Path()
      ..moveTo(243, 135)
      ..cubicTo(249, 132, 247, 126, 245, 126)
      ..cubicTo(242, 126, 242, 132, 243, 135)
      ..close();
    canvas.drawPath(leaf3, midAccentFill);
    canvas.drawPath(leaf3, outlinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeroDeskPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor || oldDelegate.isDark != isDark;
}

/// Generic 2D Line Illustration with Adaptive Theme Accent Bubble & Dynamic Inversion
class Minimal2DIcon extends StatelessWidget {
  final String type;
  final double size;
  final Color? color;
  final Color? bubbleColor;
  final Color? accentColor;
  final bool isDark;

  const Minimal2DIcon({
    super.key,
    required this.type,
    this.size = 44,
    this.color,
    this.bubbleColor,
    this.accentColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStroke = color ?? (isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B));
    final effectiveAccent = accentColor ?? const Color(0xFF10B981);
    final effectiveBubble = bubbleColor ??
        (isDark ? effectiveAccent.withValues(alpha: 0.16) : effectiveAccent.withValues(alpha: 0.12));

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          isComplex: true,
          willChange: false,
          painter: _IllustrationPainter(
            type: type,
            strokeColor: effectiveStroke,
            bubbleColor: effectiveBubble,
            accentColor: effectiveAccent,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final String type;
  final Color strokeColor;
  final Color bubbleColor;
  final Color accentColor;
  final bool isDark;

  _IllustrationPainter({
    required this.type,
    required this.strokeColor,
    required this.bubbleColor,
    required this.accentColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Dynamic Accent Bubble Backdrop (centered subtle glow)
    final bubble = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.58, h * 0.44), w * 0.36, bubble);

    // 2. Line Paint (Inverted in dark mode: white #F4F4F5, black #18181B in light mode)
    final p = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillAccent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    switch (type) {
      case 'calc':
        _drawCalc(canvas, w, h, p, fillAccent);
        break;
      case 'converters':
        _drawConverters(canvas, w, h, p, fillAccent);
        break;
      case 'compass':
        _drawCompass(canvas, w, h, p, fillAccent);
        break;
      case 'stopwatch':
        _drawStopwatch(canvas, w, h, p, fillAccent);
        break;
      case 'timer':
        _drawTimer(canvas, w, h, p, fillAccent);
        break;
      case 'alarm':
        _drawAlarm(canvas, w, h, p, fillAccent);
        break;
      case 'age':
        _drawAge(canvas, w, h, p, fillAccent);
        break;
      case 'sizer':
        _drawSizer(canvas, w, h, p, fillAccent);
        break;
      case 'counters':
        _drawCounters(canvas, w, h, p, fillAccent);
        break;
      case 'tasks':
        _drawTasks(canvas, w, h, p, fillAccent);
        break;
      case 'currency':
        _drawCurrency(canvas, w, h, p, fillAccent);
        break;
      case 'games':
        _drawGames(canvas, w, h, p, fillAccent);
        break;
      case 'browser':
        _drawBrowser(canvas, w, h, p, fillAccent);
        break;
      case 'calendar':
        _drawCalendar(canvas, w, h, p, fillAccent);
        break;
      case 'password':
        _drawPassword(canvas, w, h, p, fillAccent);
        break;
      case 'recorder':
      case 'mic':
        _drawMic(canvas, w, h, p, fillAccent);
        break;
      case 'illustrations':
      case 'character':
        _drawCharacterStudio(canvas, w, h, p, fillAccent);
        break;
      case 'power':
      case 'battery':
        _drawPower(canvas, w, h, p, fillAccent);
        break;
      case 'all_tools':
      case 'tools':
        _drawAllTools(canvas, w, h, p, fillAccent);
        break;
      case 'settings':
      default:
        _drawSettings(canvas, w, h, p, fillAccent);
        break;
    }
  }

  void _drawCalc(Canvas canvas, double w, double h, Paint p, Paint fill) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.12, w * 0.60, h * 0.76),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(rrect, p);
    // Display screen
    final disp = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.22, w * 0.40, h * 0.16),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(disp, p);
    // Keys
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 3; c++) {
        final cx = w * 0.32 + c * (w * 0.18);
        final cy = h * 0.48 + r * (h * 0.16);
        if (r == 1 && c == 2) {
          canvas.drawCircle(Offset(cx, cy), w * 0.045, fill);
        } else {
          canvas.drawCircle(Offset(cx, cy), w * 0.045, p);
        }
      }
    }
  }

  void _drawConverters(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Metric Ruler at angle
    final ruler = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.28, w * 0.70, h * 0.44),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(ruler, p);
    // Tick marks
    for (int i = 0; i < 6; i++) {
      final x = w * 0.24 + i * (w * 0.10);
      final tickH = (i % 2 == 0) ? h * 0.18 : h * 0.10;
      canvas.drawLine(Offset(x, h * 0.28), Offset(x, h * 0.28 + tickH), p);
    }
    // Accent indicator dot
    canvas.drawCircle(Offset(w * 0.74, h * 0.58), w * 0.05, fill);
  }

  void _drawCompass(Canvas canvas, double w, double h, Paint p, Paint fill) {
    final center = Offset(w * 0.5, h * 0.5);
    canvas.drawCircle(center, w * 0.36, p);
    // Cardinal ticks
    canvas.drawLine(Offset(w * 0.5, h * 0.18), Offset(w * 0.5, h * 0.26), p);
    canvas.drawLine(Offset(w * 0.5, h * 0.74), Offset(w * 0.5, h * 0.82), p);
    canvas.drawLine(Offset(w * 0.18, h * 0.5), Offset(w * 0.26, h * 0.5), p);
    canvas.drawLine(Offset(w * 0.74, h * 0.5), Offset(w * 0.82, h * 0.5), p);

    // North Needle
    final north = Path()
      ..moveTo(w * 0.5, h * 0.26)
      ..lineTo(w * 0.56, h * 0.5)
      ..lineTo(w * 0.44, h * 0.5)
      ..close();
    canvas.drawPath(north, fill);

    // South Needle
    final south = Path()
      ..moveTo(w * 0.5, h * 0.74)
      ..lineTo(w * 0.56, h * 0.5)
      ..lineTo(w * 0.44, h * 0.5)
      ..close();
    canvas.drawPath(south, p);
    final pinBg = Paint()
      ..color = isDark ? const Color(0xFF1E1E24) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.04, pinBg);
    canvas.drawCircle(center, w * 0.04, p);
  }

  void _drawStopwatch(Canvas canvas, double w, double h, Paint p, Paint fill) {
    final center = Offset(w * 0.5, h * 0.54);
    canvas.drawCircle(center, w * 0.34, p);
    // Top pusher
    canvas.drawLine(Offset(w * 0.5, h * 0.12), Offset(w * 0.5, h * 0.20), p);
    canvas.drawLine(Offset(w * 0.42, h * 0.12), Offset(w * 0.58, h * 0.12), p);
    // Needle pointing at angle
    canvas.drawLine(center, Offset(w * 0.68, h * 0.38), p);
    canvas.drawCircle(center, w * 0.05, fill);
  }

  void _drawTimer(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Modern Hourglass
    final path = Path()
      ..moveTo(w * 0.28, h * 0.20)
      ..lineTo(w * 0.72, h * 0.20)
      ..lineTo(w * 0.56, h * 0.48)
      ..quadraticBezierTo(w * 0.50, h * 0.52, w * 0.44, h * 0.48)
      ..close();
    canvas.drawPath(path, p);

    final pathBot = Path()
      ..moveTo(w * 0.28, h * 0.80)
      ..lineTo(w * 0.72, h * 0.80)
      ..lineTo(w * 0.56, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.48, w * 0.44, h * 0.52)
      ..close();
    canvas.drawPath(pathBot, p);
    // Top & bot bars
    canvas.drawLine(Offset(w * 0.22, h * 0.20), Offset(w * 0.78, h * 0.20), p);
    canvas.drawLine(Offset(w * 0.22, h * 0.80), Offset(w * 0.78, h * 0.80), p);
    // Sand droplet in purple
    canvas.drawCircle(Offset(w * 0.50, h * 0.68), w * 0.06, fill);
  }

  void _drawAlarm(Canvas canvas, double w, double h, Paint p, Paint fill) {
    final center = Offset(w * 0.50, h * 0.56);
    final radius = w * 0.30;

    // Twin Bells on top
    // Left Bell
    final leftBell = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(w * 0.28, h * 0.28), width: w * 0.24, height: w * 0.24),
        3.14159 * 0.9,
        3.14159 * 0.85,
      );
    canvas.drawPath(leftBell, p);

    // Right Bell
    final rightBell = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(w * 0.72, h * 0.28), width: w * 0.24, height: w * 0.24),
        -3.14159 * 0.75,
        3.14159 * 0.85,
      );
    canvas.drawPath(rightBell, p);

    // Top Hammer / Arch
    final hammer = Path()
      ..moveTo(w * 0.44, h * 0.22)
      ..quadraticBezierTo(w * 0.50, h * 0.14, w * 0.56, h * 0.22);
    canvas.drawPath(hammer, p);

    // Peg feet
    canvas.drawLine(Offset(w * 0.30, h * 0.82), Offset(w * 0.22, h * 0.90), p);
    canvas.drawLine(Offset(w * 0.70, h * 0.82), Offset(w * 0.78, h * 0.90), p);

    // Clock Body
    canvas.drawCircle(center, radius, p);

    // Clock Hands (Hour pointing to 10 o'clock, Minute pointing to 2 o'clock)
    canvas.drawLine(center, Offset(w * 0.38, h * 0.44), p);
    canvas.drawLine(center, Offset(w * 0.65, h * 0.42), p);

    // Center Accent Dot
    canvas.drawCircle(center, w * 0.045, fill);

    // Sound wave arcs around bells
    final waveLeft = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(w * 0.16, h * 0.22), width: w * 0.18, height: w * 0.18),
        3.14159 * 0.8,
        3.14159 * 0.5,
      );
    canvas.drawPath(waveLeft, p);

    final waveRight = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(w * 0.84, h * 0.22), width: w * 0.18, height: w * 0.18),
        -3.14159 * 0.3,
        3.14159 * 0.5,
      );
    canvas.drawPath(waveRight, p);
  }

  void _drawAge(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Calendar page
    final cal = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.20, w * 0.60, h * 0.64),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(cal, p);
    // Header line
    canvas.drawLine(Offset(w * 0.20, h * 0.40), Offset(w * 0.80, h * 0.40), p);
    // Binder rings
    canvas.drawLine(Offset(w * 0.36, h * 0.14), Offset(w * 0.36, h * 0.24), p);
    canvas.drawLine(Offset(w * 0.64, h * 0.14), Offset(w * 0.64, h * 0.24), p);
    // Star milestone
    canvas.drawCircle(Offset(w * 0.50, h * 0.58), w * 0.08, fill);
  }

  void _drawSizer(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Caliper frame
    canvas.drawLine(Offset(w * 0.22, h * 0.20), Offset(w * 0.22, h * 0.80), p);
    canvas.drawLine(Offset(w * 0.22, h * 0.20), Offset(w * 0.65, h * 0.20), p);
    canvas.drawLine(Offset(w * 0.65, h * 0.20), Offset(w * 0.65, h * 0.36), p);
    // Sliding jaw
    canvas.drawLine(Offset(w * 0.45, h * 0.16), Offset(w * 0.45, h * 0.40), p);
    canvas.drawCircle(Offset(w * 0.45, h * 0.28), w * 0.05, fill);
  }

  void _drawCounters(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Tally counter box
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.26, w * 0.64, h * 0.52),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(box, p);
    // Top clicker button
    canvas.drawLine(Offset(w * 0.50, h * 0.14), Offset(w * 0.50, h * 0.26), p);
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), w * 0.06, fill);
    // Display digits slots
    canvas.drawLine(Offset(w * 0.32, h * 0.52), Offset(w * 0.44, h * 0.52), p);
    canvas.drawLine(Offset(w * 0.56, h * 0.52), Offset(w * 0.68, h * 0.52), p);
  }

  void _drawTasks(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Clipboard
    final clip = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.56, h * 0.64),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(clip, p);
    // Top clamp
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.14, w * 0.24, h * 0.12),
        Radius.circular(w * 0.04),
      ),
      p,
    );
    // Checkboxes & lines
    for (int i = 0; i < 2; i++) {
      final y = h * 0.44 + i * (h * 0.18);
      if (i == 0) {
        canvas.drawCircle(Offset(w * 0.34, y), w * 0.045, fill);
      } else {
        canvas.drawCircle(Offset(w * 0.34, y), w * 0.045, p);
      }
      canvas.drawLine(Offset(w * 0.44, y), Offset(w * 0.66, y), p);
    }
  }

  void _drawCurrency(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Back coin
    canvas.drawCircle(Offset(w * 0.62, h * 0.44), w * 0.24, fill);
    // Front coin
    final frontCenter = Offset(w * 0.42, h * 0.56);
    final coinBg = Paint()
      ..color = isDark ? const Color(0xFF1E1E24) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(frontCenter, w * 0.24, coinBg);
    canvas.drawCircle(frontCenter, w * 0.24, p);
    // Symbol cross
    canvas.drawLine(Offset(w * 0.42, h * 0.42), Offset(w * 0.42, h * 0.70), p);
    canvas.drawLine(Offset(w * 0.34, h * 0.50), Offset(w * 0.50, h * 0.50), p);
    canvas.drawLine(Offset(w * 0.34, h * 0.60), Offset(w * 0.50, h * 0.60), p);
  }

  void _drawGames(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Gamepad silhouette
    final pad = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.64, h * 0.46),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(pad, p);
    // D-Pad +
    canvas.drawLine(Offset(w * 0.34, h * 0.44), Offset(w * 0.34, h * 0.58), p);
    canvas.drawLine(Offset(w * 0.27, h * 0.51), Offset(w * 0.41, h * 0.51), p);
    // Action buttons
    canvas.drawCircle(Offset(w * 0.62, h * 0.46), w * 0.04, fill);
    canvas.drawCircle(Offset(w * 0.70, h * 0.54), w * 0.04, p);
  }

  void _drawBrowser(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Window card
    final win = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.64, h * 0.58),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(win, p);
    // Top bar
    canvas.drawLine(Offset(w * 0.18, h * 0.38), Offset(w * 0.82, h * 0.38), p);
    // Three dots
    canvas.drawCircle(Offset(w * 0.28, h * 0.30), w * 0.03, fill);
    canvas.drawCircle(Offset(w * 0.36, h * 0.30), w * 0.03, p);
    canvas.drawCircle(Offset(w * 0.44, h * 0.30), w * 0.03, p);
    // Globe curve
    canvas.drawCircle(Offset(w * 0.50, h * 0.58), w * 0.14, p);
    canvas.drawLine(Offset(w * 0.36, h * 0.58), Offset(w * 0.64, h * 0.58), p);
  }

  void _drawPassword(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Padlock body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.44, w * 0.48, h * 0.42),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(body, p);
    // Shackle
    final shackle = Path()
      ..moveTo(w * 0.36, h * 0.44)
      ..lineTo(w * 0.36, h * 0.28)
      ..arcToPoint(
        Offset(w * 0.64, h * 0.28),
        radius: Radius.circular(w * 0.14),
      )
      ..lineTo(w * 0.64, h * 0.44);
    canvas.drawPath(shackle, p);
    // Keyhole
    canvas.drawCircle(Offset(w * 0.50, h * 0.60), w * 0.06, fill);
    canvas.drawLine(Offset(w * 0.50, h * 0.60), Offset(w * 0.50, h * 0.72), p);
  }


  void _drawCharacterStudio(Canvas canvas, double w, double h, Paint p, Paint fill) {
    canvas.drawCircle(Offset(w * 0.50, h * 0.32), w * 0.18, p);
    final body = Path()
      ..moveTo(w * 0.22, h * 0.82)
      ..cubicTo(w * 0.24, h * 0.58, w * 0.38, h * 0.52, w * 0.50, h * 0.52)
      ..cubicTo(w * 0.62, h * 0.52, w * 0.76, h * 0.58, w * 0.78, h * 0.82)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, p);
    canvas.drawCircle(Offset(w * 0.72, h * 0.26), w * 0.08, fill);
  }
  void _drawMic(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Microphone body capsule
    final capsule = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.16, w * 0.24, h * 0.42),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(capsule, p);

    // Sound wave U-bracket cradle
    final cradle = Path()
      ..moveTo(w * 0.26, h * 0.38)
      ..arcToPoint(
        Offset(w * 0.74, h * 0.38),
        radius: Radius.circular(w * 0.24),
        clockwise: false,
      );
    canvas.drawPath(cradle, p);

    // Stand pole
    canvas.drawLine(Offset(w * 0.50, h * 0.62), Offset(w * 0.50, h * 0.80), p);
    // Base line
    canvas.drawLine(Offset(w * 0.32, h * 0.80), Offset(w * 0.68, h * 0.80), p);

    // Live acoustic accent dot in center
    canvas.drawCircle(Offset(w * 0.50, h * 0.30), w * 0.045, fill);
  }

  void _drawSettings(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Adjustment sliders
    canvas.drawLine(Offset(w * 0.22, h * 0.36), Offset(w * 0.78, h * 0.36), p);
    canvas.drawCircle(Offset(w * 0.42, h * 0.36), w * 0.06, fill);

    canvas.drawLine(Offset(w * 0.22, h * 0.64), Offset(w * 0.78, h * 0.64), p);
    canvas.drawCircle(Offset(w * 0.62, h * 0.64), w * 0.06, p);
  }

  void _drawCalendar(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Outer rounded calendar box
    final calRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.56, h * 0.58),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(calRect, p);

    // Top header banner line
    canvas.drawLine(Offset(w * 0.22, h * 0.38), Offset(w * 0.78, h * 0.38), p);

    // Two top hanging binder rings
    canvas.drawLine(Offset(w * 0.36, h * 0.14), Offset(w * 0.36, h * 0.26), p);
    canvas.drawLine(Offset(w * 0.64, h * 0.14), Offset(w * 0.64, h * 0.26), p);

    // Calendar date grid pips
    final r = w * 0.035;
    // Row 1
    canvas.drawCircle(Offset(w * 0.36, h * 0.48), r, p);
    canvas.drawCircle(Offset(w * 0.50, h * 0.48), r, p);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), r, p);

    // Row 2 (with accent event marker)
    canvas.drawCircle(Offset(w * 0.36, h * 0.62), r, p);
    canvas.drawCircle(Offset(w * 0.50, h * 0.62), r * 1.3, fill);
    canvas.drawCircle(Offset(w * 0.64, h * 0.62), r, p);
  }

  void _drawPower(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Battery outer casing
    final shell = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.56, h * 0.44),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(shell, p);

    // Battery positive terminal nipple
    final terminal = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.74, h * 0.39, w * 0.08, h * 0.22),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(terminal, fill);
    canvas.drawRRect(terminal, p);

    // Energy charge lines inside
    canvas.drawLine(Offset(w * 0.28, h * 0.38), Offset(w * 0.28, h * 0.62), p);

    // Lightning bolt in center
    final bolt = Path()
      ..moveTo(w * 0.48, h * 0.31)
      ..lineTo(w * 0.36, h * 0.50)
      ..lineTo(w * 0.46, h * 0.50)
      ..lineTo(w * 0.42, h * 0.69)
      ..lineTo(w * 0.58, h * 0.48)
      ..lineTo(w * 0.48, h * 0.48)
      ..close();
    canvas.drawPath(bolt, fill);
    canvas.drawPath(bolt, p);

    // Full indicator pip
    canvas.drawCircle(Offset(w * 0.64, h * 0.50), w * 0.04, p);
  }

  void _drawAllTools(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // 2x2 grid of modern rounded squares representing All Tools
    final s = w * 0.22;
    final r = Radius.circular(w * 0.06);
    // Top-left (accent filled)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.23, h * 0.23, s, s), r), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.23, h * 0.23, s, s), r), p);
    // Top-right
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, h * 0.23, s, s), r), p);
    // Bottom-left
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.23, h * 0.55, s, s), r), p);
    // Bottom-right
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, h * 0.55, s, s), r), p);
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.bubbleColor != bubbleColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.isDark != isDark;
}
