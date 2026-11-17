import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// MINESWEEPER PRO — Classic Strategic Minefield Puzzle
/// Safe-first-tap guarantee, cascade auto-open, flag mode, timer & stats!
/// ---------------------------------------------------------------------------
class MinesweeperGame extends StatefulWidget {
  final StationeryTheme theme;
  const MinesweeperGame({super.key, required this.theme});

  @override
  State<MinesweeperGame> createState() => _MinesweeperGameState();
}

class _Cell {
  bool isMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  bool isDetonated = false;
  int neighborMines = 0;
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  static const String _bestKey = 'tooler_game_minesweeper_best_v1';
  static const int _rows = 9;
  static const int _cols = 9;
  static const int _totalMines = 10;

  final math.Random _rng = math.Random();
  late List<List<_Cell>> _grid;

  bool _isFirstTap = true;
  bool _isGameOver = false;
  bool _isGameWon = false;
  bool _flagMode = false; // Toggle between Dig ⛏️ and Flag 🚩
  int _elapsedSec = 0;
  int _bestTime = 999;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _newGame();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _bestTime = prefs.getInt(_bestKey) ?? 999);
  }

  Future<void> _saveBest(int val) async {
    if (val >= _bestTime) return;
    _bestTime = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestKey, val);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newGame() {
    _timer?.cancel();
    _timer = null;
    _elapsedSec = 0;
    _isFirstTap = true;
    _isGameOver = false;
    _isGameWon = false;

    _grid = List.generate(
      _rows,
      (_) => List.generate(_cols, (_) => _Cell()),
    );
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isGameOver && !_isGameWon && mounted) {
        setState(() => _elapsedSec++);
      }
    });
  }

  void _populateMines(int firstR, int firstC) {
    int placed = 0;
    while (placed < _totalMines) {
      final r = _rng.nextInt(_rows);
      final c = _rng.nextInt(_cols);
      // Safe first tap zone (first tile + its 8 neighbors are always clear)
      final inSafeZone = (r - firstR).abs() <= 1 && (c - firstC).abs() <= 1;
      if (!inSafeZone && !_grid[r][c].isMine) {
        _grid[r][c].isMine = true;
        placed++;
      }
    }

    // Calculate neighbor counts
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_grid[r][c].isMine) continue;
        int count = 0;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols && _grid[nr][nc].isMine) {
              count++;
            }
          }
        }
        _grid[r][c].neighborMines = count;
      }
    }
  }

  void _revealCell(int r, int c) {
    if (_isGameOver || _isGameWon) return;
    final cell = _grid[r][c];
    if (cell.isRevealed || cell.isFlagged) return;

    if (_isFirstTap) {
      _isFirstTap = false;
      _populateMines(r, c);
      _startTimer();
    }

    if (cell.isMine) {
      // Detonate
      cell.isDetonated = true;
      _isGameOver = true;
      _timer?.cancel();
      SoundService().playTap();
      HapticFeedback.heavyImpact();

      // Reveal all mines
      for (int i = 0; i < _rows; i++) {
        for (int j = 0; j < _cols; j++) {
          if (_grid[i][j].isMine) {
            _grid[i][j].isRevealed = true;
          }
        }
      }
      setState(() {});
      return;
    }

    // Safe reveal
    SoundService().playKey();
    HapticFeedback.selectionClick();
    _cascadeReveal(r, c);

    _checkWinCondition();
    setState(() {});
  }

  void _cascadeReveal(int startR, int startC) {
    final queue = <(int, int)>[(startR, startC)];

    while (queue.isNotEmpty) {
      final (r, c) = queue.removeLast();
      if (r < 0 || r >= _rows || c < 0 || c >= _cols) continue;
      final cell = _grid[r][c];
      if (cell.isRevealed || cell.isFlagged || cell.isMine) continue;

      cell.isRevealed = true;

      // If zero neighbors, cascade outward to all 8 surrounding cells
      if (cell.neighborMines == 0) {
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr != 0 || dc != 0) {
              queue.add((r + dr, c + dc));
            }
          }
        }
      }
    }
  }

  void _toggleFlag(int r, int c) {
    if (_isGameOver || _isGameWon) return;
    final cell = _grid[r][c];
    if (cell.isRevealed) return;

    SoundService().playTap();
    HapticFeedback.lightImpact();

    setState(() {
      cell.isFlagged = !cell.isFlagged;
    });

    _checkWinCondition();
  }

  void _checkWinCondition() {
    int unrevealedSafe = 0;
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final cell = _grid[r][c];
        if (!cell.isMine && !cell.isRevealed) {
          unrevealedSafe++;
        }
      }
    }

    if (unrevealedSafe == 0) {
      _isGameWon = true;
      _timer?.cancel();
      SoundService().playSuccess();
      HapticFeedback.heavyImpact();
      _saveBest(_elapsedSec);

      // Auto flag all mines
      for (int r = 0; r < _rows; r++) {
        for (int c = 0; c < _cols; c++) {
          if (_grid[r][c].isMine) _grid[r][c].isFlagged = true;
        }
      }
    }
  }

  int get _flaggedCount {
    int count = 0;
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_grid[r][c].isFlagged) count++;
      }
    }
    return count;
  }

  Color _numberColor(int n) {
    switch (n) {
      case 1:
        return const Color(0xFF3B82F6); // Blue
      case 2:
        return const Color(0xFF10B981); // Green
      case 3:
        return const Color(0xFFEF4444); // Red
      case 4:
        return const Color(0xFF8B5CF6); // Purple
      case 5:
        return const Color(0xFFF59E0B); // Amber
      case 6:
        return const Color(0xFF06B6D4); // Cyan
      case 7:
        return const Color(0xFFEC4899); // Pink
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final remainingMines = (_totalMines - _flaggedCount).clamp(0, _totalMines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top HUD Bar: Mines Remaining | Face Restart Button | Timer
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
              // Mine counter
              Row(
                children: [
                  const Icon(Icons.brightness_low_rounded, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    remainingMines.toString().padLeft(2, '0'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),

              // Restart Face Button
              GestureDetector(
                onTap: () {
                  SoundService().playClick();
                  HapticFeedback.lightImpact();
                  _newGame();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.border, width: 1.4),
                  ),
                  child: Text(
                    _isGameWon
                        ? '😎'
                        : (_isGameOver ? '😵' : (_isFirstTap ? '🙂' : '🧐')),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),

              // Digital Timer & Best
              Row(
                children: [
                  const Icon(Icons.timer_rounded, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${(_elapsedSec ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSec % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: theme.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Minesweeper Grid Board
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.border, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: theme.isDark ? 0.35 : 0.06),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: _rows * _cols,
              itemBuilder: (context, idx) {
                final r = idx ~/ _cols;
                final c = idx % _cols;
                final cell = _grid[r][c];

                Widget? content;
                Color cellBg;

                if (cell.isRevealed) {
                  if (cell.isMine) {
                    cellBg = cell.isDetonated ? const Color(0xFFEF4444) : const Color(0xFF475569);
                    content = const Icon(Icons.brightness_low_rounded, size: 20, color: Colors.white);
                  } else if (cell.neighborMines > 0) {
                    cellBg = theme.bg;
                    content = Text(
                      '${cell.neighborMines}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _numberColor(cell.neighborMines),
                      ),
                    );
                  } else {
                    cellBg = theme.bg.withValues(alpha: 0.6);
                  }
                } else {
                  cellBg = theme.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                  if (cell.isFlagged) {
                    content = const Icon(Icons.flag_rounded, size: 18, color: Color(0xFFEF4444));
                  }
                }

                return GestureDetector(
                  onTap: () {
                    if (_flagMode) {
                      _toggleFlag(r, c);
                    } else {
                      _revealCell(r, c);
                    }
                  },
                  onLongPress: () => _toggleFlag(r, c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      color: cellBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: cell.isRevealed ? theme.border.withValues(alpha: 0.35) : theme.border,
                        width: 1.0,
                      ),
                      boxShadow: !cell.isRevealed
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: theme.isDark ? 0.25 : 0.08),
                                offset: const Offset(1, 1),
                                blurRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(child: content),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Mode Action Deck: Dig / Flag Toggle & Quick Reset
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    SoundService().playTap();
                    HapticFeedback.lightImpact();
                    setState(() => _flagMode = !_flagMode);
                  },
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      color: _flagMode
                          ? const Color(0xFFEF4444)
                          : theme.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _flagMode ? const Color(0xFFEF4444) : theme.primary,
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_flagMode ? const Color(0xFFEF4444) : theme.primary).withValues(alpha: 0.30),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _flagMode ? Icons.flag_rounded : Icons.search_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _flagMode ? 'FLAG MODE (ACTIVE)' : 'DIG MODE (ACTIVE)',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    SoundService().playClick();
                    HapticFeedback.lightImpact();
                    _newGame();
                  },
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border, width: 1.8),
                    ),
                    child: Center(
                      child: Icon(Icons.refresh_rounded, color: theme.text, size: 24),
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
