import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';

class GlobalRadioHub {
  final String code;
  final String name;
  final String city;
  final double lat;
  final double lon;

  const GlobalRadioHub({
    required this.code,
    required this.name,
    required this.city,
    required this.lat,
    required this.lon,
  });
}

const List<GlobalRadioHub> kGlobalRadioHubs = [
  GlobalRadioHub(code: 'IN', name: 'India', city: 'Nagpur · Mumbai', lat: 21.1, lon: 79.1),
  GlobalRadioHub(code: 'US', name: 'United States', city: 'New York', lat: 40.7, lon: -74.0),
  GlobalRadioHub(code: 'GB', name: 'United Kingdom', city: 'London', lat: 51.5, lon: -0.1),
  GlobalRadioHub(code: 'JP', name: 'Japan', city: 'Tokyo', lat: 35.7, lon: 139.7),
  GlobalRadioHub(code: 'FR', name: 'France', city: 'Paris', lat: 48.8, lon: 2.3),
  GlobalRadioHub(code: 'DE', name: 'Germany', city: 'Berlin', lat: 52.5, lon: 13.4),
  GlobalRadioHub(code: 'AE', name: 'UAE', city: 'Dubai', lat: 25.2, lon: 55.3),
  GlobalRadioHub(code: 'BR', name: 'Brazil', city: 'Rio', lat: -22.9, lon: -43.2),
  GlobalRadioHub(code: 'AU', name: 'Australia', city: 'Sydney', lat: -33.9, lon: 151.2),
  GlobalRadioHub(code: 'KR', name: 'South Korea', city: 'Seoul', lat: 37.6, lon: 127.0),
  GlobalRadioHub(code: 'CA', name: 'Canada', city: 'Toronto', lat: 43.6, lon: -79.4),
  GlobalRadioHub(code: 'IT', name: 'Italy', city: 'Rome', lat: 41.9, lon: 12.5),
];

