import 'package:flutter/material.dart';
import 'stationery_theme.dart';

enum NotebookPattern { lined, grid, plain }

/// Clean background painter without lines or paper textures
class NotebookBackgroundPainter extends CustomPainter {
  final StationeryThemeMode mode;
  final NotebookPattern pattern;

  NotebookBackgroundPainter({
    required this.mode,
    this.pattern = NotebookPattern.plain,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pure clean aesthetic background - no notebook blue lines or red margin ink
    final isDark = mode == StationeryThemeMode.blueprintChalkboard;
    final bg = isDark ? const Color(0xFF09090B) : const Color(0xFFFAFAFC);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bg,
    );
  }

  @override
  bool shouldRepaint(covariant NotebookBackgroundPainter oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.pattern != pattern;
}
