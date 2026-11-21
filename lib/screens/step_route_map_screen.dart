import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/pedometer_sensor_service.dart';
import '../widgets_3d/bouncy_tap.dart';

/// ---------------------------------------------------------------------------
/// TOOLER STEP TRAIL & REAL MULTI-API GPS & TRAJECTORY MAP
/// - Google Maps (OLED Dark Mode, Road Light & Hybrid Satellite) + Carto Night
/// - Live GPS location centering with pulsing real-time beacon
/// - Accurate Color-coded Polyline:
///     * 🟢 Emerald Green: Walking (With Steps)
///     * 🔵 Cyan Blue: Running / Jogging (With Steps)
///     * 🔴 Red/Orange Dashed: Vehicle / Transit (WITHOUT Steps)
/// - Interactive Waypoint Dots along the route with instant speed & step diagnostics
/// - Real-Time Replay Engine & "Recenter to My Location" FAB
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
  // Available map styles: 'google_dark', 'google_road', 'google_sat', 'carto_dark'
  String _mapStyle = 'google_dark';
  String _selectedPointInfo = '';

  double _liveLat = 0.0;
  double _liveLon = 0.0;
  double _liveAccuracy = 0.0;
  Timer? _liveLocationTimer;
  StreamSubscription<int>? _stepSub;

  final List<Map<String, String>> _styleOptions = [
    {'id': 'google_dark', 'name': 'OLED Dark', 'icon': '🌙'},
    {'id': 'google_road', 'name': 'Google Road', 'icon': '🗺️'},
    {'id': 'google_sat', 'name': 'Google Sat', 'icon': '🛰️'},
    {'id': 'carto_dark', 'name': 'Carto Night', 'icon': '🌃'},
  ];

  @override
  void initState() {
    super.initState();
    _mapStyle = widget.theme.isDark ? 'google_dark' : 'google_road';
    _initMapController();
    _initLiveLocationAndTrail();

    _stepSub = _pedometer.stepStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveLocationTimer?.cancel();
    _stepSub?.cancel();
    _pedometer.stopLiveTrailTracking();
    super.dispose();
  }

  Future<void> _initLiveLocationAndTrail() async {
    // 1. Request location permissions
    await _pedometer.requestLocationPermission();

    // 2. Start native live trail tracking while map is opened
    await _pedometer.startLiveTrailTracking();

    // 3. Immediately fetch live location
    final loc = await _pedometer.getCurrentLocation();
    if (loc != null && mounted) {
      final lat = (loc['latitude'] as num?)?.toDouble() ?? 0.0;
      final lon = (loc['longitude'] as num?)?.toDouble() ?? 0.0;
      final acc = (loc['accuracy'] as num?)?.toDouble() ?? 0.0;
      if (lat != 0.0 && lon != 0.0) {
        setState(() {
          _liveLat = lat;
          _liveLon = lon;
          _liveAccuracy = acc;
        });
        _updateMapLiveLocation(lat, lon, acc, panTo: true);
      }
    }

    // 4. Periodically query location every 3.5 seconds while screen is open
    _liveLocationTimer?.cancel();
    _liveLocationTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) async {
      if (!mounted) return;
      final fresh = await _pedometer.getCurrentLocation();
      if (fresh != null && mounted) {
        final lat = (fresh['latitude'] as num?)?.toDouble() ?? 0.0;
        final lon = (fresh['longitude'] as num?)?.toDouble() ?? 0.0;
        final acc = (fresh['accuracy'] as num?)?.toDouble() ?? 0.0;
        if (lat != 0.0 && lon != 0.0) {
          final distFromPrev = _liveLat != 0.0
              ? _calculateDistanceMeters(_liveLat, _liveLon, lat, lon)
              : 999.0;

          final hadInitialFix = _liveLat != 0.0;
          _liveLat = lat;
          _liveLon = lon;
          _liveAccuracy = acc;

          _updateMapLiveLocation(lat, lon, acc, panTo: !hadInitialFix);

          // If moved > 5 meters, append waypoint
          if (distFromPrev > 5.0 && distFromPrev < 5000.0) {
            final now = DateTime.now();
            final speed = (fresh['speed'] as num?)?.toDouble() ?? _pedometer.currentSpeedKmh;
            final isVeh = speed > 16.0;
            final timeStr =
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
            final pt = StepTrailPoint(
              lat: lat,
              lon: lon,
              speedKmh: speed,
              distanceKm: _pedometer.distanceKm,
              steps: _pedometer.todaySteps,
              isVehicle: isVeh,
              activity: isVeh ? 'Vehicle' : (speed > 5.5 ? 'Running' : 'Walking'),
              timestamp: now,
            );
            _pedometer.addTrailPoint(pt);
            _appendLiveWaypointToMap(lat, lon, speed, _pedometer.distanceKm, isVeh, timeStr);
            if (mounted) setState(() {});
          }
        }
      }
    });
  }

  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  void _updateMapLiveLocation(double lat, double lon, double acc, {bool panTo = false}) {
    if (!_isMapReady) return;
    _mapController.runJavaScript('window.setLiveLocation($lat, $lon, $acc, $panTo);');
  }

  void _appendLiveWaypointToMap(
      double lat, double lon, double speed, double dist, bool isVeh, String time) {
    if (!_isMapReady) return;
    _mapController.runJavaScript(
        'window.appendLiveWaypoint($lat, $lon, $speed, $dist, $isVeh, "$time");');
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
              final isVeh = data['isVehicle'] == true;
              setState(() {
                _selectedPointInfo = isVeh
                    ? 'Point #${data['index'] + 1} · 🚗 ${data['speed']} km/h · Vehicle (No Steps)'
                    : 'Point #${data['index'] + 1} · 🚶 ${data['speed']} km/h · ${data['dist']} km';
              });
            } else if (data['event'] == 'mapLoaded') {
              setState(() => _isMapReady = true);
              if (_liveLat != 0.0 && _liveLon != 0.0) {
                _updateMapLiveLocation(_liveLat, _liveLon, _liveAccuracy, panTo: true);
              }
            }
          } catch (_) {}
        },
      )
      ..loadHtmlString(_buildLeafletHtml());
  }

  String _getTileUrl() {
    switch (_mapStyle) {
      case 'google_dark':
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case 'google_road':
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case 'google_sat':
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case 'carto_dark':
      default:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png';
    }
  }

  String _buildLeafletHtml() {
    final trail = _pedometer.todayTrail;
    final isDark = widget.theme.isDark;
    final tileUrl = _getTileUrl();
    final isCarto = _mapStyle == 'carto_dark';

    final pointsJson = jsonEncode(trail.map((p) => {
          'lat': p.lat,
          'lon': p.lon,
          'speed': p.speedKmh,
          'dist': p.distanceKm,
          'steps': p.steps,
          'isVehicle': p.isVehicle || p.speedKmh > 16.0,
          'activity': p.activity,
          'time':
              '${p.timestamp.hour.toString().padLeft(2, '0')}:${p.timestamp.minute.toString().padLeft(2, '0')}',
        }).toList());

    final initialCenter = _liveLat != 0.0 && _liveLon != 0.0
        ? [_liveLat, _liveLon]
        : (trail.isNotEmpty
            ? [trail.last.lat, trail.last.lon]
            : (_pedometer.lastLat != 0.0 && _pedometer.lastLon != 0.0
                ? [_pedometer.lastLat, _pedometer.lastLon]
                : [20.5937, 78.9629]));

    final initialZoom = (_liveLat != 0.0 || trail.isNotEmpty) ? 16 : 5;

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
    html, body, #map { width: 100%; height: 100%; background: ${isDark ? "#0A0C10" : "#F8FAFC"}; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; overflow: hidden; }
    
    ${_mapStyle == 'google_dark' ? '''
    .leaflet-tile-pane {
      filter: invert(100%) hue-rotate(180deg) brightness(92%) contrast(92%);
    }
    ''' : ''}

    .pulse-start-marker {
      width: 16px;
      height: 16px;
      background: #10B981;
      border: 3px solid #FFFFFF;
      border-radius: 50%;
      box-shadow: 0 0 10px rgba(16, 185, 129, 0.8);
    }

    .pulse-live-marker {
      position: relative;
      width: 22px;
      height: 22px;
      background: #3B82F6;
      border: 3.5px solid #FFFFFF;
      border-radius: 50%;
      box-shadow: 0 0 16px rgba(59, 130, 246, 0.9);
      animation: livePulse 1.8s infinite ease-out;
    }

    @keyframes livePulse {
      0% { box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.8); }
      70% { box-shadow: 0 0 0 18px rgba(59, 130, 246, 0); }
      100% { box-shadow: 0 0 0 0 rgba(59, 130, 246, 0); }
    }

    .runner-replay-marker {
      width: 22px;
      height: 22px;
      background: #F59E0B;
      border: 3px solid #FFFFFF;
      border-radius: 50%;
      box-shadow: 0 0 14px rgba(245, 158, 11, 0.9);
      transition: all 0.3s ease;
    }

    .leaflet-popup-content-wrapper {
      background: ${isDark ? "rgba(15, 23, 42, 0.96)" : "rgba(255, 255, 255, 0.96)"};
      color: ${isDark ? "#FFFFFF" : "#0F172A"};
      border-radius: 14px;
      border: 1px solid ${isDark ? "rgba(255,255,255,0.18)" : "rgba(0,0,0,0.12)"};
      backdrop-filter: blur(12px);
      box-shadow: 0 10px 25px rgba(0,0,0,0.3);
      padding: 4px;
    }

    .popup-badge-walk {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 6px;
      background: rgba(16, 185, 129, 0.18);
      color: #10B981;
      font-weight: 800;
      font-size: 11px;
    }

    .popup-badge-veh {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 6px;
      background: rgba(239, 68, 68, 0.18);
      color: #EF4444;
      font-weight: 800;
      font-size: 11px;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    const points = $pointsJson;
    let initialLat = ${initialCenter[0]};
    let initialLon = ${initialCenter[1]};

    const map = L.map('map', {
      zoomControl: false,
      attributionControl: false
    }).setView([initialLat, initialLon], $initialZoom);

    L.tileLayer('$tileUrl', {
      maxZoom: 20,
      subdomains: '${isCarto ? "abcd" : ""}',
    }).addTo(map);

    let liveMarker = null;
    let liveCircle = null;
    let replayIndex = 0;
    let replayTimer = null;
    let replayMarker = null;

    window.setLiveLocation = function(lat, lon, accuracy, panTo) {
      const pos = [lat, lon];
      if (!liveMarker) {
        const liveIcon = L.divIcon({
          className: '',
          html: '<div class="pulse-live-marker"></div>',
          iconSize: [22, 22],
          iconAnchor: [11, 11]
        });
        liveMarker = L.marker(pos, { icon: liveIcon, zIndexOffset: 1000 }).addTo(map);
        liveMarker.bindPopup('<strong>📍 You Are Here (Live)</strong><br>Accurate GPS Fix');
      } else {
        liveMarker.setLatLng(pos);
      }

      if (accuracy && accuracy > 0) {
        if (!liveCircle) {
          liveCircle = L.circle(pos, {
            radius: Math.min(accuracy, 80),
            color: '#3B82F6',
            fillColor: '#3B82F6',
            fillOpacity: 0.15,
            weight: 1.2
          }).addTo(map);
        } else {
          liveCircle.setLatLng(pos);
          liveCircle.setRadius(Math.min(accuracy, 80));
        }
      }

      if (panTo) {
        map.setView(pos, Math.max(map.getZoom(), 16), { animate: true });
      }
    };

    window.appendLiveWaypoint = function(lat, lon, speed, dist, isVeh, time) {
      const newPt = [lat, lon];
      if (points.length > 0) {
        const prev = points[points.length - 1];
        const strokeColor = isVeh ? '#EF4444' : (speed > 5.5 ? '#06B6D4' : '#10B981');
        const isDashed = isVeh;

        L.polyline([[prev.lat, prev.lon], newPt], {
          color: strokeColor,
          weight: isDashed ? 5 : 7,
          opacity: 0.25,
          dashArray: isDashed ? '8, 8' : null,
          lineCap: 'round'
        }).addTo(map);

        L.polyline([[prev.lat, prev.lon], newPt], {
          color: strokeColor,
          weight: 4.2,
          opacity: 0.95,
          dashArray: isDashed ? '6, 8' : null,
          lineCap: 'round',
          lineJoin: 'round'
        }).addTo(map);
      }

      points.push({ lat: lat, lon: lon, speed: speed, dist: dist, isVehicle: isVeh, time: time });

      const dotColor = isVeh ? '#EF4444' : (speed > 5.5 ? '#06B6D4' : '#10B981');
      L.circleMarker(newPt, {
        radius: 4,
        fillColor: '#FFFFFF',
        color: dotColor,
        weight: 2.5,
        opacity: 1,
        fillOpacity: 1
      }).addTo(map);
    };

    if (points && points.length > 0) {
      const latlngs = points.map(p => [p.lat, p.lon]);

      // 1. Draw Multi-Segment Colored Trajectory
      for (let i = 0; i < points.length - 1; i++) {
        const p1 = points[i];
        const p2 = points[i + 1];
        const isVeh = p1.isVehicle || p2.isVehicle;
        const speed = p1.speed;

        let strokeColor = '#10B981'; // Moderate Walking (With Steps)
        let isDashed = false;

        if (isVeh) {
          strokeColor = '#EF4444'; // Vehicle / Transit (Without Steps)
          isDashed = true;
        } else if (speed > 5.5) {
          strokeColor = '#06B6D4'; // Running / Jogging (With Steps)
        }

        // Ambient glow line
        L.polyline([[p1.lat, p1.lon], [p2.lat, p2.lon]], {
          color: strokeColor,
          weight: isDashed ? 5 : 7,
          opacity: 0.25,
          dashArray: isDashed ? '8, 8' : null,
          lineCap: 'round'
        }).addTo(map);

        // Core precision line
        L.polyline([[p1.lat, p1.lon], [p2.lat, p2.lon]], {
          color: strokeColor,
          weight: 4.2,
          opacity: 0.95,
          dashArray: isDashed ? '6, 8' : null,
          lineCap: 'round',
          lineJoin: 'round'
        }).addTo(map);
      }

      // 2. Interactive Waypoint Dots along the route
      points.forEach((p, idx) => {
        const isVeh = p.isVehicle;
        const dotColor = isVeh ? '#EF4444' : (p.speed > 5.5 ? '#06B6D4' : '#10B981');

        const circle = L.circleMarker([p.lat, p.lon], {
          radius: (idx === 0 || idx === points.length - 1) ? 6 : 4,
          fillColor: '#FFFFFF',
          color: dotColor,
          weight: 2.5,
          opacity: 1,
          fillOpacity: 1
        }).addTo(map);

        const badgeHtml = isVeh 
          ? '<div class="popup-badge-veh">🚗 VEHICLE (NO STEPS)</div>'
          : '<div class="popup-badge-walk">👣 WALKING (WITH STEPS)</div>';

        const popupContent = 
          '<div style="min-width: 150px; font-family:-apple-system, sans-serif;">' +
            badgeHtml +
            '<div style="margin-top:6px; font-size:11px; color:#94A3B8;">Waypoint #' + (idx + 1) + ' · ' + p.time + '</div>' +
            '<div style="margin-top:4px; font-size:12px; font-weight:800;">Speed: ' + p.speed + ' km/h</div>' +
            '<div style="font-size:11.5px; font-weight:600; color:#64748B;">Cum. Dist: ' + p.dist + ' km</div>' +
            (isVeh ? '<div style="margin-top:4px; font-size:10px; color:#EF4444; font-weight:700;">Steps suppressed to protect accuracy</div>' : '<div style="margin-top:4px; font-size:10px; color:#10B981; font-weight:700;">Steps tracked to pedometer</div>') +
          '</div>';

        circle.bindPopup(popupContent);
        circle.on('click', () => {
          if (window.ToolerMapChannel) {
            window.ToolerMapChannel.postMessage(JSON.stringify({
              event: 'pointClick',
              index: idx,
              speed: p.speed,
              dist: p.dist,
              isVehicle: isVeh,
              time: p.time
            }));
          }
        });
      });

      // 3. Start Marker (Green Pin)
      const startPt = points[0];
      const startIcon = L.divIcon({
        className: '',
        html: '<div class="pulse-start-marker"></div>',
        iconSize: [16, 16],
        iconAnchor: [8, 8]
      });
      L.marker([startPt.lat, startPt.lon], { icon: startIcon })
        .addTo(map)
        .bindPopup('<strong>Start Location</strong><br>Time: ' + startPt.time + '<br>0.0 km');

      // Fit bounds if no live location yet
      map.fitBounds(L.latLngBounds(latlngs), { padding: [40, 40] });
    }

    // Replay Function
    window.startRouteReplay = function() {
      if (!points || points.length === 0) return;
      if (replayTimer) clearInterval(replayTimer);
      replayIndex = 0;

      if (!replayMarker) {
        const replayIcon = L.divIcon({
          className: '',
          html: '<div class="runner-replay-marker"></div>',
          iconSize: [22, 22],
          iconAnchor: [11, 11]
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
            isVehicle: pt.isVehicle,
            time: pt.time
          }));
        }
        replayIndex++;
      }, 320);
    };

    window.fitRouteBounds = function() {
      const allCoords = points.map(p => [p.lat, p.lon]);
      if (liveMarker) {
        allCoords.push(liveMarker.getLatLng());
      }
      if (allCoords.length > 0) {
        map.fitBounds(L.latLngBounds(allCoords), { padding: [40, 40], maxZoom: 17 });
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

  void _recenterRoute() async {
    SoundService().playTap();
    HapticFeedback.selectionClick();

    if (_liveLat != 0.0 && _liveLon != 0.0) {
      _mapController.runJavaScript(
          'window.setLiveLocation($_liveLat, $_liveLon, $_liveAccuracy, true);');
    } else {
      final loc = await _pedometer.getCurrentLocation();
      if (loc != null && mounted) {
        final lat = (loc['latitude'] as num?)?.toDouble() ?? 0.0;
        final lon = (loc['longitude'] as num?)?.toDouble() ?? 0.0;
        final acc = (loc['accuracy'] as num?)?.toDouble() ?? 0.0;
        if (lat != 0.0 && lon != 0.0) {
          setState(() {
            _liveLat = lat;
            _liveLon = lon;
            _liveAccuracy = acc;
          });
          _mapController.runJavaScript(
              'window.setLiveLocation($lat, $lon, $acc, true);');
          return;
        }
      }
      _mapController.runJavaScript('window.fitRouteBounds();');
    }
  }

  void _cycleMapStyle() {
    SoundService().playClick();
    HapticFeedback.lightImpact();
    final currentIdx = _styleOptions.indexWhere((s) => s['id'] == _mapStyle);
    final nextIdx = (currentIdx + 1) % _styleOptions.length;
    setState(() {
      _mapStyle = _styleOptions[nextIdx]['id']!;
      _isMapReady = false;
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
    final steps = _pedometer.todaySteps;
    final currentStyleMeta =
        _styleOptions.firstWhere((s) => s['id'] == _mapStyle);

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Navigation Bar
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
                        Row(
                          children: [
                            Text(
                              "WALK TRAJECTORY MAP",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: theme.text,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (_liveLat != 0.0
                                        ? const Color(0xFF10B981)
                                        : theme.primary)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _liveLat != 0.0
                                      ? const Color(0xFF10B981)
                                      : theme.primary,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _liveLat != 0.0
                                          ? const Color(0xFF10B981)
                                          : theme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _liveLat != 0.0 ? 'LIVE GPS' : 'SEARCHING',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: _liveLat != 0.0
                                          ? const Color(0xFF10B981)
                                          : theme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _selectedPointInfo.isNotEmpty
                              ? _selectedPointInfo
                              : '${_pedometer.todayTrail.length} waypoints · Real GPS walk trail',
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
                  // Map Style Layer Switcher
                  BouncyTap(
                    onTap: _cycleMapStyle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentStyleMeta['icon']!,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            currentStyleMeta['name']!,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
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

            // 2. Real Interactive Map Container
            Expanded(
              child: Stack(
                children: [
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
                                        'Syncing real map tiles...',
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

                  // Floating Top HUD Card
                  Positioned(
                    top: 14,
                    left: 22,
                    right: 22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.cardBg
                            .withValues(alpha: isDark ? 0.92 : 0.96),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _hudMetric('STEPS', '$steps', theme.primary, theme),
                          _hudDivider(theme),
                          _hudMetric(
                              'DISTANCE', '$distKm km', const Color(0xFF10B981), theme),
                          _hudDivider(theme),
                          _hudMetric(
                              'AVG SPEED', '$speed km/h', const Color(0xFF06B6D4), theme),
                          _hudDivider(theme),
                          _hudMetric('ACTIVE', '$mins m', const Color(0xFFF59E0B), theme),
                        ],
                      ),
                    ),
                  ),

                  // Floating Map Action Buttons (Replay & Recenter to Live Location)
                  Positioned(
                    bottom: 18,
                    right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.3 : 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.my_location_rounded,
                                color: _liveLat != 0.0
                                    ? const Color(0xFF3B82F6)
                                    : theme.text,
                                size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Legend with Walk (Steps) vs Vehicle (No Steps)
                  Positioned(
                    bottom: 18,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            theme.cardBg.withValues(alpha: isDark ? 0.90 : 0.95),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: theme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _legendItem(const Color(0xFF10B981), 'Walk (Steps)',
                                  theme, false),
                              const SizedBox(width: 8),
                              _legendItem(
                                  const Color(0xFF06B6D4), 'Run', theme, false),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _legendItem(const Color(0xFFEF4444),
                              'Vehicle (No Steps)', theme, true),
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

  Widget _hudMetric(
      String label, String value, Color accent, StationeryTheme theme) {
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

  Widget _legendItem(
      Color color, String label, StationeryTheme theme, bool isDashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: theme.text,
          ),
        ),
      ],
    );
  }
}
