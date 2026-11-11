import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum CompassAccuracy {
  uncalibrated,
  low,
  medium,
  high,
}

class CompassReading {
  final double heading; // 0.0 to 359.9 degrees
  final String cardinal; // N, NE, E, SE, S, SW, W, NW
  final double pitch; // Front/Back tilt in degrees
  final double roll; // Left/Right tilt in degrees
  final bool isLevel; // True if device is practically horizontal
  final bool isUpright; // True if device is held upright / vertical (> 28° tilt)
  final double magneticStrength; // In microTesla (uT)
  final double gyroZ; // Angular velocity (deg/s) around Z axis
  final CompassAccuracy accuracy;
  final bool isHardwareSynced;

  const CompassReading({
    required this.heading,
    required this.cardinal,
    required this.pitch,
    required this.roll,
    required this.isLevel,
    required this.isUpright,
    required this.magneticStrength,
    required this.gyroZ,
    required this.accuracy,
    required this.isHardwareSynced,
  });

  static const empty = CompassReading(
    heading: 0.0,
    cardinal: 'North',
    pitch: 0.0,
    roll: 0.0,
    isLevel: true,
    isUpright: false,
    magneticStrength: 45.0,
    gyroZ: 0.0,
    accuracy: CompassAccuracy.medium,
    isHardwareSynced: false,
  );
}

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final StreamController<CompassReading> _readingController =
      StreamController<CompassReading>.broadcast();

  Stream<CompassReading> get readingStream => _readingController.stream;

  // Sensor state caches
  double _ax = 0, _ay = 0, _az = 9.8;
  double _mx = 0, _my = 30, _mz = -25;
  double _gz = 0; // Gyroscope Z rotation in rad/s

  // Magnetometer calibration bounds (hard-iron compensation)
  double _minMx = -35.0, _maxMx = 35.0;
  double _minMy = -35.0, _maxMy = 35.0;
  double _minMz = -45.0, _maxMz = 25.0;

  double _fusedHeading = 0.0;
  double _filteredPitch = 0.0;
  double _filteredRoll = 0.0;
  DateTime? _lastTimestamp;
  bool _hasReceivedHardwareEvent = false;

  bool _isListening = false;
  bool get isListening => _isListening;

  void recalibrate() {
    _minMx = _mx - 25.0;
    _maxMx = _mx + 25.0;
    _minMy = _my - 25.0;
    _maxMy = _my + 25.0;
    _minMz = _mz - 25.0;
    _maxMz = _mz + 25.0;
    _fusedHeading = 0.0;
  }

  void start() {
    if (_isListening) return;
    _isListening = true;

    try {
      // 1. Accelerometer stream (for pitch, roll, and gravity orientation)
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          _ax = event.x;
          _ay = event.y;
          _az = event.z;
          _hasReceivedHardwareEvent = true;
          _processSensorFusion();
        },
        onError: (err) {
          debugPrint('Accelerometer stream error: $err');
        },
      );

      // 2. Magnetometer stream (for magnetic vector with hard-iron calibration)
      _magSub = magnetometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          // Dynamic hard-iron offset tracking
          _minMx = math.min(_minMx, event.x);
          _maxMx = math.max(_maxMx, event.x);
          _minMy = math.min(_minMy, event.y);
          _maxMy = math.max(_maxMy, event.y);
          _minMz = math.min(_minMz, event.z);
          _maxMz = math.max(_maxMz, event.z);

          final double offX = (_maxMx + _minMx) / 2.0;
          final double offY = (_maxMy + _minMy) / 2.0;
          final double offZ = (_maxMz + _minMz) / 2.0;

          _mx = event.x - offX;
          _my = event.y - offY;
          _mz = event.z - offZ;

          _hasReceivedHardwareEvent = true;
          _processSensorFusion();
        },
        onError: (err) {
          debugPrint('Magnetometer stream error: $err');
        },
      );

      // 3. Gyroscope stream (for angular velocity and jitter reduction)
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          _gz = event.z;
          _hasReceivedHardwareEvent = true;
        },
        onError: (err) {
          debugPrint('Gyroscope stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize sensors: $e');
    }
  }

  void stop() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _magSub = null;
    _gyroSub = null;
    _isListening = false;
    _lastTimestamp = null;
  }

  // Tilt-Compensated Sensor Fusion
  void _processSensorFusion() {
    final now = DateTime.now();
    double dt = 0.02; // default 20ms
    if (_lastTimestamp != null) {
      dt = now.difference(_lastTimestamp!).inMicroseconds / 1000000.0;
      if (dt <= 0 || dt > 0.5) dt = 0.02;
    }
    _lastTimestamp = now;

    // 1. Calculate Pitch and Roll from Accelerometer with low-pass filter
    final double gNorm = math.sqrt(_ax * _ax + _ay * _ay + _az * _az);
    final double gx = _ax / (gNorm > 0.001 ? gNorm : 9.8);
    final double gy = _ay / (gNorm > 0.001 ? gNorm : 9.8);
    final double gz = _az / (gNorm > 0.001 ? gNorm : 9.8);

    final double pitchRad = math.asin((-gy).clamp(-1.0, 1.0));
    final double rollRad = math.atan2(gx, gz);

    final double rawPitchDeg = pitchRad * (180.0 / math.pi);
    final double rawRollDeg = rollRad * (180.0 / math.pi);

    // Exponential smoothing
    _filteredPitch = _filteredPitch * 0.70 + rawPitchDeg * 0.30;
    _filteredRoll = _filteredRoll * 0.70 + rawRollDeg * 0.30;

    final double pRad = _filteredPitch * (math.pi / 180.0);
    final double rRad = _filteredRoll * (math.pi / 180.0);

    // 2. Accurate Tilt-Compensated Magnetic Field Components
    final double cosP = math.cos(pRad);
    final double sinP = math.sin(pRad);
    final double cosR = math.cos(rRad);
    final double sinR = math.sin(rRad);

    final double xh = _mx * cosR + _mz * sinR;
    final double yh = _mx * sinP * sinR + _my * cosP - _mz * sinP * cosR;

    // Magnetic Azimuth in degrees [0, 360)
    double rawMagHeading = math.atan2(-xh, yh) * (180.0 / math.pi);
    if (rawMagHeading < 0) rawMagHeading += 360.0;

    // 3. Gyroscope + Magnetometer Complementary Filter
    final double gyroDeltaDeg = -_gz * dt * (180.0 / math.pi);

    // Integrate gyro with previous fused heading
    double gyroHeading = _fusedHeading + gyroDeltaDeg;
    if (gyroHeading < 0) gyroHeading += 360.0;
    if (gyroHeading >= 360.0) gyroHeading -= 360.0;

    // Shortest circular wrap distance
    double diff = rawMagHeading - gyroHeading;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;

    // Fused heading: 88% smooth gyro + 12% absolute magnetic anchor
    _fusedHeading = gyroHeading + (diff * 0.12);
    if (_fusedHeading < 0) _fusedHeading += 360.0;
    if (_fusedHeading >= 360.0) _fusedHeading -= 360.0;

    // 4. Magnetic Field Strength (B = sqrt(x^2 + y^2 + z^2))
    final double magStrength = math.sqrt(_mx * _mx + _my * _my + _mz * _mz);

    // 5. Accuracy Assessment based on typical Earth field (25 to 65 uT)
    CompassAccuracy accuracy = CompassAccuracy.medium;
    if (magStrength >= 25.0 && magStrength <= 70.0) {
      accuracy = CompassAccuracy.high;
    } else if (magStrength < 12.0 || magStrength > 115.0) {
      accuracy = CompassAccuracy.low;
    }

    // Phone is upright/straight if pitch is tilted more than 28° from flat
    final bool isUpright = _filteredPitch.abs() > 28.0;
    final bool isLevel = _filteredPitch.abs() < 2.0 && _filteredRoll.abs() < 2.0;

    final reading = CompassReading(
      heading: _fusedHeading,
      cardinal: _getCardinalDirection(_fusedHeading),
      pitch: _filteredPitch,
      roll: _filteredRoll,
      isLevel: isLevel,
      isUpright: isUpright,
      magneticStrength: magStrength,
      gyroZ: _gz * (180.0 / math.pi),
      accuracy: accuracy,
      isHardwareSynced: _hasReceivedHardwareEvent,
    );

    _readingController.add(reading);
  }

  String _getCardinalDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'North';
    if (heading >= 22.5 && heading < 67.5) return 'Northeast';
    if (heading >= 67.5 && heading < 112.5) return 'East';
    if (heading >= 112.5 && heading < 157.5) return 'Southeast';
    if (heading >= 157.5 && heading < 202.5) return 'South';
    if (heading >= 202.5 && heading < 247.5) return 'Southwest';
    if (heading >= 247.5 && heading < 292.5) return 'West';
    return 'Northwest';
  }
}
