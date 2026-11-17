import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// BRAIN BLITZ LAB — 3-in-1 Cognitive & IQ Brain Games Suite
/// 1) Memory Matrix  — Recall glowing spatial tile patterns (3x3 -> 5x5)
/// 2) Color Stroop   — Tap the INK color, ignore the distracting word (30s)
/// 3) Speed Math IQ  — Rapid-fire mental math (+, -, x, ÷) sprint (45s)
/// ---------------------------------------------------------------------------
class BrainGamesWidget extends StatefulWidget {
  final StationeryTheme theme;
  const BrainGamesWidget({super.key, required this.theme});

  @override
  State<BrainGamesWidget> createState() => _BrainGamesWidgetState();
}

class _BrainGamesWidgetState extends State<BrainGamesWidget> {
  final math.Random _rng = math.Random();
  int _mode = 0; // 0=Memory Matrix, 1=Color Stroop, 2=Speed Math

  // Persistent High Scores
  int _bestMemory = 0;
  int _bestStroop = 0;
  int _bestMath = 0;

  // --- MODE 0: MEMORY MATRIX ---
  int _memLevel = 1;
  int _memScore = 0;
  int _memGridSize = 3;
  Set<int> _memTargets = {};
  Set<int> _memSelected = {};
  int? _memWrongTile;
  bool _memShowingPattern = false;
  bool _memActive = false;
  bool _memGameOver = false;
  Timer? _memRevealTimer;

  // --- MODE 1: STROOP COLOR TRAP ---
  static const List<({String name, Color color})> _stroopPalette = [
    (name: 'RED', color: Color(0xFFEF4444)),
    (name: 'BLUE', color: Color(0xFF3B82F6)),
    (name: 'GREEN', color: Color(0xFF10B981)),
    (name: 'YELLOW', color: Color(0xFFF59E0B)),
  ];
  bool _stroopActive = false;
  bool _stroopDone = false;
  int _stroopScore = 0;
  int _stroopStreak = 0;
  int _stroopTimeLeft = 30;
  int _stroopWordIdx = 0;
  int _stroopInkIdx = 1;
  Timer? _stroopTimer;

  // --- MODE 2: SPEED MATH IQ ---
  bool _mathActive = false;
  bool _mathDone = false;
  int _mathScore = 0;
  int _mathStreak = 0;
  int _mathTimeLeft = 45;
  String _mathPrompt = '7 + 5 = ?';
  int _mathAnswer = 12;
  List<int> _mathChoices = [10, 12, 14, 11];
  Timer? _mathTimer;

  @override
  void initState() {
    super.initState();
    _loadBests();
  }

