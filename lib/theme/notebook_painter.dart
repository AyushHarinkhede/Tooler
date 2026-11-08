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
        : const Color(0x3882B1FF); // Clean school notebook blue line

    final Color marginColor = isDark
        ? const Color(0x33FF6B6B)
        : const Color(0x55FF5252); // Red margin ink

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    final Paint marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 1.6;

    if (pattern == NotebookPattern.lined) {
      // 1. Subtle Paper Texture (Faint fibers)
      if (!isDark) {
        final fiberPaint = Paint()
          ..color = const Color(0x06000000)
          ..strokeWidth = 0.5;
        for (double fx = 10; fx < size.width; fx += 35) {
          canvas.drawLine(Offset(fx, 0), Offset(fx + 10, size.height), fiberPaint);
        }
      }

      // 2. Horizontal Notebook Rules
      const double lineSpacing = 28.0;
      const double topOffset = 82.0; // Header index space is kept clean

      for (double y = topOffset; y < size.height; y += lineSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }

      // 3. Double Vertical Red Margin Line
      const double marginX = 36.0;
      canvas.drawLine(
        const Offset(marginX, 0),
        Offset(marginX, size.height),
        marginPaint,
      );
      canvas.drawLine(
        const Offset(marginX + 3.0, 0),
        Offset(marginX + 3.0, size.height),
        Paint()
          ..color = marginColor.withValues(alpha: 0.35)
          ..strokeWidth = 0.8,
      );
    } else if (pattern == NotebookPattern.grid) {
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
        ),
      ),
    );
  }
}
