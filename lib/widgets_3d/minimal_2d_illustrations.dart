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

  const Minimal2DHeroDesk({
    super.key,
    this.width = 160,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _HeroDeskPainter(),
      ),
    );
  }
}

class _HeroDeskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Lilac Circle Backdrop
    final bubblePaint = Paint()
      ..color = const Color(0xFFEDE9FE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.46, h * 0.44), w * 0.36, bubblePaint);

    final linePaint = Paint()
      ..color = const Color(0xFF18181B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillLilac = Paint()
      ..color = const Color(0xFFC084FC)
      ..style = PaintingStyle.fill;

    // 2. Desk Lamp overhead
    canvas.drawLine(Offset(w * 0.22, 0), Offset(w * 0.22, h * 0.28), linePaint);
    final lampHead = Path()
      ..moveTo(w * 0.14, h * 0.36)
      ..quadraticBezierTo(w * 0.22, h * 0.26, w * 0.30, h * 0.36)
      ..close();
    canvas.drawPath(lampHead, fillLilac);
    canvas.drawPath(lampHead, linePaint);

    // 3. Desk surface line
    canvas.drawLine(Offset(w * 0.12, h * 0.76), Offset(w * 0.88, h * 0.76), linePaint);
    // Desk legs
    canvas.drawLine(Offset(w * 0.20, h * 0.76), Offset(w * 0.20, h * 0.98), linePaint);
    canvas.drawLine(Offset(w * 0.80, h * 0.76), Offset(w * 0.80, h * 0.98), linePaint);

    // 4. Laptop on desk
    final laptopBase = Path()
      ..moveTo(w * 0.52, h * 0.76)
      ..lineTo(w * 0.74, h * 0.76);
    canvas.drawPath(laptopBase, linePaint);
    // Screen open at angle
    final laptopScreen = Path()
      ..moveTo(w * 0.72, h * 0.76)
      ..lineTo(w * 0.80, h * 0.54)
      ..lineTo(w * 0.65, h * 0.54);
    canvas.drawPath(laptopScreen, linePaint);

    // 5. Minimalist Person sitting at desk
    // Torso in purple tint
    final torso = Path()
      ..moveTo(w * 0.42, h * 0.76)
      ..lineTo(w * 0.40, h * 0.48)
      ..quadraticBezierTo(w * 0.46, h * 0.44, w * 0.54, h * 0.52)
      ..lineTo(w * 0.62, h * 0.70)
      ..lineTo(w * 0.48, h * 0.76)
      ..close();
    canvas.drawPath(torso, fillLilac);
    canvas.drawPath(torso, linePaint);

    // Head
    canvas.drawCircle(Offset(w * 0.45, h * 0.36), w * 0.08, linePaint);
    // Hair
    final hair = Path()
      ..moveTo(w * 0.40, h * 0.34)
      ..quadraticBezierTo(w * 0.46, h * 0.28, w * 0.52, h * 0.34)
      ..close();
    canvas.drawPath(hair, Paint()..color = const Color(0xFF18181B)..style = PaintingStyle.fill);

    // Arm typing on laptop
    final arm = Path()
      ..moveTo(w * 0.48, h * 0.52)
      ..quadraticBezierTo(w * 0.56, h * 0.64, w * 0.68, h * 0.74);
    canvas.drawPath(arm, linePaint);

    // Chair back
    canvas.drawLine(Offset(w * 0.34, h * 0.42), Offset(w * 0.34, h * 0.80), linePaint);
    canvas.drawLine(Offset(w * 0.28, h * 0.80), Offset(w * 0.40, h * 0.80), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Generic 2D Line Illustration with Lavender Accent Bubble
class Minimal2DIcon extends StatelessWidget {
  final String type;
  final double size;
  final Color? color;
  final Color? bubbleColor;

  const Minimal2DIcon({
    super.key,
    required this.type,
    this.size = 44,
    this.color,
    this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IllustrationPainter(
          type: type,
          strokeColor: color ?? const Color(0xFF18181B),
          bubbleColor: bubbleColor ?? const Color(0xFFEDE9FE),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final String type;
  final Color strokeColor;
  final Color bubbleColor;

  _IllustrationPainter({
    required this.type,
    required this.strokeColor,
    required this.bubbleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Lilac Offset Bubble Backdrop (from reference image cards)
    final bubble = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.65, h * 0.38), w * 0.32, bubble);

    // 2. Line Paint
    final p = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillAccent = Paint()
      ..color = const Color(0xFFA855F7)
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
      case 'password':
        _drawPassword(canvas, w, h, p, fillAccent);
        break;
      case 'recorder':
      case 'mic':
        _drawMic(canvas, w, h, p, fillAccent);
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
    canvas.drawCircle(center, w * 0.04, Paint()..color = Colors.white..style = PaintingStyle.fill);
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
    canvas.drawCircle(frontCenter, w * 0.24, Paint()..color = Colors.white..style = PaintingStyle.fill);
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

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.bubbleColor != bubbleColor;
}
