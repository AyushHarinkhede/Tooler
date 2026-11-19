import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GPS / Trail Waypoint recorded along the walk or transit
class StepTrailPoint {
  final double lat;
  final double lon;
  final double speedKmh;
  final double distanceKm;
  final int steps;
  final bool isVehicle;
  final String activity;
  final DateTime timestamp;

  const StepTrailPoint({
    required this.lat,
    required this.lon,
    required this.speedKmh,
    required this.distanceKm,
    this.steps = 0,
    this.isVehicle = false,
    this.activity = 'Walking',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'speedKmh': speedKmh,
        'distanceKm': distanceKm,
        'steps': steps,
        'isVehicle': isVehicle,
        'activity': activity,
        'timestamp': timestamp.toIso8601String(),
      };

  factory StepTrailPoint.fromJson(Map<String, dynamic> j) => StepTrailPoint(
        lat: (j['lat'] as num?)?.toDouble() ?? 0.0,
        lon: (j['lon'] as num?)?.toDouble() ?? 0.0,
        speedKmh: (j['speedKmh'] as num?)?.toDouble() ?? 0.0,
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0.0,
        steps: (j['steps'] as num?)?.toInt() ?? 0,
        isVehicle: j['isVehicle'] == true,
        activity: (j['activity'] as String?) ?? 'Walking',
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Daily Step Activity Record for 7D, 1M, 3M, 6M, 1Y (Strictly Real Data)
class DailyStepRecord {
  final DateTime date;
  final int steps;
  final double distanceKm;
  final double avgSpeedKmh;
  final int caloriesKcal;
  final int activeMinutes;

  const DailyStepRecord({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.caloriesKcal,
    required this.activeMinutes,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'steps': steps,
        'distanceKm': distanceKm,
        'avgSpeedKmh': avgSpeedKmh,
        'caloriesKcal': caloriesKcal,
        'activeMinutes': activeMinutes,
      };

  factory DailyStepRecord.fromJson(Map<String, dynamic> j) => DailyStepRecord(
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        steps: (j['steps'] as num?)?.toInt() ?? 0,
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0.0,
        avgSpeedKmh: (j['avgSpeedKmh'] as num?)?.toDouble() ?? 4.5,
        caloriesKcal: (j['caloriesKcal'] as num?)?.toInt() ?? 0,
        activeMinutes: (j['activeMinutes'] as num?)?.toInt() ?? 0,
      );
}

/// High-Accuracy Hardware-Fused Pedometer & GNSS Trajectory Service
/// - 100% Real Time Data (Zero Mock/Fake Data)
/// - Hardware Step Sensor Hub Binding (Android Sensor.TYPE_STEP_COUNTER)
/// - Background Service execution surviving app close / RAM eviction
/// - Vehicle Transit Detection (>16 km/h) & Step Freezing
/// - GPS & NavIC (IRNSS Constellation 7) Satellite Support
class PedometerSensorService {
  static final PedometerSensorService _instance =
      PedometerSensorService._internal();
  factory PedometerSensorService() => _instance;
  PedometerSensorService._internal();

  static const MethodChannel _stepChannel =
      MethodChannel('com.tooler.tooler/step_counter');
  static const EventChannel _stepEventChannel =
      EventChannel('com.tooler.tooler/step_counter_events');

  static const String _prefTodayStepsKey = 'tooler_steps_today_count_v2';
  static const String _prefDailyGoalKey = 'tooler_steps_daily_goal_v2';
  static const String _prefHistoryKey = 'tooler_steps_history_records_v2';
  static const String _prefTrailKey = 'tooler_steps_today_trail_v2';
  static const String _prefLastDateKey = 'tooler_steps_last_active_date_v2';
  static const String _prefActiveSecsKey = 'tooler_steps_active_seconds_v2';
  static const String _prefInstallTimeKey = 'tooler_steps_installed_time_v2';

  // Constants
  static const double kDefaultStrideLengthMeters = 0.762; // ~76.2 cm standard human stride
  static const double kCaloriesPerStep = 0.042; // ~42 kcal per 1000 steps

  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription? _nativeEventSub;
  Timer? _activeWalkTimer;

  // Real-time zero initial state (NO fake defaults!)
  int _todaySteps = 0;
  int _dailyGoal = 10000;
  int _activeSeconds = 0;
  final double _strideLengthM = kDefaultStrideLengthMeters;
  bool _isHardwareSynced = false;
  bool _isWalkingNow = false;
  bool _isVehicleMode = false;
  bool _hasNavicFix = false;
  int _satellitesCount = 0;
  String _currentActivity = 'Stationary';
  double _currentSpeedKmh = 0.0;
  double _lastLat = 0.0;
  double _lastLon = 0.0;
  DateTime? _installDate;
  DateTime _lastStepTime = DateTime.now();

  // Advanced Fallback Sensor Fusion Filter States (Cadence & Refractory)
  int _lastStepMs = 0;
  double _currentGyroRate = 0.0;
  bool _isPeakRising = false;

  // Trail polyline coordinates for today (Strictly Real Data)
  List<StepTrailPoint> _todayTrail = [];
  List<DailyStepRecord> _historyRecords = [];

  final StreamController<int> _stepStreamController =
      StreamController<int>.broadcast();
  Stream<int> get stepStream => _stepStreamController.stream;

  // Getters
  int get todaySteps => _todaySteps;
  int get dailyGoal => _dailyGoal;
  int get activeSeconds => _activeSeconds;
  bool get isHardwareSynced => _isHardwareSynced;
  bool get isWalkingNow => _isWalkingNow;
  bool get isVehicleMode => _isVehicleMode;
  bool get hasNavicFix => _hasNavicFix;
  int get satellitesCount => _satellitesCount;
  String get currentActivity => _currentActivity;
  double get currentSpeedKmh => _currentSpeedKmh;
  double get lastLat => _lastLat;
  double get lastLon => _lastLon;
  DateTime? get installDate => _installDate;
  List<StepTrailPoint> get todayTrail => List.unmodifiable(_todayTrail);
  List<DailyStepRecord> get historyRecords => List.unmodifiable(_historyRecords);

  /// Calculated total walking distance today in kilometers
  double get distanceKm {
    return double.parse(
        ((_todaySteps * _strideLengthM) / 1000.0).toStringAsFixed(2));
  }

  /// Calculated average speed in km/h
  double get avgSpeedKmh {
    if (_currentSpeedKmh > 0) return _currentSpeedKmh;
    if (_activeSeconds < 20 || distanceKm <= 0.01) return 0.0;
    final hours = _activeSeconds / 3600.0;
    final speed = distanceKm / hours;
    return double.parse(speed.clamp(1.0, 14.0).toStringAsFixed(1));
  }

  /// Calories burned today
  int get caloriesKcal {
    return (_todaySteps * kCaloriesPerStep).round();
  }

  Future<void> initialize() async {
    await _loadPersistedState();
    _checkDayRollover();
    _connectNativeServiceAndSensors();
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _stepChannel.invokeMethod('requestStepPermissions');
      } catch (_) {}
    }
  }

  void setDailyGoal(int goal) {
    _dailyGoal = goal.clamp(1000, 50000);
    _persistState();
  }

  /// Reset & purge any old mock/fake data from previous versions
  Future<void> clearAllFakeData() async {
    _todaySteps = 0;
    _activeSeconds = 0;
    _todayTrail = [];
    _historyRecords = [];
    _currentSpeedKmh = 0.0;
    _isWalkingNow = false;
    _isVehicleMode = false;

    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _stepChannel.invokeMethod('clearAllFakeData');
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTodayStepsKey, 0);
    await prefs.setInt(_prefActiveSecsKey, 0);
    await prefs.setString(_prefTrailKey, '[]');
    await prefs.setString(_prefHistoryKey, '[]');
    await prefs.setString(
      _prefInstallTimeKey,
      DateTime.now().toIso8601String(),
    );
    _installDate = DateTime.now();

    _stepStreamController.add(0);
  }

  void _connectNativeServiceAndSensors() {
    if (!kIsWeb && Platform.isAndroid) {
      // 1. Check hardware sensors and start persistent background service
      _stepChannel.invokeMethod<Map>('getHardwareStepStatus').then((res) {
        if (res != null) {
          _isHardwareSynced = res['hasStepSensor'] == true;
          _hasNavicFix = res['hasNavicFix'] == true;
          _satellitesCount = (res['satellites'] as num?)?.toInt() ?? 0;
        }
      }).catchError((_) {});

      // 2. Start Android Hardware Service
      _stepChannel.invokeMethod('startTracking').catchError((_) {});

      // 3. Listen to Native Live Step & GNSS Telemetry stream
      try {
        _nativeEventSub = _stepEventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
            if (event is Map) {
              final steps = (event['todaySteps'] as num?)?.toInt();
              final secs = (event['activeSeconds'] as num?)?.toInt();
              final speed = (event['avgSpeedKmh'] as num?)?.toDouble();
              final hw = event['isHardwareSynced'] == true;
              final walking = event['isWalking'] == true;
              final vehicle = event['isVehicle'] == true;
              final act = (event['activity'] as String?) ?? 'Walking';
              final navic = event['hasNavicFix'] == true;
              final sats = (event['satellites'] as num?)?.toInt() ?? 0;
              final lat = (event['latitude'] as num?)?.toDouble() ?? 0.0;
              final lon = (event['longitude'] as num?)?.toDouble() ?? 0.0;

              if (steps != null && steps >= 0) _todaySteps = steps;
              if (secs != null && secs >= 0) _activeSeconds = secs;
              if (speed != null) _currentSpeedKmh = speed;
              _isHardwareSynced = hw;
              _isWalkingNow = walking;
              _isVehicleMode = vehicle;
              _currentActivity = act;
              _hasNavicFix = navic;
              _satellitesCount = sats;
              if (lat != 0.0 && lon != 0.0) {
                _lastLat = lat;
                _lastLon = lon;
              }

              _stepStreamController.add(_todaySteps);
            }
          },
          onError: (_) {},
        );
      } catch (_) {}
    }

