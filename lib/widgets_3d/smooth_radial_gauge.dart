import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shared Noise-Meter-grade silky-smooth radial bar gauge & luminous pointer.
///
/// Features:
/// - 260° sweep (140° -> 400°) with 25 precision inner micro-ticks
/// - Recessed background track with soft ambient bloom glow
/// - SweepGradient active arc + luminous multi-layered leading pointer orb
/// - Optional 60/120fps exponential attack/release damping (`smoothDamping`)
/// - Optional floating peak-hold marker dot with smooth decay
class SmoothRadialGauge extends StatefulWidget {
  final double progress;
  final ValueListenable<double>? progressListenable;
  final double? externalPeakProgress;
  final double size;
  final Color gaugeColor;
  final Color primaryColor;
  final Color trackColor;
  final Color? endBenchmarkColor;
  final double strokeWidth;
  final bool smoothDamping;
  final bool enableAutoPeakHold;
  final bool showRestingPointer;
  final double risingSpeed;
  final double fallingSpeed;
  final Widget? center;

  const SmoothRadialGauge({
    super.key,
    required this.progress,
    this.progressListenable,
    this.externalPeakProgress,
    this.size = 264.0,
    required this.gaugeColor,
    required this.primaryColor,
    required this.trackColor,
    this.endBenchmarkColor,
    this.strokeWidth = 13.5,
    this.smoothDamping = true,
    this.enableAutoPeakHold = true,
    this.showRestingPointer = true,
    this.risingSpeed = 11.5,
    this.fallingSpeed = 6.2,
    this.center,
  });

  @override
  State<SmoothRadialGauge> createState() => _SmoothRadialGaugeState();
}

class _SmoothRadialGaugeState extends State<SmoothRadialGauge>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double _displayProgress = 0.0;
  double _peakHoldProgress = 0.0;
  DateTime _peakHoldUpdatedAt = DateTime.now();

  double get _targetProgress =>
      (widget.progressListenable?.value ?? widget.progress).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    if (!widget.smoothDamping) {
      _displayProgress = _targetProgress;
      _peakHoldProgress = _displayProgress;
    } else {
      _displayProgress = 0.0;
      _peakHoldProgress = 0.0;
      _ticker = createTicker(_onTick);
      widget.progressListenable?.addListener(_onTargetListenableChanged);
      if (_targetProgress > 0.0004) {
        _ensureTickerRunning();
      }
    }
  }

  @override
  void didUpdateWidget(covariant SmoothRadialGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progressListenable != widget.progressListenable) {
      oldWidget.progressListenable?.removeListener(_onTargetListenableChanged);
      if (widget.smoothDamping) {
        widget.progressListenable?.addListener(_onTargetListenableChanged);
      }
    }

    if (!widget.smoothDamping) {
      _ticker?.stop();
      _displayProgress = _targetProgress;
      _peakHoldProgress = _displayProgress;
    } else {
      _ticker ??= createTicker(_onTick);
      if ((_targetProgress - _displayProgress).abs() > 0.0004) {
        _ensureTickerRunning();
      }
    }
  }

  void _onTargetListenableChanged() {
    _ensureTickerRunning();
  }

  void _ensureTickerRunning() {
    if (!mounted || !widget.smoothDamping || _ticker == null) return;
    if (!_ticker!.isActive) {
      _lastElapsed = Duration.zero;
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    double dt = 0.016;
    if (_lastElapsed != Duration.zero && elapsed > _lastElapsed) {
      dt = ((elapsed - _lastElapsed).inMicroseconds / 1000000.0)
          .clamp(0.001, 0.05);
    }
    _lastElapsed = elapsed;

    final double target = _targetProgress;
    final bool rising = target > _displayProgress;
    final double speed = rising ? widget.risingSpeed : widget.fallingSpeed;
    final double factor = 1.0 - math.exp(-speed * dt);
    final double nextProgress =
        (_displayProgress + (target - _displayProgress) * factor)
            .clamp(0.0, 1.0);

    double nextPeak = _peakHoldProgress;
    if (widget.enableAutoPeakHold) {
      if (nextProgress >= nextPeak) {
        nextPeak = nextProgress;
        _peakHoldUpdatedAt = DateTime.now();
      } else if (DateTime.now().difference(_peakHoldUpdatedAt).inMilliseconds >
          1600) {
        nextPeak = math.max(nextProgress, nextPeak - 0.18 * dt);
      }
    } else {
      nextPeak = nextProgress;
    }

    final bool progressChanged = (nextProgress - _displayProgress).abs() > 0.00015;
    final bool peakChanged = (nextPeak - _peakHoldProgress).abs() > 0.00015;
    final bool peakWaiting =
        widget.enableAutoPeakHold && nextPeak > nextProgress + 0.001;

    if ((target - nextProgress).abs() <= 0.0004 && !peakWaiting) {
      setState(() {
        _displayProgress = target;
        _peakHoldProgress = widget.enableAutoPeakHold ? nextPeak : target;
      });
      _ticker?.stop();
      return;
    }

    if (progressChanged || peakChanged) {
      setState(() {
        _displayProgress = nextProgress;
        _peakHoldProgress = nextPeak;
      });
    }
  }

  @override
  void dispose() {
    widget.progressListenable?.removeListener(_onTargetListenableChanged);
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double activeProgress =
        widget.smoothDamping ? _displayProgress : _targetProgress;
    final double? activePeak = widget.externalPeakProgress ??
        (widget.smoothDamping && widget.enableAutoPeakHold
            ? _peakHoldProgress
            : null);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: SmoothRadialBarPainter(
                progress: activeProgress,
                peakHoldProgress: activePeak,
                gaugeColor: widget.gaugeColor,
                primaryColor: widget.primaryColor,
                trackColor: widget.trackColor,
                endBenchmarkColor: widget.endBenchmarkColor,
                strokeWidth: widget.strokeWidth,
                showRestingPointer: widget.showRestingPointer,
              ),
            ),
          ),
          if (widget.center != null) widget.center!,
        ],
      ),
    );
  }
}

