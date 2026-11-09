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

  double _fusedHeading = 0.0;
  double _filteredPitch = 0.0;
  double _filteredRoll = 0.0;
  DateTime? _lastTimestamp;
  bool _hasReceivedHardwareEvent = false;

  bool _isListening = false;
  bool get isListening => _isListening;

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

      // 2. Magnetometer stream (for magnetic vector)
      _magSub = magnetometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          _mx = event.x;
          _my = event.y;
          _mz = event.z;
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
    // Pitch: Rotation around X axis (nose up/down)
    // Roll: Rotation around Y axis (bank left/right)
    final double rawPitch = math.atan2(_ay, math.sqrt(_ax * _ax + _az * _az)) * (180.0 / math.pi);
    final double rawRoll = math.atan2(-_ax, _az) * (180.0 / math.pi);

    // Exponential smoothing (alpha = 0.25)
    _filteredPitch = _filteredPitch * 0.75 + rawPitch * 0.25;
    _filteredRoll = _filteredRoll * 0.75 + rawRoll * 0.25;

    final double pitchRad = _filteredPitch * (math.pi / 180.0);
    final double rollRad = _filteredRoll * (math.pi / 180.0);

    // 2. Tilt-Compensated Magnetic Field Components
    // Xh = Mx * cos(pitch) + Mz * sin(pitch)
    // Yh = Mx * sin(roll)*sin(pitch) + My * cos(roll) - Mz * sin(roll)*cos(pitch)
    final double xh = _mx * math.cos(pitchRad) + _mz * math.sin(pitchRad);
    final double yh = _mx * math.sin(rollRad) * math.sin(pitchRad) +
        _my * math.cos(rollRad) -
        _mz * math.sin(rollRad) * math.cos(pitchRad);

    // Magnetic Azimuth in degrees [0, 360)
    double rawMagHeading = math.atan2(-yh, xh) * (180.0 / math.pi);
    if (rawMagHeading < 0) rawMagHeading += 360.0;

    // 3. Gyroscope + Magnetometer Complementary Filter
    // Gyroscope delta: dt * gyroZ (in degrees)
    final double gyroDeltaDeg = -_gz * dt * (180.0 / math.pi);

    // Integrate gyro with previous fused heading
    double gyroHeading = _fusedHeading + gyroDeltaDeg;
    if (gyroHeading < 0) gyroHeading += 360.0;
    if (gyroHeading >= 360) gyroHeading -= 360.0;

    // Complementary fusion: handle circular 360 wrap
    double diff = rawMagHeading - gyroHeading;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;

    // Weight: 94% gyro (smooth, no noise) + 6% magnetometer (absolute drift correction)
    _fusedHeading = gyroHeading + (diff * 0.08);
    if (_fusedHeading < 0) _fusedHeading += 360.0;
    if (_fusedHeading >= 360) _fusedHeading -= 360.0;

    // 4. Magnetic Field Strength (B = sqrt(x^2 + y^2 + z^2))
    final double magStrength = math.sqrt(_mx * _mx + _my * _my + _mz * _mz);

    // 5. Accuracy Assessment based on typical Earth field (25 to 65 uT)
    CompassAccuracy accuracy = CompassAccuracy.medium;
    if (magStrength >= 28.0 && magStrength <= 68.0) {
      accuracy = CompassAccuracy.high;
    } else if (magStrength < 15.0 || magStrength > 110.0) {
      accuracy = CompassAccuracy.low;
    }

    final bool isLevel = _filteredPitch.abs() < 3.0 && _filteredRoll.abs() < 3.0;

    final reading = CompassReading(
      heading: _fusedHeading,
      cardinal: _getCardinalDirection(_fusedHeading),
      pitch: _filteredPitch,
      roll: _filteredRoll,
      isLevel: isLevel,
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
