import 'package:flutter/material.dart';
import 'stationery_theme.dart';

enum NotebookPattern { lined, grid, plain }

class NotebookBackgroundPainter extends CustomPainter {
  final StationeryThemeMode mode;
  final NotebookPattern pattern;

  NotebookBackgroundPainter({
    required this.mode,
    this.pattern = NotebookPattern.lined,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isDark = mode != StationeryThemeMode.classicDoodle;
    final Color lineColor = isDark
        ? (mode == StationeryThemeMode.blueprintChalkboard
            ? const Color(0x224A9EFF)
            : const Color(0x18FFFFFF))
        : const Color(0x3393B8D4);

    final Color marginColor = isDark
        ? const Color(0x33FF6B6B)
        : const Color(0x44FF6B6B);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    final Paint marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 1.8;

    if (pattern == NotebookPattern.lined) {
      // Draw horizontal notebook rules
      const double lineSpacing = 32.0;
      const double topOffset = 70.0;

      for (double y = topOffset; y < size.height; y += lineSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }

      // Draw left margin line (classic notebook margin)
      const double marginX = 42.0;
      canvas.drawLine(
        const Offset(marginX, 0),
        Offset(marginX, size.height),
        marginPaint,
      );

      // Draw faint second margin line
      canvas.drawLine(
        const Offset(marginX + 3.0, 0),
        Offset(marginX + 3.0, size.height),
        Paint()
          ..color = marginColor.withOpacity(0.3)
          ..strokeWidth = 1.0,
      );
    } else if (pattern == NotebookPattern.grid) {
      // Draw graph grid paper
      const double gridSize = 24.0;
      for (double x = 0; x < size.width; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NotebookBackgroundPainter oldDelegate) {
    return oldDelegate.mode != mode || oldDelegate.pattern != pattern;
  }
}

class StickyTapeWidget extends StatelessWidget {
  final double width;
  final double height;
  final double angle;
  final Color? color;

  const StickyTapeWidget({
    super.key,
    this.width = 75,
    this.height = 22,
    this.angle = -0.06,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? const Color(0xAAFFE853),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(1, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
