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

  // Ring state (Diameter in mm, defaults to ~18.2mm US Size 8)
  double _ringDiameterMm = 18.2;

  // Bangle state (Diameter in mm, defaults to ~60mm)
  double _bangleDiameterMm = 60.0;

  // Screen Calibration factor (pixels per mm, default ~ 3.78 for standard mobile density)
  double _pixelsPerMm = 3.6;

  // Watch strap lug width
  int _selectedLugMm = 20;

  // Ruler caliper drag position in mm
  double _caliperPosMm = 50.0;

  // Ring size chart lookup
  Map<String, String> _getRingSizes(double mm) {
    if (mm < 14.5) return {'US': '3', 'UK': 'F', 'EU': '44', 'JP': '4'};
    if (mm < 15.3) return {'US': '4', 'UK': 'H', 'EU': '47', 'JP': '7'};
    if (mm < 16.1) return {'US': '5', 'UK': 'J 1/2', 'EU': '49', 'JP': '9'};
    if (mm < 16.9) return {'US': '6', 'UK': 'M', 'EU': '52', 'JP': '12'};
    if (mm < 17.7) return {'US': '7', 'UK': 'O', 'EU': '54', 'JP': '14'};
    if (mm < 18.5) return {'US': '8', 'UK': 'Q', 'EU': '57', 'JP': '16'};
    if (mm < 19.4) return {'US': '9', 'UK': 'S', 'EU': '59', 'JP': '18'};
    if (mm < 20.2) return {'US': '10', 'UK': 'T 1/2', 'EU': '62', 'JP': '20'};
    if (mm < 21.0) return {'US': '11', 'UK': 'V 1/2', 'EU': '65', 'JP': '23'};
    return {'US': '12+', 'UK': 'Z+', 'EU': '67+', 'JP': '25+'};
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
                  // Tab selection row
                  Row(
                    children: [
                      _buildTabBtn("Ring Sizer", SizerToolType.ring),
                      const SizedBox(width: 8),
                      _buildTabBtn("Bangle Sizer", SizerToolType.bangle),
                      const SizedBox(width: 8),
                      _buildTabBtn("Watch Strap", SizerToolType.strap),
                      const SizedBox(width: 8),
                      _buildTabBtn("Ruler", SizerToolType.ruler),
                    ],
                  ),

                  const SizedBox(height: 18),

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

  Widget _buildTabBtn(String label, SizerToolType type) {
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
            border: Border.all(color: widget.theme.border, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.theme.border.withOpacity(0.3),
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: widget.theme.fontMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : widget.theme.text,
            ),
          ),
        ),
      ),
    );
  }

  // Ring Sizer View
  Widget _buildRingSizer() {
    final double pixelDiameter = _ringDiameterMm * _pixelsPerMm;
    final sizes = _getRingSizes(_ringDiameterMm);

    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF4ECDC4), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Place your ring on the circle below and adjust the slider until the inner rim matches perfectly.",
                  style: widget.theme.fontDoodle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Interactive 3D Metallic Ring Circle Display
        Container(
          height: 220,
          width: double.infinity,
          decoration: widget.theme.doodleCard(
            color: widget.theme.bg,
            borderWidth: 2.5,
          ),
          alignment: Alignment.center,
          child: Container(
            width: pixelDiameter,
            height: pixelDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.theme.primary,
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.theme.primary.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${_ringDiameterMm.toStringAsFixed(1)} mm",
                  style: widget.theme.fontMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.primary,
                  ),
                ),
                Text(
                  "US Size ${sizes['US']}",
                  style: widget.theme.fontDisplay(
                    fontSize: 12,
                    color: widget.theme.text,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Diameter Slider
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Diameter: ${_ringDiameterMm.toStringAsFixed(1)} mm",
                      style: widget.theme.fontDisplay(fontSize: 15)),
                  Text("Circumference: ${( _ringDiameterMm * 3.14159 ).toStringAsFixed(1)} mm",
                      style: widget.theme.fontMono(fontSize: 13)),
                ],
              ),
              Slider(
                value: _ringDiameterMm,
                min: 14.0,
                max: 23.0,
                divisions: 90,
                activeColor: widget.theme.primary,
                onChanged: (val) {
                  setState(() => _ringDiameterMm = val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Size Chart Table
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSizeBox("US / Canada", sizes['US']!),
              _buildSizeBox("UK / Australia", sizes['UK']!),
              _buildSizeBox("Europe (EU)", sizes['EU']!),
              _buildSizeBox("Japan", sizes['JP']!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSizeBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: widget.theme.fontMono(fontSize: 10, color: widget.theme.text.withOpacity(0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: widget.theme.fontDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.theme.primary,
          ),
        ),
      ],
    );
  }

  // Bangle Sizer View
  Widget _buildBangleSizer() {
    final double pixelDiameter = _bangleDiameterMm * (_pixelsPerMm * 0.7);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Text(
            "Place an existing bangle or measure your hand width at knuckles to determine bangle diameter.",
            style: widget.theme.fontDoodle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 240,
          width: double.infinity,
          decoration: widget.theme.doodleCard(color: widget.theme.bg, borderWidth: 2.5),
          alignment: Alignment.center,
          child: Container(
            width: pixelDiameter,
            height: pixelDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.theme.secondary, width: 4),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${_bangleDiameterMm.toStringAsFixed(0)} mm",
                  style: widget.theme.fontMono(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.secondary,
                  ),
                ),
                Text(
                  "Inner Circumference: ${( _bangleDiameterMm * 3.14159 / 10 ).toStringAsFixed(1)} cm",
                  style: widget.theme.fontDoodle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Slider(
            value: _bangleDiameterMm,
            min: 50.0,
            max: 75.0,
            divisions: 25,
            activeColor: widget.theme.secondary,
            onChanged: (val) => setState(() => _bangleDiameterMm = val),
          ),
        ),
      ],
    );
  }

  // Watch Strap Sizer View
  Widget _buildWatchStrapSizer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Text(
            "Match the lug width of your watch between the gauge calipers below:",
            style: widget.theme.fontDoodle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [18, 20, 22, 24].map((width) {
            final isSel = (_selectedLugMm == width);
            return InkWell(
              onTap: () => setState(() => _selectedLugMm = width),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? widget.theme.primary : widget.theme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.theme.border, width: 2),
                ),
                child: Text(
                  "$width mm",
                  style: widget.theme.fontDisplay(
                    fontSize: 16,
                    color: isSel ? Colors.white : widget.theme.text,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: widget.theme.doodleCard(borderWidth: 2.5),
          child: Column(
            children: [
              Text("Watch Lug Gap Visualizer ($_selectedLugMm mm)",
                  style: widget.theme.fontDisplay(fontSize: 16)),
              const SizedBox(height: 16),
              Container(
                width: _selectedLugMm * _pixelsPerMm,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.theme.accent.withOpacity(0.3),
                  border: Border.symmetric(
                    vertical: BorderSide(color: widget.theme.primary, width: 4),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "$_selectedLugMm mm",
                  style: widget.theme.fontMono(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Calibrated Ruler View
  Widget _buildRulerSizer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Text(
            "On-Screen Interactive Ruler: Drag the slider to measure items in mm and inches.",
            style: widget.theme.fontDoodle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          width: double.infinity,
          decoration: widget.theme.doodleCard(
            color: const Color(0xFFE8C39E),
            borderWidth: 2.5,
          ),
          child: CustomPaint(
            painter: _RulerPainter(
              pixelsPerMm: _pixelsPerMm,
              caliperMm: _caliperPosMm,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: widget.theme.doodleCard(borderWidth: 2.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Measure: ${_caliperPosMm.toStringAsFixed(1)} mm",
                      style: widget.theme.fontDisplay(fontSize: 16)),
                  Text("${(_caliperPosMm / 25.4).toStringAsFixed(2)} inches",
                      style: widget.theme.fontMono(fontSize: 14)),
                ],
              ),
              Slider(
                value: _caliperPosMm,
                min: 0.0,
                max: 80.0,
                activeColor: widget.theme.primary,
                onChanged: (val) => setState(() => _caliperPosMm = val),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double pixelsPerMm;
  final double caliperMm;

  _RulerPainter({required this.pixelsPerMm, required this.caliperMm});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint tickPaint = Paint()
      ..color = const Color(0xFF2B1D0E)
      ..strokeWidth = 1.2;

    final Paint cmPaint = Paint()
      ..color = const Color(0xFF1E140A)
      ..strokeWidth = 2.0;

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

    for (int mm = 0; mm * pixelsPerMm < size.width - 20; mm++) {
      final double x = 20 + (mm * pixelsPerMm);
      final bool isCm = (mm % 10 == 0);
      final bool isHalf = (mm % 5 == 0);

      if (isCm) {
        canvas.drawLine(Offset(x, 0), Offset(x, 26), cmPaint);
        tp.text = TextSpan(
          text: '${mm ~/ 10}',
          style: const TextStyle(color: Color(0xFF2B1D0E), fontSize: 10, fontWeight: FontWeight.bold),
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 28));
      } else if (isHalf) {
        canvas.drawLine(Offset(x, 0), Offset(x, 18), tickPaint);
      } else {
        canvas.drawLine(Offset(x, 0), Offset(x, 12), tickPaint);
      }
    }

    // Draw caliper red indicator line
    final double caliperX = 20 + (caliperMm * pixelsPerMm);
    final Paint caliperPaint = Paint()
      ..color = const Color(0xFFFF4757)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(caliperX, 0), Offset(caliperX, size.height), caliperPaint);
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.caliperMm != caliperMm;
}
