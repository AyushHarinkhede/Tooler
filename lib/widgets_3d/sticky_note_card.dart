import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

class StickyNoteCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String icon;
  final Color noteColor;
  final Color borderColor;
  final Color textColor;
  final double rotationAngle;
  final VoidCallback onTap;

  const StickyNoteCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
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
    return Transform.rotate(
      angle: widget.rotationAngle,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          SoundService().playClick();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. The Sticky Note Paper Body
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                decoration: BoxDecoration(
                  color: widget.noteColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(18), // Curled bottom-right corner
                  ),
                  border: Border.all(
                    color: widget.borderColor,
                    width: 2.0,
                  ),
                  boxShadow: [
                    // Lifted paper shadow (bottom-right curl)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      offset: const Offset(4, 6),
                      blurRadius: 5,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: widget.borderColor.withValues(alpha: 0.25),
                      offset: const Offset(2, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _StickyNoteLinedPainter(
                    lineColor: widget.borderColor.withValues(alpha: 0.15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Icon + Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.borderColor.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              widget.icon,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.borderColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: widget.textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Title & Subtitle
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

              // 2. Translucent Washi Tape Strip at Top Center
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 48,
                    height: 15,
                    decoration: BoxDecoration(
                      color: const Color(0xBBFFF275), // Translucent yellow masking tape
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: const Color(0x66D4A017),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Subtle Dog-Ear / Corner Curl Accent on Bottom-Right
              Positioned(
                bottom: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(16, 16),
                  painter: _CornerCurlPainter(
                    foldColor: widget.borderColor.withValues(alpha: 0.35),
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

// Paints faint ruled lines across the sticky note
class _StickyNoteLinedPainter extends CustomPainter {
  final Color lineColor;
  const _StickyNoteLinedPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    double y = 42;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += 18;
    }
  }

  @override
  bool shouldRepaint(covariant _StickyNoteLinedPainter oldDelegate) => false;
}

// Paints a tiny 3D corner fold on the bottom-right of the note
class _CornerCurlPainter extends CustomPainter {
  final Color foldColor;
  const _CornerCurlPainter({required this.foldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, size.height - 14)
      ..lineTo(size.width - 14, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()
      ..color = foldColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerCurlPainter oldDelegate) => false;
}
