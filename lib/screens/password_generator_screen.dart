import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  final StationeryTheme theme;
  const PasswordGeneratorScreen({super.key, required this.theme});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  int _length = 16;
  bool _includeUpper = true;
  bool _includeLower = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    SoundService().playKey();
    const upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowerChars = 'abcdefghijklmnopqrstuvwxyz';
    const numberChars = '0123456789';
    const symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String allowedChars = '';
    if (_includeUpper) allowedChars += upperChars;
    if (_includeLower) allowedChars += lowerChars;
    if (_includeNumbers) allowedChars += numberChars;
    if (_includeSymbols) allowedChars += symbolChars;

    if (allowedChars.isEmpty) {
      setState(() => _generatedPassword = 'Select at least one option!');
      return;
    }

    final rand = math.Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < _length; i++) {
      buffer.write(allowedChars[rand.nextInt(allowedChars.length)]);
    }

    setState(() {
      _generatedPassword = buffer.toString();
    });
  }

  void _copyToClipboard() {
    if (_generatedPassword.isEmpty) return;
    SoundService().playSuccess();
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Copied password to clipboard!",
          style: widget.theme.fontDoodle(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: widget.theme.border,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int _calculateStrength() {
    int score = 0;
    if (_generatedPassword.length >= 8) score++;
    if (_generatedPassword.length >= 14) score++;
    if (_includeUpper && _includeLower) score++;
    if (_includeNumbers) score++;
    if (_includeSymbols) score++;
    return score; // Max 5
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();
    String strengthText = 'Weak';
    Color strengthColor = const Color(0xFFFF4757);

    if (strength >= 4) {
      strengthText = 'Strong';
      strengthColor = const Color(0xFF2ED573);
    } else if (strength >= 3) {
      strengthText = 'Good';
      strengthColor = const Color(0xFFFFA502);
    } else if (strength >= 2) {
      strengthText = 'Fair';
      strengthColor = const Color(0xFFECCC68);
    }

    return Scaffold(
      backgroundColor: widget.theme.bg,
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
                  // Generated Password Display Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: widget.theme.doodleCard(
                      color: widget.theme.cardBg,
                      borderWidth: 2.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SelectableText(
                          _generatedPassword,
                          textAlign: TextAlign.center,
                          style: widget.theme.fontMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Strength meter bar
                        Row(
                          children: [
                            Text(
                              "Strength: $strengthText",
                              style: widget.theme.fontMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: strengthColor,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 100,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.theme.bg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: widget.theme.border, width: 1),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (strength / 5.0).clamp(0.1, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: strengthColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons: Copy & Refresh
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.theme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text("Copy Password"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 28),
                              color: widget.theme.primary,
                              tooltip: "Regenerate",
                              onPressed: _generatePassword,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Settings Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: widget.theme.doodleCard(borderWidth: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Password Length", style: widget.theme.fontDisplay(fontSize: 16)),
                            Text("$_length chars", style: widget.theme.fontMono(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _length.toDouble(),
                          min: 6,
                          max: 48,
                          divisions: 42,
                          activeColor: widget.theme.primary,
                          onChanged: (val) {
                            setState(() => _length = val.toInt());
                            _generatePassword();
                          },
                        ),
                        const Divider(),
                        _buildCheckboxRow("Uppercase (A-Z)", _includeUpper, (val) {
                          setState(() => _includeUpper = val ?? true);
                          _generatePassword();
                        }),
                        _buildCheckboxRow("Lowercase (a-z)", _includeLower, (val) {
                          setState(() => _includeLower = val ?? true);
                          _generatePassword();
                        }),
                        _buildCheckboxRow("Numbers (0-9)", _includeNumbers, (val) {
                          setState(() => _includeNumbers = val ?? true);
                          _generatePassword();
                        }),
                        _buildCheckboxRow("Special Symbols (!@#\$)", _includeSymbols, (val) {
                          setState(() => _includeSymbols = val ?? true);
                          _generatePassword();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: widget.theme.fontDoodle(fontSize: 15)),
      value: value,
      activeColor: widget.theme.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }
}
