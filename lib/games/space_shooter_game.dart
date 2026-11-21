import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// NEON SPACE SHOOTER — 60FPS Galaxy Arcade Blaster
/// Drag to pilot your starfighter, auto-fire plasma cannons, blast enemy waves,
/// and grab Triple-Shot & Shield power-ups!
/// ---------------------------------------------------------------------------
class SpaceShooterGame extends StatefulWidget {
  final StationeryTheme theme;
  const SpaceShooterGame({super.key, required this.theme});

  @override
  State<SpaceShooterGame> createState() => _SpaceShooterGameState();
}

class _Laser {
  double x, y;
  final double vx, vy;
  final bool fromEnemy;
  _Laser({required this.x, required this.y, this.vx = 0, required this.vy, this.fromEnemy = false});
}

enum _EnemyKind { scout, zigzag, cruiser }

class _EnemyShip {
  double x, y;
  double hp;
  final double maxHp;
  final _EnemyKind kind;
  final double phase;
  double shootCd;
  _EnemyShip({
    required this.x,
    required this.y,
    required this.hp,
    required this.kind,
    required this.phase,
    this.shootCd = 1.6,
  }) : maxHp = hp;
}

class _PowerUp {
  double x, y;
  final bool isShield; // false = triple laser, true = shield
  _PowerUp({required this.x, required this.y, required this.isShield});
}

class _BoomParticle {
  double x, y, vx, vy;
  double life = 1.0;
  final Color color;
  _BoomParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
  });
}

