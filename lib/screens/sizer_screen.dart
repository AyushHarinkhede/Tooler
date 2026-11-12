import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/bouncy_tap.dart';

enum SizerToolType { ring, bangle, strap, ruler }

class SizerScreen extends StatefulWidget {
  final StationeryTheme theme;
  const SizerScreen({super.key, required this.theme});

  @override
  State<SizerScreen> createState() => _SizerScreenState();
}

class _SizerScreenState extends State<SizerScreen> {
  SizerToolType _activeType = SizerToolType.ring;

  // Screen Calibration factor (Flutter 160 dpi baseline: 160 / 25.4 = 6.299 px/mm)
  double _pixelsPerMm = 6.30;

  // --- 1. RING STATE ---
  // Diameter in mm: min 13.5mm (US 2.5) to max 31.8mm (Circumference 10.0cm)
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
    if (cm != null && cm > 0 && cm <= 10.0) {
      final mm = (cm * 10.0) / math.pi;
      setState(() {
        _ringDiameterMm = mm.clamp(13.5, 31.8);
      });
    }
  }

  Map<String, String> _getRingSizes(double mm) {
    // International standard size matching (US, UK, EU, JP/India)
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
    if (mm < 24.2) return {'US': '15', 'UK': 'Z+4', 'EU': '75', 'JP': '31', 'dia': mm.toStringAsFixed(1)};
    if (mm < 25.0) return {'US': '16', 'UK': 'Z+6', 'EU': '78', 'JP': '33', 'dia': mm.toStringAsFixed(1)};
    return {'US': '16+', 'UK': 'Z+', 'EU': '80+', 'JP': '34+', 'dia': mm.toStringAsFixed(1)};
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
            final cardHeightPx = 53.98 * tempPpm; // Standard credit/ATM card short edge is 53.98mm
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
                    "Place short edge of credit/debit card on screen. Adjust until box matches card width (53.98 mm).",
                    style: widget.theme.fontDoodle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: cardHeightPx.clamp(200.0, 360.0),
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.theme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.theme.primary, width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Card Short Edge (53.98 mm)",
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
                    min: 4.5,
                    max: 8.5,
                    divisions: 80,
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
                    setState(() => _pixelsPerMm = 6.30);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Reset Default (6.30)"),
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

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey<SizerToolType>(_activeType),
                      child: _activeType == SizerToolType.ring
                          ? _buildRingSizer()
                          : _activeType == SizerToolType.bangle
                              ? _buildBangleSizer()
                              : _activeType == SizerToolType.strap
                                  ? _buildWatchStrapSizer()
                                  : _buildRulerSizer(),
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

  Widget _buildTabBtn(String label, SizerToolType type, IconData icon) {
    final bool isSelected = (_activeType == type);
    return Expanded(
      child: BouncyTap(
        onTap: () {
          SoundService().playClick();
          setState(() => _activeType = type);
        },
        scaleFraction: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
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
    final sizes = _getRingSizes(_ringDiameterMm);
    final circumferenceCm = (_ringDiameterMm * math.pi) / 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Full Graph Container with Live Ring Circle & Millimeter Coordinate Grid
        Container(
          height: 270,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.2,
          ),
          child: Stack(
            children: [
              // Full Precision Coordinate Graph
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingGraphContainerPainter(
                    ringDiameterMm: _ringDiameterMm,
                    pixelsPerMm: _pixelsPerMm,
                    primaryColor: widget.theme.primary,
                    accentColor: const Color(0xFFF1C40F),
                    textColor: widget.theme.text,
                    gridColor: widget.theme.border,
                  ),
                ),
              ),

              // Calibration Shortcut Button (Top Right)
              Positioned(
                top: 8,
                right: 8,
                child: BouncyTap(
                  onTap: _showCalibrationDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.theme.bg.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.theme.border, width: 1.2),
                    ),
                    child: Icon(Icons.tune_rounded, size: 16, color: widget.theme.primary),
                  ),
                ),
              ),

              // Top Live Dimension Badge
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.theme.bg.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.primary.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Text(
                    "⌀ ${_ringDiameterMm.toStringAsFixed(2)} mm",
                    style: widget.theme.fontMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.primary,
                    ),
                  ),
                ),
              ),

              // Bottom Live Circumference Metric
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.theme.bg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.2),
                      ),
                      child: Text(
                        "Diameter: ${_ringDiameterMm.toStringAsFixed(1)} mm  •  Circumference: ${circumferenceCm.toStringAsFixed(2)} cm",
                        style: widget.theme.fontMono(
                          fontSize: 11,
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

        const SizedBox(height: 12),

        // 2. Adjust Bar (ONLY Minus Icon, Slider, Plus Icon - NO text or words)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Row(
            children: [
              BouncyTap(
                onTap: () {
                  if (_ringDiameterMm > 13.5) {
                    setState(() {
                      _ringDiameterMm = (_ringDiameterMm - 0.1).clamp(13.5, 31.8);
                      _updateCircumferenceTextFromRingDiameter();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.theme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.border, width: 1.5),
                  ),
                  child: Icon(Icons.remove_rounded, size: 22, color: widget.theme.primary),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
                  ),
                  child: Slider(
                    value: _ringDiameterMm.clamp(13.5, 31.8),
                    min: 13.5,
                    max: 31.8,
                    divisions: 183,
                    activeColor: widget.theme.primary,
                    inactiveColor: widget.theme.border,
                    onChanged: (val) {
                      setState(() {
                        _ringDiameterMm = val;
                        _updateCircumferenceTextFromRingDiameter();
                      });
                    },
                  ),
                ),
              ),
              BouncyTap(
                onTap: () {
                  if (_ringDiameterMm < 31.8) {
                    setState(() {
                      _ringDiameterMm = (_ringDiameterMm + 0.1).clamp(13.5, 31.8);
                      _updateCircumferenceTextFromRingDiameter();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.theme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.border, width: 1.5),
                  ),
                  child: Icon(Icons.add_rounded, size: 22, color: widget.theme.primary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Number Select Bar in cm (Max 10.0 cm, millimeter precision, direct selection & entry)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.0,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  BouncyTap(
                    onTap: () {
                      final currentCm = (_ringDiameterMm * math.pi) / 10.0;
                      if (currentCm > 4.2) {
                        final newCm = (currentCm - 0.1).clamp(4.2, 10.0);
                        setState(() {
                          _ringDiameterMm = ((newCm * 10.0) / math.pi).clamp(13.5, 31.8);
                          _updateCircumferenceTextFromRingDiameter();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: Text(
                        "-0.1",
                        style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold, color: widget.theme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.primary.withValues(alpha: 0.5), width: 1.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: _ringCircumferenceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: widget.theme.fontDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.theme.primary,
                              ),
                              onChanged: _onRingCircumferenceInput,
                            ),
                          ),
                          Text(
                            "cm",
                            style: widget.theme.fontMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${((_ringDiameterMm * math.pi)).toStringAsFixed(1)} mm)",
                            style: widget.theme.fontMono(
                              fontSize: 11,
                              color: widget.theme.text.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  BouncyTap(
                    onTap: () {
                      final currentCm = (_ringDiameterMm * math.pi) / 10.0;
                      if (currentCm < 10.0) {
                        final newCm = (currentCm + 0.1).clamp(4.2, 10.0);
                        setState(() {
                          _ringDiameterMm = ((newCm * 10.0) / math.pi).clamp(13.5, 31.8);
                          _updateCircumferenceTextFromRingDiameter();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: Text(
                        "+0.1",
                        style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold, color: widget.theme.primary),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Quick cm preset selector pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [4.8, 5.2, 5.4, 5.7, 6.0, 6.5, 7.0, 8.0, 9.0, 10.0].map((presetCm) {
                    final currentCm = (_ringDiameterMm * math.pi) / 10.0;
                    final isSelected = (currentCm - presetCm).abs() < 0.15;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: BouncyTap(
                        onTap: () {
                          setState(() {
                            _ringDiameterMm = ((presetCm * 10.0) / math.pi).clamp(13.5, 31.8);
                            _updateCircumferenceTextFromRingDiameter();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? widget.theme.primary : widget.theme.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? widget.theme.primary : widget.theme.border,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            "${presetCm.toStringAsFixed(1)} cm",
                            style: widget.theme.fontMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : widget.theme.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4. Redesigned International Standard Ring Size Chart
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "International Standards",
                    style: widget.theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.theme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      "ISO 8653",
                      style: widget.theme.fontMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernSizeCard(
                      flag: "🇺🇸",
                      region: "US / Canada",
                      size: sizes['US']!,
                      standard: "Scale 3 - 15",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModernSizeCard(
                      flag: "🇮🇳",
                      region: "India / JP",
                      size: sizes['JP']!,
                      standard: "Scale 4 - 31",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModernSizeCard(
                      flag: "🇬🇧",
                      region: "UK / AU",
                      size: sizes['UK']!,
                      standard: "Letters F - Z",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModernSizeCard(
                      flag: "🇪🇺",
                      region: "Europe (EU)",
                      size: sizes['EU']!,
                      standard: "Circum. mm",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernSizeCard({
    required String flag,
    required String region,
    required String size,
    required String standard,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: widget.theme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.theme.border.withValues(alpha: 0.2),
            offset: const Offset(1, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  region,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: widget.theme.fontMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.text.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              size,
              style: widget.theme.fontDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.theme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              standard,
              style: widget.theme.fontMono(
                fontSize: 9,
                color: widget.theme.text.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. BANGLE SIZER VIEW
  // =========================================================================
  Widget _buildBangleSizer() {
    final bangleInfo = _getBangleSizeInfo(_bangleDiameterMm);
    final innerCircumferenceCm = (_bangleDiameterMm * math.pi) / 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Full Precision Millimeter Coordinate Graph Container (Reaching Screen Edges)
        Container(
          height: 330,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.2,
          ),
          child: Stack(
            children: [
              // Full Precision Coordinate Graph
              Positioned.fill(
                child: CustomPaint(
                  painter: _BangleGraphContainerPainter(
                    bangleDiameterMm: _bangleDiameterMm,
                    pixelsPerMm: _pixelsPerMm,
                    primaryColor: const Color(0xFFD35400),
                    accentColor: const Color(0xFFF1C40F),
                    gridColor: widget.theme.border,
                  ),
                ),
              ),

              // Calibration Shortcut Button (Top Right)
              Positioned(
                top: 8,
                right: 8,
                child: BouncyTap(
                  onTap: _showCalibrationDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.theme.bg.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.theme.border, width: 1.2),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFFD35400)),
                  ),
                ),
              ),

              // Top Live Dimension Badge
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.theme.bg.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD35400).withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Text(
                    "Bangle: ${bangleInfo['name']} (${bangleInfo['inches']}) • ⌀ ${_bangleDiameterMm.toStringAsFixed(1)} mm",
                    style: widget.theme.fontMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD35400),
                    ),
                  ),
                ),
              ),

              // Bottom Live Circumference Metric
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.theme.bg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.2),
                      ),
                      child: Text(
                        "Inner Diameter: ${_bangleDiameterMm.toStringAsFixed(1)} mm  •  Circumference: ${innerCircumferenceCm.toStringAsFixed(2)} cm",
                        style: widget.theme.fontMono(
                          fontSize: 11,
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

        const SizedBox(height: 12),

        // 2. Adjust Bar (ONLY Minus Icon, Slider, Plus Icon - NO text or words)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Row(
            children: [
              BouncyTap(
                onTap: () {
                  if (_bangleDiameterMm > 50.0) {
                    setState(() {
                      _bangleDiameterMm = (_bangleDiameterMm - 0.5).clamp(50.0, 80.0);
                      _updateKnuckleTextFromBangleDiameter();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.theme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.border, width: 1.5),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 22, color: Color(0xFFD35400)),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
                  ),
                  child: Slider(
                    value: _bangleDiameterMm.clamp(50.0, 80.0),
                    min: 50.0,
                    max: 80.0,
                    divisions: 60,
                    activeColor: const Color(0xFFD35400),
                    inactiveColor: widget.theme.border,
                    onChanged: (val) {
                      setState(() {
                        _bangleDiameterMm = val;
                        _updateKnuckleTextFromBangleDiameter();
                      });
                    },
                  ),
                ),
              ),
              BouncyTap(
                onTap: () {
                  if (_bangleDiameterMm < 80.0) {
                    setState(() {
                      _bangleDiameterMm = (_bangleDiameterMm + 0.5).clamp(50.0, 80.0);
                      _updateKnuckleTextFromBangleDiameter();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.theme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.theme.border, width: 1.5),
                  ),
                  child: const Icon(Icons.add_rounded, size: 22, color: Color(0xFFD35400)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Number Select Bar in cm (Direct typing & stepping, max 26.0 cm, millimeter precision)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.0,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  BouncyTap(
                    onTap: () {
                      final currentCm = (_bangleDiameterMm * math.pi) / 10.0;
                      if (currentCm > 15.0) {
                        final newCm = (currentCm - 0.1).clamp(15.0, 26.0);
                        setState(() {
                          _bangleDiameterMm = ((newCm * 10.0) / math.pi).clamp(50.0, 80.0);
                          _updateKnuckleTextFromBangleDiameter();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: Text(
                        "-0.1",
                        style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD35400)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD35400).withValues(alpha: 0.5), width: 1.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: _bangleKnuckleCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: widget.theme.fontDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD35400),
                              ),
                              onChanged: _onBangleKnuckleInput,
                            ),
                          ),
                          Text(
                            "cm",
                            style: widget.theme.fontMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${_bangleDiameterMm.toStringAsFixed(1)} mm)",
                            style: widget.theme.fontMono(
                              fontSize: 11,
                              color: widget.theme.text.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  BouncyTap(
                    onTap: () {
                      final currentCm = (_bangleDiameterMm * math.pi) / 10.0;
                      if (currentCm < 26.0) {
                        final newCm = (currentCm + 0.1).clamp(15.0, 26.0);
                        setState(() {
                          _bangleDiameterMm = ((newCm * 10.0) / math.pi).clamp(50.0, 80.0);
                          _updateKnuckleTextFromBangleDiameter();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: Text(
                        "+0.1",
                        style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD35400)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Quick Standard Bangle Size Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    {'name': '2-2', 'mm': 54.0, 'cm': '5.4 cm'},
                    {'name': '2-4', 'mm': 57.2, 'cm': '5.7 cm'},
                    {'name': '2-6', 'mm': 60.3, 'cm': '6.0 cm'},
                    {'name': '2-8', 'mm': 63.5, 'cm': '6.4 cm'},
                    {'name': '2-10', 'mm': 66.7, 'cm': '6.7 cm'},
                    {'name': '2-12', 'mm': 69.8, 'cm': '7.0 cm'},
                    {'name': '2-14', 'mm': 73.0, 'cm': '7.3 cm'},
                    {'name': '3-0', 'mm': 76.2, 'cm': '7.6 cm'},
                  ].map((item) {
                    final mm = item['mm'] as double;
                    final isSelected = (_bangleDiameterMm - mm).abs() < 1.2;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: BouncyTap(
                        onTap: () {
                          SoundService().playClick();
                          setState(() {
                            _bangleDiameterMm = mm;
                            _updateKnuckleTextFromBangleDiameter();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFD35400) : widget.theme.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFD35400) : widget.theme.border,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            "${item['name']} (${item['cm']})",
                            style: widget.theme.fontMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : widget.theme.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4. Redesigned Standard Bangle Sizes Grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Standard Bangle Chart",
                    style: widget.theme.fontDisplay(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD35400).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD35400).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      "Indian / Global",
                      style: widget.theme.fontMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD35400),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernBangleCard(
                      size: "2-2",
                      inches: "2.125\"",
                      diameter: "54.0 mm",
                      label: "Extra Small",
                      mmVal: 54.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModernBangleCard(
                      size: "2-4",
                      inches: "2.25\"",
                      diameter: "57.2 mm",
                      label: "Small",
                      mmVal: 57.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModernBangleCard(
                      size: "2-6",
                      inches: "2.375\"",
                      diameter: "60.3 mm",
                      label: "Medium (Std)",
                      mmVal: 60.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModernBangleCard(
                      size: "2-8",
                      inches: "2.50\"",
                      diameter: "63.5 mm",
                      label: "Medium-Large",
                      mmVal: 63.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModernBangleCard(
                      size: "2-10",
                      inches: "2.625\"",
                      diameter: "66.7 mm",
                      label: "Large",
                      mmVal: 66.7,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModernBangleCard(
                      size: "2-12",
                      inches: "2.75\"",
                      diameter: "69.8 mm",
                      label: "Extra Large",
                      mmVal: 69.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModernBangleCard(
                      size: "2-14",
                      inches: "2.875\"",
                      diameter: "73.0 mm",
                      label: "2X Large",
                      mmVal: 73.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModernBangleCard(
                      size: "3-0",
                      inches: "3.00\"",
                      diameter: "76.2 mm",
                      label: "3X Large",
                      mmVal: 76.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernBangleCard({
    required String size,
    required String inches,
    required String diameter,
    required String label,
    required double mmVal,
  }) {
    final isSelected = (_bangleDiameterMm - mmVal).abs() < 1.2;
    return BouncyTap(
      onTap: () {
        SoundService().playClick();
        setState(() {
          _bangleDiameterMm = mmVal;
          _updateKnuckleTextFromBangleDiameter();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD35400).withValues(alpha: 0.12) : widget.theme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD35400) : widget.theme.border,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFD35400).withValues(alpha: 0.25) : widget.theme.border.withValues(alpha: 0.2),
              offset: const Offset(1, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Size $size",
                  style: widget.theme.fontDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFFD35400) : widget.theme.text,
                  ),
                ),
                Text(
                  inches,
                  style: widget.theme.fontMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD35400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  diameter,
                  style: widget.theme.fontMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.text.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  label,
                  style: widget.theme.fontMono(
                    fontSize: 9,
                    color: widget.theme.text.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

/// Full Precision Graph Container with Live Ring Circle & Millimeter Coordinate Grid
class _RingGraphContainerPainter extends CustomPainter {
  final double ringDiameterMm;
  final double pixelsPerMm;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color gridColor;

  _RingGraphContainerPainter({
    required this.ringDiameterMm,
    required this.pixelsPerMm,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Millimeter Grid across the full container
    final step2mm = 2.0 * pixelsPerMm;
    final step10mm = 10.0 * pixelsPerMm;

    final majorGridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;
    final minorGridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = center.dx; x < size.width; x += step2mm) {
      final isMajor = ((x - center.dx) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorGridPaint : minorGridPaint);
    }
    for (double x = center.dx - step2mm; x > 0; x -= step2mm) {
      final isMajor = ((center.dx - x) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorGridPaint : minorGridPaint);
    }

    // Horizontal lines
    for (double y = center.dy; y < size.height; y += step2mm) {
      final isMajor = ((y - center.dy) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorGridPaint : minorGridPaint);
    }
    for (double y = center.dy - step2mm; y > 0; y -= step2mm) {
      final isMajor = ((center.dy - y) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorGridPaint : minorGridPaint);
    }

    // 2. Central Primary Coordinate Axes with Millimeter Tick Marks
    final axisPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.38)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    final tickPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    for (int mm = -50; mm <= 50; mm += 2) {
      if (mm == 0) continue;
      final px = center.dx + (mm * pixelsPerMm);
      if (px > 0 && px < size.width) {
        final tickLen = (mm % 10 == 0) ? 6.5 : (mm % 5 == 0 ? 4.5 : 2.5);
        canvas.drawLine(Offset(px, center.dy - tickLen), Offset(px, center.dy + tickLen), tickPaint);
      }
      final py = center.dy + (mm * pixelsPerMm);
      if (py > 0 && py < size.height) {
        final tickLen = (mm % 10 == 0) ? 6.5 : (mm % 5 == 0 ? 4.5 : 2.5);
        canvas.drawLine(Offset(center.dx - tickLen, py), Offset(center.dx + tickLen, py), tickPaint);
      }
    }

    // 3. Concentric Reference Gauge Circles (14mm, 16mm, 18mm, 20mm, 22mm, 24mm)
    final refCirclePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final d in [14.0, 16.0, 18.0, 20.0, 22.0, 24.0]) {
      final r = (d * pixelsPerMm) / 2.0;
      canvas.drawCircle(center, r, refCirclePaint);
    }

    // 4. Center Reticle indicator
    final reticlePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 4.0, reticlePaint);
    canvas.drawCircle(center, 1.2, Paint()..color = accentColor);

    // 5. LIVE DYNAMIC PHYSICAL RING CIRCLE (ACCURATE INNER DIAMETER)
    final ringRadius = (ringDiameterMm * pixelsPerMm) / 2.0;

    // Glowing shadow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, ringRadius, glowPaint);

    // Metallic Outer Bezel
    final outerBezelPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8;
    canvas.drawCircle(center, ringRadius, outerBezelPaint);

    // Golden Precision Inner Guide Ring
    final goldInnerPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, ringRadius - 1.2, goldInnerPaint);

    // Subtle clear center fill tint
    final innerClearPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, ringRadius - 2.0, innerClearPaint);
  }

  @override
  bool shouldRepaint(covariant _RingGraphContainerPainter old) =>
      old.ringDiameterMm != ringDiameterMm ||
      old.pixelsPerMm != pixelsPerMm ||
      old.primaryColor != primaryColor;
}



/// Full Precision Graph Container with Live Bangle Circle & Millimeter Coordinate Grid
class _BangleGraphContainerPainter extends CustomPainter {
  final double bangleDiameterMm;
  final double pixelsPerMm;
  final Color primaryColor;
  final Color accentColor;
  final Color gridColor;

  _BangleGraphContainerPainter({
    required this.bangleDiameterMm,
    required this.pixelsPerMm,
    required this.primaryColor,
    required this.accentColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Millimeter Coordinate Grid
    final step2mm = 2.0 * pixelsPerMm;
    final step10mm = 10.0 * pixelsPerMm;

    final majorGridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;
    final minorGridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = center.dx; x < size.width; x += step2mm) {
      final isMajor = ((x - center.dx) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorGridPaint : minorGridPaint);
    }
    for (double x = center.dx - step2mm; x > 0; x -= step2mm) {
      final isMajor = ((center.dx - x) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorGridPaint : minorGridPaint);
    }

    // Horizontal lines
    for (double y = center.dy; y < size.height; y += step2mm) {
      final isMajor = ((y - center.dy) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorGridPaint : minorGridPaint);
    }
    for (double y = center.dy - step2mm; y > 0; y -= step2mm) {
      final isMajor = ((center.dy - y) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorGridPaint : minorGridPaint);
    }

    // 2. Central Primary Coordinate Axes with Millimeter Tick Marks
    final axisPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.38)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    final tickPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    for (int mm = -60; mm <= 60; mm += 2) {
      if (mm == 0) continue;
      final px = center.dx + (mm * pixelsPerMm);
      if (px > 0 && px < size.width) {
        final tickLen = (mm % 10 == 0) ? 7.0 : (mm % 5 == 0 ? 5.0 : 2.5);
        canvas.drawLine(Offset(px, center.dy - tickLen), Offset(px, center.dy + tickLen), tickPaint);
      }
      final py = center.dy + (mm * pixelsPerMm);
      if (py > 0 && py < size.height) {
        final tickLen = (mm % 10 == 0) ? 7.0 : (mm % 5 == 0 ? 5.0 : 2.5);
        canvas.drawLine(Offset(center.dx - tickLen, py), Offset(center.dx + tickLen, py), tickPaint);
      }
    }

    // 3. Concentric Reference Circles for Standard Indian Bangle Sizes
    final refCirclePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final d in [54.0, 57.2, 60.3, 63.5, 66.7, 69.8, 76.2]) {
      final r = (d * pixelsPerMm) / 2.0;
      canvas.drawCircle(center, r, refCirclePaint);
    }

    // 4. Center Reticle indicator
    final reticlePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 5.0, reticlePaint);
    canvas.drawCircle(center, 1.5, Paint()..color = accentColor);

    // 5. LIVE DYNAMIC PHYSICAL BANGLE CIRCLE (ACCURATE 1:1 SCALE EXTENDING TO EDGES)
    final bangleRadius = (bangleDiameterMm * pixelsPerMm) / 2.0;

    // Glowing rim
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, bangleRadius, glowPaint);

    // Metallic Outer Bangle Rim
    final bangleRimPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8;
    canvas.drawCircle(center, bangleRadius, bangleRimPaint);

    // Golden Precision Inner Edge Ring
    final goldInnerPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, bangleRadius - 1.4, goldInnerPaint);

    // Subtle clear center fill tint
    final innerClearPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, bangleRadius - 2.5, innerClearPaint);
  }

  @override
  bool shouldRepaint(covariant _BangleGraphContainerPainter old) =>
      old.bangleDiameterMm != bangleDiameterMm ||
      old.pixelsPerMm != pixelsPerMm ||
      old.primaryColor != primaryColor;
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