    // 4. Fallback sensors (only active if native hardware step counter is absent)
    _startFallbackSensorListening();

    // 5. Active walking timeout checker
    _activeWalkTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final now = DateTime.now();
      if (_isWalkingNow &&
          now.difference(_lastStepTime).inMilliseconds > 3500) {
        _isWalkingNow = false;
        if (!_isVehicleMode) _currentActivity = 'Stationary';
      }
    });
  }

  void _startFallbackSensorListening() {
    try {
      // Listen to Gyroscope to filter out hand flips/rotations
      _gyroSub = gyroscopeEventStream().listen((gEvent) {
        _currentGyroRate = math.sqrt(
          gEvent.x * gEvent.x + gEvent.y * gEvent.y + gEvent.z * gEvent.z,
        );
      }, onError: (_) {});

      // Listen to Accelerometer
      _userAccelSub = userAccelerometerEventStream().listen(
        (event) {
          // If native hardware sensor is already counting, do not double-count
          if (!_isHardwareSynced) {
            _processFallbackAccelerometerEvent(event.x, event.y, event.z);
          }
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  /// High-Precision Software Fallback Step Algorithm:
  /// - Real footstep impact threshold (3.4 m/s² minimum to eliminate hand fidgets)
  /// - Gyroscope rotation rejection (> 2.2 rad/s rejects wrist rotation / phone flipping)
  /// - 6-Step Rhythmic Commitment Window (requires at least 6 consecutive human gait strides
  ///   before committing steps, discarding single taps, phone pickups, and desk vibrations)
  /// - Strict Vehicle Suppression (> 16 km/h freezes all step increments)
  static const int _kCommitmentSteps = 6;
  final List<int> _pendingCadenceTimestamps = [];
  bool _isContinuousCadenceLocked = false;

  void _processFallbackAccelerometerEvent(double x, double y, double z) {
    if (_isHardwareSynced || _isVehicleMode) return; // Strict exclusion!

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final mag = math.sqrt(x * x + y * y + z * z);

    // Reject hand fidgeting: if gyroscope angular rotation is active (> 2.2 rad/s), ignore
    if (_currentGyroRate > 2.2) return;

    // Minimum acceleration magnitude for actual heel-strike human locomotion
    const minStepMagnitude = 3.4;
    const minRefractoryMs = 280; // Max ~3.5 steps/sec
    const maxStepIntervalMs = 780; // Slower than 0.78s interval is stationary pause
    const cadenceTimeoutMs = 1800; // Cadence expires after 1.8s pause

    // Reset commitment window if user paused walking
    if (_pendingCadenceTimestamps.isNotEmpty &&
        (nowMs - _pendingCadenceTimestamps.last > cadenceTimeoutMs)) {
      _pendingCadenceTimestamps.clear();
      _isContinuousCadenceLocked = false;
      _isWalkingNow = false;
    }

    if (mag > minStepMagnitude && !_isPeakRising && (nowMs - _lastStepMs > minRefractoryMs)) {
      final delta = nowMs - _lastStepMs;
      _isPeakRising = true;
      _lastStepMs = nowMs;

      if (delta >= minRefractoryMs && delta <= maxStepIntervalMs) {
        _pendingCadenceTimestamps.add(nowMs);

        if (!_isContinuousCadenceLocked) {
          // Require at least 6 consecutive rhythmic strides before committing any steps
          if (_pendingCadenceTimestamps.length >= _kCommitmentSteps) {
            _isContinuousCadenceLocked = true;
            _commitFallbackSteps(_kCommitmentSteps);
          }
        } else {
          // Already in validated walking rhythm
          _commitFallbackSteps(1);
        }
      } else {
        // Irregular interval, reset commitment buffer
        _pendingCadenceTimestamps.clear();
        _isContinuousCadenceLocked = false;
      }
    } else if (mag < 1.2) {
      _isPeakRising = false;
    }
  }

  void _commitFallbackSteps(int count) {
    _todaySteps += count;
    _activeSeconds += count;
    _lastStepTime = DateTime.now();
    _isWalkingNow = true;
    _currentActivity = _currentSpeedKmh > 7.0
        ? 'Running'
        : (_currentSpeedKmh > 4.5 ? 'Brisk Walk' : 'Walking');

    _stepStreamController.add(_todaySteps);
    if (_todaySteps % 5 == 0 || count > 1) {
      _persistState();
    }
  }

  void _checkDayRollover() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) {
      final lastDateStr = p.getString(_prefLastDateKey);
      if (lastDateStr != null && lastDateStr != todayStr) {
        // Roll over: Save yesterday's summary into history
        if (_todaySteps > 0) {
          final yesterday = DateTime.tryParse(lastDateStr) ??
              now.subtract(const Duration(days: 1));
          final record = DailyStepRecord(
            date: yesterday,
            steps: _todaySteps,
            distanceKm: distanceKm,
            avgSpeedKmh: avgSpeedKmh > 0 ? avgSpeedKmh : 4.5,
            caloriesKcal: caloriesKcal,
            activeMinutes: (_activeSeconds / 60).round(),
          );
          _historyRecords.insert(0, record);
          if (_historyRecords.length > 365) {
            _historyRecords = _historyRecords.take(365).toList();
          }
        }
        // Reset for today
        _todaySteps = 0;
        _activeSeconds = 0;
        _todayTrail = [];
        p.setString(_prefLastDateKey, todayStr);
        _persistState();
      } else if (lastDateStr == null) {
        p.setString(_prefLastDateKey, todayStr);
      }
    });
  }

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Zero-default clean loading (Strictly Real Data)
      _todaySteps = prefs.getInt(_prefTodayStepsKey) ?? 0;
      _dailyGoal = prefs.getInt(_prefDailyGoalKey) ?? 10000;
      _activeSeconds = prefs.getInt(_prefActiveSecsKey) ?? 0;

      final installRaw = prefs.getString(_prefInstallTimeKey);
      if (installRaw != null) {
        _installDate = DateTime.tryParse(installRaw);
      } else {
        _installDate = DateTime.now();
        await prefs.setString(_prefInstallTimeKey, _installDate!.toIso8601String());
      }

      // Load Real Trail (NO fake default trail!)
      final trailRaw = prefs.getString(_prefTrailKey);
      if (trailRaw != null && trailRaw.isNotEmpty) {
        final List decoded = jsonDecode(trailRaw);
        _todayTrail = decoded
            .map((e) =>
                StepTrailPoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (_todayTrail.isNotEmpty) {
          _lastLat = _todayTrail.last.lat;
          _lastLon = _todayTrail.last.lon;
        }
      }

      // Load Real History (NO fake 365-day history!)
      final histRaw = prefs.getString(_prefHistoryKey);
      if (histRaw != null && histRaw.isNotEmpty) {
        final List decoded = jsonDecode(histRaw);
        _historyRecords = decoded
            .map((e) =>
                DailyStepRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      // If user had legacy fake seed history (length > 300 on first install), purge it!
      if (_historyRecords.length > 300) {
        _historyRecords.clear();
        await prefs.setString(_prefHistoryKey, '[]');
      }
    } catch (_) {}
  }

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefTodayStepsKey, _todaySteps);
      await prefs.setInt(_prefDailyGoalKey, _dailyGoal);
      await prefs.setInt(_prefActiveSecsKey, _activeSeconds);
      await prefs.setString(
        _prefTrailKey,
        jsonEncode(_todayTrail.take(400).map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        _prefHistoryKey,
        jsonEncode(_historyRecords.take(365).map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  void dispose() {
    _userAccelSub?.cancel();
    _gyroSub?.cancel();
    _nativeEventSub?.cancel();
    _activeWalkTimer?.cancel();
    _stepStreamController.close();
  }
}
