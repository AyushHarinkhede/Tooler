import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// BOUNCY TAP & SPRING ANIMATION SYSTEM (HIGH PERFORMANCE / JITTER-FREE)
/// ---------------------------------------------------------------------------
/// Gives interactive elements a physical, fluid spring bounce on tap
/// with hardware-accelerated GPU matrix scaling and zero layout repaints.
/// ---------------------------------------------------------------------------

class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFraction;
  final Duration duration;
  final Duration reverseDuration;
  final bool enableHaptic;
  final bool enableSound;
  final HitTestBehavior behavior;

  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFraction = 0.95,
    this.duration = const Duration(milliseconds: 90),
    this.reverseDuration = const Duration(milliseconds: 180),
    this.enableHaptic = true,
    this.enableSound = false,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFraction,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _isPressed = true;
    _controller.forward();
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.reverse();
    if (widget.enableSound) {
      SoundService().playClick();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ANIMATED TEXT POP (Numbers & Words - Smooth Easing, Zero Jank)
/// ---------------------------------------------------------------------------
class AnimatedTextPop extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration duration;
  final Axis direction;
  final int? maxLines;
  final TextOverflow? overflow;

  const AnimatedTextPop({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.duration = const Duration(milliseconds: 180),
    this.direction = Axis.vertical,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetTween = direction == Axis.vertical
              ? Tween<Offset>(
                  begin: const Offset(0.0, 0.22),
                  end: Offset.zero,
                )
              : Tween<Offset>(
                  begin: const Offset(0.18, 0.0),
                  end: Offset.zero,
                );

          return SlideTransition(
            position: offsetTween.animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Text(
          text,
          key: ValueKey<String>(text),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: style,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// STAGGERED FADE & SLIDE (Single-Pass, Zero Rebuild Jitter)
/// ---------------------------------------------------------------------------
class StaggeredSlideItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delayBase;
  final Duration duration;
  final Offset offsetBegin;

  const StaggeredSlideItem({
    super.key,
    required this.index,
    required this.child,
    this.delayBase = const Duration(milliseconds: 24),
    this.duration = const Duration(milliseconds: 240),
    this.offsetBegin = const Offset(0, 0.08),
  });

  @override
  State<StaggeredSlideItem> createState() => _StaggeredSlideItemState();
}

class _StaggeredSlideItemState extends State<StaggeredSlideItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: widget.offsetBegin,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    final delay = widget.delayBase * (widget.index < 6 ? widget.index : 6);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: widget.child,
        ),
      ),
    );
  }
}
