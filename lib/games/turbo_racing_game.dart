import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// TURBO DRIFT RACING — 60FPS 3-Lane Highway Arcade Racer
/// Dodge traffic, collect gold coins & nitro boosts, drift smoothly across lanes!
/// ---------------------------------------------------------------------------
class TurboRacingGame extends StatefulWidget {
  final StationeryTheme theme;
  const TurboRacingGame({super.key, required this.theme});

  @override
  State<TurboRacingGame> createState() => _TurboRacingGameState();
}

enum _RoadItemKind { sedan, truck, racer, coin, nitro }

class _RoadEntity {
  double lane; // 0, 1, 2
  double y; // 0.0 (top) to 1.2 (bottom)
  final _RoadItemKind kind;
  final Color color;
  final double speedMul;

  _RoadEntity({
    required this.lane,
    required this.y,
    required this.kind,
    required this.color,
    this.speedMul = 1.0,
  });
}

class _TurboRacingGameState extends State<TurboRacingGame>
    with SingleTickerProviderStateMixin {
  static const String _bestKey = 'tooler_game_racing_best_v1';
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final math.Random _rng = math.Random();

  bool _running = false;
  bool _gameOver = false;
  int _score = 0;
  int _bestScore = 0;
  int _coins = 0;

  // Player car state
  int _targetLane = 1; // 0=Left, 1=Center, 2=Right
  double _carLanePos = 1.0; // Smoothly interpolated lane position
  double _carTilt = 0.0;
  double _roadScroll = 0.0;
  double _baseSpeed = 0.52; // Screen heights per second
  double _nitroMeter = 0.45; // 0.0 to 1.0
  double _nitroActiveSec = 0.0;
  double _spawnAccum = 0.0;
  double _scoreAccum = 0.0;

  final List<_RoadEntity> _entities = [];

  @override
  void initState() {
    super.initState();
    _loadBest();
    _ticker = createTicker(_onTick);
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

  void _startGame() {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    _entities.clear();
    setState(() {
      _running = true;
      _gameOver = false;
      _score = 0;
      _coins = 0;
      _targetLane = 1;
      _carLanePos = 1.0;
      _carTilt = 0.0;
      _baseSpeed = 0.54;
      _nitroMeter = 0.45;
      _nitroActiveSec = 0.0;
      _spawnAccum = 0.0;
      _scoreAccum = 0.0;
    });
    _lastTick = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _steer(int delta) {
    if (!_running || _gameOver) return;
    final next = (_targetLane + delta).clamp(0, 2);
    if (next != _targetLane) {
      SoundService().playTap();
      HapticFeedback.selectionClick();
      _targetLane = next;
    }
  }

  void _triggerNitro() {
    if (!_running || _gameOver || _nitroActiveSec > 0 || _nitroMeter < 0.35) return;
    SoundService().playSuccess();
    HapticFeedback.heavyImpact();
    _nitroActiveSec = 3.2 * _nitroMeter + 1.2;
    _nitroMeter = 0.0;
  }

  void _onTick(Duration elapsed) {
    if (!_running || _gameOver) return;
    final dt = _lastTick == Duration.zero
        ? 0.016
        : ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.001, 0.05);
    _lastTick = elapsed;

    final bool boosting = _nitroActiveSec > 0;
    if (boosting) {
      _nitroActiveSec = math.max(0.0, _nitroActiveSec - dt);
    }

    // Smoothly ramp speed over score
    _baseSpeed = (0.54 + (_score / 1800.0)).clamp(0.54, 1.18);
    final effectiveSpeed = _baseSpeed * (boosting ? 1.55 : 1.0);

    _roadScroll = (_roadScroll + effectiveSpeed * dt * 2.8) % 1.0;

    // Smooth drift interpolation toward target lane
    final diff = _targetLane - _carLanePos;
    _carLanePos += diff * math.min(1.0, dt * 15.0);
    _carTilt = (diff * 0.28).clamp(-0.24, 0.24);

    // Distance score
    _scoreAccum += dt * (boosting ? 34 : 18);
    if (_scoreAccum >= 1.0) {
      final add = _scoreAccum.floor();
      _score += add;
      _scoreAccum -= add;
    }

    // Spawn traffic & pickups
    _spawnAccum += dt * effectiveSpeed;
    final spawnGap = boosting ? 0.42 : 0.56;
    if (_spawnAccum >= spawnGap) {
      _spawnAccum = 0.0;
      _spawnWave();
    }

    // Update entities & check collisions
    const double playerY = 0.80;
    for (int i = _entities.length - 1; i >= 0; i--) {
      final e = _entities[i];
      e.y += effectiveSpeed * e.speedMul * dt;

      if (e.y > 1.22) {
        _entities.removeAt(i);
        continue;
      }

      final sameLane = (e.lane - _carLanePos).abs() < 0.52;
      final hitY = (e.y - playerY).abs() < (e.kind == _RoadItemKind.truck ? 0.135 : 0.105);

      if (sameLane && hitY) {
        if (e.kind == _RoadItemKind.coin) {
          _coins++;
          _score += 25;
          _nitroMeter = (_nitroMeter + 0.12).clamp(0.0, 1.0);
          SoundService().playKey();
          HapticFeedback.lightImpact();
          _entities.removeAt(i);
        } else if (e.kind == _RoadItemKind.nitro) {
          _nitroMeter = (_nitroMeter + 0.45).clamp(0.0, 1.0);
          _score += 40;
          SoundService().playSuccess();
          HapticFeedback.mediumImpact();
          _entities.removeAt(i);
        } else {
          if (boosting) {
            // Nitro shield blasts traffic away!
            _score += 50;
            HapticFeedback.mediumImpact();
            _entities.removeAt(i);
          } else {
            _handleCrash();
            break;
          }
        }
      }
    }

    if (mounted) setState(() {});
  }

  void _spawnWave() {
    // Always keep at least 1 lane completely open so every wave is fair & dodgeable
    final blockedLane = _rng.nextInt(3);
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    final kindRoll = _rng.nextDouble();
    final kind = kindRoll < 0.25
        ? _RoadItemKind.truck
        : (kindRoll < 0.55 ? _RoadItemKind.racer : _RoadItemKind.sedan);

    _entities.add(
      _RoadEntity(
        lane: blockedLane.toDouble(),
        y: -0.14,
        kind: kind,
        color: colors[_rng.nextInt(colors.length)],
        speedMul: kind == _RoadItemKind.racer ? 1.15 : (kind == _RoadItemKind.truck ? 0.85 : 0.98),
      ),
    );

    // 45% chance to place a second obstacle in another lane (still leaving 1 open lane)
    if (_rng.nextDouble() < 0.44) {
      final secondLane = (blockedLane + 1 + _rng.nextInt(2)) % 3;
      _entities.add(
        _RoadEntity(
          lane: secondLane.toDouble(),
          y: -0.22 - _rng.nextDouble() * 0.08,
          kind: _RoadItemKind.sedan,
          color: colors[_rng.nextInt(colors.length)],
          speedMul: 0.96,
        ),
      );
      // Place a coin or nitro in the safe 3rd lane!
      final safeLane = 3 - blockedLane - secondLane;
      if (_rng.nextDouble() < 0.65) {
        _entities.add(
          _RoadEntity(
            lane: safeLane.toDouble(),
            y: -0.16,
            kind: _rng.nextDouble() < 0.18 ? _RoadItemKind.nitro : _RoadItemKind.coin,
            color: const Color(0xFFFACC15),
            speedMul: 1.0,
          ),
        );
      }
    } else if (_rng.nextDouble() < 0.55) {
      final pickupLane = (blockedLane + 1 + _rng.nextInt(2)) % 3;
      _entities.add(
        _RoadEntity(
          lane: pickupLane.toDouble(),
          y: -0.15,
          kind: _rng.nextDouble() < 0.16 ? _RoadItemKind.nitro : _RoadItemKind.coin,
          color: const Color(0xFFFACC15),
          speedMul: 1.0,
        ),
      );
    }
  }

  void _handleCrash() {
    _running = false;
    _gameOver = true;
    _ticker.stop();
    HapticFeedback.heavyImpact();
    SoundService().playClick();
    _saveBest(_score);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final kmh = (_baseSpeed * 215 * (_nitroActiveSec > 0 ? 1.45 : 1.0)).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top HUD Strip
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
              _hudPill('SCORE', '$_score', theme.primary, theme),
              _hudPill('SPEED', '$kmh km/h', _nitroActiveSec > 0 ? const Color(0xFFF43F5E) : const Color(0xFF10B981), theme),
              _hudPill('COINS', '$_coins', const Color(0xFFF59E0B), theme),
              _hudPill('BEST', '$_bestScore', theme.text, theme),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Interactive Highway Arena
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final vx = details.primaryVelocity ?? 0;
              if (vx < -120) _steer(-1);
              if (vx > 120) _steer(1);
            },
            onTapDown: (details) {
              if (!_running) return;
              final box = context.findRenderObject() as RenderBox?;
              final w = box?.size.width ?? 320;
              if (details.localPosition.dx < w / 2) {
                _steer(-1);
              } else {
                _steer(1);
              }
            },
            child: Container(
              height: 410,
              decoration: BoxDecoration(
                border: Border.all(color: theme.border, width: 1.6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _HighwayRacePainter(
                      roadScroll: _roadScroll,
                      carLanePos: _carLanePos,
                      carTilt: _carTilt,
                      entities: _entities,
                      boosting: _nitroActiveSec > 0,
                      accent: theme.primary,
                      isDark: theme.isDark,
                    ),
                  ),

                  // Nitro Gauge Overlay (Top-Center inside road)
                  Positioned(
                    top: 10,
                    left: 60,
                    right: 60,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _nitroActiveSec > 0
                            ? (_nitroActiveSec / 4.2).clamp(0.0, 1.0)
                            : _nitroMeter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFFF43F5E)],
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Start / Game Over Overlay
                  if (!_running)
                    Container(
                      color: Colors.black.withValues(alpha: 0.58),
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
                                _gameOver ? Icons.flag_rounded : Icons.directions_car_filled_rounded,
                                size: 38,
                                color: _gameOver ? const Color(0xFFF43F5E) : theme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _gameOver ? 'RACE OVER!' : 'TURBO DRIFT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: theme.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _gameOver
                                    ? 'Score: $_score · Coins: $_coins · Best: $_bestScore'
                                    : 'Swipe or tap Left/Right to dodge traffic.\nCollect coins & unleash NITRO shield!',
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
                                  _gameOver ? 'RACE AGAIN' : 'START ENGINE',
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

        // Tactile Steering + Nitro Deck
        Row(
          children: [
            Expanded(
              child: _driveButton(
                icon: Icons.keyboard_arrow_left_rounded,
                label: 'LEFT',
                color: theme.cardBg,
                textColor: theme.text,
                borderColor: theme.border,
                onTap: () => _steer(-1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _driveButton(
                icon: Icons.bolt_rounded,
                label: _nitroActiveSec > 0 ? 'BOOSTING!' : 'NITRO',
                color: _nitroMeter >= 0.35 || _nitroActiveSec > 0
                    ? const Color(0xFFF43F5E)
                    : theme.cardBg,
                textColor: _nitroMeter >= 0.35 || _nitroActiveSec > 0
                    ? Colors.white
                    : theme.textSecondary,
                borderColor: _nitroMeter >= 0.35 ? const Color(0xFFF43F5E) : theme.border,
                onTap: _triggerNitro,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _driveButton(
                icon: Icons.keyboard_arrow_right_rounded,
                label: 'RIGHT',
                color: theme.cardBg,
                textColor: theme.text,
                borderColor: theme.border,
                onTap: () => _steer(1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hudPill(String title, String value, Color valColor, StationeryTheme theme) {
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
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: valColor,
          ),
        ),
      ],
    );
  }

  Widget _driveButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighwayRacePainter extends CustomPainter {
  final double roadScroll;
  final double carLanePos;
  final double carTilt;
  final List<_RoadEntity> entities;
  final bool boosting;
  final Color accent;
  final bool isDark;

  _HighwayRacePainter({
    required this.roadScroll,
    required this.carLanePos,
    required this.carTilt,
    required this.entities,
    required this.boosting,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Grass shoulders
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = isDark ? const Color(0xFF132A1C) : const Color(0xFF22A06B),
    );

    // 2. Asphalt Highway
    final roadLeft = w * 0.14;
    final roadW = w * 0.72;
    final laneW = roadW / 3.0;
    canvas.drawRect(
      Rect.fromLTWH(roadLeft, 0, roadW, h),
      Paint()..color = const Color(0xFF1E2430),
    );

    // 3. Red-White Racing Kerbs scrolling on both sides
    const kerbH = 26.0;
    final kerbOffset = (roadScroll * kerbH * 2) % (kerbH * 2);
    for (double y = -kerbH * 2 + kerbOffset; y < h + kerbH; y += kerbH) {
      final isRed = ((y - kerbOffset) / kerbH).round().isEven;
      final kp = Paint()..color = isRed ? const Color(0xFFF43F5E) : Colors.white;
      canvas.drawRect(Rect.fromLTWH(roadLeft - 7, y, 7, kerbH), kp);
      canvas.drawRect(Rect.fromLTWH(roadLeft + roadW, y, 7, kerbH), kp);
    }

    // 4. Scrolling Dashed Lane Dividers
    const dashStep = 56.0;
    final dashOff = (roadScroll * dashStep * 3) % dashStep;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int divider = 1; divider <= 2; divider++) {
      final dx = roadLeft + laneW * divider;
      for (double y = -dashStep + dashOff; y < h + dashStep; y += dashStep) {
        canvas.drawLine(Offset(dx, y), Offset(dx, y + 24), dashPaint);
      }
    }

    // 5. Entities (Traffic Cars, Trucks, Gold Coins, Nitro Bolts)
    for (final e in entities) {
      final cx = roadLeft + (e.lane + 0.5) * laneW;
      final cy = e.y * h;
      if (e.kind == _RoadItemKind.coin) {
        canvas.drawCircle(Offset(cx, cy), 13, Paint()..color = const Color(0xFFFACC15));
        canvas.drawCircle(
          Offset(cx, cy),
          9,
          Paint()
            ..color = const Color(0xFFCA8A04)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else if (e.kind == _RoadItemKind.nitro) {
        canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = const Color(0xFF06B6D4).withValues(alpha: 0.28));
        canvas.drawCircle(Offset(cx, cy), 10, Paint()..color = const Color(0xFF06B6D4));
        final bolt = Path()
          ..moveTo(cx + 1, cy - 6)
          ..lineTo(cx - 4, cy + 1)
          ..lineTo(cx, cy + 1)
          ..lineTo(cx - 1, cy + 6)
          ..lineTo(cx + 4, cy - 1)
          ..lineTo(cx, cy - 1)
          ..close();
        canvas.drawPath(bolt, Paint()..color = Colors.white);
      } else {
        final carH = e.kind == _RoadItemKind.truck ? 74.0 : 54.0;
        final carW = e.kind == _RoadItemKind.truck ? 38.0 : 34.0;
        _drawVehicle(canvas, Offset(cx, cy), carW, carH, e.color, isPlayer: false, isTruck: e.kind == _RoadItemKind.truck);
      }
    }

    // 6. Player Turbo Sports Car
    final playerX = roadLeft + (carLanePos + 0.5) * laneW;
    final playerY = h * 0.80;

    canvas.save();
    canvas.translate(playerX, playerY);
    canvas.rotate(carTilt);

    if (boosting) {
      // Nitro shield glow + exhaust flame
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 58, height: 84),
        Paint()
          ..color = const Color(0xFF06B6D4).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      final flame = Path()
        ..moveTo(-9, 28)
        ..lineTo(0, 52 + (roadScroll * 12 % 8))
        ..lineTo(9, 28)
        ..close();
      canvas.drawPath(flame, Paint()..color = const Color(0xFFF97316));
    }

    // Headlight beams
    final beam = Path()
      ..moveTo(-12, -26)
      ..lineTo(-24, -84)
      ..lineTo(24, -84)
      ..lineTo(12, -26)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.amber.withValues(alpha: 0.28), Colors.transparent],
        ).createShader(const Rect.fromLTWH(-24, -84, 48, 58)),
    );

    _drawVehicle(canvas, Offset.zero, 36, 58, accent, isPlayer: true, isTruck: false);
    canvas.restore();
  }

  void _drawVehicle(
    Canvas canvas,
    Offset c,
    double cw,
    double ch,
    Color bodyColor, {
    required bool isPlayer,
    required bool isTruck,
  }) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: cw, height: ch),
      Radius.circular(isTruck ? 7 : 11),
    );
    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF0B0E14);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx - cw / 2, c.dy - ch * 0.26), width: 6, height: 12), const Radius.circular(2)), wheelPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx + cw / 2, c.dy - ch * 0.26), width: 6, height: 12), const Radius.circular(2)), wheelPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx - cw / 2, c.dy + ch * 0.26), width: 6, height: 12), const Radius.circular(2)), wheelPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx + cw / 2, c.dy + ch * 0.26), width: 6, height: 12), const Radius.circular(2)), wheelPaint);

    // Body
    canvas.drawRRect(rect, Paint()..color = bodyColor);

    // Windshield / Cab
    final glassRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + (isPlayer ? -5 : (isTruck ? 18 : 6))),
        width: cw * 0.72,
        height: ch * (isTruck ? 0.22 : 0.34),
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(glassRect, Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.78));

    // Racing stripe for player car
    if (isPlayer) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(c.dx, c.dy - ch * 0.32), width: 5, height: ch * 0.26),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
      // Rear spoiler
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, c.dy + ch * 0.42), width: cw * 0.92, height: 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF0F172A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HighwayRacePainter old) => true;
}
