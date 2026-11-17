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
  GlobalRadioHub(code: 'US', name: 'USA', city: 'New York', lat: 40.7, lon: -74.0),
  GlobalRadioHub(code: 'GB', name: 'UK', city: 'London', lat: 51.5, lon: -0.1),
  GlobalRadioHub(code: 'JP', name: 'Japan', city: 'Tokyo', lat: 35.7, lon: 139.7),
  GlobalRadioHub(code: 'FR', name: 'France', city: 'Paris', lat: 48.8, lon: 2.3),
  GlobalRadioHub(code: 'DE', name: 'Germany', city: 'Berlin', lat: 52.5, lon: 13.4),
  GlobalRadioHub(code: 'AE', name: 'UAE', city: 'Dubai', lat: 25.2, lon: 55.3),
  GlobalRadioHub(code: 'BR', name: 'Brazil', city: 'Rio', lat: -22.9, lon: -43.2),
  GlobalRadioHub(code: 'AU', name: 'Australia', city: 'Sydney', lat: -33.9, lon: 151.2),
  GlobalRadioHub(code: 'KR', name: 'S. Korea', city: 'Seoul', lat: 37.6, lon: 127.0),
  GlobalRadioHub(code: 'CA', name: 'Canada', city: 'Toronto', lat: 43.6, lon: -79.4),
  GlobalRadioHub(code: 'IT', name: 'Italy', city: 'Rome', lat: 41.9, lon: 12.5),
];

