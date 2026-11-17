import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// TOOLER REAL-TIME WEATHER, LOCATION, MOON PHASE & AQI TELEMETRY SERVICE
/// - Auto-syncs location, temperature, condition, day/night status, and AQI
/// - Astronomical precision Moon Phase calculation (Full, Crescent, Quarter, etc.)
/// - 7-day past historical telemetry + 7-day future weather forecasts
/// - 5-minute background auto-refresh with SharedPreferences offline cache
/// - Zero third-party paid keys: Uses standard geolocation & Open-Meteo API
/// ---------------------------------------------------------------------------

class MoonPhaseInfo {
  final double phase; // 0.0 to 1.0 (0.0 New Moon, 0.5 Full Moon)
  final String phaseName;
  final String hindiName;
  final double illuminationPercent;
  final double ageDays;

  const MoonPhaseInfo({
    required this.phase,
    required this.phaseName,
    required this.hindiName,
    required this.illuminationPercent,
    required this.ageDays,
  });

  factory MoonPhaseInfo.calculate([DateTime? targetDate]) {
    final date = (targetDate ?? DateTime.now()).toUtc();
    // Reference new moon epoch: 2000-01-06 18:14 UTC
    final refEpoch = DateTime.utc(2000, 1, 6, 18, 14);
    final diffSeconds = date.difference(refEpoch).inSeconds;
    final diffDays = diffSeconds / 86400.0;
    const synodicMonth = 29.530588853;
    final cycles = diffDays / synodicMonth;
    final phase = cycles - cycles.floor(); // 0.0 to 1.0
    final ageDays = phase * synodicMonth;
    final illuminationPercent = ((1.0 - math.cos(phase * 2 * math.pi)) / 2.0) * 100.0;

    String name;
    String hindi;
    if (phase < 0.03 || phase >= 0.97) {
      name = 'New Moon';
      hindi = 'Amavasya (अमावस्या)';
    } else if (phase < 0.22) {
      name = 'Waxing Crescent';
      hindi = 'Shukla Paksha (शुक्ल प्रतिपदा)';
    } else if (phase < 0.28) {
      name = 'First Quarter';
      hindi = 'Ashtami (शुक्ल अष्टमी)';
    } else if (phase < 0.47) {
      name = 'Waxing Gibbous';
      hindi = 'Ekadashi (शुक्ल एकादशी)';
    } else if (phase < 0.53) {
      name = 'Full Moon';
      hindi = 'Purnima (पूर्णिमा)';
    } else if (phase < 0.72) {
      name = 'Waning Gibbous';
      hindi = 'Krishna Paksha (कृष्ण पक्ष)';
    } else if (phase < 0.78) {
      name = 'Third Quarter';
      hindi = 'Krishna Ashtami (कृष्ण अष्टमी)';
    } else {
      name = 'Waning Crescent';
      hindi = 'Krishna Chaturdashi (कृष्ण पक्ष)';
    }

    return MoonPhaseInfo(
      phase: phase,
      phaseName: name,
      hindiName: hindi,
      illuminationPercent: illuminationPercent,
      ageDays: ageDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'phaseName': phaseName,
        'hindiName': hindiName,
        'illuminationPercent': illuminationPercent,
        'ageDays': ageDays,
      };

  factory MoonPhaseInfo.fromJson(Map<String, dynamic> json) {
    return MoonPhaseInfo(
      phase: (json['phase'] as num?)?.toDouble() ?? 0.0,
      phaseName: json['phaseName'] as String? ?? 'Full Moon',
      hindiName: json['hindiName'] as String? ?? 'Purnima (पूर्णिमा)',
      illuminationPercent: (json['illuminationPercent'] as num?)?.toDouble() ?? 100.0,
      ageDays: (json['ageDays'] as num?)?.toDouble() ?? 14.7,
    );
  }
}

class DailyForecastItem {
  final DateTime date;
  final int weatherCode;
  final double maxTempC;
  final double minTempC;
  final double maxUv;
  final int precipProb;
  final double maxWindKmH;
  final String sunrise;
  final String sunset;
  final bool isPast;
  final bool isToday;

