import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import 'bouncy_tap.dart';

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
///    - Right: Fullscreen Toggle + Favorite Button (♥) with live persistence
/// ---------------------------------------------------------------------------

class ToolerHoverSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tag;
  final StationeryTheme theme;
  final Widget child;
  final VoidCallback? onFavorite;
  final VoidCallback? onClose;
  final bool isDirectHomeOverlay;
  final Animation<double>? sheetAnimation;

  const ToolerHoverSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.theme,
    required this.child,
    this.onFavorite,
    this.onClose,
    this.isDirectHomeOverlay = false,
    this.sheetAnimation,
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
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 440),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ToolerHoverSheet(
            title: title,
            subtitle: subtitle,
            tag: tag,
            theme: theme,
            onFavorite: onFavorite,
            sheetAnimation: animation,
            child: child,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, page) {
          // Motion is driven directly inside ToolerHoverSheet so the sheet slides
          // 100% solid opaque (zero fade blend) from bottom-to-top with upward
          // throw-stretch bounce while the backdrop stays cleanly anchored.
          return page;
        },
      ),
    );
  }

  static void toggleFullScreen(BuildContext context) {
    ToolerHoverSheetScope.of(context)?.toggleFullScreen();
  }

  static bool isFullScreen(BuildContext context) {
    return ToolerHoverSheetScope.of(context)?.isFullScreen ?? false;
  }

  @override
  State<ToolerHoverSheet> createState() => _ToolerHoverSheetState();
}

class ToolerHoverSheetScope extends InheritedWidget {
  final bool isFullScreen;
  final VoidCallback toggleFullScreen;

  const ToolerHoverSheetScope({
    super.key,
    required this.isFullScreen,
    required this.toggleFullScreen,
    required super.child,
  });

  static ToolerHoverSheetScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ToolerHoverSheetScope>();
  }

  @override
  bool updateShouldNotify(ToolerHoverSheetScope oldWidget) {
    return isFullScreen != oldWidget.isFullScreen;
  }
}

