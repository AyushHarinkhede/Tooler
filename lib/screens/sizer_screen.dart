import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';

enum SizerToolType { ring, bangle, strap, ruler }

class SizerScreen extends StatefulWidget {
  final StationeryTheme theme;
  const SizerScreen({super.key, required this.theme});

  @override
  State<SizerScreen> createState() => _SizerScreenState();
}

class _SizerScreenState extends State<SizerScreen> {
  SizerToolType _activeType = SizerToolType.ring;

  // Screen Calibration factor (pixels per mm, default ~3.8 for typical phone displays)
  double _pixelsPerMm = 3.8;

  // --- 1. RING STATE ---
  // Diameter in mm: min 14.0mm (US 3) to max 24.5mm (US 15)
  double _ringDiameterMm = 18.2;
  final TextEditingController _ringCircumferenceCtrl = TextEditingController(text: '5.72');

  // --- 2. BANGLE STATE ---
  // Diameter in mm: min 54.0mm (Size 2-2) to max 76.2mm (Size 3-0)
  double _bangleDiameterMm = 60.3;
  final TextEditingController _bangleKnuckleCtrl = TextEditingController(text: '18.9');

  // --- 3. WATCH STRAP STATE ---
  int _selectedLugMm = 20;

  // --- 4. RULER & FULL SCREEN STATE ---
  bool _isFullScreenRuler = false;
  double _rulerCaliperMm = 50.0;
  final ScrollController _rulerScrollCtrl = ScrollController();
  final List<double> _pinnedPointsMm = [];

  @override
  void initState() {
    super.initState();
    _updateCircumferenceTextFromRingDiameter();
    _updateKnuckleTextFromBangleDiameter();
  }

  @override
  void dispose() {
    _ringCircumferenceCtrl.dispose();
    _bangleKnuckleCtrl.dispose();
    _rulerScrollCtrl.dispose();
    super.dispose();
  }

  // --- Helper calculations: Ring ---
  void _updateCircumferenceTextFromRingDiameter() {
    final cm = (_ringDiameterMm * math.pi) / 10.0;
    _ringCircumferenceCtrl.text = cm.toStringAsFixed(2);
  }

  void _onRingCircumferenceInput(String val) {
    final cm = double.tryParse(val);
    if (cm != null && cm > 0) {
      final mm = (cm * 10.0) / math.pi;
      if (mm >= 13.5 && mm <= 26.0) {
        setState(() {
          _ringDiameterMm = mm;
        });
      }
    }
  }

  Map<String, String> _getRingSizes(double mm) {
    // International standard size matching
    if (mm < 14.5) return {'US': '3', 'UK': 'F', 'EU': '44', 'JP': '4', 'dia': mm.toStringAsFixed(1)};
    if (mm < 14.9) return {'US': '3.5', 'UK': 'G', 'EU': '45.5', 'JP': '5.5', 'dia': mm.toStringAsFixed(1)};
    if (mm < 15.3) return {'US': '4', 'UK': 'H', 'EU': '47', 'JP': '7', 'dia': mm.toStringAsFixed(1)};
    if (mm < 15.7) return {'US': '4.5', 'UK': 'I', 'EU': '48', 'JP': '8', 'dia': mm.toStringAsFixed(1)};
    if (mm < 16.1) return {'US': '5', 'UK': 'J 1/2', 'EU': '49', 'JP': '9', 'dia': mm.toStringAsFixed(1)};
    if (mm < 16.5) return {'US': '5.5', 'UK': 'L', 'EU': '51', 'JP': '10.5', 'dia': mm.toStringAsFixed(1)};
    if (mm < 16.9) return {'US': '6', 'UK': 'M', 'EU': '52', 'JP': '12', 'dia': mm.toStringAsFixed(1)};
    if (mm < 17.3) return {'US': '6.5', 'UK': 'N', 'EU': '53', 'JP': '13', 'dia': mm.toStringAsFixed(1)};
    if (mm < 17.7) return {'US': '7', 'UK': 'O', 'EU': '54', 'JP': '14', 'dia': mm.toStringAsFixed(1)};
    if (mm < 18.1) return {'US': '7.5', 'UK': 'P', 'EU': '56', 'JP': '15', 'dia': mm.toStringAsFixed(1)};
    if (mm < 18.5) return {'US': '8', 'UK': 'Q', 'EU': '57', 'JP': '16', 'dia': mm.toStringAsFixed(1)};
    if (mm < 19.0) return {'US': '8.5', 'UK': 'R', 'EU': '58', 'JP': '17', 'dia': mm.toStringAsFixed(1)};
    if (mm < 19.4) return {'US': '9', 'UK': 'S', 'EU': '59', 'JP': '18', 'dia': mm.toStringAsFixed(1)};
    if (mm < 19.8) return {'US': '9.5', 'UK': 'T', 'EU': '61', 'JP': '19', 'dia': mm.toStringAsFixed(1)};
    if (mm < 20.2) return {'US': '10', 'UK': 'T 1/2', 'EU': '62', 'JP': '20', 'dia': mm.toStringAsFixed(1)};
    if (mm < 20.6) return {'US': '10.5', 'UK': 'U 1/2', 'EU': '63.5', 'JP': '22', 'dia': mm.toStringAsFixed(1)};
    if (mm < 21.0) return {'US': '11', 'UK': 'V 1/2', 'EU': '65', 'JP': '23', 'dia': mm.toStringAsFixed(1)};
    if (mm < 21.8) return {'US': '12', 'UK': 'X', 'EU': '67', 'JP': '25', 'dia': mm.toStringAsFixed(1)};
    if (mm < 22.6) return {'US': '13', 'UK': 'Z', 'EU': '70', 'JP': '27', 'dia': mm.toStringAsFixed(1)};
    if (mm < 23.4) return {'US': '14', 'UK': 'Z+2', 'EU': '72', 'JP': '29', 'dia': mm.toStringAsFixed(1)};
    return {'US': '15', 'UK': 'Z+4', 'EU': '75', 'JP': '31', 'dia': mm.toStringAsFixed(1)};
  }

