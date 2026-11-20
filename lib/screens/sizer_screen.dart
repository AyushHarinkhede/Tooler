import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../services/sound_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_hover_sheet.dart';

const String kRulerPinSvg = '''
<svg viewBox="0 0 24 24" width="24" height="24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M7 17L2 22" stroke="#94A3B8" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M5.5 15.5L8.5 18.5L10 17L7 14L5.5 15.5Z" fill="#991B1B"/>
  <path d="M7 14L14 21L17.5 17.5L10.5 10.5L7 14Z" fill="#DC2626"/>
  <path d="M8.5 12.5L15 19" stroke="#FCA5A5" stroke-width="1.2" stroke-linecap="round"/>
  <path d="M12.5 8.5L19.5 15.5L21.5 13.5L14.5 6.5L12.5 8.5Z" fill="#EF4444"/>
  <circle cx="17" cy="9" r="3.2" fill="#F87171"/>
  <circle cx="16" cy="8" r="1.2" fill="#FFFFFF"/>
</svg>
''';

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
  bool _ringUnitIsMm = false;

  // --- 2. BANGLE STATE ---
  // Diameter in mm: min 54.0mm (Size 2-2) to max 76.2mm (Size 3-0)
  double _bangleDiameterMm = 60.3;
  final TextEditingController _bangleKnuckleCtrl = TextEditingController(text: '18.9');
  bool _bangleUnitIsMm = false;

  // --- 3. WATCH STRAP STATE ---
  int _selectedLugMm = 20;

  // --- 4. RULER & FULL SCREEN STATE ---
  bool _isFullScreenRuler = false;
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
    ToolerHoverSheet.setImmersive(context, false);
    _ringCircumferenceCtrl.dispose();
    _bangleKnuckleCtrl.dispose();
    _rulerScrollCtrl.dispose();
    super.dispose();
  }

  // --- Helper calculations: Ring ---
  void _setRingUnit(bool isMm) {
    if (_ringUnitIsMm == isMm) return;
    setState(() {
      _ringUnitIsMm = isMm;
      _updateCircumferenceTextFromRingDiameter();
    });
  }

  void _updateCircumferenceTextFromRingDiameter() {
    if (_ringUnitIsMm) {
      final mm = _ringDiameterMm * math.pi;
      _ringCircumferenceCtrl.text = mm.toStringAsFixed(1);
    } else {
      final cm = (_ringDiameterMm * math.pi) / 10.0;
      _ringCircumferenceCtrl.text = cm.toStringAsFixed(2);
    }
  }

  void _onRingCircumferenceInput(String val) {
    final numVal = double.tryParse(val);
    if (numVal != null && numVal > 0) {
      final mm = _ringUnitIsMm ? (numVal / math.pi) : ((numVal * 10.0) / math.pi);
      if (mm >= 13.0 && mm <= 33.0) {
        setState(() {
          _ringDiameterMm = mm.clamp(13.5, 31.8);
        });
      }
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
  void _setBangleUnit(bool isMm) {
    if (_bangleUnitIsMm == isMm) return;
    setState(() {
      _bangleUnitIsMm = isMm;
      _updateKnuckleTextFromBangleDiameter();
    });
  }

  void _updateKnuckleTextFromBangleDiameter() {
    if (_bangleUnitIsMm) {
      final mm = _bangleDiameterMm * math.pi;
      _bangleKnuckleCtrl.text = mm.toStringAsFixed(1);
    } else {
      final cm = (_bangleDiameterMm * math.pi) / 10.0;
      _bangleKnuckleCtrl.text = cm.toStringAsFixed(2);
    }
  }

  void _onBangleKnuckleInput(String val) {
    final numVal = double.tryParse(val);
    if (numVal != null && numVal > 0) {
      final mm = _bangleUnitIsMm ? (numVal / math.pi) : ((numVal * 10.0) / math.pi);
      if (mm >= 48.0 && mm <= 85.0) {
        setState(() {
          _bangleDiameterMm = mm.clamp(50.0, 80.0);
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

  // Ruler Full Screen Transitions
  void _enterFullScreenRuler() {
    SoundService().playClick();
    setState(() => _isFullScreenRuler = true);
    ToolerHoverSheet.setImmersive(context, true);
  }

  void _exitFullScreenRuler() {
    SoundService().playClick();
    setState(() => _isFullScreenRuler = false);
    ToolerHoverSheet.setImmersive(context, false);
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
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _exitFullScreenRuler();
          }
        },
        child: _buildFullScreenRulerView(),
      );
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
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Title & Screen Calibration Header + Tab selection row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Scale & Dimension Studio",
                            style: widget.theme.fontDisplay(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: widget.theme.textSecondary,
                            ),
                          ),
                          BouncyTap(
                            onTap: _showCalibrationDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.theme.cardBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: widget.theme.border, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune_rounded, size: 13, color: widget.theme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Screen Calibration",
                                    style: widget.theme.fontMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: widget.theme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

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
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Active Tool Content (Ruler expands flush to bottom screen edge; others scroll)
                Expanded(
                  child: _activeType == SizerToolType.ruler
                      ? _buildRulerSizer()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: KeyedSubtree(
                              key: ValueKey<SizerToolType>(_activeType),
                              child: _activeType == SizerToolType.ring
                                  ? _buildRingSizer()
                                  : _activeType == SizerToolType.bangle
                                      ? _buildBangleSizer()
                                      : _buildWatchStrapSizer(),
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

  Widget _buildTabBtn(String label, SizerToolType type, IconData icon) {
    final bool isSelected = (_activeType == type);
    return Expanded(
      child: BouncyTap(
        onTap: () {
          SoundService().playClick();
          if (_isFullScreenRuler) {
            _exitFullScreenRuler();
          }
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
    final circumferenceMm = _ringDiameterMm * math.pi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Full Graph Container with Live Ring Circle (ONLY Circle & Grid - NO overlay badges, NO calibration button)
        Container(
          height: 270,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.2,
          ),
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

        const SizedBox(height: 12),

        // 2. Dedicated Live Diameter & Circumference Dimension Card (Showing both mm & cm prominently)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 1.8,
          ),
          child: Row(
            children: [
              // Diameter Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle_outlined, size: 14, color: widget.theme.primary),
                        const SizedBox(width: 5),
                        Text(
                          "DIAMETER (⌀)",
                          style: widget.theme.fontMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_ringDiameterMm.toStringAsFixed(1)} mm",
                      style: widget.theme.fontDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: widget.theme.primary,
                      ),
                    ),
                    Text(
                      "${(_ringDiameterMm / 10.0).toStringAsFixed(2)} cm",
                      style: widget.theme.fontMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: widget.theme.text.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 1.2,
                height: 46,
                color: widget.theme.border,
              ),
              const SizedBox(width: 14),

              // Circumference Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.all_inclusive_rounded, size: 14, color: Color(0xFFF1C40F)),
                        const SizedBox(width: 5),
                        Text(
                          "CIRCUMFERENCE",
                          style: widget.theme.fontMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${circumferenceCm.toStringAsFixed(2)} cm",
                      style: widget.theme.fontDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: widget.theme.text,
                      ),
                    ),
                    Text(
                      "${circumferenceMm.toStringAsFixed(1)} mm",
                      style: widget.theme.fontMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: widget.theme.text.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Adjust Bar (ONLY Minus Icon, Slider, Plus Icon - NO text or words)
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

        // 4. Number Select Bar with mm & cm (Direct input & stepping)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.0,
          ),
          child: Column(
            children: [
              // Unit Toggle Row [ mm | cm ]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Circumference Value",
                    style: widget.theme.fontMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.theme.textSecondary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: widget.theme.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.theme.border, width: 1.2),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _setRingUnit(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _ringUnitIsMm ? widget.theme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "mm",
                              style: widget.theme.fontMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _ringUnitIsMm ? Colors.white : widget.theme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _setRingUnit(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: !_ringUnitIsMm ? widget.theme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "cm",
                              style: widget.theme.fontMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !_ringUnitIsMm ? Colors.white : widget.theme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Stepper & Direct Entry Row
              Row(
                children: [
                  BouncyTap(
                    onTap: () {
                      if (_ringUnitIsMm) {
                        final currentMm = _ringDiameterMm * math.pi;
                        if (currentMm > 42.4) {
                          final newMm = (currentMm - 1.0).clamp(42.4, 100.0);
                          setState(() {
                            _ringDiameterMm = (newMm / math.pi).clamp(13.5, 31.8);
                            _updateCircumferenceTextFromRingDiameter();
                          });
                        }
                      } else {
                        final currentCm = (_ringDiameterMm * math.pi) / 10.0;
                        if (currentCm > 4.2) {
                          final newCm = (currentCm - 0.1).clamp(4.2, 10.0);
                          setState(() {
                            _ringDiameterMm = ((newCm * 10.0) / math.pi).clamp(13.5, 31.8);
                            _updateCircumferenceTextFromRingDiameter();
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: Text(
                        _ringUnitIsMm ? "-1 mm" : "-0.1 cm",
                        style: widget.theme.fontMono(fontSize: 11.5, fontWeight: FontWeight.bold, color: widget.theme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      height: 44,
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
                            _ringUnitIsMm ? "mm" : "cm",
                            style: widget.theme.fontMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _ringUnitIsMm
                                ? "(${((_ringDiameterMm * math.pi) / 10.0).toStringAsFixed(2)} cm)"
                                : "(${(_ringDiameterMm * math.pi).toStringAsFixed(1)} mm)",
                            style: widget.theme.fontMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.text.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  BouncyTap(
                    onTap: () {
                      if (_ringUnitIsMm) {
                        final currentMm = _ringDiameterMm * math.pi;
                        if (currentMm < 100.0) {
                          final newMm = (currentMm + 1.0).clamp(42.4, 100.0);
                          setState(() {
                            _ringDiameterMm = (newMm / math.pi).clamp(13.5, 31.8);
                            _updateCircumferenceTextFromRingDiameter();
                          });
                        }
                      } else {
                        final currentCm = (_ringDiameterMm * math.pi) / 10.0;
                        if (currentCm < 10.0) {
                          final newCm = (currentCm + 0.1).clamp(4.2, 10.0);
                          setState(() {
                            _ringDiameterMm = ((newCm * 10.0) / math.pi).clamp(13.5, 31.8);
                            _updateCircumferenceTextFromRingDiameter();
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: Text(
                        _ringUnitIsMm ? "+1 mm" : "+0.1 cm",
                        style: widget.theme.fontMono(fontSize: 11.5, fontWeight: FontWeight.bold, color: widget.theme.primary),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Quick preset selector pills showing both mm and cm numbers
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [4.8, 5.2, 5.4, 5.7, 6.0, 6.5, 7.0, 8.0, 9.0, 10.0].map((presetCm) {
                    final currentCm = (_ringDiameterMm * math.pi) / 10.0;
                    final isSelected = (currentCm - presetCm).abs() < 0.15;
                    final presetMm = (presetCm * 10.0).round();
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? widget.theme.primary : widget.theme.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? widget.theme.primary : widget.theme.border,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            "${presetMm}mm (${presetCm.toStringAsFixed(1)}cm)",
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
    final innerCircumferenceMm = _bangleDiameterMm * math.pi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Full Precision Millimeter Coordinate Graph Container (ONLY Circle & Grid - NO overlay badges, NO calibration button)
        Container(
          height: 330,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.2,
          ),
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

        const SizedBox(height: 12),

        // 2. Dedicated Live Diameter & Circumference Dimension Card (Showing both mm & cm prominently)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 1.8,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Diameter Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle_outlined, size: 14, color: Color(0xFFD35400)),
                            const SizedBox(width: 5),
                            Text(
                              "INNER DIAMETER (⌀)",
                              style: widget.theme.fontMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: widget.theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_bangleDiameterMm.toStringAsFixed(1)} mm",
                          style: widget.theme.fontDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFD35400),
                          ),
                        ),
                        Text(
                          "${(_bangleDiameterMm / 10.0).toStringAsFixed(2)} cm",
                          style: widget.theme.fontMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: widget.theme.text.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1.2,
                    height: 46,
                    color: widget.theme.border,
                  ),
                  const SizedBox(width: 14),

                  // Circumference Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.all_inclusive_rounded, size: 14, color: Color(0xFFF1C40F)),
                            const SizedBox(width: 5),
                            Text(
                              "CIRCUMFERENCE",
                              style: widget.theme.fontMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: widget.theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${innerCircumferenceCm.toStringAsFixed(2)} cm",
                          style: widget.theme.fontDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: widget.theme.text,
                          ),
                        ),
                        Text(
                          "${innerCircumferenceMm.toStringAsFixed(1)} mm",
                          style: widget.theme.fontMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: widget.theme.text.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD35400).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD35400).withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    "Standard Indian Size: ${bangleInfo['name']} (${bangleInfo['inches']}) • ${bangleInfo['label']}",
                    style: widget.theme.fontMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD35400),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Adjust Bar (ONLY Minus Icon, Slider, Plus Icon - NO text or words)
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

        // 4. Number Select Bar with mm & cm (Direct typing & stepping)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.0,
          ),
          child: Column(
            children: [
              // Unit Toggle Row [ mm | cm ]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bangle Circumference",
                    style: widget.theme.fontMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.theme.textSecondary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: widget.theme.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.theme.border, width: 1.2),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _setBangleUnit(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _bangleUnitIsMm ? const Color(0xFFD35400) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "mm",
                              style: widget.theme.fontMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _bangleUnitIsMm ? Colors.white : widget.theme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _setBangleUnit(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: !_bangleUnitIsMm ? const Color(0xFFD35400) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "cm",
                              style: widget.theme.fontMono(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !_bangleUnitIsMm ? Colors.white : widget.theme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  BouncyTap(
                    onTap: () {
                      if (_bangleUnitIsMm) {
                        final currentMm = _bangleDiameterMm * math.pi;
                        if (currentMm > 157.0) {
                          final newMm = (currentMm - 2.0).clamp(157.0, 251.3);
                          setState(() {
                            _bangleDiameterMm = (newMm / math.pi).clamp(50.0, 80.0);
                            _updateKnuckleTextFromBangleDiameter();
                          });
                        }
                      } else {
                        final currentCm = (_bangleDiameterMm * math.pi) / 10.0;
                        if (currentCm > 15.7) {
                          final newCm = (currentCm - 0.1).clamp(15.0, 26.0);
                          setState(() {
                            _bangleDiameterMm = ((newCm * 10.0) / math.pi).clamp(50.0, 80.0);
                            _updateKnuckleTextFromBangleDiameter();
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: Text(
                        _bangleUnitIsMm ? "-2 mm" : "-0.1 cm",
                        style: widget.theme.fontMono(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFFD35400)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Container(
                      height: 44,
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
                            _bangleUnitIsMm ? "mm" : "cm",
                            style: widget.theme.fontMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.text.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _bangleUnitIsMm
                                ? "(${((_bangleDiameterMm * math.pi) / 10.0).toStringAsFixed(2)} cm)"
                                : "(${(_bangleDiameterMm * math.pi).toStringAsFixed(1)} mm)",
                            style: widget.theme.fontMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.text.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  BouncyTap(
                    onTap: () {
                      if (_bangleUnitIsMm) {
                        final currentMm = _bangleDiameterMm * math.pi;
                        if (currentMm < 251.3) {
                          final newMm = (currentMm + 2.0).clamp(157.0, 251.3);
                          setState(() {
                            _bangleDiameterMm = (newMm / math.pi).clamp(50.0, 80.0);
                            _updateKnuckleTextFromBangleDiameter();
                          });
                        }
                      } else {
                        final currentCm = (_bangleDiameterMm * math.pi) / 10.0;
                        if (currentCm < 25.1) {
                          final newCm = (currentCm + 0.1).clamp(15.0, 26.0);
                          setState(() {
                            _bangleDiameterMm = ((newCm * 10.0) / math.pi).clamp(50.0, 80.0);
                            _updateKnuckleTextFromBangleDiameter();
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: Text(
                        _bangleUnitIsMm ? "+2 mm" : "+0.1 cm",
                        style: widget.theme.fontMono(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFFD35400)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Quick Standard Bangle Size Chips (Showing both mm and cm numbers)
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
                    final mmStr = "${mm.toStringAsFixed(1)}mm";
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
                            "${item['name']} • $mmStr (${item['cm']})",
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
  // 3. WATCH STRAP SIZER VIEW (Realistic 1:1 Physical Scale & Control Bar)
  // =========================================================================
  Widget _buildWatchStrapSizer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Realistic Watch Strap & 1:1 Physical Caliper Visualizer (At Top)
        Container(
          height: 350,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: widget.theme.doodleCard(
            color: widget.theme.cardBg,
            borderWidth: 2.2,
          ),
          child: Stack(
            children: [
              // Full Precision Coordinate Graph & Realistic Watch Strap
              Positioned.fill(
                child: CustomPaint(
                  painter: _RealisticWatchStrapCaliperPainter(
                    lugMm: _selectedLugMm,
                    pixelsPerMm: _pixelsPerMm,
                    primaryColor: const Color(0xFF2980B9),
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
                    child: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF2980B9)),
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
                    border: Border.all(color: const Color(0xFF2980B9).withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Text(
                    "Lug Width: $_selectedLugMm mm  •  ${(_selectedLugMm / 25.4).toStringAsFixed(2)}\"",
                    style: widget.theme.fontMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2980B9),
                    ),
                  ),
                ),
              ),

              // Bottom Live Caliper Hint
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
                        "Physical Scale 1:1  •  Hold watch case lugs between caliper jaws",
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

        const SizedBox(height: 14),

        // 2. Control Bar (Minus Icon, Slider, Plus Icon & Standard Width Pills)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            children: [
              Row(
                children: [
                  BouncyTap(
                    onTap: () {
                      if (_selectedLugMm > 12) {
                        setState(() => _selectedLugMm = (_selectedLugMm - 1).clamp(12, 26));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: const Icon(Icons.remove_rounded, size: 22, color: Color(0xFF2980B9)),
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
                        value: _selectedLugMm.toDouble(),
                        min: 12.0,
                        max: 26.0,
                        divisions: 14,
                        activeColor: const Color(0xFF2980B9),
                        inactiveColor: widget.theme.border,
                        onChanged: (val) {
                          setState(() => _selectedLugMm = val.round());
                        },
                      ),
                    ),
                  ),
                  BouncyTap(
                    onTap: () {
                      if (_selectedLugMm < 26) {
                        setState(() => _selectedLugMm = (_selectedLugMm + 1).clamp(12, 26));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.theme.border, width: 1.5),
                      ),
                      child: const Icon(Icons.add_rounded, size: 22, color: Color(0xFF2980B9)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Standard Lug Width Chips (12mm to 26mm)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [12, 14, 16, 18, 19, 20, 21, 22, 24, 26].map((w) {
                    final isSel = (_selectedLugMm == w);
                    final isCommon = (w == 18 || w == 20 || w == 22);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: BouncyTap(
                        onTap: () {
                          SoundService().playClick();
                          setState(() => _selectedLugMm = w);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF2980B9) : widget.theme.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSel ? const Color(0xFF2980B9) : widget.theme.border,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            isCommon ? "$w mm ★" : "$w mm",
                            style: widget.theme.fontMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : widget.theme.text,
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
      ],
    );
  }

  // =========================================================================
  // 4. RULER PIN MARKER WIDGET (Crisp SVG Push-Pin & Precise Measurement)
  // =========================================================================
  Widget _buildPinMarkerWidget(double pinMm, int index) {
    final pinY = pinMm * _pixelsPerMm;
    final cm = pinMm / 10.0;
    final inches = pinMm / 25.4;

    return Positioned(
      top: pinY - 14,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Red horizontal measurement line across ruler width
            Positioned(
              top: 13,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: const Color(0xFFE74C3C),
              ),
            ),
            // Center Floating Pill with SVG Pin Icon & Measurement
            GestureDetector(
              onTap: () {
                SoundService().playClick();
                _showPinsBottomSheet();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(
                      kRulerPinSvg,
                      width: 15,
                      height: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${cm.toStringAsFixed(1)} cm  (${inches.toStringAsFixed(2)}\")",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 4. RULER SIZER (Vertical Default View reaching bottom edge & Full Screen Hover trigger)
  // =========================================================================
  Widget _buildRulerSizer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double rulerHeight = constraints.maxHeight;
          final double totalCm = (rulerHeight / _pixelsPerMm) / 10.0;

          return Container(
            width: double.infinity,
            height: rulerHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F1DC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: widget.theme.border, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.border.withValues(alpha: 0.25),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Ruler Canvas with tap-to-pin
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      SoundService().playClick();
                      final localY = details.localPosition.dy;
                      final tappedMm = localY / _pixelsPerMm;
                      setState(() {
                        _pinnedPointsMm.add(tappedMm);
                      });
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, rulerHeight),
                      painter: _InfiniteTapeRulerPainter(
                        pixelsPerMm: _pixelsPerMm,
                        totalCm: totalCm,
                        pinnedPointsMm: _pinnedPointsMm,
                        primaryColor: widget.theme.primary,
                      ),
                    ),
                  ),
                ),

                // Pinned points widgets on normal view
                for (int p = 0; p < _pinnedPointsMm.length; p++)
                  _buildPinMarkerWidget(_pinnedPointsMm[p], p),

                // Upper Middle Hover Full Screen Button
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: BouncyTap(
                      onTap: _enterFullScreenRuler,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3436).withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(
                              "Full Screen",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 5. FULL SCREEN SCROLLABLE RULER (Edge-to-Edge, Hover Upper Middle Buttons)
  // =========================================================================
  Widget _buildFullScreenRulerView() {
    const double totalLengthCm = 500.0; // 500 cm = 5 Meters seamless tape
    final double totalHeightPx = totalLengthCm * 10.0 * _pixelsPerMm;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1DC),
      body: Stack(
        children: [
          // 1. Edge-to-Edge Smooth Scrollable Ruler Canvas (from absolute top y=0 to bottom)
          Positioned.fill(
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
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: SizedBox(
                  width: double.infinity,
                  height: totalHeightPx,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(double.infinity, totalHeightPx),
                        painter: _InfiniteTapeRulerPainter(
                          pixelsPerMm: _pixelsPerMm,
                          totalCm: totalLengthCm,
                          pinnedPointsMm: _pinnedPointsMm,
                          primaryColor: widget.theme.primary,
                        ),
                      ),
                      // Pinned markers rendered as crisp vector SVG pushpin widgets
                      for (int p = 0; p < _pinnedPointsMm.length; p++)
                        _buildPinMarkerWidget(_pinnedPointsMm[p], p),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Upper Middle Hover Action Buttons (Back & Pin) - NO navigation bar!
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3436).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back Hover Button (Restores normal screen size & unhides hover page header)
                    BouncyTap(
                      onTap: _exitFullScreenRuler,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 5),
                            Text(
                              "Back",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Pin Hover Button with count badge & SVG Pushpin Icon
                    BouncyTap(
                      onTap: () {
                        SoundService().playClick();
                        _showPinsBottomSheet();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.string(
                              kRulerPinSvg,
                              width: 17,
                              height: 17,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _pinnedPointsMm.isEmpty ? "Pin" : "Pin (${_pinnedPointsMm.length})",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pin points bottom hover sheet with Undo and Clear All
  void _showPinsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.theme.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: widget.theme.border, width: 2),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sheet Header with Title, Undo, and Clear All
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pinned Points (${_pinnedPointsMm.length})",
                          style: widget.theme.fontDisplay(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Undo button (removes newest / last pin)
                            TextButton.icon(
                              onPressed: _pinnedPointsMm.isEmpty
                                  ? null
                                  : () {
                                      SoundService().playClick();
                                      setState(() {
                                        _pinnedPointsMm.removeLast();
                                      });
                                      setSheetState(() {});
                                    },
                              icon: const Icon(Icons.undo_rounded, size: 16),
                              label: const Text("Undo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 4),
                            // Clear All button
                            TextButton.icon(
                              onPressed: _pinnedPointsMm.isEmpty
                                  ? null
                                  : () {
                                      SoundService().playClick();
                                      setState(() {
                                        _pinnedPointsMm.clear();
                                      });
                                      setSheetState(() {});
                                    },
                              icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFE74C3C)),
                              label: const Text("Clear All", style: TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (_pinnedPointsMm.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "No pins yet. Tap anywhere on the ruler canvas to drop a pin!",
                            style: widget.theme.fontDoodle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _pinnedPointsMm.length,
                          itemBuilder: (ctx, i) {
                            final mm = _pinnedPointsMm[i];
                            final cm = mm / 10.0;
                            final inches = mm / 25.4;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: widget.theme.bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: widget.theme.border.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.string(
                                    kRulerPinSvg,
                                    width: 18,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Pin #${i + 1}:  ${cm.toStringAsFixed(2)} cm  /  ${inches.toStringAsFixed(3)} in  (${mm.toStringAsFixed(1)} mm)",
                                      style: widget.theme.fontMono(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                    onPressed: () {
                                      SoundService().playClick();
                                      setState(() {
                                        _pinnedPointsMm.removeAt(i);
                                      });
                                      setSheetState(() {});
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
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
            );
          },
        );
      },
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

/// Realistic Vector Watch Strap & Physical Caliper (Vertical orientation, true 1:1 physical lug width)
class _RealisticWatchStrapCaliperPainter extends CustomPainter {
  final int lugMm;
  final double pixelsPerMm;
  final Color primaryColor;
  final Color accentColor;
  final Color gridColor;

  _RealisticWatchStrapCaliperPainter({
    required this.lugMm,
    required this.pixelsPerMm,
    required this.primaryColor,
    required this.accentColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Millimeter Coordinate Background Grid
    final step2mm = 2.0 * pixelsPerMm;
    final step10mm = 10.0 * pixelsPerMm;

    final majorGridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;
    final minorGridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.07)
      ..strokeWidth = 0.5;

    for (double x = center.dx; x < size.width; x += step2mm) {
      final isMajor = ((x - center.dx) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorGridPaint : minorGridPaint);
    }
    for (double x = center.dx - step2mm; x > 0; x -= step2mm) {
      final isMajor = ((center.dx - x) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorGridPaint : minorGridPaint);
    }
    for (double y = center.dy; y < size.height; y += step2mm) {
      final isMajor = ((y - center.dy) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorGridPaint : minorGridPaint);
    }
    for (double y = center.dy - step2mm; y > 0; y -= step2mm) {
      final isMajor = ((center.dy - y) % step10mm).abs() < (step2mm * 0.4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorGridPaint : minorGridPaint);
    }

    // Exact physical strap width in logical pixels
    final double strapWidth = lugMm * pixelsPerMm;
    final double leftX = center.dx - (strapWidth / 2);
    final double rightX = center.dx + (strapWidth / 2);

    // Watch Head Placement Gap
    const double gapHeight = 54.0;
    final double gapTop = center.dy - (gapHeight / 2);
    final double gapBottom = center.dy + (gapHeight / 2);

    // 2. Leather & Stitching Paints
    final leatherPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3E2723), Color(0xFF5D4037), Color(0xFF3E2723)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(leftX, 0, strapWidth, size.height));

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final stitchPaint = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // 3. TOP STRAP PIECE (Buckle End)
    final double topStrapHeight = gapTop - 28.0;
    if (topStrapHeight > 20) {
      final topStrapRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(leftX, 28, strapWidth, topStrapHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      canvas.drawRRect(topStrapRect, shadowPaint);
      canvas.drawRRect(topStrapRect, leatherPaint);

      // Top Stitching
      final topStitchRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(leftX + 4, 32, strapWidth - 8, topStrapHeight - 6),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(topStitchRect, stitchPaint);

      // Keeper Loops (Fixed keeper & floating keeper)
      final keeperPaint = Paint()..color = const Color(0xFF4E342E);
      final keeperStitch = Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final keeper1Rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftX - 1.5, 48, strapWidth + 3, 10),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(keeper1Rect, keeperPaint);
      canvas.drawRRect(keeper1Rect, keeperStitch);

      final keeper2Rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftX - 1.5, 66, strapWidth + 3, 10),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(keeper2Rect, keeperPaint);
      canvas.drawRRect(keeper2Rect, keeperStitch);

      // Metallic Brushed Steel Buckle at top
      final buckleOuterRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(leftX - 6, 12, strapWidth + 12, 18),
        const Radius.circular(4.5),
      );
      final bucklePaint = Paint()
        ..color = const Color(0xFFECEFF1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2;
      canvas.drawRRect(buckleOuterRect, bucklePaint);

      // Buckle Prong
      final prongPaint = Paint()
        ..color = const Color(0xFF78909C)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(center.dx, 12), Offset(center.dx, 32), prongPaint);

      // Top Spring Bar Pin (at gapTop)
      final pinPaint = Paint()
        ..color = const Color(0xFF90A4AE)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(leftX - 4, gapTop - 1), Offset(rightX + 4, gapTop - 1), pinPaint);
    }

    // 4. BOTTOM STRAP PIECE (Long Tail Piece with adjustment holes & pointed tip)
    final double bottomStrapTop = gapBottom + 2;
    final double bottomStrapBottom = size.height - 18;
    final double bottomStrapHeight = bottomStrapBottom - bottomStrapTop;

    if (bottomStrapHeight > 20) {
      final tailPath = Path();
      tailPath.moveTo(leftX, bottomStrapTop);
      tailPath.lineTo(rightX, bottomStrapTop);
      tailPath.lineTo(rightX, bottomStrapBottom - 18);
      // Traditional English pointed watch strap tip
      tailPath.lineTo(center.dx, bottomStrapBottom);
      tailPath.lineTo(leftX, bottomStrapBottom - 18);
      tailPath.close();

      canvas.drawPath(tailPath, shadowPaint);
      canvas.drawPath(tailPath, leatherPaint);

      // Bottom Stitching
      final stitchPath = Path();
      stitchPath.moveTo(leftX + 4, bottomStrapTop + 4);
      stitchPath.lineTo(rightX - 4, bottomStrapTop + 4);
      stitchPath.lineTo(rightX - 4, bottomStrapBottom - 20);
      stitchPath.lineTo(center.dx, bottomStrapBottom - 4);
      stitchPath.lineTo(leftX + 4, bottomStrapBottom - 20);
      stitchPath.close();
      canvas.drawPath(stitchPath, stitchPaint);

      // 6 Precision Punched Adjustment Holes along center
      final holeFill = Paint()..color = const Color(0xFF2E1C14);
      final holeRing = Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      for (int i = 0; i < 6; i++) {
        final hy = bottomStrapTop + 24.0 + (i * 14.0);
        if (hy < bottomStrapBottom - 24) {
          canvas.drawCircle(Offset(center.dx, hy), 2.2, holeFill);
          canvas.drawCircle(Offset(center.dx, hy), 2.2, holeRing);
        }
      }

      // Bottom Spring Bar Pin (at gapBottom)
      final pinPaint = Paint()
        ..color = const Color(0xFF90A4AE)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(leftX - 4, gapBottom + 1), Offset(rightX + 4, gapBottom + 1), pinPaint);
    }

    // 5. CALIPER GUIDE JAWS & DIMENSION TICKS IN WATCH GAP
    final caliperJawPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5;

    // Left caliper vertical jaw
    canvas.drawLine(Offset(leftX, gapTop - 6), Offset(leftX, gapBottom + 6), caliperJawPaint);
    // Right caliper vertical jaw
    canvas.drawLine(Offset(rightX, gapTop - 6), Offset(rightX, gapBottom + 6), caliperJawPaint);

    // Millimeter ticks on jaws
    final tickPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1.2;
    for (double y = gapTop; y <= gapBottom; y += (2.0 * pixelsPerMm)) {
      final isMajor = ((y - center.dy).abs() % (10.0 * pixelsPerMm)) < 1.0;
      final tickLen = isMajor ? 6.0 : 3.5;
      canvas.drawLine(Offset(leftX, y), Offset(leftX - tickLen, y), tickPaint);
      canvas.drawLine(Offset(rightX, y), Offset(rightX + tickLen, y), tickPaint);
    }

    // Dimension Arrow Line between jaws
    final dimPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(leftX + 2, center.dy), Offset(rightX - 2, center.dy), dimPaint);

    // Left arrowhead (<)
    canvas.drawLine(Offset(leftX + 8, center.dy - 4), Offset(leftX + 2, center.dy), dimPaint);
    canvas.drawLine(Offset(leftX + 8, center.dy + 4), Offset(leftX + 2, center.dy), dimPaint);

    // Right arrowhead (>)
    canvas.drawLine(Offset(rightX - 8, center.dy - 4), Offset(rightX - 2, center.dy), dimPaint);
    canvas.drawLine(Offset(rightX - 8, center.dy + 4), Offset(rightX - 2, center.dy), dimPaint);

    // Center Dimension Text Pill inside gap
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: "$lugMm mm",
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF1C40F),
        backgroundColor: Colors.black87,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _RealisticWatchStrapCaliperPainter old) =>
      old.lugMm != lugMm ||
      old.pixelsPerMm != pixelsPerMm ||
      old.primaryColor != primaryColor;
}

/// Smooth Vertical Scrollable Tape Ruler (Dual Unit Edge Scales & High Performance Culling)
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

    final clip = canvas.getLocalClipBounds();
    final double minY = clip.isInfinite ? 0.0 : math.max(0.0, clip.top - 80.0);
    final double maxY = clip.isInfinite ? size.height : math.min(size.height, clip.bottom + 80.0);

    final int startMm = (minY / pixelsPerMm).floor().clamp(0, totalMm);
    final int endMm = (maxY / pixelsPerMm).ceil().clamp(0, totalMm);

    final tickPaint = Paint()
      ..color = const Color(0xFF2D3436)
      ..strokeWidth = 1.0;
    final cmTickPaint = Paint()
      ..color = const Color(0xFF1E272E)
      ..strokeWidth = 2.2;
    final meterBannerPaint = Paint()..color = const Color(0xFFE74C3C);

    final tp = TextPainter(textDirection: TextDirection.ltr);

    // 1. Draw Metric Scale on Left Edge (mm, cm, m)
    if (minY <= 40) {
      tp.text = const TextSpan(
        text: '◀ CM / MM',
        style: TextStyle(
          color: Color(0xFF27AE60),
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      );
      tp.layout();
      tp.paint(canvas, const Offset(6, 6));
    }

    for (int mm = startMm; mm <= endMm; mm++) {
      final double y = mm * pixelsPerMm;
      final bool isMeter = (mm % 1000 == 0 && mm > 0);
      final bool isCm = (mm % 10 == 0);
      final bool isHalf = (mm % 5 == 0);

      if (isMeter) {
        // Meter Milestone Line
        canvas.drawRect(Rect.fromLTWH(0, y - 2, w, 4), meterBannerPaint);
        tp.text = TextSpan(
          text: '${mm ~/ 1000} METER (${mm ~/ 10} cm)',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
        );
        tp.layout();
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.5 - (tp.width + 16) / 2, y - 11, tp.width + 16, 22), const Radius.circular(6)),
          Paint()..color = const Color(0xFFE74C3C),
        );
        tp.paint(canvas, Offset(w * 0.5 - tp.width / 2, y - tp.height / 2));
      } else if (isCm) {
        canvas.drawLine(Offset(0, y), Offset(38, y), cmTickPaint);
        final cmVal = mm ~/ 10;
        tp.text = TextSpan(
          children: [
            TextSpan(
              text: '$cmVal',
              style: TextStyle(
                color: cmVal % 10 == 0 ? const Color(0xFFD63031) : const Color(0xFF2D3436),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ' cm',
              style: TextStyle(
                color: cmVal % 10 == 0 ? const Color(0xFFD63031) : const Color(0xFF27AE60),
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
        tp.layout();
        tp.paint(canvas, Offset(42, y - tp.height / 2));
      } else if (isHalf) {
        canvas.drawLine(Offset(0, y), Offset(22, y), tickPaint);
        // Subtle mm indicator on half-cm tick
        tp.text = const TextSpan(
          text: '5mm',
          style: TextStyle(
            color: Color(0xFF7F8C8D),
            fontSize: 7.5,
            fontWeight: FontWeight.w600,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(25, y - tp.height / 2));
      } else {
        canvas.drawLine(Offset(0, y), Offset(13, y), tickPaint);
      }
    }

    // 2. Draw Imperial Scale on Right Edge (Inches, 1/16, 1/8, 1/4, 1/2)
    final double totalInches = (totalMm / 25.4);
    final int totalSixteenths = (totalInches * 16).toInt();

    final double minInch = (minY / pixelsPerMm) / 25.4;
    final double maxInch = (maxY / pixelsPerMm) / 25.4;
    final int startSixteenth = (minInch * 16).floor().clamp(0, totalSixteenths);
    final int endSixteenth = (maxInch * 16).ceil().clamp(0, totalSixteenths);

    if (minY <= 40) {
      tp.text = const TextSpan(
        text: 'INCHES ▶',
        style: TextStyle(
          color: Color(0xFF0984E3),
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(w - 6 - tp.width, 6));
    }

    for (int s = startSixteenth; s <= endSixteenth; s++) {
      final double inchVal = s / 16.0;
      final double mmVal = inchVal * 25.4;
      final double y = mmVal * pixelsPerMm;

      final bool isWhole = (s % 16 == 0);
      final bool isHalf = (s % 8 == 0);
      final bool isQuarter = (s % 4 == 0);

      if (isWhole) {
        canvas.drawLine(Offset(w - 38, y), Offset(w, y), cmTickPaint);
        final int wholeInch = s ~/ 16;
        tp.text = TextSpan(
          children: [
            TextSpan(
              text: '$wholeInch',
              style: const TextStyle(
                color: Color(0xFF0984E3),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(
              text: ' in',
              style: TextStyle(
                color: Color(0xFF0984E3),
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
        tp.layout();
        tp.paint(canvas, Offset(w - 42 - tp.width, y - tp.height / 2));
      } else if (isHalf) {
        canvas.drawLine(Offset(w - 24, y), Offset(w, y), tickPaint);
        tp.text = const TextSpan(
          text: '½"',
          style: TextStyle(
            color: Color(0xFF74B9FF),
            fontSize: 8.0,
            fontWeight: FontWeight.w600,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(w - 26 - tp.width, y - tp.height / 2));
      } else if (isQuarter) {
        canvas.drawLine(Offset(w - 18, y), Offset(w, y), tickPaint);
      } else {
        canvas.drawLine(Offset(w - 11, y), Offset(w, y), tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InfiniteTapeRulerPainter old) => true;
}
