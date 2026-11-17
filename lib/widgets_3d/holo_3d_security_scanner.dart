import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';

enum HoloScannerMode {
  idle,
  scanning,
  clean,
  warning,
  threat,
}

/// Interactive True-3D Holographic Security Scanner & Volumetric Wave Engine.
/// Uses real 3D perspective projection, Euler rotation matrices, depth-sorted
/// geodesic polyhedron + gyroscopic orbital rings + sweeping 3D laser plane +
/// multi-harmonic 3D ripple waves + 3D orbiting particle field.
class Holo3DSecurityScanner extends StatefulWidget {
  final HoloScannerMode mode;
  final double progress; // 0.0 .. 1.0
  final int? securityScore;
  final String statusSubtitle;
  final StationeryTheme theme;
  final VoidCallback? onTap;

  const Holo3DSecurityScanner({
    super.key,
    required this.mode,
    required this.progress,
    required this.securityScore,
    required this.statusSubtitle,
    required this.theme,
    this.onTap,
  });

  @override
  State<Holo3DSecurityScanner> createState() => _Holo3DSecurityScannerState();
}

class _Holo3DSecurityScannerState extends State<Holo3DSecurityScanner>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _waveController;
  late final AnimationController _laserController;
  late final AnimationController _springController;

  double _userTiltX = 0.0;
  double _userTiltY = 0.0;
  double _releaseStartX = 0.0;
  double _releaseStartY = 0.0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        final t = Curves.elasticOut.transform(_springController.value);
        setState(() {
          _userTiltX = _releaseStartX * (1.0 - t);
          _userTiltY = _releaseStartY * (1.0 - t);
        });
      });
  }

  @override
  void didUpdateWidget(covariant Holo3DSecurityScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      final isScan = widget.mode == HoloScannerMode.scanning;
      _spinController.duration = Duration(milliseconds: isScan ? 4200 : 12000);
      _spinController.repeat();
      _waveController.duration = Duration(milliseconds: isScan ? 1850 : 3400);
      _waveController.repeat();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _waveController.dispose();
    _laserController.dispose();
    _springController.dispose();
    super.dispose();
  }

  Color _accentForMode() {
    switch (widget.mode) {
      case HoloScannerMode.scanning:
        return const Color(0xFF06B6D4); // Luminous Cyan
      case HoloScannerMode.clean:
        return const Color(0xFF10B981); // Emerald
      case HoloScannerMode.warning:
        return const Color(0xFFF59E0B); // Amber
      case HoloScannerMode.threat:
        return const Color(0xFFF43F5E); // Crimson
      case HoloScannerMode.idle:
        return widget.theme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForMode();
    final isScanning = widget.mode == HoloScannerMode.scanning;

    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: (_) {
        _springController.stop();
      },
      onPanUpdate: (details) {
        setState(() {
          _userTiltY = (_userTiltY + details.delta.dx * 0.011).clamp(-0.85, 0.85);
          _userTiltX = (_userTiltX - details.delta.dy * 0.011).clamp(-0.65, 0.65);
        });
      },
      onPanEnd: (_) {
        _releaseStartX = _userTiltX;
        _releaseStartY = _userTiltY;
        _springController.forward(from: 0.0);
      },
      child: Center(
        child: SizedBox(
          width: 296,
          height: 296,
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_spinController, _waveController, _laserController]),
            builder: (context, child) {
              return CustomPaint(
                painter: _Holo3DScannerPainter(
                  spinT: _spinController.value,
                  waveT: _waveController.value,
                  laserT: _laserController.value,
                  tiltX: _userTiltX,
                  tiltY: _userTiltY,
                  mode: widget.mode,
                  progress: widget.progress,
                  primaryAccent: accent,
                  theme: widget.theme,
                ),
                child: child,
              );
            },
            child: Center(
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.theme.cardBg.withValues(alpha: widget.theme.isDark ? 0.78 : 0.86),
                      widget.theme.cardBg.withValues(alpha: widget.theme.isDark ? 0.36 : 0.45),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.68, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isScanning) ...[
                      Text(
                        '${(widget.progress * 100).clamp(0, 100).toInt()}%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          color: widget.theme.text,
                          shadows: [
                            Shadow(
                              color: accent.withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.statusSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: accent,
                        ),
                      ),
                    ] else if (widget.securityScore != null) ...[
                      Text(
                        '${widget.securityScore}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -1.5,
                          color: accent,
                          shadows: [
                            Shadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.statusSubtitle,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: widget.theme.text,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.shield_outlined,
                        size: 34,
                        color: accent,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TAP 3D CORE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: widget.theme.text,
                        ),
                      ),
                      Text(
                        'DRAG TO TILT',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.9,
                          color: widget.theme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Vec3 {
  final double x;
  final double y;
  final double z;
  const _Vec3(this.x, this.y, this.z);

  _Vec3 rotX(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _Vec3(x, y * c - z * s, y * s + z * c);
  }

  _Vec3 rotY(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _Vec3(x * c + z * s, y, -x * s + z * c);
  }

  _Vec3 rotZ(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _Vec3(x * c - y * s, x * s + y * c, z);
  }
}

class _ProjPoint {
  final Offset offset;
  final double z;
  final double scale;
  const _ProjPoint(this.offset, this.z, this.scale);
}

class _Face3D {
  final int a, b, c;
  const _Face3D(this.a, this.b, this.c);
}

class _Holo3DScannerPainter extends CustomPainter {
  final double spinT;
  final double waveT;
  final double laserT;
  final double tiltX;
  final double tiltY;
  final HoloScannerMode mode;
  final double progress;
  final Color primaryAccent;
  final StationeryTheme theme;

  // Golden ratio icosahedron geometry (12 vertices, 20 faces, 30 unique edges)
  static final List<_Vec3> _icoVerts = _buildIcoVerts();
  static final List<List<int>> _icoEdges = _buildIcoEdges();
  static final List<_Face3D> _icoFaces = _buildIcoFaces();
  static final List<_ParticleSeed> _particles = _buildParticles();

  _Holo3DScannerPainter({
    required this.spinT,
    required this.waveT,
    required this.laserT,
    required this.tiltX,
    required this.tiltY,
    required this.mode,
    required this.progress,
    required this.primaryAccent,
    required this.theme,
  });

  static List<_Vec3> _buildIcoVerts() {
    final phi = (1.0 + math.sqrt(5.0)) / 2.0;
    final raw = [
      _Vec3(-1, phi, 0),
      _Vec3(1, phi, 0),
      _Vec3(-1, -phi, 0),
      _Vec3(1, -phi, 0),
      _Vec3(0, -1, phi),
      _Vec3(0, 1, phi),
      _Vec3(0, -1, -phi),
      _Vec3(0, 1, -phi),
      _Vec3(phi, 0, -1),
      _Vec3(phi, 0, 1),
      _Vec3(-phi, 0, -1),
      _Vec3(-phi, 0, 1),
    ];
    return raw.map((v) {
      final len = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
      return _Vec3(v.x / len, v.y / len, v.z / len);
    }).toList();
  }

  static List<_Face3D> _buildIcoFaces() => const [
        _Face3D(0, 11, 5),
        _Face3D(0, 5, 1),
        _Face3D(0, 1, 7),
        _Face3D(0, 7, 10),
        _Face3D(0, 10, 11),
        _Face3D(1, 5, 9),
        _Face3D(5, 11, 4),
        _Face3D(11, 10, 2),
        _Face3D(10, 7, 6),
        _Face3D(7, 1, 8),
        _Face3D(3, 9, 4),
        _Face3D(3, 4, 2),
        _Face3D(3, 2, 6),
        _Face3D(3, 6, 8),
        _Face3D(3, 8, 9),
        _Face3D(4, 9, 5),
        _Face3D(2, 4, 11),
        _Face3D(6, 2, 10),
        _Face3D(8, 6, 7),
        _Face3D(9, 8, 1),
      ];

  static List<List<int>> _buildIcoEdges() {
    final seen = <String>{};
    final edges = <List<int>>[];
    for (final f in _buildIcoFaces()) {
      for (final pair in [
        [f.a, f.b],
        [f.b, f.c],
        [f.c, f.a]
      ]) {
        final lo = math.min(pair[0], pair[1]);
        final hi = math.max(pair[0], pair[1]);
        final key = '$lo-$hi';
        if (seen.add(key)) edges.add([lo, hi]);
      }
    }
    return edges;
  }

  static List<_ParticleSeed> _buildParticles() {
    final list = <_ParticleSeed>[];
    final rng = math.Random(2026);
    for (int i = 0; i < 46; i++) {
      list.add(_ParticleSeed(
        theta0: rng.nextDouble() * math.pi * 2,
        phi0: (rng.nextDouble() - 0.5) * math.pi * 0.85,
        radius: 68.0 + rng.nextDouble() * 62.0,
        speed: (rng.nextBool() ? 1.0 : -1.0) * (0.45 + rng.nextDouble() * 1.15),
        size: 1.2 + rng.nextDouble() * 2.1,
        colorIdx: i % 5,
      ));
    }
    return list;
  }

  _ProjPoint _project(_Vec3 p, Offset center) {
    const focal = 340.0;
    final denom = (focal + p.z).clamp(80.0, 900.0);
    final scale = focal / denom;
    return _ProjPoint(
      Offset(center.dx + p.x * scale, center.dy + p.y * scale),
      p.z,
      scale,
    );
  }

  List<Color> _palette() {
    switch (mode) {
      case HoloScannerMode.clean:
        return const [
          Color(0xFF10B981),
          Color(0xFF34D399),
          Color(0xFF06B6D4),
          Color(0xFF2DD4BF),
          Color(0xFF0EA5E9),
        ];
      case HoloScannerMode.threat:
        return const [
          Color(0xFFF43F5E),
          Color(0xFFFB7185),
          Color(0xFFF59E0B),
          Color(0xFFEC4899),
          Color(0xFFA855F7),
        ];
      case HoloScannerMode.warning:
        return const [
          Color(0xFFF59E0B),
          Color(0xFFFBBF24),
          Color(0xFFFB7185),
          Color(0xFF0EA5E9),
          Color(0xFFA855F7),
        ];
      case HoloScannerMode.scanning:
      case HoloScannerMode.idle:
        return const [
          Color(0xFF06B6D4), // Quantum Cyan
          Color(0xFFA855F7), // Lilac Violet
          Color(0xFF0EA5E9), // Sky Neon
          Color(0xFF10B981), // Mint Emerald
          Color(0xFFFB7185), // Rose Pulse
        ];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final isScanning = mode == HoloScannerMode.scanning;
    final colors = _palette();
    const twoPi = math.pi * 2.0;

    final rotY = spinT * twoPi + tiltY;
    final rotX = math.sin(spinT * twoPi) * 0.34 + 0.28 + tiltX;
    final rotZ = math.cos(spinT * twoPi * 0.5) * 0.16;

    // -------------------------------------------------------------------------
    // 1. AMBIENT VOLUMETRIC HOLOGRAM BACKGLOW
    // -------------------------------------------------------------------------
    final ambientRadius = isScanning ? 132.0 : 112.0;
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryAccent.withValues(alpha: isScanning ? 0.24 : 0.13),
          colors[1].withValues(alpha: isScanning ? 0.11 : 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: ambientRadius));
    canvas.drawCircle(center, ambientRadius, ambientPaint);

    // -------------------------------------------------------------------------
    // 2. UPGRADED 3D PERSPECTIVE HARMONIC ENERGY WAVES (TILTED 3D TOROIDAL RIPPLES)
    // -------------------------------------------------------------------------
    final waveCount = isScanning ? 6 : 4;
    final baseWaveTiltX = 1.06 + tiltX * 0.65;
    final baseWaveTiltY = math.sin(spinT * twoPi) * 0.26 + tiltY * 0.65;

    for (int i = 0; i < waveCount; i++) {
      final phase = (waveT + i / waveCount) % 1.0;
      final waveRadius = 56.0 + phase * 86.0;
      final fade = math.sin(phase * math.pi).clamp(0.0, 1.0);
      final alpha = fade * (isScanning ? 0.72 : 0.36);
      final color = colors[i % colors.length];

      // Alternate orthogonal 3D wave inclination slightly for rich spatial depth
      final planeTiltX = baseWaveTiltX + (i.isEven ? 0.18 : -0.22);
      final planeTiltZ = (i * 0.42) + spinT * (i.isEven ? 0.5 : -0.4);

      final wavePath = Path();
      const segs = 64;
      for (int s = 0; s <= segs; s++) {
        final theta = (s / segs) * twoPi;
        // Multi-harmonic 3D wave undulation in both radius & vertical Z-crest
        final harmonic1 = math.sin(theta * 5.0 + waveT * twoPi * 2.0 + i);
        final harmonic2 = math.cos(theta * 3.0 - waveT * twoPi + i * 1.4);
        final amp = isScanning ? 5.2 : 2.6;
        final r = waveRadius + harmonic1 * amp * 0.55;
        final zRipple = (harmonic1 * 0.6 + harmonic2 * 0.4) * (amp * 2.1);

        final p3 = _Vec3(r * math.cos(theta), r * math.sin(theta), zRipple)
            .rotX(planeTiltX)
            .rotY(baseWaveTiltY)
            .rotZ(planeTiltZ);
        final proj = _project(p3, center);

        if (s == 0) {
          wavePath.moveTo(proj.offset.dx, proj.offset.dy);
        } else {
          wavePath.lineTo(proj.offset.dx, proj.offset.dy);
        }
      }
      wavePath.close();

      // Soft outer bloom glow stroke
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isScanning ? 5.2 : 3.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(wavePath, glowPaint);

      // Crisp inner filament stroke
      final filamentPaint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isScanning ? 1.75 : 1.2;
      canvas.drawPath(wavePath, filamentPaint);
    }

    // -------------------------------------------------------------------------
    // 3. BACK-HEMISPHERE 3D ORBITING PARTICLES (z > 0 is farther from camera)
    // -------------------------------------------------------------------------
    final projectedParticles = <_ProjectedParticle>[];
    for (final pt in _particles) {
      final tAngle = pt.theta0 + spinT * twoPi * pt.speed;
      final pAngle = pt.phi0 + math.sin(spinT * twoPi + pt.theta0) * 0.22;
      final pulseR = pt.radius + (isScanning ? math.sin(waveT * twoPi + pt.theta0) * 8.0 : 0.0);

      final x = pulseR * math.cos(pAngle) * math.cos(tAngle);
      final y = pulseR * math.sin(pAngle);
      final z = pulseR * math.cos(pAngle) * math.sin(tAngle);
      final v = _Vec3(x, y, z).rotX(tiltX).rotY(tiltY);
      final proj = _project(v, center);

      // Trail point slightly behind along trajectory for scanning warp effect
      final tPrev = tAngle - (isScanning ? 0.14 * pt.speed : 0.04 * pt.speed);
      final vPrev = _Vec3(
        pulseR * math.cos(pAngle) * math.cos(tPrev),
        pulseR * math.sin(pAngle),
        pulseR * math.cos(pAngle) * math.sin(tPrev),
      ).rotX(tiltX).rotY(tiltY);
      final projPrev = _project(vPrev, center);

      projectedParticles.add(_ProjectedParticle(
        pos: proj.offset,
        prevPos: projPrev.offset,
        z: proj.z,
        scale: proj.scale,
        size: pt.size,
        color: colors[pt.colorIdx % colors.length],
      ));
    }

    // Draw far particles (behind core)
    for (final pp in projectedParticles) {
      if (pp.z > 0) _drawParticle(canvas, pp, isScanning, isBack: true);
    }

    // -------------------------------------------------------------------------
    // 4. TRIPLE-AXIS 3D GYROSCOPIC ORBITAL RINGS (BACK + FRONT PERSPECTIVE)
    // -------------------------------------------------------------------------
    _drawGyroRing(
      canvas,
      center,
      radius: 92.0,
      rx: 1.15 + tiltX,
      ry: rotY * 0.75,
      rz: 0.35 + spinT * twoPi,
      color: colors[0],
      strokeWidth: isScanning ? 2.0 : 1.35,
      dashed: false,
      satellites: 2,
    );
    _drawGyroRing(
      canvas,
      center,
      radius: 104.0,
      rx: -0.95 + tiltX,
      ry: -rotY * 0.9,
      rz: -0.75 - spinT * twoPi * 0.7,
      color: colors[1],
      strokeWidth: isScanning ? 1.8 : 1.15,
      dashed: true,
      satellites: 3,
    );
    _drawGyroRing(
      canvas,
      center,
      radius: 80.0,
      rx: 0.52 + math.cos(spinT * twoPi) * 0.4 + tiltX,
      ry: rotY * 1.25,
      rz: 1.1,
      color: colors[2],
      strokeWidth: isScanning ? 1.6 : 1.0,
      dashed: false,
      satellites: 1,
    );

    // -------------------------------------------------------------------------
    // 5. TRUE 3D GEODESIC HOLOGRAPHIC SHIELD CORE (DEPTH-SORTED FACETS + WIREFRAME)
    // -------------------------------------------------------------------------
    final coreRadius = isScanning ? 66.0 : 62.0;
    final transformedVerts = <_Vec3>[];
    final projectedVerts = <_ProjPoint>[];

    for (final v in _icoVerts) {
      final breath = 1.0 + math.sin(waveT * twoPi) * (isScanning ? 0.045 : 0.02);
      final tv = _Vec3(v.x * coreRadius * breath, v.y * coreRadius * breath, v.z * coreRadius * breath)
          .rotX(rotX)
          .rotY(rotY)
          .rotZ(rotZ);
      transformedVerts.add(tv);
      projectedVerts.add(_project(tv, center));
    }

    // Sort triangular faces back-to-front (largest z first)
    final sortedFaces = List<_Face3D>.from(_icoFaces)
      ..sort((f1, f2) {
        final z1 = (transformedVerts[f1.a].z + transformedVerts[f1.b].z + transformedVerts[f1.c].z) / 3.0;
        final z2 = (transformedVerts[f2.a].z + transformedVerts[f2.b].z + transformedVerts[f2.c].z) / 3.0;
        return z2.compareTo(z1);
      });

    final laserY = (laserT * 2.0 - 1.0) * coreRadius * 0.96;

    // Paint subtle holographic crystal faces
    for (final face in sortedFaces) {
      final pa = projectedVerts[face.a];
      final pb = projectedVerts[face.b];
      final pc = projectedVerts[face.c];
      final avgZ = (pa.z + pb.z + pc.z) / 3.0;
      final avgY = (transformedVerts[face.a].y + transformedVerts[face.b].y + transformedVerts[face.c].y) / 3.0;

      // Facing factor: front faces (-z) brighter, back faces (+z) very subtle
      final depthNorm = ((coreRadius - avgZ) / (coreRadius * 2.0)).clamp(0.0, 1.0);
      final laserBoost = isScanning ? (1.0 - (avgY - laserY).abs() / 28.0).clamp(0.0, 1.0) : 0.0;

      final facePath = Path()
        ..moveTo(pa.offset.dx, pa.offset.dy)
        ..lineTo(pb.offset.dx, pb.offset.dy)
        ..lineTo(pc.offset.dx, pc.offset.dy)
        ..close();

      final fillAlpha = (0.02 + depthNorm * 0.08 + laserBoost * 0.16).clamp(0.0, 0.35);
      final facePaint = Paint()
        ..color = primaryAccent.withValues(alpha: fillAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawPath(facePath, facePaint);
    }

    // Paint 3D geodesic wireframe edges with depth cueing
    for (final edge in _icoEdges) {
      final p1 = projectedVerts[edge[0]];
      final p2 = projectedVerts[edge[1]];
      final avgZ = (p1.z + p2.z) * 0.5;
      final avgY = (transformedVerts[edge[0]].y + transformedVerts[edge[1]].y) * 0.5;
      final depthNorm = ((coreRadius - avgZ) / (coreRadius * 2.0)).clamp(0.0, 1.0);
      final laserBoost = isScanning ? (1.0 - (avgY - laserY).abs() / 22.0).clamp(0.0, 1.0) : 0.0;

      final edgeAlpha = (0.14 + depthNorm * 0.55 + laserBoost * 0.31).clamp(0.0, 1.0);
      final edgeColor = laserBoost > 0.35
          ? Color.lerp(primaryAccent, Colors.white, laserBoost * 0.65)!
          : primaryAccent;

      final edgePaint = Paint()
        ..color = edgeColor.withValues(alpha: edgeAlpha)
        ..strokeWidth = 0.8 + depthNorm * 1.15 + laserBoost * 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1.offset, p2.offset, edgePaint);
    }

    // Paint glowing 3D geodesic vertices
    for (int i = 0; i < projectedVerts.length; i++) {
      final pv = projectedVerts[i];
      final tv = transformedVerts[i];
      final depthNorm = ((coreRadius - pv.z) / (coreRadius * 2.0)).clamp(0.0, 1.0);
      final laserBoost = isScanning ? (1.0 - (tv.y - laserY).abs() / 18.0).clamp(0.0, 1.0) : 0.0;
      final nodeR = (1.6 + depthNorm * 2.2 + laserBoost * 1.6) * pv.scale;

      if (depthNorm > 0.45 || laserBoost > 0.3) {
        canvas.drawCircle(
          pv.offset,
          nodeR * 2.2,
          Paint()
            ..color = primaryAccent.withValues(alpha: (0.18 + laserBoost * 0.35))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
        );
      }
      canvas.drawCircle(
        pv.offset,
        nodeR,
        Paint()
          ..color = Color.lerp(primaryAccent, Colors.white, 0.35 + laserBoost * 0.5)!
              .withValues(alpha: 0.35 + depthNorm * 0.65),
      );
    }

    // -------------------------------------------------------------------------
    // 6. VOLUMETRIC 3D HORIZONTAL LASER SCAN PLANE (ACTIVE SCAN MAGIC)
    // -------------------------------------------------------------------------
    if (isScanning) {
      final sliceR = math.sqrt((coreRadius * coreRadius - laserY * laserY).clamp(0.0, coreRadius * coreRadius)) + 14.0;
      final laserPath = Path();
      const lSegs = 48;
      for (int s = 0; s <= lSegs; s++) {
        final th = (s / lSegs) * twoPi;
        final v = _Vec3(sliceR * math.cos(th), laserY, sliceR * math.sin(th))
            .rotX(tiltX + 0.16)
            .rotY(tiltY);
        final proj = _project(v, center);
        if (s == 0) {
          laserPath.moveTo(proj.offset.dx, proj.offset.dy);
        } else {
          laserPath.lineTo(proj.offset.dx, proj.offset.dy);
        }
      }
      laserPath.close();

      // Volumetric laser plane fill
      canvas.drawPath(
        laserPath,
        Paint()
          ..color = primaryAccent.withValues(alpha: 0.14)
          ..style = PaintingStyle.fill,
      );
      // Outer neon laser glow
      canvas.drawPath(
        laserPath,
        Paint()
          ..color = primaryAccent.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
      );
      // Razor-sharp core laser line
      canvas.drawPath(
        laserPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // -------------------------------------------------------------------------
    // 7. FRONT-HEMISPHERE 3D PARTICLES (z <= 0, floating in front of hologram)
    // -------------------------------------------------------------------------
    for (final pp in projectedParticles) {
      if (pp.z <= 0) _drawParticle(canvas, pp, isScanning, isBack: false);
    }
  }

  void _drawGyroRing(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double rx,
    required double ry,
    required double rz,
    required Color color,
    required double strokeWidth,
    required bool dashed,
    required int satellites,
  }) {
    const segs = 64;
    const twoPi = math.pi * 2.0;

    for (int s = 0; s < segs; s++) {
      if (dashed && s % 2 == 1) continue;
      final t1 = (s / segs) * twoPi;
      final t2 = ((s + 1) / segs) * twoPi;

      final v1 = _Vec3(radius * math.cos(t1), radius * math.sin(t1), 0)
          .rotX(rx)
          .rotY(ry)
          .rotZ(rz);
      final v2 = _Vec3(radius * math.cos(t2), radius * math.sin(t2), 0)
          .rotX(rx)
          .rotY(ry)
          .rotZ(rz);

      final p1 = _project(v1, center);
      final p2 = _project(v2, center);
      final avgZ = (p1.z + p2.z) * 0.5;
      final depthNorm = ((radius - avgZ) / (radius * 2.0)).clamp(0.0, 1.0);

      final alpha = (0.12 + depthNorm * 0.62).clamp(0.0, 0.85);
      final p = Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = strokeWidth * (0.65 + depthNorm * 0.55)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1.offset, p2.offset, p);
    }

    // Orbiting 3D glowing micro-satellites on the ring
    for (int k = 0; k < satellites; k++) {
      final a = spinT * twoPi * 1.5 + (k / satellites) * twoPi;
      final vs = _Vec3(radius * math.cos(a), radius * math.sin(a), 0)
          .rotX(rx)
          .rotY(ry)
          .rotZ(rz);
      final ps = _project(vs, center);
      final depthNorm = ((radius - ps.z) / (radius * 2.0)).clamp(0.0, 1.0);
      final r = (2.0 + depthNorm * 2.2) * ps.scale;

      canvas.drawCircle(
        ps.offset,
        r * 2.4,
        Paint()
          ..color = color.withValues(alpha: 0.25 + depthNorm * 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
      canvas.drawCircle(
        ps.offset,
        r,
        Paint()..color = Color.lerp(color, Colors.white, 0.55)!.withValues(alpha: 0.5 + depthNorm * 0.5),
      );
    }
  }

  void _drawParticle(Canvas canvas, _ProjectedParticle pp, bool isScanning, {required bool isBack}) {
    final depthAlpha = isBack ? 0.26 : 0.78;
    final r = pp.size * pp.scale * (isBack ? 0.72 : 1.05);

    if (isScanning) {
      canvas.drawLine(
        pp.prevPos,
        pp.pos,
        Paint()
          ..color = pp.color.withValues(alpha: depthAlpha * 0.55)
          ..strokeWidth = r * 0.9
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      pp.pos,
      r,
      Paint()..color = pp.color.withValues(alpha: depthAlpha),
    );
  }

  @override
  bool shouldRepaint(covariant _Holo3DScannerPainter old) => true;
}

class _ParticleSeed {
  final double theta0;
  final double phi0;
  final double radius;
  final double speed;
  final double size;
  final int colorIdx;
  const _ParticleSeed({
    required this.theta0,
    required this.phi0,
    required this.radius,
    required this.speed,
    required this.size,
    required this.colorIdx,
  });
}

class _ProjectedParticle {
  final Offset pos;
  final Offset prevPos;
  final double z;
  final double scale;
  final double size;
  final Color color;
  const _ProjectedParticle({
    required this.pos,
    required this.prevPos,
    required this.z,
    required this.scale,
    required this.size,
    required this.color,
  });
}