/// Interactive Rotating 3D Globe with Real Vector Continent Map & Live Radio Beacons.
/// Drag anywhere to spin the 3D Earth; tap any glowing beacon to tune into that country!
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

  double _lonOffsetDeg = -79.1; // Starts facing India cleanly!
  double _latTiltDeg = 18.0;
  bool _isDragging = false;

  double _focusFromLon = -79.1;
  double _focusToLon = -79.1;
  double _focusFromLat = 18.0;
  double _focusToLat = 18.0;
  double _lastTickVal = 0.0;

  final List<_HitBeacon> _hitBeacons = [];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )
      ..addListener(() {
        if (!_isDragging && !_focusController.isAnimating) {
          double delta = _spinController.value - _lastTickVal;
          if (delta < 0) delta += 1.0;
          _lonOffsetDeg = (_lonOffsetDeg - delta * 360.0) % 360.0;
        }
        _lastTickVal = _spinController.value;
      })
      ..repeat();

    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..addListener(() {
        final t = Curves.easeInOutCubic.transform(_focusController.value);
        setState(() {
          _lonOffsetDeg = _focusFromLon + (_focusToLon - _focusFromLon) * t;
          _latTiltDeg = _focusFromLat + (_focusToLat - _focusFromLat) * t;
        });
      });

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
      (h) => h.code == code,
      orElse: () => kGlobalRadioHubs.first,
    );
    final targetLon = -hub.lon;
    final targetLat = hub.lat.clamp(-42.0, 42.0);
    if (!animate) {
      _lonOffsetDeg = targetLon;
      _latTiltDeg = targetLat;
      return;
    }
    // Shortest angular distance around the 360° sphere
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
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    GlobalRadioHub? nearest;
    double minDist = 26.0;
    for (final hb in _hitBeacons) {
      final d = (hb.offset - pos).distance;
      if (d < minDist) {
        minDist = d;
        nearest = hb.hub;
      }
    }
    if (nearest != null) {
      HapticFeedback.selectionClick();
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
          _latTiltDeg = (_latTiltDeg + details.delta.dy * 0.45).clamp(-55.0, 55.0);
        });
      },
      onPanEnd: (_) {
        _isDragging = false;
      },
      onTapUp: _handleTapUp,
      child: Center(
        child: SizedBox(
          width: 236,
          height: 236,
          child: AnimatedBuilder(
            animation: Listenable.merge([_spinController, _focusController]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(236, 236),
                    painter: _Globe3DMapPainter(
                      lonOffsetDeg: _lonOffsetDeg,
                      latTiltDeg: _latTiltDeg,
                      pulsePhase: _spinController.value,
                      selectedCode: widget.selectedCountryCode,
                      isPlaying: widget.isPlaying,
                      theme: theme,
                      hitBeaconsOut: _hitBeacons,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.cardBg.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: theme.border, width: 1),
                      ),
                      child: Text(
                        'DRAG 3D GLOBE · TAP BEACON',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: theme.textSecondary,
                        ),
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

class _Globe3DMapPainter extends CustomPainter {
  final double lonOffsetDeg;
  final double latTiltDeg;
  final double pulsePhase;
  final String selectedCode;
  final bool isPlaying;
  final StationeryTheme theme;
  final List<_HitBeacon> hitBeaconsOut;

  _Globe3DMapPainter({
    required this.lonOffsetDeg,
    required this.latTiltDeg,
    required this.pulsePhase,
    required this.selectedCode,
    required this.isPlaying,
    required this.theme,
    required this.hitBeaconsOut,
  });

  // Real simplified geographic world continent polygons: List of [lat, lon] in degrees
  static const List<List<List<double>>> _continents = [
    // North America
    [
      [70, -162], [60, -165], [55, -135], [48, -125], [32, -117], [22, -106],
      [15, -92], [8, -78], [18, -88], [21, -97], [30, -88], [25, -80],
      [35, -75], [44, -64], [52, -56], [62, -74], [70, -95], [72, -135],
    ],
    // Greenland
    [
      [60, -44], [65, -53], [76, -68], [82, -32], [72, -22], [65, -38],
    ],
    // South America
    [
      [11, -74], [10, -62], [2, -50], [-6, -35], [-22, -41], [-38, -58],
      [-55, -68], [-48, -75], [-20, -71], [-5, -81], [4, -77],
    ],
    // Europe
    [
      [36, -9], [43, -9], [48, -4], [51, 2], [58, 6], [68, 16], [70, 28],
      [60, 30], [50, 40], [45, 36], [41, 28], [38, 23], [40, 18], [44, 12],
      [43, 5], [37, -2],
    ],
    // UK / Ireland
    [
      [50, -5], [58, -5], [58, -2], [51, 1],
    ],
    // Africa
    [
      [35, -6], [37, 10], [31, 32], [12, 44], [11, 51], [-2, 41], [-15, 40],
      [-26, 33], [-34, 20], [-22, 14], [-6, 12], [5, 9], [5, -8], [15, -17],
      [27, -13],
    ],
    // Madagascar
    [
      [-12, 49], [-25, 47], [-24, 44], [-15, 47],
    ],
    // Asia + India Peninsula + Southeast Asia
    [
      [68, 32], [72, 70], [74, 110], [66, 170], [55, 160], [42, 132], [35, 128],
      [31, 122], [22, 114], [10, 106], [1, 103], [16, 97], [22, 91],
      [22, 88], [14, 80], [8, 77], [16, 73], [23, 68], // India clearly shaped!
      [25, 62], [26, 56], [13, 44], [28, 35], [36, 36], [41, 29], [46, 40],
      [55, 60],
    ],
    // Japan
    [
      [31, 130], [35, 136], [40, 141], [44, 145], [41, 140], [34, 131],
    ],
    // Australia
    [
      [-12, 130], [-14, 142], [-24, 152], [-37, 150], [-38, 141], [-34, 115],
      [-22, 114],
    ],
  ];

  // Converts geographic (latDeg, lonDeg) to rotated 3D coordinates on sphere of radius R
  // z > 0 means front-facing (visible to camera!)
  _SpherePt _projectLatLon(double latDeg, double lonDeg, double radius, Offset center) {
    const deg2Rad = math.pi / 180.0;
    final lat = latDeg * deg2Rad;
    final lon = (lonDeg + lonOffsetDeg) * deg2Rad;
    final tilt = latTiltDeg * deg2Rad;

    // Unit sphere point
    final x0 = math.cos(lat) * math.sin(lon);
    final y0 = -math.sin(lat);
    final z0 = math.cos(lat) * math.cos(lon);

    // Rotate around X axis by tilt
    final cosT = math.cos(tilt);
    final sinT = math.sin(tilt);
    final y1 = y0 * cosT - z0 * sinT;
    final z1 = y0 * sinT + z0 * cosT;

    return _SpherePt(
      Offset(center.dx + x0 * radius, center.dy + y1 * radius),
      z1,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    hitBeaconsOut.clear();
    final center = Offset(size.width / 2, size.height / 2 - 4);
    final radius = size.width * 0.395;
    final isDark = theme.isDark;
    final accent = theme.primary;

    // 1. Soft Outer Atmospheric Radio Halo
    canvas.drawCircle(
      center,
      radius + 14,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: isPlaying ? 0.24 : 0.12),
            accent.withValues(alpha: 0.0),
          ],
          stops: const [0.68, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 16)),
    );

    // 2. Back Half of Tilted 3D Orbital Radio Signal Ring
    _drawOrbitRing(canvas, center, radius + 13, isFront: false, accent: accent);

    // 3. 3D Ocean Sphere Body with Specular Shading
    final sphereRect = Rect.fromCircle(center: center, radius: radius);
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.40),
        radius: 1.08,
        colors: isDark
            ? [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
                const Color(0xFF090D16),
              ]
            : [
                Color.lerp(Colors.white, accent, 0.14)!,
                Color.lerp(const Color(0xFFE0F2FE), accent, 0.18)!,
                Color.lerp(const Color(0xFFBAE6FD), accent, 0.30)!,
              ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, oceanPaint);

    // Clip all map features cleanly inside the 3D sphere silhouette
    canvas.save();
    canvas.clipPath(Path()..addOval(sphereRect));

    // 4. Subtle 3D Latitude & Longitude Graticule Lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : accent).withValues(alpha: isDark ? 0.09 : 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool started = false;
      for (double lon = -180; lon <= 180; lon += 8) {
        final pt = _projectLatLon(lat, lon, radius, center);
        if (pt.z >= 0) {
          if (!started) {
            path.moveTo(pt.offset.dx, pt.offset.dy);
            started = true;
          } else {
            path.lineTo(pt.offset.dx, pt.offset.dy);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    for (double lon = -180; lon < 180; lon += 30) {
      final path = Path();
      bool started = false;
      for (double lat = -84; lat <= 84; lat += 8) {
        final pt = _projectLatLon(lat, lon, radius, center);
        if (pt.z >= 0) {
          if (!started) {
            path.moveTo(pt.offset.dx, pt.offset.dy);
            started = true;
          } else {
            path.lineTo(pt.offset.dx, pt.offset.dy);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // 5. Real Vector Continents Mapped on 3D Sphere Surface
    final landFill = Paint()
      ..color = isDark
          ? accent.withValues(alpha: 0.34)
          : accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final landStroke = Paint()
      ..color = isDark
          ? accent.withValues(alpha: 0.82)
          : accent.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeJoin = StrokeJoin.round;

    for (final poly in _continents) {
      final path = Path();
      int visiblePts = 0;
      bool started = false;

      // Project each vertex; gently project slightly-behind vertices onto limb so polygons never tear
      final projected = <_SpherePt>[];
      for (final coord in poly) {
        final pt = _projectLatLon(coord[0], coord[1], radius, center);
        if (pt.z > -0.05) visiblePts++;
        projected.add(pt);
      }
      if (visiblePts < 2) continue;

      for (final pt in projected) {
        Offset drawOff = pt.offset;
        if (pt.z < 0) {
          // Clamp smoothly to sphere rim on the horizon
          final v = drawOff - center;
          final d = v.distance;
          if (d > 0.01) {
            drawOff = center + (v / d) * radius;
          }
        }
        if (!started) {
          path.moveTo(drawOff.dx, drawOff.dy);
          started = true;
        } else {
          path.lineTo(drawOff.dx, drawOff.dy);
        }
      }
      path.close();
      canvas.drawPath(path, landFill);
      canvas.drawPath(path, landStroke);
    }

    // 6. Specular 3D Glass Highlight & Edge Shadow inside Sphere
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.34, center.dy - radius * 0.36),
        width: radius * 0.56,
        height: radius * 0.34,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.restore();

    // 7. Crisp Sphere Rim Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accent.withValues(alpha: isDark ? 0.55 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // 8. Front Half of Tilted 3D Orbital Radio Signal Ring
    _drawOrbitRing(canvas, center, radius + 13, isFront: true, accent: accent);

    // 9. Interactive Glowing Country Radio Beacons on Visible Front Hemisphere
    for (final hub in kGlobalRadioHubs) {
      final pt = _projectLatLon(hub.lat, hub.lon, radius, center);
      if (pt.z <= 0.12) continue; // Only show front-side beacons

      hitBeaconsOut.add(_HitBeacon(hub, pt.offset));
      final bool isSelected = hub.code == selectedCode;
      final depthScale = (0.65 + pt.z * 0.45).clamp(0.65, 1.1);

      if (isSelected) {
        final wave = (pulsePhase * 4.0) % 1.0;
        canvas.drawCircle(
          pt.offset,
          (6.0 + wave * 12.0) * depthScale,
          Paint()
            ..color = const Color(0xFFF43F5E).withValues(alpha: (1.0 - wave) * 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        canvas.drawCircle(
          pt.offset,
          5.0 * depthScale,
          Paint()..color = const Color(0xFFF43F5E),
        );
        canvas.drawCircle(
          pt.offset,
          2.1 * depthScale,
          Paint()..color = Colors.white,
        );
      } else {
        canvas.drawCircle(
          pt.offset,
          4.8 * depthScale,
          Paint()..color = accent.withValues(alpha: 0.25),
        );
        canvas.drawCircle(
          pt.offset,
          2.8 * depthScale,
          Paint()..color = isDark ? Colors.white : accent,
        );
      }
    }
  }

  void _drawOrbitRing(
    Canvas canvas,
    Offset center,
    double r, {
    required bool isFront,
    required Color accent,
  }) {
    const segs = 60;
    const tiltX = 1.18;
    const tiltZ = -0.34;
    final path = Path();
    bool started = false;

    for (int i = 0; i <= segs; i++) {
      final th = (i / segs) * math.pi * 2.0;
      final x0 = r * math.cos(th);
      final y0 = r * math.sin(th);
      // Rotate around X
      final y1 = y0 * math.cos(tiltX);
      final z1 = y0 * math.sin(tiltX);
      // Rotate around Z
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
        ..color = accent.withValues(alpha: isFront ? 0.42 : 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isFront ? 1.5 : 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _Globe3DMapPainter old) => true;
}

class _SpherePt {
  final Offset offset;
  final double z;
  const _SpherePt(this.offset, this.z);
}
