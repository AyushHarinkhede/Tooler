import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// TOOLER OFFICIAL BRANDMARK & LOGO (Zero Emojis, 100% Vector Geometry)
/// Distinctive modern minimalist 2D brand logo:
/// Stylized geometric 'T' monogram with integrated precision caliper & drafting arcs
/// in Deep Slate (#18181B) & Lilac Purple (#A855F7) over soft lavender (#EDE9FE).
/// ---------------------------------------------------------------------------

class ToolerLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? accentColor;

  const ToolerLogo({
    super.key,
    this.size = 40,
    this.showText = false,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ToolerLogoPainter(
          primaryColor: primaryColor ?? const Color(0xFF18181B),
          accentColor: accentColor ?? const Color(0xFFA855F7),
          bgBubbleColor: const Color(0xFFEDE9FE),
        ),
      ),
    );

    if (!showText) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tooler',
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Color(0xFF18181B),
              ),
            ),
            Text(
              'SMART UTILITIES',
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFFA855F7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolerLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final Color bgBubbleColor;

  _ToolerLogoPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.bgBubbleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Lilac Rounded Backdrop Container
    final bgPaint = Paint()
      ..color = bgBubbleColor
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.28),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 2. Lilac Accent Arc (Precision Compass / Draft curve)
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Geometric accent dot / pill
    canvas.drawCircle(Offset(w * 0.74, h * 0.28), w * 0.12, accentPaint);

    // 3. Stylized 'T' Brand Monogram (Precision Tool Crossbar & Stem)
    final tPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Horizontal Crossbar with chamfered drafting edges
    final crossbar = Path()
      ..moveTo(w * 0.22, h * 0.28)
      ..lineTo(w * 0.64, h * 0.28)
      ..arcToPoint(
        Offset(w * 0.64, h * 0.44),
        radius: Radius.circular(w * 0.08),
      )
      ..lineTo(w * 0.22, h * 0.44)
      ..arcToPoint(
        Offset(w * 0.22, h * 0.28),
        radius: Radius.circular(w * 0.08),
      )
      ..close();
    canvas.drawPath(crossbar, tPaint);

    // Vertical Stem with precision ruler notch
    final stem = Path()
      ..moveTo(w * 0.36, h * 0.40)
      ..lineTo(w * 0.50, h * 0.40)
      ..lineTo(w * 0.50, h * 0.76)
      ..arcToPoint(
        Offset(w * 0.36, h * 0.76),
        radius: Radius.circular(w * 0.07),
      )
      ..close();
    canvas.drawPath(stem, tPaint);

    // Precision measurement notch in accent purple
    final notchPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.52, h * 0.56),
      Offset(w * 0.62, h * 0.56),
      notchPaint,
    );
    canvas.drawLine(
      Offset(w * 0.52, h * 0.66),
      Offset(w * 0.59, h * 0.66),
      notchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ToolerLogoPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.bgBubbleColor != bgBubbleColor;
}
