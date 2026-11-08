import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// MINIMAL HAND-DRAWN INK ICONS
/// Authentic stroke-based ink illustrations that appear genuinely drawn /
/// sketched directly with a fine black gel pen onto sticky notes.
/// Minimalist, aesthetic, 100% vector, zero emojis, zero cartoonish 3D clutter.
/// ---------------------------------------------------------------------------

class MinimalInkIcon extends StatelessWidget {
  final Widget Function(Canvas, Size, Paint) painter;
  final double size;
  final Color color;
  final double strokeWidth;

  const MinimalInkIcon({
    super.key,
    required this.painter,
    this.size = 24,
    this.color = const Color(0xFF1E293B),
    this.strokeWidth = 1.8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GenericInkPainter(
          paintFunc: painter,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _GenericInkPainter extends CustomPainter {
  final Widget Function(Canvas, Size, Paint) paintFunc;
  final Color color;
  final double strokeWidth;

  _GenericInkPainter({
    required this.paintFunc,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    paintFunc(canvas, size, paint);
  }

  @override
  bool shouldRepaint(covariant _GenericInkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// 1. Hand-Drawn Calendar (Age Calculator)
class InkCalendarIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkCalendarIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;

        // Calendar body
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.15, h * 0.22, w * 0.70, h * 0.68),
          const Radius.circular(4),
        );
        canvas.drawRRect(rrect, p);

        // Header separator
        canvas.drawLine(Offset(w * 0.15, h * 0.44), Offset(w * 0.85, h * 0.44), p);

        // Spiral binder rings
        canvas.drawLine(Offset(w * 0.32, h * 0.12), Offset(w * 0.32, h * 0.24), p);
        canvas.drawLine(Offset(w * 0.68, h * 0.12), Offset(w * 0.68, h * 0.24), p);

        // Little date dots / grid
        final fillPaint = Paint()..color = p.color..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.35, h * 0.60), 1.5, fillPaint);
        canvas.drawCircle(Offset(w * 0.50, h * 0.60), 1.5, fillPaint);
        canvas.drawCircle(Offset(w * 0.65, h * 0.60), 1.5, fillPaint);
        canvas.drawCircle(Offset(w * 0.35, h * 0.76), 1.5, fillPaint);
        canvas.drawCircle(Offset(w * 0.50, h * 0.76), 1.5, fillPaint);
        return const SizedBox.shrink();
      },
    );
  }
}

/// 2. Hand-Drawn Ruler (Converters)
class InkRulerIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkRulerIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;

        // Angled 45 deg ruler
        canvas.save();
        canvas.translate(w * 0.5, h * 0.5);
        canvas.rotate(-0.785);

        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 1.0, height: h * 0.36),
          const Radius.circular(2),
        );
        canvas.drawRRect(rrect, p);

        // Tick marks
        for (double tx = -w * 0.38; tx <= w * 0.38; tx += w * 0.15) {
          final double th = (tx.abs() < 2) ? h * 0.16 : h * 0.10;
          canvas.drawLine(Offset(tx, -h * 0.18), Offset(tx, -h * 0.18 + th), p);
        }

        canvas.restore();
        return const SizedBox.shrink();
      },
    );
  }
}

/// 3. Hand-Drawn Stopwatch (Stopwatch)
class InkStopwatchIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkStopwatchIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;
        final center = Offset(w * 0.5, h * 0.54);
        final r = w * 0.36;

        // Dial circle
        canvas.drawCircle(center, r, p);

        // Top pusher & stem
        canvas.drawLine(Offset(w * 0.5, h * 0.18), Offset(w * 0.5, h * 0.10), p);
        canvas.drawLine(Offset(w * 0.40, h * 0.10), Offset(w * 0.60, h * 0.10), p);

        // Hands
        canvas.drawLine(center, Offset(center.dx, center.dy - r * 0.65), p);
        canvas.drawLine(center, Offset(center.dx + r * 0.45, center.dy), p);

        // Center point
        canvas.drawCircle(center, 1.8, Paint()..color = p.color..style = PaintingStyle.fill);
        return const SizedBox.shrink();
      },
    );
  }
}

/// 4. Hand-Drawn Hourglass (Timer)
class InkHourglassIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkHourglassIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;

        // Top & bottom bars
        canvas.drawLine(Offset(w * 0.20, h * 0.15), Offset(w * 0.80, h * 0.15), p);
        canvas.drawLine(Offset(w * 0.20, h * 0.85), Offset(w * 0.80, h * 0.85), p);

        // Glass ampoule
        final path = Path()
          ..moveTo(w * 0.26, h * 0.15)
          ..lineTo(w * 0.74, h * 0.15)
          ..cubicTo(w * 0.70, h * 0.42, w * 0.55, h * 0.48, w * 0.50, h * 0.50)
          ..cubicTo(w * 0.55, h * 0.52, w * 0.70, h * 0.58, w * 0.74, h * 0.85)
          ..lineTo(w * 0.26, h * 0.85)
          ..cubicTo(w * 0.30, h * 0.58, w * 0.45, h * 0.52, w * 0.50, h * 0.50)
          ..cubicTo(w * 0.45, h * 0.48, w * 0.30, h * 0.42, w * 0.26, h * 0.15)
          ..close();
        canvas.drawPath(path, p);

        // Sand dots
        final fill = Paint()..color = p.color..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.5, h * 0.50), 1.2, fill);
        canvas.drawCircle(Offset(w * 0.5, h * 0.65), 1.2, fill);
        canvas.drawLine(Offset(w * 0.42, h * 0.80), Offset(w * 0.58, h * 0.80), p);

        return const SizedBox.shrink();
      },
    );
  }
}

