import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/stationery_3d_models.dart';

enum GameType { tictactoe, snake, dice, memory }

class GamesScreen extends StatefulWidget {
  final StationeryTheme theme;
  const GamesScreen({super.key, required this.theme});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  GameType _activeGame = GameType.tictactoe;

  // Tic-Tac-Toe state
  List<String> _tttBoard = List.filled(9, '');
  bool _isPlayerXTurn = true;
  bool _vsComputer = true;
  String _tttWinner = ''; // 'X', 'O', 'Draw', ''
  int _xScore = 0;
  int _oScore = 0;

  // Dice roller state
  int _diceValue = 1;
  bool _isRolling = false;

  // Snake state
  static const int _gridRows = 15;
  static const int _gridCols = 15;
  List<Point<int>> _snake = [const Point(5, 5), const Point(5, 6), const Point(5, 7)];
  Point<int> _food = const Point(10, 10);
  Point<int> _direction = const Point(0, -1); // Up
  Timer? _snakeTimer;
  bool _isSnakeRunning = false;
  int _snakeScore = 0;
  int _snakeHighScore = 0;

  @override
  void dispose() {
    _snakeTimer?.cancel();
    super.dispose();
  }

  // --- TIC-TAC-TOE METHODS ---
  void _resetTtt() {
    SoundService().playClick();
    setState(() {
      _tttBoard = List.filled(9, '');
      _isPlayerXTurn = true;
      _tttWinner = '';
    });
  }

