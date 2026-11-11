import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/stationery_3d_models.dart';

enum GameType { tictactoe, snake, dice }

class GamesScreen extends StatefulWidget {
  final StationeryTheme theme;
  const GamesScreen({super.key, required this.theme});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  GameType _activeGame = GameType.tictactoe;

  // =========================================================================
  // TIC-TAC-TOE STATE (WITH UNBEATABLE MINIMAX AI)
  // =========================================================================
  List<String> _tttBoard = List.filled(9, '');
  bool _isPlayerXTurn = true;
  bool _vsComputer = true;
  String _aiDifficulty = 'unbeatable'; // 'easy', 'medium', 'unbeatable'
  String _tttWinner = ''; // 'X', 'O', 'Draw', ''
  List<int>? _tttWinningCombo;
  int _xScore = 0;
  int _oScore = 0;
  int _drawScore = 0;

  // =========================================================================
  // SNAKE PRO STATE
  // =========================================================================
  static const int _gridRows = 16;
  static const int _gridCols = 16;
  List<math.Point<int>> _snake = [
    const math.Point(7, 7),
    const math.Point(7, 8),
    const math.Point(7, 9),
  ];
  math.Point<int> _food = const math.Point(12, 12);
  math.Point<int>? _bonusFood;
  int _bonusFoodTimer = 0;
  math.Point<int> _direction = const math.Point(0, -1); // Up
  math.Point<int>? _nextDirection; // Buffered input for anti-suicide
  Timer? _snakeTimer;
  bool _isSnakeRunning = false;
  int _snakeSpeedMs = 170; // 240 (Slow), 170 (Normal), 110 (Fast)
  int _snakeScore = 0;
  int _snakeHighScore = 0;

  // =========================================================================
  // 3D DICE STATE
  // =========================================================================
  int _diceValue = 1;
  bool _isRolling = false;
  final List<int> _diceHistory = [];