  const DailyForecastItem({
    required this.date,
    required this.weatherCode,
    required this.maxTempC,
    required this.minTempC,
    required this.maxUv,
    required this.precipProb,
    required this.maxWindKmH,
    required this.sunrise,
    required this.sunset,
    required this.isPast,
    required this.isToday,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weatherCode': weatherCode,
        'maxTempC': maxTempC,
        'minTempC': minTempC,
        'maxUv': maxUv,
        'precipProb': precipProb,
        'maxWindKmH': maxWindKmH,
        'sunrise': sunrise,
        'sunset': sunset,
        'isPast': isPast,
        'isToday': isToday,
      };

  factory DailyForecastItem.fromJson(Map<String, dynamic> json) {
    return DailyForecastItem(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 1,
      maxTempC: (json['maxTempC'] as num?)?.toDouble() ?? 30.0,
      minTempC: (json['minTempC'] as num?)?.toDouble() ?? 20.0,
      maxUv: (json['maxUv'] as num?)?.toDouble() ?? 5.0,
      precipProb: (json['precipProb'] as num?)?.toInt() ?? 0,
      maxWindKmH: (json['maxWindKmH'] as num?)?.toDouble() ?? 10.0,
      sunrise: json['sunrise'] as String? ?? '06:00',
      sunset: json['sunset'] as String? ?? '18:00',
      isPast: json['isPast'] as bool? ?? false,
      isToday: json['isToday'] as bool? ?? false,
    );
  }
}

class HourlyForecastItem {
  final DateTime time;
  final int hour; // 0..23
  final double tempC;
  final int weatherCode;
  final int precipProb;
  final bool isDay;
  final bool isNow;

  const HourlyForecastItem({
    required this.time,
    required this.hour,
    required this.tempC,
    required this.weatherCode,
    required this.precipProb,
    required this.isDay,
    this.isNow = false,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'hour': hour,
        'tempC': tempC,
        'weatherCode': weatherCode,
        'precipProb': precipProb,
        'isDay': isDay,
        'isNow': isNow,
      };

  factory HourlyForecastItem.fromJson(Map<String, dynamic> json) {
    return HourlyForecastItem(
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      hour: (json['hour'] as num?)?.toInt() ?? 12,
      tempC: (json['tempC'] as num?)?.toDouble() ?? 25.0,
      weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 1,
      precipProb: (json['precipProb'] as num?)?.toInt() ?? 0,
      isDay: json['isDay'] as bool? ?? true,
      isNow: json['isNow'] as bool? ?? false,
    );
  }
}

class WeatherTelemetryData {
  final String city;
  final String country;
  final double temperatureC;
  final double apparentTempC;
  final int weatherCode;
  final bool isDay;
  final String condition;
  final int aqi;
  final String aqiStatus;
  final Color aqiColor;
  final double humidity;
  final double windSpeedKmH;
  final double uvIndex;
  final double pressureHpa;
  final double pm25;
  final double pm10;
  final String sunriseToday;
  final String sunsetToday;
  final List<DailyForecastItem> dailyList;
  final List<HourlyForecastItem> hourlyList;
  final MoonPhaseInfo moonPhase;
  final DateTime lastSync;

  const WeatherTelemetryData({
    required this.city,
    required this.country,
    required this.temperatureC,
    required this.apparentTempC,
    required this.weatherCode,
    required this.isDay,
    required this.condition,
    required this.aqi,
    required this.aqiStatus,
    required this.aqiColor,
    required this.humidity,
    required this.windSpeedKmH,
    required this.uvIndex,
    required this.pressureHpa,
    required this.pm25,
    required this.pm10,
    required this.sunriseToday,
    required this.sunsetToday,
    required this.dailyList,
    required this.hourlyList,
    required this.moonPhase,
    required this.lastSync,
  });

