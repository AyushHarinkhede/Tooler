// Complete & Polished Game Suite for Tooler (Tic-Tac-Toe, Snake Pro, Real Ludo, Snakes & Ladders, UNO Cards, Tetris)
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../widgets_3d/tooler_character.dart';

enum GameType { tictactoe, snake, ludo, snakesAndLadders, uno, tetris }
enum GameOutcome { win, lose, draw }

class GamesScreen extends StatefulWidget {
  final StationeryTheme theme;
  const GamesScreen({super.key, required this.theme});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with TickerProviderStateMixin {
  GameType _activeGame = GameType.tictactoe;
  bool _isOptionsExpanded = false;

  late AnimationController _ludoHopController;
  double _ludoHopProgress = 0.0;
  int _ludoAnimFromStep = -1;
  int _ludoAnimToStep = 0;

  String? _unoBotPlayToast;
  Timer? _unoToastTimer;

  @override
  void initState() {
    super.initState();
    _initSnakeHigh();
    _initTetrisHigh();
    _unoFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _ludoHopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
    )..addListener(() {
        setState(() {
          _ludoHopProgress = _ludoHopController.value;
        });
      });
  }

  @override
  void dispose() {
    _snakeTimer?.cancel();
    _tetrisTimer?.cancel();
    _ludoBotTimer?.cancel();
    _ludoStepTimer?.cancel();
    _snlBotTimer?.cancel();
    _unoBotTimer?.cancel();
    _unoToastTimer?.cancel();
    _unoFlyController?.dispose();
    _ludoHopController.dispose();
    super.dispose();
  }

  // =========================================================================
  // 1. TIC-TAC-TOE STATE & UNBEATABLE MINIMAX ENGINE
  // =========================================================================
  List<String> _tttBoard = List.filled(9, '');
  bool _isPlayerTurn = true;
  bool _vsComputer = true;
  String _playerSymbol = 'X'; // 'X' or 'O'
  String _tttSymbolStyle = 'classic'; // 'classic' or 'stationery'
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

