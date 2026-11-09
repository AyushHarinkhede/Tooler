import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// 3D INTERACTIVE POST-IT STICKY NOTE CARD
/// Features realistic paper physics:
/// - 3D Perspective Tilt on touch & lift
/// - Dynamic drop shadow elevation off desk
/// - Authentic curled dog-ear corner fold
/// - Semi-transparent washi masking tape strip
/// - Crisp vector 3D stationery iconography (Zero emojis)
/// ---------------------------------------------------------------------------
class StickyNoteCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final Color noteColor;
  final Color borderColor;
  final Color textColor;
  final double rotationAngle;
  final VoidCallback onTap;

  const StickyNoteCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    required this.noteColor,
    required this.borderColor,
    required this.textColor,
    required this.rotationAngle,
    required this.onTap,
  });

  @override
  State<StickyNoteCard> createState() => _StickyNoteCardState();
}

class _StickyNoteCardState extends State<StickyNoteCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // 3D perspective tilt matrix when lifted/pressed
    final Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0018) // Perspective focal depth
      ..rotateZ(widget.rotationAngle)
      ..rotateX(_isPressed ? -0.06 : 0.0)
      ..rotateY(_isPressed ? 0.04 : 0.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      transform: transform,
      transformAlignment: Alignment.center,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          SoundService().playClick();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. The Sticky Note Paper Body
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                decoration: BoxDecoration(
                  color: widget.noteColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(18), // Curled corner
                  ),
                  border: Border.all(
                    color: widget.borderColor,
                    width: 2.0,
                  ),
                  boxShadow: [
                    // Dynamic elevated desk shadow (grows deeper when pressed/lifted)
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isPressed ? 0.22 : 0.12,
                      ),
                      offset: _isPressed ? const Offset(6, 12) : const Offset(3, 5),
                      blurRadius: _isPressed ? 12 : 5,
                      spreadRadius: _isPressed ? 1 : 0,
                    ),
                    BoxShadow(
                      color: widget.borderColor.withValues(alpha: 0.3),
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _StickyNoteLinedPainter(
                    lineColor: widget.borderColor.withValues(alpha: 0.16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: 3D Vector Icon Badge + Action Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.borderColor.withValues(alpha: 0.7),
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(child: widget.iconWidget),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.borderColor.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: widget.textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title & Subtitle with authentic handwriting fonts
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.patrickHand(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.textColor,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            style: GoogleFonts.kalam(
                              fontSize: 11,
                              color: widget.textColor.withValues(alpha: 0.75),
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Translucent Washi Masking Tape Strip at Top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 50,
                    height: 15,
                    decoration: BoxDecoration(
                      color: const Color(0xCCFFF382), // Translucent masking tape yellow
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: const Color(0x55CA8A04),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(0, 1.5),
                          blurRadius: 1.5,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _WashiTexturePainter(),
                    ),
                  ),
                ),
              ),

              // 3. Subtle 3D Dog-Ear Corner Fold on Bottom-Right
              Positioned(
                bottom: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(18, 18),
                  painter: _CornerCurlPainter(
                    foldColor: widget.borderColor.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints faint notebook lines across the sticky note
class _StickyNoteLinedPainter extends CustomPainter {
  final Color lineColor;
  const _StickyNoteLinedPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    double y = 46;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += 18;
    }
  }

  @override
  bool shouldRepaint(covariant _StickyNoteLinedPainter oldDelegate) => false;
}

/// Paints faint fibrous washi tape texture
class _WashiTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fiberPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.25, size.height), fiberPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.55, size.height), fiberPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.8, size.height), fiberPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints a realistic 3D paper curl fold on the bottom-right corner
class _CornerCurlPainter extends CustomPainter {
  final Color foldColor;
  const _CornerCurlPainter({required this.foldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, size.height - 16)
      ..lineTo(size.width - 16, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [foldColor, foldColor.withValues(alpha: 0.6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerCurlPainter oldDelegate) => false;
}