/// 5. Hand-Drawn Ring & Caliper (Sizer Tools)
class InkSizerIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkSizerIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;
        final center = Offset(w * 0.5, h * 0.55);

        // Ring oval
        canvas.drawOval(Rect.fromCenter(center: center, width: w * 0.55, height: h * 0.45), p);

        // Diamond gem
        final gemPath = Path()
          ..moveTo(center.dx, center.dy - h * 0.24)
          ..lineTo(center.dx + w * 0.12, center.dy - h * 0.14)
          ..lineTo(center.dx, center.dy - h * 0.08)
          ..lineTo(center.dx - w * 0.12, center.dy - h * 0.14)
          ..close();
        canvas.drawPath(gemPath, p);

        // Sparkle tick
        canvas.drawLine(
          Offset(center.dx + w * 0.16, center.dy - h * 0.22),
          Offset(center.dx + w * 0.24, center.dy - h * 0.28),
          p,
        );

        return const SizedBox.shrink();
      },
    );
  }
}

/// 6. Hand-Drawn Tally Clicker (Custom Counters)
class InkCounterIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkCounterIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;

        // Counter case
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.64, h * 0.54),
          const Radius.circular(6),
        );
        canvas.drawRRect(rrect, p);

        // Top button plunger
        canvas.drawLine(Offset(w * 0.40, h * 0.28), Offset(w * 0.40, h * 0.16), p);
        canvas.drawLine(Offset(w * 0.60, h * 0.28), Offset(w * 0.60, h * 0.16), p);
        canvas.drawLine(Offset(w * 0.34, h * 0.16), Offset(w * 0.66, h * 0.16), p);

        // Display window
        canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.42, w * 0.44, h * 0.24), p);

        // Tally number "+1"
        final fill = Paint()..color = p.color..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.42, h * 0.54), 1.2, fill);
        canvas.drawCircle(Offset(w * 0.58, h * 0.54), 1.2, fill);

        return const SizedBox.shrink();
      },
    );
  }
}

/// 7. Hand-Drawn Clipboard (Task Manager)
class InkClipboardIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkClipboardIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;

        // Clipboard board
        final board = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.72),
          const Radius.circular(4),
        );
        canvas.drawRRect(board, p);

        // Top clip
        final clip = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.34, h * 0.10, w * 0.32, h * 0.14),
          const Radius.circular(2),
        );
        canvas.drawRRect(clip, p);

        // Checkmark items
        final tick1 = Path()..moveTo(w * 0.28, h * 0.42)..lineTo(w * 0.34, h * 0.48)..lineTo(w * 0.44, h * 0.38);
        canvas.drawPath(tick1, p);
        canvas.drawLine(Offset(w * 0.48, h * 0.44), Offset(w * 0.72, h * 0.44), p);

        final tick2 = Path()..moveTo(w * 0.28, h * 0.64)..lineTo(w * 0.34, h * 0.70)..lineTo(w * 0.44, h * 0.60);
        canvas.drawPath(tick2, p);
        canvas.drawLine(Offset(w * 0.48, h * 0.66), Offset(w * 0.72, h * 0.66), p);

        return const SizedBox.shrink();
      },
    );
  }
}

/// 8. Hand-Drawn Coins (Currency Converter)
class InkCoinsIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkCoinsIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;

        // Back coin
        canvas.drawCircle(Offset(w * 0.62, h * 0.42), w * 0.26, p);

        // Front coin
        final frontCenter = Offset(w * 0.40, h * 0.58);
        canvas.drawCircle(frontCenter, w * 0.28, p);

        // Currency stroke (₹ symbol sketch)
        canvas.drawLine(Offset(w * 0.32, h * 0.50), Offset(w * 0.48, h * 0.50), p);
        canvas.drawLine(Offset(w * 0.32, h * 0.56), Offset(w * 0.48, h * 0.56), p);
        canvas.drawLine(Offset(w * 0.36, h * 0.56), Offset(w * 0.44, h * 0.68), p);

        return const SizedBox.shrink();
      },
    );
  }
}

