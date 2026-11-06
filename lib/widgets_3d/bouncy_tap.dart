import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// BOUNCY TAP & SPRING ANIMATION SYSTEM
/// ---------------------------------------------------------------------------
/// Gives every interactive card, button, and pill in Tooler a tactile,
/// physical spring bounce effect with haptic feedback.
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
    this.scaleFraction = 0.94,
    this.duration = const Duration(milliseconds: 100),
    this.reverseDuration = const Duration(milliseconds: 220),
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
        curve: Curves.easeInOutQuad,
        reverseCurve: Curves.easeOutBack,
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
    );
  }
}

/// ---------------------------------------------------------------------------
/// ANIMATED TEXT POP (Numbers & Words)
/// ---------------------------------------------------------------------------
/// Whenever a word is typed, or a number is set/updated, it transitions with a
/// spring bounce scale and vertical slide.
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
    this.duration = const Duration(milliseconds: 240),
    this.direction = Axis.vertical,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInQuad,
      transitionBuilder: (child, animation) {
        final offsetTween = direction == Axis.vertical
            ? Tween<Offset>(
                begin: const Offset(0.0, 0.35),
                end: Offset.zero,
              )
            : Tween<Offset>(
                begin: const Offset(0.25, 0.0),
                end: Offset.zero,
              );

        return SlideTransition(
          position: offsetTween.animate(animation),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
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
    );
  }
}

/// ---------------------------------------------------------------------------
/// STAGGERED FADE & SLIDE TRANSITION CONTAINER
/// ---------------------------------------------------------------------------
class StaggeredSlideItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delayBase;
  final Duration duration;
  final Offset offsetBegin;

  const StaggeredSlideItem({
    super.key,
    required this.index,
    required this.child,
    this.delayBase = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 320),
    this.offsetBegin = const Offset(0, 0.12),
  });

  @override
  Widget build(BuildContext context) {
    final delay = delayBase * index;

    return FutureBuilder<bool>(
      future: Future.delayed(delay, () => true),
      initialData: false,
      builder: (context, snapshot) {
        final isReady = snapshot.data ?? false;
        return AnimatedOpacity(
          opacity: isReady ? 1.0 : 0.0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: isReady ? Offset.zero : offsetBegin,
            duration: duration,
            curve: Curves.easeOutBack,
            child: child,
          ),
        );
      },
    );
  }
}
