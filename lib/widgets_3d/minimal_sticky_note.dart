import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// MINIMAL FLAT PASTEL STICKY NOTE CARD
/// Authentic flat stationery post-it note:
/// - Pure flat aesthetic (ZERO drop shadows)
/// - Pastel hues (Butter Yellow, Sage Mint, Powder Blue, Soft Peach, Lavender)
/// - Hand-drawn ink icons drawn right onto the note
/// - Washi masking tape strip at top
/// - Crisp typography aligned with notebook line pitch
/// ---------------------------------------------------------------------------

class MinimalStickyNote extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final Color noteColor;
  final Color borderColor;
  final Color textColor;
  final double rotationAngle;
  final VoidCallback onTap;

  const MinimalStickyNote({
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
  State<MinimalStickyNote> createState() => _MinimalStickyNoteState();
}

class _MinimalStickyNoteState extends State<MinimalStickyNote> {
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
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Flat Pastel Sticky Note Paper Body (Zero Shadows)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                decoration: BoxDecoration(
                  color: widget.noteColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.borderColor,
                    width: 1.8,
                  ),
                  // NO DROP SHADOWS as requested by user
                ),
                child: CustomPaint(
                  painter: _FaintNoteRulesPainter(
                    lineColor: widget.borderColor.withValues(alpha: 0.15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Sketched Ink Icon & Corner Arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Drawn Icon Area
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: widget.borderColor.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            child: Center(child: widget.iconWidget),
                          ),

                          // Minimal corner mark
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 15,
                            color: widget.textColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Text: Title & Subtitle written cleanly
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.patrickHand(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: widget.textColor,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: GoogleFonts.kalam(
                              fontSize: 10.5,
                              color: widget.textColor.withValues(alpha: 0.72),
                              height: 1.15,
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

              // 2. Translucent Washi Masking Tape on Top Center
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xBBFFF275), // Faint translucent yellow tape
                      borderRadius: BorderRadius.circular(1.5),
                      border: Border.all(
                        color: const Color(0x55D4A017),
                        width: 0.8,
                      ),
                    ),
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

/// Paints faint horizontal ruled notebook guides across the sticky note
class _FaintNoteRulesPainter extends CustomPainter {
  final Color lineColor;
  const _FaintNoteRulesPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    double y = 44;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += 18;
    }
  }

  @override
  bool shouldRepaint(covariant _FaintNoteRulesPainter oldDelegate) => false;
}