  void _onTttCellTapped(int index) {
    if (_tttBoard[index].isNotEmpty || _tttWinner.isNotEmpty) return;

    SoundService().playKey();
    setState(() {
      _tttBoard[index] = _isPlayerXTurn ? 'X' : 'O';
      _checkTttWinner();

      if (_tttWinner.isEmpty) {
        _isPlayerXTurn = !_isPlayerXTurn;
        if (_vsComputer && !_isPlayerXTurn) {
          // Computer makes move after short delay
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) _makeComputerMove();
          });
        }
      }
    });
  }

  void _makeComputerMove() {
    // Find best move or random empty cell
    final emptyIndices = <int>[];
    for (int i = 0; i < 9; i++) {
      if (_tttBoard[i].isEmpty) emptyIndices.add(i);
    }
    if (emptyIndices.isEmpty || _tttWinner.isNotEmpty) return;

    final move = emptyIndices[math.Random().nextInt(emptyIndices.length)];
    SoundService().playKey();
    setState(() {
      _tttBoard[move] = 'O';
      _checkTttWinner();
      if (_tttWinner.isEmpty) {
        _isPlayerXTurn = true;
      }
    });
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
        if (a == 'X') _xScore++; else _oScore++;
        SoundService().playSuccess();
        return;
      }
    }

    if (!_tttBoard.contains('')) {
      _tttWinner = 'Draw';
      SoundService().playAlert();
    }
  }

  // --- DICE ROLLER METHODS ---
  void _rollDice() {
    if (_isRolling) return;
    SoundService().playClick();
    setState(() => _isRolling = true);

    int count = 0;
    Timer.periodic(const Duration(milliseconds: 70), (t) {
      setState(() {
        _diceValue = math.Random().nextInt(6) + 1;
      });
      count++;
      if (count > 8) {
        t.cancel();
        setState(() => _isRolling = false);
        SoundService().playSuccess();
      }
    });
  }

  // --- SNAKE METHODS ---
  void _startSnake() {
    SoundService().playClick();
    _snake = [const Point(7, 7), const Point(7, 8), const Point(7, 9)];
    _direction = const Point(0, -1);
    _snakeScore = 0;
    _spawnFood();
    setState(() => _isSnakeRunning = true);

    _snakeTimer?.cancel();
    _snakeTimer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      _moveSnake();
    });
  }

  void _spawnFood() {
    final rand = math.Random();
    Point<int> newFood;
    do {
      newFood = Point(rand.nextInt(_gridCols), rand.nextInt(_gridRows));
    } while (_snake.contains(newFood));
    _food = newFood;
  }

  void _moveSnake() {
    final head = _snake.first;
    final newHead = Point(head.x + _direction.x, head.y + _direction.y);

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
      if (newHead == _food) {
        _snakeScore += 10;
        if (_snakeScore > _snakeHighScore) _snakeHighScore = _snakeScore;
        SoundService().playSuccess();
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _changeSnakeDirection(Point<int> newDir) {
    // Avoid reversing directly
    if (_direction.x + newDir.x == 0 && _direction.y + newDir.y == 0) return;
    SoundService().playKey();
    _direction = newDir;
  }

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
          "Stationery Games",
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
                      _buildGameTab("Tic-Tac-Toe", GameType.tictactoe),
                      const SizedBox(width: 8),
                      _buildGameTab("Snake", GameType.snake),
                      const SizedBox(width: 8),
                      _buildGameTab("3D Dice", GameType.dice),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.theme.primary : widget.theme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.theme.border, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.theme.border.withOpacity(0.3),
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
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

  // --- TIC-TAC-TOE WIDGET ---
  Widget _buildTicTacToeView() {
    return Column(
      children: [
        // Mode toggle & Score
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text("Mode: ", style: widget.theme.fontMono(fontSize: 12)),
                  ChoiceChip(
                    label: const Text("vs AI"),
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
                    label: const Text("2-Player"),
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
                "X: $_xScore | O: $_oScore",
                style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status or Winner banner
        if (_tttWinner.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: widget.theme.doodleCard(
              color: widget.theme.accent.withOpacity(0.35),
              borderWidth: 2.5,
            ),
            child: Text(
              _tttWinner == 'Draw' ? "Match Draw!" : "Player $_tttWinner Wins!",
              style: widget.theme.fontDisplay(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          )
        else
          Text(
            "Turn: Player ${_isPlayerXTurn ? 'X' : 'O'}",
            style: widget.theme.fontDisplay(fontSize: 16),
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
              return InkWell(
                onTap: () => _onTttCellTapped(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.theme.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.theme.border, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    val,
                    style: widget.theme.fontDisplay(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: val == 'X' ? const Color(0xFFFF4757) : const Color(0xFF2ED573),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _resetTtt,
          icon: const Icon(Icons.refresh),
          label: const Text("Restart Game"),
        ),
      ],
    );
  }

  // --- SNAKE WIDGET ---
  Widget _buildSnakeView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("Score: $_snakeScore", style: widget.theme.fontDisplay(fontSize: 18)),
            Text("High Score: $_snakeHighScore", style: widget.theme.fontDisplay(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),

        // Snake Canvas Grid
        Container(
          width: 280,
          height: 280,
          decoration: widget.theme.doodleCard(
            color: widget.theme.bg,
            borderWidth: 3.0,
          ),
          child: CustomPaint(
            painter: _SnakeGridPainter(
              snake: _snake,
              food: _food,
              rows: _gridRows,
              cols: _gridCols,
              theme: widget.theme,
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (!_isSnakeRunning)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            onPressed: _startSnake,
            child: const Text("Start Snake Game"),
          )
        else
          // D-Pad Controls
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 36),
                onPressed: () => _changeSnakeDirection(const Point(0, -1)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left, size: 36),
                    onPressed: () => _changeSnakeDirection(const Point(-1, 0)),
                  ),
                  const SizedBox(width: 48),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right, size: 36),
                    onPressed: () => _changeSnakeDirection(const Point(1, 0)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 36),
                onPressed: () => _changeSnakeDirection(const Point(0, 1)),
              ),
            ],
          ),
      ],
    );
  }

  // --- DICE WIDGET ---
  Widget _buildDiceView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Text(
            "Tap the 3D dice or roll button to roll a random number (1 to 6)!",
            textAlign: TextAlign.center,
            style: widget.theme.fontDoodle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 28),

        // 3D Dice Component
        Transform.rotate(
          angle: _isRolling ? 0.2 : 0.0,
          child: Stationery3DDiceWidget(
            value: _diceValue,
            size: 110,
            onTap: _rollDice,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          "You Rolled: $_diceValue",
          style: widget.theme.fontDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: widget.theme.primary,
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _rollDice,
          icon: const Icon(Icons.casino),
          label: Text(_isRolling ? "Rolling..." : "Roll Dice"),
        ),
      ],
    );
  }
}

class _SnakeGridPainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final int rows;
  final int cols;
  final StationeryTheme theme;

  _SnakeGridPainter({
    required this.snake,
    required this.food,
    required this.rows,
    required this.cols,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / cols;
    final double cellH = size.height / rows;

    // Draw food (Red apple)
    final Paint foodPaint = Paint()..color = const Color(0xFFFF4757);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(food.x * cellW + 1, food.y * cellH + 1, cellW - 2, cellH - 2),
        const Radius.circular(4),
      ),
      foodPaint,
    );

    // Draw snake segments
    final Paint snakePaint = Paint()..color = const Color(0xFF2ED573);
    final Paint headPaint = Paint()..color = const Color(0xFF10AC84);

    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(p.x * cellW + 1, p.y * cellH + 1, cellW - 2, cellH - 2),
          const Radius.circular(4),
        ),
        (i == 0) ? headPaint : snakePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeGridPainter oldDelegate) => true;
}
