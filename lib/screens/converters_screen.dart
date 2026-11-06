import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

enum ConverterType { length, weight, temperature, height, area, volume, speed, data }

class ConvertersScreen extends StatefulWidget {
  final StationeryTheme theme;
  const ConvertersScreen({super.key, required this.theme});

  @override
  State<ConvertersScreen> createState() => _ConvertersScreenState();
}

class _ConvertersScreenState extends State<ConvertersScreen> {
  ConverterType _activeType = ConverterType.length;
  final TextEditingController _inputCtrl = TextEditingController(text: '1');

  String _fromUnit = 'Meters';
  String _toUnit = 'Feet';
  String _convertedResult = '';

  final Map<ConverterType, List<String>> _units = {
    ConverterType.length: ['Meters', 'Kilometers', 'Centimeters', 'Millimeters', 'Miles', 'Yards', 'Feet', 'Inches'],
    ConverterType.weight: ['Kilograms', 'Grams', 'Milligrams', 'Pounds', 'Ounces', 'Tons'],
    ConverterType.temperature: ['Celsius', 'Fahrenheit', 'Kelvin', 'Rankine', 'Reaumur'],
    ConverterType.height: ['Centimeters', 'Meters', 'Feet', 'Inches'],
    ConverterType.area: ['Sq Meters', 'Sq Kilometers', 'Sq Feet', 'Sq Yards', 'Acres', 'Hectares'],
    ConverterType.volume: ['Liters', 'Milliliters', 'Cubic Meters', 'Gallons (US)', 'Quarts', 'Pints', 'Cups'],
    ConverterType.speed: ['km/h', 'm/s', 'mph', 'Knots'],
    ConverterType.data: ['Bytes', 'Kilobytes (KB)', 'Megabytes (MB)', 'Gigabytes (GB)', 'Terabytes (TB)'],
  };

  @override
  void initState() {
    super.initState();
    _resetUnitsForType();
    _convert();
  }

  void _resetUnitsForType() {
    final list = _units[_activeType]!;
    _fromUnit = list[0];
    _toUnit = list.length > 1 ? list[1] : list[0];
  }

  void _onTypeChanged(ConverterType type) {
    SoundService().playClick();
    setState(() {
      _activeType = type;
      _resetUnitsForType();
      _convert();
    });
  }

