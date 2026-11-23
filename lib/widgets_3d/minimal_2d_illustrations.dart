import 'dart:math' as math;
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
      case 'radio':
      case 'fm':
        _drawRadio(canvas, w, h, p, fillAccent);
        break;
      case 'steps':
      case 'step_counter':
      case 'pedometer':
        _drawSteps(canvas, w, h, p, fillAccent);
        break;
      case 'weather':
      case 'mausam':
        _drawWeather(canvas, w, h, p, fillAccent);
        break;
      case 'all_tools':
      case 'tools':
        _drawAllTools(canvas, w, h, p, fillAccent);
        break;
      case 'speed_test':
      case 'speedtest':
      case 'network':
      case 'wifi':
        _drawSpeedTest(canvas, w, h, p, fillAccent);
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
    final cy = h * 0.50;
    final r = w * 0.34;

    // Clean airy outer compass ring
    canvas.drawCircle(Offset(cx, cy), r, p);

    // Subtle short cardinal ticks (N, S, E, W)
    final tLen = w * 0.055;
    canvas.drawLine(Offset(cx, cy - r + tLen * 0.3), Offset(cx, cy - r + tLen * 1.3), p);
    canvas.drawLine(Offset(cx, cy + r - tLen * 1.3), Offset(cx, cy + r - tLen * 0.3), p);
    canvas.drawLine(Offset(cx - r + tLen * 0.3, cy), Offset(cx - r + tLen * 1.3, cy), p);
    canvas.drawLine(Offset(cx + r - tLen * 1.3, cy), Offset(cx + r - tLen * 0.3, cy), p);

    // Minimal tilted diamond needle (NE in accent fill, SW clean outline)
    final northTip = Offset(cx + r * 0.44, cy - r * 0.44);
    final southTip = Offset(cx - r * 0.44, cy + r * 0.44);
    final midNW = Offset(cx - r * 0.14, cy - r * 0.14);
    final midSE = Offset(cx + r * 0.14, cy + r * 0.14);

    final northNeedle = Path()
      ..moveTo(northTip.dx, northTip.dy)
      ..lineTo(midNW.dx, midNW.dy)
      ..lineTo(midSE.dx, midSE.dy)
      ..close();
    canvas.drawPath(northNeedle, fill);
    canvas.drawPath(northNeedle, p);

    final southNeedle = Path()
      ..moveTo(southTip.dx, southTip.dy)
      ..lineTo(midNW.dx, midNW.dy)
      ..lineTo(midSE.dx, midSE.dy)
      ..close();
    canvas.drawPath(southNeedle, p);

    // Tiny center dot
    final dotBg = Paint()
      ..color = isDark ? const Color(0xFF1E1E24) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), w * 0.035, dotBg);
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
    // Minimal rounded top & bottom caps
    canvas.drawLine(Offset(w * 0.26, h * 0.18), Offset(w * 0.74, h * 0.18), p);
    canvas.drawLine(Offset(w * 0.26, h * 0.82), Offset(w * 0.74, h * 0.82), p);

    // Smooth curved hourglass silhouette (organic, aesthetic pinch at center)
    final glassLeft = Path()
      ..moveTo(w * 0.31, h * 0.18)
      ..cubicTo(w * 0.31, h * 0.38, w * 0.45, h * 0.45, w * 0.45, h * 0.50)
      ..cubicTo(w * 0.45, h * 0.55, w * 0.31, h * 0.62, w * 0.31, h * 0.82);
    canvas.drawPath(glassLeft, p);

    final glassRight = Path()
      ..moveTo(w * 0.69, h * 0.18)
      ..cubicTo(w * 0.69, h * 0.38, w * 0.55, h * 0.45, w * 0.55, h * 0.50)
      ..cubicTo(w * 0.55, h * 0.55, w * 0.69, h * 0.62, w * 0.69, h * 0.82);
    canvas.drawPath(glassRight, p);

    // Soft resting sand mound in bottom bulb (accent fill)
    final sandPile = Path()
      ..moveTo(w * 0.36, h * 0.78)
      ..quadraticBezierTo(w * 0.50, h * 0.61, w * 0.64, h * 0.78)
      ..close();
    canvas.drawPath(sandPile, fill);

    // Tiny falling sand droplet in waist
    canvas.drawCircle(Offset(w * 0.50, h * 0.56), w * 0.032, fill);
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
    // Minimal clean caliper bar (rounded beam)
    final beam = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.30, w * 0.68, h * 0.14),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(beam, p);

    // 3 simple graduation ticks along ruler bar
    canvas.drawLine(Offset(w * 0.34, h * 0.30), Offset(w * 0.34, h * 0.36), p);
    canvas.drawLine(Offset(w * 0.46, h * 0.30), Offset(w * 0.46, h * 0.38), p);
    canvas.drawLine(Offset(w * 0.70, h * 0.30), Offset(w * 0.70, h * 0.36), p);

    // Left fixed caliper jaw (clean simple L-curve)
    final fixedJaw = Path()
      ..moveTo(w * 0.22, h * 0.44)
      ..lineTo(w * 0.22, h * 0.76)
      ..quadraticBezierTo(w * 0.22, h * 0.80, w * 0.28, h * 0.74)
      ..lineTo(w * 0.31, h * 0.44);
    canvas.drawPath(fixedJaw, p);

    // Right sliding caliper jaw with soft accent fill knob
    final slideJaw = Path()
      ..moveTo(w * 0.56, h * 0.44)
      ..lineTo(w * 0.56, h * 0.76)
      ..quadraticBezierTo(w * 0.56, h * 0.80, w * 0.62, h * 0.74)
      ..lineTo(w * 0.65, h * 0.44);
    canvas.drawPath(slideJaw, p);

    // Playful accent slider bead on top of movable jaw
    canvas.drawCircle(Offset(w * 0.60, h * 0.25), w * 0.055, fill);

    // Minimal width measurement line between jaws
    canvas.drawLine(Offset(w * 0.32, h * 0.64), Offset(w * 0.50, h * 0.64), p);
    canvas.drawCircle(Offset(w * 0.41, h * 0.64), w * 0.032, fill);
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
    final center = Offset(w * 0.50, h * 0.50);
    final accentStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Minimal circular coin ring
    canvas.drawCircle(center, w * 0.25, p);

    // Clean minimal Rupee (₹) line-art inside coin
    canvas.drawLine(Offset(w * 0.41, h * 0.39), Offset(w * 0.59, h * 0.39), p);
    canvas.drawLine(Offset(w * 0.41, h * 0.47), Offset(w * 0.57, h * 0.47), p);
    final rupeeCurve = Path()
      ..moveTo(w * 0.49, h * 0.39)
      ..quadraticBezierTo(w * 0.57, h * 0.45, w * 0.43, h * 0.53)
      ..lineTo(w * 0.56, h * 0.63);
    canvas.drawPath(rupeeCurve, p);

    // Two delicate exchange orbit arcs (top-right & bottom-left) in accent color
    final orbitRect = Rect.fromCenter(center: center, width: w * 0.72, height: h * 0.72);
    canvas.drawArc(orbitRect, -1.25, 1.35, false, accentStroke);
    canvas.drawArc(orbitRect, 1.88, 1.35, false, accentStroke);

    // Tiny accent arrowhead dots on the exchange orbit
    canvas.drawCircle(Offset(w * 0.84, h * 0.52), w * 0.036, fill);
    canvas.drawCircle(Offset(w * 0.16, h * 0.48), w * 0.036, fill);
  }

  void _drawGames(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Minimal charming pill-shaped game controller (airy & informal)
    final body = Path()
      ..moveTo(w * 0.32, h * 0.32)
      ..lineTo(w * 0.68, h * 0.32)
      ..cubicTo(w * 0.84, h * 0.32, w * 0.88, h * 0.54, w * 0.82, h * 0.69)
      ..cubicTo(w * 0.78, h * 0.76, w * 0.69, h * 0.74, w * 0.64, h * 0.65)
      ..lineTo(w * 0.36, h * 0.65)
      ..cubicTo(w * 0.31, h * 0.74, w * 0.22, h * 0.76, w * 0.18, h * 0.69)
      ..cubicTo(w * 0.12, h * 0.54, w * 0.16, h * 0.32, w * 0.32, h * 0.32)
      ..close();
    canvas.drawPath(body, p);

    // Simple crisp + D-pad on left
    canvas.drawLine(Offset(w * 0.28, h * 0.49), Offset(w * 0.42, h * 0.49), p);
    canvas.drawLine(Offset(w * 0.35, h * 0.42), Offset(w * 0.35, h * 0.56), p);

    // Two playful action buttons on right (1 accent filled, 1 outline)
    canvas.drawCircle(Offset(w * 0.63, h * 0.52), w * 0.044, p);
    canvas.drawCircle(Offset(w * 0.71, h * 0.45), w * 0.048, fill);
  }

  void _drawBrowser(Canvas canvas, double w, double h, Paint p, Paint fill) {
    final center = Offset(w * 0.48, h * 0.52);
    final r = w * 0.31;

    // Minimal clean open globe
    canvas.drawCircle(center, r, p);
    // Single smooth meridian oval
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 0.96, height: r * 2.0),
      p,
    );
    // Clean horizontal equator
    canvas.drawLine(
      Offset(center.dx - r, center.dy),
      Offset(center.dx + r, center.dy),
      p,
    );
    // Subtle playful accent orbit spark at top-right
    canvas.drawCircle(Offset(w * 0.78, h * 0.24), w * 0.06, fill);
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
    final accentStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    // Minimal soft mic capsule
    final capsule = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.40, h * 0.18, w * 0.20, h * 0.38),
      Radius.circular(w * 0.10),
    );
    final softFill = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.28 : 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(capsule, softFill);
    canvas.drawRRect(capsule, p);

    // Clean U-cradle arc
    final cradle = Path()
      ..moveTo(w * 0.30, h * 0.43)
      ..arcToPoint(
        Offset(w * 0.70, h * 0.43),
        radius: Radius.circular(w * 0.20),
        clockwise: false,
      );
    canvas.drawPath(cradle, p);

    // Simple stand & base
    canvas.drawLine(Offset(w * 0.50, h * 0.63), Offset(w * 0.50, h * 0.78), p);
    canvas.drawLine(Offset(w * 0.36, h * 0.78), Offset(w * 0.64, h * 0.78), p);

    // Minimal noise-meter wave bars flanking left & right in accent color
    canvas.drawLine(Offset(w * 0.20, h * 0.34), Offset(w * 0.20, h * 0.48), accentStroke);
    canvas.drawLine(Offset(w * 0.13, h * 0.39), Offset(w * 0.13, h * 0.43), accentStroke);
    canvas.drawLine(Offset(w * 0.80, h * 0.32), Offset(w * 0.80, h * 0.50), accentStroke);
    canvas.drawLine(Offset(w * 0.87, h * 0.38), Offset(w * 0.87, h * 0.44), accentStroke);
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
    // Minimal clean rounded vertical battery shell
    final shell = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.24, w * 0.44, h * 0.58),
      Radius.circular(w * 0.11),
    );
    canvas.drawRRect(shell, p);

    // Simple positive top cap line
    canvas.drawLine(Offset(w * 0.42, h * 0.17), Offset(w * 0.58, h * 0.17), p);

    // Clean minimal lightning bolt centered inside in accent fill
    final bolt = Path()
      ..moveTo(w * 0.53, h * 0.35)
      ..lineTo(w * 0.41, h * 0.54)
      ..lineTo(w * 0.50, h * 0.54)
      ..lineTo(w * 0.47, h * 0.71)
      ..lineTo(w * 0.59, h * 0.50)
      ..lineTo(w * 0.50, h * 0.50)
      ..close();
    canvas.drawPath(bolt, fill);
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

  void _drawRadio(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // Angled minimal telescopic antenna with accent tip dot
    canvas.drawLine(Offset(w * 0.28, h * 0.36), Offset(w * 0.68, h * 0.16), p);
    canvas.drawCircle(Offset(w * 0.68, h * 0.16), w * 0.036, fill);

    // Clean rounded retro radio casing
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.36, w * 0.64, h * 0.44),
      Radius.circular(w * 0.11),
    );
    canvas.drawRRect(body, p);

    // Subtle frequency dial line across top-right
    canvas.drawLine(Offset(w * 0.46, h * 0.50), Offset(w * 0.72, h * 0.50), p);
    // Accent tuning knob on bottom-right
    canvas.drawCircle(Offset(w * 0.64, h * 0.66), w * 0.068, fill);
    canvas.drawCircle(Offset(w * 0.64, h * 0.66), w * 0.068, p);

    // Minimal speaker circle on left
    canvas.drawCircle(Offset(w * 0.33, h * 0.58), w * 0.09, p);
  }

  void _drawSteps(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // -------------------------------------------------------------------------
    // REALISTIC HIGH-TECH RUNNING SNEAKER & KINETIC STEP ENERGY ENGINE
    // -------------------------------------------------------------------------
    
    // 1. Kinetic speed trailing motion waves behind heel
    final speedWavePaint = Paint()
      ..color = p.color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = p.strokeWidth * 0.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.08, h * 0.54), Offset(w * 0.16, h * 0.54), speedWavePaint);
    canvas.drawLine(Offset(w * 0.05, h * 0.62), Offset(w * 0.17, h * 0.62), speedWavePaint);
    canvas.drawLine(Offset(w * 0.10, h * 0.70), Offset(w * 0.18, h * 0.70), speedWavePaint);

    // 2. Sculpted Outsole & Air-Cushion Midsole (Aerodynamic rocker curve)
    final solePath = Path();
    solePath.moveTo(w * 0.18, h * 0.74);
    solePath.quadraticBezierTo(w * 0.20, h * 0.66, w * 0.26, h * 0.66);
    solePath.lineTo(w * 0.52, h * 0.66);
    solePath.quadraticBezierTo(w * 0.68, h * 0.67, w * 0.82, h * 0.62);
    solePath.quadraticBezierTo(w * 0.88, h * 0.64, w * 0.84, h * 0.72);
    solePath.quadraticBezierTo(w * 0.72, h * 0.75, w * 0.50, h * 0.75);
    solePath.quadraticBezierTo(w * 0.30, h * 0.76, w * 0.20, h * 0.76);
    solePath.quadraticBezierTo(w * 0.17, h * 0.76, w * 0.18, h * 0.74);
    solePath.close();

    // Fill sole with energetic accent
    canvas.drawPath(solePath, fill);
    canvas.drawPath(solePath, p);

    // Midsole Air-Pod Windows / Tread Grooves
    final podPaint = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = p.strokeWidth * 0.7
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.28, h * 0.71), Offset(w * 0.38, h * 0.71), podPaint);
    canvas.drawLine(Offset(w * 0.44, h * 0.71), Offset(w * 0.56, h * 0.71), podPaint);
    canvas.drawLine(Offset(w * 0.62, h * 0.70), Offset(w * 0.72, h * 0.69), podPaint);

    // 3. Ergonomic Sneaker Upper (Breathable Mesh Silhouette)
    final upperPath = Path();
    upperPath.moveTo(w * 0.26, h * 0.66);
    upperPath.lineTo(w * 0.24, h * 0.50);
    // Padded heel collar
    upperPath.quadraticBezierTo(w * 0.25, h * 0.42, w * 0.34, h * 0.44);
    // Ankle scoop
    upperPath.quadraticBezierTo(w * 0.38, h * 0.47, w * 0.44, h * 0.45);
    // Extended running tongue
    upperPath.lineTo(w * 0.48, h * 0.38);
    upperPath.quadraticBezierTo(w * 0.52, h * 0.39, w * 0.54, h * 0.45);
    // Forefoot instep to sleek toe box
    upperPath.quadraticBezierTo(w * 0.68, h * 0.52, w * 0.82, h * 0.62);
    upperPath.lineTo(w * 0.52, h * 0.66);
    upperPath.close();

    canvas.drawPath(upperPath, p);

    // 4. Heel Stabilizer Counter (Sleek aerodynamic cage)
    final heelCage = Path();
    heelCage.moveTo(w * 0.24, h * 0.56);
    heelCage.quadraticBezierTo(w * 0.34, h * 0.54, w * 0.36, h * 0.66);
    canvas.drawPath(heelCage, p);

    // 5. Dynamic Cross-Laces & Eyelets
    canvas.drawLine(Offset(w * 0.44, h * 0.47), Offset(w * 0.48, h * 0.51), p);
    canvas.drawLine(Offset(w * 0.49, h * 0.49), Offset(w * 0.54, h * 0.53), p);
    canvas.drawLine(Offset(w * 0.55, h * 0.51), Offset(w * 0.60, h * 0.55), p);

    // 6. Kinetic Energy Arcs (Step cadence waves radiating ahead)
    final energyPaint = Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = p.strokeWidth * 0.95
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.72, h * 0.34), radius: w * 0.18),
      -math.pi * 0.65,
      math.pi * 0.9,
      false,
      p,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.72, h * 0.34), radius: w * 0.12),
      -math.pi * 0.65,
      math.pi * 0.9,
      false,
      energyPaint,
    );

    // Center cadence pulse pip
    canvas.drawCircle(Offset(w * 0.72, h * 0.34), w * 0.045, fill);
    canvas.drawCircle(Offset(w * 0.72, h * 0.34), w * 0.045, p);
  }

  void _drawWeather(Canvas canvas, double w, double h, Paint p, Paint fill) {
    // 1. Pure Minimal Sun Peeking Behind Cloud (Upper Right)
    final sunCenter = Offset(w * 0.63, h * 0.36);
    final sunRadius = w * 0.16;

    // Sun Disc Body (Accent Fill + Line Outline)
    canvas.drawCircle(sunCenter, sunRadius, fill);
    canvas.drawCircle(sunCenter, sunRadius, p);

    // 2. Minimalist Vector Cloud with Soft Flowing Curves (Foreground)
    final cloud = Path();
    cloud.moveTo(w * 0.25, h * 0.68);
    cloud.lineTo(w * 0.73, h * 0.68);
    cloud.arcToPoint(Offset(w * 0.81, h * 0.56), radius: Radius.circular(w * 0.12));
    cloud.arcToPoint(Offset(w * 0.64, h * 0.44), radius: Radius.circular(w * 0.14));
    cloud.arcToPoint(Offset(w * 0.38, h * 0.46), radius: Radius.circular(w * 0.17));
    cloud.arcToPoint(Offset(w * 0.19, h * 0.58), radius: Radius.circular(w * 0.13));
    cloud.arcToPoint(Offset(w * 0.25, h * 0.68), radius: Radius.circular(w * 0.10));
    cloud.close();

    final bgFill = Paint()
      ..color = isDark ? const Color(0xFF18181B) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(cloud, bgFill);
    canvas.drawPath(cloud, p);
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

  void _drawSpeedTest(Canvas canvas, double w, double h, Paint p, Paint fill) {
    final center = Offset(w * 0.5, h * 0.62);
    final radius = w * 0.32;
    // Outer arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.85,
      math.pi * 1.30,
      false,
      p..strokeWidth = 2.4,
    );
    // Needle
    final needlePaint = Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final needleTip = Offset(
      center.dx + (radius * 0.75) * math.cos(math.pi * 1.6),
      center.dy + (radius * 0.75) * math.sin(math.pi * 1.6),
    );
    canvas.drawLine(center, needleTip, needlePaint);
    // Center knob
    canvas.drawCircle(center, 4.0, fill);
    canvas.drawCircle(center, 4.0, p..strokeWidth = 1.6);
    // Radiating WiFi / 5G signal arcs below
    final wavePaint = Paint()
      ..color = p.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.38, h * 0.80), Offset(w * 0.62, h * 0.80), wavePaint);
    canvas.drawLine(Offset(w * 0.44, h * 0.87), Offset(w * 0.56, h * 0.87), wavePaint);
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.bubbleColor != bubbleColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.isDark != isDark;
}
