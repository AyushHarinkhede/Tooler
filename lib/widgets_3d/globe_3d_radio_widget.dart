import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';

class GlobalRadioHub {
  final String code;
  final String name;
  final String city;
  final String flag;
  final double lat;
  final double lon;

  const GlobalRadioHub({
    required this.code,
    required this.name,
    required this.city,
    required this.flag,
    required this.lat,
    required this.lon,
  });
}

/// 54 Major Global & Regional Radio Hubs across every continent for real-time live exploration
const List<GlobalRadioHub> kGlobalRadioHubs = [
  // India & South Asia (Precise Regional Metros)
  GlobalRadioHub(code: 'IN', name: 'India (Mumbai)', city: 'Mumbai Airwaves', flag: '🇮🇳', lat: 19.07, lon: 72.87),
  GlobalRadioHub(code: 'IN_DEL', name: 'India (Delhi)', city: 'National Capital Radio', flag: '🇮🇳', lat: 28.61, lon: 77.20),
  GlobalRadioHub(code: 'IN_BLR', name: 'India (Bengaluru)', city: 'Silicon Plateau FM', flag: '🇮🇳', lat: 12.97, lon: 77.59),
  GlobalRadioHub(code: 'IN_CCU', name: 'India (Kolkata)', city: 'Bengal Live FM', flag: '🇮🇳', lat: 22.57, lon: 88.36),
  GlobalRadioHub(code: 'IN_MAA', name: 'India (Chennai)', city: 'Coromandel Hits', flag: '🇮🇳', lat: 13.08, lon: 80.27),
  GlobalRadioHub(code: 'IN_HYD', name: 'India (Hyderabad)', city: 'Deccan Radio Waves', flag: '🇮🇳', lat: 17.38, lon: 78.48),
  GlobalRadioHub(code: 'IN_JAI', name: 'India (Jaipur)', city: 'Pink City FM', flag: '🇮🇳', lat: 26.91, lon: 75.78),
  GlobalRadioHub(code: 'LK', name: 'Sri Lanka', city: 'Colombo', flag: '🇱🇰', lat: 6.92, lon: 79.86),
  GlobalRadioHub(code: 'NP', name: 'Nepal', city: 'Kathmandu', flag: '🇳🇵', lat: 27.71, lon: 85.32),
  GlobalRadioHub(code: 'BD', name: 'Bangladesh', city: 'Dhaka', flag: '🇧🇩', lat: 23.81, lon: 90.41),

  // Middle East & West Asia
  GlobalRadioHub(code: 'AE', name: 'UAE', city: 'Dubai · Abu Dhabi', flag: '🇦🇪', lat: 25.20, lon: 55.27),
  GlobalRadioHub(code: 'SA', name: 'Saudi Arabia', city: 'Riyadh · Jeddah', flag: '🇸🇦', lat: 24.71, lon: 46.67),
  GlobalRadioHub(code: 'QA', name: 'Qatar', city: 'Doha', flag: '🇶🇦', lat: 25.28, lon: 51.53),
  GlobalRadioHub(code: 'TR', name: 'Turkey', city: 'Istanbul · Ankara', flag: '🇹🇷', lat: 41.00, lon: 28.97),
  GlobalRadioHub(code: 'EG', name: 'Egypt', city: 'Cairo · Alexandria', flag: '🇪🇬', lat: 30.04, lon: 31.23),

  // East Asia & Southeast Asia
  GlobalRadioHub(code: 'JP', name: 'Japan', city: 'Tokyo · Osaka', flag: '🇯🇵', lat: 35.67, lon: 139.65),
  GlobalRadioHub(code: 'KR', name: 'South Korea', city: 'Seoul · Busan', flag: '🇰🇷', lat: 37.56, lon: 126.97),
  GlobalRadioHub(code: 'SG', name: 'Singapore', city: 'Singapore City', flag: '🇸🇬', lat: 1.35, lon: 103.81),
  GlobalRadioHub(code: 'TH', name: 'Thailand', city: 'Bangkok', flag: '🇹🇭', lat: 13.75, lon: 100.50),
  GlobalRadioHub(code: 'MY', name: 'Malaysia', city: 'Kuala Lumpur', flag: '🇲🇾', lat: 3.13, lon: 101.68),
  GlobalRadioHub(code: 'ID', name: 'Indonesia', city: 'Jakarta · Bali', flag: '🇮🇩', lat: -6.20, lon: 106.84),
  GlobalRadioHub(code: 'PH', name: 'Philippines', city: 'Manila', flag: '🇵🇭', lat: 14.59, lon: 120.98),
  GlobalRadioHub(code: 'VN', name: 'Vietnam', city: 'Hanoi · HCM City', flag: '🇻🇳', lat: 21.02, lon: 105.83),

  // Europe & UK
  GlobalRadioHub(code: 'GB', name: 'United Kingdom', city: 'London · Manchester', flag: '🇬🇧', lat: 51.50, lon: -0.12),
  GlobalRadioHub(code: 'FR', name: 'France', city: 'Paris · Lyon', flag: '🇫🇷', lat: 48.85, lon: 2.35),
  GlobalRadioHub(code: 'DE', name: 'Germany', city: 'Berlin · Munich', flag: '🇩🇪', lat: 52.52, lon: 13.40),
  GlobalRadioHub(code: 'IT', name: 'Italy', city: 'Rome · Milan', flag: '🇮🇹', lat: 41.90, lon: 12.49),
  GlobalRadioHub(code: 'ES', name: 'Spain', city: 'Madrid · Barcelona', flag: '🇪🇸', lat: 40.41, lon: -3.70),
  GlobalRadioHub(code: 'NL', name: 'Netherlands', city: 'Amsterdam', flag: '🇳🇱', lat: 52.36, lon: 4.90),
  GlobalRadioHub(code: 'CH', name: 'Switzerland', city: 'Zurich · Geneva', flag: '🇨🇭', lat: 47.37, lon: 8.54),
  GlobalRadioHub(code: 'SE', name: 'Sweden', city: 'Stockholm', flag: '🇸🇪', lat: 59.32, lon: 18.06),
  GlobalRadioHub(code: 'PL', name: 'Poland', city: 'Warsaw', flag: '🇵🇱', lat: 52.22, lon: 21.01),
  GlobalRadioHub(code: 'GR', name: 'Greece', city: 'Athens', flag: '🇬🇷', lat: 37.98, lon: 23.72),
  GlobalRadioHub(code: 'IE', name: 'Ireland', city: 'Dublin', flag: '🇮🇪', lat: 53.34, lon: -6.26),
  GlobalRadioHub(code: 'AT', name: 'Austria', city: 'Vienna', flag: '🇦🇹', lat: 48.20, lon: 16.37),
  GlobalRadioHub(code: 'NO', name: 'Norway', city: 'Oslo', flag: '🇳🇴', lat: 59.91, lon: 10.75),
  GlobalRadioHub(code: 'RU', name: 'Russia', city: 'Moscow · St. Petersburg', flag: '🇷🇺', lat: 55.75, lon: 37.61),

  // Americas (North, Central & South)
  GlobalRadioHub(code: 'US', name: 'USA (New York)', city: 'New York City', flag: '🇺🇸', lat: 40.71, lon: -74.00),
  GlobalRadioHub(code: 'US_LAX', name: 'USA (West Coast)', city: 'Los Angeles · SF', flag: '🇺🇸', lat: 34.05, lon: -118.24),
  GlobalRadioHub(code: 'CA', name: 'Canada', city: 'Toronto · Montreal', flag: '🇨🇦', lat: 43.65, lon: -79.38),
  GlobalRadioHub(code: 'MX', name: 'Mexico', city: 'Mexico City', flag: '🇲🇽', lat: 19.43, lon: -99.13),
  GlobalRadioHub(code: 'BR', name: 'Brazil', city: 'São Paulo · Rio', flag: '🇧🇷', lat: -23.55, lon: -46.63),
  GlobalRadioHub(code: 'AR', name: 'Argentina', city: 'Buenos Aires', flag: '🇦🇷', lat: -34.60, lon: -58.38),
  GlobalRadioHub(code: 'CL', name: 'Chile', city: 'Santiago', flag: '🇨🇱', lat: -33.44, lon: -70.66),
  GlobalRadioHub(code: 'CO', name: 'Colombia', city: 'Bogota · Medellin', flag: '🇨🇴', lat: 4.71, lon: -74.07),

  // Oceania
  GlobalRadioHub(code: 'AU', name: 'Australia (Sydney)', city: 'Sydney · Melbourne', flag: '🇦🇺', lat: -33.86, lon: 151.20),
  GlobalRadioHub(code: 'NZ', name: 'New Zealand', city: 'Auckland · Wellington', flag: '🇳🇿', lat: -36.84, lon: 174.76),

  // Africa
  GlobalRadioHub(code: 'ZA', name: 'South Africa', city: 'Johannesburg · Cape Town', flag: '🇿🇦', lat: -26.20, lon: 28.04),
  GlobalRadioHub(code: 'NG', name: 'Nigeria', city: 'Lagos · Abuja', flag: '🇳🇬', lat: 6.52, lon: 3.37),
  GlobalRadioHub(code: 'KE', name: 'Kenya', city: 'Nairobi', flag: '🇰🇪', lat: -1.29, lon: 36.82),
  GlobalRadioHub(code: 'MA', name: 'Morocco', city: 'Casablanca · Rabat', flag: '🇲🇦', lat: 33.57, lon: -7.58),
  GlobalRadioHub(code: 'GH', name: 'Ghana', city: 'Accra', flag: '🇬🇭', lat: 5.60, lon: -0.18),
];