class _ToolerHoverSheetState extends State<ToolerHoverSheet> {
  bool _isFavorite = false;
  bool _isFullScreen = false;
  bool _isDockActive = false;
  double _dragOffsetY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  void _dismissSheet() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  void _toggleFullScreen() {
    SoundService().playClick();
    HapticFeedback.lightImpact();
    setState(() {
      _isFullScreen = !_isFullScreen;
      _dragOffsetY = 0.0;
    });
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

  Widget _buildDockBar(StationeryTheme theme, bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _isDockActive = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        SoundService().playClick();
        HapticFeedback.lightImpact();
        _toggleFullScreen();
        Future.delayed(const Duration(milliseconds: 280), () {
          if (mounted) setState(() => _isDockActive = false);
        });
      },
      onTapCancel: () {
        setState(() {
          _isDockActive = false;
          _dragOffsetY = 0.0;
        });
      },
      onVerticalDragStart: (details) {
        setState(() {
          _isDockActive = true;
          _isDragging = true;
        });
        HapticFeedback.lightImpact();
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffsetY += details.primaryDelta!;
          if (_isFullScreen) {
            if (_dragOffsetY < 0) _dragOffsetY = 0;
          } else {
            if (_dragOffsetY < -50) _dragOffsetY = -50;
          }
        });
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        if (_dragOffsetY > 45 || velocity > 220) {
          // Drag down -> Back / exit full-screen or hover page
          SoundService().playClick();
          HapticFeedback.mediumImpact();
          if (_isFullScreen) {
            // In full-screen mode: pushing/dragging down ALWAYS returns to hover screen!
            setState(() {
              _isFullScreen = false;
              _dragOffsetY = 0.0;
              _isDockActive = false;
              _isDragging = false;
            });
          } else {
            // In hover mode: dragging down dismisses the sheet back to home screen
            _dismissSheet();
          }
        } else if (_dragOffsetY < -25 || velocity < -220) {
          // Push up -> Full screen view
          SoundService().playClick();
          HapticFeedback.lightImpact();
          if (!_isFullScreen) {
            setState(() {
              _isFullScreen = true;
              _dragOffsetY = 0.0;
              _isDockActive = false;
              _isDragging = false;
            });
          } else {
            setState(() {
              _dragOffsetY = 0.0;
              _isDockActive = false;
              _isDragging = false;
            });
          }
        } else {
          // Snap back
          setState(() {
            _dragOffsetY = 0.0;
            _isDockActive = false;
            _isDragging = false;
          });
        }
      },
      onVerticalDragCancel: () {
        setState(() {
          _dragOffsetY = 0.0;
          _isDockActive = false;
          _isDragging = false;
        });
      },
      child: Container(
        height: 32,
        width: double.infinity,
        alignment: Alignment.center,
        color: Colors.transparent, // Generous 32px touch target across the screen
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: _isDockActive ? 72 : 50,
          height: _isDockActive ? 6.0 : 4.8,
          decoration: BoxDecoration(
            color: _isDockActive
                ? theme.primary
                : (isDark ? Colors.white.withValues(alpha: 0.32) : theme.border.withValues(alpha: 0.95)),
            borderRadius: BorderRadius.circular(3),
            boxShadow: _isDockActive
                ? [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.55),
                      blurRadius: 12,
                      spreadRadius: 1.5,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final screenHeight = mq.size.height;
    final anim = widget.sheetAnimation;

    final sheetColumn = SafeArea(
      bottom: false,
      top: false, // Explicitly managed with topInset so full-screen edge background stays seamless
      child: Column(
        children: [
          // Top Empty Space in Hover Mode (~topInset + 54px):
          // Allows user to see live home screen and taps/swipes dismiss smoothly.
          // Collapses to 0 in full-screen mode.
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: _isFullScreen ? 0 : (topInset > 0 ? topInset + 50 : 64),
            width: double.infinity,
            child: _isFullScreen
                ? const SizedBox.shrink()
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      SoundService().playClick();
                      _dismissSheet();
                    },
                    onVerticalDragEnd: (details) {
                      if ((details.primaryVelocity ?? 0) > 100) {
                        SoundService().playClick();
                        HapticFeedback.mediumImpact();
                        _dismissSheet();
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
          ),

          // Main Themed Sheet Container (100% solid opaque — zero fade blend)
          Expanded(
            child: Transform.translate(
              offset: Offset(0, _dragOffsetY > 0 ? _dragOffsetY : _dragOffsetY * 0.4),
              child: AnimatedContainer(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_isFullScreen ? 0 : 32),
                  ),
                  border: Border.all(
                    color: _isFullScreen ? Colors.transparent : theme.border,
                    width: _isFullScreen ? 0 : 1.2,
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
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_isFullScreen ? 0 : 32),
                  ),
                  child: Column(
                    children: [
                      // 2.1 System Notch / Status Bar / Control Centre Clearance
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        height: _isFullScreen ? (topInset > 0 ? topInset + 6 : 28) : 4,
                      ),

                      // 2.2 Interactive Drag Handle Dock Bar
                      _buildDockBar(theme, isDark),

                      // 2.3 Unified Header Row: [Back Button] [Title] [Fullscreen & Favorite]
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            // Left: Back Button (<)
                            BouncyTap(
                              onTap: () {
                                SoundService().playClick();
                                _dismissSheet();
                              },
                              scaleFraction: 0.90,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.cardBg,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: theme.border, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
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
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: theme.text,
                                  ),
                                ),
                              ),
                            ),

                            // Dedicated Fullscreen Toggle Button
                            BouncyTap(
                              onTap: _toggleFullScreen,
                              scaleFraction: 0.88,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _isFullScreen
                                      ? theme.primary
                                      : (isDark
                                          ? theme.primary.withValues(alpha: 0.20)
                                          : theme.primary.withValues(alpha: 0.10)),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: _isFullScreen
                                        ? theme.primary
                                        : theme.primary.withValues(alpha: 0.38),
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isFullScreen
                                          ? theme.primary.withValues(alpha: 0.40)
                                          : theme.primary.withValues(alpha: 0.12),
                                      blurRadius: _isFullScreen ? 10 : 6,
                                      spreadRadius: _isFullScreen ? 1 : 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, anim) => RotationTransition(
                                      turns: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                                      child: FadeTransition(opacity: anim, child: child),
                                    ),
                                    child: Icon(
                                      _isFullScreen
                                          ? Icons.close_fullscreen_rounded
                                          : Icons.open_in_full_rounded,
                                      key: ValueKey<bool>(_isFullScreen),
                                      size: 19,
                                      color: _isFullScreen ? Colors.white : theme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Right: Favorite Button (♥)
                            BouncyTap(
                              onTap: _toggleFavorite,
                              scaleFraction: 0.88,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _isFavorite
                                      ? const Color(0xFFFF4757).withValues(alpha: 0.12)
                                      : theme.cardBg,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: _isFavorite
                                        ? const Color(0xFFFF4757).withValues(alpha: 0.45)
                                        : theme.border,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isFavorite
                                          ? const Color(0xFFFF4757).withValues(alpha: 0.18)
                                          : Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedScale(
                                    scale: _isFavorite ? 1.15 : 1.0,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutBack,
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
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      Divider(color: theme.border.withValues(alpha: 0.8), height: 1),

                      // 2.4 Tool's interactive content
                      Expanded(
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return ToolerHoverSheetScope(
      isFullScreen: _isFullScreen,
      toggleFullScreen: _toggleFullScreen,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: anim == null
            ? Stack(
                children: [
                  if (!widget.isDirectHomeOverlay)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                          ),
                        ),
                      ),
                    ),
                  sheetColumn,
                ],
              )
            : AnimatedBuilder(
                animation: anim,
                child: sheetColumn,
                builder: (context, child) {
                  final double t = anim.value.clamp(0.0, 1.0);
                  final bool isClosing = anim.status == AnimationStatus.reverse;

                  // Smooth full bottom-to-top slide on open, full top-to-bottom slide on close
                  // ZERO opacity/fade blend on the hover page — 100% visible till last pixel!
                  final double slideProgress = isClosing
                      ? Curves.easeOutCubic.transform(t)
                      : Curves.easeOutQuart.transform(t);
                  final double translateY = (1.0 - slideProgress) * screenHeight;

                  // Subtle upward throw-stretch + soft spring bounce on appear (bottom-anchored so zero gap!)
                  double scaleY = 1.0;
                  double scaleX = 1.0;
                  if (!isClosing && t > 0.14 && t < 1.0) {
                    final double u = ((t - 0.14) / 0.86).clamp(0.0, 1.0);
                    final double wave =
                        math.sin(u * math.pi * 2.0) * math.pow(1.0 - u, 1.55);
                    scaleY = 1.0 + (0.048 * wave); // Gentle ~+3.2% upward stretch then soft settle
                    scaleX = 1.0 - (0.011 * wave); // Subtle elastic volume balance
                  }

                  final double backdropAlpha =
                      (isDark ? 0.42 : 0.24) * Curves.easeOut.transform(t);
                  final double blurSigma = 6.0 * Curves.easeOut.transform(t);

                  return Stack(
                    children: [
                      if (!widget.isDirectHomeOverlay && t > 0.01)
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: blurSigma,
                                sigmaY: blurSigma,
                              ),
                              child: Container(
                                color: Colors.black.withValues(alpha: backdropAlpha),
                              ),
                            ),
                          ),
                        ),
                      Transform.translate(
                        offset: Offset(0, translateY),
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                          child: child,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