  factory WeatherTelemetryData.defaultData() {
    final now = DateTime.now();
    final hour = now.hour;
    final isDay = hour >= 6 && hour < 19;
    final moon = MoonPhaseInfo.calculate(now);

    final List<DailyForecastItem> defaultDaily = List.generate(14, (index) {
      final d = now.subtract(Duration(days: 7 - index));
      final isPast = index < 7;
      final isToday = index == 7;
      return DailyForecastItem(
        date: d,
        weatherCode: isToday ? 1 : ((index % 3 == 0) ? 2 : 1),
        maxTempC: 30.0 + (index % 4) - 2,
        minTempC: 19.0 + (index % 3) - 1,
        maxUv: 6.0,
        precipProb: index == 6 ? 35 : 5,
        maxWindKmH: 10.0 + (index % 5),
        sunrise: '06:15',
        sunset: '17:45',
        isPast: isPast,
        isToday: isToday,
      );
    });

    final List<HourlyForecastItem> defaultHourly = List.generate(24, (index) {
      final h = (now.hour + index) % 24;
      final isDayTime = h >= 6 && h < 19;
      final tempOffset = math.sin((h - 5) / 24.0 * math.pi * 2) * 5.5;
      return HourlyForecastItem(
        time: now.add(Duration(hours: index)),
        hour: h,
        tempC: (27.0 + tempOffset).clamp(18.0, 38.0),
        weatherCode: isDayTime ? 1 : 0,
        precipProb: index == 4 ? 20 : 0,
        isDay: isDayTime,
        isNow: index == 0,
      );
    });

    return WeatherTelemetryData(
      city: 'Live Location',
      country: 'IN',
      temperatureC: 28.0,
      apparentTempC: 29.0,
      weatherCode: 1,
      isDay: isDay,
      condition: isDay ? 'Sunny' : 'Clear Night',
      aqi: 72,
      aqiStatus: 'Moderate',
      aqiColor: const Color(0xFFF59E0B),
      humidity: 52.0,
      windSpeedKmH: 9.5,
      uvIndex: 5.5,
      pressureHpa: 1012.0,
      pm25: 22.4,
      pm10: 45.1,
      sunriseToday: '06:15 AM',
      sunsetToday: '05:45 PM',
      dailyList: defaultDaily,
      hourlyList: defaultHourly,
      moonPhase: moon,
      lastSync: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'country': country,
        'temperatureC': temperatureC,
        'apparentTempC': apparentTempC,
        'weatherCode': weatherCode,
        'isDay': isDay,
        'condition': condition,
        'aqi': aqi,
        'aqiStatus': aqiStatus,
        'aqiColor': aqiColor.toARGB32(),
        'humidity': humidity,
        'windSpeedKmH': windSpeedKmH,
        'uvIndex': uvIndex,
        'pressureHpa': pressureHpa,
        'pm25': pm25,
        'pm10': pm10,
        'sunriseToday': sunriseToday,
        'sunsetToday': sunsetToday,
        'dailyList': dailyList.map((e) => e.toJson()).toList(),
        'hourlyList': hourlyList.map((e) => e.toJson()).toList(),
        'moonPhase': moonPhase.toJson(),
        'lastSync': lastSync.toIso8601String(),
      };

  factory WeatherTelemetryData.fromJson(Map<String, dynamic> json) {
    final dailyRaw = json['dailyList'] as List<dynamic>?;
    List<DailyForecastItem> daily = [];
    if (dailyRaw != null) {
      daily = dailyRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => DailyForecastItem.fromJson(m))
          .toList();
    }
    if (daily.isEmpty) {
      daily = WeatherTelemetryData.defaultData().dailyList;
    }

    final hourlyRaw = json['hourlyList'] as List<dynamic>?;
    List<HourlyForecastItem> hourly = [];
    if (hourlyRaw != null) {
      hourly = hourlyRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => HourlyForecastItem.fromJson(m))
          .toList();
    }
    if (hourly.isEmpty) {
      hourly = WeatherTelemetryData.defaultData().hourlyList;
    }

    final moonJson = json['moonPhase'] as Map<String, dynamic>?;
    final moon = moonJson != null ? MoonPhaseInfo.fromJson(moonJson) : MoonPhaseInfo.calculate();