/// Silky-smooth radial bar gauge painter modeled on the Noise Meter instrument.
class SmoothRadialBarPainter extends CustomPainter {
  final double progress;
  final double? peakHoldProgress;
  final Color gaugeColor;
  final Color primaryColor;
  final Color trackColor;
  final Color? endBenchmarkColor;
  final double strokeWidth;
  final bool showRestingPointer;

  const SmoothRadialBarPainter({
    required this.progress,
    this.peakHoldProgress,
    required this.gaugeColor,
    required this.primaryColor,
    required this.trackColor,
    this.endBenchmarkColor,
    this.strokeWidth = 13.5,
    this.showRestingPointer = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - 18;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // 260° sweep from bottom-left (140°) to bottom-right (400°)
    const double startAngle = 140.0 * math.pi / 180.0;
    const double totalSweep = 260.0 * math.pi / 180.0;

    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double activeSweep = totalSweep * clampedProgress;
    final double? clampedPeak = peakHoldProgress?.clamp(0.0, 1.0);

    // Precompute vivid hue-preserving gradient colors from primaryColor -> gaugeColor
    final List<Color> vividColors =
        buildVividGaugeGradientColors(primaryColor, gaugeColor, steps: 7);

    // 1. Subtle Inner Micro-Tick Scale Dots (25 precision ticks)
    const int tickCount = 24;
    for (int i = 0; i <= tickCount; i++) {
      final double frac = i / tickCount;
      final double ang = startAngle + (totalSweep * frac);
      final bool isMajor = i % 6 == 0;
      final bool isLit =
          clampedProgress > 0.004 ? frac <= clampedProgress : i == 0;
      final double innerR = radius - (isMajor ? 18.0 : 15.0);
      final double outerR = radius - 11.0;

      Color litColor = primaryColor;
      if (isLit && clampedProgress > 0.004) {
        final double localT = (frac / clampedProgress).clamp(0.0, 1.0);
        litColor = sampleGradientColors(vividColors, localT);
      }

      final Paint tickPaint = Paint()
        ..color = isLit
            ? litColor.withValues(alpha: isMajor ? 0.85 : 0.50)
            : trackColor.withValues(alpha: isMajor ? 0.65 : 0.35)
        ..strokeWidth = isMajor ? 2.1 : 1.25
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(ang),
            center.dy + innerR * math.sin(ang)),
        Offset(center.dx + outerR * math.cos(ang),
            center.dy + outerR * math.sin(ang)),
        tickPaint,
      );
    }

