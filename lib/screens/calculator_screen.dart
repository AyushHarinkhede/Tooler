import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../models/calc_history_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets_3d/stationery_3d_modal.dart';
import '../widgets_3d/tooler_character.dart';

enum CalcMode { basic, scientific, programmer }
enum ProgBase { hex, dec, oct, bin }
enum ProgWordSize { qword64, dword32, word16, byte8 }

class CalculatorScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CalculatorScreen({super.key, required this.theme});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  CalcMode _calcMode = CalcMode.basic;

  // General State
  String _expression = '0';
  String _previewResult = '';
  String _lastEquation = '';
  String? _easterEggText;
  bool _isRad = false; // Angle mode: false = DEG, true = RAD
  bool _is2nd = false; // 2nd function toggle for inverse trig / alt powers
  double? _memoryValue;
  List<CalcHistoryItem> _history = [];

  // Slide-up Answer Animation on '='
  late AnimationController _slideUpController;
  late Animation<double> _slideUpAnimation;
  bool _isSlidingUp = false;
  String _slidingAns = '';
  String? _slideEgg;

  // Programmer State
  ProgBase _progBase = ProgBase.dec;
  ProgWordSize _progWordSize = ProgWordSize.qword64;
  BigInt _progValue = BigInt.zero;

  // Clock Mode on holding 'C' for at least 3 sec
  bool _isClockMode = false;
  String _clockHourMin = '';
  String _clockSec = '';
  String _clockAmPm = '';
  String _clockDateDay = '';
  Timer? _clockTimer;

  final ScrollController _displayScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideUpAnimation = CurvedAnimation(
      parent: _slideUpController,
      curve: Curves.easeOutCubic,
    );
    _slideUpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isSlidingUp = false;
            _expression = _slidingAns;
            _previewResult = '';
            _easterEggText = _slideEgg;
            _slideUpController.reset();
          });
        }
      }
    });
    // Initialize initial easter egg ("Nothing ⚪" for 0)
    _computePreview();
  }

  @override
  void dispose() {
    _slideUpController.dispose();
    _clockTimer?.cancel();
    _displayScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService().loadCalcHistory();
    if (mounted) {
      setState(() => _history = list);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_displayScrollController.hasClients) {
        _displayScrollController.animateTo(
          _displayScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- Real-Time Clock Mode on Holding 'C' for 3 seconds ---
  void _activateLiveClock() {
    SoundService().playSuccess();
    HapticFeedback.heavyImpact();
    _clockTimer?.cancel();
    final now = DateTime.now();
    setState(() {
      _isClockMode = true;
      _clockHourMin = DateFormat('hh:mm').format(now);
      _clockSec = DateFormat('ss').format(now);
      _clockAmPm = DateFormat('a').format(now);
      _clockDateDay = DateFormat('EEEE, dd MMMM yyyy').format(now);
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isClockMode) {
        final t = DateTime.now();
        setState(() {
          _clockHourMin = DateFormat('hh:mm').format(t);
          _clockSec = DateFormat('ss').format(t);
          _clockAmPm = DateFormat('a').format(t);
          _clockDateDay = DateFormat('EEEE, dd MMMM yyyy').format(t);
        });
      }
    });
    // Notification toast removed as requested
  }

  void _deactivateLiveClock() {
    if (_isClockMode) {
      _clockTimer?.cancel();
      setState(() {
        _isClockMode = false;
      });
    }
  }

  // Handle all button presses
  void _onKeyPress(String key) {
    _deactivateLiveClock();
    SoundService().playKey();
    HapticFeedback.lightImpact();

    setState(() {
      if (key == 'AC' || key == 'C') {
        _expression = '0';
        _previewResult = '';
        _lastEquation = '';
        _easterEggText = null;
        _progValue = BigInt.zero;
      } else if (key == '⌫') {
        _handleBackspace();
      } else if (key == '=') {
        if (_calcMode == CalcMode.programmer) {
          _evaluateFinalProgrammer();
        } else {
          _evaluateFinal();
        }
      } else if (key == '±') {
        _toggleSign();
      } else if (key == '%') {
        _handlePercent();
      } else if (key == 'DEG' || key == 'RAD') {
        _isRad = !_isRad;
        _computePreview();
      } else if (key == '2nd') {
        _is2nd = !_is2nd;
      } else if (key == 'MC') {
        _memoryValue = null;
        _showToast("Memory cleared");
      } else if (key == 'MR') {
        if (_memoryValue != null) {
          final memStr = _formatNumber(_memoryValue!);
          if (_expression == '0' || _isErrorState()) {
            _expression = memStr;
          } else {
            _expression += memStr;
          }
          _computePreview();
        } else {
          _showToast("Memory empty");
        }
      } else if (key == 'M+') {
        _handleMemoryAdd(true);
      } else if (key == 'M-') {
        _handleMemoryAdd(false);
      } else {
        if (_calcMode == CalcMode.programmer) {
          _appendProgKey(key);
        } else {
          _appendKey(key);
        }
      }
    });

    _scrollToEnd();
  }

  // --- Hardware / Physical Keyboard Shortcuts Handler ---
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final logical = event.logicalKey;
      final char = event.character;

      if (logical == LogicalKeyboardKey.enter ||
          logical == LogicalKeyboardKey.numpadEnter ||
          char == '=') {
        _onKeyPress('=');
        return KeyEventResult.handled;
      } else if (logical == LogicalKeyboardKey.backspace) {
        _onKeyPress('⌫');
        return KeyEventResult.handled;
      } else if (logical == LogicalKeyboardKey.escape) {
        _onKeyPress('AC');
        return KeyEventResult.handled;
      } else if (char != null) {
        final upper = char.toUpperCase();
        if (_calcMode == CalcMode.programmer && ['A', 'B', 'C', 'D', 'E', 'F'].contains(upper)) {
          if (_isProgKeyAllowed(upper)) {
            _onKeyPress(upper);
            return KeyEventResult.handled;
          }
        } else if (upper == 'C') {
          _onKeyPress('C');
          return KeyEventResult.handled;
        } else if (['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '+', '-', '%', '(', ')', '^'].contains(char)) {
          if (_calcMode == CalcMode.programmer && !_isProgKeyAllowed(char)) {
            return KeyEventResult.ignored;
          }
          _onKeyPress(char);
          return KeyEventResult.handled;
        } else if (char == '*' || char == 'x' || char == 'X') {
          _onKeyPress('×');
          return KeyEventResult.handled;
        } else if (char == '/') {
          _onKeyPress('÷');
          return KeyEventResult.handled;
        } else if (char == '&') {
          _onKeyPress('AND');
          return KeyEventResult.handled;
        } else if (char == '|') {
          _onKeyPress('OR');
          return KeyEventResult.handled;
        } else if (char == '~') {
          _onKeyPress('NOT');
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  bool _isErrorState() {
    return _expression == 'Error' ||
        _expression.startsWith('Cannot') ||
        _expression.startsWith('Ask your') ||
        _expression.contains('Error');
  }

  void _handleBackspace() {
    if (_isErrorState() || _expression.length <= 1) {
      _expression = '0';
      _previewResult = '';
      _easterEggText = null;
      _updateProgValue();
      return;
    }

    final multiCharTokens = [
      'sin(', 'cos(', 'tan(', 'asin(', 'acos(', 'atan(',
      'sqrt(', 'ln(', 'log(', '10^', 'e^',
      'AND', 'OR', 'XOR', 'NOT', 'LSH', 'RSH', 'MOD'
    ];

    bool tokenRemoved = false;
    for (final token in multiCharTokens) {
      if (_expression.endsWith(token)) {
        _expression = _expression.substring(0, _expression.length - token.length).trimRight();
        tokenRemoved = true;
        break;
      }
    }

    if (!tokenRemoved) {
      _expression = _expression.substring(0, _expression.length - 1);
    }

    if (_expression.isEmpty) {
      _expression = '0';
    }

    if (_calcMode == CalcMode.programmer) {
      _updateProgValue();
    } else {
      _computePreview();
    }
  }

  void _toggleSign() {
    if (_isErrorState()) return;
    if (_expression == '0') return;

    final reg = RegExp(r'(-?\d+\.?\d*)$');
    final match = reg.firstMatch(_expression);

    if (match != null) {
      final numStr = match.group(0)!;
      final start = match.start;
      String newNum;
      if (numStr.startsWith('-')) {
        newNum = numStr.substring(1);
      } else {
        newNum = '-$numStr';
      }
      _expression = _expression.substring(0, start) + newNum;
      _computePreview();
    }
  }

  void _handlePercent() {
    if (_isErrorState()) return;
    if (_expression.endsWith('%') || _isOperator(_expression[_expression.length - 1])) {
      return;
    }
    _expression += '%';
    _computePreview();
  }

  void _handleMemoryAdd(bool add) {
    try {
      final current = _evaluateExpression(_expression);
      if (current != null && current != 'Error' && !current.startsWith('Cannot')) {
        final val = double.tryParse(current) ?? 0.0;
        _memoryValue = (_memoryValue ?? 0.0) + (add ? val : -val);
        _showToast(add ? "Added to M: $current" : "Subtracted from M: $current");
      }
    } catch (_) {}
  }

  bool _isOperator(String ch) {
    return ch == '+' || ch == '-' || ch == '×' || ch == '÷' || ch == '^' ||
        ch == '&' || ch == '|';
  }

  void _appendKey(String key) {
    if (_isErrorState()) {
      _expression = '0';
    }

    if (_isOperator(key)) {
      if (_expression.isNotEmpty && _isOperator(_expression[_expression.length - 1])) {
        _expression = _expression.substring(0, _expression.length - 1) + key;
        _computePreview();
        return;
      }
    }

    if (key == '.') {
      final segments = _expression.split(RegExp(r'[+\-×÷^()]'));
      final lastSegment = segments.isNotEmpty ? segments.last : '';
      if (lastSegment.contains('.')) {
        return;
      }
      if (_expression == '0' || _isOperator(_expression[_expression.length - 1])) {
        _expression += '0.';
        _computePreview();
        return;
      }
    }

    if (_expression == '0') {
      if (_isOperator(key) || key == '%') {
        _expression = '0$key';
      } else {
        _expression = key;
      }
    } else {
      _expression += key;
    }

    _computePreview();
  }

  // --- PROGRAMMER MODE LOGIC ---
  bool _isProgKeyAllowed(String key) {
    final hexChars = ['A', 'B', 'C', 'D', 'E', 'F'];
    final decDigits = ['8', '9'];
    final octDigits = ['2', '3', '4', '5', '6', '7'];
    final binDigits = ['0', '1'];

    switch (_progBase) {
      case ProgBase.bin:
        return binDigits.contains(key);
      case ProgBase.oct:
        return binDigits.contains(key) || octDigits.contains(key);
      case ProgBase.dec:
        return binDigits.contains(key) || octDigits.contains(key) || decDigits.contains(key);
      case ProgBase.hex:
        return binDigits.contains(key) || octDigits.contains(key) || decDigits.contains(key) || hexChars.contains(key);
    }
  }

  void _appendProgKey(String key) {
    if (_isErrorState()) {
      _expression = '0';
    }

    final isProgOp = ['+', '-', '×', '÷', 'AND', 'OR', 'XOR', 'LSH', 'RSH', 'MOD'].contains(key);

    if (isProgOp) {
      _expression += ' $key ';
      return;
    }

    if (key == 'NOT') {
      _expression = 'NOT($_expression)';
      _evaluateFinalProgrammer();
      return;
    }

    if (_expression == '0') {
      _expression = key;
    } else {
      _expression += key;
    }

    _updateProgValue();
  }

  int _getWordBits() {
    switch (_progWordSize) {
      case ProgWordSize.qword64:
        return 64;
      case ProgWordSize.dword32:
        return 32;
      case ProgWordSize.word16:
        return 16;
      case ProgWordSize.byte8:
        return 8;
    }
  }

  BigInt _getWordMask() {
    final bits = _getWordBits();
    if (bits == 64) {
      return (BigInt.one << 64) - BigInt.one;
    }
    return (BigInt.one << bits) - BigInt.one;
  }

  void _updateProgValue() {
    try {
      final segments = _expression.split(RegExp(r'\s+'));
      final lastToken = segments.isNotEmpty ? segments.last : '0';
      final radix = _progBase == ProgBase.hex ? 16 : _progBase == ProgBase.oct ? 8 : _progBase == ProgBase.bin ? 2 : 10;
      final parsed = BigInt.tryParse(lastToken, radix: radix);
      if (parsed != null) {
        _progValue = parsed & _getWordMask();
      }
      _easterEggText = null;
    } catch (_) {}
  }

  void _switchProgBase(ProgBase newBase) {
    SoundService().playClick();
    HapticFeedback.selectionClick();
    setState(() {
      _progBase = newBase;
      final radix = newBase == ProgBase.hex ? 16 : newBase == ProgBase.oct ? 8 : newBase == ProgBase.bin ? 2 : 10;
      _expression = _progValue.toRadixString(radix).toUpperCase();
      _easterEggText = null;
    });
  }

  void _cycleWordSize() {
    SoundService().playClick();
    HapticFeedback.selectionClick();
    setState(() {
      switch (_progWordSize) {
        case ProgWordSize.qword64:
          _progWordSize = ProgWordSize.dword32;
          break;
        case ProgWordSize.dword32:
          _progWordSize = ProgWordSize.word16;
          break;
        case ProgWordSize.word16:
          _progWordSize = ProgWordSize.byte8;
          break;
        case ProgWordSize.byte8:
          _progWordSize = ProgWordSize.qword64;
          break;
      }
      _progValue = _progValue & _getWordMask();
      final radix = _progBase == ProgBase.hex ? 16 : _progBase == ProgBase.oct ? 8 : _progBase == ProgBase.bin ? 2 : 10;
      _expression = _progValue.toRadixString(radix).toUpperCase();
    });
  }

  void _evaluateFinalProgrammer() {
    try {
      final radix = _progBase == ProgBase.hex ? 16 : _progBase == ProgBase.oct ? 8 : _progBase == ProgBase.bin ? 2 : 10;
      final tokens = _expression.trim().split(RegExp(r'\s+'));

      if (tokens.length == 3) {
        final a = BigInt.parse(tokens[0], radix: radix);
        final op = tokens[1];
        final b = BigInt.parse(tokens[2], radix: radix);

        BigInt res = BigInt.zero;
        if (op == '+') {
          res = a + b;
        } else if (op == '-') {
          res = a - b;
        } else if (op == '×') {
          res = a * b;
        } else if (op == '÷') {
          if (b == BigInt.zero) throw Exception("Divide by zero");
          res = a ~/ b;
        } else if (op == 'AND') {
          res = a & b;
        } else if (op == 'OR') {
          res = a | b;
        } else if (op == 'XOR') {
          res = a ^ b;
        } else if (op == 'LSH') {
          res = a << b.toInt();
        } else if (op == 'RSH') {
          res = a >> b.toInt();
        } else if (op == 'MOD') {
          if (b == BigInt.zero) throw Exception("Divide by zero");
          res = a % b;
        }

        res = res & _getWordMask();
        _lastEquation = '$_expression =';
        _progValue = res;
        _expression = res.toRadixString(radix).toUpperCase();
        _previewResult = '';
        _easterEggText = null;
        SoundService().playSuccess();
        HapticFeedback.mediumImpact();
      } else if (tokens.length == 1) {
        _progValue = BigInt.parse(tokens[0], radix: radix) & _getWordMask();
        _expression = _progValue.toRadixString(radix).toUpperCase();
        _easterEggText = null;
      }
    } catch (e) {
      _lastEquation = '$_expression =';
      _expression = 'Error';
      _easterEggText = null;
      HapticFeedback.heavyImpact();
    }
  }

  void _computePreview() {
    try {
      final clean = _expression.trim();

      // Specifically for 0÷0: "Ask your ChatBot"
      if (clean == '0÷0' || clean == '0/0') {
        _previewResult = '= Ask your ChatBot! 🤖';
        _easterEggText = _calcMode == CalcMode.basic ? "Ask your ChatBot! 🤖" : null;
        return;
      }

      // Specifically for 1+: "Never Settle"
      if (clean == '1+') {
        _previewResult = '= Never Settle 🔴';
        _easterEggText = _calcMode == CalcMode.basic ? "Never Settle 🔴" : null;
        return;
      }

      if (clean == '0') {
        _previewResult = '';
        _easterEggText = _calcMode == CalcMode.basic ? "Nothing ⚪" : null;
        return;
      }

      final res = _evaluateExpression(_expression);
      if (res != null && res != 'Error' && !res.startsWith('Cannot') && res != _expression) {
        _previewResult = '= $res';
        _easterEggText = _calcMode == CalcMode.basic ? _detectEasterEgg(_expression, res) : null;
      } else {
        _previewResult = '';
        _easterEggText = _calcMode == CalcMode.basic ? _detectEasterEgg(_expression, _expression) : null;
      }
    } catch (_) {
      _previewResult = '';
      _easterEggText = null;
    }
  }

  void _evaluateFinal() {
    if (_isSlidingUp) return;

    final clean = _expression.trim();

    // 0 ÷ 0
    if (clean == '0÷0' || clean == '0/0') {
      _lastEquation = '0 ÷ 0 =';
      _slidingAns = 'Ask your ChatBot! 🤖';
      _slideEgg = "Ask your ChatBot! 🤖";
      _isSlidingUp = true;
      _previewResult = '';
      _slideUpController.forward(from: 0.0);
      SoundService().playSuccess();
      HapticFeedback.mediumImpact();
      return;
    }

    // 1+
    if (clean == '1+' || clean == '1+ ' || clean == '1+0') {
      _lastEquation = '1+ =';
      _slidingAns = 'Never Settle 🔴';
      _slideEgg = "OnePlus • Never Settle";
      _isSlidingUp = true;
      _previewResult = '';
      _slideUpController.forward(from: 0.0);
      SoundService().playSuccess();
      HapticFeedback.mediumImpact();
      return;
    }

    try {
      final res = _evaluateExpression(_expression);
      if (res != null) {
        if (res == 'Error' || res.startsWith('Cannot')) {
          _lastEquation = '$_expression =';
          _expression = 'Error';
          _previewResult = '';
          _easterEggText = _calcMode == CalcMode.basic ? "Ask your ChatBot! 🤖" : null;
          HapticFeedback.heavyImpact();
          return;
        }

        final item = CalcHistoryItem(
          expression: _expression,
          result: res,
        );

        _lastEquation = '$_expression =';
        _history.insert(0, item);
        StorageService().saveCalcHistory(_history);

        // Slide up animation trigger!
        _slidingAns = res;
        _slideEgg = _calcMode == CalcMode.basic ? _detectEasterEgg(_lastEquation, res) : null;
        _isSlidingUp = true;
        _previewResult = '';
        _slideUpController.forward(from: 0.0);

        SoundService().playSuccess();
        HapticFeedback.mediumImpact();
      } else {
        _lastEquation = '$_expression =';
        _expression = 'Error';
        _previewResult = '';
        _easterEggText = _calcMode == CalcMode.basic ? "Ask your ChatBot! 🤖" : null;
      }
    } catch (_) {
      _lastEquation = '$_expression =';
      _expression = 'Error';
      _previewResult = '';
      _easterEggText = _calcMode == CalcMode.basic ? "Ask your ChatBot! 🤖" : null;
    }
  }

  String? _detectEasterEgg(String expr, String result) {
    if (_calcMode != CalcMode.basic) return null;

    final cleanRes = result.replaceAll('=', '').trim();
    final cleanExpr = expr.replaceAll(' ', '');

    if (cleanExpr == '0÷0' || cleanExpr == '0/0' || cleanRes.contains('ChatBot') || cleanRes.contains('Chat Bot')) {
      return "Ask your ChatBot! 🤖";
    }

    if (cleanExpr.startsWith('1+') || cleanRes.contains('Never Settle')) {
      return "Never Settle 🔴";
    }

    if (cleanRes == '7') {
      return "Thala for a reason! 🦁 #7";
    }
    if (cleanRes == '13') {
      return "Unlucky ⚠️ (Friday 13th)";
    }
    if (cleanRes == '4') {
      return "Unlucky ⚠️ (Tetraphobia)";
    }
    if (cleanRes == '0' || cleanRes == '0.0' || cleanExpr == '0' || cleanExpr == '0=') {
      return "Nothing ⚪";
    }
    if (cleanRes == '67') {
      return "Six Seven 🤙";
    }
    if (cleanRes == '911') {
      return "Emergency Call 🚨";
    }
    if (cleanRes == '42') {
      return "Answer to Life 🌌";
    }
    if (cleanRes == '69') {
      return "Nice 😉";
    }
    if (cleanRes == '100') {
      return "Century! 💯";
    }
    if (cleanRes == '360') {
      return "Full Circle 🔄";
    }
    if (cleanRes == '404') {
      return "Error 404: Not Found 🔍";
    }
    if (cleanRes == '777') {
      return "Lucky 777 🎰";
    }
    if (cleanRes == '3000') {
      return "I love you 3000 ❤️";
    }
    if (cleanRes == '2026') {
      return "Current Era 2026 🚀";
    }
    if (cleanRes == '3.14' || cleanRes == '3.14159' || cleanRes.startsWith('3.14159')) {
      return "Pi Day 🥧";
    }

    // Numbers <= 10 (like 1+1 = 2, 9+1 = 10, 5+3 = 8): "It's easy! 😉"
    final d = double.tryParse(cleanRes);
    if (d != null && d > 0 && d <= 10 && d == d.roundToDouble()) {
      return "It's easy! 😉";
    }

    return null;
  }

  String _formatNumber(double val) {
    if (val.isInfinite || val.isNaN) return 'Error';
    if (val == val.roundToDouble() && val.abs() < 1e14) {
      return val.toInt().toString();
    } else {
      String str = val.toStringAsFixed(8);
      str = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return str;
    }
  }

  String? _evaluateExpression(String expr) {
    if (expr.isEmpty || expr == '0') return null;

    String clean = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', math.pi.toString())
        .replaceAll('e', math.e.toString());

    int openCount = 0;
    int closeCount = 0;
    for (int i = 0; i < clean.length; i++) {
      if (clean[i] == '(') openCount++;
      if (clean[i] == ')') closeCount++;
    }
    if (openCount > closeCount) {
      clean += ')' * (openCount - closeCount);
    }

    clean = clean.replaceAllMapped(
      RegExp(r'(\d|\))\s*(\(|sin|cos|tan|asin|acos|atan|sqrt|ln|log)'),
      (m) => '${m.group(1)}*${m.group(2)}',
    );

    try {
      double val = _parseMath(clean);
      if (val.isInfinite || val.isNaN) {
        return 'Cannot divide by 0';
      }
      return _formatNumber(val);
    } catch (e) {
      if (e.toString().contains("Divide by zero")) {
        return 'Cannot divide by 0';
      }
      return null;
    }
  }

  double _parseMath(String str) {
    int pos = -1, ch = -1;

    void nextChar() {
      ch = (++pos < str.length) ? str.codeUnitAt(pos) : -1;
    }

    bool eat(int charToEat) {
      while (ch == 32) {
        nextChar();
      }
      if (ch == charToEat) {
        nextChar();
        return true;
      }
      return false;
    }

    late double Function() parseExpression;

    double parseFactor() {
      if (eat(43)) return parseFactor(); // +
      if (eat(45)) return -parseFactor(); // -

      double x;
      int startPos = pos;
      if (eat(40)) {
        x = parseExpression();
        eat(41); // )
      } else if ((ch >= 48 && ch <= 57) || ch == 46) {
        while ((ch >= 48 && ch <= 57) || ch == 46) {
          nextChar();
        }
        x = double.parse(str.substring(startPos, pos));
      } else if (ch >= 97 && ch <= 122) {
        while (ch >= 97 && ch <= 122) {
          nextChar();
        }
        String func = str.substring(startPos, pos);
        x = parseFactor();

        if (func == "sqrt") {
          if (x < 0) throw Exception("Invalid root");
          x = math.sqrt(x);
        } else if (func == "sin") {
          x = _isRad ? math.sin(x) : math.sin(x * math.pi / 180.0);
        } else if (func == "cos") {
          x = _isRad ? math.cos(x) : math.cos(x * math.pi / 180.0);
        } else if (func == "tan") {
          x = _isRad ? math.tan(x) : math.tan(x * math.pi / 180.0);
        } else if (func == "asin") {
          x = math.asin(x);
          if (!_isRad) x = x * 180.0 / math.pi;
        } else if (func == "acos") {
          x = math.acos(x);
          if (!_isRad) x = x * 180.0 / math.pi;
        } else if (func == "atan") {
          x = math.atan(x);
          if (!_isRad) x = x * 180.0 / math.pi;
        } else if (func == "ln") {
          if (x <= 0) throw Exception("Invalid ln");
          x = math.log(x);
        } else if (func == "log") {
          if (x <= 0) throw Exception("Invalid log");
          x = math.log(x) / math.ln10;
        } else {
          throw Exception("Unknown function: $func");
        }
      } else {
        throw Exception("Unexpected char: $ch");
      }

      if (eat(94)) {
        x = math.pow(x, parseFactor()).toDouble();
      }

      if (eat(33)) {
        int n = x.toInt();
        if (n < 0 || n > 170) throw Exception("Factorial out of range");
        double fact = 1;
        for (int i = 2; i <= n; i++) {
          fact *= i;
        }
        x = fact;
      }

      return x;
    }

    double parseTerm() {
      double x = parseFactor();
      for (;;) {
        if (eat(42)) {
          x *= parseFactor();
        } else if (eat(47)) {
          double denom = parseFactor();
          if (denom == 0) throw Exception("Divide by zero");
          x /= denom;
        } else if (eat(37)) {
          x = x / 100.0;
        } else {
          return x;
        }
      }
    }

    parseExpression = () {
      double x = parseTerm();
      for (;;) {
        if (eat(43)) {
          x += parseTerm();
        } else if (eat(45)) {
          x -= parseTerm();
        } else {
          return x;
        }
      }
    };

    nextChar();
    double result = parseExpression();
    return result;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    _showToast("Copied to clipboard: $text");
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: widget.theme.fontDisplay(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: widget.theme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showHistoryModal() {
    HapticFeedback.mediumImpact();
    Stationery3DModal.show(
      context: context,
      title: "Calculation History",
      subtitle: "${_history.length} recent calculations recorded",
      theme: widget.theme,
      content: _history.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    ToolerCharacter.thinking(
                      theme: widget.theme,
                      width: 140,
                      height: 110,
                      animate: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No calculations yet\nPerform calculations to see them here",
                      textAlign: TextAlign.center,
                      style: widget.theme.fontDisplay(
                        fontSize: 14,
                        color: widget.theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.theme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.theme.border,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _expression = item.expression);
                              _computePreview();
                              Navigator.pop(context);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.expression,
                                  style: widget.theme.fontMono(
                                    fontSize: 13,
                                    color: widget.theme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "= ${item.result}",
                                  style: widget.theme.fontDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: widget.theme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: "Copy result",
                          color: widget.theme.textSecondary,
                          onPressed: () => _copyToClipboard(item.result),
                        ),
                        IconButton(
                          icon: const Icon(Icons.north_west_rounded, size: 18),
                          tooltip: "Use in calculator",
                          color: widget.theme.primary,
                          onPressed: () {
                            setState(() => _expression = item.result);
                            _computePreview();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      actions: [
        if (_history.isNotEmpty)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
            label: const Text("Clear History"),
            onPressed: () {
              setState(() => _history.clear());
              StorageService().saveCalcHistory([]);
              Navigator.pop(context);
              _showToast("History cleared");
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: widget.theme.bg,
        body: Stack(
          children: [
            // Background Notebook Grid
            CustomPaint(
              size: Size.infinite,
              painter: NotebookBackgroundPainter(
                mode: widget.theme.mode,
                pattern: NotebookPattern.grid,
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  // Quick Controls Toolbar (Basic / Scientific / Programmer Switch & History)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: widget.theme.border.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildModeTab("Basic", _calcMode == CalcMode.basic, () {
                                setState(() {
                                  _calcMode = CalcMode.basic;
                                  _expression = '0';
                                  _previewResult = '';
                                  _easterEggText = null;
                                });
                              }),
                              _buildModeTab(
                                _calcMode == CalcMode.scientific ? "Scientific" : "Sci",
                                _calcMode == CalcMode.scientific,
                                () {
                                  setState(() {
                                    _calcMode = CalcMode.scientific;
                                    _expression = '0';
                                    _previewResult = '';
                                    _easterEggText = null;
                                  });
                                },
                              ),
                              _buildModeTab(
                                _calcMode == CalcMode.programmer ? "Programming" : "Prog",
                                _calcMode == CalcMode.programmer,
                                () {
                                  setState(() {
                                    _calcMode = CalcMode.programmer;
                                    _expression = '0';
                                    _previewResult = '';
                                    _easterEggText = null;
                                    _updateProgValue();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.history_rounded, color: widget.theme.text, size: 22),
                          tooltip: "Tape History",
                          onPressed: _showHistoryModal,
                        ),
                      ],
                    ),
                  ),

                  // 1. Interactive Animated Tape Display Card
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _buildDisplayCard(),
                  ),

                  // 2. Mode-Specific Panels
                  if (_calcMode == CalcMode.scientific) _buildScientificPanel(),
                  if (_calcMode == CalcMode.programmer) _buildProgrammerBitwiseBar(),

                  // 3. Ergonomic Keypad Grid
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _calcMode == CalcMode.programmer
                          ? _buildProgrammerKeypad()
                          : Column(
                              children: [
                                _buildKeyRow(['C', '±', '%', '÷']),
                                _buildKeyRow(['7', '8', '9', '×']),
                                _buildKeyRow(['4', '5', '6', '-']),
                                _buildKeyRow(['1', '2', '3', '+']),
                                _buildKeyRow(['0', '.', '⌫', '=']),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Text(
            label,
            style: widget.theme.fontDisplay(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : widget.theme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  double _getFontSize(String expr) {
    if (expr.length > 14) return 22;
    if (expr.length > 9) return 28;
    return 34;
  }

  // --- Display Card with Smooth Animated Sizing, Expression Transitions, Clock Mode & Programmer Multi-Base ---
  Widget _buildDisplayCard() {
    final bool isError = _isErrorState();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      constraints: BoxConstraints(
        minHeight: _isClockMode
            ? 120
            : _calcMode == CalcMode.programmer
                ? 260
                : 144,
        maxHeight: _isClockMode
            ? 140
            : _calcMode == CalcMode.programmer
                ? 320
                : 144,
      ),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.theme.border,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.border.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // If Live Clock Mode is active (triggered by holding 'C' for at least 3 sec)
          if (_isClockMode) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _deactivateLiveClock,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Time with animated numbers & vertical swipe on seconds
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Hours & Minutes with smooth fade transition
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) {
                            return FadeTransition(opacity: anim, child: child);
                          },
                          child: Text(
                            "$_clockHourMin:",
                            key: ValueKey<String>(_clockHourMin),
                            style: widget.theme.fontDisplay(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: widget.theme.primary,
                            ),
                          ),
                        ),

                        // Seconds with vertical swipe transition
                        ClipRect(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            transitionBuilder: (child, anim) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, -0.7),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutBack,
                                )),
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _clockSec,
                              key: ValueKey<String>(_clockSec),
                              style: widget.theme.fontDisplay(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: widget.theme.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // AM/PM Period
                        Text(
                          _clockAmPm,
                          style: widget.theme.fontMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Date & Day (e.g. Thursday, 12 November 2026)
                    Text(
                      _clockDateDay,
                      style: widget.theme.fontMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_calcMode == CalcMode.programmer) ...[
            // PROGRAMMER MULTI-BASE DISPLAY (HEX, DEC, OCT, BIN)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "BASE CONVERSIONS",
                  style: widget.theme.fontMono(fontSize: 10, fontWeight: FontWeight.bold, color: widget.theme.textSecondary),
                ),
                InkWell(
                  onTap: _cycleWordSize,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.theme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.theme.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      "${_getWordBits()}-BIT (${_progWordSize.name.substring(0, 5).toUpperCase()})",
                      style: widget.theme.fontMono(fontSize: 10, fontWeight: FontWeight.bold, color: widget.theme.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildBaseRow(ProgBase.hex, "HEX", _progValue.toRadixString(16).toUpperCase()),
            _buildBaseRow(ProgBase.dec, "DEC", _progValue.toRadixString(10)),
            _buildBaseRow(ProgBase.oct, "OCT", _progValue.toRadixString(8)),
            _buildBaseRow(ProgBase.bin, "BIN", _formatBinNibbles(_progValue.toRadixString(2))),

            const Divider(height: 12),

            // Active Programmer Expression
            GestureDetector(
              onLongPress: () => _copyToClipboard(_expression),
              child: SingleChildScrollView(
                controller: _displayScrollController,
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _expression,
                  textAlign: TextAlign.right,
                  style: widget.theme.fontMono(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isError ? Colors.redAccent : widget.theme.primary,
                  ),
                ),
              ),
            ),
          ] else ...[
            // TOP ROW (Height 22): Memory & RAD/DEG on Left, Previous Equation on Right
            SizedBox(
              height: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (_memoryValue != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.theme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: widget.theme.primary, width: 1),
                          ),
                          child: Text(
                            "M",
                            style: widget.theme.fontMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.primary,
                            ),
                          ),
                        ),
                      if (_calcMode == CalcMode.scientific) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isRad = !_isRad);
                            _computePreview();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.theme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: widget.theme.primary.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              _isRad ? "RAD" : "DEG",
                              style: widget.theme.fontMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.theme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Previous equation if available (fades smoothly in and out without resizing container)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _lastEquation.isNotEmpty ? 1.0 : 0.0,
                    child: Text(
                      _lastEquation.isNotEmpty ? _lastEquation : '',
                      textAlign: TextAlign.right,
                      style: widget.theme.fontMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // MIDDLE ROW (Height 52): Animated Numbers Display & Slide-Up Real Answer
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isSlidingUp
                    ? AnimatedBuilder(
                        animation: _slideUpAnimation,
                        builder: (context, child) {
                          final progress = _slideUpAnimation.value;
                          return Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              // Old expression sliding up and fading away
                              Opacity(
                                opacity: (1.0 - progress).clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, -26.0 * progress),
                                  child: Text(
                                    _expression,
                                    textAlign: TextAlign.right,
                                    style: widget.theme.fontMono(
                                      fontSize: _getFontSize(_expression),
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme.text.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                              // New answer sliding up from the preview position to the center in UI theme color
                              Transform.translate(
                                offset: Offset(0, 36.0 * (1.0 - progress)),
                                child: Text(
                                  _slidingAns,
                                  textAlign: TextAlign.right,
                                  style: widget.theme.fontMono(
                                    fontSize: 18.0 + (progress * (_getFontSize(_slidingAns) - 18.0)),
                                    fontWeight: FontWeight.bold,
                                    color: widget.theme.primary, // UI THEME COLOR!
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : GestureDetector(
                        onLongPress: () => _copyToClipboard(_expression),
                        child: SingleChildScrollView(
                          controller: _displayScrollController,
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AnimatedExpressionDisplay(
                                expression: _expression,
                                style: widget.theme.fontMono(
                                  fontSize: _getFontSize(_expression),
                                  fontWeight: FontWeight.bold,
                                  color: isError ? Colors.redAccent : widget.theme.text,
                                ),
                              ),
                              if (isError) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
                                  ),
                                  child: Text(
                                    "Ask your ChatBot! 🤖",
                                    style: widget.theme.fontMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            // BOTTOM ROW (Height 28): Easter Egg Chip on Left, Live Preview Result on Right
            SizedBox(
              height: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Easter Egg Chip
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.08, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        );
                      },
                      child: (_easterEggText != null && _calcMode == CalcMode.basic)
                          ? Container(
                              key: ValueKey<String>(_easterEggText!),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.theme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.theme.primary.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _easterEggText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: widget.theme.fontDisplay(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.primary, // UI THEME COLOR!
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // Right: Preview Result (Fades out when sliding up on =)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: (!_isSlidingUp && _previewResult.isNotEmpty)
                        ? Text(
                            _previewResult,
                            key: ValueKey<String>(_previewResult),
                            style: widget.theme.fontDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.primary, // UI THEME COLOR!
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Programmer Mode: Base Row (HEX, DEC, OCT, BIN)
  Widget _buildBaseRow(ProgBase base, String label, String val) {
    final isSelected = (_progBase == base);
    return InkWell(
      onTap: () => _switchProgBase(base),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: widget.theme.primary, width: 1.2) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                label,
                style: widget.theme.fontMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? widget.theme.primary : widget.theme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                val.isEmpty ? '0' : val,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: widget.theme.fontMono(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? widget.theme.primary : widget.theme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBinNibbles(String binStr) {
    if (binStr.isEmpty) return '0000';
    // Pad to multiple of 4
    final remainder = binStr.length % 4;
    final padded = remainder == 0 ? binStr : ('0' * (4 - remainder)) + binStr;
    final parts = <String>[];
    for (int i = 0; i < padded.length; i += 4) {
      parts.add(padded.substring(i, i + 4));
    }
    return parts.join(' ');
  }

  // Programmer Mode: Bitwise Operations Toolbar
  Widget _buildProgrammerBitwiseBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: widget.theme.cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['AND', 'OR', 'XOR', 'NOT', 'LSH', 'RSH', 'MOD'].map((op) {
          return InkWell(
            onTap: () => _onKeyPress(op),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                op,
                style: widget.theme.fontMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.primary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Programmer Mode: Keypad Grid (5x5)
  Widget _buildProgrammerKeypad() {
    final rows = [
      ['A', 'B', 'C', 'AC', '⌫'],
      ['D', 'E', 'F', '(', '÷'],
      ['7', '8', '9', ')', '×'],
      ['4', '5', '6', '+', '-'],
      ['0', '1', '2', '3', '='],
    ];

    return Column(
      children: rows.map((r) {
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: r.map((k) {
              final isAllowed = _isProgKeyAllowed(k) ||
                  ['AC', 'C', '⌫', '=', '(', ')', '+', '-', '×', '÷'].contains(k);
              return _buildProgKeyBtn(k, isAllowed);
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgKeyBtn(String key, bool isAllowed) {
    final bool isOp = ['+', '-', '×', '÷'].contains(key);
    final bool isEquals = key == '=';
    final bool isClear = key == 'AC' || key == 'C';
    final bool isHexLetter = ['A', 'B', 'C', 'D', 'E', 'F'].contains(key);

    Color btnBg = widget.theme.cardBg;
    Color btnText = widget.theme.text;
    Border border = Border.all(color: widget.theme.border, width: 1.5);

    if (!isAllowed) {
      btnBg = widget.theme.bg.withValues(alpha: 0.3);
      btnText = widget.theme.textSecondary.withValues(alpha: 0.25);
      border = Border.all(color: widget.theme.border.withValues(alpha: 0.2), width: 1.0);
    } else if (isEquals) {
      btnBg = widget.theme.primary;
      btnText = Colors.white;
      border = Border.all(color: widget.theme.primary, width: 2.0);
    } else if (isClear) {
      btnBg = const Color(0xFFEF4444);
      btnText = Colors.white;
      border = Border.all(color: const Color(0xFFDC2626), width: 2.0);
    } else if (isOp) {
      btnBg = widget.theme.primary.withValues(alpha: 0.16);
      btnText = widget.theme.primary;
      border = Border.all(color: widget.theme.primary.withValues(alpha: 0.4), width: 1.5);
    } else if (isHexLetter) {
      btnBg = widget.theme.border.withValues(alpha: 0.35);
      btnText = widget.theme.primary;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: _AnimatedCalcButton(
          label: key,
          bg: btnBg,
          text: btnText,
          border: border,
          isOp: isOp,
          isEquals: isEquals,
          theme: widget.theme,
          isEnabled: isAllowed,
          onTap: isAllowed ? () => _onKeyPress(key) : () {},
          onThreeSecondHold: isClear ? _activateLiveClock : null,
          onLongPress: key == '⌫'
              ? () {
                  HapticFeedback.heavyImpact();
                  SoundService().playKey();
                  setState(() {
                    _expression = '0';
                    _previewResult = '';
                    _progValue = BigInt.zero;
                    _easterEggText = null;
                  });
                  _showToast("All cleared");
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildScientificPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.theme.cardBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSciBtn("MC", isAccent: true),
              _buildSciBtn("MR", isAccent: true),
              _buildSciBtn("M+", isAccent: true),
              _buildSciBtn("M-", isAccent: true),
              _buildSciBtn("2nd", isToggled: _is2nd),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildSciBtn(_is2nd ? "asin(" : "sin("),
              _buildSciBtn(_is2nd ? "acos(" : "cos("),
              _buildSciBtn(_is2nd ? "atan(" : "tan("),
              _buildSciBtn(_is2nd ? "x³" : "x²"),
              _buildSciBtn("^"),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildSciBtn(_is2nd ? "10^" : "sqrt("),
              _buildSciBtn("ln("),
              _buildSciBtn("log("),
              _buildSciBtn("("),
              _buildSciBtn(")"),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildSciBtn("π"),
              _buildSciBtn("e"),
              _buildSciBtn("!"),
              _buildSciBtn("1/x"),
              _buildSciBtn(_isRad ? "DEG" : "RAD", isAccent: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSciBtn(String label, {bool isAccent = false, bool isToggled = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: InkWell(
          onTap: () {
            if (label == "x²") {
              _onKeyPress("^2");
            } else if (label == "x³") {
              _onKeyPress("^3");
            } else if (label == "1/x") {
              _onKeyPress("1/(");
            } else {
              _onKeyPress(label);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: isToggled
                  ? widget.theme.primary
                  : isAccent
                      ? widget.theme.primary.withValues(alpha: 0.15)
                      : widget.theme.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToggled
                    ? widget.theme.primary
                    : widget.theme.border.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: widget.theme.fontMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isToggled
                    ? Colors.white
                    : isAccent
                        ? widget.theme.primary
                        : widget.theme.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys.map((key) => _buildKeyBtn(key)).toList(),
      ),
    );
  }

  Widget _buildKeyBtn(String key) {
    final bool isOp = ['+', '-', '×', '÷'].contains(key);
    final bool isEquals = key == '=';
    final bool isClear = key == 'C' || key == 'AC';
    final bool isSpecial = ['±', '%', '⌫'].contains(key);

    Color btnBg = widget.theme.cardBg;
    Color btnText = widget.theme.text;
    Border border = Border.all(color: widget.theme.border, width: 2.0);

    if (isEquals) {
      btnBg = widget.theme.primary;
      btnText = Colors.white;
      border = Border.all(color: widget.theme.primary, width: 2.0);
    } else if (isClear) {
      btnBg = const Color(0xFFEF4444);
      btnText = Colors.white;
      border = Border.all(color: const Color(0xFFDC2626), width: 2.0);
    } else if (isOp) {
      btnBg = widget.theme.primary.withValues(alpha: 0.16);
      btnText = widget.theme.primary;
      border = Border.all(color: widget.theme.primary.withValues(alpha: 0.4), width: 2.0);
    } else if (isSpecial) {
      btnBg = widget.theme.border.withValues(alpha: 0.5);
      btnText = widget.theme.text;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: _AnimatedCalcButton(
          label: key,
          bg: btnBg,
          text: btnText,
          border: border,
          isOp: isOp,
          isEquals: isEquals,
          theme: widget.theme,
          onTap: () => _onKeyPress(key),
          onThreeSecondHold: isClear ? _activateLiveClock : null,
          onLongPress: key == '⌫'
              ? () {
                  HapticFeedback.heavyImpact();
                  SoundService().playKey();
                  setState(() {
                    _expression = '0';
                    _previewResult = '';
                    _easterEggText = null;
                  });
                  _showToast("All cleared");
                }
              : null,
        ),
      ),
    );
  }
}

// =========================================================================
// INTERACTIVE ANIMATED BUTTON WIDGET (Spring Scale & Tactile Bounce)
// =========================================================================

class _AnimatedCalcButton extends StatefulWidget {
  final String label;
  final Color bg;
  final Color text;
  final Border border;
  final bool isOp;
  final bool isEquals;
  final StationeryTheme theme;
  final bool isEnabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onThreeSecondHold;

  const _AnimatedCalcButton({
    required this.label,
    required this.bg,
    required this.text,
    required this.border,
    required this.isOp,
    required this.isEquals,
    required this.theme,
    this.isEnabled = true,
    required this.onTap,
    this.onLongPress,
    this.onThreeSecondHold,
  });

  @override
  State<_AnimatedCalcButton> createState() => _AnimatedCalcButtonState();
}

class _AnimatedCalcButtonState extends State<_AnimatedCalcButton> {
  bool _isPressed = false;
  Timer? _holdTimer;
  bool _didTriggerHold = false;

  void _startHoldTimer() {
    _holdTimer?.cancel();
    _didTriggerHold = false;
    if (widget.onThreeSecondHold != null) {
      _holdTimer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted && _isPressed) {
          _didTriggerHold = true;
          widget.onThreeSecondHold!();
        }
      });
    }
  }

  void _cancelHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _cancelHoldTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return Container(
        decoration: BoxDecoration(
          color: widget.bg,
          borderRadius: BorderRadius.circular(16),
          border: widget.border,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: widget.theme.fontDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.text,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _startHoldTimer();
      },
      onTapUp: (_) {
        _cancelHoldTimer();
        setState(() => _isPressed = false);
        if (!_didTriggerHold) {
          widget.onTap();
        }
        _didTriggerHold = false;
      },
      onTapCancel: () {
        _cancelHoldTimer();
        setState(() => _isPressed = false);
        _didTriggerHold = false;
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.91 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(16),
            border: widget.border,
            boxShadow: [
              BoxShadow(
                color: widget.theme.border.withValues(alpha: _isPressed ? 0.1 : 0.3),
                offset: _isPressed ? const Offset(0, 1) : const Offset(0, 3),
                blurRadius: _isPressed ? 1 : 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: widget.theme.fontDisplay(
              fontSize: 22,
              fontWeight: widget.isEquals || widget.isOp ? FontWeight.w900 : FontWeight.bold,
              color: widget.text,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Number Appear & Disappear Spring Pop Micro-Animation ---
class _AnimatedExpressionDisplay extends StatelessWidget {
  final String expression;
  final TextStyle style;

  const _AnimatedExpressionDisplay({
    required this.expression,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final chars = expression.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (int i = 0; i < chars.length; i++)
          _AnimatedDigit(
            key: ValueKey('d-$i-${chars[i]}'),
            char: chars[i],
            style: style,
            isLatest: i == chars.length - 1,
          ),
      ],
    );
  }
}

class _AnimatedDigit extends StatefulWidget {
  final String char;
  final TextStyle style;
  final bool isLatest;

  const _AnimatedDigit({
    super.key,
    required this.char,
    required this.style,
    this.isLatest = false,
  });

  @override
  State<_AnimatedDigit> createState() => _AnimatedDigitState();
}

class _AnimatedDigitState extends State<_AnimatedDigit> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.isLatest) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Text(
            widget.char,
            style: widget.style,
          ),
        ),
      ),
    );
  }
}