  @override
  void dispose() {
    _memRevealTimer?.cancel();
    _stroopTimer?.cancel();
    _mathTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBests() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bestMemory = p.getInt('tooler_brain_mem_best') ?? 0;
      _bestStroop = p.getInt('tooler_brain_stroop_best') ?? 0;
      _bestMath = p.getInt('tooler_brain_math_best') ?? 0;
    });
  }

  Future<void> _saveBest(String key, int val) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(key, val);
  }

  // =========================================================================
  // MODE 0: MEMORY MATRIX LOGIC
  // =========================================================================
  void _startMemoryGame() {
    SoundService().playClick();
    _memLevel = 1;
    _memScore = 0;
    _memGameOver = false;
    _memActive = true;
    _setupMemoryLevel();
  }

  void _setupMemoryLevel() {
    _memRevealTimer?.cancel();
    final grid = _memLevel <= 2 ? 3 : (_memLevel <= 6 ? 4 : 5);
    final total = grid * grid;
    final targetCount = (2 + _memLevel).clamp(3, (total * 0.55).floor());

    final pool = List.generate(total, (i) => i)..shuffle(_rng);
    setState(() {
      _memGridSize = grid;
      _memTargets = pool.take(targetCount).toSet();
      _memSelected = {};
      _memWrongTile = null;
      _memShowingPattern = true;
    });

    final revealMs = (1200 + targetCount * 110).clamp(1100, 2300);
    _memRevealTimer = Timer(Duration(milliseconds: revealMs), () {
      if (mounted) {
        setState(() => _memShowingPattern = false);
      }
    });
  }

  void _tapMemoryTile(int idx) {
    if (!_memActive || _memShowingPattern || _memGameOver) return;
    if (_memSelected.contains(idx)) return;

    if (_memTargets.contains(idx)) {
      SoundService().playKey();
      HapticFeedback.selectionClick();
      setState(() {
        _memSelected.add(idx);
        _memScore += 10 * _memLevel;
      });
      if (_memSelected.length == _memTargets.length) {
        SoundService().playSuccess();
        if (_memScore > _bestMemory) {
          _bestMemory = _memScore;
          _saveBest('tooler_brain_mem_best', _bestMemory);
        }
        _memLevel++;
        Timer(const Duration(milliseconds: 520), () {
          if (mounted && _memActive) _setupMemoryLevel();
        });
      }
    } else {
      SoundService().playClick();
      HapticFeedback.heavyImpact();
      if (_memScore > _bestMemory) {
        _bestMemory = _memScore;
        _saveBest('tooler_brain_mem_best', _bestMemory);
      }
      setState(() {
        _memWrongTile = idx;
        _memGameOver = true;
        _memActive = false;
      });
    }
  }

  // =========================================================================
  // MODE 1: COLOR STROOP TRAP LOGIC
  // =========================================================================
  void _startStroop() {
    SoundService().playClick();
    _stroopTimer?.cancel();
    setState(() {
      _stroopActive = true;
      _stroopDone = false;
      _stroopScore = 0;
      _stroopStreak = 0;
      _stroopTimeLeft = 30;
    });
    _nextStroopPrompt();
    _stroopTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _stroopTimeLeft--;
        if (_stroopTimeLeft <= 0) {
          t.cancel();
          _stroopActive = false;
          _stroopDone = true;
          if (_stroopScore > _bestStroop) {
            _bestStroop = _stroopScore;
            _saveBest('tooler_brain_stroop_best', _bestStroop);
          }
          SoundService().playSuccess();
        }
      });
    });
  }

  void _nextStroopPrompt() {
    final wIdx = _rng.nextInt(_stroopPalette.length);
    int inkIdx = _rng.nextInt(_stroopPalette.length);
    // 78% mismatch to truly challenge the brain's Stroop reflex!
    if (_rng.nextDouble() < 0.78 && inkIdx == wIdx) {
      inkIdx = (inkIdx + 1 + _rng.nextInt(_stroopPalette.length - 1)) % _stroopPalette.length;
    }
    setState(() {
      _stroopWordIdx = wIdx;
      _stroopInkIdx = inkIdx;
    });
  }

  void _answerStroop(int chosenIdx) {
    if (!_stroopActive) return;
    if (chosenIdx == _stroopInkIdx) {
      _stroopStreak++;
      _stroopScore += 10 + (_stroopStreak >= 5 ? 5 : 0);
      SoundService().playKey();
      HapticFeedback.selectionClick();
    } else {
      _stroopStreak = 0;
      _stroopScore = math.max(0, _stroopScore - 5);
      HapticFeedback.heavyImpact();
    }
    _nextStroopPrompt();
  }

  // =========================================================================
  // MODE 2: SPEED MATH IQ LOGIC
  // =========================================================================
  void _startMath() {
    SoundService().playClick();
    _mathTimer?.cancel();
    setState(() {
      _mathActive = true;
      _mathDone = false;
      _mathScore = 0;
      _mathStreak = 0;
      _mathTimeLeft = 45;
    });
    _nextMathQuestion();
    _mathTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _mathTimeLeft--;
        if (_mathTimeLeft <= 0) {
          t.cancel();
          _mathActive = false;
          _mathDone = true;
          if (_mathScore > _bestMath) {
            _bestMath = _mathScore;
            _saveBest('tooler_brain_math_best', _bestMath);
          }
          SoundService().playSuccess();
        }
      });
    });
  }

  void _nextMathQuestion() {
    final tier = 1 + (_mathScore ~/ 80);
    final op = _rng.nextInt(4);
    int a, b, ans;
    String sym;

    if (op == 0) {
      a = 4 + _rng.nextInt(14 * tier);
      b = 3 + _rng.nextInt(12 * tier);
      ans = a + b;
      sym = '+';
    } else if (op == 1) {
      b = 3 + _rng.nextInt(12 * tier);
      ans = 2 + _rng.nextInt(16 * tier);
      a = ans + b;
      sym = '−';
    } else if (op == 2) {
      a = 2 + _rng.nextInt(7 + tier * 2);
      b = 2 + _rng.nextInt(8 + tier);
      ans = a * b;
      sym = '×';
    } else {
      b = 2 + _rng.nextInt(8 + tier);
      ans = 2 + _rng.nextInt(9 + tier);
      a = ans * b;
      sym = '÷';
    }

    final opts = <int>{ans};
    while (opts.length < 4) {
      final delta = (_rng.nextInt(9) - 4);
      final candidate = ans + (delta == 0 ? 5 : delta);
      if (candidate > 0) opts.add(candidate);
    }
    final shuffled = opts.toList()..shuffle(_rng);

    setState(() {
      _mathPrompt = '$a $sym $b = ?';
      _mathAnswer = ans;
      _mathChoices = shuffled;
    });
  }

  void _answerMath(int val) {
    if (!_mathActive) return;
    if (val == _mathAnswer) {
      _mathStreak++;
      _mathScore += 15 + (_mathStreak >= 4 ? 5 : 0);
      SoundService().playKey();
      HapticFeedback.selectionClick();
    } else {
      _mathStreak = 0;
      _mathScore = math.max(0, _mathScore - 5);
      HapticFeedback.heavyImpact();
    }
    _nextMathQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3-Mode Brain Selector Strip
        Row(
          children: [
            _modeChip(0, 'Memory Grid', Icons.grid_view_rounded, theme),
            const SizedBox(width: 7),
            _modeChip(1, 'Color Trap', Icons.palette_rounded, theme),
            const SizedBox(width: 7),
            _modeChip(2, 'Speed Math', Icons.calculate_rounded, theme),
          ],
        ),
        const SizedBox(height: 12),

        if (_mode == 0) _buildMemoryMatrixCard(theme),
        if (_mode == 1) _buildStroopCard(theme),
        if (_mode == 2) _buildMathCard(theme),
      ],
    );
  }

  Widget _modeChip(int idx, String label, IconData icon, StationeryTheme theme) {
    final sel = _mode == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          SoundService().playTap();
          setState(() => _mode = idx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: sel ? theme.primary : theme.cardBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: sel ? theme.primary : theme.border, width: 1.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: sel ? Colors.white : theme.primary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: sel ? Colors.white : theme.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI: MEMORY MATRIX ---
  Widget _buildMemoryMatrixCard(StationeryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border, width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LEVEL $_memLevel',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: theme.primary,
                ),
              ),
              Text(
                'SCORE $_memScore · BEST $_bestMemory',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !_memActive && !_memGameOver
                ? 'Memorize the glowing pattern, then tap every tile!'
                : (_memShowingPattern
                    ? 'WATCH CAREFULLY...'
                    : (_memGameOver ? 'OOPS! WRONG TILE' : 'TAP THE TILES FROM MEMORY')),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _memGameOver ? const Color(0xFFF43F5E) : theme.text,
            ),
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _memGridSize,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _memGridSize * _memGridSize,
              itemBuilder: (_, idx) {
                final isTarget = _memTargets.contains(idx);
                final isSelected = _memSelected.contains(idx);
                final isWrong = _memWrongTile == idx;
                final lit = (_memShowingPattern && isTarget) ||
                    isSelected ||
                    (_memGameOver && isTarget);

                Color tileCol = theme.bg;
                if (isWrong) {
                  tileCol = const Color(0xFFF43F5E);
                } else if (lit) {
                  tileCol = theme.primary;
                }

                return GestureDetector(
                  onTap: () => _tapMemoryTile(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: tileCol,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: lit || isWrong ? tileCol : theme.border,
                        width: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (!_memActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _startMemoryGame,
                icon: const Icon(Icons.psychology_rounded),
                label: Text(
                  _memGameOver ? 'TRY AGAIN' : 'START MEMORY TEST',
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- UI: COLOR STROOP TRAP ---
  Widget _buildStroopCard(StationeryTheme theme) {
    final wordText = _stroopPalette[_stroopWordIdx].name;
    final inkColor = _stroopPalette[_stroopInkIdx].color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border, width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIME ${_stroopTimeLeft}s',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: _stroopTimeLeft <= 7 ? const Color(0xFFF43F5E) : theme.primary,
                ),
              ),
              Text(
                'SCORE $_stroopScore · BEST $_bestStroop',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the INK COLOR — ignore what the word says!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 128,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.border),
            ),
            child: Center(
              child: _stroopActive
                  ? Text(
                      wordText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: inkColor,
                        letterSpacing: 2.0,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _stroopDone ? 'TIME UP! SCORE: $_stroopScore' : 'STROOP FOCUS TEST',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _startStroop,
                          child: Text(_stroopDone ? 'PLAY AGAIN' : 'START 30s CHALLENGE'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.35,
            children: List.generate(_stroopPalette.length, (i) {
              final item = _stroopPalette[i];
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _stroopActive ? () => _answerStroop(i) : null,
                child: Text(
                  item.name,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- UI: SPEED MATH IQ ---
  Widget _buildMathCard(StationeryTheme theme) {
    final iqRank = _mathScore >= 240
        ? 'GENIUS TIER'
        : (_mathScore >= 140 ? 'SHARP MIND' : 'QUICK THINKER');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border, width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIME ${_mathTimeLeft}s',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: _mathTimeLeft <= 8 ? const Color(0xFFF43F5E) : theme.primary,
                ),
              ),
              Text(
                'STREAK x$_mathStreak',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                ),
              ),
              Text(
                'BEST $_bestMath',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 128,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.border),
            ),
            child: Center(
              child: _mathActive
                  ? Text(
                      _mathPrompt,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: theme.text,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _mathDone ? '$iqRank · SCORE $_mathScore' : '45s SPEED MATH SPRINT',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _startMath,
                          child: Text(_mathDone ? 'SPRINT AGAIN' : 'START MATH IQ'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.35,
            children: _mathChoices.map((opt) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.bg,
                  foregroundColor: theme.text,
                  side: BorderSide(color: theme.primary.withValues(alpha: 0.45), width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _mathActive ? () => _answerMath(opt) : null,
                child: Text(
                  '$opt',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