/// 9. Hand-Drawn Dice (Games Arcade)
class InkDiceIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkDiceIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;

        // Isometric cube sketch
        final top = Path()
          ..moveTo(w * 0.50, h * 0.15)
          ..lineTo(w * 0.82, h * 0.32)
          ..lineTo(w * 0.50, h * 0.50)
          ..lineTo(w * 0.18, h * 0.32)
          ..close();
        canvas.drawPath(top, p);

        final left = Path()
          ..moveTo(w * 0.18, h * 0.32)
          ..lineTo(w * 0.50, h * 0.50)
          ..lineTo(w * 0.50, h * 0.85)
          ..lineTo(w * 0.18, h * 0.68)
          ..close();
        canvas.drawPath(left, p);

        final right = Path()
          ..moveTo(w * 0.50, h * 0.50)
          ..lineTo(w * 0.82, h * 0.32)
          ..lineTo(w * 0.82, h * 0.68)
          ..lineTo(w * 0.50, h * 0.85)
          ..close();
        canvas.drawPath(right, p);

        // Center pip on top
        final fill = Paint()..color = p.color..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.50, h * 0.32), 1.8, fill);

        return const SizedBox.shrink();
      },
    );
  }
}

/// 10. Hand-Drawn Globe (Web Browser)
class InkGlobeIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkGlobeIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;
        final center = Offset(w * 0.48, h * 0.44);
        final r = w * 0.30;

        // Globe sphere
        canvas.drawCircle(center, r, p);

        // Meridian curve
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r * 1.25),
          -math.pi * 0.75,
          math.pi * 1.05,
          false,
          p,
        );

        // Stand stem & base
        canvas.drawLine(Offset(w * 0.48, h * 0.74), Offset(w * 0.48, h * 0.85), p);
        canvas.drawLine(Offset(w * 0.30, h * 0.85), Offset(w * 0.66, h * 0.85), p);

        // Latitude line
        canvas.drawOval(Rect.fromCenter(center: center, width: r * 1.9, height: r * 0.6), p);

        return const SizedBox.shrink();
      },
    );
  }
}

/// 11. Hand-Drawn Compass (Digital Compass)
class InkCompassIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkCompassIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;
        final center = Offset(w * 0.5, h * 0.5);
        final r = w * 0.38;

        // Outer circle
        canvas.drawCircle(center, r, p);

        // 4 cardinal tick marks
        canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy - r + 3), p);
        canvas.drawLine(Offset(center.dx, center.dy + r), Offset(center.dx, center.dy + r - 3), p);
        canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx - r + 3, center.dy), p);
        canvas.drawLine(Offset(center.dx + r, center.dy), Offset(center.dx + r - 3, center.dy), p);

        // Needle (diamond star)
        final needle = Path()
          ..moveTo(center.dx, center.dy - r * 0.70)
          ..lineTo(center.dx + 3, center.dy)
          ..lineTo(center.dx, center.dy + r * 0.70)
          ..lineTo(center.dx - 3, center.dy)
          ..close();
        canvas.drawPath(needle, p);

        // Center dot
        canvas.drawCircle(center, 1.8, Paint()..color = p.color..style = PaintingStyle.fill);

        return const SizedBox.shrink();
      },
    );
  }
}

/// 12. Hand-Drawn Padlock (Password Generator)
class InkPadlockIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkPadlockIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;

        // U-shackle
        final shackle = Path()
          ..moveTo(w * 0.32, h * 0.44)
          ..lineTo(w * 0.32, h * 0.26)
          ..arcToPoint(Offset(w * 0.68, h * 0.26), radius: Radius.circular(w * 0.18))
          ..lineTo(w * 0.68, h * 0.44);
        canvas.drawPath(shackle, p);

        // Lock body
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.42, w * 0.56, h * 0.46),
          const Radius.circular(4),
        );
        canvas.drawRRect(body, p);

        // Keyhole
        final center = Offset(w * 0.50, h * 0.60);
        canvas.drawCircle(center, 2.5, Paint()..color = p.color..style = PaintingStyle.fill);
        canvas.drawLine(center, Offset(center.dx, center.dy + 6), p..strokeWidth = 2.0);

        return const SizedBox.shrink();
      },
    );
  }
}

/// 13. Hand-Drawn Gears (Settings)
class InkGearsIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkGearsIcon({super.key, this.size = 24, this.color = const Color(0xFF1E293B)});

  @override
  Widget build(BuildContext context) {
    return MinimalInkIcon(
      size: size,
      color: color,
      painter: (canvas, s, p) {
        final w = s.width;
        final h = s.height;
        final center = Offset(w * 0.5, h * 0.5);
        final r = w * 0.24;

        // Central gear body
        canvas.drawCircle(center, r, p);
        canvas.drawCircle(center, r * 0.4, p);

        // 6 Gear teeth
        for (int i = 0; i < 6; i++) {
          final double angle = i * math.pi / 3;
          final p1 = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
          final p2 = Offset(center.dx + (r + 4) * math.cos(angle), center.dy + (r + 4) * math.sin(angle));
          canvas.drawLine(p1, p2, p..strokeWidth = 2.4);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
