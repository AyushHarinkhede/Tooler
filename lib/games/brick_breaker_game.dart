import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// NEON BRICK BREAKER — 60FPS Arcade Arkanoid / Breakout
/// Smashing bricks, explosive dynamite, falling power-ups, and laser paddle!
/// ---------------------------------------------------------------------------
class BrickBreakerGame extends StatefulWidget {
  final StationeryTheme theme;
  const BrickBreakerGame({super.key, required this.theme});

  @override
  State<BrickBreakerGame> createState() => _BrickBreakerGameState();
}

enum _PowerUpType { multiball, widePaddle, shieldFloor, bonusScore }

class _Brick {
  double x; // normalized 0..1
  double y; // normalized 0..1
  double w;
  double h;
  int hits;
  int maxHits;
  final bool isBomb;
  final _PowerUpType? powerUp;
  final Color color;

  _Brick({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.hits,
    required this.maxHits,
    this.isBomb = false,
    this.powerUp,
    required this.color,
  });
}

class _Ball {
  double x;
  double y;
  double vx;
  double vy;
  final double radius = 0.018;
  final List<Offset> trail = [];

  _Ball({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}

class _FallingPowerUp {
  double x;
  double y;
  final _PowerUpType type;
  _FallingPowerUp({required this.x, required this.y, required this.type});
}

class _BrickParticle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  final Color color;
  _BrickParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
  });
}