/// Interactive Rotating 3D Globe with Horizon-Clipped Real Vector World Map,
/// Orbiting Radio Satellite Ring & Clickable Country Beacons.
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

  double _lonOffsetDeg = -79.1; // Faces India on initial open
  double _latTiltDeg = 20.0;
  bool _isDragging = false;
  DateTime _pauseSpinUntil = DateTime.fromMillisecondsSinceEpoch(0);

  double _focusFromLon = -79.1;
  double _focusToLon = -79.1;
  double _focusFromLat = 20.0;
  double _focusToLat = 20.0;
  double _lastTickVal = 0.0;

  final List<_HitBeacon> _hitBeacons = [];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
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
      duration: const Duration(milliseconds: 640),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(_focusController.value);
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
    _pauseSpinUntil = DateTime.now().add(const Duration(milliseconds: 2600));
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
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    GlobalRadioHub? nearest;
    double minDist = 30.0;
    for (final hb in _hitBeacons) {
      final d = (hb.offset - pos).distance;
      if (d < minDist) {
        minDist = d;
        nearest = hb.hub;
      }
    }
    if (nearest != null) {
      HapticFeedback.selectionClick();
      _pauseSpinUntil = DateTime.now().add(const Duration(seconds: 3));
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
          _lonOffsetDeg = (_lonOffsetDeg + details.delta.dx * 0.52) % 360.0;
          _latTiltDeg = (_latTiltDeg + details.delta.dy * 0.42).clamp(-55.0, 55.0);
        });
      },
      onPanEnd: (_) {
        _isDragging = false;
        _pauseSpinUntil = DateTime.now().add(const Duration(milliseconds: 1600));
      },
      onTapUp: _handleTapUp,
      child: Center(
        child: SizedBox(
          width: 244,
          height: 244,
          child: AnimatedBuilder(
            animation: Listenable.merge([_spinController, _focusController]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(244, 244),
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
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: theme.cardBg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: theme.border, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, size: 11, color: theme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'SPIN 3D GLOBE · TAP COUNTRY',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
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

  // Detailed simplified geographic continent polygons ([lat, lon] in degrees)
  static const List<List<List<double>>> _rawContinents = [
    // North America
    [
      [70, -162], [62, -166], [56, -158], [59, -140], [50, -126], [38, -123],
      [32, -117], [23, -110], [18, -103], [14, -92], [9, -82], [9, -78],
      [16, -86], [21, -87], [20, -96], [26, -97], [30, -88], [25, -80],
      [33, -78], [41, -70], [46, -61], [52, -56], [60, -65], [64, -80],
      [70, -96], [71, -135],
    ],
    // Greenland
    [
      [60, -44], [65, -53], [76, -68], [82, -32], [72, -22], [65, -38],
    ],
    // South America
    [
      [11, -75], [10, -62], [3, -51], [-5, -35], [-16, -39], [-24, -44],
      [-35, -55], [-46, -66], [-55, -68], [-48, -75], [-33, -72], [-18, -71],
      [-5, -81], [4, -77],
    ],
    // Europe
    [
      [36, -9], [43, -9], [48, -4], [51, 2], [55, 8], [60, 5], [69, 18],
      [70, 29], [64, 30], [60, 29], [54, 24], [50, 38], [46, 36], [41, 28],
      [37, 23], [41, 18], [44, 13], [43, 5], [37, -2],
    ],
    // UK & Ireland
    [
      [50, -5], [55, -6], [58, -5], [57, -2], [51, 1],
    ],
    // Africa
    [
      [35, -6], [37, 10], [31, 32], [22, 37], [12, 44], [11, 51], [2, 45],
      [-4, 40], [-15, 40], [-26, 33], [-34, 20], [-28, 16], [-18, 12],
      [-5, 11], [4, 9], [5, -7], [14, -17], [26, -14],
    ],
    // Madagascar
    [
      [-12, 49], [-25, 47], [-24, 44], [-15, 46],
    ],
    // Asia + India Peninsula + Southeast Asia
    [
      [68, 34], [72, 72], [74, 108], [68, 166], [58, 161], [50, 141],
      [40, 129], [34, 127], [31, 122], [22, 114], [12, 109], [2, 103],
      [10, 99], [16, 97], [22, 91], [22, 88], [15, 80], [8, 77], [15, 73],
      [23, 68], [25, 62], [26, 56], [13, 44], [28, 35], [36, 36], [41, 29],
      [46, 40], [54, 52],
    ],
    // Japan
    [
      [31, 130], [35, 136], [40, 141], [44, 145], [41, 140], [34, 131],
    ],
    // Indonesia (Sumatra + Java)
    [
      [5, 95], [-6, 106], [-8, 115], [-6, 113], [-4, 104], [4, 98],
    ],
    // Australia
    [
      [-12, 131], [-14, 143], [-24, 153], [-37, 150], [-38, 141], [-34, 115],
      [-22, 114], [-15, 124],
    ],
    // New Zealand
    [
      [-35, 173], [-41, 175], [-46, 168], [-44, 167], [-38, 174],
    ],
  ];

  // Pre-subdivided polygons (max ~6° per edge) so spherical curves & horizon clipping stay razor-sharp
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
        final steps = math.max(1, (dist / 6.0).ceil());
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
    final radius = size.width * 0.39;
    final isDark = theme.isDark;
    final accent = theme.primary;

    // 1. Ambient Radio Atmosphere Halo
    canvas.drawCircle(
      center,
      radius + 16,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: isPlaying ? 0.25 : 0.12),
            accent.withValues(alpha: 0.0),
          ],
          stops: const [0.64, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 16)),
    );

    // 2. Back Half of Tilted 3D Orbital Radio Signal Ring
    _drawOrbitRing(canvas, center, radius + 14, isFront: false, accent: accent);

    // 3. 3D Ocean Sphere with Soft Depth Shading
    final sphereRect = Rect.fromCircle(center: center, radius: radius);
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.36, -0.38),
        radius: 1.08,
        colors: isDark
            ? [
                const Color(0xFF202E44),
                const Color(0xFF10192A),
                const Color(0xFF080D17),
              ]
            : [
                Color.lerp(Colors.white, accent, 0.10)!,
                Color.lerp(const Color(0xFFE0F2FE), accent, 0.15)!,
                Color.lerp(const Color(0xFFBAE6FD), accent, 0.28)!,
              ],
        stops: const [0.0, 0.56, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, oceanPaint);

    // Clip interior map cleanly inside the sphere silhouette
    canvas.save();
    canvas.clipPath(Path()..addOval(sphereRect));

    // 4. Crisp 3D Lat/Lon Graticule Grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : accent).withValues(alpha: isDark ? 0.085 : 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    for (double lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool started = false;
      for (double lon = -180; lon <= 180; lon += 6) {
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
      canvas.drawPath(path, gridPaint);
    }

    for (double lon = -180; lon < 180; lon += 30) {
      final path = Path();
      bool started = false;
      for (double lat = -84; lat <= 84; lat += 6) {
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
      canvas.drawPath(path, gridPaint);
    }

    // 5. Proper Horizon-Clipped 3D Vector Continents (Zero Tearing!)
    final landFill = Paint()
      ..color = isDark
          ? accent.withValues(alpha: 0.36)
          : accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final landStroke = Paint()
      ..color = isDark
          ? accent.withValues(alpha: 0.85)
          : accent.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
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

    // 6. Specular 3D Glass Highlight + Soft Limb Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.33, center.dy - radius * 0.35),
        width: radius * 0.52,
        height: radius * 0.30,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.30)
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
        ..strokeWidth = 1.5,
    );

    // 8. Front Half of Tilted 3D Orbital Radio Signal Ring + Orbiting Satellite Pulse
    _drawOrbitRing(canvas, center, radius + 14, isFront: true, accent: accent);

    // 9. Interactive Glowing Country Radio Beacons + Selected Floating Label
    Offset? selectedLabelPos;
    GlobalRadioHub? selectedHubVisible;

    for (final hub in kGlobalRadioHubs) {
      final v = _rotateUnit(hub.lat, hub.lon);
      if (v.z <= 0.10) continue; // Front hemisphere only

      final off = Offset(center.dx + v.x * radius, center.dy + v.y * radius);
      hitBeaconsOut.add(_HitBeacon(hub, off));
      final bool isSelected = hub.code == selectedCode;
      final depthScale = (0.68 + v.z * 0.42).clamp(0.68, 1.12);

      if (isSelected) {
        selectedLabelPos = off;
        selectedHubVisible = hub;
        final wave = (pulsePhase * 5.0) % 1.0;
        canvas.drawCircle(
          off,
          (6.0 + wave * 13.0) * depthScale,
          Paint()
            ..color = const Color(0xFFF43F5E).withValues(alpha: (1.0 - wave) * 0.72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        canvas.drawCircle(
          off,
          5.2 * depthScale,
          Paint()..color = const Color(0xFFF43F5E),
        );
        canvas.drawCircle(
          off,
          2.2 * depthScale,
          Paint()..color = Colors.white,
        );
      } else {
        canvas.drawCircle(
          off,
          5.0 * depthScale,
          Paint()..color = accent.withValues(alpha: 0.25),
        );
        canvas.drawCircle(
          off,
          2.7 * depthScale,
          Paint()..color = isDark ? Colors.white : accent,
        );
      }
    }

    // Draw clean floating tag for selected country beacon
    if (selectedLabelPos != null && selectedHubVisible != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${selectedHubVisible.code} · ${selectedHubVisible.name}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.0,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final boxW = tp.width + 12;
      final boxH = tp.height + 6;
      final bx = (selectedLabelPos.dx - boxW / 2).clamp(6.0, size.width - boxW - 6.0);
      final by = (selectedLabelPos.dy - boxH - 10).clamp(6.0, size.height - boxH - 24.0);
      final tagRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, boxW, boxH),
        const Radius.circular(7),
      );
      canvas.drawRRect(
        tagRect,
        Paint()..color = const Color(0xFFF43F5E).withValues(alpha: 0.94),
      );
      tp.paint(canvas, Offset(bx + 6, by + 3));
    }
  }

  /// Clips a 3D unit-sphere polygon cleanly against the z = 0 horizon plane,
  /// tracing the circular limb arc smoothly whenever an edge exits & re-enters!
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

    // Insert smooth rim arc segments between consecutive horizon points (z == 0)
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
    const tiltX = 1.18;
    const tiltZ = -0.32;
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
        ..color = accent.withValues(alpha: isFront ? 0.45 : 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isFront ? 1.5 : 1.0,
    );

    // Orbiting live radio signal pulse satellite on the 3D ring
    final satAngle = pulsePhase * math.pi * 2.0 * 3.0;
    final sx0 = r * math.cos(satAngle);
    final sy0 = r * math.sin(satAngle);
    final sy1 = sy0 * math.cos(tiltX);
    final sz1 = sy0 * math.sin(tiltX);
    final satVisible = isFront ? (sz1 >= 0) : (sz1 < 0);
    if (satVisible) {
      final sx2 = sx0 * math.cos(tiltZ) - sy1 * math.sin(tiltZ);
      final sy2 = sx0 * math.sin(tiltZ) + sy1 * math.cos(tiltZ);
      final satPt = Offset(center.dx + sx2, center.dy + sy2);
      canvas.drawCircle(
        satPt,
        5.5,
        Paint()..color = accent.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        satPt,
        2.7,
        Paint()..color = isPlaying ? const Color(0xFFF43F5E) : accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Globe3DMapPainter old) => true;
}
