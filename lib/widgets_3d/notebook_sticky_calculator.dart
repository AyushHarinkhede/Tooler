import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../models/calc_history_model.dart';
import 'stationery_3d_modal.dart';

/// ---------------------------------------------------------------------------
/// MINIMAL AESTHETIC NOTEBOOK STICKY CALCULATOR
/// Inspired by Tooler.html .sticky-calculator:
/// - Flat pastel sticky note card sitting on notebook rules
/// - Clean washi tape strips on top corners
/// - Zero pseudo-3D bulky bevels or heavy shadows
/// - Ruled paper display with authentic ink lettering
/// - Foldable / Expandable minimal keypad with scientific toggle
/// ---------------------------------------------------------------------------

class NotebookStickyCalculator extends StatefulWidget {
  final StationeryTheme theme;

  const NotebookStickyCalculator({super.key, required this.theme});

  @override
  State<NotebookStickyCalculator> createState() => _NotebookStickyCalculatorState();
}

class _NotebookStickyCalculatorState extends State<NotebookStickyCalculator> {
  bool _isExpanded = true;
  bool _isScientific = false;

  String _expression = '0';
  String _previewResult = '';
  List<CalcHistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService().loadCalcHistory();
    if (mounted) setState(() => _history = list);
  }

  void _onKeyPress(String key) {
    SoundService().playKey();
    setState(() {
      if (key == 'C') {
        _expression = '0';
        _previewResult = '';
      } else if (key == '⌫') {
        if (_expression.length > 1 && _expression != 'Error') {
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
        final item = CalcHistoryItem(expression: _expression, result: res);
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
        .replaceAll('π', '${math.pi}')
        .replaceAll('e', '${math.e}');

    try {
      double val = _parseMath(clean);
      if (val.isNaN || val.isInfinite) return 'Error';
      if (val == val.roundToDouble()) {
        return val.toInt().toString();
      }
      return val.toStringAsFixed(4).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    } catch (_) {
      return null;
    }
  }

  double _parseMath(String str) {
    final tokens = _tokenize(str);
    return _MathEvaluator(tokens).parse();
  }

  List<String> _tokenize(String s) {
    final List<String> list = [];
    int i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (RegExp(r'\s').hasMatch(ch)) {
        i++;
        continue;
      }
      if (RegExp(r'[0-9.]').hasMatch(ch)) {
        int start = i;
        while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) {
          i++;
        }
        list.add(s.substring(start, i));
      } else if (RegExp(r'[a-zA-Z]').hasMatch(ch)) {
        int start = i;
        while (i < s.length && RegExp(r'[a-zA-Z]').hasMatch(s[i])) {
          i++;
        }
        list.add(s.substring(start, i));
      } else {
        list.add(ch);
        i++;
      }
    }
    return list;
  }

  void _showHistoryModal() {
    SoundService().playClick();
    Stationery3DModal.show(
      context: context,
      title: "Calculation Tape",
      subtitle: "Recent answers on paper ribbon",
      theme: widget.theme,
      content: _history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "No calculation history yet.",
                  style: widget.theme.fontDoodle(fontSize: 15),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length > 8 ? 8 : _history.length,
              separatorBuilder: (_, __) => Divider(
                color: widget.theme.border.withValues(alpha: 0.2),
                height: 12,
              ),
              itemBuilder: (context, idx) {
                final itm = _history[idx];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long, size: 18),
                  title: Text(
                    itm.expression,
                    style: GoogleFonts.architectsDaughter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.text,
                    ),
                  ),
                  trailing: Text(
                    "= ${itm.result}",
                    style: GoogleFonts.architectsDaughter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.primary,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _expression = itm.result;
                      _previewResult = '';
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Sticky Note Card Body (Flat pastel, zero heavy shadow)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3), // Soft Butter Pastel Post-it
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFCA8A04),
                width: 1.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row: Title & Action Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "NOTEBOOK CALCULATOR",
                          style: GoogleFonts.patrickHand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF713F12),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        // Scientific Toggle Button
                        InkWell(
                          onTap: () {
                            SoundService().playClick();
                            setState(() => _isScientific = !_isScientific);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: _isScientific
                                  ? const Color(0xFFCA8A04)
                                  : Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCA8A04), width: 1.2),
                            ),
                            child: Text(
                              _isScientific ? "SCI ON" : "SCI",
                              style: GoogleFonts.robotoMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: _isScientific ? Colors.white : const Color(0xFF713F12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // History Tape Button
                        InkWell(
                          onTap: _showHistoryModal,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCA8A04), width: 1.2),
                            ),
                            child: Text(
                              "TAPE",
                              style: GoogleFonts.robotoMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF713F12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Expand/Collapse Fold Arrow
                        InkWell(
                          onTap: () {
                            SoundService().playClick();
                            setState(() => _isExpanded = !_isExpanded);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCA8A04).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 18,
                              color: const Color(0xFF713F12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Ruled Paper Calculator Display (Ink Pen handwriting style)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFCA8A04).withValues(alpha: 0.5), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Preview result
                      if (_previewResult.isNotEmpty)
                        Text(
                          _previewResult,
                          style: GoogleFonts.architectsDaughter(
                            fontSize: 13,
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      // Main expression
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _expression,
                          maxLines: 1,
                          style: GoogleFonts.architectsDaughter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B), // Dark graphite ink
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Keypad (Collapsible)
                if (_isExpanded) ...[
                  const SizedBox(height: 10),

                  // Scientific row when active
                  if (_isScientific) ...[
                    Row(
                      children: ['sin', 'cos', 'tan', 'π', 'e', '√'].map((k) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: _buildKeyBtn(k, isSci: true),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: ['ln', 'log', '^', '(', ')', '!'].map((k) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: _buildKeyBtn(k, isSci: true),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Standard rows
                  ...[
                    ['7', '8', '9', '÷'],
                    ['4', '5', '6', '×'],
                    ['1', '2', '3', '-'],
                    ['0', '.', '%', '+'],
                  ].map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: row.map((k) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
                              child: _buildKeyBtn(k),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),

                  const SizedBox(height: 4),

                  // Bottom Action Row: Clear, Backspace, Calculate
                  Row(
                    children: [
                      // Clear 'C'
                      Expanded(
                        flex: 1,
                        child: _buildKeyBtn('C', color: const Color(0xFFFEE2E2), textColor: const Color(0xFF991B1B)),
                      ),
                      const SizedBox(width: 6),
                      // Backspace
                      Expanded(
                        flex: 1,
                        child: _buildKeyBtn('⌫', color: const Color(0xFFFED7AA), textColor: const Color(0xFFC2410C)),
                      ),
                      const SizedBox(width: 6),
                      // Equals '='
                      Expanded(
                        flex: 2,
                        child: _buildKeyBtn(
                          '= CALCULATE',
                          color: const Color(0xFFBBF7D0),
                          textColor: const Color(0xFF14532D),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 2 Washi Tapes at Top Corners (as in Tooler.html)
          Positioned(
            top: -2,
            left: 24,
            child: Transform.rotate(
              angle: -0.06,
              child: Container(
                width: 36,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xBBFFF275),
                  borderRadius: BorderRadius.circular(1.5),
                  border: Border.all(color: const Color(0x55CA8A04), width: 0.8),
                ),
              ),
            ),
          ),
          Positioned(
            top: -2,
            right: 28,
            child: Transform.rotate(
              angle: 0.05,
              child: Container(
                width: 36,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xBBFFF275),
                  borderRadius: BorderRadius.circular(1.5),
                  border: Border.all(color: const Color(0x55CA8A04), width: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyBtn(
    String key, {
    Color? color,
    Color? textColor,
    bool isSci = false,
  }) {
    final bool isOp = ['÷', '×', '-', '+'].contains(key);
    final Color btnBg = color ??
        (isSci
            ? const Color(0xFFFEF3C7)
            : isOp
                ? const Color(0xFFFED7AA)
                : Colors.white);

    final Color btnText = textColor ??
        (isSci
            ? const Color(0xFF78350F)
            : isOp
                ? const Color(0xFFC2410C)
                : const Color(0xFF1E293B));

    return InkWell(
      onTap: () => _onKeyPress(key == '= CALCULATE' ? '=' : key),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: isSci ? 28 : 34,
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFCA8A04).withValues(alpha: 0.7), width: 1.2),
        ),
        child: Center(
          child: Text(
            key,
            style: isSci
                ? GoogleFonts.robotoMono(fontSize: 10, fontWeight: FontWeight.bold, color: btnText)
                : GoogleFonts.architectsDaughter(
                    fontSize: isOp ? 17 : 15,
                    fontWeight: FontWeight.bold,
                    color: btnText,
                  ),
          ),
        ),
      ),
    );
  }
}

class _MathEvaluator {
  final List<String> tokens;
  int idx = 0;

  _MathEvaluator(this.tokens);

  double parse() => parseExpression();

  double parseExpression() {
    double left = parseTerm();
    while (idx < tokens.length) {
      final op = tokens[idx];
      if (op == '+' || op == '-') {
        idx++;
        final right = parseTerm();
        left = (op == '+') ? left + right : left - right;
      } else {
        break;
      }
    }
    return left;
  }

  double parseTerm() {
    double left = parseFactor();
    while (idx < tokens.length) {
      final op = tokens[idx];
      if (op == '*' || op == '/' || op == '%') {
        idx++;
        final right = parseFactor();
        if (op == '*') left *= right;
        if (op == '/') left /= right;
        if (op == '%') left %= right;
      } else {
        break;
      }
    }
    return left;
  }

  double parseFactor() {
    if (idx >= tokens.length) return 0.0;
    String t = tokens[idx++];

    if (t == '-') return -parseFactor();
    if (t == '+') return parseFactor();

    if (t == 'sin') return math.sin(_toRadians(parseFactor()));
    if (t == 'cos') return math.cos(_toRadians(parseFactor()));
    if (t == 'tan') return math.tan(_toRadians(parseFactor()));
    if (t == 'ln') return math.log(parseFactor());
    if (t == 'log') return math.log(parseFactor()) / math.ln10;
    if (t == '√') return math.sqrt(parseFactor());

    if (t == '(') {
      final val = parseExpression();
      if (idx < tokens.length && tokens[idx] == ')') idx++;
      return val;
    }

    double val = double.tryParse(t) ?? 0.0;
    if (idx < tokens.length && tokens[idx] == '^') {
      idx++;
      val = math.pow(val, parseFactor()).toDouble();
    }
    if (idx < tokens.length && tokens[idx] == '!') {
      idx++;
      val = _factorial(val);
    }
    return val;
  }

  static double _toRadians(double deg) => deg * (math.pi / 180.0);

  static double _factorial(double n) {
    int val = n.toInt();
    if (val <= 1) return 1.0;
    double res = 1.0;
    for (int i = 2; i <= val && i <= 20; i++) {
      res *= i;
    }
    return res;
  }
}

