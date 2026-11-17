import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// LIVE ANIMATED TOOLER WORDMARK LOGO (EXPRESSIVE EDITION)
/// - Keeps the exact iconic "Tooler" wordmark silhouette
/// - Upgraded cartoon-expressive eyes ("oo") with soft sclera, colored iris,
///   dark pupil core, dual specular catchlights, 2D gaze, cross-eye & happy "^"
/// - Every letter is its own articulated animated character element:
///     T  : Expressive cap/visor that tips & hops
///     oo : Independent live eyes (blink, wink, 2D glance, cross-eye, happy ^)
///     l  : Springy squash-and-stretch pillar
///     e  : Joyful chuckling smiling glyph
///     r  : Playful waving shoulder arm & bouncy accent dot
/// - Silky-smooth spontaneous funny idle antics + 3 cycling funny tap reactions!
/// ---------------------------------------------------------------------------

enum _LogoAntic {
  none,
  doubleBlink,
  crossEyed,
  waveAndTip,
  sneakySideEye,
  dominoJump,
  cheekyWink,
}

class ToolerLogo extends StatefulWidget {
  final double height;
  final Color? color;
  final Color? accentColor;
  final bool interactive;
  final VoidCallback? onTap;

  // Backward compatibility parameters
  final double? size;
  final bool showText;

  const ToolerLogo({
    super.key,
    this.height = 34,
    this.color,
    this.accentColor,
    this.interactive = true,
    this.onTap,
    this.size,
    this.showText = false,
  });

  @override
  State<ToolerLogo> createState() => _ToolerLogoState();
}

class _ToolerLogoState extends State<ToolerLogo> with TickerProviderStateMixin {
  late final AnimationController _anticController;
  late final AnimationController _gazeController;
  late final AnimationController _breatheController;

  _LogoAntic _activeAntic = _LogoAntic.none;

  // Smooth 2D gaze interpolation
  double _fromGazeX = 0.0;
  double _fromGazeY = 0.0;
  double _toGazeX = 0.0;
  double _toGazeY = 0.0;

  Timer? _idleTimer;
  final math.Random _random = math.Random();
  int _tapCycleIndex = 0;

