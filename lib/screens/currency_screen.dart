import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

class CurrencyScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CurrencyScreen({super.key, required this.theme});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final TextEditingController _amountCtrl = TextEditingController(text: '100');
  String _fromCurrency = 'USD';
  String _toCurrency = 'INR';
  double _convertedAmount = 0.0;

  // Base exchange rates relative to 1 USD
  final Map<String, double> _rates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'INR': 83.45,
    'JPY': 155.20,
    'CAD': 1.36,
    'AUD': 1.51,
    'CHF': 0.91,
    'CNY': 7.23,
    'AED': 3.67,
    'SGD': 1.35,
    'NZD': 1.64,
  };

  final Map<String, String> _currencyNames = {
    'USD': r'US Dollar ($)',
    'EUR': 'Euro (€)',
    'GBP': 'British Pound (£)',
    'INR': 'Indian Rupee (₹)',
    'JPY': 'Japanese Yen (¥)',
    'CAD': r'Canadian Dollar (C$)',
    'AUD': r'Australian Dollar (A$)',
    'CHF': 'Swiss Franc (CHF)',
    'CNY': 'Chinese Yuan (¥)',
    'AED': 'UAE Dirham (د.إ)',
    'SGD': r'Singapore Dollar (S$)',
    'NZD': r'New Zealand Dollar (NZ$)',
  };

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final double? amount = double.tryParse(_amountCtrl.text);
    if (amount == null) {
      setState(() => _convertedAmount = 0.0);
      return;
    }

    final double fromRate = _rates[_fromCurrency] ?? 1.0;
    final double toRate = _rates[_toCurrency] ?? 1.0;

    // Convert from source to USD then USD to target
    final inUsd = amount / fromRate;
    final inTarget = inUsd * toRate;

    setState(() {
      _convertedAmount = inTarget;
    });
  }

  void _swap() {
    SoundService().playClick();
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _calculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double ratePerUnit = (_rates[_toCurrency] ?? 1.0) / (_rates[_fromCurrency] ?? 1.0);

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
          "Currency Converter",
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
                  // Currency Input Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: widget.theme.doodleCard(borderWidth: 2.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Amount to Convert:",
                          style: widget.theme.fontMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: widget.theme.fontMono(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text,
                          ),
                          onChanged: (_) => _calculate(),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: widget.theme.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: widget.theme.border, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: widget.theme.border, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: widget.theme.primary, width: 2.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Dropdowns & Swap
                        Row(
                          children: [
                            // From
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("From:", style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  _buildCurrencyDropdown(_fromCurrency, (val) {
                                    if (val != null) setState(() { _fromCurrency = val; _calculate(); });
                                  }),
                                ],
                              ),
                            ),

                            // Swap
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: IconButton(
                                icon: const Icon(Icons.swap_horiz, size: 28),
                                color: widget.theme.primary,
                                tooltip: "Swap Currencies",
                                onPressed: _swap,
                              ),
                            ),

                            // To
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("To:", style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  _buildCurrencyDropdown(_toCurrency, (val) {
                                    if (val != null) setState(() { _toCurrency = val; _calculate(); });
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Converted Result Display Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: widget.theme.doodleCard(
                      color: widget.theme.accent.withOpacity(0.25),
                      borderWidth: 3.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "EXCHANGE RESULT",
                          style: widget.theme.fontMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          _convertedAmount.toStringAsFixed(2),
                          style: widget.theme.fontMono(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyNames[_toCurrency] ?? _toCurrency,
                          style: widget.theme.fontDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.theme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.theme.border, width: 1.5),
                          ),
                          child: Text(
                            "1 $_fromCurrency = ${ratePerUnit.toStringAsFixed(4)} $_toCurrency",
                            style: widget.theme.fontMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text,
                            ),
                          ),
                        ),
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

  Widget _buildCurrencyDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: widget.theme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.border, width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: widget.theme.cardBg,
          style: widget.theme.fontMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: widget.theme.text,
          ),
          items: _rates.keys.map((code) {
            return DropdownMenuItem<String>(
              value: code,
              child: Text(code),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
