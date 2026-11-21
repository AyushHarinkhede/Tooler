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

/// 36 Major Global Radio Hubs across every continent for real-time live exploration
const List<GlobalRadioHub> kGlobalRadioHubs = [
  GlobalRadioHub(code: 'IN', name: 'India', city: 'Mumbai · Delhi', flag: '🇮🇳', lat: 20.59, lon: 78.96),
  GlobalRadioHub(code: 'US', name: 'USA', city: 'New York · LA', flag: '🇺🇸', lat: 37.09, lon: -95.71),
  GlobalRadioHub(code: 'GB', name: 'United Kingdom', city: 'London', flag: '🇬🇧', lat: 55.37, lon: -3.43),
  GlobalRadioHub(code: 'JP', name: 'Japan', city: 'Tokyo', flag: '🇯🇵', lat: 36.20, lon: 138.25),
  GlobalRadioHub(code: 'DE', name: 'Germany', city: 'Berlin', flag: '🇩🇪', lat: 51.16, lon: 10.45),
  GlobalRadioHub(code: 'FR', name: 'France', city: 'Paris', flag: '🇫🇷', lat: 46.22, lon: 2.21),
  GlobalRadioHub(code: 'AE', name: 'UAE', city: 'Dubai', flag: '🇦🇪', lat: 23.42, lon: 53.84),
  GlobalRadioHub(code: 'BR', name: 'Brazil', city: 'Rio · São Paulo', flag: '🇧🇷', lat: -14.23, lon: -51.92),
  GlobalRadioHub(code: 'AU', name: 'Australia', city: 'Sydney · Melbourne', flag: '🇦🇺', lat: -25.27, lon: 133.77),
  GlobalRadioHub(code: 'KR', name: 'South Korea', city: 'Seoul', flag: '🇰🇷', lat: 35.90, lon: 127.76),
  GlobalRadioHub(code: 'CA', name: 'Canada', city: 'Toronto · Montreal', flag: '🇨🇦', lat: 56.13, lon: -106.34),
  GlobalRadioHub(code: 'IT', name: 'Italy', city: 'Rome · Milan', flag: '🇮🇹', lat: 41.87, lon: 12.56),
  GlobalRadioHub(code: 'ES', name: 'Spain', city: 'Madrid · Barcelona', flag: '🇪🇸', lat: 40.46, lon: -3.74),
  GlobalRadioHub(code: 'NL', name: 'Netherlands', city: 'Amsterdam', flag: '🇳🇱', lat: 52.13, lon: 5.29),
  GlobalRadioHub(code: 'RU', name: 'Russia', city: 'Moscow', flag: '🇷🇺', lat: 61.52, lon: 105.31),
  GlobalRadioHub(code: 'MX', name: 'Mexico', city: 'Mexico City', flag: '🇲🇽', lat: 23.63, lon: -102.55),
  GlobalRadioHub(code: 'ZA', name: 'South Africa', city: 'Cape Town · Joburg', flag: '🇿🇦', lat: -30.55, lon: 22.93),
  GlobalRadioHub(code: 'TR', name: 'Turkey', city: 'Istanbul', flag: '🇹🇷', lat: 38.96, lon: 35.24),
  GlobalRadioHub(code: 'ID', name: 'Indonesia', city: 'Jakarta', flag: '🇮🇩', lat: -0.78, lon: 113.92),
  GlobalRadioHub(code: 'EG', name: 'Egypt', city: 'Cairo', flag: '🇪🇬', lat: 26.82, lon: 30.80),
  GlobalRadioHub(code: 'SE', name: 'Sweden', city: 'Stockholm', flag: '🇸🇪', lat: 60.12, lon: 18.64),
  GlobalRadioHub(code: 'AR', name: 'Argentina', city: 'Buenos Aires', flag: '🇦🇷', lat: -38.41, lon: -63.61),
  GlobalRadioHub(code: 'SG', name: 'Singapore', city: 'Singapore', flag: '🇸🇬', lat: 1.35, lon: 103.81),
  GlobalRadioHub(code: 'CH', name: 'Switzerland', city: 'Zurich · Geneva', flag: '🇨🇭', lat: 46.81, lon: 8.22),
  GlobalRadioHub(code: 'PH', name: 'Philippines', city: 'Manila', flag: '🇵🇭', lat: 12.87, lon: 121.77),
  GlobalRadioHub(code: 'SA', name: 'Saudi Arabia', city: 'Riyadh · Jeddah', flag: '🇸🇦', lat: 23.88, lon: 45.07),
  GlobalRadioHub(code: 'NZ', name: 'New Zealand', city: 'Auckland', flag: '🇳🇿', lat: -40.90, lon: 174.88),
  GlobalRadioHub(code: 'KE', name: 'Kenya', city: 'Nairobi', flag: '🇰🇪', lat: -0.02, lon: 37.90),
  GlobalRadioHub(code: 'PL', name: 'Poland', city: 'Warsaw', flag: '🇵🇱', lat: 51.91, lon: 19.14),
  GlobalRadioHub(code: 'TH', name: 'Thailand', city: 'Bangkok', flag: '🇹🇭', lat: 15.87, lon: 100.99),
  GlobalRadioHub(code: 'NG', name: 'Nigeria', city: 'Lagos · Abuja', flag: '🇳🇬', lat: 9.08, lon: 8.67),
  GlobalRadioHub(code: 'GR', name: 'Greece', city: 'Athens', flag: '🇬🇷', lat: 39.07, lon: 21.82),
  GlobalRadioHub(code: 'VN', name: 'Vietnam', city: 'Hanoi · HCM City', flag: '🇻🇳', lat: 14.05, lon: 108.27),
  GlobalRadioHub(code: 'CL', name: 'Chile', city: 'Santiago', flag: '🇨🇱', lat: -35.67, lon: -71.54),
  GlobalRadioHub(code: 'CO', name: 'Colombia', city: 'Bogota', flag: '🇨🇴', lat: 4.57, lon: -74.29),
  GlobalRadioHub(code: 'IE', name: 'Ireland', city: 'Dublin', flag: '🇮🇪', lat: 53.14, lon: -7.69),
];

