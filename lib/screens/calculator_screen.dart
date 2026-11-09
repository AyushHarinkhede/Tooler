import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  bool _isScientific = false;
  List<CalcHistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService().loadCalcHistory();
    setState(() => _history = list);
  }

  void _onKeyPress(String key) {
    SoundService().playKey();
    setState(() {
      if (key == 'C') {
        _expression = '0';
        _previewResult = '';
      } else if (key == '⌫') {
        if (_expression.length > 1) {
          _expression = _expression.substring(0, _expression.length - 1);
        } else {
          _expression = '0';
        }
        _computePreview();
      } else if (key == '=') {
        _evaluateFinal();
      } else {
        if (_expression == '0' || _expression == 'Error') {
          if (['+', '×', '÷', '%', '^'].contains(key)) {
            _expression = '0$key';
          } else {
            _expression = key;
          }
        } else {
          _expression += key;
        }
        _computePreview();
      }
    });
  }

  void _computePreview() {
    try {
      final res = _evaluateExpression(_expression);
      _previewResult = res != null ? '= $res' : '';
    } catch (_) {
      _previewResult = '';
    }
  }

  void _evaluateFinal() {
    try {
      final res = _evaluateExpression(_expression);
      if (res != null) {
        final item = CalcHistoryItem(
          expression: _expression,
          result: res,
        );
        _history.insert(0, item);
        StorageService().saveCalcHistory(_history);
        _expression = res;
        _previewResult = '';
        SoundService().playSuccess();
      } else {
        _expression = 'Error';
      }
    } catch (_) {
      _expression = 'Error';
    }
  }

  String? _evaluateExpression(String expr) {
    if (expr.isEmpty || expr == '0') return null;

    String clean = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', math.pi.toString())
        .replaceAll('e', math.e.toString());

    // Evaluate basic math with operator precedence
    try {
      double val = _parseMath(clean);
      if (val.isInfinite || val.isNaN) return 'Error';
      if (val == val.roundToDouble()) {
        return val.toInt().toString();
      } else {
        return val.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    } catch (_) {
      return null;
    }
  }

  // Recursive descent or simple expression evaluator
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
          x = math.sqrt(x);
        } else if (func == "sin") {
          x = math.sin(x * math.pi / 180.0);
        } else if (func == "cos") {
          x = math.cos(x * math.pi / 180.0);
        } else if (func == "tan") {
          x = math.tan(x * math.pi / 180.0);
        } else if (func == "ln") {
          x = math.log(x);
        } else if (func == "log") {
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
          x /= parseFactor(); // /
        } else if (eat(37)) {
          x = x * (parseFactor() / 100.0); // %
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

  void _showHistoryModal() {
    Stationery3DModal.show(
      context: context,
      title: "Calculation History",
      subtitle: "Recent answers on paper tape",
      theme: widget.theme,
      content: _history.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No calculation history yet.\nSolve something first!",
                  textAlign: TextAlign.center,
                  style: widget.theme.fontDoodle(fontSize: 16),
                ),
              ),
            )
          : Column(
              children: _history.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.theme.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.theme.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.expression,
                              style: widget.theme.fontMono(
                                fontSize: 13,
                                color: widget.theme.text.withOpacity(0.7),
                              ),
                            ),
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
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 20),
                        tooltip: "Recall to display",
                        onPressed: () {
                          setState(() {
                            _expression = item.result;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
      actions: [
        if (_history.isNotEmpty)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() => _history.clear());
              StorageService().saveCalcHistory([]);
              Navigator.pop(context);
            },
            child: const Text("Clear All"),
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Calculator",
          style: widget.theme.fontDisplay(fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isScientific ? Icons.functions : Icons.calculate_outlined,
              color: widget.theme.text,
            ),
            tooltip: _isScientific ? "Basic Mode" : "Scientific Mode",
            onPressed: () => setState(() => _isScientific = !_isScientific),
          ),
          IconButton(
            icon: Icon(Icons.history, color: widget.theme.text),
            tooltip: "Tape History",
            onPressed: _showHistoryModal,
          ),
        ],
      ),
      body: Stack(
        children: [
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
                // Display Paper Tape
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: widget.theme.doodleCard(
                    color: widget.theme.cardBg,
                    borderWidth: 2.5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _expression,
                          style: widget.theme.fontMono(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _previewResult,
                        style: widget.theme.fontDisplay(
                          fontSize: 20,
                          color: widget.theme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scientific Toolbar Row
                if (_isScientific)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSciKey('sin('),
                        _buildSciKey('cos('),
                        _buildSciKey('tan('),
                        _buildSciKey('sqrt('),
                        _buildSciKey('ln('),
                        _buildSciKey('log('),
                        _buildSciKey('^'),
                        _buildSciKey('!'),
                        _buildSciKey('('),
                        _buildSciKey(')'),
                        _buildSciKey('π'),
                        _buildSciKey('e'),
                      ],
                    ),
                  ),

                // Keypad Grid
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildKeyRow(['C', '(', ')', '÷']),
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

  Widget _buildKeyRow(List<String> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys.map((key) => _buildKeyBtn(key)).toList(),
      ),
    );
  }

  Widget _buildKeyBtn(String key) {
    final bool isOp = ['+', '-', '×', '÷', '%', '(', ')'].contains(key);

    Color btnBg = widget.theme.cardBg;
    Color btnText = widget.theme.text;

    if (key == '=') {
      btnBg = widget.theme.primary;
      btnText = Colors.white;
    } else if (key == 'C') {
      btnBg = const Color(0xFFFF4757);
      btnText = Colors.white;
    } else if (isOp) {
      btnBg = widget.theme.secondary.withOpacity(0.35);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: InkWell(
          onTap: () => _onKeyPress(key),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: btnBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.theme.border, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.border.withOpacity(0.3),
                  offset: const Offset(2, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              key,
              style: widget.theme.fontDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: btnText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSciKey(String key) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.theme.accent.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.theme.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            key,
            style: widget.theme.fontMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.theme.text,
            ),
          ),
        ),
      ),
    );
  }
}