  // --- Helper calculations: Bangle ---
  void _updateKnuckleTextFromBangleDiameter() {
    final cm = (_bangleDiameterMm * math.pi) / 10.0;
    _bangleKnuckleCtrl.text = cm.toStringAsFixed(2);
  }

  void _onBangleKnuckleInput(String val) {
    final cm = double.tryParse(val);
    if (cm != null && cm > 0) {
      final mm = (cm * 10.0) / math.pi;
      if (mm >= 50.0 && mm <= 85.0) {
        setState(() {
          _bangleDiameterMm = mm;
        });
      }
    }
  }

  Map<String, String> _getBangleSizeInfo(double mm) {
    if (mm <= 55.0) return {'name': '2-2', 'inches': '2.125"', 'cm': '5.4 cm', 'label': 'Extra Small'};
    if (mm <= 58.5) return {'name': '2-4', 'inches': '2.25"', 'cm': '5.7 cm', 'label': 'Small'};
    if (mm <= 61.8) return {'name': '2-6', 'inches': '2.375"', 'cm': '6.0 cm', 'label': 'Medium (Standard)'};
    if (mm <= 65.0) return {'name': '2-8', 'inches': '2.50"', 'cm': '6.4 cm', 'label': 'Medium-Large'};
    if (mm <= 68.2) return {'name': '2-10', 'inches': '2.625"', 'cm': '6.7 cm', 'label': 'Large'};
    if (mm <= 71.5) return {'name': '2-12', 'inches': '2.75"', 'cm': '7.0 cm', 'label': 'Extra Large'};
    if (mm <= 74.8) return {'name': '2-14', 'inches': '2.875"', 'cm': '7.3 cm', 'label': '2X Large'};
    return {'name': '3-0', 'inches': '3.00"', 'cm': '7.6 cm', 'label': '3X Large'};
  }

