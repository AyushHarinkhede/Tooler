import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// PAPER CRUMPLE & UNCRUMPLE (SCRAP PAPER BALL) ROUTE TRANSITION
/// Simulates tightly compressed crumpled scrap paper blossoming open into a
/// full-screen aesthetic notebook sheet, and scrunching back into a paper ball
/// when closed.
/// ---------------------------------------------------------------------------

class PaperUnfoldRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final String title;
  final Color noteColor;
  final Color borderColor;
  final Color textColor;

  PaperUnfoldRoute({
    required this.child,
    required this.title,
    this.noteColor = const Color(0xFFFEF9C3), // Soft butter pastel
    this.borderColor = const Color(0xFFCA8A04),
    this.textColor = const Color(0xFF451A03),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 440),
          transitionsBuilder: (context, animation, secondaryAnimation, page) {
            final curvedAnim = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack, // Realistic paper rebound expansion
              reverseCurve: Curves.easeInOutCubic, // Snappy compression back into ball
            );

            return _PaperCrumpleTransition(
              animation: curvedAnim,
              title: title,
              noteColor: noteColor,
              borderColor: borderColor,
              textColor: textColor,
              child: page,
            );
          },
        );
}

class _PaperCrumpleTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final String title;
  final Color noteColor;
  final Color borderColor;
  final Color textColor;

  const _PaperCrumpleTransition({
    required this.animation,
    required this.child,
    required this.title,
    required this.noteColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;

        // 1. Scale: starts from tiny compressed ball (0.12) to full size (1.0)
        final double scale = (t < 0.05) ? 0.12 : (0.12 + 0.88 * t);

        // 2. Paper Unwinding Rotation (twists as it uncurls)
        final double rotation = (1.0 - t) * 0.35 * math.sin((1.0 - t) * math.pi);

        // 3. Crease wrinkle overlay intensity: high when compressed (0.8), fades to 0 as it unfolds flat
        final double wrinkleOpacity = (1.0 - t).clamp(0.0, 1.0);

        // 4. Transform Matrix
        final Matrix4 matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..scale(scale, scale, 1.0)
          ..rotateZ(rotation)
          ..rotateX((1.0 - t) * 0.15)
          ..rotateY((1.0 - t) * -0.15);

        return Material(
          color: Colors.black.withValues(alpha: 0.45 * t), // Faint desk focus backdrop
          child: Center(
            child: Transform(
              transform: matrix,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  // The Unfolded Large Sticky Sheet Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                      color: noteColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 2.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        children: [
                          // Top Hand-Crafted Note Header Strip
                          _buildUnfoldedSheetHeader(context),

                          // The Screen Body Content
                          Expanded(
                            child: Container(
                              color: Colors.transparent,
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Creased Crumpled Paper Wrinkles Overlay (Fades out as it flattens!)
                  if (wrinkleOpacity > 0.05)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: wrinkleOpacity,
                          child: CustomPaint(
                            painter: _PaperWrinklesPainter(strokeColor: borderColor),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Header of the opened large sheet
  Widget _buildUnfoldedSheetHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: noteColor,
        border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pinned Washi Tape Aesthetic
          Row(
            children: [
              Container(
                width: 32,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0x99FFE853),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: const Color(0x44CA8A04), width: 1),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.patrickHand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // Fold & Compress Back Button
          InkWell(
            onTap: () {
              SoundService().playClick();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.close_rounded, size: 16, color: textColor),
                  const SizedBox(width: 4),
                  Text(
                    "Fold back",
                    style: GoogleFonts.kalam(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints geometric crease lines representing crumpled paper folds
class _PaperWrinklesPainter extends CustomPainter {
  final Color strokeColor;
  _PaperWrinklesPainter({required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = strokeColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Crinkle crease lines across the paper ball
    final crease1 = Path()
      ..moveTo(w * 0.15, h * 0.20)
      ..lineTo(w * 0.45, h * 0.35)
      ..lineTo(w * 0.38, h * 0.58)
      ..lineTo(w * 0.65, h * 0.50)
      ..lineTo(w * 0.85, h * 0.75);
    canvas.drawPath(crease1, p);

    final crease2 = Path()
      ..moveTo(w * 0.78, h * 0.15)
      ..lineTo(w * 0.55, h * 0.38)
      ..lineTo(w * 0.28, h * 0.45)
      ..lineTo(w * 0.42, h * 0.82);
    canvas.drawPath(crease2, p);

    final crease3 = Path()
      ..moveTo(w * 0.10, h * 0.70)
      ..lineTo(w * 0.35, h * 0.62)
      ..lineTo(w * 0.50, h * 0.78)
      ..lineTo(w * 0.88, h * 0.40);
    canvas.drawPath(crease3, p);
  }

  @override
  bool shouldRepaint(covariant _PaperWrinklesPainter oldDelegate) => false;
}
