import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';

enum GameType { tictactoe, snake, ludo, snakesAndLadders, uno, tetris }

class GamesScreen extends StatefulWidget {
  final StationeryTheme theme;
  const GamesScreen({super.key, required this.theme});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with TickerProviderStateMixin {
  GameType _activeGame = GameType.tictactoe;

  @override
  void initState() {
    super.initState();
    _initSnakeHigh();
    _initTetrisHigh();
  }

  @override
  void dispose() {
    _snakeTimer?.cancel();
    _tetrisTimer?.cancel();
    _ludoBotTimer?.cancel();
    _snlBotTimer?.cancel();
    _unoBotTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // 1. TIC-TAC-TOE STATE & SUPER-STRONG MINIMAX ENGINE
  // =========================================================================
  List<String> _tttBoard = List.filled(9, '');
  bool _isPlayerTurn = true;
  bool _vsComputer = true;
  String _playerSymbol = 'X'; // 'X' or 'O'
  String _aiDifficulty = 'unbeatable'; // 'easy', 'medium', 'unbeatable'
  String _tttWinner = ''; // 'X', 'O', 'Draw', ''
  List<int>? _tttWinningCombo;
  int _xScore = 0;
  int _oScore = 0;
  int _drawScore = 0;

  String get _aiSymbol => _playerSymbol == 'X' ? 'O' : 'X';

  void _resetTtt() {
    SoundService().playClick();
    setState(() {
      _tttBoard = List.filled(9, '');
      _tttWinner = '';
      _tttWinningCombo = null;
      _isPlayerTurn = _playerSymbol == 'X';

      if (_vsComputer && !_isPlayerTurn) {
        Timer(const Duration(milliseconds: 400), () {
          if (mounted) _makeTttComputerMove();
        });
      }
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
    if (_vsComputer && !_isPlayerTurn) return;

    SoundService().playKey();
    setState(() {
      final currentSymbol = _vsComputer ? _playerSymbol : (_isPlayerTurn ? 'X' : 'O');
      _tttBoard[index] = currentSymbol;
      _checkTttWinner();

      if (_tttWinner.isEmpty) {
        _isPlayerTurn = !_isPlayerTurn;
        if (_vsComputer && !_isPlayerTurn) {
          Timer(const Duration(milliseconds: 350), () {
            if (mounted) _makeTttComputerMove();
          });
        }
      }
    });
  }

  void _makeTttComputerMove() {
    if (_tttWinner.isNotEmpty) return;

    final emptyIndices = <int>[];
    for (int i = 0; i < 9; i++) {
      if (_tttBoard[i].isEmpty) emptyIndices.add(i);
    }
    if (emptyIndices.isEmpty) return;

    int chosenMove = emptyIndices.first;

    if (_aiDifficulty == 'easy') {
      chosenMove = emptyIndices[math.Random().nextInt(emptyIndices.length)];
    } else if (_aiDifficulty == 'medium') {
      final winMove = _findImmediateWinOrBlock(_aiSymbol);
      final blockMove = _findImmediateWinOrBlock(_playerSymbol);
      if (winMove != null) {
        chosenMove = winMove;
      } else if (blockMove != null) {
        chosenMove = blockMove;
      } else if (math.Random().nextBool()) {
        chosenMove = _getBestMinimaxMove();
      } else {
        chosenMove = emptyIndices[math.Random().nextInt(emptyIndices.length)];
      }
    } else {
      chosenMove = _getBestMinimaxMove();
    }

    SoundService().playKey();
    setState(() {
      _tttBoard[chosenMove] = _aiSymbol;
      _checkTttWinner();
      if (_tttWinner.isEmpty) {
        _isPlayerTurn = true;
      }
    });
  }

  int? _findImmediateWinOrBlock(String sym) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final line in lines) {
      final vals = [_tttBoard[line[0]], _tttBoard[line[1]], _tttBoard[line[2]]];
      if (vals.where((v) => v == sym).length == 2 && vals.contains('')) {
        for (final idx in line) {
          if (_tttBoard[idx].isEmpty) return idx;
        }
      }
    }
    return null;
  }

  int _getBestMinimaxMove() {
    // Center priority for unbreakable play
    if (_tttBoard[4].isEmpty && math.Random().nextDouble() < 0.85) {
      return 4;
    }

    int bestScore = -10000;
    int bestMove = -1;

    for (int i = 0; i < 9; i++) {
      if (_tttBoard[i].isEmpty) {
        _tttBoard[i] = _aiSymbol;
        int score = _tttMinimax(_tttBoard, 0, false);
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

  int _tttMinimax(List<String> board, int depth, bool isMaximizing) {
    String? result = _checkTttWinnerState(board);
    if (result == _aiSymbol) return 10 - depth;
    if (result == _playerSymbol) return depth - 10;
    if (result == 'Draw') return 0;

    if (isMaximizing) {
      int maxScore = -10000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = _aiSymbol;
          int score = _tttMinimax(board, depth + 1, false);
          board[i] = '';
          maxScore = math.max(maxScore, score);
        }
      }
      return maxScore;
    } else {
      int minScore = 10000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = _playerSymbol;
          int score = _tttMinimax(board, depth + 1, true);
          board[i] = '';
          minScore = math.min(minScore, score);
        }
      }
      return minScore;
    }
  }

  String? _checkTttWinnerState(List<String> b) {
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
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    for (final combo in winCombos) {
      if (_tttBoard[combo[0]].isNotEmpty &&
          _tttBoard[combo[0]] == _tttBoard[combo[1]] &&
          _tttBoard[combo[0]] == _tttBoard[combo[2]]) {
        _tttWinner = _tttBoard[combo[0]];
        _tttWinningCombo = combo;
        if (_tttWinner == 'X') _xScore++;
        if (_tttWinner == 'O') _oScore++;
        SoundService().playSuccess();
        return;
      }
    }

    if (!_tttBoard.contains('')) {
      _tttWinner = 'Draw';
      _drawScore++;
      SoundService().playAlert();
    }
  }

  // =========================================================================
  // 2. SNAKE PRO STATE & ENGINE
  // =========================================================================
  static const int _snakeRows = 16;
  static const int _snakeCols = 16;
  List<math.Point<int>> _snake = [
    const math.Point(7, 7),
    const math.Point(7, 8),
    const math.Point(7, 9),
  ];
  math.Point<int> _snakeFood = const math.Point(12, 12);
  math.Point<int>? _snakeGoldenApple;
  int _goldenAppleTimer = 0;
  math.Point<int> _snakeDirection = const math.Point(0, -1);
  math.Point<int>? _snakeNextDirection;
  Timer? _snakeTimer;
  bool _isSnakeRunning = false;
  final int _snakeSpeedMs = 140;
  int _snakeScore = 0;
  int _snakeHighScore = 0;

  Future<void> _initSnakeHigh() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _snakeHighScore = prefs.getInt('tooler_snake_hi') ?? 0;
    });
  }

  void _saveSnakeHigh() async {
    if (_snakeScore > _snakeHighScore) {
      _snakeHighScore = _snakeScore;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tooler_snake_hi', _snakeHighScore);
    }
  }

  void _startSnake() {
    SoundService().playClick();
    _snakeTimer?.cancel();
    setState(() {
      _isSnakeRunning = true;
      _snakeDirection = const math.Point(0, -1);
      _snakeNextDirection = null;
    });
    _snakeTimer = Timer.periodic(Duration(milliseconds: _snakeSpeedMs), (_) => _snakeStep());
  }

  void _pauseSnake() {
    _snakeTimer?.cancel();
    setState(() {
      _isSnakeRunning = false;
    });
  }

  void _resetSnake() {
    _pauseSnake();
    setState(() {
      _snake = [
        const math.Point(7, 7),
        const math.Point(7, 8),
        const math.Point(7, 9),
      ];
      _snakeDirection = const math.Point(0, -1);
      _snakeNextDirection = null;
      _snakeScore = 0;
      _snakeGoldenApple = null;
      _spawnSnakeFood();
    });
  }

  void _spawnSnakeFood() {
    final r = math.Random();
    math.Point<int> p;
    do {
      p = math.Point(r.nextInt(_snakeCols), r.nextInt(_snakeRows));
    } while (_snake.contains(p));
    _snakeFood = p;

    // 25% chance of spawning bonus golden apple
    if (r.nextDouble() < 0.25 && _snakeGoldenApple == null) {
      math.Point<int> gp;
      do {
        gp = math.Point(r.nextInt(_snakeCols), r.nextInt(_snakeRows));
      } while (_snake.contains(gp) || gp == _snakeFood);
      _snakeGoldenApple = gp;
      _goldenAppleTimer = 40;
    }
  }

  void _setSnakeDir(math.Point<int> newDir) {
    if (_snakeDirection.x + newDir.x == 0 && _snakeDirection.y + newDir.y == 0) return;
    _snakeNextDirection = newDir;
  }

  void _snakeStep() {
    if (!_isSnakeRunning) return;

    setState(() {
      if (_snakeNextDirection != null) {
        _snakeDirection = _snakeNextDirection!;
        _snakeNextDirection = null;
      }

      final head = _snake.first;
      final newHead = math.Point(head.x + _snakeDirection.x, head.y + _snakeDirection.y);

      // Wall collision check
      if (newHead.x < 0 || newHead.x >= _snakeCols || newHead.y < 0 || newHead.y >= _snakeRows) {
        _onSnakeGameOver();
        return;
      }

      // Self collision check
      if (_snake.contains(newHead)) {
        _onSnakeGameOver();
        return;
      }

      _snake.insert(0, newHead);

      // Food collision
      if (newHead == _snakeFood) {
        _snakeScore += 10;
        SoundService().playSuccess();
        _saveSnakeHigh();
        _spawnSnakeFood();
      } else if (_snakeGoldenApple != null && newHead == _snakeGoldenApple) {
        _snakeScore += 35;
        _snakeGoldenApple = null;
        SoundService().playSuccess();
        _saveSnakeHigh();
      } else {
        _snake.removeLast();
      }

      if (_snakeGoldenApple != null) {
        _goldenAppleTimer--;
        if (_goldenAppleTimer <= 0) {
          _snakeGoldenApple = null;
        }
      }
    });
  }

  void _onSnakeGameOver() {
    _pauseSnake();
    SoundService().playAlert();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.theme.border, width: 2),
        ),
        title: Text('Game Over', style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Score: $_snakeScore', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Best High Score: $_snakeHighScore', style: TextStyle(fontSize: 14, color: widget.theme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetSnake();
            },
            child: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. REAL LUDO STATE & ENGINE
  // =========================================================================
  static const List<int> _ludoSafeStars = [0, 8, 13, 21, 26, 34, 39, 47];
  static const List<Color> _ludoPlayerColors = [
    Color(0xFFE74C3C), // Red
    Color(0xFF27AE60), // Green
    Color(0xFFF39C12), // Yellow
    Color(0xFF2980B9), // Blue
  ];
  static const List<String> _ludoPlayerNames = ['Red (You)', 'Green (Bot)', 'Yellow (Bot)', 'Blue (Bot)'];

  List<List<int>> _ludoTokens = [
    [-1, -1, -1, -1],
    [-1, -1, -1, -1],
    [-1, -1, -1, -1],
    [-1, -1, -1, -1],
  ];
  int _ludoCurrentTurn = 0;
  int _ludoDiceVal = 1;
  bool _ludoHasRolled = false;
  bool _ludoIsRolling = false;
  Timer? _ludoBotTimer;
  String? _ludoWinner;

  void _resetLudo() {
    SoundService().playClick();
    _ludoBotTimer?.cancel();
    setState(() {
      _ludoTokens = [
        [-1, -1, -1, -1],
        [-1, -1, -1, -1],
        [-1, -1, -1, -1],
        [-1, -1, -1, -1],
      ];
      _ludoCurrentTurn = 0;
      _ludoDiceVal = 1;
      _ludoHasRolled = false;
      _ludoIsRolling = false;
      _ludoWinner = null;
    });
  }

  bool _canLudoTokenMove(int pIdx, int tIdx) {
    if (!_ludoHasRolled) return false;
    final step = _ludoTokens[pIdx][tIdx];
    if (step == -1) return _ludoDiceVal == 6;
    if (step == 56) return false;
    return (step + _ludoDiceVal) <= 56;
  }

  void _rollLudoDice() {
    if (_ludoHasRolled || _ludoIsRolling || _ludoWinner != null) return;
    if (_ludoCurrentTurn != 0) return;
    _executeLudoRoll();
  }

  void _executeLudoRoll() {
    SoundService().playClick();
    setState(() {
      _ludoIsRolling = true;
    });

    int count = 0;
    Timer.periodic(const Duration(milliseconds: 60), (t) {
      setState(() {
        _ludoDiceVal = math.Random().nextInt(6) + 1;
      });
      count++;
      if (count > 7) {
        t.cancel();
        setState(() {
          _ludoIsRolling = false;
          _ludoHasRolled = true;
          _postLudoRoll();
        });
      }
    });
  }

  void _postLudoRoll() {
    final movable = <int>[];
    for (int i = 0; i < 4; i++) {
      if (_canLudoTokenMove(_ludoCurrentTurn, i)) movable.add(i);
    }

    if (movable.isEmpty) {
      Timer(const Duration(milliseconds: 700), () {
        if (mounted) _nextLudoTurn();
      });
    } else if (movable.length == 1 && _ludoCurrentTurn == 0) {
      Timer(const Duration(milliseconds: 300), () {
        if (mounted && _ludoHasRolled) _moveLudoToken(_ludoCurrentTurn, movable.first);
      });
    } else if (_ludoCurrentTurn != 0) {
      _ludoBotTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        final chosen = _pickBestLudoMove(movable);
        _moveLudoToken(_ludoCurrentTurn, chosen);
      });
    }
  }

  int _pickBestLudoMove(List<int> movable) {
    // 1. Capture enemy token
    for (final t in movable) {
      final step = _ludoTokens[_ludoCurrentTurn][t];
      final targetStep = step == -1 ? 0 : step + _ludoDiceVal;
      if (targetStep <= 50) {
        final trackIdx = (_getStartIdx(_ludoCurrentTurn) + targetStep) % 52;
        if (!_ludoSafeStars.contains(trackIdx) && _hasEnemyOnTrack(trackIdx, _ludoCurrentTurn)) {
          return t;
        }
      }
    }
    // 2. Bring out token on 6
    if (_ludoDiceVal == 6) {
      for (final t in movable) {
        if (_ludoTokens[_ludoCurrentTurn][t] == -1) return t;
      }
    }
    // 3. Enter home
    for (final t in movable) {
      final step = _ludoTokens[_ludoCurrentTurn][t];
      if (step + _ludoDiceVal == 56) return t;
    }
    // 4. Furthest advance
    movable.sort((a, b) => _ludoTokens[_ludoCurrentTurn][b].compareTo(_ludoTokens[_ludoCurrentTurn][a]));
    return movable.first;
  }

  bool _hasEnemyOnTrack(int trackIdx, int myPlayer) {
    for (int p = 0; p < 4; p++) {
      if (p == myPlayer) continue;
      for (final s in _ludoTokens[p]) {
        if (s >= 0 && s <= 50) {
          final enemyTrack = (_getStartIdx(p) + s) % 52;
          if (enemyTrack == trackIdx) return true;
        }
      }
    }
    return false;
  }

  int _getStartIdx(int p) {
    return p == 0 ? 0 : p == 1 ? 13 : p == 2 ? 26 : 39;
  }

  void _moveLudoToken(int pIdx, int tIdx) {
    if (!_ludoHasRolled) return;

    SoundService().playKey();
    bool getsBonusRoll = false;

    setState(() {
      final currentStep = _ludoTokens[pIdx][tIdx];
      if (currentStep == -1) {
        _ludoTokens[pIdx][tIdx] = 0;
      } else {
        final targetStep = currentStep + _ludoDiceVal;
        _ludoTokens[pIdx][tIdx] = targetStep;

        if (targetStep == 56) {
          getsBonusRoll = true;
          if (_ludoTokens[pIdx].every((s) => s == 56)) {
            _ludoWinner = _ludoPlayerNames[pIdx];
            SoundService().playSuccess();
            return;
          }
        } else if (targetStep <= 50) {
          final actualTrack = (_getStartIdx(pIdx) + targetStep) % 52;
          if (!_ludoSafeStars.contains(actualTrack)) {
            for (int enemy = 0; enemy < 4; enemy++) {
              if (enemy == pIdx) continue;
              for (int et = 0; et < 4; et++) {
                final es = _ludoTokens[enemy][et];
                if (es >= 0 && es <= 50) {
                  final enemyTrack = (_getStartIdx(enemy) + es) % 52;
                  if (enemyTrack == actualTrack) {
                    _ludoTokens[enemy][et] = -1; // Send back to yard!
                    getsBonusRoll = true;
                    SoundService().playSuccess();
                  }
                }
              }
            }
          }
        }
      }

      if (_ludoDiceVal == 6) getsBonusRoll = true;

      _ludoHasRolled = false;

      if (getsBonusRoll && _ludoWinner == null) {
        if (_ludoCurrentTurn != 0) {
          _ludoBotTimer = Timer(const Duration(milliseconds: 700), () {
            if (mounted) _executeLudoRoll();
          });
        }
      } else {
        _nextLudoTurn();
      }
    });
  }

  void _nextLudoTurn() {
    setState(() {
      _ludoHasRolled = false;
      _ludoCurrentTurn = (_ludoCurrentTurn + 1) % 4;
    });

    if (_ludoCurrentTurn != 0 && _ludoWinner == null) {
      _ludoBotTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) _executeLudoRoll();
      });
    }
  }

  // =========================================================================
  // 4. SNAKE AND LADDER STATE & ENGINE
  // =========================================================================
  static const Map<int, int> _snlSnakes = {
    98: 78, 95: 56, 92: 73, 83: 19, 73: 15, 69: 33, 64: 36, 59: 17, 52: 11, 48: 9, 46: 5
  };
  static const Map<int, int> _snlLadders = {
    4: 14, 9: 31, 20: 38, 28: 84, 40: 59, 51: 67, 63: 81, 71: 91
  };
  int _snlP1Pos = 1;
  int _snlP2Pos = 1;
  int _snlTurn = 1; // 1 = Human, 2 = Bot
  int _snlDice = 1;
  bool _snlIsRolling = false;
  String _snlStatus = 'Your Turn! Tap Roll Dice.';
  Timer? _snlBotTimer;

  void _resetSnl() {
    SoundService().playClick();
    _snlBotTimer?.cancel();
    setState(() {
      _snlP1Pos = 1;
      _snlP2Pos = 1;
      _snlTurn = 1;
      _snlDice = 1;
      _snlIsRolling = false;
      _snlStatus = 'New Game Started! Your Turn.';
    });
  }

  void _rollSnlDice() {
    if (_snlIsRolling || _snlTurn != 1) return;
    _executeSnlRoll();
  }

  void _executeSnlRoll() {
    SoundService().playClick();
    setState(() {
      _snlIsRolling = true;
    });

    int count = 0;
    Timer.periodic(const Duration(milliseconds: 60), (t) {
      setState(() {
        _snlDice = math.Random().nextInt(6) + 1;
      });
      count++;
      if (count > 7) {
        t.cancel();
        setState(() {
          _snlIsRolling = false;
          _stepSnlPlayer();
        });
      }
    });
  }

  void _stepSnlPlayer() {
    final isP1 = _snlTurn == 1;
    int currentPos = isP1 ? _snlP1Pos : _snlP2Pos;
    int target = currentPos + _snlDice;

    if (target <= 100) {
      currentPos = target;
      if (_snlSnakes.containsKey(currentPos)) {
        currentPos = _snlSnakes[currentPos]!;
        _snlStatus = '${isP1 ? "You" : "Bot"} got bitten by a snake! Slid to $currentPos';
      } else if (_snlLadders.containsKey(currentPos)) {
        currentPos = _snlLadders[currentPos]!;
        _snlStatus = '${isP1 ? "You" : "Bot"} climbed a ladder! Reached $currentPos';
      } else {
        _snlStatus = '${isP1 ? "You" : "Bot"} rolled a $_snlDice and moved to $currentPos';
      }
    } else {
      _snlStatus = '${isP1 ? "You" : "Bot"} rolled $_snlDice! Need exact roll to reach 100.';
    }

    if (isP1) {
      _snlP1Pos = currentPos;
    } else {
      _snlP2Pos = currentPos;
    }

    if (currentPos == 100) {
      _snlStatus = '${isP1 ? "You Won!" : "Bot Won!"} Reached Square 100!';
      SoundService().playSuccess();
      return;
    }

    if (_snlDice == 6) {
      _snlStatus += ' • Rolled a 6! Extra turn!';
      if (!isP1) {
        _snlBotTimer = Timer(const Duration(milliseconds: 900), () {
          if (mounted) _executeSnlRoll();
        });
      }
    } else {
      _snlTurn = isP1 ? 2 : 1;
      if (_snlTurn == 2) {
        _snlBotTimer = Timer(const Duration(milliseconds: 900), () {
          if (mounted) _executeSnlRoll();
        });
      }
    }
  }

  // =========================================================================
  // 5. UNO CARD GAME STATE & ENGINE
  // =========================================================================
  List<Map<String, String>> _unoDeck = [];
  List<Map<String, String>> _unoPlayerHand = [];
  List<Map<String, String>> _unoBotHand = [];
  Map<String, String> _unoTopCard = {};
  String _unoActiveColor = 'red';
  String _unoCurrentTurn = 'player';
  bool _unoSaidUno = false;
  String _unoStatusMsg = 'Your Turn! Play a matching card or draw.';
  Timer? _unoBotTimer;

  void _initUno() {
    _unoBotTimer?.cancel();
    _unoDeck = _generateUnoDeck();
    _unoDeck.shuffle();
    _unoPlayerHand = _unoDeck.sublist(0, 7);
    _unoBotHand = _unoDeck.sublist(7, 14);
    _unoDeck.removeRange(0, 14);

    int startIdx = _unoDeck.indexWhere((c) => c['color'] != 'wild' && !['🚫', '🔄', '+2'].contains(c['value']));
    if (startIdx == -1) startIdx = 0;
    _unoTopCard = _unoDeck.removeAt(startIdx);
    _unoActiveColor = _unoTopCard['color']!;
    _unoCurrentTurn = 'player';
    _unoSaidUno = false;
    _unoStatusMsg = 'Your Turn! Play a matching card or draw.';
  }

  List<Map<String, String>> _generateUnoDeck() {
    const colors = ['red', 'blue', 'green', 'yellow'];
    final deck = <Map<String, String>>[];
    for (final c in colors) {
      deck.add({'color': c, 'value': '0', 'symbol': '0'});
      for (int i = 1; i <= 9; i++) {
        deck.add({'color': c, 'value': '$i', 'symbol': '$i'});
        deck.add({'color': c, 'value': '$i', 'symbol': '$i'});
      }
      for (final action in ['🚫', '🔄', '+2']) {
        deck.add({'color': c, 'value': action, 'symbol': action});
        deck.add({'color': c, 'value': action, 'symbol': action});
      }
    }
    for (int i = 0; i < 4; i++) {
      deck.add({'color': 'wild', 'value': 'WILD', 'symbol': '🌈'});
      deck.add({'color': 'wild', 'value': '+4', 'symbol': '+4'});
    }
    return deck;
  }

  bool _isUnoCardPlayable(Map<String, String> card) {
    if (card['color'] == 'wild') return true;
    if (card['color'] == _unoActiveColor) return true;
    if (card['value'] == _unoTopCard['value']) return true;
    return false;
  }

  void _onUnoCardTapped(int index) {
    if (_unoCurrentTurn != 'player') return;
    final card = _unoPlayerHand[index];
    if (!_isUnoCardPlayable(card)) {
      SoundService().playAlert();
      setState(() {
        _unoStatusMsg = 'Cannot play this card! Match color $_unoActiveColor or value ${_unoTopCard['value']}.';
      });
      return;
    }

    SoundService().playKey();
    if (card['color'] == 'wild') {
      _showColorPickerModal((chosenColor) {
        _executeUnoPlay(index, chosenColor, isPlayer: true);
      });
    } else {
      _executeUnoPlay(index, card['color']!, isPlayer: true);
    }
  }

  void _showColorPickerModal(Function(String) onPick) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pick Active Color', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _colorPickCircle('red', const Color(0xFFE74C3C), onPick, ctx),
            _colorPickCircle('blue', const Color(0xFF2980B9), onPick, ctx),
            _colorPickCircle('green', const Color(0xFF27AE60), onPick, ctx),
            _colorPickCircle('yellow', const Color(0xFFF1C40F), onPick, ctx),
          ],
        ),
      ),
    );
  }

  Widget _colorPickCircle(String colorName, Color c, Function(String) onPick, BuildContext ctx) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        onPick(colorName);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)],
        ),
      ),
    );
  }

  void _executeUnoPlay(int cardIdx, String chosenColor, {required bool isPlayer}) {
    setState(() {
      final hand = isPlayer ? _unoPlayerHand : _unoBotHand;
      final card = hand.removeAt(cardIdx);
      _unoTopCard = card;
      _unoActiveColor = chosenColor;

      if (hand.isEmpty) {
        _unoStatusMsg = isPlayer ? 'Congratulations! You emptied your hand and Won UNO!' : 'Bot Won UNO!';
        SoundService().playSuccess();
        return;
      }

      if (isPlayer && hand.length == 1 && !_unoSaidUno) {
        _unoStatusMsg = 'Forgot to shout UNO! 2 penalty cards drawn!';
        _drawUnoCards(2, isPlayer: true);
      }

      final val = card['value'];
      if (val == '+2') {
        _drawUnoCards(2, isPlayer: !isPlayer);
        _unoStatusMsg = '${isPlayer ? "You" : "Bot"} played +2! Opponent draws 2 and skips turn!';
        if (!isPlayer) {
          _unoBotTimer = Timer(const Duration(milliseconds: 1000), () {
            if (mounted) _executeUnoBotMove();
          });
        }
        return;
      } else if (val == '+4') {
        _drawUnoCards(4, isPlayer: !isPlayer);
        _unoStatusMsg = '${isPlayer ? "You" : "Bot"} played +4! Opponent draws 4 and skips turn!';
        if (!isPlayer) {
          _unoBotTimer = Timer(const Duration(milliseconds: 1000), () {
            if (mounted) _executeUnoBotMove();
          });
        }
        return;
      } else if (val == '🚫' || val == '🔄') {
        _unoStatusMsg = '${isPlayer ? "You" : "Bot"} played $val! Opponent turn skipped!';
        if (!isPlayer) {
          _unoBotTimer = Timer(const Duration(milliseconds: 1000), () {
            if (mounted) _executeUnoBotMove();
          });
        }
        return;
      }

      _unoCurrentTurn = isPlayer ? 'bot' : 'player';
      _unoSaidUno = false;
      _unoStatusMsg = isPlayer ? "Bot's Turn..." : 'Your Turn!';

      if (_unoCurrentTurn == 'bot') {
        _unoBotTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) _executeUnoBotMove();
        });
      }
    });
  }

  void _drawUnoCards(int count, {required bool isPlayer}) {
    for (int i = 0; i < count; i++) {
      if (_unoDeck.isEmpty) {
        _unoDeck = _generateUnoDeck();
        _unoDeck.shuffle();
      }
      final c = _unoDeck.removeLast();
      if (isPlayer) {
        _unoPlayerHand.add(c);
      } else {
        _unoBotHand.add(c);
      }
    }
  }

  void _playerDrawCard() {
    if (_unoCurrentTurn != 'player') return;
    SoundService().playClick();
    setState(() {
      _drawUnoCards(1, isPlayer: true);
      final drawn = _unoPlayerHand.last;
      if (_isUnoCardPlayable(drawn)) {
        _unoStatusMsg = 'Drawn card is playable! Tap it to play or end turn.';
      } else {
        _unoCurrentTurn = 'bot';
        _unoStatusMsg = 'Drawn card cannot be played. Bot turn...';
        _unoBotTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) _executeUnoBotMove();
        });
      }
    });
  }

  void _shoutUno() {
    SoundService().playClick();
    setState(() {
      _unoSaidUno = true;
      _unoStatusMsg = 'Shouted UNO!';
    });
  }

  void _executeUnoBotMove() {
    if (_unoCurrentTurn != 'bot') return;

    final playable = <int>[];
    for (int i = 0; i < _unoBotHand.length; i++) {
      if (_isUnoCardPlayable(_unoBotHand[i])) playable.add(i);
    }

    if (playable.isEmpty) {
      _drawUnoCards(1, isPlayer: false);
      final drawn = _unoBotHand.last;
      if (_isUnoCardPlayable(drawn)) {
        final chosenColor = drawn['color'] == 'wild' ? _getBotBestColor() : drawn['color']!;
        _executeUnoPlay(_unoBotHand.length - 1, chosenColor, isPlayer: false);
      } else {
        setState(() {
          _unoCurrentTurn = 'player';
          _unoStatusMsg = 'Bot drew a card and passed. Your Turn!';
        });
      }
    } else {
      int chosen = playable.first;
      for (final idx in playable) {
        if (['+2', '+4', '🚫'].contains(_unoBotHand[idx]['value'])) {
          chosen = idx;
          break;
        }
      }
      final card = _unoBotHand[chosen];
      final chosenColor = card['color'] == 'wild' ? _getBotBestColor() : card['color']!;
      _executeUnoPlay(chosen, chosenColor, isPlayer: false);
    }
  }

  String _getBotBestColor() {
    final counts = {'red': 0, 'blue': 0, 'green': 0, 'yellow': 0};
    for (final c in _unoBotHand) {
      if (counts.containsKey(c['color'])) {
        counts[c['color']!] = counts[c['color']!]! + 1;
      }
    }
    String best = 'red';
    int maxC = -1;
    counts.forEach((col, cnt) {
      if (cnt > maxC) {
        maxC = cnt;
        best = col;
      }
    });
    return best;
  }

  // =========================================================================
  // 6. TETRIS STATE & ENGINE
  // =========================================================================
  static const int _tetrisRows = 20;
  static const int _tetrisCols = 10;
  List<List<Color?>> _tetrisGrid = List.generate(_tetrisRows, (_) => List.filled(_tetrisCols, null));

  static const Map<String, List<List<int>>> _tetrominoShapes = {
    'I': [[1, 1, 1, 1]],
    'J': [[1, 0, 0], [1, 1, 1]],
    'L': [[0, 0, 1], [1, 1, 1]],
    'O': [[1, 1], [1, 1]],
    'S': [[0, 1, 1], [1, 1, 0]],
    'T': [[0, 1, 0], [1, 1, 1]],
    'Z': [[1, 1, 0], [0, 1, 1]],
  };

  static const Map<String, Color> _tetrominoColors = {
    'I': Color(0xFF00CED1),
    'J': Color(0xFF3498DB),
    'L': Color(0xFFE67E22),
    'O': Color(0xFFF1C40F),
    'S': Color(0xFF2ECC71),
    'T': Color(0xFF9B59B6),
    'Z': Color(0xFFE74C3C),
  };

  String _currentPieceType = 'T';
  List<List<int>> _currentPieceMatrix = [[0, 1, 0], [1, 1, 1]];
  int _pieceX = 3;
  int _pieceY = 0;
  String _nextPieceType = 'I';

  Timer? _tetrisTimer;
  bool _isTetrisRunning = false;
  int _tetrisScore = 0;
  int _tetrisLines = 0;
  int _tetrisLevel = 1;
  int _tetrisHighScore = 0;

  Future<void> _initTetrisHigh() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tetrisHighScore = prefs.getInt('tooler_tetris_hi') ?? 0;
    });
  }

  void _saveTetrisHigh() async {
    if (_tetrisScore > _tetrisHighScore) {
      _tetrisHighScore = _tetrisScore;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tooler_tetris_hi', _tetrisHighScore);
    }
  }

  void _resetTetris() {
    _tetrisTimer?.cancel();
    setState(() {
      _tetrisGrid = List.generate(_tetrisRows, (_) => List.filled(_tetrisCols, null));
      _tetrisScore = 0;
      _tetrisLines = 0;
      _tetrisLevel = 1;
      _isTetrisRunning = false;
      _spawnTetrisPiece();
    });
  }

  void _startTetris() {
    SoundService().playClick();
    _tetrisTimer?.cancel();
    setState(() {
      _isTetrisRunning = true;
    });
    final interval = math.max(120, 600 - (_tetrisLevel * 45));
    _tetrisTimer = Timer.periodic(Duration(milliseconds: interval), (_) => _tetrisStep());
  }

  void _pauseTetris() {
    _tetrisTimer?.cancel();
    setState(() {
      _isTetrisRunning = false;
    });
  }

  void _spawnTetrisPiece() {
    final types = _tetrominoShapes.keys.toList();
    _currentPieceType = _nextPieceType;
    _currentPieceMatrix = _tetrominoShapes[_currentPieceType]!.map((r) => List<int>.from(r)).toList();
    _nextPieceType = types[math.Random().nextInt(types.length)];
    _pieceX = (_tetrisCols - _currentPieceMatrix[0].length) ~/ 2;
    _pieceY = 0;

    if (_isPieceColliding(_currentPieceMatrix, _pieceX, _pieceY)) {
      _pauseTetris();
      SoundService().playAlert();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: widget.theme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: widget.theme.border, width: 2),
          ),
          title: Text('Tetris Game Over', style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Score: $_tetrisScore', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Lines Cleared: $_tetrisLines', style: const TextStyle(fontSize: 14)),
              Text('High Score: $_tetrisHighScore', style: TextStyle(fontSize: 14, color: widget.theme.textSecondary)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetTetris();
              },
              child: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  bool _isPieceColliding(List<List<int>> matrix, int px, int py) {
    for (int r = 0; r < matrix.length; r++) {
      for (int c = 0; c < matrix[r].length; c++) {
        if (matrix[r][c] == 1) {
          int gx = px + c;
          int gy = py + r;
          if (gx < 0 || gx >= _tetrisCols || gy >= _tetrisRows) return true;
          if (gy >= 0 && _tetrisGrid[gy][gx] != null) return true;
        }
      }
    }
    return false;
  }

  void _tetrisStep() {
    if (!_isTetrisRunning) return;
    setState(() {
      if (!_isPieceColliding(_currentPieceMatrix, _pieceX, _pieceY + 1)) {
        _pieceY++;
      } else {
        _lockTetrisPiece();
      }
    });
  }

  void _lockTetrisPiece() {
    SoundService().playKey();
    for (int r = 0; r < _currentPieceMatrix.length; r++) {
      for (int c = 0; c < _currentPieceMatrix[r].length; c++) {
        if (_currentPieceMatrix[r][c] == 1) {
          int gx = _pieceX + c;
          int gy = _pieceY + r;
          if (gy >= 0 && gy < _tetrisRows && gx >= 0 && gx < _tetrisCols) {
            _tetrisGrid[gy][gx] = _tetrominoColors[_currentPieceType];
          }
        }
      }
    }

    int linesCleared = 0;
    for (int r = _tetrisRows - 1; r >= 0; r--) {
      if (_tetrisGrid[r].every((cell) => cell != null)) {
        _tetrisGrid.removeAt(r);
        _tetrisGrid.insert(0, List.filled(_tetrisCols, null));
        linesCleared++;
        r++;
      }
    }

    if (linesCleared > 0) {
      SoundService().playSuccess();
      _tetrisLines += linesCleared;
      final points = [0, 100, 300, 500, 800][math.min(linesCleared, 4)] * _tetrisLevel;
      _tetrisScore += points;
      _tetrisLevel = (_tetrisLines ~/ 10) + 1;
      _saveTetrisHigh();
    }

    _spawnTetrisPiece();
  }

  void _moveTetris(int dx) {
    if (!_isTetrisRunning) return;
    if (!_isPieceColliding(_currentPieceMatrix, _pieceX + dx, _pieceY)) {
      setState(() => _pieceX += dx);
      SoundService().playKey();
    }
  }

  void _rotateTetris() {
    if (!_isTetrisRunning) return;
    final r = _currentPieceMatrix.length;
    final c = _currentPieceMatrix[0].length;
    final rotated = List.generate(c, (i) => List.generate(r, (j) => _currentPieceMatrix[r - 1 - j][i]));

    for (final offset in [0, -1, 1, -2, 2]) {
      if (!_isPieceColliding(rotated, _pieceX + offset, _pieceY)) {
        setState(() {
          _pieceX += offset;
          _currentPieceMatrix = rotated;
        });
        SoundService().playKey();
        return;
      }
    }
  }

  void _hardDropTetris() {
    if (!_isTetrisRunning) return;
    while (!_isPieceColliding(_currentPieceMatrix, _pieceX, _pieceY + 1)) {
      _pieceY++;
      _tetrisScore += 2;
    }
    _lockTetrisPiece();
  }

  // =========================================================================
  // MAIN BUILD & TAB NAVIGATION
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.theme.bg,
      body: Column(
        children: [
          _buildGameTabBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: _buildActiveGameView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTabBar() {
    final games = [
      {'type': GameType.tictactoe, 'label': 'Tic-Tac-Toe'},
      {'type': GameType.snake, 'label': 'Snake Pro'},
      {'type': GameType.ludo, 'label': 'Real Ludo'},
      {'type': GameType.snakesAndLadders, 'label': 'Snake & Ladder'},
      {'type': GameType.uno, 'label': 'UNO Cards'},
      {'type': GameType.tetris, 'label': 'Tetris'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: games.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final g = games[idx];
          final isSelected = _activeGame == g['type'];
          return GestureDetector(
            onTap: () {
              SoundService().playClick();
              setState(() {
                _activeGame = g['type'] as GameType;
                if (_activeGame == GameType.uno && _unoDeck.isEmpty) _initUno();
                if (_activeGame == GameType.tetris && _tetrisGrid.isEmpty) _resetTetris();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? widget.theme.primary : widget.theme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? widget.theme.primary : widget.theme.border,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: widget.theme.primary.withValues(alpha: 0.35),
                          offset: const Offset(1, 3),
                          blurRadius: 4,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  g['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : widget.theme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveGameView() {
    switch (_activeGame) {
      case GameType.tictactoe:
        return _buildTicTacToeView();
      case GameType.snake:
        return _buildSnakeView();
      case GameType.ludo:
        return _buildLudoView();
      case GameType.snakesAndLadders:
        return _buildSnakesAndLaddersView();
      case GameType.uno:
        return _buildUnoView();
      case GameType.tetris:
        return _buildTetrisView();
    }
  }

  // =========================================================================
  // UI 1: TIC-TAC-TOE VIEW
  // =========================================================================
  Widget _buildTicTacToeView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChoiceChip('vs Computer', _vsComputer, () {
              setState(() {
                _vsComputer = true;
                _resetTtt();
              });
            }),
            const SizedBox(width: 10),
            _buildChoiceChip('2 Players', !_vsComputer, () {
              setState(() {
                _vsComputer = false;
                _resetTtt();
              });
            }),
          ],
        ),
        if (_vsComputer) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('AI Level: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              _buildChoiceChip('Easy', _aiDifficulty == 'easy', () => setState(() => _aiDifficulty = 'easy')),
              const SizedBox(width: 6),
              _buildChoiceChip('Medium', _aiDifficulty == 'medium', () => setState(() => _aiDifficulty = 'medium')),
              const SizedBox(width: 6),
              _buildChoiceChip('Unbeatable', _aiDifficulty == 'unbeatable', () => setState(() => _aiDifficulty = 'unbeatable')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Play As: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              _buildChoiceChip('X (First)', _playerSymbol == 'X', () {
                setState(() {
                  _playerSymbol = 'X';
                  _resetTtt();
                });
              }),
              const SizedBox(width: 8),
              _buildChoiceChip('O (Second)', _playerSymbol == 'O', () {
                setState(() {
                  _playerSymbol = 'O';
                  _resetTtt();
                });
              }),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.theme.border, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('X: $_xScore', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE74C3C), fontSize: 15)),
              Text('Draws: $_drawScore', style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.text, fontSize: 15)),
              Text('O: $_oScore', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3498DB), fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _tttWinner.isNotEmpty
              ? (_tttWinner == 'Draw' ? "It's a Draw!" : "Winner: $_tttWinner!")
              : (_isPlayerTurn ? 'Your Turn ($_playerSymbol)' : (_vsComputer ? 'Computer is thinking...' : 'Player O Turn')),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.theme.primary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 290,
          height: 290,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.border, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(3, 4))],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (ctx, i) {
              final val = _tttBoard[i];
              final isWinCell = _tttWinningCombo != null && _tttWinningCombo!.contains(i);
              return GestureDetector(
                onTap: () => _onTttCellTapped(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: isWinCell ? const Color(0xFFFFF3CD) : widget.theme.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isWinCell ? const Color(0xFFE74C3C) : widget.theme.border,
                      width: isWinCell ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      val,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: val == 'X' ? const Color(0xFFE74C3C) : const Color(0xFF3498DB),
                      ),
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
            ElevatedButton(
              onPressed: _resetTtt,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Restart Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _resetTttScores,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.theme.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Reset Scores', style: TextStyle(color: widget.theme.text, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // UI 2: SNAKE PRO VIEW
  // =========================================================================
  Widget _buildSnakeView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.border, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score: $_snakeScore', style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.primary, fontSize: 15)),
              Text('High: $_snakeHighScore', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF39C12), fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onPanUpdate: (details) {
            final dx = details.delta.dx;
            final dy = details.delta.dy;
            if (dx.abs() > dy.abs()) {
              if (dx > 2) _setSnakeDir(const math.Point(1, 0));
              if (dx < -2) _setSnakeDir(const math.Point(-1, 0));
            } else {
              if (dy > 2) _setSnakeDir(const math.Point(0, 1));
              if (dy < -2) _setSnakeDir(const math.Point(0, -1));
            }
          },
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: widget.theme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.theme.border, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(3, 4))],
            ),
            child: CustomPaint(
              painter: _SnakeBoardPainter(
                snake: _snake,
                food: _snakeFood,
                goldenApple: _snakeGoldenApple,
                rows: _snakeRows,
                cols: _snakeCols,
                theme: widget.theme,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_drop_up, size: 36),
              onPressed: () => _setSnakeDir(const math.Point(0, -1)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, size: 36),
                  onPressed: () => _setSnakeDir(const math.Point(-1, 0)),
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(Icons.arrow_right, size: 36),
                  onPressed: () => _setSnakeDir(const math.Point(1, 0)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down, size: 36),
              onPressed: () => _setSnakeDir(const math.Point(0, 1)),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isSnakeRunning ? _pauseSnake : _startSnake,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_isSnakeRunning ? 'Pause' : 'Start Snake', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _resetSnake,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.theme.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Reset', style: TextStyle(color: widget.theme.text, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // UI 3: REAL LUDO VIEW
  // =========================================================================
  Widget _buildLudoView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.border, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Turn: ${_ludoPlayerNames[_ludoCurrentTurn]}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _ludoPlayerColors[_ludoCurrentTurn],
                ),
              ),
              OutlinedButton(
                onPressed: _resetLudo,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  side: BorderSide(color: widget.theme.border),
                ),
                child: const Text('New Game', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.border, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 3))],
          ),
          child: CustomPaint(
            painter: _LudoBoardPainter(
              tokens: _ludoTokens,
              currentTurn: _ludoCurrentTurn,
              hasRolled: _ludoHasRolled,
              canMoveFunc: _canLudoTokenMove,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_ludoCurrentTurn == 0 && _ludoHasRolled) ...[
          const Text('Tap token below to advance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (tIdx) {
              final canMove = _canLudoTokenMove(0, tIdx);
              final step = _ludoTokens[0][tIdx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: canMove ? () => _moveLudoToken(0, tIdx) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canMove ? const Color(0xFFE74C3C) : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: Text(
                    step == -1 ? 'Base ${tIdx + 1}' : (step == 56 ? 'Home' : 'T${tIdx + 1} ($step)'),
                    style: TextStyle(
                      color: canMove ? Colors.white : Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: widget.theme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.theme.border, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))],
              ),
              child: Center(
                child: Text(
                  ['', '⚀', '⚁', '⚂', '⚃', '⚄', '⚅'][_ludoDiceVal],
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _ludoPlayerColors[_ludoCurrentTurn],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: (_ludoCurrentTurn == 0 && !_ludoHasRolled && !_ludoIsRolling) ? _rollLudoDice : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: Text(
                _ludoIsRolling ? 'Rolling...' : (_ludoHasRolled ? 'Rolled $_ludoDiceVal' : 'Roll Dice'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // UI 4: SNAKE & LADDER VIEW
  // =========================================================================
  Widget _buildSnakesAndLaddersView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.border, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('You: Sq $_snlP1Pos', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE74C3C), fontSize: 14)),
              Text(_snlTurn == 1 ? 'Your Turn' : 'Bot Turn', style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.primary, fontSize: 14)),
              Text('Bot: Sq $_snlP2Pos', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2980B9), fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(_snlStatus, style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.border, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 3))],
          ),
          child: CustomPaint(
            painter: _SnakesAndLaddersPainter(
              p1Pos: _snlP1Pos,
              p2Pos: _snlP2Pos,
              snakes: _snlSnakes,
              ladders: _snlLadders,
              theme: widget.theme,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: widget.theme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.theme.border, width: 2),
              ),
              child: Center(
                child: Text(
                  ['', '⚀', '⚁', '⚂', '⚃', '⚄', '⚅'][_snlDice],
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: (_snlTurn == 1 && !_snlIsRolling) ? _rollSnlDice : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: Text(
                _snlIsRolling ? 'Rolling...' : 'Roll Dice',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _resetSnl,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.theme.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Reset', style: TextStyle(color: widget.theme.text, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // UI 5: UNO VIEW
  // =========================================================================
  Widget _buildUnoView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bot Hand: ${_unoBotHand.length} cards', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: List.generate(math.min(_unoBotHand.length, 7), (_) => Container(
                  width: 12, height: 18, margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(color: const Color(0xFF2C3E50), borderRadius: BorderRadius.circular(3)),
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: _playerDrawCard,
              child: Container(
                width: 64,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(2, 3))],
                ),
                child: const Center(
                  child: Text('UNO\nDraw', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  'Color: ${_unoActiveColor.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _getUnoColorValue(_unoActiveColor),
                  ),
                ),
                const SizedBox(height: 4),
                _buildUnoCardWidget(_unoTopCard, isLarge: true),
              ],
            ),
            ElevatedButton(
              onPressed: _unoPlayerHand.length <= 2 ? _shoutUno : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              child: const Text('UNO!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(_unoStatusMsg, style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.primary, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Container(
          height: 115,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _unoPlayerHand.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final card = _unoPlayerHand[i];
              final playable = _isUnoCardPlayable(card) && _unoCurrentTurn == 'player';
              return GestureDetector(
                onTap: () => _onUnoCardTapped(i),
                child: Opacity(
                  opacity: playable ? 1.0 : 0.6,
                  child: _buildUnoCardWidget(card, isLarge: false),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => setState(() => _initUno()),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('New UNO Game', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildUnoCardWidget(Map<String, String> card, {required bool isLarge}) {
    final c = _getUnoColorValue(card['color'] ?? 'red');
    final val = card['value'] ?? '0';
    final sym = card['symbol'] ?? val;

    return Container(
      width: isLarge ? 68 : 58,
      height: isLarge ? 98 : 88,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(2, 3))],
      ),
      child: Center(
        child: Container(
          width: isLarge ? 52 : 44,
          height: isLarge ? 78 : 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              sym,
              style: TextStyle(
                color: c == const Color(0xFF2C3E50) ? Colors.black : c,
                fontSize: isLarge ? 22 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getUnoColorValue(String col) {
    switch (col) {
      case 'red':
        return const Color(0xFFE74C3C);
      case 'blue':
        return const Color(0xFF2980B9);
      case 'green':
        return const Color(0xFF27AE60);
      case 'yellow':
        return const Color(0xFFF1C40F);
      case 'wild':
      default:
        return const Color(0xFF2C3E50);
    }
  }

  // =========================================================================
  // UI 6: TETRIS VIEW
  // =========================================================================
  Widget _buildTetrisView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.border, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Score: $_tetrisScore', style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.primary, fontSize: 13)),
              Text('Lines: $_tetrisLines', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Level: $_tetrisLevel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('High: $_tetrisHighScore', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF39C12), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 190,
              height: 380,
              decoration: BoxDecoration(
                color: const Color(0xFF1E272E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.theme.border, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(2, 3))],
              ),
              child: CustomPaint(
                painter: _TetrisBoardPainter(
                  grid: _tetrisGrid,
                  currentMatrix: _currentPieceMatrix,
                  pieceX: _pieceX,
                  pieceY: _pieceY,
                  pieceColor: _tetrominoColors[_currentPieceType] ?? Colors.white,
                  rows: _tetrisRows,
                  cols: _tetrisCols,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E272E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.theme.border, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'Next:\n$_nextPieceType',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tetrominoColors[_nextPieceType] ?? Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _isTetrisRunning ? _pauseTetris : _startTetris,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(_isTetrisRunning ? 'Pause' : 'Start', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _resetTetris,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: widget.theme.border),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text('Restart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left, size: 36),
              onPressed: () => _moveTetris(-1),
            ),
            IconButton(
              icon: const Icon(Icons.rotate_right, size: 36),
              onPressed: _rotateTetris,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down, size: 36),
              onPressed: _tetrisStep,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right, size: 36),
              onPressed: () => _moveTetris(1),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_double_arrow_down, size: 36, color: Color(0xFFE74C3C)),
              onPressed: _hardDropTetris,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        SoundService().playClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary : widget.theme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? widget.theme.primary : widget.theme.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : widget.theme.text,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM PAINTERS FOR SNAKE, LUDO, SNAKES & LADDERS, AND TETRIS
// =========================================================================

class _SnakeBoardPainter extends CustomPainter {
  final List<math.Point<int>> snake;
  final math.Point<int> food;
  final math.Point<int>? goldenApple;
  final int rows;
  final int cols;
  final StationeryTheme theme;

  _SnakeBoardPainter({
    required this.snake,
    required this.food,
    required this.goldenApple,
    required this.rows,
    required this.cols,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final gridPaint = Paint()..color = Colors.black.withValues(alpha: 0.05)..strokeWidth = 1;
    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(Offset(i * cellW, 0), Offset(i * cellW, size.height), gridPaint);
    }
    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(Offset(0, i * cellH), Offset(size.width, i * cellH), gridPaint);
    }

    final foodPaint = Paint()..color = const Color(0xFFE74C3C);
    canvas.drawCircle(Offset((food.x + 0.5) * cellW, (food.y + 0.5) * cellH), cellW * 0.42, foodPaint);

    if (goldenApple != null) {
      final goldPaint = Paint()..color = const Color(0xFFF1C40F);
      canvas.drawCircle(Offset((goldenApple!.x + 0.5) * cellW, (goldenApple!.y + 0.5) * cellH), cellW * 0.46, goldPaint);
    }

    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final isHead = i == 0;
      final bodyPaint = Paint()..color = isHead ? theme.primary : theme.primary.withValues(alpha: 0.75);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x * cellW + 1, p.y * cellH + 1, cellW - 2, cellH - 2),
        Radius.circular(isHead ? 6 : 4),
      );
      canvas.drawRRect(rrect, bodyPaint);

      if (isHead) {
        final eyePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset((p.x + 0.35) * cellW, (p.y + 0.35) * cellH), cellW * 0.12, eyePaint);
        canvas.drawCircle(Offset((p.x + 0.65) * cellW, (p.y + 0.35) * cellH), cellW * 0.12, eyePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeBoardPainter old) => true;
}

class _LudoBoardPainter extends CustomPainter {
  final List<List<int>> tokens;
  final int currentTurn;
  final bool hasRolled;
  final bool Function(int, int) canMoveFunc;

  _LudoBoardPainter({
    required this.tokens,
    required this.currentTurn,
    required this.hasRolled,
    required this.canMoveFunc,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15.0;

    final redPaint = Paint()..color = const Color(0xFFFF7675);
    final greenPaint = Paint()..color = const Color(0xFF55EFC4);
    final yellowPaint = Paint()..color = const Color(0xFFFFEAA7);
    final bluePaint = Paint()..color = const Color(0xFF74B9FF);

    canvas.drawRect(Rect.fromLTWH(0, 0, cell * 6, cell * 6), redPaint);
    canvas.drawRect(Rect.fromLTWH(cell * 9, 0, cell * 6, cell * 6), greenPaint);
    canvas.drawRect(Rect.fromLTWH(cell * 9, cell * 9, cell * 6, cell * 6), yellowPaint);
    canvas.drawRect(Rect.fromLTWH(0, cell * 9, cell * 6, cell * 6), bluePaint);

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cell * 1, cell * 1, cell * 4, cell * 4), const Radius.circular(8)), whitePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cell * 10, cell * 1, cell * 4, cell * 4), const Radius.circular(8)), whitePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cell * 10, cell * 10, cell * 4, cell * 4), const Radius.circular(8)), whitePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cell * 1, cell * 10, cell * 4, cell * 4), const Radius.circular(8)), whitePaint);

    final redLane = Paint()..color = const Color(0xFFE74C3C);
    final greenLane = Paint()..color = const Color(0xFF27AE60);
    final yellowLane = Paint()..color = const Color(0xFFF39C12);
    final blueLane = Paint()..color = const Color(0xFF2980B9);

    for (int i = 1; i <= 5; i++) {
      canvas.drawRect(Rect.fromLTWH(cell * i, cell * 7, cell, cell), redLane);
      canvas.drawRect(Rect.fromLTWH(cell * 7, cell * i, cell, cell), greenLane);
      canvas.drawRect(Rect.fromLTWH(cell * (14 - i), cell * 7, cell, cell), yellowLane);
      canvas.drawRect(Rect.fromLTWH(cell * 7, cell * (14 - i), cell, cell), blueLane);
    }

    final centerPaint = Paint()..color = const Color(0xFF2C3E50);
    canvas.drawRect(Rect.fromLTWH(cell * 6, cell * 6, cell * 3, cell * 3), centerPaint);

    final borderPaint = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1;
    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), borderPaint);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), borderPaint);
    }

    final baseSlots = [
      [Offset(cell * 2, cell * 2), Offset(cell * 4, cell * 2), Offset(cell * 2, cell * 4), Offset(cell * 4, cell * 4)],
      [Offset(cell * 11, cell * 2), Offset(cell * 13, cell * 2), Offset(cell * 11, cell * 4), Offset(cell * 13, cell * 4)],
      [Offset(cell * 11, cell * 11), Offset(cell * 13, cell * 11), Offset(cell * 11, cell * 13), Offset(cell * 13, cell * 13)],
      [Offset(cell * 2, cell * 11), Offset(cell * 4, cell * 11), Offset(cell * 2, cell * 13), Offset(cell * 4, cell * 13)],
    ];

    final track = _buildLudoTrackCoords(cell);

    final tokenColors = [
      const Color(0xFFE74C3C),
      const Color(0xFF27AE60),
      const Color(0xFFF39C12),
      const Color(0xFF2980B9),
    ];

    for (int p = 0; p < 4; p++) {
      for (int t = 0; t < 4; t++) {
        final step = tokens[p][t];
        Offset pos;
        if (step == -1) {
          pos = baseSlots[p][t];
        } else if (step == 56) {
          pos = Offset(cell * 7.5, cell * 7.5);
        } else if (step > 50) {
          final offset = (step - 50).toDouble();
          if (p == 0) {
            pos = Offset(cell * (offset + 0.5), cell * 7.5);
          } else if (p == 1) {
            pos = Offset(cell * 7.5, cell * (offset + 0.5));
          } else if (p == 2) {
            pos = Offset(cell * (14.5 - offset), cell * 7.5);
          } else {
            pos = Offset(cell * 7.5, cell * (14.5 - offset));
          }
        } else {
          final trackIdx = ((p == 0 ? 0 : p == 1 ? 13 : p == 2 ? 26 : 39) + step) % 52;
          pos = track[trackIdx];
        }

        final tPaint = Paint()..color = tokenColors[p];
        final canMove = p == currentTurn && hasRolled && canMoveFunc(p, t);

        if (canMove) {
          final haloPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3;
          canvas.drawCircle(pos, cell * 0.44, haloPaint);
        }

        canvas.drawCircle(pos, cell * 0.36, tPaint);
        canvas.drawCircle(pos, cell * 0.16, Paint()..color = Colors.white);
      }
    }
  }

  List<Offset> _buildLudoTrackCoords(double cell) {
    const coords = [
      [6, 1], [6, 2], [6, 3], [6, 4], [6, 5],
      [5, 6], [4, 6], [3, 6], [2, 6], [1, 6], [0, 6],
      [0, 7], [0, 8],
      [1, 8], [2, 8], [3, 8], [4, 8], [5, 8],
      [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14],
      [7, 14], [8, 14],
      [8, 13], [8, 12], [8, 11], [8, 10], [8, 9],
      [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], [14, 8],
      [14, 7], [14, 6],
      [13, 6], [12, 6], [11, 6], [10, 6], [9, 6],
      [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0],
      [7, 0], [6, 0]
    ];
    return coords.map((c) => Offset((c[1] + 0.5) * cell, (c[0] + 0.5) * cell)).toList();
  }

  @override
  bool shouldRepaint(covariant _LudoBoardPainter old) => true;
}