    return WeatherTelemetryData(
      city: json['city'] as String? ?? 'Live Location',
      country: json['country'] as String? ?? 'IN',
      temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 28.0,
      apparentTempC: (json['apparentTempC'] as num?)?.toDouble() ?? 29.0,
      weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 1,
      isDay: json['isDay'] as bool? ?? true,
      condition: json['condition'] as String? ?? 'Clear',
      aqi: (json['aqi'] as num?)?.toInt() ?? 72,
      aqiStatus: json['aqiStatus'] as String? ?? 'Moderate',
      aqiColor: Color((json['aqiColor'] as num?)?.toInt() ?? 0xFFF59E0B),
      humidity: (json['humidity'] as num?)?.toDouble() ?? 52.0,
      windSpeedKmH: (json['windSpeedKmH'] as num?)?.toDouble() ?? 9.5,
      uvIndex: (json['uvIndex'] as num?)?.toDouble() ?? 5.5,
      pressureHpa: (json['pressureHpa'] as num?)?.toDouble() ?? 1012.0,
      pm25: (json['pm25'] as num?)?.toDouble() ?? 22.4,
      pm10: (json['pm10'] as num?)?.toDouble() ?? 45.1,
      sunriseToday: json['sunriseToday'] as String? ?? '06:15 AM',
      sunsetToday: json['sunsetToday'] as String? ?? '05:45 PM',
      dailyList: daily,
      hourlyList: hourly,
      moonPhase: moon,
      lastSync: DateTime.tryParse(json['lastSync'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class WeatherTelemetryService extends ChangeNotifier {
  static final WeatherTelemetryService _instance = WeatherTelemetryService._internal();
  factory WeatherTelemetryService() => _instance;
  WeatherTelemetryService._internal();

  static const String _cacheKey = 'tooler_cached_weather_telemetry_v2';

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

      // Step 2: Open-Meteo Comprehensive Weather (Current, Hourly 24h, Past 7 days, Forecast 7 days)
      final weatherUrl =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
          '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m,surface_pressure'
          '&hourly=temperature_2m,weather_code,precipitation_probability,is_day'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,wind_speed_10m_max'
          '&past_days=7&forecast_days=7';
      final weatherJson = await _httpGetJson(weatherUrl);

      double tempC = _data.temperatureC;
      double apparentTempC = _data.apparentTempC;
      int weatherCode = _data.weatherCode;
      bool isDay = _data.isDay;
      double humidity = _data.humidity;
      double windSpeed = _data.windSpeedKmH;
      double pressure = _data.pressureHpa;
      double uvIndex = _data.uvIndex;
      String sunriseToday = _data.sunriseToday;
      String sunsetToday = _data.sunsetToday;
      List<DailyForecastItem> dailyList = _data.dailyList;
      List<HourlyForecastItem> hourlyList = _data.hourlyList;

      if (weatherJson != null) {
        if (weatherJson.containsKey('current')) {
          final current = weatherJson['current'] as Map<String, dynamic>;
          tempC = (current['temperature_2m'] as num?)?.toDouble() ?? tempC;
          apparentTempC = (current['apparent_temperature'] as num?)?.toDouble() ?? tempC;
          weatherCode = (current['weather_code'] as num?)?.toInt() ?? weatherCode;
          final isDayVal = (current['is_day'] as num?)?.toInt() ?? 1;
          isDay = isDayVal == 1;
          humidity = (current['relative_humidity_2m'] as num?)?.toDouble() ?? humidity;
          windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? windSpeed;
          pressure = (current['surface_pressure'] as num?)?.toDouble() ?? pressure;
        }

        if (weatherJson.containsKey('hourly')) {
          final hourlyMap = weatherJson['hourly'] as Map<String, dynamic>;
          final hTimes = (hourlyMap['time'] as List<dynamic>?) ?? [];
          final hTemps = (hourlyMap['temperature_2m'] as List<dynamic>?) ?? [];
          final hCodes = (hourlyMap['weather_code'] as List<dynamic>?) ?? [];
          final hPrecips = (hourlyMap['precipitation_probability'] as List<dynamic>?) ?? [];
          final hIsDays = (hourlyMap['is_day'] as List<dynamic>?) ?? [];

          final now = DateTime.now();
          int startIdx = 0;
          for (int i = 0; i < hTimes.length; i++) {
            final dt = DateTime.tryParse(hTimes[i].toString());
            if (dt != null && dt.isAfter(now.subtract(const Duration(minutes: 45)))) {
              startIdx = i;
              break;
            }
          }

          final parsedHourly = <HourlyForecastItem>[];
          final endIdx = math.min(startIdx + 24, hTimes.length);
          for (int i = startIdx; i < endIdx; i++) {
            final dt = DateTime.tryParse(hTimes[i].toString()) ?? now;
            final isDayVal = (i < hIsDays.length) ? (hIsDays[i] as num).toInt() : 1;
            parsedHourly.add(HourlyForecastItem(
              time: dt,
              hour: dt.hour,
              tempC: (i < hTemps.length) ? (hTemps[i] as num).toDouble() : 25.0,
              weatherCode: (i < hCodes.length) ? (hCodes[i] as num).toInt() : 1,
              precipProb: (i < hPrecips.length) ? (hPrecips[i] as num).toInt() : 0,
              isDay: isDayVal == 1,
              isNow: i == startIdx,
            ));
          }

          if (parsedHourly.isNotEmpty) {
            hourlyList = parsedHourly;
          }
        }

        if (weatherJson.containsKey('daily')) {
          final dailyMap = weatherJson['daily'] as Map<String, dynamic>;
          final times = (dailyMap['time'] as List<dynamic>?) ?? [];
          final codes = (dailyMap['weather_code'] as List<dynamic>?) ?? [];
          final maxTemps = (dailyMap['temperature_2m_max'] as List<dynamic>?) ?? [];
          final minTemps = (dailyMap['temperature_2m_min'] as List<dynamic>?) ?? [];
          final sunrises = (dailyMap['sunrise'] as List<dynamic>?) ?? [];
          final sunsets = (dailyMap['sunset'] as List<dynamic>?) ?? [];
          final uvs = (dailyMap['uv_index_max'] as List<dynamic>?) ?? [];
          final precips = (dailyMap['precipitation_probability_max'] as List<dynamic>?) ?? [];
          final winds = (dailyMap['wind_speed_10m_max'] as List<dynamic>?) ?? [];

          final parsedDaily = <DailyForecastItem>[];
          final now = DateTime.now();
          final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          for (int i = 0; i < times.length; i++) {
            final tStr = times[i].toString();
            final d = DateTime.tryParse(tStr) ?? now;
            final isToday = tStr == todayStr || (i == 7);
            final isPast = !isToday && d.isBefore(DateTime(now.year, now.month, now.day));

            final sr = (i < sunrises.length) ? _formatTimeStr(sunrises[i].toString()) : '06:00';
            final ss = (i < sunsets.length) ? _formatTimeStr(sunsets[i].toString()) : '18:00';

            if (isToday) {
              sunriseToday = sr;
              sunsetToday = ss;
              if (i < uvs.length) {
                uvIndex = (uvs[i] as num?)?.toDouble() ?? uvIndex;
              }
            }

            parsedDaily.add(DailyForecastItem(
              date: d,
              weatherCode: (i < codes.length) ? (codes[i] as num).toInt() : 1,
              maxTempC: (i < maxTemps.length) ? (maxTemps[i] as num).toDouble() : 30.0,
              minTempC: (i < minTemps.length) ? (minTemps[i] as num).toDouble() : 20.0,
              maxUv: (i < uvs.length) ? (uvs[i] as num).toDouble() : 5.0,
              precipProb: (i < precips.length) ? (precips[i] as num).toInt() : 0,
              maxWindKmH: (i < winds.length) ? (winds[i] as num).toDouble() : 10.0,
              sunrise: sr,
              sunset: ss,
              isPast: isPast,
              isToday: isToday,
            ));
          }

          if (parsedDaily.isNotEmpty) {
            dailyList = parsedDaily;
          }
        }
      }

      // Step 3: Open-Meteo Real-Time Air Quality (AQI, PM2.5, PM10)
      final aqiUrl =
          'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&current=us_aqi,pm2_5,pm10';
      final aqiJson = await _httpGetJson(aqiUrl);

      int aqi = _data.aqi;
      double pm25 = _data.pm25;
      double pm10 = _data.pm10;
      if (aqiJson != null && aqiJson.containsKey('current')) {
        final currentAqi = aqiJson['current'] as Map<String, dynamic>;
        aqi = (currentAqi['us_aqi'] as num?)?.toInt() ?? aqi;
        pm25 = (currentAqi['pm2_5'] as num?)?.toDouble() ?? pm25;
        pm10 = (currentAqi['pm10'] as num?)?.toDouble() ?? pm10;
      }

      // Condition name, AQI classification & Astronomical Moon Phase
      final condition = _getWeatherDescription(weatherCode, isDay);
      final aqiStatus = _getAqiStatus(aqi);
      final aqiColor = _getAqiColor(aqi);
      final moon = MoonPhaseInfo.calculate(DateTime.now());

      _data = WeatherTelemetryData(
        city: city,
        country: country,
        temperatureC: tempC,
        apparentTempC: apparentTempC,
        weatherCode: weatherCode,
        isDay: isDay,
        condition: condition,
        aqi: aqi,
        aqiStatus: aqiStatus,
        aqiColor: aqiColor,
        humidity: humidity,
        windSpeedKmH: windSpeed,
        uvIndex: uvIndex,
        pressureHpa: pressure,
        pm25: pm25,
        pm10: pm10,
        sunriseToday: sunriseToday,
        sunsetToday: sunsetToday,
        dailyList: dailyList,
        hourlyList: hourlyList,
        moonPhase: moon,
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

  static String _formatTimeStr(String raw) {
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final hour = dt.hour;
        final minute = dt.minute.toString().padLeft(2, '0');
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$displayHour:$minute $ampm';
      }
    } catch (_) {}
    return raw;
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