/// Interactive Rotating 3D Globe with Atmosphere Aura, Detailed Vector Landmasses,
/// Great-Circle Radio Signal Beams, Orbiting Satellite Relay & Tactile Beacons.
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

  double _lonOffsetDeg = -78.96; // Center on India initially
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
      duration: const Duration(seconds: 36),
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
    final hub = kGlobalRadioHubs.firstWhere(
      (h) => h.code.toUpperCase() == code.toUpperCase(),
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
    double minDist = 34.0;
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
          width: 256,
          height: 256,
          child: AnimatedBuilder(
            animation: Listenable.merge([_spinController, _focusController, _pulseController]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(256, 256),
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
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.cardBg.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: theme.border, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: theme.isDark ? 0.3 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public_rounded, size: 11.5, color: theme.primary),
                          const SizedBox(width: 5),
                          Text(
                            'SWIPE TO ROTATE · TAP PIN FOR LIVE FM',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
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

  // Accurate detailed continent coordinates ([lat, lon] in degrees)
  static const List<List<List<double>>> _rawContinents = [
    // North America (Alaska, Canada, USA, Mexico, Central America)
    [
      [71, -156], [69, -141], [68, -133], [60, -140], [56, -132], [54, -130],
      [49, -125], [45, -124], [38, -123], [34, -119], [30, -114], [23, -110],
      [22, -105], [19, -104], [16, -98], [15, -92], [14, -89], [9, -83],
      [8, -78], [9, -77], [12, -84], [16, -88], [21, -89], [21, -97],
      [26, -97], [29, -94], [30, -88], [25, -81], [30, -81], [35, -75],
      [41, -71], [45, -64], [47, -53], [53, -56], [59, -64], [62, -74],
      [68, -85], [70, -100], [70, -130],
    ],
    // Greenland
    [
      [60, -44], [64, -51], [72, -56], [78, -72], [82, -35], [76, -18],
      [70, -22], [65, -36],
    ],
    // South America
    [
      [12, -72], [11, -63], [7, -58], [2, -50], [-3, -40], [-5, -35],
      [-10, -36], [-15, -39], [-23, -42], [-29, -49], [-35, -57], [-42, -63],
      [-53, -68], [-55, -67], [-52, -74], [-45, -75], [-37, -73], [-24, -70],
      [-17, -71], [-5, -81], [2, -79], [8, -77],
    ],
    // Europe
    [
      [36, -6], [38, -9], [43, -9], [44, -1], [49, -1], [51, 2], [54, 8],
      [57, 10], [60, 5], [64, 11], [71, 26], [68, 30], [60, 28], [55, 21],
      [54, 14], [48, 17], [45, 14], [42, 18], [40, 23], [36, 23], [37, 15],
      [41, 13], [44, 8], [43, 3], [37, -2],
    ],
    // Scandinavia
    [
      [58, 5], [63, 8], [69, 16], [71, 26], [66, 24], [60, 18], [56, 12],
    ],
    // UK & Ireland
    [
      [50, -5], [54, -3], [58, -3], [58, -6], [55, -6], [51, 1],
    ],
    // Africa
    [
      [36, -6], [37, 10], [33, 11], [32, 24], [31, 32], [26, 35], [22, 37],
      [12, 44], [11, 51], [3, 47], [-4, 40], [-11, 40], [-17, 39], [-26, 33],
      [-34, 19], [-33, 18], [-28, 16], [-16, 12], [-6, 12], [4, 9], [6, 2],
      [5, -4], [6, -11], [14, -17], [21, -17], [28, -12], [32, -9],
    ],
    // Madagascar
    [
      [-12, 49], [-16, 50], [-25, 47], [-25, 44], [-17, 44],
    ],
    // Asia Mainland + Arabian Peninsula + India
    [
      [68, 32], [72, 70], [75, 110], [70, 160], [64, 175], [58, 162],
      [52, 142], [43, 132], [39, 127], [35, 129], [30, 122], [22, 114],
      [16, 108], [11, 108], [8, 103], [13, 100], [21, 92], [22, 88],
      [16, 82], [9, 78], [15, 74], [22, 69], [25, 62], [25, 57], [15, 53],
      [13, 44], [22, 38], [28, 35], [33, 35], [37, 36], [42, 29], [46, 38],
      [55, 48],
    ],
    // Japan
    [
      [31, 131], [35, 136], [40, 140], [44, 145], [42, 141], [35, 133],
    ],
    // Indonesia & Philippines
    [
      [5, 96], [-6, 106], [-8, 115], [-6, 113], [-2, 104], [3, 98],
    ],
    // Australia
    [
      [-12, 131], [-13, 142], [-20, 148], [-28, 153], [-37, 150], [-38, 144],
      [-35, 137], [-32, 129], [-34, 116], [-28, 114], [-22, 114], [-16, 123],
    ],
    // New Zealand
    [
      [-35, 173], [-41, 175], [-46, 168], [-44, 167], [-38, 174],
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
        final steps = math.max(1, (dist / 5.2).ceil());
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
    final center = Offset(size.width / 2, size.height / 2 - 4);
    final radius = size.width * 0.395;
    final isDark = theme.isDark;
    final accent = theme.primary;

    // 1. Deep Atmospheric Rayleigh Glow (Outer Halo)
    canvas.drawCircle(
      center,
      radius + 20,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: isPlaying ? 0.30 : 0.16),
            accent.withValues(alpha: 0.08),
            accent.withValues(alpha: 0.0),
          ],
          stops: const [0.65, 0.85, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 20)),
    );

    // 2. Back Orbit Ring
    _drawOrbitRing(canvas, center, radius + 15, isFront: false, accent: accent);

    // 3. Deep 3D Ocean Sphere with Curvature Shading
    final sphereRect = Rect.fromCircle(center: center, radius: radius);
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 1.12,
        colors: isDark
            ? [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
                const Color(0xFF060911),
              ]
            : [
                Color.lerp(Colors.white, accent, 0.14)!,
                Color.lerp(const Color(0xFFE0F2FE), accent, 0.20)!,
                Color.lerp(const Color(0xFF7DD3FC), accent, 0.35)!,
              ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, oceanPaint);

    // Clip globe interior
    canvas.save();
    canvas.clipPath(Path()..addOval(sphereRect));

    // 4. Subtle Latitude/Longitude Graticule with Equator Marker
    final graticulePaint = Paint()
      ..color = (isDark ? Colors.white : accent).withValues(alpha: isDark ? 0.075 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    final equatorPaint = Paint()
      ..color = (isDark ? Colors.white : accent).withValues(alpha: isDark ? 0.18 : 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Parallels (Latitudes)
    for (double lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool started = false;
      for (double lon = -180; lon <= 180; lon += 5) {
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

    // Meridians (Longitudes)
    for (double lon = -180; lon < 180; lon += 30) {
      final path = Path();
      bool started = false;
      for (double lat = -84; lat <= 84; lat += 5) {
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

    // 5. Horizon-Clipped Continents with Clean Coastal Strokes
    final landFill = Paint()
      ..color = isDark
          ? accent.withValues(alpha: 0.38)
          : accent.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;

    final landStroke = Paint()
      ..color = isDark
          ? accent.withValues(alpha: 0.90)
          : accent.withValues(alpha: 0.85)
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

    // 6. Realistic 3D Specular Sun Glare & Twilight Limb Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.34, center.dy - radius * 0.36),
        width: radius * 0.55,
        height: radius * 0.32,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.09 : 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Subtle edge rim shadow
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
          ],
          stops: const [0.78, 1.0],
        ).createShader(sphereRect),
    );

    canvas.restore();

    // 7. Crisp Sphere Rim Ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accent.withValues(alpha: isDark ? 0.60 : 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // 8. Front Orbit Ring + Satellite
    _drawOrbitRing(canvas, center, radius + 15, isFront: true, accent: accent);

    // 9. Interactive Beacons & Active Radio Signal Arcs
    GlobalRadioHub? selectedHub;
    Offset? selectedBeaconPos;

    for (final hub in kGlobalRadioHubs) {
      final v = _rotateUnit(hub.lat, hub.lon);
      if (v.z <= 0.08) continue; // Front hemisphere only

      final off = Offset(center.dx + v.x * radius, center.dy + v.y * radius);
      hitBeaconsOut.add(_HitBeacon(hub, off));
      final bool isSelected = hub.code.toUpperCase() == selectedCode.toUpperCase();
      final depthScale = (0.70 + v.z * 0.40).clamp(0.70, 1.15);

      if (isSelected) {
        selectedHub = hub;
        selectedBeaconPos = off;

        // Multi-stage radio pulse ripples
        for (int rIdx = 0; rIdx < 2; rIdx++) {
          final p = (pulsePhase + rIdx * 0.5) % 1.0;
          canvas.drawCircle(
            off,
            (6.0 + p * 16.0) * depthScale,
            Paint()
              ..color = const Color(0xFFF43F5E).withValues(alpha: (1.0 - p) * 0.70)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        }

        // Selected Pin Center
        canvas.drawCircle(
          off,
          5.5 * depthScale,
          Paint()..color = const Color(0xFFF43F5E),
        );
        canvas.drawCircle(
          off,
          2.4 * depthScale,
          Paint()..color = Colors.white,
        );
      } else {
        // Ambient hub beacon
        canvas.drawCircle(
          off,
          4.8 * depthScale,
          Paint()..color = accent.withValues(alpha: 0.22),
        );
        canvas.drawCircle(
          off,
          2.6 * depthScale,
          Paint()..color = isDark ? Colors.white70 : accent,
        );
      }
    }

    // 10. Selected Country HUD Badge
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
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final boxW = tp.width + 16;
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
        Paint()..color = Colors.black.withValues(alpha: 0.25),
      );
      // Tag background
      canvas.drawRRect(
        tagRect,
        Paint()..color = const Color(0xFFE11D48),
      );
      tp.paint(canvas, Offset(bx + 8, by + 4));
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

    // Orbiting live satellite
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
        6.0,
        Paint()..color = accent.withValues(alpha: 0.28),
      );
      canvas.drawCircle(
        satPt,
        2.8,
        Paint()..color = isPlaying ? const Color(0xFFF43F5E) : accent,
      );
      // Small satellite solar panels
      canvas.drawLine(
        Offset(satPt.dx - 4, satPt.dy),
        Offset(satPt.dx + 4, satPt.dy),
        Paint()
          ..color = (isPlaying ? const Color(0xFFF43F5E) : accent).withValues(alpha: 0.8)
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Globe3DMapPainter old) => true;
}
