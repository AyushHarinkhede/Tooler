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

  double _liveLat = 0.0;
  double _liveLon = 0.0;
  double _liveAccuracy = 0.0;
  Timer? _liveLocationTimer;
  StreamSubscription<int>? _stepSub;
  int _lastRecordedSteps = -1;

  final List<Map<String, String>> _styleOptions = [
    {
      'id': 'google_road',
      'name': 'Light Mode',
      'icon': '🗺️',
      'desc': 'High-clarity road & street map with landmarks',
    },
    {
      'id': 'google_dark',
      'name': 'Dark Mode',
      'icon': '🌙',
      'desc': 'Deep black OLED contrast, battery efficient',
    },
    {
      'id': 'google_sat',
      'name': 'Satellite Mode',
      'icon': '🛰️',
      'desc': 'Photorealistic high-resolution satellite imagery',
    },
    {
      'id': 'carto_dark',
      'name': 'Carto Night',
      'icon': '🌃',
      'desc': 'Minimalist dark cartographic vector tiles',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapStyle = widget.theme.isDark ? 'google_dark' : 'google_road';
    _lastRecordedSteps = _pedometer.todaySteps;
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

          // Anti-Jitter Precision Movement Gate:
          // User must either Drive (speed > 18 km/h & moved > 30m) OR Walk/Run with actual steps taken!
          final currentSteps = _pedometer.todaySteps;
          final stepDelta = (_lastRecordedSteps >= 0) ? (currentSteps - _lastRecordedSteps) : 0;
          final speed = (fresh['speed'] as num?)?.toDouble() ?? _pedometer.currentSpeedKmh;
          final isDrive = speed > 18.0;

          final isDriveMove = isDrive && distFromPrev >= 30.0;
          final isWalkMove = !isDrive &&
              (stepDelta >= 4 || _pedometer.isWalkingNow) &&
              distFromPrev >= 12.0 &&
              distFromPrev >= (acc * 0.65);

          if (isDriveMove || isWalkMove) {
            _lastRecordedSteps = currentSteps;
            final now = DateTime.now();
            final timeStr =
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
            final activityStr = isDrive ? 'Drive' : (speed > 5.5 ? 'Run' : 'Walk');
            final pt = StepTrailPoint(
              lat: lat,
              lon: lon,
              speedKmh: speed,
              distanceKm: _pedometer.distanceKm,
              steps: currentSteps,
              isVehicle: isDrive,
              activity: activityStr,
              timestamp: now,
            );
            _pedometer.addTrailPoint(pt);
            _appendLiveWaypointToMap(
              lat,
              lon,
              speed,
              _pedometer.distanceKm,
              isDrive,
              timeStr,
              activityStr,
              currentSteps,
            );
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
    double lat,
    double lon,
    double speed,
    double dist,
    bool isVeh,
    String time,
    String activity,
    int steps,
  ) {
    if (!_isMapReady) return;
    _mapController.runJavaScript(
        'window.appendLiveWaypoint($lat, $lon, $speed, $dist, $isVeh, "$time", "$activity", $steps);');
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

    final pointsJson = jsonEncode(trail.map((p) {
      final isDrive = p.isVehicle || p.activity == 'Drive' || p.speedKmh > 16.0;
      final isRun = !isDrive && (p.activity == 'Run' || p.speedKmh > 5.5);
      final act = isDrive ? 'Drive' : (isRun ? 'Run' : 'Walk');
      return {
        'lat': p.lat,
        'lon': p.lon,
        'speed': p.speedKmh,
        'dist': p.distanceKm,
        'steps': p.steps,
        'isVehicle': isDrive,
        'activity': act,
        'time':
            '${p.timestamp.hour.toString().padLeft(2, '0')}:${p.timestamp.minute.toString().padLeft(2, '0')}',
      };
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

    .popup-badge-run {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 6px;
      background: rgba(6, 182, 212, 0.18);
      color: #06B6D4;
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

    window.appendLiveWaypoint = function(lat, lon, speed, dist, isVeh, time, activity, steps) {
      const newPt = [lat, lon];
      const isDrive = isVeh || activity === 'Drive' || speed > 16.0;
      const isRun = !isDrive && (activity === 'Run' || speed > 5.5);
      const strokeColor = isDrive ? '#EF4444' : (isRun ? '#06B6D4' : '#10B981');
      const isDashed = isDrive;

      if (points.length > 0) {
        const prev = points[points.length - 1];

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

      points.push({ lat: lat, lon: lon, speed: speed, dist: dist, isVehicle: isDrive, activity: isDrive ? 'Drive' : (isRun ? 'Run' : 'Walk'), steps: steps || 0, time: time });

      const dotColor = isDrive ? '#EF4444' : (isRun ? '#06B6D4' : '#10B981');
      const circle = L.circleMarker(newPt, {
        radius: 4,
        fillColor: '#FFFFFF',
        color: dotColor,
        weight: 2.5,
        opacity: 1,
        fillOpacity: 1
      }).addTo(map);

      const badgeHtml = isDrive 
        ? '<div class="popup-badge-veh">🚗 DRIVE</div>'
        : (isRun
            ? '<div class="popup-badge-run">🏃 RUN</div>'
            : '<div class="popup-badge-walk">👣 WALK</div>');

      const popupContent = 
        '<div style="min-width: 155px; font-family:-apple-system, sans-serif; padding: 2px;">' +
          badgeHtml +
          '<div style="margin-top:6px; font-size:11px; color:#94A3B8;">Waypoint #' + points.length + ' · ' + time + '</div>' +
          '<div style="margin-top:4px; font-size:12px; font-weight:800;">Steps: ' + (steps || 0) + '</div>' +
          '<div style="font-size:12px; font-weight:700;">Distance: ' + dist + ' km</div>' +
          '<div style="font-size:12px; font-weight:700;">Avg Speed: ' + speed + ' km/h</div>' +
        '</div>';

      circle.bindPopup(popupContent);
    };

    if (points && points.length > 0) {
      const latlngs = points.map(p => [p.lat, p.lon]);

      // 1. Draw Multi-Segment Colored Trajectory
      for (let i = 0; i < points.length - 1; i++) {
        const p1 = points[i];
        const p2 = points[i + 1];
        const isVeh = p1.isVehicle || p2.isVehicle || p1.activity === 'Drive' || p2.activity === 'Drive' || p1.speed > 16.0;
        const isRun = !isVeh && (p1.activity === 'Run' || p2.activity === 'Run' || p1.speed > 5.5);

        let strokeColor = '#10B981'; // Walk (Emerald Green)
        let isDashed = false;

        if (isVeh) {
          strokeColor = '#EF4444'; // Drive (Coral Red, Dashed)
          isDashed = true;
        } else if (isRun) {
          strokeColor = '#06B6D4'; // Run (Cyan Blue)
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
        const isVeh = p.isVehicle || p.activity === 'Drive' || p.speed > 16.0;
        const isRun = !isVeh && (p.activity === 'Run' || p.speed > 5.5);
        const dotColor = isVeh ? '#EF4444' : (isRun ? '#06B6D4' : '#10B981');

        const circle = L.circleMarker([p.lat, p.lon], {
          radius: (idx === 0 || idx === points.length - 1) ? 6 : 4,
          fillColor: '#FFFFFF',
          color: dotColor,
          weight: 2.5,
          opacity: 1,
          fillOpacity: 1
        }).addTo(map);

        const badgeHtml = isVeh 
          ? '<div class="popup-badge-veh">🚗 DRIVE</div>'
          : (isRun
              ? '<div class="popup-badge-run">🏃 RUN</div>'
              : '<div class="popup-badge-walk">👣 WALK</div>');

        const popupContent = 
          '<div style="min-width: 155px; font-family:-apple-system, sans-serif; padding: 2px;">' +
            badgeHtml +
            '<div style="margin-top:6px; font-size:11px; color:#94A3B8;">Waypoint #' + (idx + 1) + ' · ' + p.time + '</div>' +
            '<div style="margin-top:4px; font-size:12px; font-weight:800;">Steps: ' + (p.steps || 0) + '</div>' +
            '<div style="font-size:12px; font-weight:700;">Distance: ' + p.dist + ' km</div>' +
            '<div style="font-size:12px; font-weight:700;">Avg Speed: ' + p.speed + ' km/h</div>' +
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
              activity: isVeh ? 'Drive' : (isRun ? 'Run' : 'Walk'),
              steps: p.steps || 0,
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

  IconData _getCurrentStyleIcon() {
    switch (_mapStyle) {
      case 'google_road':
        return Icons.map_outlined;
      case 'google_dark':
        return Icons.dark_mode_outlined;
      case 'google_sat':
        return Icons.satellite_alt_rounded;
      case 'carto_dark':
        return Icons.nights_stay_outlined;
      default:
        return Icons.layers_rounded;
    }
  }

  void _showMapLayerSelectorSheet(BuildContext context, StationeryTheme theme) {
    SoundService().playClick();
    HapticFeedback.mediumImpact();
    final isDark = theme.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: theme.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.layers_rounded, color: theme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Map View Style',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._styleOptions.map((style) {
                final isSelected = style['id'] == _mapStyle;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: BouncyTap(
                    onTap: () {
                      SoundService().playClick();
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      if (_mapStyle != style['id']) {
                        setState(() {
                          _mapStyle = style['id']!;
                          _isMapReady = false;
                        });
                        _mapController.loadHtmlString(_buildLeafletHtml());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primary.withValues(alpha: 0.12)
                            : theme.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? theme.primary : theme.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            style['icon']!,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  style['name']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? theme.primary
                                        : theme.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  style['desc']!,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: theme.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;
    final distKm = _pedometer.distanceKm;
    final speed = _pedometer.avgSpeedKmh;
    final mins = (_pedometer.activeSeconds / 60).round();
    final steps = _pedometer.todaySteps;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: Stack(
            children: [
              // 1. Real Interactive Leaflet Map Container
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
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

              // 2. Floating Top HUD Card
              Positioned(
                top: 12,
                left: 12,
                right: 12,
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

              // 3. Floating Map Action Buttons (Layers Selector, Route Replay, Recenter)
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Layer / Map Style Selector Button
                    BouncyTap(
                      onTap: () => _showMapLayerSelectorSheet(context, theme),
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
                                  .withValues(alpha: isDark ? 0.35 : 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getCurrentStyleIcon(),
                          color: theme.primary,
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Route Replay Button
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
                              color: theme.primary.withValues(alpha: 0.45),
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
                    // Recenter / Live Location Button
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
                                  .withValues(alpha: isDark ? 0.35 : 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.my_location_rounded,
                          color: _liveLat != 0.0
                              ? const Color(0xFF3B82F6)
                              : theme.text,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Floating Legend: Walk, Run, Drive
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        theme.cardBg.withValues(alpha: isDark ? 0.90 : 0.95),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: theme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendItem(const Color(0xFF10B981), 'Walk',
                          theme, false),
                      const SizedBox(width: 8),
                      _legendItem(
                          const Color(0xFF06B6D4), 'Run', theme, false),
                      const SizedBox(width: 8),
                      _legendItem(const Color(0xFFEF4444),
                          'Drive', theme, true),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
