import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// LIVE ANIMATED TOOLER WORDMARK LOGO
/// - The word "Tooler" IS the logo (no isolated 'T' icon)
/// - The "oo" letters are two expressive, animated eyes with pupils & specular shine
/// - Letters T, l, e, r relate to the character personality:
///     T: Smart inquisitive brow / visor
///     oo: Live observant eyes (blinks every ~3.5s, glances around)
///     l: Sleek periscope column
///     e: Cheerful smiling mouth curve
///     r: Friendly waving tool hook / arm
/// - Tap to wink interaction with tactile click sound & haptics!
/// ---------------------------------------------------------------------------

class ToolerLogo extends StatefulWidget {
  final double height;
  final Color? color;
  final Color? accentColor;
  final bool interactive;

  // Backward compatibility parameters
  final double? size;
  final bool showText;

  const ToolerLogo({
    super.key,
    this.height = 34,
    this.color,
    this.accentColor,
    this.interactive = true,
    this.size,
    this.showText = false,
  });

  @override
  State<ToolerLogo> createState() => _ToolerLogoState();
}

class _ToolerLogoState extends State<ToolerLogo> with TickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final AnimationController _lookController;
  late final AnimationController _winkController;

  late final Animation<double> _blinkAnimation;
  late final Animation<double> _winkAnimation;
  late final Animation<double> _lookAnimation;

  Timer? _idleTimer;
  final math.Random _random = math.Random();
  bool _isWinking = false;

  @override
  void initState() {
    super.initState();

    // 1. Blink Controller (Natural eye blink)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.08).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOutQuad,
      ),
    );

    // 2. Wink Controller (Tap interaction)
    _winkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _winkAnimation = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(
        parent: _winkController,
        curve: Curves.easeInOutQuad,
      ),
    );

    // 3. Look-around Controller (Pupils gently scan)
    _lookController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _lookAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _lookController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _startIdleLife();
  }

  void _startIdleLife() {
    _idleTimer?.cancel();
    // Spontaneous natural eye actions every 3 - 5 seconds
    final delay = Duration(milliseconds: 2800 + _random.nextInt(2200));
    _idleTimer = Timer(delay, () {
      if (!mounted) return;

      // 70% chance to blink, 30% chance to look around
      if (_random.nextBool()) {
        _performBlink();
      } else {
        _performGlance();
      }
      _startIdleLife();
    });
  }

  void _performBlink() async {
    if (!mounted || _blinkController.isAnimating || _winkController.isAnimating) return;
    await _blinkController.forward();
    if (!mounted) return;
    await _blinkController.reverse();
  }

  void _performGlance() {
    if (!mounted || _lookController.isAnimating) return;
    final target = (_random.nextDouble() * 2.0 - 1.0); // -1.0 to +1.0
    _lookAnimation = Tween<double>(
      begin: _lookAnimation.value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _lookController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _lookController.forward(from: 0.0);
  }

  void _onTapLogo() async {
    if (!widget.interactive || _winkController.isAnimating) return;
    SoundService().playClick();

    setState(() => _isWinking = true);
    await _winkController.forward();
    if (!mounted) return;
    await _winkController.reverse();
    if (mounted) {
      setState(() => _isWinking = false);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _blinkController.dispose();
    _winkController.dispose();
    _lookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.size != null && widget.size! > 40
        ? widget.size! * 0.75
        : widget.height;
    final effectiveWidth = effectiveHeight * 3.65; // Proportional aspect ratio

    final letterColor = widget.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFF4F4F5)
            : const Color(0xFF18181B));
    final pupilColor = widget.accentColor ?? const Color(0xFFA855F7);

    return GestureDetector(
      onTap: _onTapLogo,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_blinkAnimation, _winkAnimation, _lookAnimation]),
        builder: (context, child) {
          return SizedBox(
            width: effectiveWidth,
            height: effectiveHeight,
            child: CustomPaint(
              painter: _ToolerWordmarkPainter(
                textColor: letterColor,
                pupilColor: pupilColor,
                blinkProgress: _blinkAnimation.value,
                winkProgress: _isWinking ? _winkAnimation.value : 1.0,
                lookOffset: _lookAnimation.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// TOOLER TYPOGRAPHIC CHARACTER VECTOR PAINTER
/// Coordinates mapped to a virtual 160 × 44 design canvas
/// ---------------------------------------------------------------------------
class _ToolerWordmarkPainter extends CustomPainter {
  final Color textColor;
  final Color pupilColor;
  final double blinkProgress; // 1.0 = open, 0.0 = closed
  final double winkProgress; // right eye wink
  final double lookOffset; // -1.0 (left) to +1.0 (right)

  _ToolerWordmarkPainter({
    required this.textColor,
    required this.pupilColor,
    required this.blinkProgress,
    required this.winkProgress,
    required this.lookOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale virtual canvas 160 x 44 to actual widget size
    final scale = size.height / 44.0;
    canvas.save();
    canvas.scale(scale, scale);

    final textPaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pupilPaint = Paint()
      ..color = pupilColor
      ..style = PaintingStyle.fill;

    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // -----------------------------------------------------------------------
    // 1. LETTER 'T': Inquisitive Brow & Solid Upright Stem
    // -----------------------------------------------------------------------
    // Top Brow Crossbar with slightly curved protective wing
    final tCrossbar = Path()
      ..moveTo(4, 9.5)
      ..lineTo(26, 9.5)
      ..arcToPoint(
        const Offset(26, 16),
        radius: const Radius.circular(3.2),
      )
      ..lineTo(4, 16)
      ..arcToPoint(
        const Offset(4, 9.5),
        radius: const Radius.circular(3.2),
      )
      ..close();
    canvas.drawPath(tCrossbar, textPaint);

    // Vertical Stem
    final tStem = RRect.fromRectAndRadius(
      const Rect.fromLTWH(11.5, 14, 7.0, 23),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(tStem, textPaint);

    // -----------------------------------------------------------------------
    // 2. FIRST 'o' (LEFT EYE): Live observant circle with tracking pupil
    // -----------------------------------------------------------------------
    const leftEyeCenter = Offset(45.0, 25.5);
    const eyeRadius = 12.0;

    canvas.save();
    // Vertical scaling for blink (pivot at eye center)
    canvas.translate(leftEyeCenter.dx, leftEyeCenter.dy);
    canvas.scale(1.0, blinkProgress);
    canvas.translate(-leftEyeCenter.dx, -leftEyeCenter.dy);

    // Eye outer ring
    canvas.drawCircle(leftEyeCenter, eyeRadius - 2.6, strokePaint);

    // Pupil inside eye (only visible when eye is sufficiently open)
    if (blinkProgress > 0.25) {
      final pupilDx = lookOffset * 2.8;
      final pupilPos = Offset(leftEyeCenter.dx + pupilDx, leftEyeCenter.dy);
      // Pupil dot in accent color
      canvas.drawCircle(pupilPos, 4.2, pupilPaint);
      // Specular shine highlight
      canvas.drawCircle(
        Offset(pupilPos.dx + 1.3, pupilPos.dy - 1.3),
        1.3,
        shinePaint,
      );
    }
    canvas.restore();

    // -----------------------------------------------------------------------
    // 3. SECOND 'o' (RIGHT EYE): Live eye (with tap-to-wink capability!)
    // -----------------------------------------------------------------------
    const rightEyeCenter = Offset(72.0, 25.5);
    final effectiveRightBlink = math.min(blinkProgress, winkProgress);

    canvas.save();
    canvas.translate(rightEyeCenter.dx, rightEyeCenter.dy);
    canvas.scale(1.0, effectiveRightBlink);
    canvas.translate(-rightEyeCenter.dx, -rightEyeCenter.dy);

    // Eye outer ring
    canvas.drawCircle(rightEyeCenter, eyeRadius - 2.6, strokePaint);

    if (effectiveRightBlink > 0.25) {
      final pupilDx = lookOffset * 2.8;
      final pupilPos = Offset(rightEyeCenter.dx + pupilDx, rightEyeCenter.dy);
      canvas.drawCircle(pupilPos, 4.2, pupilPaint);
      canvas.drawCircle(
        Offset(pupilPos.dx + 1.3, pupilPos.dy - 1.3),
        1.3,
        shinePaint,
      );
    }
    canvas.restore();

    // -----------------------------------------------------------------------
    // 4. LETTER 'l': Tall sleek periscope / column
    // -----------------------------------------------------------------------
    final lStem = RRect.fromRectAndRadius(
      const Rect.fromLTWH(91.5, 7.0, 6.8, 30.0),
      const Radius.circular(3.4),
    );
    canvas.drawRRect(lStem, textPaint);

    // -----------------------------------------------------------------------
    // 5. LETTER 'e': Cheerful smiling mouth curve
    // -----------------------------------------------------------------------
    // Outer 'e' curve
    final ePath = Path()
      // Horizontal crossbar (mouth smile line)
      ..moveTo(105.5, 25.5)
      ..lineTo(123.5, 25.5)
      // Top eye of 'e'
      ..arcToPoint(
        const Offset(114.5, 15.0),
        radius: const Radius.circular(9.0),
      )
      ..arcToPoint(
        const Offset(105.5, 25.5),
        radius: const Radius.circular(9.0),
      )
      // Bottom happy curve sweeping up
      ..arcToPoint(
        const Offset(114.5, 36.5),
        radius: const Radius.circular(10.0),
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(123.8, 31.0),
        radius: const Radius.circular(10.0),
        clockwise: false,
      );

    final eStrokePaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(ePath, eStrokePaint);

    // -----------------------------------------------------------------------
    // 6. LETTER 'r': Friendly waving arm / tool hook
    // -----------------------------------------------------------------------
    // Main vertical stem
    final rStem = RRect.fromRectAndRadius(
      const Rect.fromLTWH(133.0, 15.5, 6.5, 21.5),
      const Radius.circular(3.2),
    );
    canvas.drawRRect(rStem, textPaint);

    // Waving hook arm arching upwards
    final rArm = Path()
      ..moveTo(136.0, 22.0)
      ..quadraticBezierTo(140.0, 15.5, 149.0, 15.5);

    final rArmPaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(rArm, rArmPaint);

    // Friendly little accent tip dot in primary color on waving tip
    canvas.drawCircle(
      const Offset(149.0, 15.5),
      2.6,
      pupilPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ToolerWordmarkPainter oldDelegate) =>
      oldDelegate.textColor != textColor ||
      oldDelegate.pupilColor != pupilColor ||
      oldDelegate.blinkProgress != blinkProgress ||
      oldDelegate.winkProgress != winkProgress ||
      oldDelegate.lookOffset != lookOffset;
}