  @override
  void initState() {
    super.initState();

    _anticController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _activeAntic = _LogoAntic.none);
        }
      });

    _gazeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // Subtle continuous living micro-motion (very gentle organic life)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _scheduleNextIdleAntic();
  }

  void _scheduleNextIdleAntic() {
    _idleTimer?.cancel();
    final delay = Duration(milliseconds: 2700 + _random.nextInt(2300));
    _idleTimer = Timer(delay, () {
      if (!mounted) return;
      if (!_anticController.isAnimating) {
        final roll = _random.nextInt(100);
        if (roll < 30) {
          _playAntic(_LogoAntic.doubleBlink, const Duration(milliseconds: 620));
        } else if (roll < 52) {
          _performSmooth2DGlance();
        } else if (roll < 68) {
          _playAntic(_LogoAntic.crossEyed, const Duration(milliseconds: 1450));
        } else if (roll < 82) {
          _playAntic(_LogoAntic.waveAndTip, const Duration(milliseconds: 1200));
        } else if (roll < 92) {
          _playAntic(_LogoAntic.sneakySideEye, const Duration(milliseconds: 1350));
        } else {
          _playAntic(_LogoAntic.dominoJump, const Duration(milliseconds: 1050));
        }
      }
      _scheduleNextIdleAntic();
    });
  }

  void _playAntic(_LogoAntic antic, Duration duration) {
    if (!mounted) return;
    setState(() => _activeAntic = antic);
    _anticController.duration = duration;
    _anticController.forward(from: 0.0);
  }

  void _performSmooth2DGlance() {
    if (!mounted || _gazeController.isAnimating) return;
    final t = Curves.easeInOutCubic.transform(_gazeController.value);
    _fromGazeX = _fromGazeX + (_toGazeX - _fromGazeX) * t;
    _fromGazeY = _fromGazeY + (_toGazeY - _fromGazeY) * t;

    // Pick expressive cute 2D gaze targets (or return to center)
    const targets = [
      Offset(-0.85, -0.35),
      Offset(0.95, -0.25),
      Offset(0.0, -0.75),
      Offset(0.85, 0.35),
      Offset(-0.75, 0.30),
      Offset(0.0, 0.0),
    ];
    final next = targets[_random.nextInt(targets.length)];
    _toGazeX = next.dx;
    _toGazeY = next.dy;
    _gazeController.forward(from: 0.0);
  }

  void _handleTap() {
    if (widget.interactive) {
      SoundService().playClick();
      HapticFeedback.lightImpact();

      // Cycle through 3 smooth, hilarious tap reactions!
      final step = _tapCycleIndex % 3;
      _tapCycleIndex++;

      if (step == 0) {
        _playAntic(_LogoAntic.cheekyWink, const Duration(milliseconds: 1050));
      } else if (step == 1) {
        _playAntic(_LogoAntic.crossEyed, const Duration(milliseconds: 1450));
      } else {
        _playAntic(_LogoAntic.dominoJump, const Duration(milliseconds: 1050));
      }
    }
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _anticController.dispose();
    _gazeController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.size != null && widget.size! > 40
        ? widget.size! * 0.75
        : widget.height;
    final effectiveWidth = effectiveHeight * 3.65;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final letterColor = widget.color ??
        (isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B));
    final pupilColor = widget.accentColor ?? const Color(0xFFA855F7);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _anticController,
          _gazeController,
          _breatheController,
        ]),
        builder: (context, child) {
          final gazeEase = Curves.easeInOutCubic.transform(_gazeController.value);
          final baseGazeX = _fromGazeX + (_toGazeX - _fromGazeX) * gazeEase;
          final baseGazeY = _fromGazeY + (_toGazeY - _fromGazeY) * gazeEase;

          return SizedBox(
            width: effectiveWidth,
            height: effectiveHeight,
            child: CustomPaint(
              painter: _ToolerWordmarkPainter(
                textColor: letterColor,
                pupilColor: pupilColor,
                isDark: isDark,
                antic: _activeAntic,
                anticT: _anticController.value,
                baseGazeX: baseGazeX,
                baseGazeY: baseGazeY,
                breatheT: _breatheController.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// TOOLER ARTICULATED CHARACTER WORDMARK VECTOR PAINTER
/// Virtual design canvas: 160 × 44 (exact original proportions)
/// Every letter is individually animated with smooth squash/stretch/tilt/wave.
/// ---------------------------------------------------------------------------
class _ToolerWordmarkPainter extends CustomPainter {
  final Color textColor;
  final Color pupilColor;
  final bool isDark;
  final _LogoAntic antic;
  final double anticT;
  final double baseGazeX;
  final double baseGazeY;
  final double breatheT;

  _ToolerWordmarkPainter({
    required this.textColor,
    required this.pupilColor,
    required this.isDark,
    required this.antic,
    required this.anticT,
    required this.baseGazeX,
    required this.baseGazeY,
    required this.breatheT,
  });

  /// Smooth pulse envelope: 0 -> 1 -> 0 over [start, end]
  double _bell(double t, double start, double end) {
    if (t <= start || t >= end) return 0.0;
    final u = (t - start) / (end - start);
    return math.sin(u * math.pi);
  }

  /// Smooth hold envelope: ramps up, holds at 1.0, ramps back down
  double _holdEnvelope(double t, double riseEnd, double fallStart) {
    if (t <= 0.0 || t >= 1.0) return 0.0;
    if (t < riseEnd) {
      return Curves.easeOutCubic.transform(t / riseEnd);
    }
    if (t > fallStart) {
      return 1.0 - Curves.easeInCubic.transform((t - fallStart) / (1.0 - fallStart));
    }
    return 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 44.0;
    canvas.save();
    canvas.scale(scale, scale);

    // -------------------------------------------------------------------------
    // COMPUTE PER-LETTER SMOOTH ANIMATION KINEMATICS
    // -------------------------------------------------------------------------
    final subtleFloat = math.sin(breatheT * math.pi * 2.0);

    // Letter T (Expressive Cap)
    double tDy = 0.0;
    double tAngle = 0.0;

    // Left & Right Eyes (oo)
    double leftBlink = 1.0;
    double rightBlink = 1.0;
    double leftEyeDy = 0.0;
    double rightEyeDy = 0.0;
    double leftLookX = baseGazeX;
    double leftLookY = baseGazeY;
    double rightLookX = baseGazeX;
    double rightLookY = baseGazeY;
    bool leftHappy = false;
    bool rightHappy = false;
    double eyePopScale = 1.0;

    // Letter l (Springy Pillar)
    double lDy = 0.0;
    double lScaleX = 1.0;
    double lScaleY = 1.0;

    // Letter e (Joyful Smiling Mouth)
    double eDy = 0.0;
    double eAngle = 0.0;
    double eScaleY = 1.0;

    // Letter r (Playful Waving Hook Arm + Bouncy Dot)
    double rDy = 0.0;
    double rWaveAngle = subtleFloat * 0.045;
    double rDotLift = subtleFloat * 0.45;

    switch (antic) {
      case _LogoAntic.doubleBlink:
        final b1 = _bell(anticT, 0.05, 0.42);
        final b2 = _bell(anticT, 0.52, 0.92);
        final close = math.max(b1, b2);
        leftBlink = 1.0 - close * 0.92;
        rightBlink = 1.0 - close * 0.92;
        break;

      case _LogoAntic.crossEyed:
        // Hilarious cross-eyed goofball! Pupils slide inward & slightly opposite vertically,
        // 'T' tilts curiously, 'l' & 'e' giggle/boing, then crisp blink back!
        final env = _holdEnvelope(anticT, 0.22, 0.72);
        final wobble = math.sin(anticT * math.pi * 6.0) * env;
        leftLookX = baseGazeX * (1.0 - env) + (1.18 * env);
        rightLookX = baseGazeX * (1.0 - env) + (-1.18 * env);
        leftLookY = -0.35 * env + wobble * 0.15;
        rightLookY = 0.35 * env - wobble * 0.15;
        eyePopScale = 1.0 + env * 0.06;
        tAngle = -0.14 * env;
        tDy = -1.2 * env;
        lScaleY = 1.0 + math.sin(anticT * math.pi * 4.0) * 0.09 * env;
        lScaleX = 1.0 / math.sqrt(lScaleY);
        eAngle = 0.12 * wobble;
        rWaveAngle += 0.18 * wobble;
        // Clean reset blink at the very end
        final endBlink = _bell(anticT, 0.80, 0.98);
        leftBlink = 1.0 - endBlink * 0.92;
        rightBlink = 1.0 - endBlink * 0.92;
        break;

      case _LogoAntic.waveAndTip:
        // Polite cap tip on 'T', friendly double wave on 'r', happy glance right!
        final env = _holdEnvelope(anticT, 0.20, 0.78);
        tAngle = 0.16 * env;
        tDy = -1.6 * env;
        leftLookX = baseGazeX * (1.0 - env) + 0.9 * env;
        rightLookX = baseGazeX * (1.0 - env) + 0.9 * env;
        leftLookY = -0.25 * env;
        rightLookY = -0.25 * env;
        final waveOsc = math.sin(anticT * math.pi * 5.0) * env;
        rWaveAngle = -0.36 * env + waveOsc * 0.26;
        rDotLift = -2.2 * env + waveOsc * 1.4;
        eScaleY = 1.0 + 0.07 * env;
        lDy = -1.5 * _bell(anticT, 0.15, 0.55);
        break;

      case _LogoAntic.sneakySideEye:
        // Mischievous side-eye glance with subtle squint
        final env = _holdEnvelope(anticT, 0.20, 0.78);
        leftLookX = baseGazeX * (1.0 - env) + (-1.05 * env);
        rightLookX = baseGazeX * (1.0 - env) + (-1.05 * env);
        leftLookY = -0.10 * env;
        rightLookY = -0.10 * env;
        leftBlink = 1.0 - 0.28 * env;
        rightBlink = 1.0 - 0.28 * env;
        tAngle = -0.07 * env;
        break;

      case _LogoAntic.cheekyWink:
        // Cheeky smiling "^" wink on right eye + playful 'r' wave + 'T' tip + 'e' chuckle
        final winkEnv = _holdEnvelope(anticT, 0.18, 0.72);
        rightHappy = winkEnv > 0.35;
        rightBlink = 1.0 - winkEnv * 0.85;
        leftLookX = 0.45 * winkEnv;
        leftLookY = -0.20 * winkEnv;
        tAngle = 0.15 * winkEnv;
        tDy = -1.8 * _bell(anticT, 0.08, 0.55);
        eDy = -1.4 * _bell(anticT, 0.20, 0.65);
        eAngle = -0.12 * winkEnv;
        final wWave = math.sin(anticT * math.pi * 5.0) * winkEnv;
        rWaveAngle = -0.32 * winkEnv + wWave * 0.28;
        rDotLift = -2.0 * winkEnv + wWave * 1.5;
        break;

      case _LogoAntic.dominoJump:
        // Full 6-letter joyful elastic domino wave (T -> o -> o -> l -> e -> r) with happy ^ ^ eyes!
        final p0 = _bell(anticT, 0.00, 0.40);
        final p1 = _bell(anticT, 0.10, 0.50);
        final p2 = _bell(anticT, 0.20, 0.60);
        final p3 = _bell(anticT, 0.30, 0.70);
        final p4 = _bell(anticT, 0.40, 0.80);
        final p5 = _bell(anticT, 0.50, 0.94);

        tDy = -4.2 * p0;
        tAngle = -0.12 * p0;
        leftEyeDy = -4.0 * p1;
        rightEyeDy = -4.0 * p2;
        leftHappy = p1 > 0.25 || p2 > 0.25;
        rightHappy = p1 > 0.25 || p2 > 0.25;
        lDy = -4.8 * p3;
        lScaleY = 1.0 + 0.14 * p3;
        lScaleX = 1.0 - 0.07 * p3;
        eDy = -4.2 * p4;
        eAngle = 0.14 * p4;
        rDy = -4.2 * p5;
        rWaveAngle = -0.34 * p5;
        rDotLift = -2.8 * p5;
        break;

      case _LogoAntic.none:
        break;
    }

    // Shared Paints
    final textPaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final irisPaint = Paint()
      ..color = pupilColor
      ..style = PaintingStyle.fill;

    final scleraPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final pupilCorePaint = Paint()
      ..color = isDark ? const Color(0xFF09090B) : const Color(0xFF18181B)
      ..style = PaintingStyle.fill;

    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // -------------------------------------------------------------------------
    // 1. LETTER 'T' — Expressive Visor / Cap Element
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(15.0, 22.0 + tDy);
    canvas.rotate(tAngle);
    canvas.translate(-15.0, -22.0);
    final tPath = Path()
      ..moveTo(4.5, 9.5)
      ..lineTo(25.5, 9.5)
      ..arcToPoint(const Offset(27.0, 12.0), radius: const Radius.circular(2.5))
      ..arcToPoint(const Offset(25.5, 14.5), radius: const Radius.circular(2.5))
      ..lineTo(19.0, 14.5)
      ..quadraticBezierTo(18.5, 16.0, 18.5, 17.5)
      ..lineTo(18.5, 34.0)
      ..arcToPoint(const Offset(11.5, 34.0), radius: const Radius.circular(3.5))
      ..lineTo(11.5, 17.5)
      ..quadraticBezierTo(11.5, 16.0, 11.0, 14.5)
      ..lineTo(4.5, 14.5)
      ..arcToPoint(const Offset(3.0, 12.0), radius: const Radius.circular(2.5))
      ..arcToPoint(const Offset(4.5, 9.5), radius: const Radius.circular(2.5))
      ..close();
    canvas.drawPath(tPath, textPaint);
    canvas.restore();

    // -------------------------------------------------------------------------
    // 2. FIRST 'o' (LEFT EYE) — Upgraded Expressive Cartoon Eye Element
    // -------------------------------------------------------------------------
    _drawExpressiveEye(
      canvas: canvas,
      center: Offset(45.0, 25.5 + leftEyeDy),
      radius: 12.0,
      blinkScale: leftBlink,
      popScale: eyePopScale,
      lookX: leftLookX,
      lookY: leftLookY,
      isHappyArc: leftHappy,
      scleraPaint: scleraPaint,
      strokePaint: strokePaint,
      irisPaint: irisPaint,
      pupilCorePaint: pupilCorePaint,
      shinePaint: shinePaint,
    );

    // -------------------------------------------------------------------------
    // 3. SECOND 'o' (RIGHT EYE) — Independent Live Eye + Happy Wink Element
    // -------------------------------------------------------------------------
    _drawExpressiveEye(
      canvas: canvas,
      center: Offset(72.0, 25.5 + rightEyeDy),
      radius: 12.0,
      blinkScale: rightBlink,
      popScale: eyePopScale,
      lookX: rightLookX,
      lookY: rightLookY,
      isHappyArc: rightHappy,
      scleraPaint: scleraPaint,
      strokePaint: strokePaint,
      irisPaint: irisPaint,
      pupilCorePaint: pupilCorePaint,
      shinePaint: shinePaint,
    );

    // -------------------------------------------------------------------------
    // 4. LETTER 'l' — Springy Squash-and-Stretch Column Element
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(95.0, 37.0 + lDy);
    canvas.scale(lScaleX, lScaleY);
    canvas.translate(-95.0, -37.0);
    final lStem = RRect.fromRectAndRadius(
      const Rect.fromLTWH(91.5, 7.5, 7.0, 29.5),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(lStem, textPaint);
    canvas.restore();

    // -------------------------------------------------------------------------
    // 5. LETTER 'e' — Cheerful Smiling / Chuckling Glyph Element
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(114.0, 26.0 + eDy);
    canvas.rotate(eAngle);
    canvas.scale(1.0, eScaleY);
    canvas.translate(-114.0, -26.0);
    final ePath = Path()
      ..moveTo(104.2, 25.5)
      ..lineTo(123.8, 25.5)
      ..arcToPoint(
        const Offset(114.0, 15.0),
        radius: const Radius.circular(9.5),
      )
      ..arcToPoint(
        const Offset(104.2, 25.5),
        radius: const Radius.circular(9.5),
      )
      ..arcToPoint(
        const Offset(114.0, 36.8),
        radius: const Radius.circular(10.2),
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(124.0, 31.0),
        radius: const Radius.circular(10.2),
        clockwise: false,
      );
    canvas.drawPath(ePath, strokePaint);
    canvas.restore();

    // -------------------------------------------------------------------------
    // 6. LETTER 'r' — Articulated Stem + Waving Hook Arm + Bouncy Accent Dot
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(0, rDy);

    // Solid stem
    final rStem = RRect.fromRectAndRadius(
      const Rect.fromLTWH(133.0, 15.5, 6.8, 21.5),
      const Radius.circular(3.4),
    );
    canvas.drawRRect(rStem, textPaint);

    // Articulated waving shoulder arch pivoting smoothly at (136.5, 23.0)
    canvas.save();
    canvas.translate(136.5, 23.0);
    canvas.rotate(rWaveAngle);
    canvas.translate(-136.5, -23.0);

    final rArch = Path()
      ..moveTo(136.5, 23.0)
      ..cubicTo(138.0, 16.8, 142.5, 14.8, 148.5, 14.8)
      ..lineTo(149.5, 15.2);
    canvas.drawPath(rArch, strokePaint);

    // Playful accent tip orb with soft subtle spring lift
    canvas.drawCircle(
      Offset(150.0, 15.0 + rDotLift * 0.4),
      3.1,
      irisPaint,
    );
    canvas.drawCircle(
      Offset(151.0, 14.0 + rDotLift * 0.4),
      0.95,
      shinePaint,
    );
    canvas.restore();

    canvas.restore();
    canvas.restore();
  }

  /// Draws an ultra-expressive cartoon eye keeping the exact iconic circular 'o' ring:
  /// - Soft sclera interior
  /// - Colored iris + dark inner pupil core + dual specular catchlights
  /// - Supports smooth 2D gaze, blink squash, pop scale, and smiling "^" happy arc!
  void _drawExpressiveEye({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double blinkScale,
    required double popScale,
    required double lookX,
    required double lookY,
    required bool isHappyArc,
    required Paint scleraPaint,
    required Paint strokePaint,
    required Paint irisPaint,
    required Paint pupilCorePaint,
    required Paint shinePaint,
  }) {
    final ringRadius = radius - 2.6;

    if (isHappyArc) {
      // Cute cheerful smiling "^" eye arc with subtle rosy accent blush dot below!
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(popScale, popScale);
      canvas.translate(-center.dx, -center.dy);

      final happyArc = Path()
        ..moveTo(center.dx - ringRadius * 0.85, center.dy + 1.5)
        ..quadraticBezierTo(
          center.dx,
          center.dy - ringRadius * 0.95,
          center.dx + ringRadius * 0.85,
          center.dy + 1.5,
        );
      canvas.drawPath(happyArc, strokePaint);

      // Tiny playful cheek sparkle below happy eye
      canvas.drawCircle(
        Offset(center.dx, center.dy + ringRadius * 0.65),
        1.8,
        Paint()..color = pupilColor.withValues(alpha: 0.45),
      );
      canvas.restore();
      return;
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(popScale, blinkScale * popScale);
    canvas.translate(-center.dx, -center.dy);

    // Soft clean sclera interior so eyes look crisp & alive
    canvas.drawCircle(center, ringRadius, scleraPaint);

    // Expressive Iris + Dark Pupil Core + Dual Specular Catchlights
    if (blinkScale > 0.24) {
      final dx = lookX.clamp(-1.2, 1.2) * 2.85;
      final dy = lookY.clamp(-1.0, 1.0) * 2.35;
      final pupilPos = Offset(center.dx + dx, center.dy + dy);

      // Clip iris inside eye ring so extreme cross-eye never leaks outside!
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: ringRadius - 1.5)),
      );

      // Vibrant theme-colored iris
      canvas.drawCircle(pupilPos, 4.7, irisPaint);

      // Crisp dark pupil core
      canvas.drawCircle(pupilPos, 2.35, pupilCorePaint);

      // Main bright specular catchlight (top-right)
      canvas.drawCircle(
        Offset(pupilPos.dx + 1.55, pupilPos.dy - 1.55),
        1.45,
        shinePaint,
      );

      // Secondary tiny catchlight (bottom-left) for lively cartoon depth
      canvas.drawCircle(
        Offset(pupilPos.dx - 1.45, pupilPos.dy + 1.45),
        0.65,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );

      canvas.restore();
    }

    // Crisp outer 'o' letter ring
    canvas.drawCircle(center, ringRadius, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ToolerWordmarkPainter oldDelegate) =>
      oldDelegate.textColor != textColor ||
      oldDelegate.pupilColor != pupilColor ||
      oldDelegate.isDark != isDark ||
      oldDelegate.antic != antic ||
      oldDelegate.anticT != anticT ||
      oldDelegate.baseGazeX != baseGazeX ||
      oldDelegate.baseGazeY != baseGazeY ||
      oldDelegate.breatheT != breatheT;
}
