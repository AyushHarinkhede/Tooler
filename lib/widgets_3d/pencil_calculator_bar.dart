import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../models/calc_history_model.dart';
import 'stationery_3d_modal.dart';
import 'stationery_3d_icons.dart';

class PencilCalculatorBar extends StatefulWidget {
  final StationeryTheme theme;
  final VoidCallback? onHistoryPressed;

  const PencilCalculatorBar({
    super.key,
    required this.theme,
    this.onHistoryPressed,
  });

  @override
  State<PencilCalculatorBar> createState() => _PencilCalculatorBarState();
}

class _PencilCalculatorBarState extends State<PencilCalculatorBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isScientific = false;

  String _expression = '0';
  String _previewResult = '';
  List<CalcHistoryItem> _history = [];

  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInOutCubic,
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService().loadCalcHistory();
    if (mounted) setState(() => _history = list);
  }

  void _toggleExpand() {
    SoundService().playClick();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    });
  }

  void _toggleScientific() {
    SoundService().playClick();
    setState(() => _isScientific = !_isScientific);
  }

  void _onKeyPress(String key) {
    SoundService().playKey();
    setState(() {
      if (key == 'C') {
        _expression = '0';
        _previewResult = '';
      } else if (key == '⌫') {
        _handleBackspace();
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

  void _handleBackspace() {
    if (_expression.length > 1 && _expression != 'Error') {
      _expression = _expression.substring(0, _expression.length - 1);
    } else {
      _expression = '0';
    }
    _computePreview();
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
    int pos = -1;
    int ch = 0;

    void nextChar() {
      pos++;
      ch = (pos < str.length) ? str.codeUnitAt(pos) : -1;
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
    return parseExpression();
  }

  void _showHistoryModal() {
    SoundService().playClick();
    Stationery3DModal.show(
      context: context,
      title: "Pencil Calculation History",
      subtitle: "Recent answers on paper tape",
      theme: widget.theme,
      content: _history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "No calculations yet!\nWrite with the pencil calculator above",
                  textAlign: TextAlign.center,
                  style: widget.theme.fontDoodle(
                    fontSize: 15,
                    color: widget.theme.text.withValues(alpha: 0.6),
                  ),
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
                  leading: const Icon3DClipboard(size: 20),
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
      child: AnimatedBuilder(
        animation: _expandAnim,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: widget.theme.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.theme.border,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.border.withValues(alpha: 0.35),
                  offset: const Offset(4, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Long Pencil Bar (Always visible header / toggle)
                  GestureDetector(
                    onTap: _toggleExpand,
                    child: _buildPencilBarHeader(),
                  ),

                  // 2. Expandable Calculator Body
                  if (_expandAnim.value > 0.01)
                    Opacity(
                      opacity: _expandAnim.value.clamp(0.0, 1.0),
                      child: Align(
                        heightFactor: _expandAnim.value,
                        alignment: Alignment.topCenter,
                        child: _buildExpandedCalculatorBody(),
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

  // --- THE LONG PENCIL BAR HEADER ---
  Widget _buildPencilBarHeader() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24), // Vibrant school pencil yellow
        border: Border(
          bottom: _isExpanded
              ? BorderSide(color: widget.theme.border, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Stack(
        children: [
          // Pencil wooden facets
          Positioned.fill(
            child: Row(
              children: [
                // Sharpened Wooden Tip
                CustomPaint(
                  size: const Size(42, 54),
                  painter: _PencilTipPainter(),
                ),

                // Hexagonal Shaft Center
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFDE68A), // Top bevel highlight
                          Color(0xFFF59E0B), // Body yellow
                          Color(0xFFD97706), // Bottom shadow bevel
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon3DPencil(size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "CALCULATOR",
                          style: GoogleFonts.architectsDaughter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "HB • 2B",
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Metallic Ferrule
                Container(
                  width: 22,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE2E8F0),
                        Color(0xFF94A3B8),
                        Color(0xFFE2E8F0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(height: 1.5, color: const Color(0xFF64748B)),
                      Container(height: 1.5, color: const Color(0xFF64748B)),
                      Container(height: 1.5, color: const Color(0xFF64748B)),
                    ],
                  ),
                ),

                // Pink Rubber Eraser Cap
                Container(
                  width: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF472B6), // Pink eraser
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF831843),
                        size: 22,
                      ),
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

  // --- EXPANDED CALCULATOR BODY ---
  Widget _buildExpandedCalculatorBody() {
    return Container(
      color: widget.theme.cardBg,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 1. Sketch Pencil Display Box
          _buildSketchDisplay(),

          const SizedBox(height: 10),

          // 2. Action Toolbar: Scientific Toggle & Real Eraser Cut Button
          _buildActionToolbar(),

          const SizedBox(height: 8),

          // 3. Optional Scientific Keypad Rows
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: _isScientific
                ? _buildScientificKeypad()
                : const SizedBox.shrink(),
          ),

          if (_isScientific) const SizedBox(height: 8),

          // 4. Standard Number & Operator Keypad
          _buildStandardKeypad(),
        ],
      ),
    );
  }

  // --- SKETCH PENCIL DISPLAY (Numbers in sketch pencil font) ---
  Widget _buildSketchDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5), // Warm notepad paper
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.theme.border,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.border.withValues(alpha: 0.15),
            offset: const Offset(2, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Ruled notepad line indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NOTEBOOK MATH",
                style: GoogleFonts.architectsDaughter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
              if (_previewResult.isNotEmpty)
                Text(
                  _previewResult,
                  style: GoogleFonts.architectsDaughter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Main Sketched Expression / Output
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _expression,
              maxLines: 1,
              style: GoogleFonts.architectsDaughter(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B), // Dark graphite pencil color
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.12),
                    offset: const Offset(1.5, 1.5),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTION TOOLBAR (Scientific Toggle + Eraser Cut Button + History) ---
  Widget _buildActionToolbar() {
    return Row(
      children: [
        // Scientific Toggle Button
        InkWell(
          onTap: _toggleScientific,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isScientific
                  ? const Color(0xFF3B82F6) // Active blue
                  : widget.theme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isScientific ? const Color(0xFF1D4ED8) : widget.theme.border,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.border.withValues(alpha: 0.25),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon3DFasciaFlask(size: 16),
                const SizedBox(width: 6),
                Text(
                  _isScientific ? "Scientific ON" : "Scientific",
                  style: GoogleFonts.kalam(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _isScientific ? Colors.white : widget.theme.text,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // History Paper Tape Button
        InkWell(
          onTap: _showHistoryModal,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.theme.border, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.border.withValues(alpha: 0.25),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon3DPaperTape(size: 16),
                const SizedBox(width: 5),
                Text(
                  "Tape",
                  style: GoogleFonts.kalam(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.text,
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Clear 'C' Button
        _buildDoodleButton(
          label: "C",
          color: const Color(0xFFFCA5A5),
          textColor: const Color(0xFF991B1B),
          onTap: () => _onKeyPress("C"),
          width: 38,
          height: 34,
        ),

        const SizedBox(width: 8),

        // --- REAL ERASER SHAPED CUT / BACKSPACE BUTTON ---
        _buildEraserCutButton(),
      ],
    );
  }

  // --- ERASER SHAPED BUTTON (Pink & Blue Bevel Eraser with Paper Band) ---
  Widget _buildEraserCutButton() {
    return _TactileEraserCutButton(
      onTap: () => _onKeyPress("⌫"),
      onLongPress: () {
        SoundService().playSuccess();
        setState(() {
          _expression = '0';
          _previewResult = '';
        });
      },
    );
  }

  // --- SCIENTIFIC KEYPAD (Expanded rows) ---
  Widget _buildScientificKeypad() {
    final sciRows = [
      ['sin', 'cos', 'tan', 'π', 'e', '√'],
      ['ln', 'log', '^', '(', ')', '!'],
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.border, width: 1.5),
      ),
      child: Column(
        children: sciRows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: _buildDoodleButton(
                      label: key,
                      color: const Color(0xFFE0E7FF),
                      textColor: const Color(0xFF3730A3),
                      fontSize: 13,
                      height: 32,
                      onTap: () => _onKeyPress(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- STANDARD KEYPAD ---
  Widget _buildStandardKeypad() {
    final rows = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['0', '.', '%', '+'],
    ];

    return Column(
      children: [
        ...rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: row.map((key) {
                final isOp = ['÷', '×', '-', '+'].contains(key);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: _buildDoodleButton(
                      label: key,
                      color: isOp
                          ? const Color(0xFFFED7AA) // Pastel orange operator
                          : const Color(0xFFFFFFFF), // Crisp number button
                      textColor: isOp
                          ? const Color(0xFFC2410C)
                          : const Color(0xFF1E293B),
                      fontSize: isOp ? 22 : 20,
                      isSketchFont: !isOp,
                      onTap: () => _onKeyPress(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),

        // Equal Button Banner Row
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Expanded(
                child: _buildDoodleButton(
                  label: "= CALCULATE",
                  color: const Color(0xFF4ADE80), // Highlighter Green
                  textColor: const Color(0xFF065F46),
                  fontSize: 18,
                  height: 44,
                  onTap: () => _onKeyPress("="),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Generic Tactical Doodle Button with mechanical physical depression
  Widget _buildDoodleButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    double height = 40,
    double? width,
    double fontSize = 18,
    bool isSketchFont = false,
  }) {
    return _TactileDoodleButton(
      label: label,
      color: color,
      textColor: textColor,
      borderColor: widget.theme.border,
      onTap: onTap,
      height: height,
      width: width,
      fontSize: fontSize,
      isSketchFont: isSketchFont,
    );
  }
}

// --- TACTILE MECHANICAL DOODLE BUTTON ---
class _TactileDoodleButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;
  final double height;
  final double? width;
  final double fontSize;
  final bool isSketchFont;

  const _TactileDoodleButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
    this.height = 40,
    this.width,
    this.fontSize = 18,
    this.isSketchFont = false,
  });

  @override
  State<_TactileDoodleButton> createState() => _TactileDoodleButtonState();
}

class _TactileDoodleButtonState extends State<_TactileDoodleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(0, _pressed ? 2.5 : 0, 0),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.borderColor,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withValues(alpha: 0.3),
                offset: _pressed ? const Offset(1, 1) : const Offset(2, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: widget.isSketchFont
                  ? GoogleFonts.architectsDaughter(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                    )
                  : GoogleFonts.kalam(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- TACTILE ERASER CUT BUTTON ---
class _TactileEraserCutButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TactileEraserCutButton({
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_TactileEraserCutButton> createState() => _TactileEraserCutButtonState();
}

class _TactileEraserCutButtonState extends State<_TactileEraserCutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        height: 36,
        transform: Matrix4.translationValues(0, _pressed ? 2.0 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFB7185), // Eraser rubber pink
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12), // Angled bevel cut
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(
            color: const Color(0xFF9F1239),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF881337),
              offset: _pressed ? const Offset(1, 1) : const Offset(2, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // White eraser sleeve band
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF9F1239), width: 1),
              ),
              child: Text(
                "ERASE",
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF9F1239),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "⌫",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Sharpened Wooden Pencil Tip
class _PencilTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF2B2D42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 1. Wooden Collar (Beige Triangle)
    final woodPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    final woodPaint = Paint()
      ..color = const Color(0xFFE2BA84) // Cedar wood grain
      ..style = PaintingStyle.fill;
    canvas.drawPath(woodPath, woodPaint);
    canvas.drawPath(woodPath, borderPaint);

    // 2. Graphite Lead Tip (Black triangle at point)
    final leadPath = Path()
      ..moveTo(size.width * 0.38, size.height * 0.31)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width * 0.38, size.height * 0.69)
      ..close();

    final leadPaint = Paint()
      ..color = const Color(0xFF1E293B) // Dark graphite
      ..style = PaintingStyle.fill;
    canvas.drawPath(leadPath, leadPaint);
    canvas.drawPath(leadPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
