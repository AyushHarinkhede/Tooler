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
      case 'security':
      case 'shield':
        _drawSecurity(canvas, w, h, p, fillAccent);
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
    final cx = w * 0.50;
    final cy = h * 0.53;
    final r = w * 0.35;

    final pThin = Paint()
      ..color = strokeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Vintage navigation casing top loop & mounting collar
    canvas.drawCircle(Offset(cx, h * 0.12), w * 0.055, p);
    canvas.drawLine(Offset(cx - w * 0.045, h * 0.175), Offset(cx + w * 0.045, h * 0.175), p);

    // Outer compass bezel casing & inner dial ring
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawCircle(Offset(cx, cy), r * 0.80, pThin);

    // Cardinal tick marks (N, S, E, W)
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy - r * 0.72), p);
    canvas.drawLine(Offset(cx, cy + r * 0.76), Offset(cx, cy + r), p);
    canvas.drawLine(Offset(cx - r, cy), Offset(cx - r * 0.76, cy), p);
    canvas.drawLine(Offset(cx + r * 0.76, cy), Offset(cx + r, cy), p);

    // 4 Sub-cardinal pips (NE, NW, SE, SW)
    final d = r * 0.80 * 0.7071;
    canvas.drawCircle(Offset(cx + d, cy - d), w * 0.016, p);
    canvas.drawCircle(Offset(cx - d, cy - d), w * 0.016, p);
    canvas.drawCircle(Offset(cx + d, cy + d), w * 0.016, p);
    canvas.drawCircle(Offset(cx - d, cy + d), w * 0.016, p);

    // North apex arrow notch indicator
    final nArrow = Path()
      ..moveTo(cx - w * 0.035, cy - r + w * 0.09)
      ..lineTo(cx, cy - r + w * 0.035)
      ..lineTo(cx + w * 0.035, cy - r + w * 0.09)
      ..close();
    canvas.drawPath(nArrow, fill);

    // 4-Point Faceted Compass Rose & Magnetic Needle
    // North Needle (Faceted: Left facet accent filled, Right facet stroked)
    final nLeft = Path()
      ..moveTo(cx, cy - r * 0.68)
      ..lineTo(cx - w * 0.065, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(nLeft, fill);
    canvas.drawPath(nLeft, p);

    final nRight = Path()
      ..moveTo(cx, cy - r * 0.68)
      ..lineTo(cx + w * 0.065, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(nRight, p);

    // South Needle (Faceted)
    final sLeft = Path()
      ..moveTo(cx, cy + r * 0.64)
      ..lineTo(cx - w * 0.055, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(sLeft, p);

    final sRight = Path()
      ..moveTo(cx, cy + r * 0.64)
      ..lineTo(cx + w * 0.055, cy)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(sRight, p);

    // East & West compass wings
    final wWing = Path()
      ..moveTo(cx - r * 0.42, cy)
      ..lineTo(cx, cy - w * 0.035)
      ..lineTo(cx, cy + w * 0.035)
      ..close();
    canvas.drawPath(wWing, p);

    final eWing = Path()
      ..moveTo(cx + r * 0.42, cy)
      ..lineTo(cx, cy - w * 0.035)
      ..lineTo(cx, cy + w * 0.035)
      ..close();
    canvas.drawPath(eWing, p);

    // Center brass pivot assembly
    final pinBg = Paint()
      ..color = isDark ? const Color(0xFF1E1E24) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), w * 0.045, pinBg);
    canvas.drawCircle(Offset(cx, cy), w * 0.045, p);
    canvas.drawCircle(Offset(cx, cy), w * 0.02, fill);
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
    final pThin = Paint()
      ..color = strokeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final beamY1 = h * 0.33;
    final beamY2 = h * 0.47;

    // Main Vernier scale beam (ruler bar)
    final beamRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.16, beamY1, w * 0.68, beamY2 - beamY1),
      topRight: Radius.circular(w * 0.03),
      bottomRight: Radius.circular(w * 0.03),
    );
    canvas.drawRRect(beamRect, p);

    // Depth gauge probe extending from rear
    canvas.drawLine(Offset(w * 0.84, (beamY1 + beamY2) / 2), Offset(w * 0.90, (beamY1 + beamY2) / 2), p);

    // Millimeter graduation ticks along top of main beam
    for (int i = 0; i < 5; i++) {
      final tx = w * 0.34 + i * (w * 0.09);
      final tHeight = (i % 2 == 0) ? h * 0.07 : h * 0.04;
      canvas.drawLine(Offset(tx, beamY1), Offset(tx, beamY1 + tHeight), pThin);
    }

    // Fixed Jaw (Left end)
    // Lower external measuring jaw
    final fixedJaw = Path()
      ..moveTo(w * 0.16, beamY2)
      ..lineTo(w * 0.16, h * 0.82)
      ..quadraticBezierTo(w * 0.16, h * 0.84, w * 0.23, h * 0.84)
      ..lineTo(w * 0.23, h * 0.58)
      ..lineTo(w * 0.27, beamY2)
      ..close();
    canvas.drawPath(fixedJaw, p);

    // Upper internal measuring nib
    final fixedNib = Path()
      ..moveTo(w * 0.16, beamY1)
      ..lineTo(w * 0.16, h * 0.19)
      ..quadraticBezierTo(w * 0.16, h * 0.17, w * 0.22, h * 0.17)
      ..lineTo(w * 0.22, beamY1)
      ..close();
    canvas.drawPath(fixedNib, p);

    // Movable Vernier Slider Carriage (at w * 0.49 to w * 0.62)
    final slider = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.49, beamY1 - h * 0.03, w * 0.13, (beamY2 - beamY1) + h * 0.06),
      Radius.circular(w * 0.03),
    );
    final sliderBg = Paint()
      ..color = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(slider, sliderBg);
    canvas.drawRRect(slider, p);

    // Top knurled locking thumb screw
    final screw = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.525, h * 0.21, w * 0.06, h * 0.09),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(screw, fill);
    canvas.drawRRect(screw, p);

    // Lower sliding jaw clamping toward fixed jaw
    final slidingJaw = Path()
      ..moveTo(w * 0.49, beamY2 + h * 0.03)
      ..lineTo(w * 0.49, h * 0.80)
      ..quadraticBezierTo(w * 0.50, h * 0.82, w * 0.55, h * 0.76)
      ..lineTo(w * 0.58, beamY2 + h * 0.03)
      ..close();
    canvas.drawPath(slidingJaw, p);

    // Vernier scale ticks on slider body
    canvas.drawLine(Offset(w * 0.53, beamY1 + h * 0.01), Offset(w * 0.53, beamY1 + h * 0.05), pThin);
    canvas.drawLine(Offset(w * 0.56, beamY1 + h * 0.01), Offset(w * 0.56, beamY1 + h * 0.05), pThin);

    // Precision measured ring / workpiece being sized
    final ringCenter = Offset(w * 0.36, h * 0.70);
    canvas.drawCircle(ringCenter, w * 0.075, fill);
    canvas.drawCircle(ringCenter, w * 0.075, p);
    final holeBg = Paint()
      ..color = isDark ? const Color(0xFF18181B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ringCenter, w * 0.035, holeBg);
    canvas.drawCircle(ringCenter, w * 0.035, pThin);
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
    final pThin = Paint()
      ..color = strokeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ergonomic modern console controller silhouette
    final pad = Path()
      ..moveTo(w * 0.50, h * 0.35)
      ..cubicTo(w * 0.58, h * 0.32, w * 0.68, h * 0.32, w * 0.78, h * 0.36)
      ..cubicTo(w * 0.86, h * 0.40, w * 0.88, h * 0.58, w * 0.84, h * 0.72)
      ..cubicTo(w * 0.82, h * 0.80, w * 0.72, h * 0.82, w * 0.67, h * 0.74)
      ..cubicTo(w * 0.62, h * 0.66, w * 0.56, h * 0.58, w * 0.50, h * 0.58)
      ..cubicTo(w * 0.44, h * 0.58, w * 0.38, h * 0.66, w * 0.33, h * 0.74)
      ..cubicTo(w * 0.28, h * 0.82, w * 0.18, h * 0.80, w * 0.16, h * 0.72)
      ..cubicTo(w * 0.12, h * 0.58, w * 0.14, h * 0.40, w * 0.22, h * 0.36)
      ..cubicTo(w * 0.32, h * 0.32, w * 0.42, h * 0.32, w * 0.50, h * 0.35)
      ..close();
    canvas.drawPath(pad, p);

    // Top shoulder triggers (L1 and R1 bumpers)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, h * 0.26, w * 0.13, h * 0.07), Radius.circular(w * 0.03)),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.61, h * 0.26, w * 0.13, h * 0.07), Radius.circular(w * 0.03)),
      p,
    );

    // Left Directional D-Pad (+)
    final dpadCenter = Offset(w * 0.31, h * 0.51);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: dpadCenter, width: w * 0.15, height: h * 0.06), Radius.circular(w * 0.02)),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: dpadCenter, width: w * 0.06, height: h * 0.15), Radius.circular(w * 0.02)),
      p,
    );
    canvas.drawCircle(dpadCenter, w * 0.018, p);

    // Right Action Buttons (ABXY Diamond)
    final btnCenter = Offset(w * 0.69, h * 0.51);
    final rBtn = w * 0.032;
    // Top (Y)
    canvas.drawCircle(Offset(btnCenter.dx, btnCenter.dy - h * 0.08), rBtn, p);
    // Right (B)
    canvas.drawCircle(Offset(btnCenter.dx + w * 0.075, btnCenter.dy), rBtn, p);
    // Bottom (A) - Primary action button in vibrant accent fill!
    canvas.drawCircle(Offset(btnCenter.dx, btnCenter.dy + h * 0.08), rBtn, fill);
    canvas.drawCircle(Offset(btnCenter.dx, btnCenter.dy + h * 0.08), rBtn, p);
    // Left (X)
    canvas.drawCircle(Offset(btnCenter.dx - w * 0.075, btnCenter.dy), rBtn, p);

    // Dual Ergonomic Analog Thumbsticks
    // Left thumbstick (offset lower-right)
    final stickL = Offset(w * 0.42, h * 0.62);
    canvas.drawCircle(stickL, w * 0.045, p);
    canvas.drawCircle(stickL, w * 0.02, pThin);
    // Right thumbstick (offset lower-left)
    final stickR = Offset(w * 0.58, h * 0.62);
    canvas.drawCircle(stickR, w * 0.045, p);
    canvas.drawCircle(stickR, w * 0.02, pThin);

    // Central Glowing Home / Menu Button
    canvas.drawCircle(Offset(w * 0.50, h * 0.44), w * 0.03, fill);
  }

  void _drawBrowser(Canvas canvas, double w, double h, Paint p, Paint fill) {
    final pThin = Paint()
      ..color = strokeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Sleek modern desktop/tablet browser window shell
    final win = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.17, w * 0.70, h * 0.66),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(win, p);

    // Window chrome header divider bar
    canvas.drawLine(Offset(w * 0.15, h * 0.35), Offset(w * 0.85, h * 0.35), p);

    // Traffic light window control dots
    canvas.drawCircle(Offset(w * 0.23, h * 0.26), w * 0.022, fill);
    canvas.drawCircle(Offset(w * 0.29, h * 0.26), w * 0.022, p);
    canvas.drawCircle(Offset(w * 0.35, h * 0.26), w * 0.022, p);

    // Modern URL search capsule / address bar
    final urlBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.42, h * 0.21, w * 0.36, h * 0.10),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(urlBar, p);
    // SSL lock & address line placeholder
    canvas.drawLine(Offset(w * 0.48, h * 0.26), Offset(w * 0.68, h * 0.26), pThin);
    canvas.drawCircle(Offset(w * 0.72, h * 0.26), w * 0.018, fill);

    // Viewport: 3D Spherical Web Globe
    final cx = w * 0.46;
    final cy = h * 0.59;
    final rGlobe = w * 0.17;

    // Outer globe meridian circle
    canvas.drawCircle(Offset(cx, cy), rGlobe, p);
    // Equator line
    canvas.drawLine(Offset(cx - rGlobe, cy), Offset(cx + rGlobe, cy), p);
    // Prime Meridian 3D ellipse
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rGlobe * 0.90, height: rGlobe * 2.0), p);
    // Latitude curvature arcs
    final latRect1 = Rect.fromCenter(center: Offset(cx, cy - rGlobe * 0.48), width: rGlobe * 1.6, height: rGlobe * 0.7);
    canvas.drawArc(latRect1, 0.2, 2.74, false, pThin);
    final latRect2 = Rect.fromCenter(center: Offset(cx, cy + rGlobe * 0.48), width: rGlobe * 1.6, height: rGlobe * 0.7);
    canvas.drawArc(latRect2, -2.94, 2.74, false, pThin);

    // Dynamic web mouse cursor arrow interacting with web content
    final cursor = Path()
      ..moveTo(w * 0.62, h * 0.60)
      ..lineTo(w * 0.74, h * 0.68)
      ..lineTo(w * 0.69, h * 0.69)
      ..lineTo(w * 0.75, h * 0.78)
      ..lineTo(w * 0.71, h * 0.81)
      ..lineTo(w * 0.65, h * 0.72)
      ..lineTo(w * 0.59, h * 0.73)
      ..close();
    canvas.drawPath(cursor, fill);
    canvas.drawPath(cursor, p);
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
    final pThin = Paint()
      ..color = strokeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // High-tech battery vertical outer shell
    final shell = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.24, w * 0.44, h * 0.62),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(shell, p);

    // Battery top positive terminal nipple (+ cap)
    final terminal = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.42, h * 0.16, w * 0.16, h * 0.08),
      topLeft: Radius.circular(w * 0.04),
      topRight: Radius.circular(w * 0.04),
    );
    canvas.drawRRect(terminal, fill);
    canvas.drawRRect(terminal, p);

    // Internal bottom charging energy reservoir level
    final chargeLevel = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.33, h * 0.66, w * 0.34, h * 0.15),
      Radius.circular(w * 0.05),
    );
    final chargeBg = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.30 : 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(chargeLevel, chargeBg);
    canvas.drawRRect(chargeLevel, pThin);

    // High-voltage dynamic electric lightning bolt
    final bolt = Path()
      ..moveTo(w * 0.54, h * 0.30)
      ..lineTo(w * 0.40, h * 0.49)
      ..lineTo(w * 0.51, h * 0.49)
      ..lineTo(w * 0.43, h * 0.72)
      ..lineTo(w * 0.58, h * 0.47)
      ..lineTo(w * 0.47, h * 0.47)
      ..close();
    canvas.drawPath(bolt, fill);
    canvas.drawPath(bolt, p);

    // Polarity telemetry markings (+ at top left, - at bottom right)
    // Plus (+)
    canvas.drawLine(Offset(w * 0.34, h * 0.34), Offset(w * 0.40, h * 0.34), pThin);
    canvas.drawLine(Offset(w * 0.37, h * 0.31), Offset(w * 0.37, h * 0.37), pThin);
    // Minus (-)
    canvas.drawLine(Offset(w * 0.60, h * 0.74), Offset(w * 0.66, h * 0.74), pThin);

    // Wireless / Telemetric charge pulse arcs on flanks
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.19, h * 0.54), width: w * 0.13, height: w * 0.26),
      -1.5,
      3.0,
      false,
      pThin,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.81, h * 0.54), width: w * 0.13, height: w * 0.26),
      1.6,
      3.0,
      false,
      pThin,
    );
  }

  void _drawSecurity(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Elegant Security Shield outline
    final shield = Path()
      ..moveTo(w * 0.50, h * 0.16)
      ..lineTo(w * 0.78, h * 0.28)
      ..lineTo(w * 0.78, h * 0.54)
      ..cubicTo(w * 0.78, h * 0.74, w * 0.50, h * 0.86, w * 0.50, h * 0.86)
      ..cubicTo(w * 0.50, h * 0.86, w * 0.22, h * 0.74, w * 0.22, h * 0.54)
      ..lineTo(w * 0.22, h * 0.28)
      ..close();
    canvas.drawPath(shield, p);

    // Inner checkmark with accent fill
    final check = Path()
      ..moveTo(w * 0.38, h * 0.48)
      ..lineTo(w * 0.47, h * 0.58)
      ..lineTo(w * 0.64, h * 0.38);
    canvas.drawPath(check, fill);
    canvas.drawPath(check, p);

    // Top protective accent pip
    canvas.drawCircle(Offset(w * 0.50, h * 0.28), w * 0.04, fill);
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