class _SnakesAndLaddersPainter extends CustomPainter {
  final int p1Pos;
  final int p2Pos;
  final Map<int, int> snakes;
  final Map<int, int> ladders;
  final StationeryTheme theme;

  _SnakesAndLaddersPainter({
    required this.p1Pos,
    required this.p2Pos,
    required this.snakes,
    required this.ladders,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 10.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int r = 9; r >= 0; r--) {
      final isEven = (r % 2 == 0);
      for (int c = 0; c < 10; c++) {
        final actualCol = isEven ? (9 - c) : c;
        final cellNum = r * 10 + actualCol + 1;
        final cellRect = Rect.fromLTWH(c * cell, (9 - r) * cell, cell, cell);

        Color cellColor = cellNum % 2 == 0 ? theme.bg : theme.cardBg;
        if (snakes.containsKey(cellNum)) cellColor = const Color(0xFFFFEAEA);
        if (ladders.containsKey(cellNum)) cellColor = const Color(0xFFEAFFEA);
        if (cellNum == 100) cellColor = const Color(0xFFFFF3CD);

        canvas.drawRect(cellRect, Paint()..color = cellColor);
        canvas.drawRect(cellRect, Paint()..color = Colors.black12..style = PaintingStyle.stroke);

        textPainter.text = TextSpan(
          text: '$cellNum',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(cellRect.left + 2, cellRect.top + 2));

        if (snakes.containsKey(cellNum)) {
          textPainter.text = TextSpan(
            text: '🐍${snakes[cellNum]}',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFE74C3C)),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(cellRect.left + 2, cellRect.bottom - 12));
        } else if (ladders.containsKey(cellNum)) {
          textPainter.text = TextSpan(
            text: '🪜${ladders[cellNum]}',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(cellRect.left + 2, cellRect.bottom - 12));
        }
      }
    }

    _drawPawn(canvas, p1Pos, cell, const Color(0xFFE74C3C), -3);
    _drawPawn(canvas, p2Pos, cell, const Color(0xFF2980B9), 3);
  }

  void _drawPawn(Canvas canvas, int num, double cell, Color col, double shift) {
    if (num < 1 || num > 100) return;
    int idx = num - 1;
    int r = idx ~/ 10;
    int c = idx % 10;
    int actualCol = (r % 2 == 0) ? c : (9 - c);
    double x = (actualCol + 0.5) * cell + shift;
    double y = (9 - r + 0.5) * cell;

    canvas.drawCircle(Offset(x, y), cell * 0.28, Paint()..color = col);
    canvas.drawCircle(Offset(x, y), cell * 0.12, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SnakesAndLaddersPainter old) => true;
}

class _TetrisBoardPainter extends CustomPainter {
  final List<List<Color?>> grid;
  final List<List<int>> currentMatrix;
  final int pieceX;
  final int pieceY;
  final Color pieceColor;
  final int rows;
  final int cols;

  _TetrisBoardPainter({
    required this.grid,
    required this.currentMatrix,
    required this.pieceX,
    required this.pieceY,
    required this.pieceColor,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final blockW = size.width / cols;
    final blockH = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final col = grid[r][c];
        final rect = Rect.fromLTWH(c * blockW + 1, r * blockH + 1, blockW - 2, blockH - 2);
        if (col != null) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), Paint()..color = col);
        } else {
          canvas.drawRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.03));
        }
      }
    }

    for (int r = 0; r < currentMatrix.length; r++) {
      for (int c = 0; c < currentMatrix[r].length; c++) {
        if (currentMatrix[r][c] == 1) {
          int gx = pieceX + c;
          int gy = pieceY + r;
          if (gy >= 0 && gy < rows && gx >= 0 && gx < cols) {
            final rect = Rect.fromLTWH(gx * blockW + 1, gy * blockH + 1, blockW - 2, blockH - 2);
            canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), Paint()..color = pieceColor);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TetrisBoardPainter old) => true;
}