class _BrickBreakerGameState extends State<BrickBreakerGame>
    with SingleTickerProviderStateMixin {
  static const String _bestKey = 'tooler_game_brick_breaker_best_v1';
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  bool _running = false;
  bool _gameOver = false;
  bool _gameWon = false;
  int _score = 0;
  int _bestScore = 0;
  int _lives = 3;
  int _level = 1;

  double _paddleX = 0.5; // center
  double _paddleW = 0.22; // width fraction
  double _paddleTargetW = 0.22;
  double _shieldSec = 0.0;

  final List<_Ball> _balls = [];
  final List<_Brick> _bricks = [];
  final List<_FallingPowerUp> _powerUps = [];
  final List<_BrickParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _loadBest();
    _ticker = createTicker(_onTick);
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _bestScore = prefs.getInt(_bestKey) ?? 0);
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

  void _setupLevel(int level) {
    _bricks.clear();
    _balls.clear();
    _powerUps.clear();
    _particles.clear();
    _shieldSec = 0.0;
    _paddleTargetW = 0.22;
    _paddleW = 0.22;

    // Build brick grid (rows x cols)
    const rows = 5;
    const cols = 7;
    const startY = 0.10;
    const brickH = 0.042;
    const marginX = 0.03;
    const brickW = (1.0 - (marginX * 2)) / cols;

    const palette = [
      Color(0xFFF43F5E), // Rose
      Color(0xFFFB923C), // Orange
      Color(0xFFFACC15), // Amber
      Color(0xFF10B981), // Emerald
      Color(0xFF38BDF8), // Sky Blue
    ];

    for (int r = 0; r < rows; r++) {
      final rowColor = palette[r % palette.length];
      for (int c = 0; c < cols; c++) {
        final bx = marginX + (c * brickW);
        final by = startY + (r * (brickH + 0.012));
        final isBomb = _rng.nextDouble() < 0.08;
        _PowerUpType? pUp;
        if (!isBomb && _rng.nextDouble() < 0.22) {
          const types = _PowerUpType.values;
          pUp = types[_rng.nextInt(types.length)];
        }
        final maxH = (r == 0 && level > 1) ? 2 : 1;
        _bricks.add(
          _Brick(
            x: bx + 0.005,
            y: by,
            w: brickW - 0.010,
            h: brickH,
            hits: maxH,
            maxHits: maxH,
            isBomb: isBomb,
            powerUp: pUp,
            color: isBomb ? const Color(0xFFEF4444) : rowColor,
          ),
        );
      }
    }

    // Spawn starter ball on paddle
    _balls.add(
      _Ball(
        x: _paddleX,
        y: 0.82,
        vx: (_rng.nextBool() ? 0.38 : -0.38),
        vy: -0.62,
      ),
    );
  }

  void _startGame() {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    setState(() {
      _running = true;
      _gameOver = false;
      _gameWon = false;
      _score = 0;
      _lives = 3;
      _level = 1;
      _paddleX = 0.5;
      _setupLevel(_level);
    });
    _lastTick = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _nextLevel() {
    SoundService().playSuccess();
    HapticFeedback.heavyImpact();
    setState(() {
      _level++;
      _score += 500;
      _setupLevel(_level);
    });
  }

  void _onTick(Duration elapsed) {
    if (!_running || _gameOver || _gameWon) return;
    final dt = _lastTick == Duration.zero
        ? 0.016
        : ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.001, 0.04);
    _lastTick = elapsed;

    // Smooth paddle width transitions
    _paddleW += (_paddleTargetW - _paddleW) * (dt * 5.0);

    // Shield countdown
    if (_shieldSec > 0) {
      _shieldSec = math.max(0, _shieldSec - dt);
    }

    // 1. Move Falling Power-ups
    for (int i = _powerUps.length - 1; i >= 0; i--) {
      final p = _powerUps[i];
      p.y += dt * 0.28;
      // Check collision with paddle
      if (p.y >= 0.84 && p.y <= 0.88) {
        if ((p.x >= _paddleX - (_paddleW / 2)) && (p.x <= _paddleX + (_paddleW / 2))) {
          _applyPowerUp(p.type);
          _powerUps.removeAt(i);
          continue;
        }
      }
      if (p.y > 1.05) {
        _powerUps.removeAt(i);
      }
    }

    // 2. Update Particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final pt = _particles[i];
      pt.x += pt.vx * dt;
      pt.y += pt.vy * dt;
      pt.life -= dt * 2.5;
      if (pt.life <= 0) _particles.removeAt(i);
    }

    // 3. Update Balls
    const paddleY = 0.86;
    const paddleTop = paddleY - 0.015;
    const paddleBottom = paddleY + 0.025;

    for (int bIdx = _balls.length - 1; bIdx >= 0; bIdx--) {
      final ball = _balls[bIdx];

      // Trail
      ball.trail.add(Offset(ball.x, ball.y));
      if (ball.trail.length > 6) ball.trail.removeAt(0);

      ball.x += ball.vx * dt;
      ball.y += ball.vy * dt;

      // Left & Right Wall bounce
      if (ball.x <= ball.radius) {
        ball.x = ball.radius;
        ball.vx = ball.vx.abs();
        SoundService().playTap();
      } else if (ball.x >= 1.0 - ball.radius) {
        ball.x = 1.0 - ball.radius;
        ball.vx = -ball.vx.abs();
        SoundService().playTap();
      }

      // Ceiling bounce
      if (ball.y <= ball.radius) {
        ball.y = ball.radius;
        ball.vy = ball.vy.abs();
        SoundService().playTap();
      }

      // Shield Floor bounce
      if (_shieldSec > 0 && ball.y >= 0.96) {
        ball.y = 0.95;
        ball.vy = -ball.vy.abs();
        SoundService().playKey();
        HapticFeedback.lightImpact();
      }

      // Paddle collision
      if (ball.vy > 0 && ball.y >= paddleTop && ball.y <= paddleBottom) {
        final halfW = _paddleW / 2;
        if (ball.x >= _paddleX - halfW - 0.02 && ball.x <= _paddleX + halfW + 0.02) {
          // Angle depends on where on paddle the ball hit
          final hitOffset = (ball.x - _paddleX) / halfW; // -1.0 to 1.0
          final speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy).clamp(0.68, 1.15);
          final angle = (hitOffset * 0.95).clamp(-1.2, 1.2);

          ball.vx = math.sin(angle) * speed;
          ball.vy = -math.cos(angle) * speed;
          ball.y = paddleTop - ball.radius;

          SoundService().playKey();
          HapticFeedback.lightImpact();
        }
      }

      // Brick collisions
      for (int i = _bricks.length - 1; i >= 0; i--) {
        final br = _bricks[i];
        if (ball.x >= br.x - ball.radius &&
            ball.x <= br.x + br.w + ball.radius &&
            ball.y >= br.y - ball.radius &&
            ball.y <= br.y + br.h + ball.radius) {
          // Rebound ball
          final overlapL = (ball.x - br.x).abs();
          final overlapR = ((br.x + br.w) - ball.x).abs();
          final overlapT = (ball.y - br.y).abs();
          final overlapB = ((br.y + br.h) - ball.y).abs();
          final minOverlap = [overlapL, overlapR, overlapT, overlapB].reduce(math.min);

          if (minOverlap == overlapL || minOverlap == overlapR) {
            ball.vx = -ball.vx;
          } else {
            ball.vy = -ball.vy;
          }

          br.hits--;
          _score += 40;
          SoundService().playTap();
          HapticFeedback.selectionClick();

          // Spawn burst particles
          _spawnParticles(br.x + br.w / 2, br.y + br.h / 2, br.color);

          if (br.hits <= 0) {
            // Check bomb
            if (br.isBomb) {
              _detonateBomb(br.x + br.w / 2, br.y + br.h / 2);
            }
            // Check powerup spawn
            if (br.powerUp != null) {
              _powerUps.add(
                _FallingPowerUp(
                  x: br.x + br.w / 2,
                  y: br.y + br.h / 2,
                  type: br.powerUp!,
                ),
              );
            }
            _bricks.removeAt(i);
          }
          break; // Hit one brick per step
        }
      }

      // Bottom death
      if (ball.y > 1.02) {
        _balls.removeAt(bIdx);
      }
    }

    // Check ball loss
    if (_balls.isEmpty) {
      _lives--;
      HapticFeedback.mediumImpact();
      if (_lives <= 0) {
        _gameOver = true;
        _saveBest(_score);
      } else {
        // Respawn single ball
        _balls.add(
          _Ball(
            x: _paddleX,
            y: 0.82,
            vx: (_rng.nextBool() ? 0.38 : -0.38),
            vy: -0.62,
          ),
        );
      }
    }

    // Check level clear
    if (_bricks.isEmpty) {
      if (_level >= 3) {
        _gameWon = true;
        _saveBest(_score);
      } else {
        _nextLevel();
      }
    }

    if (mounted) setState(() {});
  }

  void _detonateBomb(double cx, double cy) {
    SoundService().playSuccess();
    HapticFeedback.heavyImpact();
    _spawnParticles(cx, cy, const Color(0xFFEF4444), count: 24);

    for (int i = _bricks.length - 1; i >= 0; i--) {
      final b = _bricks[i];
      final bx = b.x + b.w / 2;
      final by = b.y + b.h / 2;
      final dist = math.sqrt((bx - cx) * (bx - cx) + (by - cy) * (by - cy));
      if (dist < 0.16) {
        _score += 50;
        _spawnParticles(bx, by, b.color, count: 6);
        _bricks.removeAt(i);
      }
    }
  }

  void _applyPowerUp(_PowerUpType type) {
    SoundService().playSuccess();
    HapticFeedback.mediumImpact();
    switch (type) {
      case _PowerUpType.multiball:
        if (_balls.isNotEmpty) {
          final b = _balls.first;
          _balls.add(_Ball(x: b.x, y: b.y, vx: -b.vx, vy: b.vy));
          _balls.add(_Ball(x: b.x, y: b.y, vx: b.vx * 0.5, vy: -b.vy.abs()));
        }
        break;
      case _PowerUpType.widePaddle:
        _paddleTargetW = 0.34;
        Future.delayed(const Duration(seconds: 9), () {
          if (mounted) setState(() => _paddleTargetW = 0.22);
        });
        break;
      case _PowerUpType.shieldFloor:
        _shieldSec = 10.0;
        break;
      case _PowerUpType.bonusScore:
        _score += 250;
        break;
    }
  }

  void _spawnParticles(double x, double y, Color color, {int count = 10}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final spd = 0.08 + _rng.nextDouble() * 0.24;
      _particles.add(
        _BrickParticle(
          x: x,
          y: y,
          vx: math.cos(angle) * spd,
          vy: math.sin(angle) * spd,
          life: 0.45 + _rng.nextDouble() * 0.35,
          color: color,
        ),
      );
    }
  }

  void _movePaddle(double delta) {
    if (!_running || _gameOver || _gameWon) return;
    setState(() {
      _paddleX = (_paddleX + delta).clamp(_paddleW / 2, 1.0 - (_paddleW / 2));
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top HUD Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _hudPill('SCORE', '$_score', theme.primary, theme),
              _hudPill('LEVEL', '$_level', const Color(0xFF38BDF8), theme),
              _hudPill('BEST', '$_bestScore', const Color(0xFFF59E0B), theme),
              Row(
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: i < _lives ? const Color(0xFFEF4444) : theme.border,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Interactive Brick Breaker Arena Canvas
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final arenaW = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) {
                  if (!_running) return;
                  setState(() {
                    _paddleX = (_paddleX + d.delta.dx / arenaW).clamp(_paddleW / 2, 1.0 - (_paddleW / 2));
                  });
                },
                onTapDown: (d) {
                  if (!_running) return;
                  setState(() {
                    _paddleX = (d.localPosition.dx / arenaW).clamp(_paddleW / 2, 1.0 - (_paddleW / 2));
                  });
                },
                child: Container(
                  height: 425,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: theme.border, width: 1.6),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _BrickBreakerPainter(
                          paddleX: _paddleX,
                          paddleW: _paddleW,
                          balls: _balls,
                          bricks: _bricks,
                          powerUps: _powerUps,
                          particles: _particles,
                          hasShield: _shieldSec > 0,
                          accent: theme.primary,
                          isDark: theme.isDark,
                        ),
                      ),

                      // Overlay Dialogs: Start / Over / Win
                      if (!_running || _gameOver || _gameWon)
                        Container(
                          color: Colors.black.withValues(alpha: 0.60),
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 26),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.cardBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: theme.border, width: 1.5),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _gameWon
                                        ? Icons.emoji_events_rounded
                                        : (_gameOver ? Icons.sentiment_very_dissatisfied_rounded : Icons.sports_tennis_rounded),
                                    size: 40,
                                    color: _gameWon ? const Color(0xFFF59E0B) : theme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _gameWon ? 'ARCADE MASTER!' : (_gameOver ? 'GAME OVER' : 'BRICK BREAKER'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: theme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _gameWon
                                        ? 'All levels demolished!\nScore: $_score · Best: $_bestScore'
                                        : (_gameOver
                                            ? 'Reached Level $_level · Score: $_score · Best: $_bestScore'
                                            : 'Smash all neon bricks!\nSlide paddle to bounce ball, catch powerups & bombs!'),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _startGame,
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(
                                      _gameOver || _gameWon ? 'PLAY AGAIN' : 'START GAME',
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
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Ergonomic Tactile Paddle Control Deck
        Row(
          children: [
            Expanded(
              flex: 4,
              child: _paddleButton(
                icon: Icons.keyboard_double_arrow_left_rounded,
                label: 'GLIDE LEFT',
                color: theme.cardBg,
                textColor: theme.text,
                borderColor: theme.border,
                onTap: () => _movePaddle(-0.11),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _paddleButton(
                icon: Icons.center_focus_strong_rounded,
                label: 'CENTER',
                color: theme.primary.withValues(alpha: 0.14),
                textColor: theme.primary,
                borderColor: theme.primary,
                onTap: () {
                  setState(() => _paddleX = 0.5);
                  HapticFeedback.lightImpact();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _paddleButton(
                icon: Icons.keyboard_double_arrow_right_rounded,
                label: 'GLIDE RIGHT',
                color: theme.cardBg,
                textColor: theme.text,
                borderColor: theme.border,
                onTap: () => _movePaddle(0.11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hudPill(String title, String val, Color color, StationeryTheme theme) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: theme.textSecondary,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _paddleButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.22),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrickBreakerPainter extends CustomPainter {
  final double paddleX;
  final double paddleW;
  final List<_Ball> balls;
  final List<_Brick> bricks;
  final List<_FallingPowerUp> powerUps;
  final List<_BrickParticle> particles;
  final bool hasShield;
  final Color accent;
  final bool isDark;

  _BrickBreakerPainter({
    required this.paddleX,
    required this.paddleW,
    required this.balls,
    required this.bricks,
    required this.powerUps,
    required this.particles,
    required this.hasShield,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Background grid
    final bgPaint = Paint()..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle grid lines
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (double x = 0; x < w; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);
    }
    for (double y = 0; y < h; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
    }

    // 2. Shield Floor (if active)
    if (hasShield) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF06B6D4)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(10, h * 0.97), Offset(w - 10, h * 0.97), shieldPaint);
      canvas.drawLine(
        Offset(10, h * 0.97),
        Offset(w - 10, h * 0.97),
        Paint()
          ..color = const Color(0xFF06B6D4).withValues(alpha: 0.35)
          ..strokeWidth = 12.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // 3. Bricks
    for (final b in bricks) {
      final rect = Rect.fromLTWH(b.x * w, b.y * h, b.w * w, b.h * h);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));

      // Fill
      canvas.drawRRect(rrect, Paint()..color = b.color);

      // 3D Top-edge reflection
      canvas.drawLine(
        Offset(rect.left + 3, rect.top + 2),
        Offset(rect.right - 3, rect.top + 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..strokeWidth = 1.6,
      );

      // Icon for Bomb / Powerup
      if (b.isBomb) {
        final center = rect.center;
        canvas.drawCircle(center, 5.5, Paint()..color = Colors.white);
      } else if (b.powerUp != null) {
        final center = rect.center;
        canvas.drawCircle(
          center,
          4.0,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // 4. Falling Powerups
    for (final p in powerUps) {
      final cx = p.x * w;
      final cy = p.y * h;
      final capsuleRect = Rect.fromCenter(center: Offset(cx, cy), width: 22, height: 13);
      final rrect = RRect.fromRectAndRadius(capsuleRect, const Radius.circular(99));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF59E0B));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // 5. Particles
    for (final pt in particles) {
      final pColor = pt.color.withValues(alpha: pt.life.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(pt.x * w, pt.y * h), 2.8, Paint()..color = pColor);
    }

    // 6. Paddle
    final pw = paddleW * w;
    final px = paddleX * w;
    final py = h * 0.86;
    final paddleRect = Rect.fromCenter(center: Offset(px, py), width: pw, height: 14);
    final paddleRRect = RRect.fromRectAndRadius(paddleRect, const Radius.circular(8));

    // Glow under paddle
    canvas.drawRRect(
      paddleRRect,
      Paint()
        ..color = accent.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Paddle body
    canvas.drawRRect(paddleRRect, Paint()..color = accent);
    // Bevel shine
    canvas.drawLine(
      Offset(paddleRect.left + 5, paddleRect.top + 2),
      Offset(paddleRect.right - 5, paddleRect.top + 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2.0,
    );

    // 7. Balls + Trails
    for (final b in balls) {
      final bx = b.x * w;
      final by = b.y * h;
      final br = b.radius * w;

      // Glow Trail
      for (int i = 0; i < b.trail.length; i++) {
        final t = b.trail[i];
        final frac = (i + 1) / b.trail.length;
        canvas.drawCircle(
          Offset(t.dx * w, t.dy * h),
          br * frac * 0.8,
          Paint()..color = accent.withValues(alpha: frac * 0.35),
        );
      }

      // Ball Outer Glow
      canvas.drawCircle(
        Offset(bx, by),
        br * 1.5,
        Paint()
          ..color = (isDark ? Colors.white : accent).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Solid Ball
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = isDark ? Colors.white : const Color(0xFF0F172A));
      // Specular highlight
      canvas.drawCircle(Offset(bx - br * 0.3, by - br * 0.3), br * 0.3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _BrickBreakerPainter old) => true;
}
