import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// 2048 NEON MERGE — Tactile Swipe + Undo Classic Number Puzzle
/// ---------------------------------------------------------------------------
class Merge2048Game extends StatefulWidget {
  final StationeryTheme theme;
  const Merge2048Game({super.key, required this.theme});

  @override
  State<Merge2048Game> createState() => _Merge2048GameState();
}

class _Merge2048GameState extends State<Merge2048Game> {
  static const String _bestKey = 'tooler_game_2048_best_v1';
  final math.Random _rng = math.Random();

  List<List<int>> _grid = List.generate(4, (_) => List.filled(4, 0));
  List<List<int>>? _prevGrid;
  int _prevScore = 0;
  int _score = 0;
  int _bestScore = 0;
  bool _gameOver = false;
  bool _won2048 = false;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _newGame();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _bestScore = p.getInt(_bestKey) ?? 0);
  }

  Future<void> _saveBest(int val) async {
    if (val <= _bestScore) return;
    _bestScore = val;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_bestKey, val);
  }

  void _newGame() {
    _grid = List.generate(4, (_) => List.filled(4, 0));
    _prevGrid = null;
    _score = 0;
    _gameOver = false;
    _won2048 = false;
    _spawnTile();
    _spawnTile();
    if (mounted) setState(() {});
  }

  void _undo() {
    if (_prevGrid == null) return;
    SoundService().playTap();
    setState(() {
      _grid = _prevGrid!.map((r) => List<int>.from(r)).toList();
      _score = _prevScore;
      _prevGrid = null;
      _gameOver = false;
    });
  }

  void _spawnTile() {
    final empty = <(int, int)>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_grid[r][c] == 0) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return;
    final (r, c) = empty[_rng.nextInt(empty.length)];
    _grid[r][c] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  void _move(int dir) {
    // 0=left, 1=right, 2=up, 3=down
    if (_gameOver) return;
    final backup = _grid.map((r) => List<int>.from(r)).toList();
    final backupScore = _score;
    bool changed = false;

    List<int> compressLine(List<int> line) {
      final nonZero = line.where((v) => v != 0).toList();
      final out = <int>[];
      int i = 0;
      while (i < nonZero.length) {
        if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
          final merged = nonZero[i] * 2;
          out.add(merged);
          _score += merged;
          if (merged == 2048) _won2048 = true;
          i += 2;
        } else {
          out.add(nonZero[i]);
          i++;
        }
      }
      while (out.length < 4) {
        out.add(0);
      }
      return out;
    }

    if (dir == 0 || dir == 1) {
      for (int r = 0; r < 4; r++) {
        var row = List<int>.from(_grid[r]);
        if (dir == 1) row = row.reversed.toList();
        var merged = compressLine(row);
        if (dir == 1) merged = merged.reversed.toList();
        for (int c = 0; c < 4; c++) {
          if (_grid[r][c] != merged[c]) changed = true;
          _grid[r][c] = merged[c];
        }
      }
    } else {
      for (int c = 0; c < 4; c++) {
        var col = [for (int r = 0; r < 4; r++) _grid[r][c]];
        if (dir == 3) col = col.reversed.toList();
        var merged = compressLine(col);
        if (dir == 3) merged = merged.reversed.toList();
        for (int r = 0; r < 4; r++) {
          if (_grid[r][c] != merged[r]) changed = true;
          _grid[r][c] = merged[r];
        }
      }
    }

    if (!changed) return;

    _prevGrid = backup;
    _prevScore = backupScore;
    _spawnTile();
    SoundService().playKey();
    HapticFeedback.selectionClick();
    _saveBest(_score);
    _gameOver = !_canMoveAny();
    setState(() {});
  }

  bool _canMoveAny() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final v = _grid[r][c];
        if (v == 0) return true;
        if (r + 1 < 4 && _grid[r + 1][c] == v) return true;
        if (c + 1 < 4 && _grid[r][c + 1] == v) return true;
      }
    }
    return false;
  }

  Color _tileColor(int v, StationeryTheme theme) {
    switch (v) {
      case 0:
        return theme.bg;
      case 2:
        return theme.isDark ? const Color(0xFF283044) : const Color(0xFFFEE2E2);
      case 4:
        return theme.isDark ? const Color(0xFF334155) : const Color(0xFFFEF3C7);
      case 8:
        return const Color(0xFFFB923C);
      case 16:
        return const Color(0xFFF97316);
      case 32:
        return const Color(0xFFF43F5E);
      case 64:
        return const Color(0xFFEC4899);
      case 128:
        return const Color(0xFFA855F7);
      case 256:
        return const Color(0xFF6366F1);
      case 512:
        return const Color(0xFF3B82F6);
      case 1024:
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HUD Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border, width: 1.4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'SCORE $_score  ·  BEST $_bestScore',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: theme.text,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.undo_rounded,
                  color: _prevGrid != null ? theme.primary : theme.textSecondary.withValues(alpha: 0.4),
                ),
                onPressed: _prevGrid != null ? _undo : null,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.refresh_rounded, color: theme.primary),
                onPressed: _newGame,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Swipeable 4x4 Board with Opaque Gesture Absorption
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (d) {
            final vx = d.primaryVelocity ?? 0;
            if (vx < -80) _move(0);
            if (vx > 80) _move(1);
          },
          onVerticalDragEnd: (d) {
            final vy = d.primaryVelocity ?? 0;
            if (vy < -80) _move(2);
            if (vy > 80) _move(3);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.border, width: 1.5),
            ),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 16,
                    itemBuilder: (_, idx) {
                      final val = _grid[idx ~/ 4][idx % 4];
                      final bg = _tileColor(val, theme);
                      final darkText = val <= 4 && !theme.isDark;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: val == 0 ? theme.border : bg,
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: val == 0
                              ? null
                              : Text(
                                  '$val',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: val >= 1024 ? 17 : (val >= 128 ? 20 : 24),
                                    fontWeight: FontWeight.w900,
                                    color: darkText ? const Color(0xFF1E293B) : Colors.white,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
                if (_gameOver)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _won2048 ? '2048 CHAMPION!' : 'NO MOVES LEFT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _newGame,
                              child: const Text('NEW GAME'),
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

        const SizedBox(height: 10),

        // Tactile D-Pad Buttons (for effortless 1-hand play without fighting scroll!)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dirBtn(Icons.arrow_back_rounded, () => _move(0), theme),
            const SizedBox(width: 8),
            _dirBtn(Icons.arrow_upward_rounded, () => _move(2), theme),
            const SizedBox(width: 8),
            _dirBtn(Icons.arrow_downward_rounded, () => _move(3), theme),
            const SizedBox(width: 8),
            _dirBtn(Icons.arrow_forward_rounded, () => _move(1), theme),
          ],
        ),
      ],
    );
  }

  Widget _dirBtn(IconData icon, VoidCallback onTap, StationeryTheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Ink(
          width: 64,
          height: 52,
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: theme.isDark ? 0.30 : 0.08),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: theme.primary, size: 26),
          ),
        ),
      ),
    );
  }
}
