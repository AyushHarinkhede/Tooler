import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER UNIFIED HOVER POP-UP SHEET
/// ---------------------------------------------------------------------------
/// Features:
/// 1. Top empty space (~72px) with live BackdropFilter frosted-glass blur
///    revealing the animated/live Home Screen underneath. Tapping dismisses.
/// 2. Clean sliding bottom sheet with large top border-radius (32px) matching theme.
/// 3. Unified Single Header Bar:
///    - Left: Circular Back Button (<)
///    - Center: Upper Centered Tool Title
///    - Right: Circular Favorite Button (♥) with live persistence
/// 4. Dedicated Aesthetic Vector Artwork Banner:
///    - Natural multi-leaf botanical flora with realistic veins and curves
///    - Retro hanging bell lamp with vintage curly cord & radiating light cone
///    - Fully self-contained in a 76px card, never overlaps tool controls
/// ---------------------------------------------------------------------------

class ToolerHoverSheet extends StatefulWidget {
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
    VoidCallback? onFavorite,
  }) {
    SoundService().playClick();
    return Navigator.push<T>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ToolerHoverSheet(
            title: title,
            subtitle: subtitle,
            tag: tag,
            theme: theme,
            onFavorite: onFavorite,
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
              begin: const Offset(0, 0.18),
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
  State<ToolerHoverSheet> createState() => _ToolerHoverSheetState();
}

class _ToolerHoverSheetState extends State<ToolerHoverSheet> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final fav = await StorageService().isToolFavorite(widget.title);
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  Future<void> _toggleFavorite() async {
    SoundService().playClick();
    HapticFeedback.lightImpact();
    final newStatus = await StorageService().toggleToolFavorite(widget.title);
    if (mounted) {
      setState(() => _isFavorite = newStatus);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? '${widget.title} added to Favorites ♥' : '${widget.title} removed from Favorites',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          backgroundColor: newStatus ? widget.theme.primary : Colors.grey.shade800,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (widget.onFavorite != null) {
        widget.onFavorite!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Full-screen Live Blur Backdrop (Frosted glass showing home screen)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              ),
            ),
          ),

          // 2. Sliding Hover Sheet with top empty space
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Empty Space (~65-72px): Allows user to see live blurred home screen!
                // Tapping it dismisses the sheet smoothly.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    SoundService().playClick();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 68,
                    width: double.infinity,
                    color: Colors.transparent,
                  ),
                ),

                // Main Themed Sheet Container
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                          blurRadius: 28,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: Column(
                        children: [
                          // 2.1 Drag Handle Pill
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 6),
                              width: 42,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: theme.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),

                          // 2.2 Unified Header Row: [Back Button] on Left, [Centered Title] in Center, [Favorite Button] on Right
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                // Left Back Button (<)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
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
                                            blurRadius: 6,
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
                                ),

                                // Center: Upper Tool Title
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        color: theme.text,
                                      ),
                                    ),
                                  ),
                                ),

                                // Right: Favorite Button (♥)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _toggleFavorite,
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: theme.cardBg,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isFavorite
                                              ? theme.primary.withValues(alpha: 0.5)
                                              : theme.border,
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _isFavorite
                                                ? theme.primary.withValues(alpha: 0.15)
                                                : Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_outline_rounded,
                                        size: 20,
                                        color: _isFavorite
                                            ? const Color(0xFFFF4757)
                                            : theme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2.3 Dedicated Botanical & Hanging Lamp Vector Artwork Banner (inside hover sheet)
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                            height: 76,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.lavenderBubble,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.border.withValues(alpha: 0.7),
                                width: 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CustomPaint(
                                painter: _EnhancedAestheticBannerPainter(
                                  strokeColor: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
                                  accentColor: theme.primary,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),

                          Divider(color: theme.border.withValues(alpha: 0.8), height: 1),

                          // 2.4 Tool's interactive content (Converter, Calculator, etc.)
                          Expanded(
                            child: widget.child,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ENHANCED BOTANICAL FOLIAGE & HANGING BELL LAMP PAINTER
/// ---------------------------------------------------------------------------
/// Beautiful vector illustration depicting:
/// - Hanging bell lamp with vintage braided/curly cord & glowing light beam
/// - Natural eucalyptus branch with paired organic leaves & realistic veins
/// - Broad monstera-style leaf with realistic curved notches & vein ribs
/// - Floating ambient 4-point sparkle stars (✦)
/// - Perfectly theme-reactive (dark ink #18181B in light, crisp white #F4F4F5 in dark,
///   glow & accents in theme.primary)
/// ---------------------------------------------------------------------------
class _EnhancedAestheticBannerPainter extends CustomPainter {
  final Color strokeColor;
  final Color accentColor;
  final bool isDark;

  _EnhancedAestheticBannerPainter({
    required this.strokeColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinStrokePaint = Paint()
      ..color = strokeColor.withValues(alpha: isDark ? 0.7 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final accentFillPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.35 : 0.22)
      ..style = PaintingStyle.fill;

    final softLeafFill = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.20 : 0.14)
      ..style = PaintingStyle.fill;

    // -------------------------------------------------------------------------
    // 1. HANGING BELL LAMP & RADIATING LIGHT CONE (Left-Center)
    // -------------------------------------------------------------------------
    final double lampX = size.width * 0.32;
    const double lampY = 28.0;

    // Glowing Light Cone radiating downwards from lamp
    final lightConePath = Path()
      ..moveTo(lampX - 14, lampY + 12)
      ..lineTo(lampX - 44, size.height + 10)
      ..lineTo(lampX + 44, size.height + 10)
      ..lineTo(lampX + 14, lampY + 12)
      ..close();

    final lightGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: isDark ? 0.32 : 0.24),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(lampX - 50, lampY + 10, 100, size.height - lampY));

    canvas.drawPath(lightConePath, lightGlowPaint);

    // Decorative Hanging Cord with Vintage Curly Loop
    final cordPath = Path()
      ..moveTo(lampX, 0)
      ..lineTo(lampX, 6)
      ..cubicTo(lampX + 8, 8, lampX + 10, 14, lampX + 2, 17)
      ..cubicTo(lampX - 8, 20, lampX - 6, 25, lampX, 28);
    canvas.drawPath(cordPath, thinStrokePaint);

    // Lamp Top Socket Cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lampX, lampY - 2), width: 8, height: 4),
        const Radius.circular(2),
      ),
      strokePaint,
    );

    // Bell Lamp Shade
    final lampPath = Path()
      ..moveTo(lampX - 16, lampY + 10)
      ..cubicTo(lampX - 14, lampY + 1, lampX - 6, lampY, lampX, lampY)
      ..cubicTo(lampX + 6, lampY, lampX + 14, lampY + 1, lampX + 16, lampY + 10)
      ..quadraticBezierTo(lampX, lampY + 13, lampX - 16, lampY + 10);

    // Lamp shade fill
    canvas.drawPath(lampPath, accentFillPaint);
    canvas.drawPath(lampPath, strokePaint);

    // Lamp Rim Detail Line
    final rimPath = Path()
      ..moveTo(lampX - 17, lampY + 10)
      ..quadraticBezierTo(lampX, lampY + 14, lampX + 17, lampY + 10);
    canvas.drawPath(rimPath, strokePaint);

    // Glowing Bulb inside
    final bulbPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lampX, lampY + 8), 3.2, bulbPaint);

    // -------------------------------------------------------------------------
    // 2. NATURAL BOTANICAL FOLIAGE (Right Side)
    // -------------------------------------------------------------------------
    // Eucalyptus branch arching gracefully from bottom right
    final stemPath = Path()
      ..moveTo(size.width * 0.94, size.height + 6)
      ..cubicTo(
        size.width * 0.86, size.height * 0.55,
        size.width * 0.78, size.height * 0.40,
        size.width * 0.62, size.height * 0.28,
      );
    canvas.drawPath(stemPath, strokePaint);

    // Leaf 1: Broad Monstera/Philodendron style leaf on lower right
    _drawMonsteraLeaf(
      canvas: canvas,
      center: Offset(size.width * 0.88, size.height * 0.52),
      angle: -0.35,
      width: 24,
      height: 38,
      fillPaint: softLeafFill,
      strokePaint: strokePaint,
      ribPaint: thinStrokePaint,
    );

    // Leaf 2: Elegant Eucalyptus Leaf (upper mid branch)
    _drawVeinedLeaf(
      canvas: canvas,
      start: Offset(size.width * 0.74, size.height * 0.42),
      tip: Offset(size.width * 0.70, size.height * 0.14),
      curveWidth: 10,
      fillPaint: accentFillPaint,
      strokePaint: strokePaint,
      veinPaint: thinStrokePaint,
    );

    // Leaf 3: Small accent Leaf (top right)
    _drawVeinedLeaf(
      canvas: canvas,
      start: Offset(size.width * 0.81, size.height * 0.35),
      tip: Offset(size.width * 0.90, size.height * 0.18),
      curveWidth: 8,
      fillPaint: softLeafFill,
      strokePaint: strokePaint,
      veinPaint: thinStrokePaint,
    );

    // Leaf 4: Sprouting tip leaf (branch terminus)
    _drawVeinedLeaf(
      canvas: canvas,
      start: Offset(size.width * 0.62, size.height * 0.28),
      tip: Offset(size.width * 0.54, size.height * 0.22),
      curveWidth: 7,
      fillPaint: accentFillPaint,
      strokePaint: strokePaint,
      veinPaint: thinStrokePaint,
    );

    // Leaf 5: Lower trailing leaf
    _drawVeinedLeaf(
      canvas: canvas,
      start: Offset(size.width * 0.70, size.height * 0.50),
      tip: Offset(size.width * 0.62, size.height * 0.62),
      curveWidth: 9,
      fillPaint: softLeafFill,
      strokePaint: strokePaint,
      veinPaint: thinStrokePaint,
    );

    // -------------------------------------------------------------------------
    // 3. AMBIENT SPARKLES & 4-POINT STARS (✦)
    // -------------------------------------------------------------------------
    _drawSparkle(canvas, Offset(size.width * 0.16, size.height * 0.36), 6.5, accentColor);
    _drawSparkle(canvas, Offset(size.width * 0.48, size.height * 0.22), 5.0, strokeColor);
    _drawSparkle(canvas, Offset(size.width * 0.80, size.height * 0.68), 4.5, accentColor);

    // Subtle ambient stardust dots
    final dotPaint = Paint()..color = strokeColor.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.65), 1.6, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.44, size.height * 0.54), 1.4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.68), 1.8, dotPaint);
  }

  /// Draws a natural leaf with main central vein and delicate lateral ribs
  void _drawVeinedLeaf({
    required Canvas canvas,
    required Offset start,
    required Offset tip,
    required double curveWidth,
    required Paint fillPaint,
    required Paint strokePaint,
    required Paint veinPaint,
  }) {
    final double midX = (start.dx + tip.dx) / 2;
    final double midY = (start.dy + tip.dy) / 2;
    final double dx = tip.dx - start.dx;
    final double dy = tip.dy - start.dy;
    final double len = (dx * dx + dy * dy);
    if (len == 0) return;

    // Normal vector perpendicular to leaf axis
    final double nx = -dy / 4;
    final double ny = dx / 4;

    final leafPath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(midX + nx * (curveWidth / 4), midY + ny * (curveWidth / 4), tip.dx, tip.dy)
      ..quadraticBezierTo(midX - nx * (curveWidth / 4), midY - ny * (curveWidth / 4), start.dx, start.dy)
      ..close();

    canvas.drawPath(leafPath, fillPaint);
    canvas.drawPath(leafPath, strokePaint);

    // Center vein
    final centerVein = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(midX, midY, tip.dx, tip.dy);
    canvas.drawPath(centerVein, veinPaint);

    // Lateral ribs
    canvas.drawLine(
      Offset(start.dx + dx * 0.4, start.dy + dy * 0.4),
      Offset(start.dx + dx * 0.4 + nx * 0.6, start.dy + dy * 0.4 + ny * 0.6),
      veinPaint,
    );
    canvas.drawLine(
      Offset(start.dx + dx * 0.4, start.dy + dy * 0.4),
      Offset(start.dx + dx * 0.4 - nx * 0.6, start.dy + dy * 0.4 - ny * 0.6),
      veinPaint,
    );
    canvas.drawLine(
      Offset(start.dx + dx * 0.65, start.dy + dy * 0.65),
      Offset(start.dx + dx * 0.65 + nx * 0.5, start.dy + dy * 0.65 + ny * 0.5),
      veinPaint,
    );
    canvas.drawLine(
      Offset(start.dx + dx * 0.65, start.dy + dy * 0.65),
      Offset(start.dx + dx * 0.65 - nx * 0.5, start.dy + dy * 0.65 - ny * 0.5),
      veinPaint,
    );
  }

  /// Draws a broad monstera-style leaf with realistic leaf contours
  void _drawMonsteraLeaf({
    required Canvas canvas,
    required Offset center,
    required double angle,
    required double width,
    required double height,
    required Paint fillPaint,
    required Paint strokePaint,
    required Paint ribPaint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, height / 2)
      ..cubicTo(width * 0.8, height * 0.3, width, -height * 0.1, 0, -height / 2)
      ..cubicTo(-width, -height * 0.1, -width * 0.8, height * 0.3, 0, height / 2)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Center stem
    canvas.drawLine(Offset(0, height / 2), Offset(0, -height / 2 + 3), strokePaint);

    // Lateral veins
    canvas.drawLine(Offset(0, height * 0.15), Offset(width * 0.55, height * 0.05), ribPaint);
    canvas.drawLine(Offset(0, height * 0.15), Offset(-width * 0.55, height * 0.05), ribPaint);
    canvas.drawLine(Offset(0, -height * 0.1), Offset(width * 0.5, -height * 0.22), ribPaint);
    canvas.drawLine(Offset(0, -height * 0.1), Offset(-width * 0.5, -height * 0.22), ribPaint);

    canvas.restore();
  }

  /// Draws an aesthetic 4-pointed star (✦)
  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EnhancedAestheticBannerPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