    // 2. Smooth Recessed Background Track Arc
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, startAngle, totalSweep, false, trackPaint);

    // 3. Soft Ambient Glow & Silky SweepGradient Active Arc
    // Buffer the gradient rotation backward past startAngle by 0.22 rad (~12.6 deg)
    // so StrokeCap.round's backward half-circle stays strictly within pure primaryColor
    // instead of wrapping across 360 deg into gaugeColor.
    if (activeSweep > 0.005) {
      const double capBufferRad = 0.22;
      const double fullTurn = 2.0 * math.pi;
      final double effSweep = math.max(activeSweep, 0.08);
      const double startStop = capBufferRad / fullTurn;
      final double endStop = (capBufferRad + effSweep) / fullTurn;

      final List<Color> shaderColors = <Color>[
        vividColors.first,
        vividColors.first,
      ];
      final List<double> shaderStops = <double>[
        0.0,
        startStop,
      ];

      for (int i = 1; i < vividColors.length; i++) {
        final double frac = i / (vividColors.length - 1);
        shaderColors.add(vividColors[i]);
        shaderStops.add(startStop + (endStop - startStop) * frac);
      }

      shaderColors.addAll(<Color>[
        vividColors.last,
        vividColors.first,
        vividColors.first,
      ]);
      shaderStops.addAll(<double>[
        math.max(endStop + 0.02, 0.88),
        0.94,
        1.0,
      ]);

      final Shader arcShader = SweepGradient(
        startAngle: 0.0,
        endAngle: fullTurn,
        colors: shaderColors,
        stops: shaderStops,
        transform: const GradientRotation(startAngle - capBufferRad),
      ).createShader(arcRect);

      final Shader glowShader = SweepGradient(
        startAngle: 0.0,
        endAngle: fullTurn,
        colors: shaderColors.map((c) => c.withValues(alpha: 0.32)).toList(),
        stops: shaderStops,
        transform: const GradientRotation(startAngle - capBufferRad),
      ).createShader(arcRect);

      final Paint glowPaint = Paint()
        ..shader = glowShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.5);
      canvas.drawArc(arcRect, startAngle, activeSweep, false, glowPaint);

      final Paint activePaint = Paint()
        ..shader = arcShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, startAngle, activeSweep, false, activePaint);

      // 5. Crisp Luminous Leading Pointer Orb
      final double tipAngle = startAngle + activeSweep;
      final Offset tipCenter = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tipCenter,
        9.0,
        Paint()
          ..color = gaugeColor.withValues(alpha: 0.40)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
      );
      canvas.drawCircle(
        tipCenter,
        5.4,
        Paint()..color = gaugeColor.withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        tipCenter,
        3.5,
        Paint()..color = Colors.white.withValues(alpha: 0.96),
      );
    } else if (showRestingPointer) {
      // Resting pointer orb anchored cleanly at 0% start position
      final Offset startPos = Offset(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      canvas.drawCircle(
        startPos,
        6.5,
        Paint()
          ..color = primaryColor.withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
      canvas.drawCircle(
        startPos,
        4.2,
        Paint()..color = primaryColor.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        startPos,
        2.3,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
    }

    // 6. Floating Peak-Hold Indicator Marker Dot (Noise-Meter Signature)
    if (clampedPeak != null && clampedPeak > clampedProgress + 0.025) {
      final double peakAngle = startAngle + (totalSweep * clampedPeak);
      final Offset peakPos = Offset(
        center.dx + radius * math.cos(peakAngle),
        center.dy + radius * math.sin(peakAngle),
      );
      canvas.drawCircle(
        peakPos,
        6.0,
        Paint()
          ..color = gaugeColor.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
      canvas.drawCircle(
        peakPos,
        3.8,
        Paint()..color = gaugeColor.withValues(alpha: 0.92),
      );
    }

    // 7. Optional 100% Benchmark Goal Marker Dot
    if (endBenchmarkColor != null && clampedProgress < 0.97) {
      const double endAngle = startAngle + totalSweep;
      final Offset endPos = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      canvas.drawCircle(
        endPos,
        3.6,
        Paint()..color = endBenchmarkColor!.withValues(alpha: 0.72),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SmoothRadialBarPainter oldDelegate) {
    return (oldDelegate.progress - progress).abs() > 0.0001 ||
        ((oldDelegate.peakHoldProgress ?? -1) - (peakHoldProgress ?? -1))
                .abs() >
            0.0001 ||
        oldDelegate.gaugeColor != gaugeColor ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.endBenchmarkColor != endBenchmarkColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showRestingPointer != showRestingPointer;
  }
}

/// Builds a rich, vibrant multi-stop color list between [start] and [end] using
/// shortest-arc HSV interpolation so complementary hues (such as pink/red to
/// green or green to red) flow cleanly through warm gold/amber/lime without
/// muddying into desaturated grey-brown midpoints.
List<Color> buildVividGaugeGradientColors(
  Color start,
  Color end, {
  int steps = 7,
}) {
  if (steps < 2 || start.toARGB32() == end.toARGB32()) {
    return <Color>[start, end];
  }

  final HSVColor hsvA = HSVColor.fromColor(start);
  final HSVColor hsvB = HSVColor.fromColor(end);

  // If either endpoint is nearly achromatic (e.g. Slate), direct RGB lerp is cleanest.
  if (hsvA.saturation < 0.12 || hsvB.saturation < 0.12) {
    return List<Color>.generate(
      steps,
      (i) => Color.lerp(start, end, i / (steps - 1))!,
    );
  }

  double deltaHue = hsvB.hue - hsvA.hue;
  if (deltaHue > 180.0) deltaHue -= 360.0;
  if (deltaHue < -180.0) deltaHue += 360.0;

  return List<Color>.generate(steps, (i) {
    final double t = i / (steps - 1);
    if (i == 0) return start;
    if (i == steps - 1) return end;

    final double hue = (hsvA.hue + deltaHue * t) % 360.0;
    final double normalizedHue = hue < 0 ? hue + 360.0 : hue;

    // Gentle mid-arc saturation & value lift prevents washed-out midtones
    final double midLift = math.sin(math.pi * t);
    final double baseSat =
        hsvA.saturation + (hsvB.saturation - hsvA.saturation) * t;
    final double sat =
        (baseSat + midLift * 0.14).clamp(math.min(hsvA.saturation, hsvB.saturation), 0.94);

    final double baseVal = hsvA.value + (hsvB.value - hsvA.value) * t;
    final double val = (baseVal + midLift * 0.05).clamp(0.0, 1.0);

    return HSVColor.fromAHSV(1.0, normalizedHue, sat, val).toColor();
  });
}

/// Samples a multi-stop [colors] list evenly at [t] in [0.0, 1.0].
Color sampleGradientColors(List<Color> colors, double t) {
  if (colors.isEmpty) return Colors.white;
  if (colors.length == 1) return colors.first;
  final double clamped = t.clamp(0.0, 1.0);
  final double scaled = clamped * (colors.length - 1);
  final int idx = scaled.floor().clamp(0, colors.length - 2);
  final double localT = scaled - idx;
  return Color.lerp(colors[idx], colors[idx + 1], localT)!;
}
