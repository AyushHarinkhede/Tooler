import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// TOOLER REAL-TIME WEATHER, LOCATION & AIR QUALITY (AQI) TELEMETRY SERVICE
/// - Auto-syncs location, temperature, condition, day/night status, and AQI
/// - 5-minute background auto-refresh with SharedPreferences offline cache
/// - Zero third-party paid keys: Uses standard geolocation & Open-Meteo API
/// ---------------------------------------------------------------------------

class WeatherTelemetryData {
  final String city;
  final String country;
  final double temperatureC;
  final int weatherCode;
  final bool isDay;
  final String condition;
  final int aqi;
  final String aqiStatus;
  final Color aqiColor;
  final DateTime lastSync;

  const WeatherTelemetryData({
    required this.city,
    required this.country,
    required this.temperatureC,
    required this.weatherCode,
    required this.isDay,
    required this.condition,
    required this.aqi,
    required this.aqiStatus,
    required this.aqiColor,
    required this.lastSync,
  });

  factory WeatherTelemetryData.defaultData() {
    final now = DateTime.now();
    final hour = now.hour;
    final isDay = hour >= 6 && hour < 19;
    return WeatherTelemetryData(
      city: 'Live Location',
      country: 'IN',
      temperatureC: 28.0,
      weatherCode: 1,
      isDay: isDay,
      condition: isDay ? 'Sunny' : 'Clear Night',
      aqi: 72,
      aqiStatus: 'Moderate',
      aqiColor: const Color(0xFFF59E0B),
      lastSync: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'country': country,
        'temperatureC': temperatureC,
        'weatherCode': weatherCode,
        'isDay': isDay,
        'condition': condition,
        'aqi': aqi,
        'aqiStatus': aqiStatus,
        'aqiColor': aqiColor.toARGB32(),
        'lastSync': lastSync.toIso8601String(),
      };

  factory WeatherTelemetryData.fromJson(Map<String, dynamic> json) {
    return WeatherTelemetryData(
      city: json['city'] as String? ?? 'Live Location',
      country: json['country'] as String? ?? 'IN',
      temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 28.0,
      weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 1,
      isDay: json['isDay'] as bool? ?? true,
      condition: json['condition'] as String? ?? 'Clear',
      aqi: (json['aqi'] as num?)?.toInt() ?? 72,
      aqiStatus: json['aqiStatus'] as String? ?? 'Moderate',
      aqiColor: Color((json['aqiColor'] as num?)?.toInt() ?? 0xFFF59E0B),
      lastSync: DateTime.tryParse(json['lastSync'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class WeatherTelemetryService extends ChangeNotifier {
  static final WeatherTelemetryService _instance = WeatherTelemetryService._internal();
  factory WeatherTelemetryService() => _instance;
  WeatherTelemetryService._internal();

  static const String _cacheKey = 'tooler_cached_weather_telemetry_v1';

  WeatherTelemetryData _data = WeatherTelemetryData.defaultData();
  WeatherTelemetryData get data => _data;

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  Timer? _syncTimer;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Immediately restore cached telemetry for 0ms startup
    await _loadFromCache();

    // 2. Fetch fresh live data
    unawaited(fetchTelemetry(silent: true));

    // 3. Keep syncing every 5 minutes in background
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchTelemetry(silent: true);
    });
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
        _data = WeatherTelemetryData.fromJson(map);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_data.toJson());
      await prefs.setString(_cacheKey, raw);
    } catch (_) {}
  }

  Future<void> fetchTelemetry({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!silent) notifyListeners();

    try {
      // Step 1: Geolocation by IP
      String city = _data.city;
      String country = _data.country;
      double lat = 21.146;
      double lon = 79.0983;

      final ipGeoJson = await _httpGetJson('http://ip-api.com/json/');
      if (ipGeoJson != null && ipGeoJson['status'] == 'success') {
        city = (ipGeoJson['city'] as String?) ?? city;
        country = (ipGeoJson['countryCode'] as String?) ?? country;
        final rawLat = (ipGeoJson['lat'] as num?)?.toDouble();
        final rawLon = (ipGeoJson['lon'] as num?)?.toDouble();
        if (rawLat != null && rawLon != null) {
          lat = rawLat;
          lon = rawLon;
        }
      }

      // Step 2: Open-Meteo Real-Time Weather
      final weatherUrl =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,is_day,weather_code';
      final weatherJson = await _httpGetJson(weatherUrl);

      double tempC = _data.temperatureC;
      int weatherCode = _data.weatherCode;
      bool isDay = _data.isDay;

      if (weatherJson != null && weatherJson.containsKey('current')) {
        final current = weatherJson['current'] as Map<String, dynamic>;
        tempC = (current['temperature_2m'] as num?)?.toDouble() ?? tempC;
        weatherCode = (current['weather_code'] as num?)?.toInt() ?? weatherCode;
        final isDayVal = (current['is_day'] as num?)?.toInt() ?? 1;
        isDay = isDayVal == 1;
      }

      // Step 3: Open-Meteo Real-Time Air Quality (AQI)
      final aqiUrl =
          'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&current=us_aqi,pm2_5,pm10';
      final aqiJson = await _httpGetJson(aqiUrl);

      int aqi = _data.aqi;
      if (aqiJson != null && aqiJson.containsKey('current')) {
        final currentAqi = aqiJson['current'] as Map<String, dynamic>;
        aqi = (currentAqi['us_aqi'] as num?)?.toInt() ?? aqi;
      }

      // Condition name and AQI classification
      final condition = _getWeatherDescription(weatherCode, isDay);
      final aqiStatus = _getAqiStatus(aqi);
      final aqiColor = _getAqiColor(aqi);

      _data = WeatherTelemetryData(
        city: city,
        country: country,
        temperatureC: tempC,
        weatherCode: weatherCode,
        isDay: isDay,
        condition: condition,
        aqi: aqi,
        aqiStatus: aqiStatus,
        aqiColor: aqiColor,
        lastSync: DateTime.now(),
      );

      await _saveToCache();
    } catch (_) {
      // Fallback preserves cached data gracefully
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _httpGetJson(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
    return null;
  }

  String _getWeatherDescription(int code, bool isDay) {
    switch (code) {
      case 0:
        return isDay ? 'Clear Sky' : 'Clear Night';
      case 1:
        return isDay ? 'Mainly Sunny' : 'Clear Night';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Fog / Haze';
      case 51:
      case 53:
      case 55:
        return 'Light Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rainy';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return isDay ? 'Sunny' : 'Clear';
    }
  }

  String _getAqiStatus(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF10B981); // Green
    if (aqi <= 100) return const Color(0xFFF59E0B); // Amber / Yellow
    if (aqi <= 150) return const Color(0xFFF97316); // Orange
    if (aqi <= 200) return const Color(0xFFEF4444); // Red
    if (aqi <= 300) return const Color(0xFF8B5CF6); // Purple
    return const Color(0xFF881337); // Deep Maroon
  }

  IconData getWeatherIcon(int code, bool isDay) {
    switch (code) {
      case 0:
      case 1:
        return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
      case 2:
      case 3:
        return isDay ? Icons.cloud_queue_rounded : Icons.nights_stay_rounded;
      case 45:
      case 48:
        return Icons.blur_on_rounded;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
        return Icons.water_drop_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
        return Icons.ac_unit_rounded;
      case 80:
      case 81:
      case 82:
        return Icons.umbrella_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
