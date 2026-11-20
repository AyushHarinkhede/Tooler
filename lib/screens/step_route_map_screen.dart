import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/pedometer_sensor_service.dart';
import '../widgets_3d/bouncy_tap.dart';

/// ---------------------------------------------------------------------------
/// TOOLER STEP TRAIL & REAL GPS TRAJECTORY MAP (HOVER PAGE)
/// - Real High-Resolution OpenStreetMap / Leaflet Vector Tile Engine
/// - Color-coded Speed Polyline showing exact path walked today
/// - Interactive Waypoints with speed, time & distance popups
/// - Start & Current Location pulsing radar beacons
/// - Live Route Replay animation with runner marker & telemetry HUD
/// ---------------------------------------------------------------------------

class StepRouteMapScreen extends StatefulWidget {
  final StationeryTheme theme;
  const StepRouteMapScreen({super.key, required this.theme});

  @override
  State<StepRouteMapScreen> createState() => _StepRouteMapScreenState();
}

class _StepRouteMapScreenState extends State<StepRouteMapScreen> {
  late final WebViewController _mapController;
  final PedometerSensorService _pedometer = PedometerSensorService();

  bool _isMapReady = false;
  String _mapStyle = 'carto_dark'; // 'carto_dark' or 'osm_light'
  String _selectedPointInfo = '';

  @override
  void initState() {
    super.initState();
    _mapStyle = widget.theme.isDark ? 'carto_dark' : 'osm_light';
    _initMapController();
  }