  // Calibration Dialog
  void _showCalibrationDialog() {
    SoundService().playClick();
    showDialog(
      context: context,
      builder: (ctx) {
        double tempPpm = _pixelsPerMm;
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final cardWidthPx = 85.6 * tempPpm; // Standard credit/ATM card is 85.6mm
            return AlertDialog(
              backgroundColor: widget.theme.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: widget.theme.border, width: 2),
              ),
              title: Text(
                "Screen Calibration",
                style: widget.theme.fontDisplay(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Place a standard credit/debit card on screen. Adjust slider until card width matches the box below (85.6 mm).",
                    style: widget.theme.fontDoodle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: cardWidthPx.clamp(180.0, 310.0),
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.theme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.theme.primary, width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Credit Card Width (85.6 mm)",
                      style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold, color: widget.theme.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "${tempPpm.toStringAsFixed(2)} px/mm",
                    style: widget.theme.fontMono(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: tempPpm,
                    min: 2.5,
                    max: 5.5,
                    divisions: 60,
                    activeColor: widget.theme.primary,
                    onChanged: (val) {
                      setDlgState(() => tempPpm = val);
                      setState(() => _pixelsPerMm = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _pixelsPerMm = 3.8);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Reset Default"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primary),
                  child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreenRuler) {
      return _buildFullScreenRulerView();
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
                  // Tab selection row
                  Row(
                    children: [
                      _buildTabBtn("Ring Sizer", SizerToolType.ring, Icons.adjust_rounded),
                      const SizedBox(width: 6),
                      _buildTabBtn("Bangle Sizer", SizerToolType.bangle, Icons.radio_button_unchecked_rounded),
                      const SizedBox(width: 6),
                      _buildTabBtn("Watch Strap", SizerToolType.strap, Icons.watch_rounded),
                      const SizedBox(width: 6),
                      _buildTabBtn("Ruler", SizerToolType.ruler, Icons.straighten_rounded),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (_activeType == SizerToolType.ring) _buildRingSizer(),
                  if (_activeType == SizerToolType.bangle) _buildBangleSizer(),
                  if (_activeType == SizerToolType.strap) _buildWatchStrapSizer(),
                  if (_activeType == SizerToolType.ruler) _buildRulerSizer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, SizerToolType type, IconData icon) {
    final bool isSelected = (_activeType == type);
    return Expanded(
      child: InkWell(
        onTap: () {
          SoundService().playClick();
          setState(() => _activeType = type);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.theme.primary : widget.theme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? widget.theme.primary : widget.theme.border, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.theme.primary.withValues(alpha: 0.25),
                      offset: const Offset(1, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : widget.theme.primary),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: widget.theme.fontMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : widget.theme.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. RING SIZER VIEW
  // =========================================================================
  Widget _buildRingSizer() {
    final double pixelDiameter = _ringDiameterMm * _pixelsPerMm;
    final sizes = _getRingSizes(_ringDiameterMm);
    final circumferenceMm = _ringDiameterMm * math.pi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions & Calibration Shortcut
        Container(
          padding: const EdgeInsets.all(12),
          decoration: widget.theme.doodleCard(borderWidth: 1.8),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF4ECDC4), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Place your physical ring directly onto the circle. Adjust slider until the circle matches the inner edge of your ring.",
                  style: widget.theme.fontDoodle(fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: "Calibrate Screen DPI",
                onPressed: _showCalibrationDialog,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Interactive Ring Circle (Hollow with NO numbers inside)
        Container(
          height: 250,
          width: double.infinity,
          decoration: widget.theme.doodleCard(
            color: widget.theme.bg,
            borderWidth: 2.2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top size badge outside circle
              Text(
                "Inner Diameter: ${_ringDiameterMm.toStringAsFixed(2)} mm",
                style: widget.theme.fontDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // The Hollow Physical Placement Circle
              SizedBox(
                width: pixelDiameter,
                height: pixelDiameter,
                child: CustomPaint(
                  painter: _HollowCircleWithCrosshairPainter(
                    primaryColor: widget.theme.primary,
                    accentColor: const Color(0xFFF1C40F),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              // Bottom size tags outside circle
              Text(
                "US Size ${sizes['US']}  •  India/JP ${sizes['JP']}  •  UK ${sizes['UK']}",
                style: widget.theme.fontMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.text,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Diameter Adjustment Controls (Slider + Micro Stepper Buttons)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ring Diameter Range: 14.0 mm – 24.5 mm",
                    style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Circumference: ${circumferenceMm.toStringAsFixed(1)} mm",
                    style: widget.theme.fontMono(fontSize: 11, color: widget.theme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                    onPressed: () {
                      if (_ringDiameterMm > 14.0) {
                        setState(() {
                          _ringDiameterMm = (_ringDiameterMm - 0.1).clamp(14.0, 24.5);
                          _updateCircumferenceTextFromRingDiameter();
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: _ringDiameterMm,
                      min: 14.0,
                      max: 24.5,
                      divisions: 105,
                      activeColor: widget.theme.primary,
                      onChanged: (val) {
                        setState(() {
                          _ringDiameterMm = val;
                          _updateCircumferenceTextFromRingDiameter();
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                    onPressed: () {
                      if (_ringDiameterMm < 24.5) {
                        setState(() {
                          _ringDiameterMm = (_ringDiameterMm + 0.1).clamp(14.0, 24.5);
                          _updateCircumferenceTextFromRingDiameter();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Tape / Circumference Formula Box (User finger tape measurement calculation)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 1.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: Color(0xFFF39C12), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Finger Circumference Tape Formula",
                    style: widget.theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Enter tape measurement around finger:",
                      style: widget.theme.fontMono(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.8)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    height: 38,
                    child: TextField(
                      controller: _ringCircumferenceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: "cm",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        fillColor: widget.theme.bg,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: widget.theme.fontMono(fontSize: 13, fontWeight: FontWeight.bold),
                      onChanged: _onRingCircumferenceInput,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.theme.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.theme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📐 Formula: Circumference (C) = Diameter (D) × 3.1416  |  Diameter (D) = C / 3.1416",
                      style: widget.theme.fontMono(fontSize: 10, fontWeight: FontWeight.bold, color: widget.theme.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Wrap paper or thread around finger joint, mark overlap, measure length in cm with a ruler to find ring size automatically.",
                      style: widget.theme.fontDoodle(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // International Ring Size Conversion Grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "International Standard Ring Size Chart",
                style: widget.theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSizeColumn("US / Canada", sizes['US']!),
                  _buildSizeColumn("India / JP", sizes['JP']!),
                  _buildSizeColumn("UK / AU", sizes['UK']!),
                  _buildSizeColumn("Europe (EU)", sizes['EU']!),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSizeColumn(String title, String val) {
    return Column(
      children: [
        Text(
          title,
          style: widget.theme.fontMono(fontSize: 10, color: widget.theme.text.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.theme.primary.withValues(alpha: 0.4)),
          ),
          child: Text(
            val,
            style: widget.theme.fontDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.theme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 2. BANGLE SIZER VIEW
  // =========================================================================
  Widget _buildBangleSizer() {
    final double pixelDiameter = _bangleDiameterMm * (_pixelsPerMm * 0.7);
    final bangleInfo = _getBangleSizeInfo(_bangleDiameterMm);
    final innerCircumferenceCm = (_bangleDiameterMm * math.pi) / 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: widget.theme.doodleCard(borderWidth: 1.8),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFF39C12), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Place your physical bangle over the circle below to match inner diameter, or measure knuckles with tape.",
                  style: widget.theme.fontDoodle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Interactive Bangle Hollow Circle (NO numbers inside circle)
        Container(
          height: 270,
          width: double.infinity,
          decoration: widget.theme.doodleCard(
            color: widget.theme.bg,
            borderWidth: 2.2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top label outside circle
              Text(
                "Bangle Size: ${bangleInfo['name']} (${bangleInfo['inches']}) • ${bangleInfo['label']}",
                style: widget.theme.fontDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD35400),
                ),
              ),
              const SizedBox(height: 8),

              // The Hollow Bangle Circle
              SizedBox(
                width: pixelDiameter,
                height: pixelDiameter,
                child: CustomPaint(
                  painter: _HollowBanglePainter(
                    strokeColor: const Color(0xFFE67E22),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              // Bottom measurement outside circle
              Text(
                "Inner Diameter: ${_bangleDiameterMm.toStringAsFixed(1)} mm  •  Circumference: ${innerCircumferenceCm.toStringAsFixed(1)} cm",
                style: widget.theme.fontMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.text,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Standard Bangle Quick Size Chips (2-2 to 3-0)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Standard Indian / International Sizes:",
                style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildBangleChip("2-2 (54 mm)", 54.0),
                  _buildBangleChip("2-4 (57.2 mm)", 57.2),
                  _buildBangleChip("2-6 (60.3 mm)", 60.3),
                  _buildBangleChip("2-8 (63.5 mm)", 63.5),
                  _buildBangleChip("2-10 (66.7 mm)", 66.7),
                  _buildBangleChip("2-12 (69.8 mm)", 69.8),
                  _buildBangleChip("2-14 (73.0 mm)", 73.0),
                  _buildBangleChip("3-0 (76.2 mm)", 76.2),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Hand Knuckle Measuring Tape Formula
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 1.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.front_hand_rounded, color: Color(0xFFE67E22), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Hand Knuckle Tape Formula",
                    style: widget.theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Knuckle circumference tape reading:",
                      style: widget.theme.fontMono(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.8)),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    height: 38,
                    child: TextField(
                      controller: _bangleKnuckleCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: "cm",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        fillColor: widget.theme.bg,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: widget.theme.fontMono(fontSize: 13, fontWeight: FontWeight.bold),
                      onChanged: _onBangleKnuckleInput,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.theme.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.theme.border),
                ),
                child: Text(
                  "📐 Bangle Formula: Inner Diameter = Knuckle Circumference / 3.1416\nBring thumb and pinky together (as if wearing a bangle), measure around the widest knuckle line with tape.",
                  style: widget.theme.fontMono(fontSize: 10, color: widget.theme.text.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBangleChip(String label, double mm) {
    final isSel = ((_bangleDiameterMm - mm).abs() < 1.0);
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSel ? Colors.white : widget.theme.text,
        ),
      ),
      backgroundColor: isSel ? const Color(0xFFE67E22) : widget.theme.cardBg,
      side: BorderSide(
        color: isSel ? const Color(0xFFE67E22) : widget.theme.border,
      ),
      onPressed: () {
        SoundService().playClick();
        setState(() {
          _bangleDiameterMm = mm;
          _updateKnuckleTextFromBangleDiameter();
        });
      },
    );
  }

  // =========================================================================
  // 3. WATCH STRAP SIZER VIEW (With Vector Long Strap & Calipers)
  // =========================================================================
  Widget _buildWatchStrapSizer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: widget.theme.doodleCard(borderWidth: 1.8),
          child: Row(
            children: [
              const Icon(Icons.watch_rounded, color: Color(0xFF2980B9), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Hold your watch case between the caliper gap below to verify the exact lug width (strap size).",
                  style: widget.theme.fontDoodle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Lug Width Selection Chips (Min 12mm to Max 26mm)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Standard Watch Lug Widths (Min 12mm to Max 26mm):",
                style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [12, 14, 16, 18, 19, 20, 21, 22, 24, 26].map((w) {
                  final isSel = (_selectedLugMm == w);
                  return ActionChip(
                    label: Text(
                      "$w mm",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : widget.theme.text,
                      ),
                    ),
                    backgroundColor: isSel ? widget.theme.primary : widget.theme.cardBg,
                    side: BorderSide(
                      color: isSel ? widget.theme.primary : widget.theme.border,
                    ),
                    onPressed: () {
                      SoundService().playClick();
                      setState(() => _selectedLugMm = w);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Live Physical Lug Caliper Gap (Match Watch Head)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: widget.theme.doodleCard(borderWidth: 2.2),
          child: Column(
            children: [
              Text(
                "Watch Lug Width Gap: $_selectedLugMm mm",
                style: widget.theme.fontDisplay(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Place watch head lugs directly inside this colored gap:",
                style: widget.theme.fontDoodle(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: _selectedLugMm * _pixelsPerMm,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.theme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.symmetric(
                      vertical: BorderSide(color: widget.theme.primary, width: 4.5),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "$_selectedLugMm mm",
                    style: widget.theme.fontMono(fontSize: 13, fontWeight: FontWeight.bold, color: widget.theme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Real Vector SVG Long Watch Strap Visualizer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: widget.theme.doodleCard(borderWidth: 2.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Realistic Watch Strap Visualizer",
                style: widget.theme.fontDisplay(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Proportional leather strap with precision perimeter stitching, metallic buckle, and adjustment holes:",
                style: widget.theme.fontDoodle(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 320,
                  height: 100,
                  child: CustomPaint(
                    painter: _LongWatchStrapPainter(
                      lugMm: _selectedLugMm,
                      pixelsPerMm: _pixelsPerMm,
                      themeColor: widget.theme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Standard Strap Length Guide Table
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Wrist Size & Strap Length Reference",
                style: widget.theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStrapRow("Short Length", "110 / 70 mm", "Fits wrists 5.5\" – 6.5\" (14 – 16.5 cm)"),
              const Divider(height: 14),
              _buildStrapRow("Standard Length", "120 / 80 mm", "Fits wrists 6.5\" – 7.5\" (16.5 – 19 cm)"),
              const Divider(height: 14),
              _buildStrapRow("Long Length", "130 / 90 mm", "Fits wrists 7.5\" – 8.5\" (19 – 21.5 cm)"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrapRow(String name, String dims, String wrist) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: widget.theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(wrist, style: widget.theme.fontDoodle(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.7))),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.theme.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: widget.theme.border),
          ),
          child: Text(
            dims,
            style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold, color: widget.theme.primary),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 4. RULER SIZER (Phone Side Edge & Full Screen Scrollable 300cm+ with Pins)
  // =========================================================================
  Widget _buildRulerSizer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Side Edge Mode Callout & Full Screen Action Button
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.straighten_rounded, color: Color(0xFF27AE60), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Phone Edge Ruler & Infinite 300cm+ Full Screen Tape",
                      style: widget.theme.fontDisplay(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Measure directly on phone's side edge or enter Full Screen Ruler to scroll up to 300cm+ (3 meters) and drop pinned checkpoints.",
                style: widget.theme.fontDoodle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  SoundService().playClick();
                  setState(() => _isFullScreenRuler = true);
                },
                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                label: const Text(
                  "Enter Full Screen Scrollable Ruler (0–300cm+)",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Side Edge Quick Ruler Preview
        Container(
          height: 180,
          decoration: widget.theme.doodleCard(
            color: const Color(0xFFFDEAA7),
            borderWidth: 2.2,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _EdgeRulerPainter(
                pixelsPerMm: _pixelsPerMm,
                caliperMm: _rulerCaliperMm,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Slider for Caliper
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Measured: ${_rulerCaliperMm.toStringAsFixed(1)} mm  (${(_rulerCaliperMm / 10).toStringAsFixed(2)} cm)",
                    style: widget.theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${(_rulerCaliperMm / 25.4).toStringAsFixed(2)} inches",
                    style: widget.theme.fontMono(fontSize: 13, color: widget.theme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: _rulerCaliperMm,
                min: 0.0,
                max: 120.0,
                divisions: 120,
                activeColor: widget.theme.primary,
                onChanged: (val) => setState(() => _rulerCaliperMm = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 5. FULL SCREEN SCROLLABLE RULER (0 - 300cm+ with Pins & Dual Scale)
  // =========================================================================
  Widget _buildFullScreenRulerView() {
    const double totalLengthCm = 320.0; // 320 cm = 3.2 Meters / 126 inches
    final double totalHeightPx = totalLengthCm * 10.0 * _pixelsPerMm;

    return Scaffold(
      backgroundColor: widget.theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Full Screen Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: widget.theme.cardBg,
                border: Border(bottom: BorderSide(color: widget.theme.border, width: 2)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 24),
                    onPressed: () {
                      SoundService().playClick();
                      setState(() => _isFullScreenRuler = false);
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Full Screen Ruler (0 – 320 cm / 3.2m)",
                          style: widget.theme.fontDisplay(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Scroll tape vertically. Tap anywhere to pin a measurement.",
                          style: widget.theme.fontDoodle(fontSize: 11, color: widget.theme.text.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  // Pin button
                  ElevatedButton.icon(
                    onPressed: () {
                      SoundService().playKey();
                      final currentMm = (_rulerScrollCtrl.hasClients ? _rulerScrollCtrl.offset / _pixelsPerMm : 0.0) + 30.0;
                      setState(() {
                        _pinnedPointsMm.add(currentMm);
                      });
                    },
                    icon: const Icon(Icons.push_pin_rounded, size: 16, color: Colors.white),
                    label: const Text("Pin Point", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Ruler Canvas
            Expanded(
              child: GestureDetector(
                onTapUp: (details) {
                  // User tapped on the ruler canvas: Pin this exact position!
                  SoundService().playClick();
                  final localY = details.localPosition.dy;
                  final scrollY = _rulerScrollCtrl.hasClients ? _rulerScrollCtrl.offset : 0.0;
                  final tappedMm = (scrollY + localY) / _pixelsPerMm;
                  setState(() {
                    _pinnedPointsMm.add(tappedMm);
                  });
                },
                child: SingleChildScrollView(
                  controller: _rulerScrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: double.infinity,
                    height: totalHeightPx,
                    child: CustomPaint(
                      size: Size(double.infinity, totalHeightPx),
                      painter: _InfiniteTapeRulerPainter(
                        pixelsPerMm: _pixelsPerMm,
                        totalCm: totalLengthCm,
                        pinnedPointsMm: _pinnedPointsMm,
                        primaryColor: widget.theme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pinned Points Bottom Panel
            if (_pinnedPointsMm.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.cardBg,
                  border: Border(top: BorderSide(color: widget.theme.border, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pinned Points (${_pinnedPointsMm.length}):",
                          style: widget.theme.fontDisplay(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            SoundService().playClick();
                            setState(() => _pinnedPointsMm.clear());
                          },
                          child: const Text("Clear All Pins", style: TextStyle(color: Color(0xFFE74C3C), fontSize: 12)),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _pinnedPointsMm.length,
                        itemBuilder: (ctx, i) {
                          final mm = _pinnedPointsMm[i];
                          final cm = mm / 10.0;
                          final inches = mm / 25.4;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.theme.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE74C3C)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFE74C3C)),
                                const SizedBox(width: 4),
                                Text(
                                  "Pin #${i + 1}: ${cm.toStringAsFixed(1)} cm (${inches.toStringAsFixed(2)} in)",
                                  style: widget.theme.fontMono(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    SoundService().playClick();
                                    setState(() => _pinnedPointsMm.removeAt(i));
                                  },
                                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM PAINTERS: VECTOR ARTWORK & RULERS
// =========================================================================

/// Hollow Ring Circle with Crosshairs (Numbers outside)
class _HollowCircleWithCrosshairPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  _HollowCircleWithCrosshairPainter({required this.primaryColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Crosshairs guide
    final crossPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), crossPaint);

    // Subtle inner guide circle
    canvas.drawCircle(center, radius * 0.7, Paint()..color = primaryColor.withValues(alpha: 0.05));

    // Outer thick metallic rim
    final ringPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8;
    canvas.drawCircle(center, radius, ringPaint);

    // Golden inner highlight ring
    final goldPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1.5, goldPaint);
  }

  @override
  bool shouldRepaint(covariant _HollowCircleWithCrosshairPainter old) => true;
}

/// Hollow Bangle Circle
class _HollowBanglePainter extends CustomPainter {
  final Color strokeColor;
  _HollowBanglePainter({required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Crosshairs
    final crossPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), crossPaint);

    // Outer Bangle rim
    final banglePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, radius, banglePaint);

    // Inner brass/gold gleam
    final gleamPaint = Paint()
      ..color = const Color(0xFFF1C40F).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius - 1.8, gleamPaint);
  }

  @override
  bool shouldRepaint(covariant _HollowBanglePainter old) => true;
}

/// Vector Long Watch Strap Painter (Leather texturing, stitches, buckle, pin holes)
class _LongWatchStrapPainter extends CustomPainter {
  final int lugMm;
  final double pixelsPerMm;
  final Color themeColor;

  _LongWatchStrapPainter({
    required this.lugMm,
    required this.pixelsPerMm,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strapW = size.width;
    final double strapH = (lugMm * pixelsPerMm).clamp(38.0, 72.0);
    final double startY = (size.height - strapH) / 2;

    final leatherRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(40, startY, strapW - 80, strapH),
      const Radius.circular(8),
    );

    // Leather Body Gradient Fill
    final bodyPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(leatherRect, bodyPaint);

    // Perimeter Stitching line
    final stitchPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final innerStitchRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(44, startY + 4, strapW - 88, strapH - 8),
      const Radius.circular(5),
    );
    canvas.drawRRect(innerStitchRect, stitchPaint);

    // Metallic Buckle on the left
    final buckleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(26, startY - 4, 18, strapH + 8),
      const Radius.circular(4),
    );
    final bucklePaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRRect(buckleRect, bucklePaint);

    // Buckle Prong
    final prongPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(28, startY + strapH / 2), Offset(44, startY + strapH / 2), prongPaint);

    // 7 Adjustment Pin Holes along the strap
    final holePaint = Paint()..color = const Color(0xFF3E2723);
    final holeBorder = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 7; i++) {
      final double hx = strapW * 0.42 + (i * 20.0);
      final double hy = startY + strapH / 2;
      canvas.drawCircle(Offset(hx, hy), 2.5, holePaint);
      canvas.drawCircle(Offset(hx, hy), 2.5, holeBorder);
    }

    // Spring Bar Pins on the right
    final pinPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(strapW - 40, startY - 3), Offset(strapW - 40, startY + strapH + 3), pinPaint);

    // Dimension labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: "Lug Width: $lugMm mm",
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
    );
    tp.layout();
    tp.paint(canvas, Offset(strapW * 0.16, startY + (strapH - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _LongWatchStrapPainter old) =>
      old.lugMm != lugMm || old.pixelsPerMm != pixelsPerMm;
}

/// Phone Side Edge Calibrated Ruler (Horizontal preview)
class _EdgeRulerPainter extends CustomPainter {
  final double pixelsPerMm;
  final double caliperMm;

  _EdgeRulerPainter({required this.pixelsPerMm, required this.caliperMm});

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = const Color(0xFF2C1E12)
      ..strokeWidth = 1.0;
    final cmPaint = Paint()
      ..color = const Color(0xFF1E140A)
      ..strokeWidth = 2.0;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int mm = 0; mm * pixelsPerMm < size.width; mm++) {
      final double x = mm * pixelsPerMm;
      final bool isCm = (mm % 10 == 0);
      final bool isHalf = (mm % 5 == 0);

      if (isCm) {
        canvas.drawLine(Offset(x, 0), Offset(x, 32), cmPaint);
        tp.text = TextSpan(
          text: '${mm ~/ 10} cm',
          style: const TextStyle(color: Color(0xFF2C1E12), fontSize: 10, fontWeight: FontWeight.bold),
        );
        tp.layout();
        tp.paint(canvas, Offset(x + 2, 36));
      } else if (isHalf) {
        canvas.drawLine(Offset(x, 0), Offset(x, 20), tickPaint);
      } else {
        canvas.drawLine(Offset(x, 0), Offset(x, 12), tickPaint);
      }
    }

    // Caliper red marker line
    final double cx = caliperMm * pixelsPerMm;
    final caliperPaint = Paint()
      ..color = const Color(0xFFFF4757)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), caliperPaint);
  }

  @override
  bool shouldRepaint(covariant _EdgeRulerPainter old) =>
      old.caliperMm != caliperMm || old.pixelsPerMm != pixelsPerMm;
}

/// Infinite Vertical Scrollable Tape Ruler (0 to 320 cm / 3.2 Meters with Pins & Dual Scale)
class _InfiniteTapeRulerPainter extends CustomPainter {
  final double pixelsPerMm;
  final double totalCm;
  final List<double> pinnedPointsMm;
  final Color primaryColor;

  _InfiniteTapeRulerPainter({
    required this.pixelsPerMm,
    required this.totalCm,
    required this.pinnedPointsMm,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final totalMm = (totalCm * 10).toInt();

    // Background Wood / Vintage Tape texture
    final bgPaint = Paint()..color = const Color(0xFFF9F1DC);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, size.height), bgPaint);

    final tickPaint = Paint()
      ..color = const Color(0xFF2D3436)
      ..strokeWidth = 1.0;
    final cmTickPaint = Paint()
      ..color = const Color(0xFF1E272E)
      ..strokeWidth = 2.2;
    final meterBannerPaint = Paint()..color = const Color(0xFFE74C3C);

    final tp = TextPainter(textDirection: TextDirection.ltr);

    // 1. Draw Metric Scale on Left Edge (mm, cm, m)
    for (int mm = 0; mm <= totalMm; mm++) {
      final double y = mm * pixelsPerMm;
      final bool isMeter = (mm % 1000 == 0 && mm > 0);
      final bool isCm = (mm % 10 == 0);
      final bool isHalf = (mm % 5 == 0);

      if (isMeter) {
        // Meter Milestone Line
        canvas.drawRect(Rect.fromLTWH(0, y - 2, w, 4), meterBannerPaint);
        tp.text = TextSpan(
          text: '★ ${mm ~/ 1000} METER (${mm ~/ 10} cm) ★',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
        );
        tp.layout();
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, y - 11, tp.width + 16, 22), const Radius.circular(6)),
          Paint()..color = const Color(0xFFE74C3C),
        );
        tp.paint(canvas, Offset(w * 0.28 + 8, y - 8));
      } else if (isCm) {
        canvas.drawLine(Offset(0, y), Offset(42, y), cmTickPaint);
        final cmVal = mm ~/ 10;
        tp.text = TextSpan(
          text: '$cmVal cm',
          style: TextStyle(
            color: cmVal % 10 == 0 ? const Color(0xFFD63031) : const Color(0xFF2D3436),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(46, y - tp.height / 2));
      } else if (isHalf) {
        canvas.drawLine(Offset(0, y), Offset(24, y), tickPaint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(14, y), tickPaint);
      }
    }

    // 2. Draw Imperial Scale on Right Edge (Inches, 1/16, 1/8, 1/4, 1/2)
    final double totalInches = (totalMm / 25.4);
    final int totalSixteenths = (totalInches * 16).toInt();

    for (int s = 0; s <= totalSixteenths; s++) {
      final double inchVal = s / 16.0;
      final double mmVal = inchVal * 25.4;
      final double y = mmVal * pixelsPerMm;

      final bool isWhole = (s % 16 == 0);
      final bool isHalf = (s % 8 == 0);
      final bool isQuarter = (s % 4 == 0);

      if (isWhole) {
        canvas.drawLine(Offset(w - 42, y), Offset(w, y), cmTickPaint);
        final int wholeInch = s ~/ 16;
        tp.text = TextSpan(
          text: '$wholeInch"',
          style: const TextStyle(color: Color(0xFF0984E3), fontSize: 12, fontWeight: FontWeight.bold),
        );
        tp.layout();
        tp.paint(canvas, Offset(w - 46 - tp.width, y - tp.height / 2));
      } else if (isHalf) {
        canvas.drawLine(Offset(w - 28, y), Offset(w, y), tickPaint);
      } else if (isQuarter) {
        canvas.drawLine(Offset(w - 20, y), Offset(w, y), tickPaint);
      } else {
        canvas.drawLine(Offset(w - 12, y), Offset(w, y), tickPaint);
      }
    }

    // 3. Draw Center Dividing Line
    final centerLine = Paint()
      ..color = const Color(0xFFB2BEC3)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, size.height), centerLine);

    // 4. Draw Pinned Points
    for (int p = 0; p < pinnedPointsMm.length; p++) {
      final pinMm = pinnedPointsMm[p];
      final pinY = pinMm * pixelsPerMm;

      // Pin marker line
      final pinLine = Paint()
        ..color = const Color(0xFFE74C3C)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(0, pinY), Offset(w, pinY), pinLine);

      // Pin icon flag badge
      final pinBadge = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.5 - 38, pinY - 11, 76, 22),
        const Radius.circular(11),
      );
      canvas.drawRRect(pinBadge, Paint()..color = const Color(0xFFE74C3C));

      tp.text = TextSpan(
        text: '📍 ${(pinMm / 10).toStringAsFixed(1)}cm',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, Offset(w * 0.5 - tp.width / 2, pinY - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _InfiniteTapeRulerPainter old) => true;
}