class _SpaceShooterGameState extends State<SpaceShooterGame>
    with SingleTickerProviderStateMixin {
  static const String _bestKey = 'tooler_game_shooter_best_v1';
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  bool _running = false;
  bool _gameOver = false;
  int _score = 0;
  int _bestScore = 0;
  int _lives = 3;
  int _wave = 1;

  double _shipX = 0.5;
  double _fireAccum = 0.0;
  double _spawnAccum = 0.0;
  double _tripleShotSec = 0.0;
  double _shieldSec = 0.0;
  double _invulnSec = 0.0;
  double _starScroll = 0.0;

  final List<_Laser> _lasers = [];
  final List<_EnemyShip> _enemies = [];
  final List<_PowerUp> _powerUps = [];
  final List<_BoomParticle> _particles = [];
  late final List<Offset> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(48, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));
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

  void _startGame() {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    _lasers.clear();
    _enemies.clear();
    _powerUps.clear();
    _particles.clear();
    setState(() {
      _running = true;
      _gameOver = false;
      _score = 0;
      _lives = 3;
      _wave = 1;
      _shipX = 0.5;
      _tripleShotSec = 0.0;
      _shieldSec = 2.0;
      _invulnSec = 0.0;
      _fireAccum = 0.0;
      _spawnAccum = 0.0;
    });
    _lastTick = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _steerShip(double delta) {
    if (!_running || _gameOver) return;
    setState(() {
      _shipX = (_shipX + delta).clamp(0.08, 0.92);
    });
    HapticFeedback.selectionClick();
  }

  void _fireManualBarrage() {
    if (!_running || _gameOver) return;
    SoundService().playTap();
    HapticFeedback.lightImpact();
    setState(() {
      _lasers.add(_Laser(x: _shipX, y: 0.82, vy: -1.35));
      _lasers.add(_Laser(x: _shipX - 0.04, y: 0.83, vx: -0.25, vy: -1.30));
      _lasers.add(_Laser(x: _shipX + 0.04, y: 0.83, vx: 0.25, vy: -1.30));
    });
  }

  void _spawnBurst(double x, double y, Color color, {int count = 12}) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final spd = 0.14 + _rng.nextDouble() * 0.35;
      _particles.add(
        _BoomParticle(
          x: x,
          y: y,
          vx: math.cos(a) * spd,
          vy: math.sin(a) * spd,
          color: color,
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    if (!_running || _gameOver) return;
    final dt = _lastTick == Duration.zero
        ? 0.016
        : ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.001, 0.05);
    _lastTick = elapsed;

    _starScroll = (_starScroll + dt * 0.28) % 1.0;
    _wave = 1 + (_score ~/ 260);

    if (_tripleShotSec > 0) _tripleShotSec = math.max(0.0, _tripleShotSec - dt);
    if (_shieldSec > 0) _shieldSec = math.max(0.0, _shieldSec - dt);
    if (_invulnSec > 0) _invulnSec = math.max(0.0, _invulnSec - dt);

    // Auto-fire plasma bolts
    _fireAccum += dt;
    final fireInterval = _tripleShotSec > 0 ? 0.16 : 0.20;
    if (_fireAccum >= fireInterval) {
      _fireAccum = 0.0;
      _lasers.add(_Laser(x: _shipX, y: 0.82, vy: -1.25));
      if (_tripleShotSec > 0) {
        _lasers.add(_Laser(x: _shipX - 0.03, y: 0.83, vx: -0.22, vy: -1.22));
        _lasers.add(_Laser(x: _shipX + 0.03, y: 0.83, vx: 0.22, vy: -1.22));
      }
    }

    // Spawn enemies scaled by wave
    _spawnAccum += dt;
    final spawnInterval = (1.05 - _wave * 0.07).clamp(0.38, 1.05);
    if (_spawnAccum >= spawnInterval) {
      _spawnAccum = 0.0;
      final r = _rng.nextDouble();
      final kind = r < 0.55
          ? _EnemyKind.scout
          : (r < 0.84 ? _EnemyKind.zigzag : _EnemyKind.cruiser);
      _enemies.add(
        _EnemyShip(
          x: 0.12 + _rng.nextDouble() * 0.76,
          y: -0.06,
          hp: kind == _EnemyKind.cruiser ? 3.0 + (_wave ~/ 3) : (kind == _EnemyKind.zigzag ? 2.0 : 1.0),
          kind: kind,
          phase: _rng.nextDouble() * math.pi * 2,
          shootCd: 1.3 + _rng.nextDouble() * 1.2,
        ),
      );
    }

    // Update lasers
    for (int i = _lasers.length - 1; i >= 0; i--) {
      final l = _lasers[i];
      l.x += l.vx * dt;
      l.y += l.vy * dt;
      if (l.y < -0.08 || l.y > 1.08 || l.x < -0.05 || l.x > 1.05) {
        _lasers.removeAt(i);
        continue;
      }

      if (l.fromEnemy) {
        if ((l.x - _shipX).abs() < 0.06 && (l.y - 0.86).abs() < 0.05) {
          _lasers.removeAt(i);
          _damagePlayer();
        }
      }
    }

    // Update enemies + bullet hits
    for (int i = _enemies.length - 1; i >= 0; i--) {
      final e = _enemies[i];
      final spd = e.kind == _EnemyKind.cruiser
          ? 0.18
          : (e.kind == _EnemyKind.zigzag ? 0.26 : 0.30 + _wave * 0.015);
      e.y += spd * dt;
      if (e.kind == _EnemyKind.zigzag) {
        e.x = (e.x + math.sin(e.y * 12 + e.phase) * 0.38 * dt).clamp(0.08, 0.92);
      }

      // Cruisers fire enemy plasma bolts!
      if (e.kind == _EnemyKind.cruiser && e.y > 0.08 && e.y < 0.65) {
        e.shootCd -= dt;
        if (e.shootCd <= 0) {
          e.shootCd = 1.65;
          _lasers.add(_Laser(x: e.x, y: e.y + 0.04, vy: 0.56, fromEnemy: true));
        }
      }

      // Check player laser hits
      bool destroyed = false;
      for (int j = _lasers.length - 1; j >= 0; j--) {
        final l = _lasers[j];
        if (l.fromEnemy) continue;
        final hitR = e.kind == _EnemyKind.cruiser ? 0.085 : 0.065;
        if ((l.x - e.x).abs() < hitR && (l.y - e.y).abs() < hitR) {
          _lasers.removeAt(j);
          e.hp -= 1.0;
          if (e.hp <= 0) {
            destroyed = true;
            final pts = e.kind == _EnemyKind.cruiser ? 50 : (e.kind == _EnemyKind.zigzag ? 25 : 15);
            _score += pts;
            _spawnBurst(
              e.x,
              e.y,
              e.kind == _EnemyKind.cruiser ? const Color(0xFFF59E0B) : const Color(0xFFF43F5E),
              count: e.kind == _EnemyKind.cruiser ? 18 : 10,
            );
            SoundService().playKey();
            // 16% chance to drop power-up
            if (_rng.nextDouble() < 0.16) {
              _powerUps.add(_PowerUp(x: e.x, y: e.y, isShield: _rng.nextBool()));
            }
            break;
          }
        }
      }

      if (destroyed) {
        _enemies.removeAt(i);
        continue;
      }

      // Check collision with player ship or passing bottom
      if ((e.x - _shipX).abs() < 0.075 && (e.y - 0.86).abs() < 0.065) {
        _spawnBurst(e.x, e.y, const Color(0xFFF43F5E), count: 14);
        _enemies.removeAt(i);
        _damagePlayer();
      } else if (e.y > 1.06) {
        _enemies.removeAt(i);
      }
    }

    // Update power-ups
    for (int i = _powerUps.length - 1; i >= 0; i--) {
      final p = _powerUps[i];
      p.y += 0.24 * dt;
      if ((p.x - _shipX).abs() < 0.08 && (p.y - 0.86).abs() < 0.07) {
        if (p.isShield) {
          _shieldSec = 6.5;
        } else {
          _tripleShotSec = 7.5;
        }
        SoundService().playSuccess();
        HapticFeedback.lightImpact();
        _powerUps.removeAt(i);
      } else if (p.y > 1.08) {
        _powerUps.removeAt(i);
      }
    }

    // Update explosion particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt * 2.4;
      if (p.life <= 0) _particles.removeAt(i);
    }

    if (mounted) setState(() {});
  }

  void _damagePlayer() {
    if (_shieldSec > 0 || _invulnSec > 0) return;
    _lives--;
    _invulnSec = 1.4;
    HapticFeedback.heavyImpact();
    _spawnBurst(_shipX, 0.86, const Color(0xFF06B6D4), count: 16);
    if (_lives <= 0) {
      _running = false;
      _gameOver = true;
      _ticker.stop();
      SoundService().playClick();
      _saveBest(_score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top HUD
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 17,
                      color: i < _lives ? const Color(0xFFF43F5E) : theme.textSecondary,
                    ),
                  ),
                ),
              ),
              Text(
                'WAVE $_wave',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: theme.primary,
                ),
              ),
              Text(
                'SCORE $_score',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: theme.text,
                ),
              ),
              Text(
                'BEST $_bestScore',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Space Arena Canvas (drag anywhere horizontally to glide ship!)
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
                    _shipX = (_shipX + d.delta.dx / arenaW).clamp(0.08, 0.92);
                  });
                },
                onTapDown: (d) {
                  if (!_running) return;
                  setState(() {
                    _shipX = (d.localPosition.dx / arenaW).clamp(0.08, 0.92);
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
                        painter: _SpaceArenaPainter(
                          shipX: _shipX,
                          starScroll: _starScroll,
                          stars: _stars,
                          lasers: _lasers,
                          enemies: _enemies,
                          powerUps: _powerUps,
                          particles: _particles,
                          hasShield: _shieldSec > 0,
                          hasTriple: _tripleShotSec > 0,
                          blink: _invulnSec > 0 && ((_invulnSec * 12).floor().isEven),
                          accent: theme.primary,
                        ),
                      ),

                      // Active Power-up Chips
                      if (_running && (_tripleShotSec > 0 || _shieldSec > 0))
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Row(
                            children: [
                              if (_tripleShotSec > 0)
                                _powerChip('TRIPLE ${_tripleShotSec.toStringAsFixed(0)}s', const Color(0xFFF59E0B)),
                              if (_shieldSec > 0) ...[
                                const SizedBox(width: 6),
                                _powerChip('SHIELD ${_shieldSec.toStringAsFixed(0)}s', const Color(0xFF06B6D4)),
                              ],
                            ],
                          ),
                        ),

                      // Start / Game Over Modal
                      if (!_running)
                        Container(
                          color: Colors.black.withValues(alpha: 0.62),
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
                                    Icons.rocket_launch_rounded,
                                    size: 38,
                                    color: _gameOver ? const Color(0xFFF43F5E) : theme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _gameOver ? 'MISSION FAILED' : 'SPACE SHOOTER',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: theme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _gameOver
                                        ? 'Reached Wave $_wave · Score: $_score · Best: $_bestScore'
                                        : 'Slide finger to steer your starfighter.\nAuto-lasers blast drones — grab Triple Shot & Shield!',
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
                                      _gameOver ? 'RELAUNCH' : 'LAUNCH MISSION',
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

        // Ergonomic Starfighter Tactical Flight Deck
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _flightButton(
                icon: Icons.keyboard_double_arrow_left_rounded,
                label: 'THRUST L',
                color: theme.cardBg,
                textColor: theme.text,
                borderColor: theme.border,
                onTap: () => _steerShip(-0.11),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _flightButton(
                icon: Icons.flash_on_rounded,
                label: 'MEGA BLASTER',
                color: theme.primary,
                textColor: Colors.white,
                borderColor: theme.primary,
                onTap: _fireManualBarrage,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _flightButton(
                icon: Icons.keyboard_double_arrow_right_rounded,
                label: 'THRUST R',
                color: theme.cardBg,
                textColor: theme.text,
                borderColor: theme.border,
                onTap: () => _steerShip(0.11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _flightButton({
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
                color: borderColor.withValues(alpha: 0.25),
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

  Widget _powerChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SpaceArenaPainter extends CustomPainter {
  final double shipX;
  final double starScroll;
  final List<Offset> stars;
  final List<_Laser> lasers;
  final List<_EnemyShip> enemies;
  final List<_PowerUp> powerUps;
  final List<_BoomParticle> particles;
  final bool hasShield;
  final bool hasTriple;
  final bool blink;
  final Color accent;

  _SpaceArenaPainter({
    required this.shipX,
    required this.starScroll,
    required this.stars,
    required this.lasers,
    required this.enemies,
    required this.powerUps,
    required this.particles,
    required this.hasShield,
    required this.hasTriple,
    required this.blink,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Deep Space Nebula Gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050814), Color(0xFF0F172A), Color(0xFF151230)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Parallax Starfield
    for (int i = 0; i < stars.length; i++) {
      final sx = stars[i].dx * w;
      final speedMul = (i % 3 == 0) ? 1.5 : 0.8;
      final sy = ((stars[i].dy + starScroll * speedMul) % 1.0) * h;
      canvas.drawCircle(
        Offset(sx, sy),
        i % 4 == 0 ? 1.8 : 1.0,
        Paint()..color = Colors.white.withValues(alpha: i % 4 == 0 ? 0.78 : 0.35),
      );
    }

    // 3. Power-ups
    for (final p in powerUps) {
      final c = Offset(p.x * w, p.y * h);
      final col = p.isShield ? const Color(0xFF06B6D4) : const Color(0xFFF59E0B);
      canvas.drawCircle(c, 13, Paint()..color = col.withValues(alpha: 0.25));
      canvas.drawCircle(c, 8.5, Paint()..color = col);
      canvas.drawCircle(c, 3.5, Paint()..color = Colors.white);
    }

    // 4. Lasers
    for (final l in lasers) {
      final c = Offset(l.x * w, l.y * h);
      final col = l.fromEnemy
          ? const Color(0xFFF43F5E)
          : (hasTriple ? const Color(0xFFFACC15) : const Color(0xFF38BDF8));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: l.fromEnemy ? 5 : 4, height: l.fromEnemy ? 12 : 16),
          const Radius.circular(3),
        ),
        Paint()..color = col,
      );
    }

    // 5. Enemies
    for (final e in enemies) {
      final cx = e.x * w;
      final cy = e.y * h;
      if (e.kind == _EnemyKind.cruiser) {
        final ship = Path()
          ..moveTo(cx, cy + 20)
          ..lineTo(cx - 22, cy - 10)
          ..lineTo(cx - 10, cy - 18)
          ..lineTo(cx + 10, cy - 18)
          ..lineTo(cx + 22, cy - 10)
          ..close();
        canvas.drawPath(ship, Paint()..color = const Color(0xFFF59E0B));
        // Mini HP bar
        canvas.drawRect(
          Rect.fromLTWH(cx - 16, cy - 25, 32 * (e.hp / e.maxHp).clamp(0.0, 1.0), 3.5),
          Paint()..color = const Color(0xFF10B981),
        );
      } else if (e.kind == _EnemyKind.zigzag) {
        final ship = Path()
          ..moveTo(cx, cy + 16)
          ..lineTo(cx - 16, cy - 10)
          ..lineTo(cx, cy - 4)
          ..lineTo(cx + 16, cy - 10)
          ..close();
        canvas.drawPath(ship, Paint()..color = const Color(0xFFA855F7));
      } else {
        final ship = Path()
          ..moveTo(cx, cy + 14)
          ..lineTo(cx - 13, cy - 10)
          ..lineTo(cx + 13, cy - 10)
          ..close();
        canvas.drawPath(ship, Paint()..color = const Color(0xFFF43F5E));
      }
      canvas.drawCircle(Offset(cx, cy - 2), 3.5, Paint()..color = Colors.white.withValues(alpha: 0.85));
    }

    // 6. Explosion Particles
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * w, p.y * h),
        3.2 * p.life.clamp(0.1, 1.0),
        Paint()..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
      );
    }

    // 7. Player Starfighter
    if (!blink) {
      final px = shipX * w;
      final py = h * 0.86;

      if (hasShield) {
        canvas.drawCircle(
          Offset(px, py),
          28,
          Paint()
            ..color = const Color(0xFF06B6D4).withValues(alpha: 0.20)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(px, py),
          28,
          Paint()
            ..color = const Color(0xFF06B6D4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      // Engine Thruster Flame
      final flame = Path()
        ..moveTo(px - 6, py + 14)
        ..lineTo(px, py + 26 + (starScroll * 20 % 7))
        ..lineTo(px + 6, py + 14)
        ..close();
      canvas.drawPath(flame, Paint()..color = const Color(0xFFF97316));

      // Sleek Delta Wing Starfighter
      final fighter = Path()
        ..moveTo(px, py - 22)
        ..lineTo(px + 20, py + 14)
        ..lineTo(px + 7, py + 9)
        ..lineTo(px, py + 15)
        ..lineTo(px - 7, py + 9)
        ..lineTo(px - 20, py + 14)
        ..close();
      canvas.drawPath(fighter, Paint()..color = accent);
      canvas.drawPath(
        fighter,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      // Glowing Cockpit
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py - 4), width: 7, height: 12),
        Paint()..color = const Color(0xFF38BDF8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpaceArenaPainter old) => true;
}
