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

enum CalcMode { basic, scientific, programmer }
enum ProgBase { hex, dec, oct, bin }
enum ProgWordSize { qword64, dword32, word16, byte8 }

class CalculatorScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CalculatorScreen({super.key, required this.theme});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
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

  // Programmer State
  ProgBase _progBase = ProgBase.dec;
  ProgWordSize _progWordSize = ProgWordSize.qword64;
  BigInt _progValue = BigInt.zero;

  // Clock Mode on holding 'C' / 'AC' for 2-3 sec
  bool _isClockMode = false;
  String _clockTimeStr = '';
  String _clockDateStr = '';
  Timer? _clockTimer;

  final ScrollController _displayScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
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

  // --- Real-Time Clock Mode on Holding 'C' ---
  void _activateLiveClock() {
    SoundService().playSuccess();
    HapticFeedback.heavyImpact();
    _clockTimer?.cancel();
    setState(() {
      _isClockMode = true;
      _clockTimeStr = DateFormat('hh:mm:ss a').format(DateTime.now());
      _clockDateStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isClockMode) {
        setState(() {
          _clockTimeStr = DateFormat('hh:mm:ss a').format(DateTime.now());
          _clockDateStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
        });
      }
    });
    _showToast("🕒 Real-Time Clock Mode (Tap any key to exit)");
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
        _easterEggText = _detectProgEasterEgg(_progValue);
      }
    } catch (_) {}
  }

  void _switchProgBase(ProgBase newBase) {
    SoundService().playClick();
    HapticFeedback.selectionClick();
    setState(() {
      _progBase = newBase;
      final radix = newBase == ProgBase.hex ? 16 : newBase == ProgBase.oct ? 8 : newBase == ProgBase.bin ? 2 : 10;
      _expression = _progValue.toRadixString(radix).toUpperCase();
      _easterEggText = _detectProgEasterEgg(_progValue);
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
        _easterEggText = _detectProgEasterEgg(res);
        SoundService().playSuccess();
        HapticFeedback.mediumImpact();
      } else if (tokens.length == 1) {
        _progValue = BigInt.parse(tokens[0], radix: radix) & _getWordMask();
        _expression = _progValue.toRadixString(radix).toUpperCase();
        _easterEggText = _detectProgEasterEgg(_progValue);
      }
    } catch (e) {
      _expression = 'Error';
      _easterEggText = "Ask your ChatBot! 🤖 (Division / Syntax Error)";
      HapticFeedback.heavyImpact();
    }
  }

  String? _detectProgEasterEgg(BigInt val) {
    final hex = val.toRadixString(16).toUpperCase();
    final bin = val.toRadixString(2);
    final intVal = val.toInt();

    if (hex == 'DEADBEEF') return "Dead Beef 🥩 (Classic Memory Marker)";
    if (hex == 'CAFEBABE') return "Cafe Babe ☕ (Java Class Magic Header)";
    if (hex == 'BADA55') return "Badass Hex 🕶️ (Dev Culture)";
    if (hex == 'C001') return "Cool Hex 😎 (Leet System)";
    if (hex == '1337') return "Elite 👾 (Leet Code 1337)";
    if (intVal == 42 || hex == '2A' || bin == '101010') return "42 • Answer to Life, Universe & Everything 🌌";
    if (intVal == 127 || hex == '7F') return "Max Signed 8-bit Int (0x7F) 🔢";
    if (intVal == 255 || hex == 'FF') return "Full Byte 255 (0xFF) 💾";
    if (intVal == 65535 || hex == 'FFFF') return "Max 16-bit Int (65535) 🌐";
    if (intVal == 404 || hex == '194') return "HTTP 404 Not Found 🔍";
    if (intVal == 0) return "Null / Zero Pointer ⚪";

    return null;
  }

  void _computePreview() {
    try {
      final clean = _expression.trim();

      if (clean == '0÷0' || clean == '0/0') {
        _previewResult = '= Ask your ChatBot! 🤖';
        _easterEggText = "0÷0 is mathematically indeterminate!";
        return;
      }

      if (clean == '1+') {
        _previewResult = '= Never Settle 🔴';
        _easterEggText = "OnePlus • Never Settle";
        return;
      }

      final res = _evaluateExpression(_expression);
      if (res != null && res != 'Error' && !res.startsWith('Cannot') && res != _expression) {
        _previewResult = '= $res';
        _easterEggText = _detectEasterEgg(_expression, res);
      } else {
        _previewResult = '';
        _easterEggText = _detectEasterEgg(_expression, _expression);
      }
    } catch (_) {
      _previewResult = '';
      _easterEggText = null;
    }
  }

  void _evaluateFinal() {
    final clean = _expression.trim();

    if (clean == '0÷0' || clean == '0/0') {
      _lastEquation = '0 ÷ 0 =';
      _expression = 'Ask your ChatBot! 🤖';
      _previewResult = '';
      _easterEggText = "0÷0 is indeterminate. Ask your AI ChatBot!";
      SoundService().playSuccess();
      HapticFeedback.mediumImpact();
      return;
    }

    if (clean == '1+' || clean == '1+ ' || clean == '1+0') {
      _lastEquation = '1+ =';
      _expression = 'Never Settle 🔴';
      _previewResult = '';
      _easterEggText = "OnePlus Flagship Spirit: Never Settle!";
      SoundService().playSuccess();
      HapticFeedback.mediumImpact();
      return;
    }

    try {
      final res = _evaluateExpression(_expression);
      if (res != null) {
        if (res == 'Error' || res.startsWith('Cannot')) {
          _expression = res;
          _previewResult = '';
          _easterEggText = "Ask your ChatBot! 🤖";
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

        _easterEggText = _detectEasterEgg(_expression, res);
        _expression = res;
        _previewResult = '';
        SoundService().playSuccess();
        HapticFeedback.mediumImpact();
      } else {
        _expression = 'Error';
        _easterEggText = "Ask your ChatBot! 🤖";
      }
    } catch (_) {
      _expression = 'Error';
      _easterEggText = "Ask your ChatBot! 🤖";
    }
  }

  String? _detectEasterEgg(String expr, String result) {
    if (_isErrorState()) {
      return "Ask your ChatBot! 🤖";
    }

    final cleanRes = result.replaceAll('=', '').trim();
    final cleanExpr = expr.replaceAll(' ', '');

    if (cleanExpr == '0÷0' || cleanExpr == '0/0') {
      return "Ask your ChatBot! 🤖 (Indeterminate)";
    }

    if (cleanExpr == '1+' || cleanExpr == '1+=' || cleanRes == 'Never Settle 🔴') {
      return "Never Settle 🔴 (OnePlus)";
    }

    if (cleanRes == '0' || cleanRes == '0.0' || cleanExpr == '0') {
      return "Nothing ⚪";
    }

    if (cleanRes == '7') {
      return "Thala for a reason! 🦁 #7";
    }
    if (cleanRes == '67') {
      return "Six Seven 🤙 (Prime & Iconic)";
    }
    if (cleanRes == '911') {
      return "Emergency Call 🚨 911";
    }
    if (cleanRes == '13') {
      return "Triskaidekaphobia (Unlucky 13 in West) 🐈‍⬛";
    }
    if (cleanRes == '4') {
      return "Tetraphobia (Unlucky 4 in East Asia) 🏮";
    }
    if (cleanRes == '42') {
      return "Answer to Ultimate Question of Life 🌌";
    }
    if (cleanRes == '69') {
      return "Nice! 😏";
    }
    if (cleanRes == '100') {
      return "Century! 💯";
    }
    if (cleanRes == '360') {
      return "Full Circle 🔄 (360°)";
    }
    if (cleanRes == '404') {
      return "Error 404: Not Found 🔍";
    }
    if (cleanRes == '777') {
      return "Lucky 777 Jackpot 🎰";
    }
    if (cleanRes == '3000') {
      return "I love you 3000 💖";
    }
    if (cleanRes == '2026') {
      return "Current Era 🚀 2026";
    }
    if (cleanRes == '3.14' || cleanRes == '3.14159' || cleanRes.startsWith('3.14159')) {
      return "Pi Day 🥧 (3.14159...)";
    }

    final parsed = double.tryParse(cleanRes);
    if (parsed != null && parsed > 0 && parsed <= 10 && parsed == parsed.roundToDouble()) {
      return "It's easy! 😉 (Quick Math)";
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
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 48,
                      color: widget.theme.textSecondary.withValues(alpha: 0.5),
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
                                });
                              }),
                              _buildModeTab("Sci", _calcMode == CalcMode.scientific, () {
                                setState(() {
                                  _calcMode = CalcMode.scientific;
                                  _expression = '0';
                                  _previewResult = '';
                                });
                              }),
                              _buildModeTab("Prog", _calcMode == CalcMode.programmer, () {
                                setState(() {
                                  _calcMode = CalcMode.programmer;
                                  _expression = '0';
                                  _previewResult = '';
                                  _updateProgValue();
                                });
                              }),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Tooltip(
                              message: "Physical Keyboard Supported: Numbers, + - * / Enter, ESC, Backspace",
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: widget.theme.border.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.keyboard_outlined, size: 14, color: widget.theme.textSecondary),
                                    const SizedBox(width: 3),
                                    Text(
                                      "KB Ready",
                                      style: widget.theme.fontMono(fontSize: 10, color: widget.theme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.history_rounded, color: widget.theme.text, size: 22),
                              tooltip: "Tape History",
                              onPressed: _showHistoryModal,
                            ),
                          ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: widget.theme.fontDisplay(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : widget.theme.textSecondary,
          ),
        ),
      ),
    );
  }

  // --- Display Card with Smooth Animated Sizing, Expression Transitions, Clock Mode & Programmer Multi-Base ---
  Widget _buildDisplayCard() {
    final bool isError = _isErrorState();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isClockMode ? const Color(0xFFF39C12) : widget.theme.border,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isClockMode ? const Color(0xFFF39C12) : widget.theme.border).withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If Live Clock Mode is active (triggered by holding 'C' for 2-3 sec)
          if (_isClockMode) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFFF39C12)),
                    const SizedBox(width: 5),
                    Text(
                      "LIVE REAL-TIME CLOCK",
                      style: widget.theme.fontMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF39C12),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _deactivateLiveClock,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.theme.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Exit Clock",
                      style: widget.theme.fontMono(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _clockTimeStr,
                  key: ValueKey<String>(_clockTimeStr),
                  style: widget.theme.fontDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: widget.theme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _clockDateStr,
                style: widget.theme.fontMono(
                  fontSize: 12,
                  color: widget.theme.textSecondary,
                  fontWeight: FontWeight.bold,
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

            // Easter Egg Row for Programmer Mode
            if (_easterEggText != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.theme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _easterEggText!,
                    style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold, color: widget.theme.primary),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Normal Basic & Scientific Calculator Display Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_calcMode == CalcMode.scientific)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isRad = !_isRad);
                      _computePreview();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.theme.primary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _isRad ? "RAD" : "DEG",
                        style: widget.theme.fontMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.theme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Previous equation if available
            if (_lastEquation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text(
                  _lastEquation,
                  textAlign: TextAlign.right,
                  style: widget.theme.fontMono(
                    fontSize: 13,
                    color: widget.theme.textSecondary,
                  ),
                ),
              ),

            // Primary Interactive Expression with smooth AnimatedSwitcher
            GestureDetector(
              onLongPress: () => _copyToClipboard(_expression),
              child: SingleChildScrollView(
                controller: _displayScrollController,
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _expression,
                        key: ValueKey<String>(_expression),
                        textAlign: TextAlign.right,
                        style: widget.theme.fontMono(
                          fontSize: _expression.length > 14
                              ? 26
                              : _expression.length > 9
                                  ? 32
                                  : 38,
                          fontWeight: FontWeight.bold,
                          color: isError ? Colors.redAccent : widget.theme.text,
                        ),
                      ),
                    ),
                    // If error state: show "Ask your ChatBot! 🤖" right next to it!
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

            // Live Result Preview with Pop-up Scale Transition & Easter Egg Chip
            const SizedBox(height: 4),
            SizedBox(
              height: 26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Easter Egg chip / badge (left/center)
                  if (_easterEggText != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          style: widget.theme.fontMono(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Preview Result pop-up
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: _previewResult.isNotEmpty
                        ? Text(
                            _previewResult,
                            key: ValueKey<String>(_previewResult),
                            style: widget.theme.fontDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.primary,
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
          onLongPress: isClear
              ? _activateLiveClock
              : key == '⌫'
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
          onLongPress: isClear
              ? _activateLiveClock
              : key == '⌫'
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
  });

  @override
  State<_AnimatedCalcButton> createState() => _AnimatedCalcButtonState();
}

class _AnimatedCalcButtonState extends State<_AnimatedCalcButton> {
  bool _isPressed = false;

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
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
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