  void _initMapController() {
    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        widget.theme.isDark ? const Color(0xFF0F1117) : Colors.white,
      )
      ..addJavaScriptChannel(
        'ToolerMapChannel',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message);
            if (data['event'] == 'pointClick') {
              HapticFeedback.selectionClick();
              SoundService().playTap();
              setState(() {
                _selectedPointInfo =
                    'Point #${data['index'] + 1} · ${data['speed']} km/h · ${data['dist']} km';
              });
            } else if (data['event'] == 'mapLoaded') {
              setState(() => _isMapReady = true);
            }
          } catch (_) {}
        },
      )
      ..loadHtmlString(_buildLeafletHtml());
  }

  String _buildLeafletHtml() {
    final trail = _pedometer.todayTrail;
    final isDark = widget.theme.isDark;
    final tileUrl = _mapStyle == 'carto_dark'
        ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final pointsJson = jsonEncode(trail.map((p) => {
          'lat': p.lat,
          'lon': p.lon,
          'speed': p.speedKmh,
          'dist': p.distanceKm,
          'time': '${p.timestamp.hour.toString().padLeft(2, '0')}:${p.timestamp.minute.toString().padLeft(2, '0')}',
        }).toList());

    final initialCenter = trail.isNotEmpty
        ? [trail.first.lat, trail.first.lon]
        : [19.0760, 72.8777];

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body, #map { width: 100%; height: 100%; background: ${isDark ? "#0A0C10" : "#F8FAFC"}; font-family: -apple-system, sans-serif; overflow: hidden; }
    
    .pulse-start-marker {
      width: 18px;
      height: 18px;
      background: #10B981;
      border: 3px solid #FFFFFF;
      border-radius: 50%;
      box-shadow: 0 0 12px rgba(16, 185, 129, 0.8);
    }

    .pulse-current-marker {
      width: 22px;
      height: 22px;
      background: #F43F5E;
      border: 3.5px solid #FFFFFF;
      border-radius: 50%;
      box-shadow: 0 0 16px rgba(244, 63, 94, 0.9);
      animation: beaconPulse 1.6s infinite ease-out;
    }

    @keyframes beaconPulse {
      0% { box-shadow: 0 0 0 0 rgba(244, 63, 94, 0.7); }
      70% { box-shadow: 0 0 0 18px rgba(244, 63, 94, 0); }
      100% { box-shadow: 0 0 0 0 rgba(244, 63, 94, 0); }
    }

    .runner-replay-marker {
      width: 20px;
      height: 20px;
      background: #3B82F6;
      border: 3px solid #FFFFFF;
      border-radius: 50%;
      box-shadow: 0 0 14px rgba(59, 130, 246, 0.9);
      transition: all 0.35s ease;
    }

    .leaflet-popup-content-wrapper {
      background: ${isDark ? "rgba(22, 25, 34, 0.92)" : "rgba(255, 255, 255, 0.95)"};
      color: ${isDark ? "#FFFFFF" : "#0F172A"};
      border-radius: 12px;
      border: 1px solid ${isDark ? "rgba(255,255,255,0.12)" : "rgba(0,0,0,0.1)"};
      backdrop-filter: blur(10px);
      font-size: 11.5px;
      font-weight: 700;
      padding: 4px;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    const points = $pointsJson;
    const map = L.map('map', {
      zoomControl: false,
      attributionControl: false
    }).setView([${initialCenter[0]}, ${initialCenter[1]}], 16);

    L.tileLayer('$tileUrl', {
      maxZoom: 19,
      subdomains: 'abcd',
    }).addTo(map);

    let replayIndex = 0;
    let replayTimer = null;
    let replayMarker = null;

    if (points && points.length > 0) {
      const latlngs = points.map(p => [p.lat, p.lon]);

      // 1. Draw Multi-Segment Colored Trajectory Line based on Speed
      for (let i = 0; i < points.length - 1; i++) {
        const p1 = points[i];
        const p2 = points[i + 1];
        const speed = p1.speed;

        // Speed Color Palette: Green (normal walk) -> Amber (brisk) -> Red (jogging)
        let strokeColor = '#10B981'; // Moderate walk (<= 4.2 km/h)
        if (speed > 4.2 && speed <= 5.8) {
          strokeColor = '#F59E0B'; // Brisk walk
        } else if (speed > 5.8) {
          strokeColor = '#F43F5E'; // Jogging / Running
        }

        // Draw shadow glow segment
        L.polyline([[p1.lat, p1.lon], [p2.lat, p2.lon]], {
          color: strokeColor,
          weight: 7,
          opacity: 0.28,
          lineCap: 'round'
        }).addTo(map);

        // Core polyline segment
        L.polyline([[p1.lat, p1.lon], [p2.lat, p2.lon]], {
          color: strokeColor,
          weight: 4.2,
          opacity: 0.95,
          lineCap: 'round',
          lineJoin: 'round'
        }).addTo(map);
      }

      // 2. Interactive Waypoints along the line
      points.forEach((p, idx) => {
        if (idx > 0 && idx < points.length - 1 && (idx % 2 === 0 || points.length < 15)) {
          const circle = L.circleMarker([p.lat, p.lon], {
            radius: 4,
            fillColor: '#FFFFFF',
            color: p.speed > 5.8 ? '#F43F5E' : (p.speed > 4.2 ? '#F59E0B' : '#10B981'),
            weight: 2.2,
            opacity: 1,
            fillOpacity: 1
          }).addTo(map);

          circle.bindPopup('<strong>Point #' + (idx + 1) + '</strong><br>Time: ' + p.time + '<br>Speed: ' + p.speed + ' km/h<br>Dist: ' + p.dist + ' km');
          circle.on('click', () => {
            if (window.ToolerMapChannel) {
              window.ToolerMapChannel.postMessage(JSON.stringify({
                event: 'pointClick',
                index: idx,
                speed: p.speed,
                dist: p.dist,
                time: p.time
              }));
            }
          });
        }
      });

      // 3. Start Marker (Green Pin)
      const startPt = points[0];
      const startIcon = L.divIcon({
        className: '',
        html: '<div class="pulse-start-marker"></div>',
        iconSize: [18, 18],
        iconAnchor: [9, 9]
      });
      L.marker([startPt.lat, startPt.lon], { icon: startIcon })
        .addTo(map)
        .bindPopup('<strong>Start Location</strong><br>Time: ' + startPt.time + '<br>0.0 km');

      // 4. Current / End Marker (Red Radar Pulse Pin)
      const endPt = points[points.length - 1];
      const endIcon = L.divIcon({
        className: '',
        html: '<div class="pulse-current-marker"></div>',
        iconSize: [22, 22],
        iconAnchor: [11, 11]
      });
      L.marker([endPt.lat, endPt.lon], { icon: endIcon })
        .addTo(map)
        .bindPopup('<strong>Current Location</strong><br>Speed: ' + endPt.speed + ' km/h<br>' + endPt.dist + ' km Walked');

      // Fit bounds with nice padding
      map.fitBounds(L.latLngBounds(latlngs), { padding: [40, 40] });
    }

    // Interactive Replay Function
    window.startRouteReplay = function() {
      if (!points || points.length === 0) return;
      if (replayTimer) clearInterval(replayTimer);
      replayIndex = 0;

      if (!replayMarker) {
        const replayIcon = L.divIcon({
          className: '',
          html: '<div class="runner-replay-marker"></div>',
          iconSize: [20, 20],
          iconAnchor: [10, 10]
        });
        replayMarker = L.marker([points[0].lat, points[0].lon], { icon: replayIcon }).addTo(map);
      }

      replayTimer = setInterval(() => {
        if (replayIndex >= points.length) {
          clearInterval(replayTimer);
          return;
        }
        const pt = points[replayIndex];
        replayMarker.setLatLng([pt.lat, pt.lon]);
        if (window.ToolerMapChannel) {
          window.ToolerMapChannel.postMessage(JSON.stringify({
            event: 'pointClick',
            index: replayIndex,
            speed: pt.speed,
            dist: pt.dist,
            time: pt.time
          }));
        }
        replayIndex++;
      }, 350);
    };

    window.fitRouteBounds = function() {
      if (points && points.length > 0) {
        const latlngs = points.map(p => [p.lat, p.lon]);
        map.fitBounds(L.latLngBounds(latlngs), { padding: [40, 40] });
      }
    };

    if (window.ToolerMapChannel) {
      window.ToolerMapChannel.postMessage(JSON.stringify({ event: 'mapLoaded' }));
    }
  </script>
</body>
</html>
''';
  }

  void _triggerReplay() {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    _mapController.runJavaScript('window.startRouteReplay();');
  }

  void _recenterRoute() {
    SoundService().playTap();
    HapticFeedback.selectionClick();
    _mapController.runJavaScript('window.fitRouteBounds();');
  }

  void _toggleMapStyle() {
    SoundService().playClick();
    HapticFeedback.lightImpact();
    setState(() {
      _mapStyle = _mapStyle == 'carto_dark' ? 'osm_light' : 'carto_dark';
    });
    _mapController.loadHtmlString(_buildLeafletHtml());
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;
    final distKm = _pedometer.distanceKm;
    final speed = _pedometer.avgSpeedKmh;
    final mins = (_pedometer.activeSeconds / 60).round();
    final cals = _pedometer.caloriesKcal;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  BouncyTap(
                    onTap: () {
                      SoundService().playClick();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border, width: 1.1),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: theme.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TODAY'S WALK TRAJECTORY",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          _selectedPointInfo.isNotEmpty
                              ? _selectedPointInfo
                              : '${_pedometer.todayTrail.length} waypoints recorded · Live GPS trail',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Map Style Toggle (Day / Night)
                  BouncyTap(
                    onTap: _toggleMapStyle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mapStyle == 'carto_dark'
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            size: 13,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _mapStyle == 'carto_dark' ? 'Dark' : 'Light',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: theme.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Real Interactive Map Container with Floating HUD & Controls
            Expanded(
              child: Stack(
                children: [
                  // Full Real Leaflet/OpenStreetMap WebView
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: theme.border, width: 1.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Stack(
                          children: [
                            WebViewWidget(controller: _mapController),
                            if (!_isMapReady)
                              Container(
                                color: theme.cardBg,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: theme.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Loading real street map tiles...',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          color: theme.textSecondary,
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

                  // Floating Top HUD Card (Distance · Time · Speed · Calories)
                  Positioned(
                    top: 14,
                    left: 22,
                    right: 22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.cardBg.withValues(alpha: isDark ? 0.92 : 0.96),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _hudMetric('DISTANCE', '$distKm km', theme.primary, theme),
                          _hudDivider(theme),
                          _hudMetric('DURATION', '$mins min', const Color(0xFF10B981), theme),
                          _hudDivider(theme),
                          _hudMetric('AVG SPEED', '$speed km/h', const Color(0xFFF59E0B), theme),
                          _hudDivider(theme),
                          _hudMetric('BURNED', '$cals kcal', const Color(0xFFF43F5E), theme),
                        ],
                      ),
                    ),
                  ),

                  // Floating Map Action Buttons (Replay Walk & Recenter)
                  Positioned(
                    bottom: 18,
                    right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Route Replay Button
                        BouncyTap(
                          onTap: _triggerReplay,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Recenter Route Button
                        BouncyTap(
                          onTap: _recenterRoute,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.border, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.my_location_rounded, color: theme.text, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Legend (Speed Color Guide)
                  Positioned(
                    bottom: 18,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.cardBg.withValues(alpha: isDark ? 0.90 : 0.94),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _legendItem(const Color(0xFF10B981), 'Walk', theme),
                          const SizedBox(width: 8),
                          _legendItem(const Color(0xFFF59E0B), 'Brisk', theme),
                          const SizedBox(width: 8),
                          _legendItem(const Color(0xFFF43F5E), 'Jog', theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _hudMetric(String label, String value, Color accent, StationeryTheme theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _hudDivider(StationeryTheme theme) {
    return Container(
      width: 1,
      height: 22,
      color: theme.border,
    );
  }

  Widget _legendItem(Color color, String label, StationeryTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: theme.text,
          ),
        ),
      ],
    );
  }
}