        Timer(const Duration(milliseconds: 320), () {
          if (!mounted) return;
          if (_vsComputer) {
            if (_tttWinner == _playerSymbol) {
              _showGameResultModal(
                outcome: GameOutcome.win,
                title: 'VICTORY!',
                subtitle: 'Outstanding strategy! You defeated the AI!',
                statTitle: 'Winning Symbol',
                statValue: _playerSymbol,
                secondaryStat: 'X: $_xScore | O: $_oScore',
                onPlayAgain: _resetTtt,
              );
            } else {
              _showGameResultModal(
                outcome: GameOutcome.lose,
                title: 'AI WON',
                subtitle: 'The computer secured the 3-in-a-row!',
                statTitle: 'Winning Symbol',
                statValue: _aiSymbol,
                secondaryStat: 'X: $_xScore | O: $_oScore',
                onPlayAgain: _resetTtt,
              );
            }
          } else {
            _showGameResultModal(
              outcome: GameOutcome.win,
              title: 'PLAYER $_tttWinner WINS!',
              subtitle: 'Superb 3-in-a-row match victory!',
              statTitle: 'Winner',
              statValue: 'Player $_tttWinner',
              secondaryStat: 'X: $_xScore | O: $_oScore',
              onPlayAgain: _resetTtt,
            );
          }
        });
        return;
      }
    }

    if (!_tttBoard.contains('')) {
      _tttWinner = 'Draw';
      _drawScore++;
      Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        _showGameResultModal(
          outcome: GameOutcome.draw,
          title: "IT'S A DRAW!",
          subtitle: 'Well played! Both sides defended with full focus.',
          statTitle: 'Total Draws',
          statValue: '$_drawScore',
          secondaryStat: 'X: $_xScore | O: $_oScore',
          onPlayAgain: _resetTtt,
        );
      });
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
  String _snakeSkin = 'theme'; // 'theme', 'green', 'cyan', 'gold', 'pink'
  String _snakeDifficulty = 'normal'; // 'casual', 'normal', 'insane'
  int _snakeScore = 0;
  int _snakeHighScore = 0;

  int get _snakeSpeedMs {
    switch (_snakeDifficulty) {
      case 'casual':
        return 175;
      case 'insane':
        return 95;
      case 'normal':
      default:
        return 130;
    }
  }

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

      if (newHead.x < 0 || newHead.x >= _snakeCols || newHead.y < 0 || newHead.y >= _snakeRows) {
        _onSnakeGameOver();
        return;
      }

      if (_snake.contains(newHead)) {
        _onSnakeGameOver();
        return;
      }

      _snake.insert(0, newHead);

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
    final isNewHigh = _snakeScore > _snakeHighScore;
    _saveSnakeHigh();

    Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _showGameResultModal(
        outcome: isNewHigh ? GameOutcome.win : GameOutcome.lose,
        title: isNewHigh ? 'NEW HIGH SCORE!' : 'GAME OVER',
        subtitle: isNewHigh
            ? 'Awesome reflexes! You set a brand-new high score record!'
            : 'The snake hit a wall or ran into itself!',
        statTitle: 'Your Score',
        statValue: '$_snakeScore pts',
        secondaryStat: 'Best: $_snakeHighScore pts',
        onPlayAgain: _resetSnake,
      );
    });
  }

  // =========================================================================
  // 3. REAL LUDO STATE & MULTI-PLAYER / BOT ENGINE
  // =========================================================================
  static const List<int> _ludoSafeStars = [0, 8, 13, 21, 26, 34, 39, 47];
  static const List<Color> _ludoPlayerColors = [
    Color(0xFFE74C3C), // Red
    Color(0xFF27AE60), // Green
    Color(0xFFF39C12), // Yellow
    Color(0xFF2980B9), // Blue
  ];
  static const List<String> _ludoBaseNames = ['Red', 'Green', 'Yellow', 'Blue'];

  int _ludoHumanPlayer = 0; // 0=Red, 1=Green, 2=Yellow, 3=Blue
  int _ludoBotSpeedMs = 600;

  List<String> get _ludoPlayerNames => List.generate(4, (i) {
        final base = _ludoBaseNames[i];
        return i == _ludoHumanPlayer ? '$base (You)' : '$base (Bot)';
      });

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
  bool _ludoIsAnimatingMove = false;
  int? _animatingLudoPlayer;
  int? _animatingLudoToken;
  Timer? _ludoStepTimer;
  Timer? _ludoBotTimer;
  String? _ludoWinner;

  void _resetLudo() {
    SoundService().playClick();
    _ludoBotTimer?.cancel();
    _ludoStepTimer?.cancel();
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
      _ludoIsAnimatingMove = false;
      _animatingLudoPlayer = null;
      _animatingLudoToken = null;
      _ludoHopProgress = 0.0;
      _ludoAnimFromStep = -1;
      _ludoAnimToStep = 0;
      _ludoWinner = null;
    });

    if (_ludoCurrentTurn != _ludoHumanPlayer) {
      _ludoBotTimer = Timer(Duration(milliseconds: _ludoBotSpeedMs), () {
        if (mounted) _executeLudoRoll();
      });
    }
  }

  bool _canLudoTokenMove(int pIdx, int tIdx) {
    if (!_ludoHasRolled || _ludoIsAnimatingMove) return false;
    final step = _ludoTokens[pIdx][tIdx];
    if (step == -1) return _ludoDiceVal == 6;
    if (step == 56) return false;
    return (step + _ludoDiceVal) <= 56;
  }

  void _rollLudoDice() {
    if (_ludoHasRolled || _ludoIsRolling || _ludoIsAnimatingMove || _ludoWinner != null) return;
    if (_ludoCurrentTurn != _ludoHumanPlayer) return;
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
      Timer(Duration(milliseconds: _ludoBotSpeedMs), () {
        if (mounted) _nextLudoTurn();
      });
    } else if (movable.length == 1 && _ludoCurrentTurn == _ludoHumanPlayer) {
      Timer(const Duration(milliseconds: 250), () {
        if (mounted && _ludoHasRolled) _moveLudoToken(_ludoCurrentTurn, movable.first);
      });
    } else if (_ludoCurrentTurn != _ludoHumanPlayer) {
      _ludoBotTimer = Timer(Duration(milliseconds: _ludoBotSpeedMs), () {
        if (!mounted) return;
        final chosen = _pickBestLudoMove(movable);
        _moveLudoToken(_ludoCurrentTurn, chosen);
      });
    }
  }

  int _pickBestLudoMove(List<int> movable) {
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
    if (_ludoDiceVal == 6) {
      for (final t in movable) {
        if (_ludoTokens[_ludoCurrentTurn][t] == -1) return t;
      }
    }
    for (final t in movable) {
      final step = _ludoTokens[_ludoCurrentTurn][t];
      if (step + _ludoDiceVal == 56) return t;
    }
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
    if (!_ludoHasRolled || _ludoIsAnimatingMove) return;

    final currentStep = _ludoTokens[pIdx][tIdx];
    final targetStep = currentStep == -1 ? 0 : (currentStep + _ludoDiceVal);

    setState(() {
      _ludoIsAnimatingMove = true;
      _animatingLudoPlayer = pIdx;
      _animatingLudoToken = tIdx;
      _ludoHasRolled = false;
    });

    _animateLudoSingleHop(pIdx, tIdx, currentStep, targetStep);
  }

  void _animateLudoSingleHop(int pIdx, int tIdx, int step, int finalTargetStep) {
    if (step >= finalTargetStep) {
      setState(() {
        _ludoTokens[pIdx][tIdx] = finalTargetStep;
        _ludoIsAnimatingMove = false;
        _animatingLudoPlayer = null;
        _animatingLudoToken = null;
        _ludoHopProgress = 0.0;
      });
      _finalizeLudoTurn(pIdx, tIdx, finalTargetStep, bonusOnSix: true);
      return;
    }

    final nextStep = (step == -1) ? 0 : (step + 1);
    _ludoAnimFromStep = step;
    _ludoAnimToStep = nextStep;
    _ludoHopProgress = 0.0;
    _ludoHopController.reset();

    SoundService().playKey();
    _ludoHopController.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _ludoTokens[pIdx][tIdx] = nextStep;
      });
      _animateLudoSingleHop(pIdx, tIdx, nextStep, finalTargetStep);
    });
  }

  void _finalizeLudoTurn(int pIdx, int tIdx, int targetStep, {required bool bonusOnSix}) {
    bool getsBonusRoll = (bonusOnSix && _ludoDiceVal == 6);

    if (targetStep == 56) {
      getsBonusRoll = true;
      if (_ludoTokens[pIdx].every((s) => s == 56)) {
        _ludoWinner = _ludoPlayerNames[pIdx];
        SoundService().playSuccess();
        final isHumanWin = (pIdx == _ludoHumanPlayer);
        Timer(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _showGameResultModal(
            outcome: isHumanWin ? GameOutcome.win : GameOutcome.lose,
            title: isHumanWin ? 'LUDO VICTORY!' : 'LUDO OVER',
            subtitle: isHumanWin
                ? 'Congratulations! You brought all 4 tokens Home to victory!'
                : '${_ludoPlayerNames[pIdx]} brought all tokens home first!',
            statTitle: 'Winner',
            statValue: _ludoPlayerNames[pIdx],
            onPlayAgain: _resetLudo,
          );
        });
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
                _ludoTokens[enemy][et] = -1;
                getsBonusRoll = true;
                SoundService().playSuccess();
              }
            }
          }
        }
      }
    }

    if (getsBonusRoll && _ludoWinner == null) {
      if (_ludoCurrentTurn != _ludoHumanPlayer) {
        _ludoBotTimer = Timer(Duration(milliseconds: _ludoBotSpeedMs), () {
          if (mounted) _executeLudoRoll();
        });
      }
    } else {
      _nextLudoTurn();
    }
  }

  void _nextLudoTurn() {
    setState(() {
      _ludoHasRolled = false;
      _ludoCurrentTurn = (_ludoCurrentTurn + 1) % 4;
    });

    if (_ludoCurrentTurn != _ludoHumanPlayer && _ludoWinner == null) {
      _ludoBotTimer = Timer(Duration(milliseconds: _ludoBotSpeedMs), () {
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
  static const List<Map<String, dynamic>> _snlPawns = [
    {'name': 'Pencil', 'icon': Icons.edit_rounded, 'color': Color(0xFFE74C3C)},
    {'name': 'Ruler', 'icon': Icons.straighten_rounded, 'color': Color(0xFF2980B9)},
    {'name': 'Eraser', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFF27AE60)},
    {'name': 'Compass', 'icon': Icons.explore_rounded, 'color': Color(0xFF8E44AD)},
  ];

  int _snlPlayerPawn = 0; // 0=Pencil, 1=Ruler, 2=Eraser, 3=Compass
  int _snlFirstTurn = 1; // 1 = Human, 2 = Bot
  int _snlP1Pos = 1;
  int _snlP2Pos = 1;
  int _snlTurn = 1;
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
      _snlTurn = _snlFirstTurn;
      _snlDice = 1;
      _snlIsRolling = false;
      _snlStatus = _snlTurn == 1 ? 'New Game Started! Your Turn.' : 'New Game Started! Bot Turn.';
    });

    if (_snlTurn == 2) {
      _snlBotTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) _executeSnlRoll();
      });
    }
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
      Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _showGameResultModal(
          outcome: isP1 ? GameOutcome.win : GameOutcome.lose,
          title: isP1 ? 'YOU WON!' : 'BOT WON!',
          subtitle: isP1
              ? 'Incredible climb! You scaled the board to Square 100!'
              : 'The bot dodged all snakes and reached Square 100 first!',
          statTitle: 'Status',
          statValue: isP1 ? 'You reached Sq 100' : 'Bot reached Sq 100',
          secondaryStat: isP1 ? 'Bot at Sq $_snlP2Pos' : 'You at Sq $_snlP1Pos',
          onPlayAgain: _resetSnl,
        );
      });
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
  String _unoPlayerAvatar = 'Scholar';
  String _unoDifficulty = 'normal';
  AnimationController? _unoFlyController;
  Animation<Offset>? _unoFlyOffsetAnimation;
  Animation<double>? _unoFlyScaleAnimation;
  Animation<double>? _unoFlyRotateAnimation;
  Map<String, String>? _unoFlyingCard;
  bool _unoIsAnimatingCard = false;

  void _initUno() {
    _unoBotTimer?.cancel();
    _unoDeck = _generateUnoDeck();
    _unoDeck.shuffle();
    _unoPlayerHand = _unoDeck.sublist(0, 7);
    _unoBotHand = _unoDeck.sublist(7, 14);
    _unoDeck.removeRange(0, 14);

    int startIdx = _unoDeck.indexWhere((c) => c['color'] != 'wild' && !['SKIP', 'REVERSE', '+2'].contains(c['value']));
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
      deck.add({'color': c, 'value': '0'});
      for (int i = 1; i <= 9; i++) {
        deck.add({'color': c, 'value': '$i'});
        deck.add({'color': c, 'value': '$i'});
      }
      for (final action in ['SKIP', 'REVERSE', '+2']) {
        deck.add({'color': c, 'value': action});
        deck.add({'color': c, 'value': action});
      }
    }
    for (int i = 0; i < 4; i++) {
      deck.add({'color': 'wild', 'value': 'WILD'});
      deck.add({'color': 'wild', 'value': '+4'});
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
    if (_unoCurrentTurn != 'player' || _unoIsAnimatingCard) return;
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
    if (_unoIsAnimatingCard) return;

    final hand = isPlayer ? _unoPlayerHand : _unoBotHand;
    final card = hand.removeAt(cardIdx);

    _animateCardToDiscard(card, chosenColor, isPlayer, () {
      setState(() {
        if (hand.isEmpty) {
          _unoStatusMsg = isPlayer ? 'Congratulations! You emptied your hand and Won UNO!' : 'Bot Won UNO!';
          SoundService().playSuccess();
          Timer(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            _showGameResultModal(
              outcome: isPlayer ? GameOutcome.win : GameOutcome.lose,
              title: isPlayer ? 'UNO CHAMPION!' : 'BOT WON UNO',
              subtitle: isPlayer
                  ? 'Superb! You emptied all cards from your hand!'
                  : 'The bot played its last card before you!',
              statTitle: 'Hand Status',
              statValue: isPlayer ? '0 Cards (Victory)' : '${_unoPlayerHand.length} cards remaining',
              secondaryStat: 'Bot Cards: ${_unoBotHand.length}',
              onPlayAgain: () => setState(() => _initUno()),
            );
          });
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
        } else if (val == 'SKIP' || val == 'REVERSE') {
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
    });
  }

  void _animateCardToDiscard(Map<String, String> card, String chosenColor, bool isPlayer, VoidCallback onFinish) {
    setState(() {
      _unoFlyingCard = card;
      _unoIsAnimatingCard = true;
    });
    SoundService().playKey();

    final startOffset = isPlayer ? const Offset(0.0, 1.8) : const Offset(0.0, -1.8);
    _unoFlyOffsetAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _unoFlyController!, curve: Curves.easeOutCubic));

    _unoFlyScaleAnimation = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _unoFlyController!, curve: Curves.easeOutBack));

    _unoFlyRotateAnimation = Tween<double>(
      begin: isPlayer ? -0.22 : 0.25,
      end: (math.Random().nextDouble() - 0.5) * 0.1,
    ).animate(CurvedAnimation(parent: _unoFlyController!, curve: Curves.easeOutQuad));

    _unoFlyController!.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _unoTopCard = card;
        _unoActiveColor = chosenColor;
        _unoFlyingCard = null;
        _unoIsAnimatingCard = false;
      });
      onFinish();
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

  void _triggerUnoBotPlayToast(Map<String, String> card, String chosenColor) {
    final val = card['value'] ?? '';
    final colorStr = chosenColor.toUpperCase();
    setState(() {
      _unoBotPlayToast = 'Opponent played $colorStr $val!';
    });
    _unoToastTimer?.cancel();
    _unoToastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _unoBotPlayToast = null);
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
        _triggerUnoBotPlayToast(drawn, chosenColor);
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
        if (['+2', '+4', 'SKIP'].contains(_unoBotHand[idx]['value'])) {
          chosen = idx;
          break;
        }
      }
      final card = _unoBotHand[chosen];
      final chosenColor = card['color'] == 'wild' ? _getBotBestColor() : card['color']!;
      _triggerUnoBotPlayToast(card, chosenColor);
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
  String _tetrisPalette = 'theme';
  int _tetrisStartLevel = 1;

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
      _tetrisLevel = _tetrisStartLevel;
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
      final isNewHigh = _tetrisScore > _tetrisHighScore;
      _saveTetrisHigh();

      Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _showGameResultModal(
          outcome: isNewHigh ? GameOutcome.win : GameOutcome.lose,
          title: isNewHigh ? 'NEW HIGH SCORE!' : 'GAME OVER',
          subtitle: isNewHigh
              ? 'Sensational stacking! You set a new Tetris record!'
              : 'The blocks reached the top of the grid!',
          statTitle: 'Score / Lines',
          statValue: '$_tetrisScore pts ($_tetrisLines lines)',
          secondaryStat: 'Best: $_tetrisHighScore pts',
          onPlayAgain: _resetTetris,
        );
      });
      return;
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

    if (!_isPieceColliding(_currentPieceMatrix, _pieceX, _pieceY + 1)) {
      setState(() {
        _pieceY++;
      });
    } else {
      _lockTetrisPiece();
    }
  }

  void _lockTetrisPiece() {
    final pieceColor = _getTetrisColor(_currentPieceType);
    setState(() {
      for (int r = 0; r < _currentPieceMatrix.length; r++) {
        for (int c = 0; c < _currentPieceMatrix[r].length; c++) {
          if (_currentPieceMatrix[r][c] == 1) {
            int gx = _pieceX + c;
            int gy = _pieceY + r;
            if (gy >= 0 && gy < _tetrisRows && gx >= 0 && gx < _tetrisCols) {
              _tetrisGrid[gy][gx] = pieceColor;
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
        final basePoints = [0, 100, 300, 500, 800];
        _tetrisScore += basePoints[linesCleared] * _tetrisLevel;
        _tetrisLevel = (_tetrisLines ~/ 10) + 1;
        _saveTetrisHigh();
      } else {
        SoundService().playKey();
      }

      _spawnTetrisPiece();
    });
  }

  Color _getTetrisColor(String type) {
    if (_tetrisPalette == 'theme') {
      final tints = [
        widget.theme.primary,
        widget.theme.primary.withValues(alpha: 0.85),
        const Color(0xFFF39C12),
        const Color(0xFF27AE60),
        const Color(0xFF2980B9),
        const Color(0xFF8E44AD),
        const Color(0xFFE74C3C),
      ];
      final idx = ['I', 'J', 'L', 'O', 'S', 'T', 'Z'].indexOf(type);
      return tints[idx >= 0 ? idx : 0];
    } else if (_tetrisPalette == 'neon') {
      return _tetrominoColors[type] ?? Colors.white;
    } else {
      final pastel = {
        'I': const Color(0xFF81ECEC),
        'J': const Color(0xFF74B9FF),
        'L': const Color(0xFFFFEAA7),
        'O': const Color(0xFFFDCB6E),
        'S': const Color(0xFF55EFC4),
        'T': const Color(0xFFA29BFE),
        'Z': const Color(0xFFFF7675),
      };
      return pastel[type] ?? Colors.white;
    }
  }

  void _moveTetris(int dx) {
    if (!_isTetrisRunning) return;
    if (!_isPieceColliding(_currentPieceMatrix, _pieceX + dx, _pieceY)) {
      SoundService().playClick();
      setState(() {
        _pieceX += dx;
      });
    }
  }

  void _rotateTetris() {
    if (!_isTetrisRunning) return;
    final r = _currentPieceMatrix.length;
    final c = _currentPieceMatrix[0].length;
    final rotated = List.generate(c, (i) => List.generate(r, (j) => _currentPieceMatrix[r - 1 - j][i]));

    if (!_isPieceColliding(rotated, _pieceX, _pieceY)) {
      SoundService().playKey();
      setState(() {
        _currentPieceMatrix = rotated;
      });
    } else if (!_isPieceColliding(rotated, _pieceX - 1, _pieceY)) {
      SoundService().playKey();
      setState(() {
        _pieceX -= 1;
        _currentPieceMatrix = rotated;
      });
    } else if (!_isPieceColliding(rotated, _pieceX + 1, _pieceY)) {
      SoundService().playKey();
      setState(() {
        _pieceX += 1;
        _currentPieceMatrix = rotated;
      });
    }
  }

  void _hardDropTetris() {
    if (!_isTetrisRunning) return;
    SoundService().playKey();
    while (!_isPieceColliding(_currentPieceMatrix, _pieceX, _pieceY + 1)) {
      _pieceY++;
      _tetrisScore += 2;
    }
    _lockTetrisPiece();
  }

  // =========================================================================
  // RESULT MODAL & SVG THEME PAINTERS
  // =========================================================================
  void _showGameResultModal({
    required GameOutcome outcome,
    required String title,
    required String subtitle,
    required String statTitle,
    required String statValue,
    String? secondaryStat,
    required VoidCallback onPlayAgain,
  }) {
    if (!mounted) return;
    if (outcome == GameOutcome.win) {
      SoundService().playSuccess();
    } else {
      SoundService().playAlert();
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Color bannerColor;
        CustomPainter painter;
        switch (outcome) {
          case GameOutcome.win:
            bannerColor = const Color(0xFFF39C12);
            painter = _WinResultPainter(primaryColor: widget.theme.primary);
            break;
          case GameOutcome.lose:
            bannerColor = const Color(0xFFE74C3C);
            painter = _LoseResultPainter(primaryColor: widget.theme.primary);
            break;
          case GameOutcome.draw:
            bannerColor = widget.theme.primary;
            painter = _DrawResultPainter(primaryColor: widget.theme.primary);
            break;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: widget.theme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.theme.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  offset: const Offset(4, 8),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ToolerCharacter(
                  pose: outcome == GameOutcome.win
                      ? ToolerCharacterPose.celebratingSuccess
                      : (outcome == GameOutcome.lose
                          ? ToolerCharacterPose.tabletThinking
                          : ToolerCharacterPose.brainstormStickyWall),
                  theme: widget.theme,
                  width: 140,
                  height: 105,
                  animate: true,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 130,
                  height: 70,
                  child: CustomPaint(painter: painter),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: widget.theme.fontDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.theme.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.theme.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.textSecondary,
                            ),
                          ),
                          Text(
                            statValue,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (secondaryStat != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Scoreboard / Best:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.theme.textSecondary,
                              ),
                            ),
                            Text(
                              secondaryStat,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF39C12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: widget.theme.border, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: widget.theme.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onPlayAgain();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Play Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // MAIN BUILD METHOD & TABS
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: _buildActiveGameView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTabBar() {
    final games = [
      {'type': GameType.tictactoe, 'label': 'Tic-Tac-Toe', 'icon': Icons.grid_3x3_rounded},
      {'type': GameType.snake, 'label': 'Snake Pro', 'icon': Icons.gesture_rounded},
      {'type': GameType.ludo, 'label': 'Real Ludo', 'icon': Icons.casino_rounded},
      {'type': GameType.snakesAndLadders, 'label': 'Snake & Ladder', 'icon': Icons.stairs_rounded},
      {'type': GameType.uno, 'label': 'UNO Cards', 'icon': Icons.style_rounded},
      {'type': GameType.tetris, 'label': 'Tetris', 'icon': Icons.view_quilt_rounded},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 4, bottom: 6),
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
                _isOptionsExpanded = false;
                if (_activeGame == GameType.uno && _unoDeck.isEmpty) _initUno();
                if (_activeGame == GameType.tetris && _tetrisGrid.isEmpty) _resetTetris();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    g['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : widget.theme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    g['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : widget.theme.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getGameOptionsSummary() {
    switch (_activeGame) {
      case GameType.tictactoe:
        return 'Playing as $_playerSymbol | ${_vsComputer ? "vs AI (${_aiDifficulty.toUpperCase()})" : "2 Players"}';
      case GameType.snake:
        return 'Skin: $_snakeSkin | Speed: $_snakeDifficulty';
      case GameType.ludo:
        return 'Color: ${_ludoPlayerNames[_ludoHumanPlayer]} | Pace: ${_ludoBotSpeedMs}ms';
      case GameType.snakesAndLadders:
        return 'Pawn: ${_snlPawns[_snlPlayerPawn]["name"]} | ${_snlFirstTurn == 1 ? "You first" : "Bot first"}';
      case GameType.uno:
        return 'Persona: $_unoPlayerAvatar | Bot: $_unoDifficulty';
      case GameType.tetris:
        return 'Palette: $_tetrisPalette | Level: $_tetrisStartLevel';
    }
  }

  /// Collapsible Options Header Bar for EVERY game
  Widget _buildGameOptionsHeader() {
    final summary = _getGameOptionsSummary();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              SoundService().playClick();
              setState(() {
                _isOptionsExpanded = !_isOptionsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: widget.theme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isOptionsExpanded ? widget.theme.primary : widget.theme.border,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(1, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.theme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isOptionsExpanded ? Icons.tune_rounded : Icons.settings_rounded,
                      size: 16,
                      color: widget.theme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOptionsExpanded ? 'Hide Options & Settings' : 'Game Options & Player Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: widget.theme.text,
                          ),
                        ),
                        if (!_isOptionsExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.theme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isOptionsExpanded
                          ? widget.theme.primary
                          : widget.theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isOptionsExpanded ? 'Hide' : 'Options',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isOptionsExpanded ? Colors.white : widget.theme.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          _isOptionsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: _isOptionsExpanded ? Colors.white : widget.theme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.theme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.theme.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(2, 4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: _buildCurrentGameOptionsContent(),
            ),
            crossFadeState: _isOptionsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentGameOptionsContent() {
    switch (_activeGame) {
      case GameType.tictactoe:
        return _buildTttOptions();
      case GameType.snake:
        return _buildSnakeOptions();
      case GameType.ludo:
        return _buildLudoOptions();
      case GameType.snakesAndLadders:
        return _buildSnlOptions();
      case GameType.uno:
        return _buildUnoOptions();
      case GameType.tetris:
        return _buildTetrisOptions();
    }
  }

  // --- TIC TAC TOE OPTIONS ---
  Widget _buildTttOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Game Mode & Opponent:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildChoiceChip('vs Computer', _vsComputer, () {
              setState(() {
                _vsComputer = true;
                _resetTtt();
              });
            }),
            const SizedBox(width: 8),
            _buildChoiceChip('2 Players', !_vsComputer, () {
              setState(() {
                _vsComputer = false;
                _resetTtt();
              });
            }),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Select Your Player Symbol:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildChoiceChip('Play as X (First)', _playerSymbol == 'X', () {
              setState(() {
                _playerSymbol = 'X';
                _resetTtt();
              });
            }),
            const SizedBox(width: 8),
            _buildChoiceChip('Play as O (Second)', _playerSymbol == 'O', () {
              setState(() {
                _playerSymbol = 'O';
                _resetTtt();
              });
            }),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Mark Style:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildChoiceChip('Classic (X / O)', _tttSymbolStyle == 'classic', () {
              setState(() => _tttSymbolStyle = 'classic');
            }),
            const SizedBox(width: 8),
            _buildChoiceChip('Stationery (Pencil / Eraser)', _tttSymbolStyle == 'stationery', () {
              setState(() => _tttSymbolStyle = 'stationery');
            }),
          ],
        ),
        if (_vsComputer) ...[
          const SizedBox(height: 10),
          const Text('AI Difficulty Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildChoiceChip('Easy', _aiDifficulty == 'easy', () => setState(() => _aiDifficulty = 'easy')),
              const SizedBox(width: 6),
              _buildChoiceChip('Medium', _aiDifficulty == 'medium', () => setState(() => _aiDifficulty = 'medium')),
              const SizedBox(width: 6),
              _buildChoiceChip('Unbeatable', _aiDifficulty == 'unbeatable', () => setState(() => _aiDifficulty = 'unbeatable')),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetTtt,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text('Restart Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetTttScores,
                icon: Icon(Icons.delete_outline, size: 16, color: widget.theme.text),
                label: Text('Reset Scores', style: TextStyle(color: widget.theme.text, fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.theme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- SNAKE OPTIONS ---
  Widget _buildSnakeOptions() {
    final skins = [
      {'id': 'theme', 'name': 'Theme Accent'},
      {'id': 'green', 'name': 'Emerald Viper'},
      {'id': 'cyan', 'name': 'Neon Cyan'},
      {'id': 'gold', 'name': 'Golden Python'},
      {'id': 'pink', 'name': 'Coral Pink'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Your Snake Skin:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skins.map((s) {
            return _buildChoiceChip(
              s['name']!,
              _snakeSkin == s['id'],
              () => setState(() => _snakeSkin = s['id']!),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text('Speed & Reflex Challenge:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildChoiceChip('Casual (Slow)', _snakeDifficulty == 'casual', () {
              setState(() {
                _snakeDifficulty = 'casual';
                if (_isSnakeRunning) _startSnake();
              });
            }),
            const SizedBox(width: 6),
            _buildChoiceChip('Normal (Classic)', _snakeDifficulty == 'normal', () {
              setState(() {
                _snakeDifficulty = 'normal';
                if (_isSnakeRunning) _startSnake();
              });
            }),
            const SizedBox(width: 6),
            _buildChoiceChip('Insane (Turbo)', _snakeDifficulty == 'insane', () {
              setState(() {
                _snakeDifficulty = 'insane';
                if (_isSnakeRunning) _startSnake();
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetSnake,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text('Reset Snake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- LUDO OPTIONS ---
  Widget _buildLudoOptions() {
    final colors = [
      {'idx': 0, 'label': 'Red (You)', 'color': const Color(0xFFE74C3C)},
      {'idx': 1, 'label': 'Green (You)', 'color': const Color(0xFF27AE60)},
      {'idx': 2, 'label': 'Yellow (You)', 'color': const Color(0xFFF39C12)},
      {'idx': 3, 'label': 'Blue (You)', 'color': const Color(0xFF2980B9)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Your Player Color (Other 3 become Bots):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: colors.map((c) {
            final isChosen = _ludoHumanPlayer == c['idx'];
            return GestureDetector(
              onTap: () {
                SoundService().playClick();
                setState(() {
                  _ludoHumanPlayer = c['idx'] as int;
                  _resetLudo();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isChosen ? (c['color'] as Color).withValues(alpha: 0.15) : widget.theme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChosen ? (c['color'] as Color) : widget.theme.border,
                    width: isChosen ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: c['color'] as Color),
                    const SizedBox(width: 6),
                    Text(
                      c['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isChosen ? (c['color'] as Color) : widget.theme.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text('Bot Roll Pace:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildChoiceChip('Fast (400ms)', _ludoBotSpeedMs == 400, () => setState(() => _ludoBotSpeedMs = 400)),
            const SizedBox(width: 6),
            _buildChoiceChip('Normal (600ms)', _ludoBotSpeedMs == 600, () => setState(() => _ludoBotSpeedMs = 600)),
            const SizedBox(width: 6),
            _buildChoiceChip('Slow (900ms)', _ludoBotSpeedMs == 900, () => setState(() => _ludoBotSpeedMs = 900)),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _resetLudo,
          icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
          label: const Text('Start New Match', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // --- SNAKES & LADDERS OPTIONS ---
  Widget _buildSnlOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Your Pawn Mascot:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: List.generate(_snlPawns.length, (idx) {
            final p = _snlPawns[idx];
            final isSelected = _snlPlayerPawn == idx;
            return GestureDetector(
              onTap: () {
                SoundService().playClick();
                setState(() => _snlPlayerPawn = idx);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? (p['color'] as Color).withValues(alpha: 0.15) : widget.theme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? (p['color'] as Color) : widget.theme.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p['icon'] as IconData, size: 16, color: isSelected ? (p['color'] as Color) : widget.theme.text),
                    const SizedBox(width: 6),
                    Text(
                      p['name'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? (p['color'] as Color) : widget.theme.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        const Text('Opening Turn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildChoiceChip('You Go First', _snlFirstTurn == 1, () {
              setState(() {
                _snlFirstTurn = 1;
                _resetSnl();
              });
            }),
            const SizedBox(width: 8),
            _buildChoiceChip('Bot Goes First', _snlFirstTurn == 2, () {
              setState(() {
                _snlFirstTurn = 2;
                _resetSnl();
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _resetSnl,
          icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
          label: const Text('Reset Game', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // --- UNO OPTIONS ---
  Widget _buildUnoOptions() {
    final avatars = [
      {'name': 'Scholar', 'icon': Icons.school_rounded},
      {'name': 'Artist', 'icon': Icons.palette_rounded},
      {'name': 'Speedster', 'icon': Icons.bolt_rounded},
      {'name': 'Champion', 'icon': Icons.emoji_events_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Your Player Persona:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: avatars.map((a) {
            final isChosen = _unoPlayerAvatar == a['name'];
            return GestureDetector(
              onTap: () {
                SoundService().playClick();
                setState(() => _unoPlayerAvatar = a['name'] as String);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isChosen ? widget.theme.primary : widget.theme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChosen ? widget.theme.primary : widget.theme.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      a['icon'] as IconData,
                      size: 15,
                      color: isChosen ? Colors.white : widget.theme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      a['name'] as String,
                      style: TextStyle(
                        color: isChosen ? Colors.white : widget.theme.text,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text('Bot Playing Style:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildChoiceChip('Normal (Casual)', _unoDifficulty == 'normal', () => setState(() => _unoDifficulty = 'normal')),
            const SizedBox(width: 8),
            _buildChoiceChip('Challenger (Aggressive)', _unoDifficulty == 'challenger', () => setState(() => _unoDifficulty = 'challenger')),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() => _initUno()),
          icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
          label: const Text('Deal New Hand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // --- TETRIS OPTIONS ---
  Widget _buildTetrisOptions() {
    final palettes = [
      {'id': 'theme', 'name': 'Theme Accent'},
      {'id': 'neon', 'name': 'Arcade Neon'},
      {'id': 'pastel', 'name': 'Pastel Modern'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Block Palette:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: palettes.map((p) {
            return _buildChoiceChip(
              p['name']!,
              _tetrisPalette == p['id'],
              () => setState(() => _tetrisPalette = p['id']!),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text('Starting Speed Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildChoiceChip('Level 1', _tetrisStartLevel == 1, () {
              setState(() {
                _tetrisStartLevel = 1;
                _resetTetris();
              });
            }),
            const SizedBox(width: 6),
            _buildChoiceChip('Level 3', _tetrisStartLevel == 3, () {
              setState(() {
                _tetrisStartLevel = 3;
                _resetTetris();
              });
            }),
            const SizedBox(width: 6),
            _buildChoiceChip('Level 5', _tetrisStartLevel == 5, () {
              setState(() {
                _tetrisStartLevel = 5;
                _resetTetris();
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _resetTetris,
          icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
          label: const Text('Restart Tetris', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ACTIVE GAME VIEWS (CLEAN & UNCLUTTERED)
  // =========================================================================
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

  // --- UI 1: TIC-TAC-TOE VIEW ---
  Widget _buildTicTacToeView() {
    return Column(
      children: [
        _buildGameOptionsHeader(),
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
              final rawVal = _tttBoard[i];
              Widget cellContent;
              if (rawVal.isEmpty) {
                cellContent = const SizedBox.shrink();
              } else if (_tttSymbolStyle == 'stationery') {
                cellContent = Icon(
                  rawVal == 'X' ? Icons.edit_rounded : Icons.cleaning_services_rounded,
                  size: 34,
                  color: rawVal == 'X' ? const Color(0xFFE74C3C) : const Color(0xFF3498DB),
                );
              } else {
                cellContent = Text(
                  rawVal,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: rawVal == 'X' ? const Color(0xFFE74C3C) : const Color(0xFF3498DB),
                  ),
                );
              }
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
                    child: cellContent,
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
              onPressed: _resetTtt,
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('Restart Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  // --- UI 2: SNAKE PRO VIEW ---
  Widget _buildSnakeView() {
    return Column(
      children: [
        _buildGameOptionsHeader(),
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
              Text('Best: $_snakeHighScore', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF39C12), fontSize: 15)),
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
                snakeSkin: _snakeSkin,
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

  // --- UI 3: REAL LUDO VIEW ---
  Widget _buildLudoView() {
    return Column(
      children: [
        _buildGameOptionsHeader(),
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
              Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: _ludoPlayerColors[_ludoCurrentTurn]),
                  const SizedBox(width: 8),
                  Text(
                    'Turn: ${_ludoPlayerNames[_ludoCurrentTurn]}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _ludoPlayerColors[_ludoCurrentTurn],
                    ),
                  ),
                ],
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
              humanPlayer: _ludoHumanPlayer,
              animatingPlayer: _animatingLudoPlayer,
              animatingToken: _animatingLudoToken,
              hopProgress: _ludoHopProgress,
              animFromStep: _ludoAnimFromStep,
              animToStep: _ludoAnimToStep,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_ludoCurrentTurn == _ludoHumanPlayer && _ludoHasRolled) ...[
          const Text('Tap token below to advance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (tIdx) {
              final canMove = _canLudoTokenMove(_ludoHumanPlayer, tIdx);
              final step = _ludoTokens[_ludoHumanPlayer][tIdx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: canMove ? () => _moveLudoToken(_ludoHumanPlayer, tIdx) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canMove ? _ludoPlayerColors[_ludoHumanPlayer] : Colors.grey.shade400,
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
            _TactileDiceWidget(
              value: _ludoDiceVal,
              isRolling: _ludoIsRolling,
              size: 54,
              dotColor: _ludoPlayerColors[_ludoCurrentTurn],
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: (_ludoCurrentTurn == _ludoHumanPlayer && !_ludoHasRolled && !_ludoIsRolling) ? _rollLudoDice : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ludoPlayerColors[_ludoHumanPlayer],
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

  // --- UI 4: SNAKE & LADDER VIEW ---
  Widget _buildSnakesAndLaddersView() {
    final pawn = _snlPawns[_snlPlayerPawn];
    return Column(
      children: [
        _buildGameOptionsHeader(),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(pawn['icon'] as IconData, size: 15, color: pawn['color'] as Color),
                  const SizedBox(width: 4),
                  Text('You (${pawn['name']}): Sq $_snlP1Pos', style: TextStyle(fontWeight: FontWeight.bold, color: pawn['color'] as Color, fontSize: 13)),
                ],
              ),
              Text(_snlTurn == 1 ? 'Your Turn' : 'Bot Turn', style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.primary, fontSize: 13)),
              Text('Bot: Sq $_snlP2Pos', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2980B9), fontSize: 13)),
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
              p1Color: pawn['color'] as Color,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TactileDiceWidget(
              value: _snlDice,
              isRolling: _snlIsRolling,
              size: 50,
              dotColor: widget.theme.primary,
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

  // --- UI 5: UNO VIEW ---
  Widget _buildUnoView() {
    return Column(
      children: [
        _buildGameOptionsHeader(),
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
        if (_unoBotPlayToast != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _getUnoColorValue(_unoActiveColor).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getUnoColorValue(_unoActiveColor), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy_rounded, size: 16, color: _getUnoColorValue(_unoActiveColor)),
                const SizedBox(width: 6),
                Text(
                  _unoBotPlayToast!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _getUnoColorValue(_unoActiveColor),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _buildUnoCardWidget(_unoTopCard, isLarge: true),
                    if (_unoIsAnimatingCard && _unoFlyingCard != null && _unoFlyController != null)
                      AnimatedBuilder(
                        animation: _unoFlyController!,
                        builder: (ctx, child) {
                          return Transform.translate(
                            offset: Offset(
                              _unoFlyOffsetAnimation!.value.dx * 120,
                              _unoFlyOffsetAnimation!.value.dy * 120,
                            ),
                            child: Transform.rotate(
                              angle: _unoFlyRotateAnimation!.value,
                              child: Transform.scale(
                                scale: _unoFlyScaleAnimation!.value,
                                child: _buildUnoCardWidget(_unoFlyingCard!, isLarge: true),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
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

    Widget centerContent;
    if (val == 'SKIP') {
      centerContent = Icon(
        Icons.block_rounded,
        size: isLarge ? 28 : 22,
        color: c == const Color(0xFF2C3E50) ? Colors.black87 : c,
      );
    } else if (val == 'REVERSE') {
      centerContent = Icon(
        Icons.sync_rounded,
        size: isLarge ? 28 : 22,
        color: c == const Color(0xFF2C3E50) ? Colors.black87 : c,
      );
    } else if (val == 'WILD') {
      centerContent = SizedBox(
        width: isLarge ? 30 : 24,
        height: isLarge ? 30 : 24,
        child: CustomPaint(painter: _UnoWildBadgePainter()),
      );
    } else if (val == '+4') {
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: isLarge ? 22 : 18,
            height: isLarge ? 22 : 18,
            child: CustomPaint(painter: _UnoWildBadgePainter()),
          ),
          const SizedBox(height: 2),
          Text(
            '+4',
            style: TextStyle(
              fontSize: isLarge ? 15 : 12,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      );
    } else {
      centerContent = Text(
        val,
        style: TextStyle(
          color: c == const Color(0xFF2C3E50) ? Colors.black : c,
          fontSize: isLarge ? 22 : 18,
          fontWeight: FontWeight.w900,
        ),
      );
    }

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
            child: centerContent,
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

  // --- UI 6: TETRIS VIEW ---
  Widget _buildTetrisView() {
    return Column(
      children: [
        _buildGameOptionsHeader(),
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
                  pieceColor: _getTetrisColor(_currentPieceType),
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
                        color: _getTetrisColor(_nextPieceType),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
// CUSTOM PAINTERS: RESULT POPUPS (WIN, LOSE, DRAW) & BOARDS
// =========================================================================

class _WinResultPainter extends CustomPainter {
  final Color primaryColor;
  _WinResultPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 6;

    final random = math.Random(42);
    final confettiColors = [
      primaryColor,
      const Color(0xFFF1C40F),
      const Color(0xFFE74C3C),
      const Color(0xFF3498DB),
      const Color(0xFF2ECC71),
    ];
    for (int i = 0; i < 24; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = 28.0 + random.nextDouble() * (w * 0.40);
      final px = cx + math.cos(angle) * dist;
      final py = cy + math.sin(angle) * dist * 0.7;
      final color = confettiColors[i % confettiColors.length];
      final pPaint = Paint()..color = color;
      if (i % 3 == 0) {
        canvas.drawCircle(Offset(px, py), 2.5, pPaint);
      } else if (i % 3 == 1) {
        canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: 4.5, height: 4.5), pPaint);
      } else {
        canvas.drawLine(Offset(px - 2.5, py - 2.5), Offset(px + 2.5, py + 2.5), Paint()..color = color..strokeWidth = 2);
      }
    }

    final trophyPaint = Paint()..color = const Color(0xFFF39C12);
    final trophyHighlight = Paint()..color = const Color(0xFFFFEAA7);
    final trophyShadow = Paint()..color = const Color(0xFFD35400);

    // Pedestal
    final baseRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 32), width: 44, height: 10), const Radius.circular(3));
    canvas.drawRRect(baseRect, trophyShadow);
    final standRect = Rect.fromCenter(center: Offset(cx, cy + 22), width: 14, height: 12);
    canvas.drawRect(standRect, trophyPaint);

    // Handles
    final handlePaint = Paint()
      ..color = const Color(0xFFF39C12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 24, cy - 2), width: 20, height: 24), math.pi * 0.5, math.pi, false, handlePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 24, cy - 2), width: 20, height: 24), -math.pi * 0.5, math.pi, false, handlePaint);

    // Cup body
    final cupPath = Path();
    cupPath.moveTo(cx - 22, cy - 18);
    cupPath.lineTo(cx + 22, cy - 18);
    cupPath.quadraticBezierTo(cx + 20, cy + 16, cx, cy + 18);
    cupPath.quadraticBezierTo(cx - 20, cy + 16, cx - 22, cy - 18);
    cupPath.close();
    canvas.drawPath(cupPath, trophyPaint);

    // Shine
    final shinePath = Path();
    shinePath.moveTo(cx - 16, cy - 14);
    shinePath.lineTo(cx - 12, cy - 14);
    shinePath.quadraticBezierTo(cx - 10, cy + 8, cx - 4, cy + 12);
    shinePath.lineTo(cx - 8, cy + 12);
    shinePath.close();
    canvas.drawPath(shinePath, trophyHighlight);

    // Star
    _drawStar(canvas, Offset(cx, cy - 2), 6.5, 3.2, Paint()..color = Colors.white);

    // Sparkles
    _drawSparkle(canvas, Offset(cx - 34, cy - 22), 5, const Color(0xFFF1C40F));
    _drawSparkle(canvas, Offset(cx + 32, cy - 20), 6, primaryColor);
    _drawSparkle(canvas, Offset(cx, cy - 32), 4, const Color(0xFFF1C40F));
  }

  void _drawStar(Canvas canvas, Offset center, double outerRadius, double innerRadius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / 5) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final p = Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - size, center.dy), Offset(center.dx + size, center.dy), p);
    canvas.drawLine(Offset(center.dx, center.dy - size), Offset(center.dx, center.dy + size), p);
  }

  @override
  bool shouldRepaint(covariant _WinResultPainter old) => old.primaryColor != primaryColor;
}

class _LoseResultPainter extends CustomPainter {
  final Color primaryColor;
  _LoseResultPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 4;

    // Sweat drops
    final sweatPaint = Paint()..color = const Color(0xFF3498DB);
    canvas.drawCircle(Offset(cx + 28, cy - 16), 3.5, sweatPaint);
    canvas.drawCircle(Offset(cx - 28, cy - 12), 3.5, sweatPaint);

    final pencilPaint = Paint()..color = const Color(0xFFE74C3C);
    final woodPaint = Paint()..color = const Color(0xFFFFD1A4);
    final graphitePaint = Paint()..color = const Color(0xFF2C3E50);
    final eraserPaint = Paint()..color = const Color(0xFFFF7675);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.12);

    // Eraser
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -36, 22, 12), const Radius.circular(5)), eraserPaint);
    // Ferrule
    canvas.drawRect(const Rect.fromLTWH(-11, -24, 22, 5), Paint()..color = const Color(0xFFBDC3C7));
    // Body
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -19, 22, 34), const Radius.circular(3)), pencilPaint);

    // Bandage
    final bandagePaint = Paint()..color = const Color(0xFFFFF3CD);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-13, -5, 26, 8), const Radius.circular(2)), bandagePaint);

    // Wood tip
    final woodPath = Path()
      ..moveTo(-11, 15)
      ..lineTo(11, 15)
      ..lineTo(0, 32)
      ..close();
    canvas.drawPath(woodPath, woodPaint);

    // Graphite lead tip
    final leadPath = Path()
      ..moveTo(-4, 25)
      ..lineTo(4, 25)
      ..lineTo(0, 32)
      ..close();
    canvas.drawPath(leadPath, graphitePaint);

    // Droopy eyes
    final eyePaint = Paint()..color = Colors.white..strokeWidth = 2.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(-8, -14, 6, 6), math.pi, math.pi, false, eyePaint);
    canvas.drawArc(const Rect.fromLTWH(2, -14, 6, 6), math.pi, math.pi, false, eyePaint);

    // Sad mouth
    canvas.drawArc(const Rect.fromLTWH(-4, 2, 8, 6), math.pi, math.pi, false, eyePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoseResultPainter old) => old.primaryColor != primaryColor;
}

class _DrawResultPainter extends CustomPainter {
  final Color primaryColor;
  _DrawResultPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 4;

    final standPaint = Paint()..color = primaryColor..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 18), Offset(cx, cy + 26), standPaint);
    canvas.drawLine(Offset(cx - 22, cy + 26), Offset(cx + 22, cy + 26), standPaint);
    canvas.drawLine(Offset(cx - 32, cy - 18), Offset(cx + 32, cy - 18), standPaint);

    final strPaint = Paint()..color = primaryColor.withValues(alpha: 0.6)..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx - 32, cy - 18), Offset(cx - 42, cy + 4), strPaint);
    canvas.drawLine(Offset(cx - 32, cy - 18), Offset(cx - 22, cy + 4), strPaint);
    canvas.drawLine(Offset(cx + 32, cy - 18), Offset(cx + 22, cy + 4), strPaint);
    canvas.drawLine(Offset(cx + 32, cy - 18), Offset(cx + 42, cy + 4), strPaint);

    final panPaint1 = Paint()..color = const Color(0xFFE74C3C);
    canvas.drawCircle(Offset(cx - 32, cy + 8), 11, panPaint1);
    final fPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - 35, cy + 6), 1.5, fPaint);
    canvas.drawCircle(Offset(cx - 29, cy + 6), 1.5, fPaint);

    final panPaint2 = Paint()..color = const Color(0xFF3498DB);
    canvas.drawCircle(Offset(cx + 32, cy + 8), 11, panPaint2);
    canvas.drawCircle(Offset(cx + 29, cy + 6), 1.5, fPaint);
    canvas.drawCircle(Offset(cx + 35, cy + 6), 1.5, fPaint);

    final eqBg = Paint()..color = const Color(0xFFF39C12);
    canvas.drawCircle(Offset(cx, cy - 18), 7.5, eqBg);
    final eqP = Paint()..color = Colors.white..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 3.5, cy - 20), Offset(cx + 3.5, cy - 20), eqP);
    canvas.drawLine(Offset(cx - 3.5, cy - 16), Offset(cx + 3.5, cy - 16), eqP);
  }

  @override
  bool shouldRepaint(covariant _DrawResultPainter old) => old.primaryColor != primaryColor;
}

class _SnakeBoardPainter extends CustomPainter {
  final List<math.Point<int>> snake;
  final math.Point<int> food;
  final math.Point<int>? goldenApple;
  final int rows;
  final int cols;
  final StationeryTheme theme;
  final String snakeSkin;

  _SnakeBoardPainter({
    required this.snake,
    required this.food,
    required this.goldenApple,
    required this.rows,
    required this.cols,
    required this.theme,
    required this.snakeSkin,
  });

  Color _getSnakeColor() {
    switch (snakeSkin) {
      case 'green':
        return const Color(0xFF27AE60);
      case 'cyan':
        return const Color(0xFF00CEC9);
      case 'gold':
        return const Color(0xFFF1C40F);
      case 'pink':
        return const Color(0xFFFD79A8);
      case 'theme':
      default:
        return theme.primary;
    }
  }

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

    final snakeColor = _getSnakeColor();

    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final isHead = i == 0;
      final bodyPaint = Paint()..color = isHead ? snakeColor : snakeColor.withValues(alpha: 0.75);
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
  final int humanPlayer;
  final int? animatingPlayer;
  final int? animatingToken;
  final double hopProgress;
  final int animFromStep;
  final int animToStep;

  _LudoBoardPainter({
    required this.tokens,
    required this.currentTurn,
    required this.hasRolled,
    required this.canMoveFunc,
    required this.humanPlayer,
    this.animatingPlayer,
    this.animatingToken,
    this.hopProgress = 0.0,
    this.animFromStep = -1,
    this.animToStep = 0,
  });

  Offset _getLudoTokenPosition(int p, int step, int t, double cell) {
    final baseSlots = [
      [Offset(cell * 2, cell * 2), Offset(cell * 4, cell * 2), Offset(cell * 2, cell * 4), Offset(cell * 4, cell * 4)],
      [Offset(cell * 11, cell * 2), Offset(cell * 13, cell * 2), Offset(cell * 11, cell * 4), Offset(cell * 13, cell * 4)],
      [Offset(cell * 11, cell * 11), Offset(cell * 13, cell * 11), Offset(cell * 11, cell * 13), Offset(cell * 13, cell * 13)],
      [Offset(cell * 2, cell * 11), Offset(cell * 4, cell * 11), Offset(cell * 2, cell * 13), Offset(cell * 4, cell * 13)],
    ];
    final track = _buildLudoTrackCoords(cell);

    if (step == -1) {
      return baseSlots[p][t];
    } else if (step == 56) {
      return Offset(cell * 7.5, cell * 7.5);
    } else if (step > 50) {
      final offset = (step - 50).toDouble();
      if (p == 0) {
        return Offset(cell * (offset + 0.5), cell * 7.5);
      } else if (p == 1) {
        return Offset(cell * 7.5, cell * (offset + 0.5));
      } else if (p == 2) {
        return Offset(cell * (14.5 - offset), cell * 7.5);
      } else {
        return Offset(cell * 7.5, cell * (14.5 - offset));
      }
    } else {
      final trackIdx = ((p == 0 ? 0 : p == 1 ? 13 : p == 2 ? 26 : 39) + step) % 52;
      return track[trackIdx];
    }
  }

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

    final tokenColors = [
      const Color(0xFFE74C3C),
      const Color(0xFF27AE60),
      const Color(0xFFF39C12),
      const Color(0xFF2980B9),
    ];

    for (int p = 0; p < 4; p++) {
      for (int t = 0; t < 4; t++) {
        final step = tokens[p][t];
        final isAnimating = (p == animatingPlayer && t == animatingToken);

        Offset drawPos;
        double scale = 1.0;

        if (isAnimating) {
          final startPos = _getLudoTokenPosition(p, animFromStep, t, cell);
          final endPos = _getLudoTokenPosition(p, animToStep, t, cell);
          final groundPos = Offset.lerp(startPos, endPos, hopProgress)!;
          final jumpArc = -math.sin(hopProgress * math.pi) * (cell * 0.72);
          drawPos = Offset(groundPos.dx, groundPos.dy + jumpArc);
          scale = 1.0 + math.sin(hopProgress * math.pi) * 0.35;

          // Realistic dynamic drop shadow on the board surface
          final shadowW = cell * 0.65 * (1.0 - math.sin(hopProgress * math.pi) * 0.22);
          final shadowH = cell * 0.26 * (1.0 - math.sin(hopProgress * math.pi) * 0.22);
          canvas.drawOval(
            Rect.fromCenter(center: groundPos, width: shadowW, height: shadowH),
            Paint()..color = Colors.black.withValues(alpha: 0.28 - math.sin(hopProgress * math.pi) * 0.12),
          );

          // Landing impact ripple
          if (hopProgress > 0.85) {
            final ripFrac = (hopProgress - 0.85) / 0.15;
            canvas.drawCircle(
              endPos,
              cell * 0.52 * ripFrac,
              Paint()
                ..color = tokenColors[p].withValues(alpha: 0.5 * (1.0 - ripFrac))
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2,
            );
          }
        } else {
          drawPos = _getLudoTokenPosition(p, step, t, cell);
        }

        final tPaint = Paint()..color = tokenColors[p];
        final canMove = p == currentTurn && hasRolled && canMoveFunc(p, t);

        if (isAnimating) {
          final jumpHalo = Paint()
            ..color = const Color(0xFFF1C40F).withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4;
          canvas.drawCircle(drawPos, cell * 0.46 * scale, jumpHalo);
        } else if (canMove) {
          final haloPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
          canvas.drawCircle(drawPos, cell * 0.44, haloPaint);
        }

        // Token Body
        canvas.drawCircle(drawPos, cell * 0.36 * scale, tPaint);
        // Center Core Indicator
        canvas.drawCircle(
          drawPos,
          cell * 0.16 * scale,
          Paint()..color = p == humanPlayer ? const Color(0xFFF1C40F) : Colors.white,
        );
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
  final Color p1Color;

  _SnakesAndLaddersPainter({
    required this.p1Pos,
    required this.p2Pos,
    required this.snakes,
    required this.ladders,
    required this.theme,
    required this.p1Color,
  });

  Offset _getCellCenter(int num, double cell) {
    if (num < 1) num = 1;
    if (num > 100) num = 100;
    final idx = num - 1;
    final r = idx ~/ 10;
    final c = idx % 10;
    final actualCol = (r % 2 == 0) ? c : (9 - c);
    return Offset((actualCol + 0.5) * cell, (9 - r + 0.5) * cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 10.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 1. Grid Cells & Numbers
    for (int r = 9; r >= 0; r--) {
      final isEven = (r % 2 == 0);
      for (int c = 0; c < 10; c++) {
        final actualCol = isEven ? (9 - c) : c;
        final cellNum = r * 10 + actualCol + 1;
        final cellRect = Rect.fromLTWH(c * cell, (9 - r) * cell, cell, cell);

        Color cellColor = cellNum % 2 == 0 ? theme.bg : theme.cardBg;
        if (cellNum == 100) cellColor = const Color(0xFFFFF3CD);

        canvas.drawRect(cellRect, Paint()..color = cellColor);
        canvas.drawRect(cellRect, Paint()..color = Colors.black12..style = PaintingStyle.stroke);

        textPainter.text = TextSpan(
          text: '$cellNum',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(cellRect.left + 2, cellRect.top + 2));
      }
    }

    // 2. Draw Real Vector Ladders (No Emojis)
    ladders.forEach((start, end) {
      final bottom = _getCellCenter(start, cell);
      final top = _getCellCenter(end, cell);
      _drawRealLadder(canvas, bottom, top, cell);
    });

    // 3. Draw Real Vector Snakes with Mouth to Tail (No Emojis)
    snakes.forEach((head, tail) {
      final headPos = _getCellCenter(head, cell);
      final tailPos = _getCellCenter(tail, cell);
      _drawRealSnake(canvas, headPos, tailPos, cell, head);
    });

    // 4. Draw Player Pawns
    _drawPawn(canvas, p1Pos, cell, p1Color, -3.5);
    _drawPawn(canvas, p2Pos, cell, const Color(0xFF2980B9), 3.5);
  }

  void _drawRealLadder(Canvas canvas, Offset b, Offset t, double cell) {
    final dx = t.dx - b.dx;
    final dy = t.dy - b.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 5) return;

    // Unit normal vector perpendicular to ladder length
    final nx = -dy / len;
    final ny = dx / len;
    final halfW = cell * 0.22;

    final p1 = Offset(b.dx - nx * halfW, b.dy - ny * halfW);
    final p2 = Offset(t.dx - nx * halfW, t.dy - ny * halfW);
    final p3 = Offset(b.dx + nx * halfW, b.dy + ny * halfW);
    final p4 = Offset(t.dx + nx * halfW, t.dy + ny * halfW);

    // 1. Ladder Start Base Anchor Ring on Start Square
    final baseAnchorRing = Paint()
      ..color = const Color(0xFF27AE60).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(b, cell * 0.32, baseAnchorRing);

    // 2. Drop Shadows for Rails
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(p1.dx + 2, p1.dy + 2.5), Offset(p2.dx + 2, p2.dy + 2.5), shadowPaint);
    canvas.drawLine(Offset(p3.dx + 2, p3.dy + 2.5), Offset(p4.dx + 2, p4.dy + 2.5), shadowPaint);

    // 3. Sturdy Wood Rails
    final railPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    final railHighlight = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1, p2, railPaint);
    canvas.drawLine(p3, p4, railPaint);
    canvas.drawLine(p1, p2, railHighlight);
    canvas.drawLine(p3, p4, railHighlight);

    // 4. Sturdy Rungs with Shadows
    final rungCount = (len / (cell * 0.42)).clamp(3, 15).round();
    final rungPaint = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final rungShadow = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= rungCount; i++) {
      final frac = i / (rungCount + 1);
      final r1 = Offset(p1.dx + (p2.dx - p1.dx) * frac, p1.dy + (p2.dy - p1.dy) * frac);
      final r2 = Offset(p3.dx + (p4.dx - p3.dx) * frac, p3.dy + (p4.dy - p3.dy) * frac);
      canvas.drawLine(Offset(r1.dx + 0.6, r1.dy + 1.2), Offset(r2.dx + 0.6, r2.dy + 1.2), rungShadow);
      canvas.drawLine(r1, r2, rungPaint);
    }

    // 5. Golden Climbing Hooks at Top Destination Square
    final hookPaint = Paint()
      ..color = const Color(0xFFF1C40F)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: p2, width: 7, height: 7), 0, math.pi, false, hookPaint);
    canvas.drawArc(Rect.fromCenter(center: p4, width: 7, height: 7), 0, math.pi, false, hookPaint);

    // Destination climb target ring
    final topRing = Paint()
      ..color = const Color(0xFFF1C40F).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(t, cell * 0.32, topRing);
  }

  void _drawRealSnake(Canvas canvas, Offset h, Offset t, double cell, int seed) {
    final dx = t.dx - h.dx;
    final dy = t.dy - h.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 5) return;

    final nx = -dy / dist;
    final ny = dx / dist;
    final sign = (seed % 2 == 0) ? 1.0 : -1.0;
    final waveAmp = cell * 0.45 * sign;

    final mid1 = Offset(h.dx + dx * 0.33 + nx * waveAmp, h.dy + dy * 0.33 + ny * waveAmp);
    final mid2 = Offset(h.dx + dx * 0.66 - nx * waveAmp * 0.85, h.dy + dy * 0.66 - ny * waveAmp * 0.85);

    final snakePath = Path();
    snakePath.moveTo(h.dx, h.dy);
    snakePath.cubicTo(mid1.dx, mid1.dy, mid2.dx, mid2.dy, t.dx, t.dy);

    // 1. Start Square Hazard Danger Ring (Snake Mouth Biting Location)
    final bitePulse = Paint()
      ..color = const Color(0xFFE74C3C).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(h, cell * 0.44, bitePulse);
    final biteRing = Paint()
      ..color = const Color(0xFFE74C3C).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(h, cell * 0.34, biteRing);

    // 2. Heavy Drop Shadow / Dark Outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF0A2912)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(snakePath, outlinePaint);

    // 3. Vibrant Emerald Green Serpentine Body
    final bodyPaint = Paint()
      ..color = const Color(0xFF27AE60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(snakePath, bodyPaint);

    // 4. Golden Dorsal Diamond Scales / Pattern Spine
    final spinePaint = Paint()
      ..color = const Color(0xFFF1C40F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(snakePath, spinePaint);

    // 5. Cobra Head at h (Mouth & Fangs precisely biting the Start Square)
    final headAngle = math.atan2(mid1.dy - h.dy, mid1.dx - h.dx) + math.pi;
    canvas.save();
    canvas.translate(h.dx, h.dy);
    canvas.rotate(headAngle);

    // Red Forked Tongue flicking forward
    final tonguePaint = Paint()
      ..color = const Color(0xFFE74C3C)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(6, 0), const Offset(13, 0), tonguePaint);
    canvas.drawLine(const Offset(13, 0), const Offset(16.5, -3.0), tonguePaint);
    canvas.drawLine(const Offset(13, 0), const Offset(16.5, 3.0), tonguePaint);

    // Flared Cobra Hood & Head
    final hoodPath = Path();
    hoodPath.moveTo(-6, -8);
    hoodPath.quadraticBezierTo(4, -10, 8, 0);
    hoodPath.quadraticBezierTo(4, 10, -6, 8);
    hoodPath.quadraticBezierTo(-2, 0, -6, -8);
    hoodPath.close();
    canvas.drawPath(hoodPath, Paint()..color = const Color(0xFF0F381E));
    canvas.drawPath(hoodPath, Paint()..color = const Color(0xFF2ECC71)..style = PaintingStyle.fill);

    // Open mouth & White Venom Fangs
    final fangPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(6, -2.5), 1.2, fangPaint);
    canvas.drawCircle(const Offset(6, 2.5), 1.2, fangPaint);

    // Fierce Golden Eyes with Vertical Slit Pupils
    final eyePaint = Paint()..color = const Color(0xFFF39C12);
    canvas.drawCircle(const Offset(2.5, -4.5), 2.2, eyePaint);
    canvas.drawCircle(const Offset(2.5, 4.5), 2.2, eyePaint);
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(2.6, -5.5, 0.8, 2.2), pupilPaint);
    canvas.drawRect(const Rect.fromLTWH(2.6, 3.3, 0.8, 2.2), pupilPaint);

    canvas.restore();

    // 6. Tail Tip at t (Destination Landing Square)
    final dropRing = Paint()
      ..color = const Color(0xFFF39C12).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(t, cell * 0.32, dropRing);

    // Concentric Rattle rings (3 golden beads)
    final rattleAngle = math.atan2(t.dy - mid2.dy, t.dx - mid2.dx);
    for (int r = 0; r < 3; r++) {
      final rPos = Offset(
        t.dx - math.cos(rattleAngle) * (r * 3.5),
        t.dy - math.sin(rattleAngle) * (r * 3.5),
      );
      canvas.drawCircle(rPos, (3.2 - r * 0.7).clamp(1.4, 3.2), Paint()..color = const Color(0xFFF1C40F));
      canvas.drawCircle(
        rPos,
        (3.2 - r * 0.7).clamp(1.4, 3.2),
        Paint()
          ..color = const Color(0xFFB7950B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }

  void _drawPawn(Canvas canvas, int num, double cell, Color col, double shift) {
    if (num < 1 || num > 100) return;
    final pos = _getCellCenter(num, cell);
    final x = pos.dx + shift;
    final y = pos.dy;

    // Drop shadow on ground
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 1, y + cell * 0.22), width: cell * 0.46, height: cell * 0.18),
      Paint()..color = Colors.black26,
    );

    // Outer colored circular pawn base
    canvas.drawCircle(Offset(x, y), cell * 0.28, Paint()..color = col);
    canvas.drawCircle(
      Offset(x, y),
      cell * 0.28,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner disc
    canvas.drawCircle(Offset(x, y), cell * 0.16, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(x, y), cell * 0.08, Paint()..color = col);
  }

  @override
  bool shouldRepaint(covariant _SnakesAndLaddersPainter old) => true;
}

class _TactileDiceWidget extends StatelessWidget {
  final int value;
  final bool isRolling;
  final double size;
  final Color dotColor;

  const _TactileDiceWidget({
    required this.value,
    this.isRolling = false,
    this.size = 52,
    this.dotColor = const Color(0xFF2C3E50),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(2, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DicePainter(
          value: value.clamp(1, 6),
          isRolling: isRolling,
          dotColor: dotColor,
        ),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final int value;
  final bool isRolling;
  final Color dotColor;

  _DicePainter({required this.value, required this.isRolling, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.085; // pip radius

    final pipPaint = Paint()..color = dotColor;
    final centerRedPaint = Paint()..color = const Color(0xFFE74C3C);

    if (isRolling) {
      // Draw rolling motion pips
      final p1 = Offset(w * 0.3, h * 0.3);
      final p2 = Offset(w * 0.5, h * 0.5);
      final p3 = Offset(w * 0.7, h * 0.7);
      canvas.drawCircle(p1, r, Paint()..color = dotColor.withValues(alpha: 0.5));
      canvas.drawCircle(p2, r * 1.2, centerRedPaint);
      canvas.drawCircle(p3, r, Paint()..color = dotColor.withValues(alpha: 0.5));
      return;
    }

    final pTopLeft = Offset(w * 0.28, h * 0.28);
    final pTopRight = Offset(w * 0.72, h * 0.28);
    final pCenter = Offset(w * 0.5, h * 0.5);
    final pBottomLeft = Offset(w * 0.28, h * 0.72);
    final pBottomRight = Offset(w * 0.72, h * 0.72);
    final pMidLeft = Offset(w * 0.28, h * 0.5);
    final pMidRight = Offset(w * 0.72, h * 0.5);

    switch (value) {
      case 1:
        canvas.drawCircle(pCenter, r * 1.5, centerRedPaint);
        break;
      case 2:
        canvas.drawCircle(pTopLeft, r, pipPaint);
        canvas.drawCircle(pBottomRight, r, pipPaint);
        break;
      case 3:
        canvas.drawCircle(pTopLeft, r, pipPaint);
        canvas.drawCircle(pCenter, r * 1.1, centerRedPaint);
        canvas.drawCircle(pBottomRight, r, pipPaint);
        break;
      case 4:
        canvas.drawCircle(pTopLeft, r, pipPaint);
        canvas.drawCircle(pTopRight, r, pipPaint);
        canvas.drawCircle(pBottomLeft, r, pipPaint);
        canvas.drawCircle(pBottomRight, r, pipPaint);
        break;
      case 5:
        canvas.drawCircle(pTopLeft, r, pipPaint);
        canvas.drawCircle(pTopRight, r, pipPaint);
        canvas.drawCircle(pCenter, r * 1.1, centerRedPaint);
        canvas.drawCircle(pBottomLeft, r, pipPaint);
        canvas.drawCircle(pBottomRight, r, pipPaint);
        break;
      case 6:
        canvas.drawCircle(pTopLeft, r, pipPaint);
        canvas.drawCircle(pTopRight, r, pipPaint);
        canvas.drawCircle(pMidLeft, r, pipPaint);
        canvas.drawCircle(pMidRight, r, pipPaint);
        canvas.drawCircle(pBottomLeft, r, pipPaint);
        canvas.drawCircle(pBottomRight, r, pipPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter old) =>
      old.value != value || old.isRolling != isRolling || old.dotColor != dotColor;
}

class _UnoWildBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    final pRed = Paint()..color = const Color(0xFFE74C3C);
    final pBlue = Paint()..color = const Color(0xFF2980B9);
    final pYellow = Paint()..color = const Color(0xFFF1C40F);
    final pGreen = Paint()..color = const Color(0xFF27AE60);

    canvas.drawArc(rect, -math.pi, math.pi / 2, true, pRed);
    canvas.drawArc(rect, -math.pi / 2, math.pi / 2, true, pBlue);
    canvas.drawArc(rect, 0, math.pi / 2, true, pYellow);
    canvas.drawArc(rect, math.pi / 2, math.pi / 2, true, pGreen);

    // Center disc
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.22, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

