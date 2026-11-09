import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D Wooden Ruler with beveled depth and brass edge
class Stationery3DRulerPainter extends CustomPainter {
  final double length;
  final double tiltAngle;

  Stationery3DRulerPainter({this.length = 300, this.tiltAngle = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Wood base gradient
    final Rect rulerRect = Rect.fromLTWH(0, 0, w, h);
    final Paint woodPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE8C39E),
          Color(0xFFD2A679),
          Color(0xFFB58452),
          Color(0xFF8B5E34),
        ],
        stops: [0.0, 0.2, 0.85, 1.0],
      ).createShader(rulerRect);

    // 3D bottom bevel shadow
    final Paint bevelShadow = Paint()
      ..color = const Color(0xFF5A3A1A)
      ..style = PaintingStyle.fill;

    final Path bevelPath = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w - 6, h + 8)
      ..lineTo(6, h + 8)
      ..close();
    canvas.drawPath(bevelPath, bevelShadow);

    // Main body
    canvas.drawRRect(
      RRect.fromRectAndRadius(rulerRect, const Radius.circular(4)),
      woodPaint,
    );

    // Brass edge on top
    final Paint brassPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFDF73), Color(0xFFC99700), Color(0xFFFFEFA6)],
      ).createShader(Rect.fromLTWH(0, 0, w, 4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, 4), const Radius.circular(2)),
      brassPaint,
    );

    // Millimeter and Centimeter tick marks
    final Paint tickPaint = Paint()
      ..color = const Color(0xFF2B1D0E)
      ..strokeWidth = 1.2;

    final Paint cmTickPaint = Paint()
      ..color = const Color(0xFF1E140A)
      ..strokeWidth = 2.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const double cmStep = 28.0;
    int cm = 0;
    for (double x = 16.0; x < w - 16; x += cmStep / 10) {
      final bool isCm = (cm % 10 == 0);
      final bool isHalfCm = (cm % 5 == 0);

      if (isCm) {
        canvas.drawLine(Offset(x, 4), Offset(x, 22), cmTickPaint);
        final int cmNum = cm ~/ 10;
        textPainter.text = TextSpan(
          text: '$cmNum',
          style: const TextStyle(
            color: Color(0xFF2B1D0E),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - (textPainter.width / 2), 24));
      } else if (isHalfCm) {
        canvas.drawLine(Offset(x, 4), Offset(x, 16), tickPaint);
      } else {
        canvas.drawLine(Offset(x, 4), Offset(x, 11), tickPaint);
      }
      cm++;
    }

    // Hand-drawn pencil outline for aesthetic
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF3A2411)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rulerRect, const Radius.circular(4)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant Stationery3DRulerPainter oldDelegate) => false;
}

/// 3D Hexagonal Pencil with Graphite Tip and Rubber Eraser
class Stationery3DPencilPainter extends CustomPainter {
  final Color pencilColor;

  Stationery3DPencilPainter({this.pencilColor = const Color(0xFFFFB300)});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Pencil Body (Hexagonal 3D facets)
    final double facetHeight = h / 3;

    // Facet 1: Top (Highlighted)
    final Paint facet1 = Paint()
      ..color = Color.lerp(pencilColor, Colors.white, 0.35)!;
    canvas.drawRect(Rect.fromLTWH(40, 0, w - 85, facetHeight), facet1);

    // Facet 2: Middle (Base color)
    final Paint facet2 = Paint()..color = pencilColor;
    canvas.drawRect(Rect.fromLTWH(40, facetHeight, w - 85, facetHeight), facet2);

    // Facet 3: Bottom (Shaded)
    final Paint facet3 = Paint()
      ..color = Color.lerp(pencilColor, Colors.black, 0.3)!;
    canvas.drawRect(
      Rect.fromLTWH(40, facetHeight * 2, w - 85, facetHeight),
      facet3,
    );

    // Sharpened Wooden Cone tip (Left)
    final Path woodTip = Path()
      ..moveTo(40, 0)
      ..lineTo(14, h / 2)
      ..lineTo(40, h)
      ..close();
    final Paint woodPaint = Paint()..color = const Color(0xFFE2B788);
    canvas.drawPath(woodTip, woodPaint);

    // Graphite lead tip
    final Path leadTip = Path()
      ..moveTo(22, h * 0.32)
      ..lineTo(8, h / 2)
      ..lineTo(22, h * 0.68)
      ..close();
    final Paint leadPaint = Paint()..color = const Color(0xFF282828);
    canvas.drawPath(leadTip, leadPaint);