/// Interactive Rotating 3D Globe with Atmosphere Aura, High-Definition Vector Continents,
/// Precise Coastlines, Great-Circle Radio Signal Beams & Orbiting Satellite Relay.
class Globe3DRadioWidget extends StatefulWidget {
  final StationeryTheme theme;
  final String selectedCountryCode;
  final bool isPlaying;
  final ValueChanged<GlobalRadioHub> onHubSelected;

  const Globe3DRadioWidget({
    super.key,
    required this.theme,
    required this.selectedCountryCode,
    required this.isPlaying,
    required this.onHubSelected,
  });

  @override
  State<Globe3DRadioWidget> createState() => _Globe3DRadioWidgetState();
}

class _Globe3DRadioWidgetState extends State<Globe3DRadioWidget>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _focusController;
  late final AnimationController _pulseController;

  double _lonOffsetDeg = -78.96; // Centered on India initially
  double _latTiltDeg = 20.0;
  bool _isDragging = false;
  DateTime _pauseSpinUntil = DateTime.fromMillisecondsSinceEpoch(0);

  double _focusFromLon = -78.96;
  double _focusToLon = -78.96;
  double _focusFromLat = 20.0;
  double _focusToLat = 20.0;
  double _lastTickVal = 0.0;

  final List<_HitBeacon> _hitBeacons = [];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )
      ..addListener(() {
        final now = DateTime.now();
        if (!_isDragging &&
            !_focusController.isAnimating &&
            now.isAfter(_pauseSpinUntil)) {
          double delta = _spinController.value - _lastTickVal;
          if (delta < 0) delta += 1.0;
          _lonOffsetDeg = (_lonOffsetDeg - delta * 360.0) % 360.0;
        }
        _lastTickVal = _spinController.value;
      })
      ..repeat();

    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(_focusController.value);
        setState(() {
          _lonOffsetDeg = _focusFromLon + (_focusToLon - _focusFromLon) * t;
          _latTiltDeg = _focusFromLat + (_focusToLat - _focusFromLat) * t;
        });
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _focusOnCode(widget.selectedCountryCode, animate: false);
  }

  @override
  void didUpdateWidget(covariant Globe3DRadioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCountryCode != widget.selectedCountryCode) {
      _focusOnCode(widget.selectedCountryCode, animate: true);
    }
  }

  void _focusOnCode(String code, {required bool animate}) {
    final clean = code.toUpperCase().trim();
    final hub = kGlobalRadioHubs.firstWhere(
      (h) =>
          h.code.toUpperCase() == clean ||
          clean.startsWith(h.code.toUpperCase()) ||
          h.code.toUpperCase().startsWith(clean),
      orElse: () => kGlobalRadioHubs.first,
    );
    final targetLon = -hub.lon;
    final targetLat = hub.lat.clamp(-48.0, 48.0);
    _pauseSpinUntil = DateTime.now().add(const Duration(milliseconds: 3200));

    if (!animate) {
      _lonOffsetDeg = targetLon;
      _latTiltDeg = targetLat;
      return;
    }
    double diff = (targetLon - _lonOffsetDeg) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;

    _focusFromLon = _lonOffsetDeg;
    _focusToLon = _lonOffsetDeg + diff;
    _focusFromLat = _latTiltDeg;
    _focusToLat = targetLat;
    _focusController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _focusController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    GlobalRadioHub? nearest;
    double minDist = 36.0;
    for (final hb in _hitBeacons) {
      final d = (hb.offset - pos).distance;
      if (d < minDist) {
        minDist = d;
        nearest = hb.hub;
      }
    }
    if (nearest != null) {
      HapticFeedback.selectionClick();
      _pauseSpinUntil = DateTime.now().add(const Duration(seconds: 4));
      widget.onHubSelected(nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return GestureDetector(
      onPanStart: (_) {
        _focusController.stop();
        _isDragging = true;
      },
      onPanUpdate: (details) {
        setState(() {
          _lonOffsetDeg = (_lonOffsetDeg + details.delta.dx * 0.55) % 360.0;
          _latTiltDeg = (_latTiltDeg + details.delta.dy * 0.42).clamp(-58.0, 58.0);
        });
      },
      onPanEnd: (_) {
        _isDragging = false;
        _pauseSpinUntil = DateTime.now().add(const Duration(milliseconds: 2200));
      },
      onTapUp: _handleTapUp,
      child: Center(
        child: SizedBox(
          width: 270,
          height: 270,
          child: AnimatedBuilder(
            animation: Listenable.merge([_spinController, _focusController, _pulseController]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(270, 270),
                    painter: _Globe3DMapPainter(
                      lonOffsetDeg: _lonOffsetDeg,
                      latTiltDeg: _latTiltDeg,
                      pulsePhase: _pulseController.value,
                      spinPhase: _spinController.value,
                      selectedCode: widget.selectedCountryCode,
                      isPlaying: widget.isPlaying,
                      theme: theme,
                      hitBeaconsOut: _hitBeacons,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: theme.cardBg.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: theme.border, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: theme.isDark ? 0.35 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.satellite_alt_rounded, size: 11, color: theme.primary),
                          const SizedBox(width: 5),
                          Text(
                            'SWIPE TO ROTATE 360° · TAP CITY TO TUNE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HitBeacon {
  final GlobalRadioHub hub;
  final Offset offset;
  const _HitBeacon(this.hub, this.offset);
}

class _Vec3 {
  final double x, y, z;
  const _Vec3(this.x, this.y, this.z);
}

class _Globe3DMapPainter extends CustomPainter {
  final double lonOffsetDeg;
  final double latTiltDeg;
  final double pulsePhase;
  final double spinPhase;
  final String selectedCode;
  final bool isPlaying;
  final StationeryTheme theme;
  final List<_HitBeacon> hitBeaconsOut;

  _Globe3DMapPainter({
    required this.lonOffsetDeg,
    required this.latTiltDeg,
    required this.pulsePhase,
    required this.spinPhase,
    required this.selectedCode,
    required this.isPlaying,
    required this.theme,
    required this.hitBeaconsOut,
  });

  // Highly Detailed Geographic Continents & Subcontinents (Accurate [lat, lon] polygons)
  static const List<List<List<double>>> _rawContinents = [
    // 1. INDIAN SUBCONTINENT (High precision coastal boundary: Gujarat, Mumbai, Goa, Kerala, Kanyakumari, Chennai, Vizag, Bengal, Himalayas)
    [
      [24, 68], [23, 70], [21, 69], [21, 72], [19, 72.8], [15.5, 73.8], [12, 75],
      [8.1, 77.5], [9.3, 79], [13, 80.3], [16, 82], [18, 84], [21.5, 87], [22, 89],
      [23, 91], [26, 92], [27, 88], [28, 85], [30, 80], [33, 76], [35, 74],
      [31, 71], [27, 68], [24, 68],
    ],
    // 2. SRI LANKA
    [
      [9.8, 80.2], [8.6, 81.2], [6.9, 81.8], [5.9, 80.5], [6.9, 79.8], [8.6, 79.8],
    ],
    // 3. ARABIAN PENINSULA & PERSIAN GULF (Saudi Arabia, UAE, Oman, Yemen)
    [
      [30, 48], [27, 49], [25, 51], [24, 54], [25.5, 56.5], [23.5, 58.5],
      [18, 55], [14.5, 53], [12.8, 45], [12.5, 43.5], [16, 42], [21, 39],
      [28, 35], [29.5, 35], [31, 36], [30, 48],
    ],
    // 4. SOUTHEAST ASIA MAINLAND (Indochina, Thailand, Myanmar, Vietnam, Malaysia)
    [
      [21, 92], [16, 94], [14, 98], [10, 98], [5, 100], [1.3, 103.8],
      [3, 103], [7, 101], [12, 100], [13, 101], [10, 105], [9, 107],
      [12, 109], [16, 108], [21, 108], [22, 104], [25, 98], [24, 94],
    ],
    // 5. INDONESIAN ARCHIPELAGO (Sumatra, Java, Borneo, Sulawesi)
    [
      [5.5, 95.3], [1, 98], [-4, 104], [-6, 106], [-8, 114], [-8, 116],
      [-5, 114], [-2, 108], [1, 104], [5.5, 95.3],
    ],
    // Borneo
    [
      [7, 116.5], [4, 118], [1, 119], [-3, 116], [-3.5, 112], [0, 109], [4, 114],
    ],
    // 6. PHILIPPINES
    [
      [18.5, 121], [14, 124], [9, 126], [6, 125], [9, 122], [14.5, 120], [18.5, 121],
    ],
    // 7. EAST ASIA & CHINA MAINLAND
    [
      [22, 108], [22, 114], [25, 119], [30, 122], [35, 120], [39, 122], [40, 128],
      [43, 132], [50, 140], [53, 141], [58, 137], [64, 172], [70, 178], [72, 140],
      [76, 110], [72, 70], [60, 60], [50, 70], [42, 80], [35, 90], [28, 98],
    ],
    // 8. JAPAN ARCHIPELAGO (Honshu, Hokkaido, Kyushu)
    [
      [31, 130.5], [33, 132], [35, 136], [38, 140], [42, 141], [45, 142],
      [43, 145], [40, 142], [36, 140], [34, 136], [31, 130.5],
    ],
    // 9. EUROPE MAINLAND & MEDITERRANEAN (Iberia, France, Germany, Italy, Balkans, Greece)
    [
      [36, -6], [37, -9], [43, -9], [43.5, -1.8], [47, -3], [49, -1], [51, 2],
      [54, 8], [55, 12], [54, 18], [58, 22], [60, 28], [55, 37], [45, 36],
      [42, 28], [40, 23], [37, 22], [39, 16], [41, 15], [44, 13], [45, 8],
      [43, 3], [37, -1], [36, -6],
    ],
    // Italy Peninsula Boot
    [
      [44, 8], [42, 11], [38, 15], [37, 14], [40, 18], [45, 13],
    ],
    // 10. BRITISH ISLES (Great Britain & Ireland)
    [
      [50, -5], [54, -3], [58, -3], [58, -6], [55, -6], [51, 1], [50, -5],
    ],
    [
      [51.5, -9.5], [54, -8], [55, -7], [53, -6], [52, -6.5],
    ],
    // 11. SCANDINAVIA (Norway, Sweden, Finland)
    [
      [58, 5], [62, 5], [68, 14], [71, 25], [70, 31], [65, 25], [60, 19], [56, 12],
    ],
    // 12. AFRICA (Mediterranean, Horn of Africa, Cape of Good Hope, Gulf of Guinea)
    [
      [36, -6], [37, 10], [33, 11], [31, 30], [26, 35], [22, 37], [12, 44],
      [11, 51], [3, 47], [-4, 40], [-11, 40], [-17, 39], [-26, 33], [-34, 19],
      [-34, 18], [-28, 16], [-16, 12], [-6, 12], [4, 9], [6, 2], [5, -4],
      [6, -11], [14, -17], [21, -17], [28, -12], [32, -9], [36, -6],
    ],
    // Madagascar
    [
      [-12, 49], [-16, 50], [-25, 47], [-25, 44], [-17, 44],
    ],
    // 13. NORTH AMERICA (Alaska, Canada, USA, Florida, California, Mexico, Central America)
    [
      [71, -156], [69, -141], [60, -140], [54, -130], [49, -125], [45, -124],
      [38, -123], [34, -119], [30, -114], [23, -110], [19, -104], [16, -98],
      [15, -92], [9, -83], [8, -78], [12, -84], [16, -88], [21, -89],
      [26, -97], [29, -94], [25, -81], [30, -81], [35, -75], [41, -71],
      [45, -64], [47, -53], [53, -56], [59, -64], [62, -74], [68, -85],
      [70, -100], [70, -130], [71, -156],
    ],
    // 14. SOUTH AMERICA (Colombia, Venezuela, Brazil Bulge, Argentina, Chile, Peru)
    [
      [12, -72], [11, -63], [7, -58], [2, -50], [-3, -40], [-5, -35],
      [-10, -36], [-15, -39], [-23, -42], [-29, -49], [-35, -57], [-42, -63],
      [-53, -68], [-55, -67], [-52, -74], [-45, -75], [-37, -73], [-24, -70],
      [-17, -71], [-5, -81], [2, -79], [8, -77], [12, -72],
    ],
    // 15. AUSTRALIA & OCEANIA
    [
      [-12, 131], [-13, 142], [-20, 148], [-28, 153], [-37, 150], [-38, 144],
      [-35, 137], [-32, 129], [-34, 116], [-28, 114], [-22, 114], [-16, 123],
      [-12, 131],
    ],
    // New Zealand (North & South Islands)
    [
      [-35, 173], [-41, 175], [-46, 168], [-44, 167], [-38, 174],
    ],
    // 16. GREENLAND
    [
      [60, -44], [64, -51], [72, -56], [78, -72], [82, -35], [76, -18],
      [70, -22], [65, -36], [60, -44],
    ],
  ];

  static final List<List<List<double>>> _continents = _buildSubdividedContinents();

  static List<List<List<double>>> _buildSubdividedContinents() {
    final out = <List<List<double>>>[];
    for (final poly in _rawContinents) {
      final sub = <List<double>>[];
      for (int i = 0; i < poly.length; i++) {
        final a = poly[i];
        final b = poly[(i + 1) % poly.length];
        final dLat = b[0] - a[0];
        final dLon = b[1] - a[1];
        final dist = math.sqrt(dLat * dLat + dLon * dLon);
        final steps = math.max(1, (dist / 4.4).ceil());
        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          sub.add([a[0] + dLat * t, a[1] + dLon * t]);
        }
      }
      out.add(sub);
    }
    return out;
  }

  _Vec3 _rotateUnit(double latDeg, double lonDeg) {
    const deg2Rad = math.pi / 180.0;
    final lat = latDeg * deg2Rad;
    final lon = (lonDeg + lonOffsetDeg) * deg2Rad;
    final tilt = latTiltDeg * deg2Rad;

    final x0 = math.cos(lat) * math.sin(lon);
    final y0 = -math.sin(lat);
    final z0 = math.cos(lat) * math.cos(lon);

    final cosT = math.cos(tilt);
    final sinT = math.sin(tilt);
    final y1 = y0 * cosT - z0 * sinT;
    final z1 = y0 * sinT + z0 * cosT;

    return _Vec3(x0, y1, z1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    hitBeaconsOut.clear();
    final center = Offset(size.width / 2, size.height / 2 - 5);
    final radius = size.width * 0.435; // Larger, immersion-first sphere diameter
    final isDark = theme.isDark;
    final accent = theme.primary;

    // 1. Multi-Stage Atmospheric Rayleigh Scattering (Soft Glowing Blue/Cyan Outer Corona)
    canvas.drawCircle(
      center,
      radius + 24,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF0284C7).withValues(alpha: isPlaying ? 0.35 : 0.22),
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.0),
          ],
          stops: const [0.70, 0.88, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 24)),
    );

    // 2. Back Orbit Ring
    _drawOrbitRing(canvas, center, radius + 18, isFront: false, accent: accent);

    // 3. Deep 3D Spherical Ocean with Curvature Shading
    final sphereRect = Rect.fromCircle(center: center, radius: radius);
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.38),
        radius: 1.15,
        colors: isDark
            ? [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
                const Color(0xFF050811),
              ]
            : [
                Color.lerp(Colors.white, accent, 0.16)!,
                Color.lerp(const Color(0xFFE0F2FE), accent, 0.25)!,
                Color.lerp(const Color(0xFF38BDF8), accent, 0.40)!,
              ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, oceanPaint);

    // Clip globe interior for all spherical surface elements
    canvas.save();
    canvas.clipPath(Path()..addOval(sphereRect));

    // 4. Precision Graticule (Latitude Parallels & Longitude Meridians with Equator Marker)
    final graticulePaint = Paint()
      ..color = (isDark ? Colors.white : accent).withValues(alpha: isDark ? 0.08 : 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final equatorPaint = Paint()
      ..color = (isDark ? const Color(0xFF38BDF8) : accent).withValues(alpha: isDark ? 0.24 : 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Parallels (Latitudes: -60°, -30°, 0°, 30°, 60°)
    for (double lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool started = false;
      for (double lon = -180; lon <= 180; lon += 4) {
        final v = _rotateUnit(lat, lon);
        if (v.z >= 0) {
          final px = center.dx + v.x * radius;
          final py = center.dy + v.y * radius;
          if (!started) {
            path.moveTo(px, py);
            started = true;
          } else {
            path.lineTo(px, py);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, lat == 0 ? equatorPaint : graticulePaint);
    }

    // Meridians (Longitudes every 30°)
    for (double lon = -180; lon < 180; lon += 30) {
      final path = Path();
      bool started = false;
      for (double lat = -84; lat <= 84; lat += 4) {
        final v = _rotateUnit(lat, lon);
        if (v.z >= 0) {
          final px = center.dx + v.x * radius;
          final py = center.dy + v.y * radius;
          if (!started) {
            path.moveTo(px, py);
            started = true;
          } else {
            path.lineTo(px, py);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, graticulePaint);
    }

    // 5. Horizon-Clipped Continents with Tactical Coastal Borders
    final landFill = Paint()
      ..color = isDark
          ? accent.withValues(alpha: 0.38)
          : accent.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;

    final landStroke = Paint()
      ..color = isDark
          ? accent.withValues(alpha: 0.92)
          : accent.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeJoin = StrokeJoin.round;

    for (final poly in _continents) {
      final pts3 = poly.map((c) => _rotateUnit(c[0], c[1])).toList();
      final clipped = _clipPolygonToFrontHemisphere(pts3);
      if (clipped.length < 3) continue;

      final path = Path();
      for (int i = 0; i < clipped.length; i++) {
        final off = Offset(
          center.dx + clipped[i].x * radius,
          center.dy + clipped[i].y * radius,
        );
        if (i == 0) {
          path.moveTo(off.dx, off.dy);
        } else {
          path.lineTo(off.dx, off.dy);
        }
      }
      path.close();
      canvas.drawPath(path, landFill);
      canvas.drawPath(path, landStroke);
    }

    // 6. Realistic 3D Solar Specular Glare & Twilight Limb Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.35, center.dy - radius * 0.38),
        width: radius * 0.60,
        height: radius * 0.35,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.12 : 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Deep Horizon Edge Twilight Vignette
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: isDark ? 0.50 : 0.18),
          ],
          stops: const [0.76, 1.0],
        ).createShader(sphereRect),
    );

    canvas.restore();

    // 7. Atmospheric Blue Luminous Rim Ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.70 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // 8. Front Orbit Ring + Satellite
    _drawOrbitRing(canvas, center, radius + 18, isFront: true, accent: accent);

    // 9. Interactive Beacons & Active Radio Signal Arcs
    GlobalRadioHub? selectedHub;
    Offset? selectedBeaconPos;

    for (final hub in kGlobalRadioHubs) {
      final v = _rotateUnit(hub.lat, hub.lon);
      if (v.z <= 0.08) continue; // Front hemisphere only

      final off = Offset(center.dx + v.x * radius, center.dy + v.y * radius);
      hitBeaconsOut.add(_HitBeacon(hub, off));
      final bool isSelected = hub.code.toUpperCase() == selectedCode.toUpperCase() ||
          selectedCode.toUpperCase().startsWith(hub.code.toUpperCase());
      final depthScale = (0.72 + v.z * 0.42).clamp(0.72, 1.18);

      if (isSelected) {
        selectedHub = hub;
        selectedBeaconPos = off;

        // Multi-stage radio pulse ripples
        for (int rIdx = 0; rIdx < 2; rIdx++) {
          final p = (pulsePhase + rIdx * 0.5) % 1.0;
          canvas.drawCircle(
            off,
            (6.5 + p * 18.0) * depthScale,
            Paint()
              ..color = const Color(0xFFF43F5E).withValues(alpha: (1.0 - p) * 0.75)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        }

        // Selected Pin Center
        canvas.drawCircle(
          off,
          5.6 * depthScale,
          Paint()..color = const Color(0xFFF43F5E),
        );
        canvas.drawCircle(
          off,
          2.5 * depthScale,
          Paint()..color = Colors.white,
        );
      } else {
        // Ambient city station beacon
        canvas.drawCircle(
          off,
          4.8 * depthScale,
          Paint()..color = accent.withValues(alpha: 0.24),
        );
        canvas.drawCircle(
          off,
          2.6 * depthScale,
          Paint()..color = isDark ? Colors.white70 : accent,
        );
      }
    }

    // 10. Selected Country & City Floating HUD Badge
    if (selectedBeaconPos != null && selectedHub != null) {
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${selectedHub.flag} ${selectedHub.name} · ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: selectedHub.city,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFDE047),
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final boxW = tp.width + 18;
      final boxH = tp.height + 8;
      final bx = (selectedBeaconPos.dx - boxW / 2).clamp(8.0, size.width - boxW - 8.0);
      final by = (selectedBeaconPos.dy - boxH - 12).clamp(8.0, size.height - boxH - 26.0);
      final tagRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, boxW, boxH),
        const Radius.circular(8),
      );

      // Shadow
      canvas.drawRRect(
        tagRect.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.30),
      );
      // Tag background (Studio Ruby Red)
      canvas.drawRRect(
        tagRect,
        Paint()..color = const Color(0xFFBE123C),
      );
      tp.paint(canvas, Offset(bx + 9, by + 4));
    }
  }

  List<_Vec3> _clipPolygonToFrontHemisphere(List<_Vec3> pts) {
    int frontCount = 0;
    for (final p in pts) {
      if (p.z >= 0) frontCount++;
    }
    if (frontCount == 0) return const [];
    if (frontCount == pts.length) return pts;

    final out = <_Vec3>[];
    final n = pts.length;
    for (int i = 0; i < n; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % n];
      final aIn = a.z >= 0;
      final bIn = b.z >= 0;

      if (aIn) out.add(a);

      if (aIn != bIn) {
        final t = a.z / (a.z - b.z);
        final ix = a.x + (b.x - a.x) * t;
        final iy = a.y + (b.y - a.y) * t;
        final len = math.sqrt(ix * ix + iy * iy);
        if (len > 1e-4) {
          out.add(_Vec3(ix / len, iy / len, 0.0));
        }
      }
    }

    final smoothed = <_Vec3>[];
    for (int i = 0; i < out.length; i++) {
      final curr = out[i];
      final next = out[(i + 1) % out.length];
      smoothed.add(curr);
      if (curr.z == 0.0 && next.z == 0.0) {
        final angA = math.atan2(curr.y, curr.x);
        var diff = math.atan2(next.y, next.x) - angA;
        if (diff > math.pi) diff -= 2 * math.pi;
        if (diff < -math.pi) diff += 2 * math.pi;
        final arcSteps = math.max(1, (diff.abs() / 0.14).ceil());
        for (int s = 1; s < arcSteps; s++) {
          final a = angA + diff * (s / arcSteps);
          smoothed.add(_Vec3(math.cos(a), math.sin(a), 0.0));
        }
      }
    }
    return smoothed;
  }

  void _drawOrbitRing(
    Canvas canvas,
    Offset center,
    double r, {
    required bool isFront,
    required Color accent,
  }) {
    const segs = 72;
    const tiltX = 1.15;
    const tiltZ = -0.30;
    final path = Path();
    bool started = false;

    for (int i = 0; i <= segs; i++) {
      final th = (i / segs) * math.pi * 2.0;
      final x0 = r * math.cos(th);
      final y0 = r * math.sin(th);
      final y1 = y0 * math.cos(tiltX);
      final z1 = y0 * math.sin(tiltX);
      final x2 = x0 * math.cos(tiltZ) - y1 * math.sin(tiltZ);
      final y2 = x0 * math.sin(tiltZ) + y1 * math.cos(tiltZ);

      final visible = isFront ? (z1 >= 0) : (z1 < 0);
      if (visible) {
        final pt = Offset(center.dx + x2, center.dy + y2);
        if (!started) {
          path.moveTo(pt.dx, pt.dy);
          started = true;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      } else {
        started = false;
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: isFront ? 0.45 : 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isFront ? 1.5 : 1.0,
    );

    // Orbiting live communication relay satellite
    final satAngle = (spinPhase * 2.5 + pulsePhase * 0.5) * math.pi * 2.0;
    final sx0 = r * math.cos(satAngle);
    final sy0 = r * math.sin(satAngle);
    final sy1 = sy0 * math.cos(tiltX);
    final sz1 = sy0 * math.sin(tiltX);
    final satVisible = isFront ? (sz1 >= 0) : (sz1 < 0);
    if (satVisible) {
      final sx2 = sx0 * math.cos(tiltZ) - sy1 * math.sin(tiltZ);
      final sy2 = sx0 * math.sin(tiltZ) + sy1 * math.cos(tiltZ);
      final satPt = Offset(center.dx + sx2, center.dy + sy2);

      // Satellite glow
      canvas.drawCircle(
        satPt,
        6.5,
        Paint()..color = accent.withValues(alpha: 0.32),
      );
      canvas.drawCircle(
        satPt,
        3.0,
        Paint()..color = isPlaying ? const Color(0xFFF43F5E) : accent,
      );
      // Small satellite solar panels
      canvas.drawLine(
        Offset(satPt.dx - 4.5, satPt.dy),
        Offset(satPt.dx + 4.5, satPt.dy),
        Paint()
          ..color = (isPlaying ? const Color(0xFFF43F5E) : accent).withValues(alpha: 0.9)
          ..strokeWidth = 1.3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Globe3DMapPainter old) => true;
}
