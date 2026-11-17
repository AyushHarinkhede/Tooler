import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

/// ---------------------------------------------------------------------------
/// CONNECT 4 (FOUR IN A ROW) — Classic 7x6 Strategy Drop Game
/// Drop discs, outsmart smart AI or challenge a friend in pass & play!
/// ---------------------------------------------------------------------------
class ConnectFourGame extends StatefulWidget {
  final StationeryTheme theme;
  const ConnectFourGame({super.key, required this.theme});

  @override
  State<ConnectFourGame> createState() => _ConnectFourGameState();
}

class _ConnectFourGameState extends State<ConnectFourGame> {
  static const int _rows = 6;
  static const int _cols = 7;

  // 0=Empty, 1=Red (Player 1), 2=Yellow (Player 2 / AI)
  late List<List<int>> _board;
  bool _isPlayer1Turn = true;
  bool _vsAi = true;
  bool _isAiThinking = false;
  int? _winner; // 1, 2, 0=Draw, null=In progress
  List<(int, int)>? _winningCoords;

  int _p1Score = 0;
  int _p2Score = 0;
  int _drawScore = 0;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  void _resetBoard() {
    setState(() {
      _board = List.generate(_rows, (_) => List.filled(_cols, 0));
      _isPlayer1Turn = true;
      _isAiThinking = false;
      _winner = null;
      _winningCoords = null;
    });
  }

  void _dropDisc(int col) {
    if (_winner != null || _isAiThinking) return;
    if (_board[0][col] != 0) return; // Column full

    // Find lowest available row in column
    int targetRow = -1;
    for (int r = _rows - 1; r >= 0; r--) {
      if (_board[r][col] == 0) {
        targetRow = r;
        break;
      }
    }
    if (targetRow == -1) return;

    final discPlayer = _isPlayer1Turn ? 1 : 2;
    _board[targetRow][col] = discPlayer;
    SoundService().playKey();
    HapticFeedback.lightImpact();

    // Check Win or Draw
    final winningLine = _checkWin(targetRow, col, discPlayer);
    if (winningLine != null) {
      _winner = discPlayer;
      _winningCoords = winningLine;
      if (discPlayer == 1) {
        _p1Score++;
      } else {
        _p2Score++;
      }
      SoundService().playSuccess();
      HapticFeedback.heavyImpact();
      setState(() {});
      return;
    }

    if (_isBoardFull()) {
      _winner = 0; // Draw
      _drawScore++;
      SoundService().playTap();
      setState(() {});
      return;
    }

    setState(() {
      _isPlayer1Turn = !_isPlayer1Turn;
    });

    if (_vsAi && !_isPlayer1Turn) {
      _triggerAiTurn();
    }
  }

  void _triggerAiTurn() {
    _isAiThinking = true;
    setState(() {});

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _winner != null) return;
      final bestCol = _findBestAiMove();
      _isAiThinking = false;
      _dropDisc(bestCol);
    });
  }

  int _findBestAiMove() {
    // 1. Can AI win in 1 move? Take it!
    for (int c = 0; c < _cols; c++) {
      final r = _getLowestRow(c);
      if (r != -1) {
        _board[r][c] = 2;
        final win = _checkWin(r, c, 2);
        _board[r][c] = 0;
        if (win != null) return c;
      }
    }

    // 2. Can Player win in next move? Block it!
    for (int c = 0; c < _cols; c++) {
      final r = _getLowestRow(c);
      if (r != -1) {
        _board[r][c] = 1;
        final win = _checkWin(r, c, 1);
        _board[r][c] = 0;
        if (win != null) return c;
      }
    }

    // 3. Prefer center columns (3, then 2/4, then 1/5, then 0/6)
    final colPriority = [3, 2, 4, 1, 5, 0, 6];
    for (final c in colPriority) {
      if (_getLowestRow(c) != -1) return c;
    }

    return 3;
  }

  int _getLowestRow(int col) {
    for (int r = _rows - 1; r >= 0; r--) {
      if (_board[r][col] == 0) return r;
    }
    return -1;
  }

  bool _isBoardFull() {
    for (int c = 0; c < _cols; c++) {
      if (_board[0][c] == 0) return false;
    }
    return true;
  }

  List<(int, int)>? _checkWin(int r, int c, int player) {
    const directions = [
      [(0, 1), (0, -1)], // Horizontal
      [(1, 0), (-1, 0)], // Vertical
      [(1, 1), (-1, -1)], // Diagonal /
      [(1, -1), (-1, 1)], // Diagonal \
    ];

    for (final dir in directions) {
      final line = <(int, int)>[(r, c)];
      for (final (dr, dc) in dir) {
        int step = 1;
        while (true) {
          final nr = r + (dr * step);
          final nc = c + (dc * step);
          if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols && _board[nr][nc] == player) {
            line.add((nr, nc));
            step++;
          } else {
            break;
          }
        }
      }
      if (line.length >= 4) {
        return line;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score & Turn HUD
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scorePill('PLAYER 1', '$_p1Score', const Color(0xFFEF4444), _isPlayer1Turn && _winner == null, theme),
              _scorePill('DRAWS', '$_drawScore', theme.textSecondary, false, theme),
              _scorePill(_vsAi ? 'SMART AI' : 'PLAYER 2', '$_p2Score', const Color(0xFFF59E0B), !_isPlayer1Turn && _winner == null, theme),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 7x6 Connect 4 Board
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A), // Classic Blue Cabinet
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF3B82F6), width: 2.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                offset: const Offset(0, 6),
                blurRadius: 14,
              ),
            ],
          ),
          child: Column(
            children: [
              // Column Touch Triggers & Drop Arrows
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_cols, (col) {
                  return GestureDetector(
                    onTap: () => _dropDisc(col),
                    child: Container(
                      width: 38,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),

              // 7x6 Grid Cells
              Table(
                children: List.generate(_rows, (r) {
                  return TableRow(
                    children: List.generate(_cols, (c) {
                      final val = _board[r][c];
                      final isWinningDisc = _winningCoords?.any((coord) => coord.$1 == r && coord.$2 == c) ?? false;

                      Color discColor;
                      if (val == 1) {
                        discColor = const Color(0xFFEF4444); // Red
                      } else if (val == 2) {
                        discColor = const Color(0xFFFACC15); // Yellow
                      } else {
                        discColor = const Color(0xFF0F172A); // Empty slot
                      }

                      return GestureDetector(
                        onTap: () => _dropDisc(c),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            margin: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: discColor,
                              border: Border.all(
                                color: isWinningDisc
                                    ? Colors.white
                                    : (val != 0 ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF1E293B)),
                                width: isWinningDisc ? 3.0 : 1.2,
                              ),
                              boxShadow: isWinningDisc
                                  ? [
                                      const BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Controls Deck: Mode Toggle (vs AI / 2 Player) + Restart
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
                    setState(() {
                      _vsAi = !_vsAi;
                      _resetBoard();
                    });
                  },
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.primary, width: 1.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _vsAi ? Icons.smart_toy_rounded : Icons.people_alt_rounded,
                          color: theme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _vsAi ? 'MODE: VS AI BOT' : 'MODE: 2 PLAYERS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: theme.text,
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
                    _resetBoard();
                  },
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
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

  Widget _scorePill(String label, String score, Color color, bool isTurn, StationeryTheme theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isTurn ? color.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTurn ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isTurn ? color : theme.textSecondary,
            ),
          ),
          Text(
            score,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