  @override
  void dispose() {
    _snakeTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // TIC-TAC-TOE METHODS (MINIMAX ENGINE)
  // =========================================================================
  void _resetTtt() {
    SoundService().playClick();
    setState(() {
      _tttBoard = List.filled(9, '');
      _isPlayerXTurn = true;
      _tttWinner = '';
      _tttWinningCombo = null;
    });
  }

  void _resetTttScores() {
    SoundService().playClick();
    setState(() {
      _xScore = 0;
      _oScore = 0;
      _drawScore = 0;
      _resetTtt();
    });
  }

  void _onTttCellTapped(int index) {
    if (_tttBoard[index].isNotEmpty || _tttWinner.isNotEmpty) return;
    if (_vsComputer && !_isPlayerXTurn) return; // Prevent clicking during AI turn

    SoundService().playKey();
    setState(() {
      _tttBoard[index] = _isPlayerXTurn ? 'X' : 'O';
      _checkTttWinner();

      if (_tttWinner.isEmpty) {
        _isPlayerXTurn = !_isPlayerXTurn;
        if (_vsComputer && !_isPlayerXTurn) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _makeComputerMove();
          });
        }
      }
    });
  }

  void _makeComputerMove() {
    if (_tttWinner.isNotEmpty) return;

    final emptyIndices = <int>[];
    for (int i = 0; i < 9; i++) {
      if (_tttBoard[i].isEmpty) emptyIndices.add(i);
    }
    if (emptyIndices.isEmpty) return;

    int chosenMove = emptyIndices.first;

    if (_aiDifficulty == 'easy') {
      // Pure random
      chosenMove = emptyIndices[math.Random().nextInt(emptyIndices.length)];
    } else if (_aiDifficulty == 'medium') {
      // 50% minimax, 50% random
      if (math.Random().nextBool()) {
        chosenMove = _getBestMinimaxMove();
      } else {
        chosenMove = emptyIndices[math.Random().nextInt(emptyIndices.length)];
      }
    } else {
      // Unbeatable Minimax
      chosenMove = _getBestMinimaxMove();
    }

    SoundService().playKey();
    setState(() {
      _tttBoard[chosenMove] = 'O';
      _checkTttWinner();
      if (_tttWinner.isEmpty) {
        _isPlayerXTurn = true;
      }
    });
  }

  int _getBestMinimaxMove() {
    int bestScore = -10000;
    int bestMove = -1;

    for (int i = 0; i < 9; i++) {
      if (_tttBoard[i].isEmpty) {
        _tttBoard[i] = 'O';
        int score = _minimax(_tttBoard, 0, false);
        _tttBoard[i] = '';
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }

    if (bestMove == -1) {
      for (int i = 0; i < 9; i++) {
        if (_tttBoard[i].isEmpty) return i;
      }
    }
    return bestMove;
  }

  int _minimax(List<String> board, int depth, bool isMaximizing) {
    String? result = _checkWinnerState(board);
    if (result == 'O') return 10 - depth;
    if (result == 'X') return depth - 10;
    if (result == 'Draw') return 0;

    if (isMaximizing) {
      int maxScore = -10000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = 'O';
          int score = _minimax(board, depth + 1, false);
          board[i] = '';
          maxScore = math.max(maxScore, score);
        }
      }
      return maxScore;
    } else {
      int minScore = 10000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = 'X';
          int score = _minimax(board, depth + 1, true);
          board[i] = '';
          minScore = math.min(minScore, score);
        }
      }
      return minScore;
    }
  }

  String? _checkWinnerState(List<String> b) {
    const combos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final c in combos) {
      if (b[c[0]].isNotEmpty && b[c[0]] == b[c[1]] && b[c[1]] == b[c[2]]) {
        return b[c[0]];
      }
    }
    if (!b.contains('')) return 'Draw';
    return null;
  }

  void _checkTttWinner() {
    const winCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (final combo in winCombos) {
      final a = _tttBoard[combo[0]];
      final b = _tttBoard[combo[1]];
      final c = _tttBoard[combo[2]];
      if (a.isNotEmpty && a == b && b == c) {
        _tttWinner = a;
        _tttWinningCombo = combo;
        if (a == 'X') {
          _xScore++;
          SoundService().playSuccess();
        } else {
          _oScore++;
          SoundService().playAlert();
        }
        return;
      }
    }

    if (!_tttBoard.contains('')) {
      _tttWinner = 'Draw';
      _drawScore++;
      SoundService().playClick();
    }
  }

  // =========================================================================
  // SNAKE PRO METHODS (RESPONSIVE CONTROLS, ANTI-SUICIDE, BONUS FOOD)
  // =========================================================================
  void _startSnake() {
    SoundService().playClick();
    _snake = [
      const math.Point(7, 7),
      const math.Point(7, 8),
      const math.Point(7, 9),
    ];
    _direction = const math.Point(0, -1);
    _nextDirection = null;
    _snakeScore = 0;
    _bonusFood = null;
    _bonusFoodTimer = 0;
    _spawnFood();
    setState(() => _isSnakeRunning = true);

    _snakeTimer?.cancel();
    _snakeTimer = Timer.periodic(Duration(milliseconds: _snakeSpeedMs), (timer) {
      _moveSnake();
    });
  }

  void _pauseSnake() {
    _snakeTimer?.cancel();
    setState(() => _isSnakeRunning = false);
    SoundService().playClick();
  }

  void _spawnFood() {
    final rand = math.Random();
    math.Point<int> newFood;
    do {
      newFood = math.Point(rand.nextInt(_gridCols), rand.nextInt(_gridRows));
    } while (_snake.contains(newFood));
    _food = newFood;

    // Chance to spawn bonus golden star
    if (rand.nextInt(4) == 0 && _bonusFood == null) {
      math.Point<int> newBonus;
      do {
        newBonus = math.Point(rand.nextInt(_gridCols), rand.nextInt(_gridRows));
      } while (_snake.contains(newBonus) || newBonus == _food);
      _bonusFood = newBonus;
      _bonusFoodTimer = 25; // 25 ticks countdown
    }
  }

  void _moveSnake() {
    if (_nextDirection != null) {
      _direction = _nextDirection!;
      _nextDirection = null;
    }

    final head = _snake.first;
    final newHead = math.Point(head.x + _direction.x, head.y + _direction.y);

    // Wall collision or self-collision
    if (newHead.x < 0 ||
        newHead.x >= _gridCols ||
        newHead.y < 0 ||
        newHead.y >= _gridRows ||
        _snake.contains(newHead)) {
      _snakeTimer?.cancel();
      setState(() => _isSnakeRunning = false);
      SoundService().playAlert();
      return;
    }

    setState(() {
      _snake.insert(0, newHead);

      // Countdown bonus food
      if (_bonusFood != null) {
        _bonusFoodTimer--;
        if (_bonusFoodTimer <= 0) {
          _bonusFood = null;
        }
      }

      if (newHead == _food) {
        _snakeScore += 10;
        if (_snakeScore > _snakeHighScore) _snakeHighScore = _snakeScore;
        SoundService().playSuccess();
        _spawnFood();
      } else if (_bonusFood != null && newHead == _bonusFood) {
        _snakeScore += 30; // Golden bonus!
        if (_snakeScore > _snakeHighScore) _snakeHighScore = _snakeScore;
        _bonusFood = null;
        SoundService().playSuccess();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _changeSnakeDirection(math.Point<int> newDir) {
    // Prevent 180-degree suicide reversing
    final current = _nextDirection ?? _direction;
    if (current.x + newDir.x == 0 && current.y + newDir.y == 0) return;
    if (current == newDir) return;

    SoundService().playKey();
    _nextDirection = newDir;
  }

  // =========================================================================
  // DICE ROLLER METHODS
  // =========================================================================
  void _rollDice() {
    if (_isRolling) return;
    SoundService().playClick();
    setState(() => _isRolling = true);

    int count = 0;
    Timer.periodic(const Duration(milliseconds: 65), (t) {
      setState(() {
        _diceValue = math.Random().nextInt(6) + 1;
      });
      count++;
      if (count > 9) {
        t.cancel();
        setState(() {
          _isRolling = false;
          _diceHistory.insert(0, _diceValue);
          if (_diceHistory.length > 8) _diceHistory.removeLast();
        });
        SoundService().playSuccess();
      }
    });
  }

  // =========================================================================
  // BUILD UI
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Stationery Games Arcade",
          style: widget.theme.fontDisplay(fontSize: 22),
        ),
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Games Selector Tabs
                  Row(
                    children: [
                      _buildGameTab("❌⭕ Tic-Tac-Toe", GameType.tictactoe),
                      const SizedBox(width: 8),
                      _buildGameTab("🐍 Snake Pro", GameType.snake),
                      const SizedBox(width: 8),
                      _buildGameTab("🎲 3D Dice", GameType.dice),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (_activeGame == GameType.tictactoe) _buildTicTacToeView(),
                  if (_activeGame == GameType.snake) _buildSnakeView(),
                  if (_activeGame == GameType.dice) _buildDiceView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTab(String label, GameType type) {
    final bool isSelected = (_activeGame == type);
    return Expanded(
      child: InkWell(
        onTap: () {
          SoundService().playClick();
          setState(() => _activeGame = type);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? widget.theme.primary : widget.theme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.theme.border, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.theme.border.withValues(alpha: 0.3),
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: widget.theme.fontMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : widget.theme.text,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TIC-TAC-TOE VIEW
  // =========================================================================
  Widget _buildTicTacToeView() {
    return Column(
      children: [
        // Mode toggle & Score
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("🤖 vs AI"),
                        selected: _vsComputer,
                        selectedColor: widget.theme.primary,
                        onSelected: (val) {
                          setState(() {
                            _vsComputer = true;
                            _resetTtt();
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text("👥 2-Player"),
                        selected: !_vsComputer,
                        selectedColor: widget.theme.secondary,
                        onSelected: (val) {
                          setState(() {
                            _vsComputer = false;
                            _resetTtt();
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    "X: $_xScore | O: $_oScore | Ties: $_drawScore",
                    style: widget.theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_vsComputer) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("AI Level: ", style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold)),
                    _buildDiffChip("Easy", "easy"),
                    const SizedBox(width: 4),
                    _buildDiffChip("Medium", "medium"),
                    const SizedBox(width: 4),
                    _buildDiffChip("🔥 Unbeatable", "unbeatable"),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status or Winner banner
        if (_tttWinner.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: widget.theme.doodleCard(
              color: _tttWinner == 'Draw'
                  ? widget.theme.cardBg
                  : _tttWinner == 'X'
                      ? const Color(0xFFFFEAA7)
                      : const Color(0xFFDFF9FB),
              borderWidth: 2.5,
            ),
            child: Text(
              _tttWinner == 'Draw'
                  ? "🤝 Perfectly Matched Draw!"
                  : _tttWinner == 'X'
                      ? "🎉 Player X Wins!"
                      : (_vsComputer ? "🤖 Unbeatable AI Wins!" : "🎉 Player O Wins!"),
              style: widget.theme.fontDisplay(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          )
        else
          Text(
            "Turn: Player ${_isPlayerXTurn ? 'X' : (_vsComputer ? 'O (AI thinking...)' : 'O')}",
            style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
          ),

        const SizedBox(height: 16),

        // 3x3 Grid
        Container(
          width: 300,
          height: 300,
          padding: const EdgeInsets.all(12),
          decoration: widget.theme.doodleCard(borderWidth: 3.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final val = _tttBoard[index];
              final isWinCell = _tttWinningCombo != null && _tttWinningCombo!.contains(index);

              return InkWell(
                onTap: () => _onTttCellTapped(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isWinCell ? const Color(0xFF55EFC4) : widget.theme.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isWinCell ? const Color(0xFF00B894) : widget.theme.border,
                      width: isWinCell ? 3.0 : 2.0,
                    ),
                    boxShadow: isWinCell
                        ? [
                            const BoxShadow(
                              color: Color(0xFF00B894),
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    val,
                    style: widget.theme.fontDisplay(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: val == 'X' ? const Color(0xFFFF4757) : const Color(0xFF0984E3),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _resetTtt,
              icon: const Icon(Icons.refresh),
              label: const Text("New Match"),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.theme.text,
                side: BorderSide(color: widget.theme.border, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _resetTttScores,
              child: const Text("Reset Scores"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiffChip(String label, String diffKey) {
    final bool sel = (_aiDifficulty == diffKey);
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      selected: sel,
      selectedColor: widget.theme.secondary,
      onSelected: (val) {
        setState(() {
          _aiDifficulty = diffKey;
          _resetTtt();
        });
      },
    );
  }

  // =========================================================================
  // SNAKE PRO VIEW
  // =========================================================================
  Widget _buildSnakeView() {
    return Column(
      children: [
        // Score Bar & Speed Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Score: $_snakeScore", style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_bonusFood != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("⭐ +30 Star!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                ),
              Text("Best: $_snakeHighScore", style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Snake Canvas Grid with Gesture Detector for Swipe Controls
        GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -5) {
              _changeSnakeDirection(const math.Point(0, -1)); // Up
            } else if (details.delta.dy > 5) {
              _changeSnakeDirection(const math.Point(0, 1)); // Down
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx < -5) {
              _changeSnakeDirection(const math.Point(-1, 0)); // Left
            } else if (details.delta.dx > 5) {
              _changeSnakeDirection(const math.Point(1, 0)); // Right
            }
          },
          child: Container(
            width: 290,
            height: 290,
            decoration: widget.theme.doodleCard(
              color: widget.theme.bg,
              borderWidth: 3.0,
            ),
            child: CustomPaint(
              painter: _SnakeGridPainter(
                snake: _snake,
                food: _food,
                bonusFood: _bonusFood,
                rows: _gridRows,
                cols: _gridCols,
                theme: widget.theme,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Start / Pause Controls & Speed Toggles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSnakeRunning ? const Color(0xFFFFA502) : widget.theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSnakeRunning ? _pauseSnake : _startSnake,
              icon: Icon(_isSnakeRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_isSnakeRunning ? "Pause" : "Start Snake"),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<int>(
              tooltip: "Speed Preset",
              initialValue: _snakeSpeedMs,
              onSelected: (val) {
                setState(() => _snakeSpeedMs = val);
                if (_isSnakeRunning) {
                  _snakeTimer?.cancel();
                  _snakeTimer = Timer.periodic(Duration(milliseconds: _snakeSpeedMs), (_) => _moveSnake());
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 230, child: Text("🐢 Slow")),
                PopupMenuItem(value: 170, child: Text("🚶 Normal")),
                PopupMenuItem(value: 105, child: Text("⚡ Fast")),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: widget.theme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.theme.border, width: 2),
                ),
                child: Row(
                  children: [
                    Text(
                      _snakeSpeedMs > 200 ? "🐢 Slow" : _snakeSpeedMs > 130 ? "🚶 Normal" : "⚡ Fast",
                      style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Tactile D-Pad Controls
        Column(
          children: [
            _buildDpadBtn(Icons.arrow_upward, () => _changeSnakeDirection(const math.Point(0, -1))),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDpadBtn(Icons.arrow_back, () => _changeSnakeDirection(const math.Point(-1, 0))),
                const SizedBox(width: 48),
                _buildDpadBtn(Icons.arrow_forward, () => _changeSnakeDirection(const math.Point(1, 0))),
              ],
            ),
            const SizedBox(height: 4),
            _buildDpadBtn(Icons.arrow_downward, () => _changeSnakeDirection(const math.Point(0, 1))),
          ],
        ),
      ],
    );
  }

  Widget _buildDpadBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: () {
        if (!_isSnakeRunning) _startSnake();
        onPressed();
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: widget.theme.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: widget.theme.border, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: widget.theme.border.withValues(alpha: 0.3),
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, color: widget.theme.text, size: 28),
      ),
    );
  }

  // =========================================================================
  // 3D DICE VIEW
  // =========================================================================
  Widget _buildDiceView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Text(
            "Tap the 3D dice or roll button to roll a random number (1 to 6) for Ludo / Board games!",
            textAlign: TextAlign.center,
            style: widget.theme.fontDoodle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),

        // 3D Dice Component
        Transform.rotate(
          angle: _isRolling ? 0.25 : 0.0,
          child: Stationery3DDiceWidget(
            value: _diceValue,
            size: 110,
            onTap: _rollDice,
          ),
        ),

        const SizedBox(height: 22),

        Text(
          "You Rolled: $_diceValue",
          style: widget.theme.fontDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: widget.theme.primary,
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _rollDice,
          icon: const Icon(Icons.casino),
          label: Text(_isRolling ? "Rolling..." : "Roll Dice 🎲"),
        ),

        if (_diceHistory.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Recent rolls: ", style: widget.theme.fontMono(fontSize: 12)),
              Wrap(
                spacing: 6,
                children: _diceHistory.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.theme.cardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.theme.border, width: 1.5),
                    ),
                    child: Text("$d", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// =========================================================================
// CUSTOM PAINTER FOR SNAKE PRO
// =========================================================================
class _SnakeGridPainter extends CustomPainter {
  final List<math.Point<int>> snake;
  final math.Point<int> food;
  final math.Point<int>? bonusFood;
  final int rows;
  final int cols;
  final StationeryTheme theme;

  _SnakeGridPainter({
    required this.snake,
    required this.food,
    this.bonusFood,
    required this.rows,
    required this.cols,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / cols;
    final double cellH = size.height / rows;

    // Draw subtle grid lines
    final Paint linePaint = Paint()
      ..color = theme.border.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    for (int r = 1; r < rows; r++) {
      canvas.drawLine(Offset(0, r * cellH), Offset(size.width, r * cellH), linePaint);
    }
    for (int c = 1; c < cols; c++) {
      canvas.drawLine(Offset(c * cellW, 0), Offset(c * cellW, size.height), linePaint);
    }

    // Draw food (Red apple)
    final Paint foodPaint = Paint()..color = const Color(0xFFFF4757);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(food.x * cellW + 1.5, food.y * cellH + 1.5, cellW - 3, cellH - 3),
        const Radius.circular(5),
      ),
      foodPaint,
    );

    // Draw bonus food (Golden Star)
    if (bonusFood != null) {
      final Paint bonusPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(
        Offset(bonusFood!.x * cellW + cellW / 2, bonusFood!.y * cellH + cellH / 2),
        cellW * 0.42,
        bonusPaint,
      );
    }

    // Draw snake segments
    final Paint snakePaint = Paint()..color = const Color(0xFF2ED573);
    final Paint headPaint = Paint()..color = const Color(0xFF10AC84);

    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final isHead = (i == 0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(p.x * cellW + 1, p.y * cellH + 1, cellW - 2, cellH - 2),
          Radius.circular(isHead ? 6 : 4),
        ),
        isHead ? headPaint : snakePaint,
      );

      // Eye dots on head
      if (isHead) {
        final Paint eyePaint = Paint()..color = Colors.white;
        canvas.drawCircle(
          Offset(p.x * cellW + cellW * 0.35, p.y * cellH + cellH * 0.35),
          1.5,
          eyePaint,
        );
        canvas.drawCircle(
          Offset(p.x * cellW + cellW * 0.65, p.y * cellH + cellH * 0.35),
          1.5,
          eyePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeGridPainter oldDelegate) => true;
}