    // Gold/Silver Ferrule (Right connector)
    final double ferruleX = w - 45;
    final Paint ferrulePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade400, Colors.grey.shade100, Colors.grey.shade600],
      ).createShader(Rect.fromLTWH(ferruleX, 0, 16, h));
    canvas.drawRect(Rect.fromLTWH(ferruleX, 0, 16, h), ferrulePaint);

    // Pink Rubber Eraser
    final double eraserX = ferruleX + 16;
    final Paint eraserPaint = Paint()..color = const Color(0xFFFF85A2);
    final RRect eraserRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(eraserX, 1, 24, h - 2),
      topRight: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    canvas.drawRRect(eraserRect, eraserPaint);

    // Pencil Border
    final Paint border = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(40, 0, w - 85, h), border);
  }

  @override
  bool shouldRepaint(covariant Stationery3DPencilPainter oldDelegate) => false;
}

/// 3D Metallic Divider / School Compass
class Stationery3DCompassDividerPainter extends CustomPainter {
  final double openAngle; // in radians

  Stationery3DCompassDividerPainter({this.openAngle = 0.45});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset pivot = Offset(size.width / 2, 28);
    final double legLength = size.height - 35;

    // Head / Knob
    final Paint knobPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.grey.shade200, Colors.grey.shade600],
      ).createShader(Rect.fromCircle(center: Offset(pivot.dx, 12), radius: 10));
    canvas.drawCircle(Offset(pivot.dx, 12), 8, knobPaint);

    // Hinge Pivot wheel
    final Paint hingePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.grey.shade100, Colors.grey.shade800],
      ).createShader(Rect.fromCircle(center: pivot, radius: 14));
    canvas.drawCircle(pivot, 12, hingePaint);

    // Metallic Leg Paint
    final Paint metalPaint = Paint()
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [Colors.grey.shade400, Colors.white, Colors.grey.shade700],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Left Leg (Metallic needle)
    final double leftX = pivot.dx - math.sin(openAngle / 2) * legLength;
    final double leftY = pivot.dy + math.cos(openAngle / 2) * legLength;
    canvas.drawLine(pivot, Offset(leftX, leftY), metalPaint);

    // Needle Point
    final Paint needlePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(leftX, leftY),
      Offset(leftX - 4, leftY + 14),
      needlePaint,
    );

    // Right Leg (Pencil holder clamp)
    final double rightX = pivot.dx + math.sin(openAngle / 2) * legLength;
    final double rightY = pivot.dy + math.cos(openAngle / 2) * legLength;
    canvas.drawLine(pivot, Offset(rightX, rightY), metalPaint);

    // Pencil Clamp & Lead
    final Paint clampPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawCircle(Offset(rightX, rightY), 5, clampPaint);
    canvas.drawLine(
      Offset(rightX, rightY),
      Offset(rightX + 3, rightY + 12),
      Paint()
        ..color = const Color(0xFF1B3B6F) // Blue pencil lead
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant Stationery3DCompassDividerPainter oldDelegate) =>
      oldDelegate.openAngle != openAngle;
}

/// 3D Interactive Tumbling Dice
class Stationery3DDiceWidget extends StatelessWidget {
  final int value;
  final double size;
  final VoidCallback? onTap;

  const Stationery3DDiceWidget({
    super.key,
    required this.value,
    this.size = 64,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3A3A3A), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF2C3E50),
              offset: Offset(4, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomPaint(
            painter: _DiceFacePainter(value: value),
          ),
        ),
      ),
    );
  }
}

class _DiceFacePainter extends CustomPainter {
  final int value;
  _DiceFacePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pipPaint = Paint()
      ..color = (value == 1) ? const Color(0xFFFF4757) : const Color(0xFF2F3542);

    final double r = size.width * 0.11;
    final double left = size.width * 0.22;
    final double mid = size.width * 0.5;
    final double right = size.width * 0.78;

    final double top = size.height * 0.22;
    final double center = size.height * 0.5;
    final double bottom = size.height * 0.78;

    void drawPip(double x, double y) {
      canvas.drawCircle(Offset(x, y), r, pipPaint);
    }

    switch (value) {
      case 1:
        canvas.drawCircle(Offset(mid, center), r * 1.5, pipPaint);
        break;
      case 2:
        drawPip(left, top);
        drawPip(right, bottom);
        break;
      case 3:
        drawPip(left, top);
        drawPip(mid, center);
        drawPip(right, bottom);
        break;
      case 4:
        drawPip(left, top);
        drawPip(right, top);
        drawPip(left, bottom);
        drawPip(right, bottom);
        break;
      case 5:
        drawPip(left, top);
        drawPip(right, top);
        drawPip(mid, center);
        drawPip(left, bottom);
        drawPip(right, bottom);
        break;
      case 6:
      default:
        drawPip(left, top);
        drawPip(right, top);
        drawPip(left, center);
        drawPip(right, center);
        drawPip(left, bottom);
        drawPip(right, bottom);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter oldDelegate) =>
      oldDelegate.value != value;
}
