import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER AESTHETIC HOVER POP-UP SHEET (Screen 3 Reference Match)
/// Directly replicates Screen 3 from uploaded user images:
/// - Top colored pastel background (#EDE9FE / lavenderCard)
/// - 2D Vector Line Art: Hanging Lamp with Curly Cord & Delicate Plant Leaves
/// - Circular Back Button (<) on top left + Favorite Star on top right
/// - Pure White container sliding up with large rounded top corners (Radius 32)
/// - Title, rating pill (★ 4.9), subtitle, tag chips, and embedded tool content
/// - Silky smooth slide-up and fade transition
/// ---------------------------------------------------------------------------

class ToolerHoverSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final StationeryTheme theme;
  final Widget child;
  final VoidCallback? onFavorite;

  const ToolerHoverSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.theme,
    required this.child,
    this.onFavorite,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String tag,
    required StationeryTheme theme,
    required Widget child,
  }) {
    SoundService().playClick();
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ToolerHoverSheet(
            title: title,
            subtitle: subtitle,
            tag: tag,
            theme: theme,
            child: child,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, page) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: page,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Pastel Header Area with 2D Line Art (Hanging Lamp & Plant)
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.lavenderBubble,
              ),
              child: Stack(
                children: [
                  // 2D Line Art: Hanging Lamp, Curly Wire & Plant Leaves
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AestheticHeaderArtPainter(
                        strokeColor: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
                        accentColor: theme.primary,
                      ),
                    ),
                  ),

                  // Top Action Controls: Circular Back Button & Star
                  Positioned(
                    top: 14,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Circular Outline Back Button (<)
                        InkWell(
                          onTap: () {
                            SoundService().playClick();
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: theme.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.border, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: theme.text,
                            ),
                          ),
                        ),

                        // Circular Favorite / Star Button
                        InkWell(
                          onTap: () {
                            SoundService().playClick();
                            if (onFavorite != null) onFavorite!();
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: theme.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.border, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 19,
                              color: theme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Sliding White Container (Top Radius 32)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: theme.border,
                    width: 1.2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: Column(
                    children: [
                      // Little Drag Handle Bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Tool Title Header & Tags
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: theme.text,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),
                      Divider(color: theme.border, height: 1),

                      // Tool's interactive body
                      Expanded(
                        child: child,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 2D ARTWORK: HANGING LAMP WITH CURLY WIRE & BOTANICAL PLANT LEAVES
/// (Directly matching Screen 3 from user images!)
/// ---------------------------------------------------------------------------
class _AestheticHeaderArtPainter extends CustomPainter {
  final Color strokeColor;
  final Color accentColor;

  _AestheticHeaderArtPainter({
    required this.strokeColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillDark = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // 1. Subtle Accent Circle behind lamp
    canvas.drawCircle(Offset(w * 0.80, h * 0.50), 38, accentPaint);

    // 2. Hanging Lamp with Curly Cord (Matching Screen 3!)
    final cordPath = Path()
      ..moveTo(w * 0.72, 0)
      ..cubicTo(w * 0.72, h * 0.18, w * 0.86, h * 0.12, w * 0.86, h * 0.28)
      ..cubicTo(w * 0.86, h * 0.40, w * 0.78, h * 0.36, w * 0.78, h * 0.48)
      ..lineTo(w * 0.78, h * 0.54);
    canvas.drawPath(cordPath, linePaint);

    // Lampshade Top Ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.75, h * 0.54, w * 0.06, h * 0.04),
        const Radius.circular(2),
      ),
      fillDark,
    );

    // Lampshade Bell
    final lampShade = Path()
      ..moveTo(w * 0.71, h * 0.72)
      ..quadraticBezierTo(w * 0.78, h * 0.56, w * 0.85, h * 0.72)
      ..close();
    canvas.drawPath(lampShade, fillDark);

    // 3. Delicate Botanical Plant Leaves (at bottom right)
    final leafPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    // Stem 1
    final stem1 = Path()
      ..moveTo(w * 0.94, h)
      ..quadraticBezierTo(w * 0.90, h * 0.78, w * 0.92, h * 0.68);
    canvas.drawPath(stem1, leafPaint);

    // Leaf 1
    final leaf1 = Path()
      ..moveTo(w * 0.92, h * 0.68)
      ..quadraticBezierTo(w * 0.88, h * 0.62, w * 0.92, h * 0.54)
      ..quadraticBezierTo(w * 0.96, h * 0.62, w * 0.92, h * 0.68);
    canvas.drawPath(leaf1, leafPaint);

    // Leaf 2
    final leaf2 = Path()
      ..moveTo(w * 0.91, h * 0.78)
      ..quadraticBezierTo(w * 0.84, h * 0.75, w * 0.85, h * 0.67)
      ..quadraticBezierTo(w * 0.90, h * 0.72, w * 0.91, h * 0.78);
    canvas.drawPath(leaf2, leafPaint);

    // Leaf 3 (left side)
    final stem2 = Path()
      ..moveTo(w * 0.89, h)
      ..quadraticBezierTo(w * 0.83, h * 0.84, w * 0.82, h * 0.76);
    canvas.drawPath(stem2, leafPaint);
  }

  @override
  bool shouldRepaint(covariant _AestheticHeaderArtPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor || oldDelegate.accentColor != accentColor;
}
