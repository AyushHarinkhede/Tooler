import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// FLAPPY SKY BIRD — 60FPS Silky Physics Arcade Flapper
/// Tap anywhere to flap past glossy emerald pipes, collect medals & beat best!
/// ---------------------------------------------------------------------------
class FlappyBirdGame extends StatefulWidget {
  final StationeryTheme theme;
  const FlappyBirdGame({super.key, required this.theme});

  @override
  State<FlappyBirdGame> createState() => _FlappyBirdGameState();
}

class _PipePair {
  double x; // 0.0 to 1.2 normalized width
  final double gapCenterY; // 0.24 to 0.66 normalized height
  bool passed = false;

  _PipePair({required this.x, required this.gapCenterY});
}

class _FlappyBirdGameState extends State<FlappyBirdGame>
    with SingleTickerProviderStateMixin {
  static const String _bestKey = 'tooler_game_flappy_best_v1';
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  bool _started = false;
  bool _gameOver = false;
  int _score = 0;
  int _bestScore = 0;

  double _birdY = 0.44; // normalized [0..1]
  double _birdVel = 0.0;
  double _wingPhase = 0.0;
  double _groundScroll = 0.0;
  double _cloudScroll = 0.0;

  final List<_PipePair> _pipes = [];

  static const double _birdX = 0.28;
  static const double _gravity = 1.95;
  static const double _flapImpulse = -0.62;
  static const double _gapHeight = 0.265;
  static const double _groundTop = 0.87;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _bestScore = prefs.getInt(_bestKey) ?? 0);
    }
  }

  Future<void> _saveBest(int val) async {
    if (val <= _bestScore) return;
    _bestScore = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestKey, val);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _resetAndStart() {
    _pipes.clear();
    _score = 0;
    _birdY = 0.44;
    _birdVel = _flapImpulse;
    _started = true;
    _gameOver = false;
    _spawnPipe(1.12);
    _spawnPipe(1.66);
    SoundService().playTap();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _flap() {
    if (_gameOver) {
      _resetAndStart();
      return;
    }
    if (!_started) {
      _resetAndStart();
      return;
    }
    _birdVel = _flapImpulse;
    SoundService().playTap();
    HapticFeedback.selectionClick();
  }

  void _spawnPipe(double startX) {
    final gapY = 0.25 + _rng.nextDouble() * 0.40;
    _pipes.add(_PipePair(x: startX, gapCenterY: gapY));
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 0.016
        : ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.001, 0.045);
    _lastTick = elapsed;

    _wingPhase += dt * (_gameOver ? 0.0 : 12.0);
    _cloudScroll = (_cloudScroll + dt * 0.045) % 1.0;

    if (!_started) {
      // Gentle idle hover
      _birdY = 0.44 + math.sin(_wingPhase * 0.45) * 0.022;
      _groundScroll = (_groundScroll + dt * 0.30) % 1.0;
      if (mounted) setState(() {});
      return;
    }

    if (_gameOver) return;

    final speed = (0.36 + (_score * 0.004)).clamp(0.36, 0.56);
    _groundScroll = (_groundScroll + dt * speed) % 1.0;

    _birdVel += _gravity * dt;
    _birdY += _birdVel * dt;

    // Ceiling & ground check
    if (_birdY < 0.03) {
      _birdY = 0.03;
      _birdVel = 0;
    }
    if (_birdY >= _groundTop - 0.035) {
      _birdY = _groundTop - 0.035;
      _triggerGameOver();
      return;
    }

    // Move pipes & check collisions
    for (int i = _pipes.length - 1; i >= 0; i--) {
      final p = _pipes[i];
      p.x -= speed * dt;

      if (!p.passed && p.x < _birdX - 0.03) {
        p.passed = true;
        _score++;
        SoundService().playKey();
        HapticFeedback.lightImpact();
      }

      // Collision box (forgiving classic Flappy hitbox)
      const double pipeHalfW = 0.068;
      if ((p.x - _birdX).abs() < pipeHalfW + 0.025) {
        final gapTop = p.gapCenterY - _gapHeight / 2;
        final gapBottom = p.gapCenterY + _gapHeight / 2;
        if (_birdY - 0.026 < gapTop || _birdY + 0.026 > gapBottom) {
          _triggerGameOver();
          return;
        }
      }

      if (p.x < -0.15) {
        _pipes.removeAt(i);
      }
    }

    if (_pipes.isEmpty || _pipes.last.x < 0.58) {
      _spawnPipe(1.14);
    }

    if (mounted) setState(() {});
  }

  void _triggerGameOver() {
    _gameOver = true;
    HapticFeedback.heavyImpact();
    SoundService().playClick();
    _saveBest(_score);
    if (mounted) setState(() {});
  }

  String _medalLabel(int s) {
    if (s >= 40) return 'PLATINUM MEDAL';
    if (s >= 25) return 'GOLD MEDAL';
    if (s >= 12) return 'SILVER MEDAL';
    if (s >= 5) return 'BRONZE MEDAL';
    return 'KEEP FLAPPING';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score & Best Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flutter_dash_rounded, color: theme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SCORE: $_score',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: theme.text,
                    ),
                  ),
                ],
              ),
              Text(
                'BEST: $_bestScore',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Interactive Sky Canvas
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _flap(),
            child: Container(
              height: 430,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.border, width: 1.6),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _FlappySkyPainter(
                      birdX: _birdX,
                      birdY: _birdY,
                      birdVel: _birdVel,
                      wingPhase: _wingPhase,
                      groundScroll: _groundScroll,
                      cloudScroll: _cloudScroll,
                      pipes: _pipes,
                      gapHeight: _gapHeight,
                      groundTop: _groundTop,
                      isDark: theme.isDark,
                      accent: theme.primary,
                    ),
                  ),

                  // Big Arcade Center Score while flying
                  if (_started && !_gameOver)
                    Positioned(
                      top: 22,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          '$_score',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Ready prompt
                  if (!_started && !_gameOver)
                    Positioned(
                      bottom: 92,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'TAP ANYWHERE TO FLAP',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Game Over Card
                  if (_gameOver)
                    Container(
                      color: Colors.black.withValues(alpha: 0.48),
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: theme.border, width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 38,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'GAME OVER',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: theme.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_medalLabel(_score)} · Score $_score · Best $_bestScore',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _resetAndStart,
                                icon: const Icon(Icons.replay_rounded),
                                label: Text(
                                  'FLAP AGAIN',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Tactile Flap Action Controller Deck
        Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _flap,
                  child: Ink(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primary,
                          theme.primary.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.primary,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.flutter_dash_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _gameOver ? 'PLAY AGAIN' : (_started ? 'TAP TO FLAP WINGS' : 'START FLIGHT'),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlappySkyPainter extends CustomPainter {
  final double birdX;
  final double birdY;
  final double birdVel;
  final double wingPhase;
  final double groundScroll;
  final double cloudScroll;
  final List<_PipePair> pipes;
  final double gapHeight;
  final double groundTop;
  final bool isDark;
  final Color accent;

  _FlappySkyPainter({
    required this.birdX,
    required this.birdY,
    required this.birdVel,
    required this.wingPhase,
    required this.groundScroll,
    required this.cloudScroll,
    required this.pipes,
    required this.gapHeight,
    required this.groundTop,
    required this.isDark,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gY = h * groundTop;

    // 1. Sky Gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, gY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E3A5F)]
              : const [Color(0xFF38BDF8), Color(0xFFBAE6FD)],
        ).createShader(Rect.fromLTWH(0, 0, w, gY)),
    );

    // 2. Soft Drifting Clouds
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.14 : 0.72);
    for (int i = 0; i < 4; i++) {
      final cx = ((i * 0.34 - cloudScroll + 1.4) % 1.4 - 0.2) * w;
      final cy = h * (0.14 + (i % 2) * 0.12);
      canvas.drawCircle(Offset(cx, cy), 22, cloudPaint);
      canvas.drawCircle(Offset(cx + 18, cy - 5), 18, cloudPaint);
      canvas.drawCircle(Offset(cx + 34, cy + 2), 16, cloudPaint);
    }

    // 3. Glossy Beveled Green Pipes
    final pipeW = w * 0.135;
    for (final p in pipes) {
      final px = p.x * w - pipeW / 2;
      final topH = (p.gapCenterY - gapHeight / 2) * h;
      final botY = (p.gapCenterY + gapHeight / 2) * h;
      final botH = (gY - botY).clamp(0.0, h);

      _drawPipe(canvas, Rect.fromLTWH(px, 0, pipeW, topH), isTop: true);
      _drawPipe(canvas, Rect.fromLTWH(px, botY, pipeW, botH), isTop: false);
    }

    // 4. Scrolling Ground Strip
    canvas.drawRect(
      Rect.fromLTWH(0, gY, w, h - gY),
      Paint()..color = isDark ? const Color(0xFF3F2E1E) : const Color(0xFFD9C382),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, gY, w, 13),
      Paint()..color = const Color(0xFF22C55E),
    );
    const stripeW = 28.0;
    final off = (groundScroll * stripeW * 4) % stripeW;
    final stripePaint = Paint()..color = const Color(0xFF16A34A);
    for (double sx = -stripeW - off; sx < w + stripeW; sx += stripeW) {
      final path = Path()
        ..moveTo(sx, gY)
        ..lineTo(sx + 12, gY)
        ..lineTo(sx + 4, gY + 13)
        ..lineTo(sx - 8, gY + 13)
        ..close();
      canvas.drawPath(path, stripePaint);
    }

    // 5. Cute Expressive Vector Bird with Pitch & Flapping Wing
    final bx = birdX * w;
    final by = birdY * h;
    final angle = (birdVel * 1.15).clamp(-0.48, 1.12);

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(angle);

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 26),
      Paint()..color = const Color(0xFFFACC15),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 26),
      Paint()
        ..color = const Color(0xFF854D0E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Belly highlight
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-1, 5), width: 22, height: 11),
      Paint()..color = const Color(0xFFFEF08A),
    );

    // Flapping Wing
    final wingY = math.sin(wingPhase) * 5.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-6, 1 + wingY * 0.5), width: 16, height: 10),
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-6, 1 + wingY * 0.5), width: 16, height: 10),
      Paint()
        ..color = const Color(0xFF854D0E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Eye
    canvas.drawCircle(const Offset(8, -4), 5.2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(9.5, -4), 2.4, Paint()..color = const Color(0xFF0F172A));

    // Orange Beak
    final beak = Path()
      ..moveTo(14, -1)
      ..lineTo(24, 2.5)
      ..lineTo(14, 6.5)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFF97316));

    canvas.restore();
  }

  void _drawPipe(Canvas canvas, Rect rect, {required bool isTop}) {
    if (rect.height <= 0) return;
    final grad = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF15803D), Color(0xFF4ADE80), Color(0xFF16A34A), Color(0xFF14532D)],
        stops: [0.0, 0.28, 0.70, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, grad);

    final border = Paint()
      ..color = const Color(0xFF14532D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, border);

    // Rim Cap
    const capH = 22.0;
    final capRect = Rect.fromLTWH(
      rect.left - 4,
      isTop ? rect.bottom - capH : rect.top,
      rect.width + 8,
      capH,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(4)), grad);
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(4)), border);
  }

  @override
  bool shouldRepaint(covariant _FlappySkyPainter old) => true;
}