  void _swapUnits() {
    SoundService().playClick();
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _convert();
    });
  }

  void _convert() {
    final double? val = double.tryParse(_inputCtrl.text);
    if (val == null) {
      setState(() => _convertedResult = '0');
      return;
    }

    double res = 0;
    switch (_activeType) {
      case ConverterType.length:
        res = _convertLength(val, _fromUnit, _toUnit);
        break;
      case ConverterType.weight:
        res = _convertWeight(val, _fromUnit, _toUnit);
        break;
      case ConverterType.temperature:
        res = _convertTemperature(val, _fromUnit, _toUnit);
        break;
      case ConverterType.height:
        res = _convertLength(val, _fromUnit, _toUnit);
        break;
      case ConverterType.area:
        res = _convertArea(val, _fromUnit, _toUnit);
        break;
      case ConverterType.volume:
        res = _convertVolume(val, _fromUnit, _toUnit);
        break;
      case ConverterType.speed:
        res = _convertSpeed(val, _fromUnit, _toUnit);
        break;
      case ConverterType.data:
        res = _convertData(val, _fromUnit, _toUnit);
        break;
    }

    setState(() {
      if (res == res.roundToDouble()) {
        _convertedResult = res.toInt().toString();
      } else {
        _convertedResult = res.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    });
  }

  double _convertLength(double val, String from, String to) {
    final Map<String, double> toMeters = {
      'Meters': 1.0,
      'Kilometers': 1000.0,
      'Centimeters': 0.01,
      'Millimeters': 0.001,
      'Miles': 1609.344,
      'Yards': 0.9144,
      'Feet': 0.3048,
      'Inches': 0.0254,
    };
    final inMeters = val * (toMeters[from] ?? 1.0);
    return inMeters / (toMeters[to] ?? 1.0);
  }

  double _convertWeight(double val, String from, String to) {
    final Map<String, double> toKg = {
      'Kilograms': 1.0,
      'Grams': 0.001,
      'Milligrams': 0.000001,
      'Pounds': 0.45359237,
      'Ounces': 0.0283495,
      'Tons': 1000.0,
    };
    final inKg = val * (toKg[from] ?? 1.0);
    return inKg / (toKg[to] ?? 1.0);
  }

  double _convertTemperature(double val, String from, String to) {
    // Convert to Celsius first
    double c = val;
    if (from == 'Fahrenheit') {
      c = (val - 32) * 5 / 9;
    } else if (from == 'Kelvin') {
      c = val - 273.15;
    } else if (from == 'Rankine') {
      c = (val - 491.67) * 5 / 9;
    } else if (from == 'Reaumur') {
      c = val * 5 / 4;
    }

    // Convert from Celsius to Target
    if (to == 'Celsius') return c;
    if (to == 'Fahrenheit') return (c * 9 / 5) + 32;
    if (to == 'Kelvin') return c + 273.15;
    if (to == 'Rankine') return (c + 273.15) * 9 / 5;
    if (to == 'Reaumur') return c * 4 / 5;
    return c;
  }

  double _convertArea(double val, String from, String to) {
    final Map<String, double> toSqM = {
      'Sq Meters': 1.0,
      'Sq Kilometers': 1000000.0,
      'Sq Feet': 0.092903,
      'Sq Yards': 0.836127,
      'Acres': 4046.86,
      'Hectares': 10000.0,
    };
    final inSqM = val * (toSqM[from] ?? 1.0);
    return inSqM / (toSqM[to] ?? 1.0);
  }

  double _convertVolume(double val, String from, String to) {
    final Map<String, double> toLiter = {
      'Liters': 1.0,
      'Milliliters': 0.001,
      'Cubic Meters': 1000.0,
      'Gallons (US)': 3.78541,
      'Quarts': 0.946353,
      'Pints': 0.473176,
      'Cups': 0.24,
    };
    final inLiters = val * (toLiter[from] ?? 1.0);
    return inLiters / (toLiter[to] ?? 1.0);
  }

  double _convertSpeed(double val, String from, String to) {
    final Map<String, double> toMps = {
      'm/s': 1.0,
      'km/h': 0.277778,
      'mph': 0.44704,
      'Knots': 0.514444,
    };
    final inMps = val * (toMps[from] ?? 1.0);
    return inMps / (toMps[to] ?? 1.0);
  }

  double _convertData(double val, String from, String to) {
    final Map<String, double> toBytes = {
      'Bytes': 1.0,
      'Kilobytes (KB)': 1024.0,
      'Megabytes (MB)': 1048576.0,
      'Gigabytes (GB)': 1073741824.0,
      'Terabytes (TB)': 1099511627776.0,
    };
    final inBytes = val * (toBytes[from] ?? 1.0);
    return inBytes / (toBytes[to] ?? 1.0);
  }

  IconData _getCategoryIcon(ConverterType type) {
    switch (type) {
      case ConverterType.length: return Icons.straighten;
      case ConverterType.weight: return Icons.scale;
      case ConverterType.temperature: return Icons.thermostat;
      case ConverterType.height: return Icons.height;
      case ConverterType.area: return Icons.square_foot;
      case ConverterType.volume: return Icons.science;
      case ConverterType.speed: return Icons.speed;
      case ConverterType.data: return Icons.memory;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Horizontal Tab Bar of Categories
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ConverterType.values.length,
                      itemBuilder: (context, index) {
                        final type = ConverterType.values[index];
                        final bool isSelected = (type == _activeType);
                        final String name = type.name[0].toUpperCase() + type.name.substring(1);
                        final IconData icon = _getCategoryIcon(type);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () => _onTypeChanged(type),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? widget.theme.primary : widget.theme.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: widget.theme.border, width: 2),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: widget.theme.border.withOpacity(0.3),
                                          offset: const Offset(2, 3),
                                          blurRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(icon, size: 16, color: isSelected ? Colors.white : widget.theme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: widget.theme.fontDisplay(
                                      fontSize: 14,
                                      color: isSelected ? Colors.white : widget.theme.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Conversion Input & Selection Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: widget.theme.doodleCard(borderWidth: 2.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Input value field
                        Text(
                          "Enter Value:",
                          style: widget.theme.fontMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _inputCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: widget.theme.fontMono(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text,
                          ),
                          onChanged: (_) => _convert(),
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

                        const SizedBox(height: 16),

                        // From and To dropdowns with Swap button
                        Row(
                          children: [
                            // From
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "From:",
                                    style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildDropdown(_fromUnit, (val) {
                                    if (val != null) {
                                      setState(() {
                                        _fromUnit = val;
                                        _convert();
                                      });
                                    }
                                  }),
                                ],
                              ),
                            ),

                            // Swap Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                              child: IconButton(
                                icon: const Icon(Icons.swap_horiz, size: 28),
                                color: widget.theme.primary,
                                tooltip: "Swap Units",
                                onPressed: _swapUnits,
                              ),
                            ),

                            // To
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "To:",
                                    style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildDropdown(_toUnit, (val) {
                                    if (val != null) {
                                      setState(() {
                                        _toUnit = val;
                                        _convert();
                                      });
                                    }
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
                      color: widget.theme.secondary.withOpacity(0.25),
                      borderWidth: 3.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "CONVERTED EQUIVALENT",
                          style: widget.theme.fontMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          _convertedResult,
                          style: widget.theme.fontMono(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _toUnit,
                          style: widget.theme.fontDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.primary,
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

  Widget _buildDropdown(String value, ValueChanged<String?> onChanged) {
    final list = _units[_activeType]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: widget.theme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.border, width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: list.contains(value) ? value : list.first,
          isExpanded: true,
          dropdownColor: widget.theme.cardBg,
          style: widget.theme.fontDoodle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: widget.theme.text,
          ),
          items: list.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
