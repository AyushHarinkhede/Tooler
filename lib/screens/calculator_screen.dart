import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../models/calc_history_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets_3d/stationery_3d_modal.dart';

class CalculatorScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CalculatorScreen({super.key, required this.theme});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '0';
  String _previewResult = '';
  String _lastEquation = '';
  bool _isScientific = false;
  bool _isRad = false; // Angle mode: false = DEG, true = RAD
  bool _is2nd = false; // 2nd function toggle for inverse trig / alt powers
  double? _memoryValue;
  List<CalcHistoryItem> _history = [];
  final ScrollController _displayScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _displayScrollController.dispose();
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

  // Handle all button presses
  void _onKeyPress(String key) {
    SoundService().playKey();
    HapticFeedback.lightImpact();

    setState(() {
      if (key == 'AC' || key == 'C') {
        _expression = '0';
        _previewResult = '';
        _lastEquation = '';
      } else if (key == '⌫') {
        _handleBackspace();
      } else if (key == '=') {
        _evaluateFinal();
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
        _appendKey(key);
      }
    });

    _scrollToEnd();
  }

  bool _isErrorState() {
    return _expression == 'Error' || _expression.startsWith('Cannot');
  }

  void _handleBackspace() {
    if (_isErrorState() || _expression.length <= 1) {
      _expression = '0';
      _previewResult = '';
      return;
    }

    // Check for multi-character functions to delete in one go (e.g. sin(, cos(, sqrt()
    final multiCharTokens = [
      'sin(', 'cos(', 'tan(', 'asin(', 'acos(', 'atan(',
      'sqrt(', 'ln(', 'log(', '10^', 'e^'
    ];

    bool tokenRemoved = false;
    for (final token in multiCharTokens) {
      if (_expression.endsWith(token)) {
        _expression = _expression.substring(0, _expression.length - token.length);
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

    _computePreview();
  }

  void _toggleSign() {
    if (_isErrorState()) return;

    if (_expression == '0') return;

    // Toggle sign of the trailing number
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
    return ch == '+' || ch == '-' || ch == '×' || ch == '÷' || ch == '^';
  }

  void _appendKey(String key) {
    if (_isErrorState()) {
      _expression = '0';
    }

    // Handle operator replacement if user changes mind
    if (_isOperator(key)) {
      if (_expression.isNotEmpty && _isOperator(_expression[_expression.length - 1])) {
        _expression = _expression.substring(0, _expression.length - 1) + key;
        _computePreview();
        return;
      }
    }

    // Prevent duplicate decimal point in current number segment
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

  void _computePreview() {
    try {
      final res = _evaluateExpression(_expression);
      if (res != null && res != 'Error' && !res.startsWith('Cannot') && res != _expression) {
        _previewResult = '= $res';
      } else {
        _previewResult = '';
      }
    } catch (_) {
      _previewResult = '';
    }
  }

  void _evaluateFinal() {
    try {
      final res = _evaluateExpression(_expression);
      if (res != null) {
        if (res == 'Error' || res.startsWith('Cannot')) {
          _expression = res;
          _previewResult = '';
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

        _expression = res;
        _previewResult = '';
        SoundService().playSuccess();
        HapticFeedback.mediumImpact();
      } else {
        _expression = 'Error';
      }
    } catch (_) {
      _expression = 'Error';
    }
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

    // Auto close open parentheses
    int openCount = 0;
    int closeCount = 0;
    for (int i = 0; i < clean.length; i++) {
      if (clean[i] == '(') openCount++;
      if (clean[i] == ')') closeCount++;
    }
    if (openCount > closeCount) {
      clean += ')' * (openCount - closeCount);
    }

    // Insert implicit multiplication e.g. 2(3) -> 2*(3), )2 -> )*2, ) ( -> )*(
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

  // Recursive descent math evaluator
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
        // (
        x = parseExpression();
        eat(41); // )
      } else if ((ch >= 48 && ch <= 57) || ch == 46) {
        // numbers
        while ((ch >= 48 && ch <= 57) || ch == 46) {
          nextChar();
        }
        x = double.parse(str.substring(startPos, pos));
      } else if (ch >= 97 && ch <= 122) {
        // functions
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

      // Handle power ^
      if (eat(94)) {
        x = math.pow(x, parseFactor()).toDouble();
      }

      // Handle factorial !
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
          x *= parseFactor(); // *
        } else if (eat(47)) {
          double denom = parseFactor();
          if (denom == 0) throw Exception("Divide by zero");
          x /= denom; // /
        } else if (eat(37)) {
          x = x / 100.0; // %
        } else {
          return x;
        }
      }
    }

    parseExpression = () {
      double x = parseTerm();
      for (;;) {
        if (eat(43)) {
          x += parseTerm(); // +
        } else if (eat(45)) {
          x -= parseTerm(); // -
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
    return Scaffold(
      backgroundColor: widget.theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.theme.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Calculator",
          style: widget.theme.fontDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: widget.theme.text,
          ),
        ),
        actions: [
          // Standard / Scientific Toggle Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: widget.theme.border.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTab("Basic", !_isScientific, () {
                  setState(() => _isScientific = false);
                }),
                _buildModeTab("Sci", _isScientific, () {
                  setState(() => _isScientific = true);
                }),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.history_rounded, color: widget.theme.text),
            tooltip: "Tape History",
            onPressed: _showHistoryModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
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
            child: Column(
              children: [
                // 1. Interactive Tape Display Card
                _buildDisplayCard(),

                // 2. Scientific Toolbar (if activated)
                if (_isScientific) _buildScientificPanel(),

                // 3. Ergonomic Keypad Grid
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
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

  Widget _buildDisplayCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.theme.border, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: widget.theme.border.withValues(alpha: 0.35),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Memory badge & Deg/Rad indicator
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
              if (_isScientific)
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

          // Primary Interactive Expression (Auto-scaling & Scrollable)
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
                  fontSize: _expression.length > 14
                      ? 26
                      : _expression.length > 9
                          ? 32
                          : 38,
                  fontWeight: FontWeight.bold,
                  color: _isErrorState() ? Colors.redAccent : widget.theme.text,
                ),
              ),
            ),
          ),

          // Live Result Preview (Subtle accent)
          const SizedBox(height: 4),
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.centerRight,
              child: _previewResult.isNotEmpty
                  ? Text(
                      _previewResult,
                      style: widget.theme.fontDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.primary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
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
          // Row 1: Memory & Trig functions
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
          // Row 2: Advanced Math
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
          // Row 3: Roots, logs, constants
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
          // Row 4: Constants & Specials
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
        child: InkWell(
          onTap: () => _onKeyPress(key),
          onLongPress: key == '⌫'
              ? () {
                  HapticFeedback.heavyImpact();
                  SoundService().playKey();
                  setState(() {
                    _expression = '0';
                    _previewResult = '';
                  });
                  _showToast("All cleared");
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: btnBg,
              borderRadius: BorderRadius.circular(16),
              border: border,
              boxShadow: [
                BoxShadow(
                  color: widget.theme.border.withValues(alpha: 0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              key,
              style: widget.theme.fontDisplay(
                fontSize: 24,
                fontWeight: isEquals || isOp ? FontWeight.w900 : FontWeight.bold,
                color: btnText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
