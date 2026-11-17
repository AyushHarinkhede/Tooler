import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../widgets_3d/minimal_2d_illustrations.dart';
import '../services/sound_service.dart';
import '../services/weather_telemetry_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER MAUSAM & WEATHER SCREEN
/// - Real-time Weather, Location & AQI telemetry
/// - Interactive Mountain & Sky Landscape with Sun, Moon Phase, Clouds, Rain,
///   Thunder Lightning, Mountain Flood Surge & Tornado Disasters
/// - Dynamic AQI Ecology: Birds gliding & lush swaying trees vs. dry bare branches
///   and thick pollution smog
/// - Reactive Tooler Vector Character for AQI: Smiling -> Coughing -> N95 Mask
///   -> Oxygen Cylinder & Mask
/// - Past 7 Days History & Next 7 Days Forecast Charts with °C / °F toggle
/// - Astronomical Precision Moon Phase Visualizer with all 8 phases
/// - Interactive Weather & Disaster Simulator
/// ---------------------------------------------------------------------------

enum WeatherSimMode {
  live,
  sunnyDay,
  starryNight,
  cloudySky,
  rainyDeluge,
  thunderstorm,
  mountainFlood,
  tornadoTwister,
  severeSmog,
}

class WeatherScreen extends StatefulWidget {
  final StationeryTheme theme;
  const WeatherScreen({super.key, required this.theme});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  final WeatherTelemetryService _telemetry = WeatherTelemetryService();
  bool _useFahrenheit = false;
  int _forecastTab = 0; // 0: All 14 Days, 1: Past 7 Days, 2: Next 7 Days
  WeatherSimMode _simMode = WeatherSimMode.live;
  int? _simAqiOverride;

  late final AnimationController _animController;
  late final AnimationController _lightningController;
  late final AnimationController _floodController;
  late final AnimationController _twisterController;
  late final AnimationController _coughController;

  @override
  void initState() {
    super.initState();
    _telemetry.init();

    // Main ambient landscape loop (drifting clouds, sun rotation, birds, trees swaying)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    )..repeat();

    // Lightning flash burst controller
    _lightningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // Mountain flood surge waves controller
    _floodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Tornado twister vortex controller
    _twisterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Character coughing / breathing bobbing controller
    _coughController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _lightningController.dispose();
    _floodController.dispose();
    _twisterController.dispose();
    _coughController.dispose();
    super.dispose();
  }

  double _toDisplayTemp(double tempC) {
    if (_useFahrenheit) {
      return (tempC * 9.0 / 5.0) + 32.0;
    }
    return tempC;
  }

  String _tempUnit() => _useFahrenheit ? '°F' : '°C';

  // Resolve active weather characteristics based on real data or simulation override
  _EffectiveWeather _getEffectiveWeather() {
    final live = _telemetry.data;
    if (_simMode == WeatherSimMode.live) {
      final aqi = _simAqiOverride ?? live.aqi;
      final code = live.weatherCode;
      final isDay = live.isDay;
      final isRain = [51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code);
      final isThunder = [95, 96, 99].contains(code);
      final isCloudy = [2, 3, 45, 48].contains(code);
      return _EffectiveWeather(
        isDay: isDay,
        isRain: isRain,
        isThunder: isThunder,
        isCloudy: isCloudy,
        isFlood: false,
        isTwister: false,
        tempC: live.temperatureC,
        condition: live.condition,
        aqi: aqi,
        aqiStatus: _telemetryAqiStatus(aqi),
        aqiColor: _telemetryAqiColor(aqi),
        city: live.city,
        country: live.country,
      );
    }

    switch (_simMode) {
      case WeatherSimMode.sunnyDay:
        return _EffectiveWeather(
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: false,
          isFlood: false,
          isTwister: false,
          tempC: 32.0,
          condition: 'Sunny & Clear',
          aqi: _simAqiOverride ?? 38,
          aqiStatus: 'Good',
          aqiColor: const Color(0xFF10B981),
          city: 'Sunny Hills',
          country: 'Sim',
        );
      case WeatherSimMode.starryNight:
        return _EffectiveWeather(
          isDay: false,
          isRain: false,
          isThunder: false,
          isCloudy: false,
          isFlood: false,
          isTwister: false,
          tempC: 19.5,
          condition: 'Clear Moonlit Night',
          aqi: _simAqiOverride ?? 42,
          aqiStatus: 'Good',
          aqiColor: const Color(0xFF10B981),
          city: 'Moon Valley',
          country: 'Sim',
        );
      case WeatherSimMode.cloudySky:
        return _EffectiveWeather(
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: true,
          isFlood: false,
          isTwister: false,
          tempC: 24.0,
          condition: 'Dense Overcast',
          aqi: _simAqiOverride ?? 75,
          aqiStatus: 'Moderate',
          aqiColor: const Color(0xFFF59E0B),
          city: 'Cloud Ridge',
          country: 'Sim',
        );
      case WeatherSimMode.rainyDeluge:
        return _EffectiveWeather(
          isDay: false,
          isRain: true,
          isThunder: false,
          isCloudy: true,
          isFlood: false,
          isTwister: false,
          tempC: 21.0,
          condition: 'Heavy Rain Showers',
          aqi: _simAqiOverride ?? 45,
          aqiStatus: 'Good',
          aqiColor: const Color(0xFF10B981),
          city: 'Rainfall Basin',
          country: 'Sim',
        );
      case WeatherSimMode.thunderstorm:
        return _EffectiveWeather(
          isDay: false,
          isRain: true,
          isThunder: true,
          isCloudy: true,
          isFlood: false,
          isTwister: false,
          tempC: 20.0,
          condition: 'Violent Thunderstorm',
          aqi: _simAqiOverride ?? 58,
          aqiStatus: 'Moderate',
          aqiColor: const Color(0xFFF59E0B),
          city: 'Storm Peak',
          country: 'Sim',
        );
      case WeatherSimMode.mountainFlood:
        return _EffectiveWeather(
          isDay: false,
          isRain: true,
          isThunder: true,
          isCloudy: true,
          isFlood: true,
          isTwister: false,
          tempC: 18.5,
          condition: 'Mountain Flood Hazard',
          aqi: _simAqiOverride ?? 92,
          aqiStatus: 'Moderate',
          aqiColor: const Color(0xFFF59E0B),
          city: 'River Canyon',
          country: 'Alert',
        );
      case WeatherSimMode.tornadoTwister:
        return _EffectiveWeather(
          isDay: false,
          isRain: true,
          isThunder: true,
          isCloudy: true,
          isFlood: false,
          isTwister: true,
          tempC: 17.0,
          condition: 'Tornado Twister Vortex',
          aqi: _simAqiOverride ?? 145,
          aqiStatus: 'Sensitive',
          aqiColor: const Color(0xFFF97316),
          city: 'Twister Valley',
          country: 'Alert',
        );
      case WeatherSimMode.severeSmog:
        return _EffectiveWeather(
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: true,
          isFlood: false,
          isTwister: false,
          tempC: 29.0,
          condition: 'Severe Toxic Smog',
          aqi: _simAqiOverride ?? 320,
          aqiStatus: 'Hazardous',
          aqiColor: const Color(0xFF881337),
          city: 'Industrial Metro',
          country: 'Polluted',
        );
      case WeatherSimMode.live:
        return _EffectiveWeather(
          isDay: live.isDay,
          isRain: false,
          isThunder: false,
          isCloudy: false,
          isFlood: false,
          isTwister: false,
          tempC: live.temperatureC,
          condition: live.condition,
          aqi: live.aqi,
          aqiStatus: live.aqiStatus,
          aqiColor: live.aqiColor,
          city: live.city,
          country: live.country,
        );
    }
  }

  String _telemetryAqiStatus(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color _telemetryAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF10B981);
    if (aqi <= 100) return const Color(0xFFF59E0B);
    if (aqi <= 150) return const Color(0xFFF97316);
    if (aqi <= 200) return const Color(0xFFEF4444);
    if (aqi <= 300) return const Color(0xFF8B5CF6);
    return const Color(0xFF881337);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: AnimatedBuilder(
            animation: _telemetry,
            builder: (context, _) {
              final weather = _getEffectiveWeather();
              final rawData = _telemetry.data;

              return Column(
                children: [
                  // 1. App Bar Header
                  _buildTopBar(theme, isDark),

                  // 2. Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Atmospheric Animated Landscape Canvas
                          _buildAtmosphericLandscape(theme, isDark, weather, rawData),
                          const SizedBox(height: 18),

                          // Dedicated AQI Reactive Character Card
                          _buildAqiCharacterCard(theme, isDark, weather, rawData),
                          const SizedBox(height: 18),

                          // Astronomical Moon Phase Detail Card
                          _buildMoonPhaseCard(theme, isDark, rawData.moonPhase),
                          const SizedBox(height: 18),

                          // 14-Day History & Forecast Visualizer
                          _buildForecastHistoryCard(theme, isDark, rawData),
                          const SizedBox(height: 18),

                          // Detailed Atmospheric Metrics Grid
                          _buildMetricsGrid(theme, isDark, rawData, weather),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
    );
  }

  Widget _buildTopBar(StationeryTheme theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: theme.border.withValues(alpha: 0.5), width: 1.2)),
      ),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () {
              SoundService().playTap();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A30) : theme.lavenderBubble,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border, width: 1.2),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: theme.text),
            ),
          ),
          const SizedBox(width: 12),

          // Weather Icon & Title
          Expanded(
            child: Row(
              children: [
                Minimal2DIcon(
                  type: 'weather',
                  size: 34,
                  bubbleColor: theme.lavenderBubble,
                  accentColor: theme.primary,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Weather',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LIVE',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: theme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Live Forecast & Air Quality',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Single Clean Three-Dot Menu Button (Contains °C/°F Toggle, Refresh & Weather Simulator)
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A30) : theme.lavenderBubble,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border, width: 1.2),
              ),
              child: Icon(Icons.more_vert_rounded, size: 18, color: theme.text),
            ),
            tooltip: 'Weather Options',
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.border, width: 1.2),
            ),
            elevation: 8,
            onSelected: (value) {
              if (value == 'unit') {
                SoundService().playClick();
                HapticFeedback.selectionClick();
                setState(() => _useFahrenheit = !_useFahrenheit);
              } else if (value == 'refresh') {
                SoundService().playTap();
                HapticFeedback.lightImpact();
                _telemetry.fetchTelemetry();
              } else if (value == 'simulator') {
                SoundService().playSpecialClick();
                _showSimulationSheet(theme, isDark);
              } else if (value == 'reset') {
                SoundService().playTap();
                setState(() {
                  _simMode = WeatherSimMode.live;
                  _simAqiOverride = null;
                });
              }
            },
            itemBuilder: (context) => [
              // 1. Temperature Unit Toggle (°C / °F)
              PopupMenuItem<String>(
                value: 'unit',
                child: Row(
                  children: [
                    Icon(
                      Icons.thermostat_rounded,
                      size: 18,
                      color: theme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _useFahrenheit ? 'Switch to °Celsius' : 'Switch to °Fahrenheit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _useFahrenheit ? '°F' : '°C',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),

              // 2. Refresh Weather
              PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Refresh Weather',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),

              // 3. Weather Simulator
              PopupMenuItem<String>(
                value: 'simulator',
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Weather Simulator',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Reset Option (Visible when simulator mode or AQI override is active)
              if (_simMode != WeatherSimMode.live || _simAqiOverride != null) ...[
                const PopupMenuDivider(height: 1),
                PopupMenuItem<String>(
                  value: 'reset',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restore_rounded,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reset to Live Weather',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP ATMOSPHERIC LANDSCAPE CANVAS
  // ---------------------------------------------------------------------------
  Widget _buildAtmosphericLandscape(
    StationeryTheme theme,
    bool isDark,
    _EffectiveWeather weather,
    WeatherTelemetryData raw,
  ) {
    final displayTemp = _toDisplayTemp(weather.tempC).round();
    final displayUnit = _tempUnit();

    return Container(
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Custom Atmospheric Landscape CustomPainter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _animController,
                _lightningController,
                _floodController,
                _twisterController,
              ]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _AtmosphericLandscapePainter(
                    weather: weather,
                    moonPhase: raw.moonPhase,
                    animProgress: _animController.value,
                    lightningProgress: _lightningController.value,
                    floodProgress: _floodController.value,
                    twisterProgress: _twisterController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // Weather Condition & Disaster Warning Pill at Top Left
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    weather.isTwister
                        ? Icons.cyclone_rounded
                        : (weather.isFlood
                            ? Icons.flood_rounded
                            : (weather.isThunder
                                ? Icons.thunderstorm_rounded
                                : (weather.isRain
                                    ? Icons.water_drop_rounded
                                    : (weather.isDay
                                        ? Icons.wb_sunny_rounded
                                        : Icons.nightlight_round)))),
                    size: 15,
                    color: weather.isTwister || weather.isFlood
                        ? const Color(0xFFEF4444)
                        : (weather.isDay ? const Color(0xFFFBBF24) : const Color(0xFFE0E7FF)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    weather.condition,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // City Location Badge at Top Right
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.city}, ${weather.country}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Temperature & Status Display
          Align(
            alignment: const Alignment(0, -0.15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Prominent Large Animated Weather SVG Icon
                _BigAnimatedWeatherIcon(
                  weather: weather,
                  moonPhase: raw.moonPhase,
                  animProgress: _animController.value,
                  lightningProgress: _lightningController.value,
                  floodProgress: _floodController.value,
                  twisterProgress: _twisterController.value,
                ),
                const SizedBox(height: 6),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayTemp',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 68,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 2),
                      child: Text(
                        displayUnit,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'AQI ${weather.aqi} • ${weather.aqiStatus}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        offset: const Offset(0, 1.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar in Landscape: Mountain Foot High/Low & Moon Info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // High / Low
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFF87171)),
                      Text(
                        '${_toDisplayTemp(raw.dailyList.isNotEmpty ? raw.dailyList[7].maxTempC : 31).round()}°',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF60A5FA)),
                      Text(
                        '${_toDisplayTemp(raw.dailyList.isNotEmpty ? raw.dailyList[7].minTempC : 19).round()}°',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Moon Phase Indicator Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.brightness_2_rounded, size: 13, color: Color(0xFFFEF08A)),
                        const SizedBox(width: 5),
                        Text(
                          '${raw.moonPhase.phaseName} (${raw.moonPhase.illuminationPercent.round()}%)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. AQI CONTAINER WITH REACTIVE TOOLER CHARACTER
  // ---------------------------------------------------------------------------
  Widget _buildAqiCharacterCard(
    StationeryTheme theme,
    bool isDark,
    _EffectiveWeather weather,
    WeatherTelemetryData raw,
  ) {
    final aqi = weather.aqi;

    // Character state determination based on AQI:
    // <= 50: Happy, fresh air, deep breath, smiling
    // 51-100: Moderate, concerned, mild cough
    // 101-200: Poor, coughing, protective N95 mask
    // > 200: Hazardous, sad, medical oxygen mask + oxygen cylinder
        // Progressive 6-Stage Character AQI Logic:
    // 1. CleanAirBreathe:         <= 50   (Khul ke saans, fresh air breeze, green leaves)
    // 2. MildCoughAutumn:         51-100  (Coughing spasm, hand to mouth, autumn red/amber leaves)
    // 3. UnhealthyMask:           101-150 (Protective N95 mask, wilting brown leaves)
    // 4. VeryUnhealthySadMask:    151-200 (Visibly sad slumped mask pose, eye-bags, soot motes)
    // 5. HazardousOxygenCylinder: 201-300 (Medical oxygen mask + oxygen tank & coiled tube, toxic yellow smog)
    // 6. SevereToxicWrinkled:     > 300   (Deep facial wrinkles, emaciated gaunt, tremor, cylinder in red zone)
    final _AqiCharacterMood mood;
    final String advice;
    final String healthImpact;

    if (aqi <= 50) {
      mood = _AqiCharacterMood.cleanAirBreathe;
      advice = 'Ideal air quality! Perfect time for outdoor walks, jogs, and deep breathing.';
      healthImpact = 'Clean Air • No health precautions required.';
    } else if (aqi <= 100) {
      mood = _AqiCharacterMood.mildCoughAutumn;
      advice = 'Acceptable air quality. Sensitive individuals may feel throat tickles or mild coughs.';
      healthImpact = 'Moderate • Minor respiratory sensitivity & cough.';
    } else if (aqi <= 150) {
      mood = _AqiCharacterMood.unhealthyMask;
      advice = 'Unhealthy for sensitive groups! Wear a protective N95 mask when outdoors.';
      healthImpact = 'Unhealthy (Mild) • N95 mask recommended outdoors.';
    } else if (aqi <= 200) {
      mood = _AqiCharacterMood.veryUnhealthySadMask;
      advice = 'Unhealthy air quality! High particulate fatigue. Keep mask strapped and windows shut.';
      healthImpact = 'Unhealthy • High dust fatigue, wear mask & rest.';
    } else if (aqi <= 300) {
      mood = _AqiCharacterMood.hazardousOxygenCylinder;
      advice = 'Very Unhealthy & Hazardous! Dangerous pollution levels. Stay indoors with oxygen purifier support.';
      healthImpact = 'Hazardous • Heavy smog, oxygen tank support required.';
    } else {
      mood = _AqiCharacterMood.severeToxicWrinkled;
      advice = 'Severe Toxic Emergency! Critical air toxicity causing intense physical strain. Keep cylinder running & seal premises.';
      healthImpact = 'Severe Toxic • Critical hazard, extreme fatigue & exhaustion.';
    }

return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: weather.aqiColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: weather.aqiColor.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: weather.aqiColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: weather.aqiColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Air Quality Index (AQI)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: weather.aqiColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: weather.aqiColor, width: 1.2),
                ),
                child: Text(
                  weather.aqiStatus.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: weather.aqiColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Center Section: Vector Character + AQI Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dedicated Authentic Tooler Vector Character (No board, Scenario Reactive)
              AnimatedBuilder(
                animation: _coughController,
                builder: (context, _) {
                  return _AqiToolerCharacter(
                    mood: mood,
                    theme: theme,
                    isDark: isDark,
                    animValue: _coughController.value,
                    width: 118,
                    height: 130,
                  );
                },
              ),
              const SizedBox(width: 14),

              // AQI Gauge & Particulate Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$aqi',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: weather.aqiColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'US AQI',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // PM 2.5 and PM 10 Pills
                    Row(
                      children: [
                        _buildParticulatePill(theme, isDark, 'PM2.5', '${raw.pm25} µg/m³'),
                        const SizedBox(width: 6),
                        _buildParticulatePill(theme, isDark, 'PM10', '${raw.pm10} µg/m³'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Health Impact Text
                    Text(
                      healthImpact,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: theme.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Protective Advice Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : theme.lavenderBubble.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border.withValues(alpha: 0.5), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  mood == _AqiCharacterMood.cleanAirBreathe
                      ? Icons.check_circle_rounded
                      : (mood == _AqiCharacterMood.mildCoughAutumn
                          ? Icons.sentiment_neutral_rounded
                          : (mood == _AqiCharacterMood.unhealthyMask || mood == _AqiCharacterMood.veryUnhealthySadMask
                              ? Icons.masks_rounded
                              : Icons.medical_services_rounded)),
                  size: 16,
                  color: weather.aqiColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    advice,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
                  ],
      ),
    );
  }

  Widget _buildParticulatePill(StationeryTheme theme, bool isDark, String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.border.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: theme.textSecondary,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: theme.text,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ASTRONOMICAL MOON PHASE DETAIL CARD
  // ---------------------------------------------------------------------------
  Widget _buildMoonPhaseCard(StationeryTheme theme, bool isDark, MoonPhaseInfo moon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.nightlight_round, size: 18, color: theme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Lunar Trajectory & Moon Phase',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.lavenderBubble,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${moon.illuminationPercent.round()}% ILLUM',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Moon Phase Vector Display
          Row(
            children: [
              // Large Custom Vector Moon
              SizedBox(
                width: 76,
                height: 76,
                child: CustomPaint(
                  painter: _VectorMoonPhasePainter(phase: moon.phase, isDark: isDark),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moon.phaseName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moon.hindiName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Moon Age: ${moon.ageDays.toStringAsFixed(1)} days in synodic cycle • Next New/Full in ${(29.5 - moon.ageDays).toStringAsFixed(1)}d',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        color: theme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 8 Moon Phases Visual Strip
          Text(
            '8-Phase Lunar Cycle Preview:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildMoonPhaseStripItem('New', 0.0, moon.phase, theme, isDark),
                _buildMoonPhaseStripItem('Wax Crescent', 0.12, moon.phase, theme, isDark),
                _buildMoonPhaseStripItem('1st Quarter', 0.25, moon.phase, theme, isDark),
                _buildMoonPhaseStripItem('Wax Gibbous', 0.38, moon.phase, theme, isDark),
                _buildMoonPhaseStripItem('Full Moon', 0.50, moon.phase, theme, isDark),
                _buildMoonPhaseStripItem('Wan Gibbous', 0.62, moon.phase, theme, isDark),
                _buildMoonPhaseStripItem('3rd Quarter', 0.75, moon.phase, theme, isDark),
                _buildMoonPhaseStripItem('Wan Crescent', 0.88, moon.phase, theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonPhaseStripItem(
    String label,
    double phaseVal,
    double currentPhase,
    StationeryTheme theme,
    bool isDark,
  ) {
    final isCurrent = (currentPhase - phaseVal).abs() < 0.08 ||
        (phaseVal == 0.0 && (currentPhase >= 0.94 || currentPhase <= 0.06));

    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.primary.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? theme.primary : theme.border.withValues(alpha: 0.4),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CustomPaint(
              painter: _VectorMoonPhasePainter(phase: phaseVal, isDark: isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
              color: isCurrent ? theme.primary : theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. 14-DAY HISTORY & FORECAST VISUALIZER
  // ---------------------------------------------------------------------------
  Widget _buildForecastHistoryCard(StationeryTheme theme, bool isDark, WeatherTelemetryData raw) {
    final dailyList = raw.dailyList;

    // Filter list according to tab
    List<DailyForecastItem> itemsToDisplay;
    if (_forecastTab == 1) {
      // Past 7 Days
      itemsToDisplay = dailyList.where((d) => d.isPast).toList();
    } else if (_forecastTab == 2) {
      // Next 7 Days
      itemsToDisplay = dailyList.where((d) => !d.isPast).toList();
    } else {
      // All 14 Days
      itemsToDisplay = dailyList;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '14-Day Weather Trend',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: theme.text,
                ),
              ),
              // Segmented tab control
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildForecastTabButton('14d', 0, theme, isDark),
                    _buildForecastTabButton('Past 7d', 1, theme, isDark),
                    _buildForecastTabButton('Next 7d', 2, theme, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal Bar Chart
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: itemsToDisplay.map((item) {
                final maxT = _toDisplayTemp(item.maxTempC).round();
                final minT = _toDisplayTemp(item.minTempC).round();
                final dayLabel = _formatDayLabel(item.date, item.isToday);
                final dateLabel = '${item.date.day}/${item.date.month}';

                return Container(
                  width: 58,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: item.isToday
                        ? theme.primary.withValues(alpha: 0.12)
                        : (item.isPast
                            ? (isDark ? const Color(0xFF222226) : const Color(0xFFF9FAFB))
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5))),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.isToday
                          ? theme.primary
                          : (item.isPast ? theme.border.withValues(alpha: 0.3) : theme.border),
                      width: item.isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Past / Today / Future Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: item.isToday
                              ? theme.primary
                              : (item.isPast
                                  ? Colors.grey.withValues(alpha: 0.2)
                                  : theme.lavenderBubble),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isToday ? 'TODAY' : (item.isPast ? 'PAST' : 'FCST'),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: item.isToday ? Colors.white : theme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Day Name
                      Text(
                        dayLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: item.isToday ? FontWeight.w900 : FontWeight.w700,
                          color: item.isToday ? theme.primary : theme.text,
                        ),
                      ),
                      Text(
                        dateLabel,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Weather Icon
                      Icon(
                        _telemetry.getWeatherIcon(item.weatherCode, true),
                        size: 20,
                        color: [0, 1].contains(item.weatherCode)
                            ? const Color(0xFFF59E0B)
                            : ([95, 96, 99].contains(item.weatherCode)
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF0284C7)),
                      ),
                      const SizedBox(height: 8),

                      // Temperature High
                      Text(
                        '$maxT°',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFEF4444),
                        ),
                      ),

                      // Visual Temperature Bar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        width: 8,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFEF4444),
                              Color(0xFF38BDF8),
                            ],
                          ),
                        ),
                      ),

                      // Temperature Low
                      Text(
                        '$minT°',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Rain Probability
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.water_drop_rounded, size: 9, color: Color(0xFF0284C7)),
                          Text(
                            '${item.precipProb}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTabButton(String label, int tabIndex, StationeryTheme theme, bool isDark) {
    final isSelected = _forecastTab == tabIndex;
    return InkWell(
      onTap: () {
        SoundService().playTap();
        setState(() => _forecastTab = tabIndex);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3F3F46) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? theme.primary : theme.textSecondary,
          ),
        ),
      ),
    );
  }

  static String _formatDayLabel(DateTime d, bool isToday) {
    if (isToday) return 'Today';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[d.weekday - 1];
  }

  // ---------------------------------------------------------------------------
  // 5. DETAILED ATMOSPHERIC METRICS GRID
  // ---------------------------------------------------------------------------
  Widget _buildMetricsGrid(
    StationeryTheme theme,
    bool isDark,
    WeatherTelemetryData raw,
    _EffectiveWeather weather,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atmospheric Metrics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricTile(
              theme,
              isDark,
              icon: Icons.water_drop_outlined,
              title: 'Humidity',
              value: '${raw.humidity.round()}%',
              subtitle: raw.humidity < 40 ? 'Dry air' : (raw.humidity > 70 ? 'Humid' : 'Comfortable'),
              accentColor: const Color(0xFF0284C7),
            ),
            _buildMetricTile(
              theme,
              isDark,
              icon: Icons.air_rounded,
              title: 'Wind Speed',
              value: '${raw.windSpeedKmH.toStringAsFixed(1)} km/h',
              subtitle: 'Gentle mountain breeze',
              accentColor: const Color(0xFF10B981),
            ),
            _buildMetricTile(
              theme,
              isDark,
              icon: Icons.wb_sunny_outlined,
              title: 'UV Index',
              value: raw.uvIndex.toStringAsFixed(1),
              subtitle: raw.uvIndex >= 6 ? 'High (Wear sunscreen)' : 'Moderate safe level',
              accentColor: const Color(0xFFF59E0B),
            ),
            _buildMetricTile(
              theme,
              isDark,
              icon: Icons.speed_rounded,
              title: 'Pressure',
              value: '${raw.pressureHpa.round()} hPa',
              subtitle: 'Stable atmospheric basin',
              accentColor: const Color(0xFF8B5CF6),
            ),
            _buildMetricTile(
              theme,
              isDark,
              icon: Icons.wb_twilight_rounded,
              title: 'Sunrise',
              value: raw.sunriseToday,
              subtitle: 'Golden dawn',
              accentColor: const Color(0xFFF97316),
            ),
            _buildMetricTile(
              theme,
              isDark,
              icon: Icons.bedtime_outlined,
              title: 'Sunset',
              value: raw.sunsetToday,
              subtitle: 'Twilight evening',
              accentColor: const Color(0xFF6366F1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    StationeryTheme theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: theme.text,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. INTERACTIVE SIMULATOR SHEET (Disasters, Sun, Moon & AQI testing)
  // ---------------------------------------------------------------------------
  void _showSimulationSheet(StationeryTheme theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weather Simulator',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: theme.text,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Experience live SVG Sun, Moon phases, Rain, Thunder, Floods, Tornados & AQI transformations.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSimChip('Live Radar', WeatherSimMode.live, setSheetState, theme, isDark),
                      _buildSimChip('Sunny & Birds', WeatherSimMode.sunnyDay, setSheetState, theme, isDark),
                      _buildSimChip('Starry Night', WeatherSimMode.starryNight, setSheetState, theme, isDark),
                      _buildSimChip('Moving Clouds', WeatherSimMode.cloudySky, setSheetState, theme, isDark),
                      _buildSimChip('Heavy Rain', WeatherSimMode.rainyDeluge, setSheetState, theme, isDark),
                      _buildSimChip('Thunder Lightning', WeatherSimMode.thunderstorm, setSheetState, theme, isDark),
                      _buildSimChip('Mountain Flood 🌊', WeatherSimMode.mountainFlood, setSheetState, theme, isDark),
                      _buildSimChip('Tornado Twister 🌪️', WeatherSimMode.tornadoTwister, setSheetState, theme, isDark),
                      _buildSimChip('Hazardous Smog 🏭', WeatherSimMode.severeSmog, setSheetState, theme, isDark),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // AQI Quick Slider
                  Text(
                    'Interactive AQI Character & Ecology Slider: ${_simAqiOverride ?? _telemetry.data.aqi}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  Slider(
                    value: (_simAqiOverride ?? _telemetry.data.aqi).toDouble().clamp(0, 400),
                    min: 0,
                    max: 400,
                    divisions: 40,
                    activeColor: _telemetryAqiColor(_simAqiOverride ?? _telemetry.data.aqi),
                    onChanged: (val) {
                      setState(() => _simAqiOverride = val.round());
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSimChip(
    String label,
    WeatherSimMode mode,
    StateSetter setSheetState,
    StationeryTheme theme,
    bool isDark,
  ) {
    final isSelected = _simMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.primary.withValues(alpha: 0.2),
      backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? theme.primary : theme.text,
      ),
      side: BorderSide(
        color: isSelected ? theme.primary : theme.border,
        width: 1.2,
      ),
      onSelected: (_) {
        SoundService().playTap();
        setState(() {
          _simMode = mode;
        });
        setSheetState(() {});
      },
    );
  }
}

// ---------------------------------------------------------------------------
// DATA WRAPPER FOR ACTIVE WEATHER STATE
// ---------------------------------------------------------------------------
class _EffectiveWeather {
  final bool isDay;
  final bool isRain;
  final bool isThunder;
  final bool isCloudy;
  final bool isFlood;
  final bool isTwister;
  final double tempC;
  final String condition;
  final int aqi;
  final String aqiStatus;
  final Color aqiColor;
  final String city;
  final String country;

  _EffectiveWeather({
    required this.isDay,
    required this.isRain,
    required this.isThunder,
    required this.isCloudy,
    required this.isFlood,
    required this.isTwister,
    required this.tempC,
    required this.condition,
    required this.aqi,
    required this.aqiStatus,
    required this.aqiColor,
    required this.city,
    required this.country,
  });
}

// ---------------------------------------------------------------------------
// ATMOSPHERIC LANDSCAPE PAINTER (Mountains, Sun, Moon, Overlays, AQI, Disasters)
// ---------------------------------------------------------------------------
class _AtmosphericLandscapePainter extends CustomPainter {
  final _EffectiveWeather weather;
  final MoonPhaseInfo moonPhase;
  final double animProgress;
  final double lightningProgress;
  final double floodProgress;
  final double twisterProgress;
  final bool isDark;

  _AtmosphericLandscapePainter({
    required this.weather,
    required this.moonPhase,
    required this.animProgress,
    required this.lightningProgress,
    required this.floodProgress,
    required this.twisterProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. SKY GRADIENT
    _paintSky(canvas, w, h);

    // 2. STARS AT NIGHT
    if (!weather.isDay) {
      _paintStars(canvas, w, h);
    }

    // 3. SUN OR MOON
    if (weather.isDay) {
      _paintSun(canvas, w, h);
    } else {
      _paintMoon(canvas, w, h);
    }

    // 4. DISTANT MOUNTAIN RIDGE
    _paintDistantMountains(canvas, w, h);

    // 5. MIDGROUND MOUNTAINS & CANYON
    _paintMidgroundMountains(canvas, w, h);

    // 6. MOUNTAIN FLOOD SURGE DISASTER (rushing through mountain valley)
    if (weather.isFlood) {
      _paintFloodSurge(canvas, w, h);
    }

    // 7. FOREGROUND HILLS & HORIZON
    _paintForegroundHills(canvas, w, h);

    // 8. TREES & BIRDS ECOLOGY (Driven by AQI)
    _paintEcology(canvas, w, h);

    // 9. DRIFTING CLOUDS
    _paintClouds(canvas, w, h);

    // 10. RAIN DELUGE
    if (weather.isRain) {
      _paintRain(canvas, w, h);
    }

    // 11. THUNDER LIGHTNING
    if (weather.isThunder) {
      _paintLightning(canvas, w, h);
    }

    // 12. TORNADO TWISTER VORTEX DISASTER
    if (weather.isTwister) {
      _paintTornado(canvas, w, h);
    }

    // 13. SMOG / POLLUTION HAZE (If AQI >= 100)
    if (weather.aqi >= 100) {
      _paintSmogHaze(canvas, w, h);
    }
  }

  void _paintSky(Canvas canvas, double w, double h) {
    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final Gradient grad;

    if (weather.isTwister) {
      // Ominous stormy green-black twister sky
      grad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF132E27)],
      );
    } else if (weather.isThunder || weather.isFlood) {
      // Dark brooding storm sky
      grad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
      );
    } else if (weather.isRain) {
      // Cool misty rain sky
      grad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E293B), Color(0xFF3B82F6), Color(0xFF64748B)],
      );
    } else if (weather.isDay) {
      // Radiant daylight sky
      grad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFBAE6FD), Color(0xFFFEF08A)],
      );
    } else {
      // Deep starry night indigo
      grad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050814), Color(0xFF0F172A), Color(0xFF1E1B4B)],
      );
    }

    final paint = Paint()..shader = grad.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintStars(Canvas canvas, double w, double h) {
    final starPaint = Paint()..color = Colors.white;
    // Pre-calculated star offsets
    final stars = [
      Offset(w * 0.12, h * 0.12),
      Offset(w * 0.28, h * 0.08),
      Offset(w * 0.44, h * 0.16),
      Offset(w * 0.62, h * 0.09),
      Offset(w * 0.78, h * 0.14),
      Offset(w * 0.88, h * 0.06),
      Offset(w * 0.20, h * 0.22),
      Offset(w * 0.72, h * 0.24),
    ];

    for (int i = 0; i < stars.length; i++) {
      final twinkle = (math.sin((animProgress * math.pi * 2) + i) + 1.0) / 2.0;
      starPaint.color = Colors.white.withValues(alpha: 0.3 + (twinkle * 0.65));
      final r = 1.0 + (twinkle * 1.2);
      canvas.drawCircle(stars[i], r, starPaint);
    }
  }

  void _paintSun(Canvas canvas, double w, double h) {
    final now = DateTime.now();
    final hour = now.hour + (now.minute / 60.0);

    // Dynamic morning growth & trajectory from behind mountain:
    final double sunX;
    final double sunY;
    final double scale;

    if (hour >= 5.0 && hour <= 10.5) {
      // Morning: Sun emerges low from mountain slope and grows in size & brightness
      final t = ((hour - 5.0) / 5.5).clamp(0.0, 1.0);
      sunX = w * (0.24 + (t * 0.46));
      sunY = h * (0.50 - (t * 0.28)); // emerges from mountain crest
      scale = 0.72 + (t * 0.38); // grows from 0.72x to 1.1x!
    } else if (hour > 10.5 && hour <= 16.0) {
      // High bright midday sun
      sunX = w * 0.70;
      sunY = h * 0.22;
      scale = 1.10;
    } else {
      // Evening: Sun descends towards the mountain crest
      final t = ((hour - 16.0) / 2.5).clamp(0.0, 1.0);
      sunX = w * (0.70 + (t * 0.18));
      sunY = h * (0.22 + (t * 0.26));
      scale = 1.10 - (t * 0.25);
    }

    final sunCenter = Offset(sunX, sunY);
    final sunRadius = w * 0.085 * scale;

    // Radiant outer glowing aura
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withValues(alpha: 0.6),
          const Color(0xFFFBBF24).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius * 3.2));
    canvas.drawCircle(sunCenter, sunRadius * 3.2, glowPaint);

    // Rotating solar rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.38)
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;

    final rayRot = animProgress * math.pi * 2;
    for (int i = 0; i < 8; i++) {
      final angle = rayRot + (i * (math.pi / 4));
      final p1 = Offset(sunCenter.dx + math.cos(angle) * (sunRadius * 1.25), sunCenter.dy + math.sin(angle) * (sunRadius * 1.25));
      final p2 = Offset(sunCenter.dx + math.cos(angle) * (sunRadius * 1.85), sunCenter.dy + math.sin(angle) * (sunRadius * 1.85));
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Golden Sun Disc
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);
  }

  void _paintMoon(Canvas canvas, double w, double h) {
    final now = DateTime.now();
    final hour = now.hour + (now.minute / 60.0);

    // Night trajectory: Moon emerges from behind mountain into starry sky
    final double moonX;
    final double moonY;
    final double scale;

    if (hour >= 18.0 && hour <= 23.5) {
      final t = ((hour - 18.0) / 5.5).clamp(0.0, 1.0);
      moonX = w * (0.28 + (t * 0.46));
      moonY = h * (0.48 - (t * 0.22)); // emerges from behind mountain
      scale = 0.75 + (t * 0.30);
    } else {
      moonX = w * 0.74;
      moonY = h * 0.26;
      scale = 1.05;
    }

    final moonCenter = Offset(moonX, moonY);
    final r = w * 0.085 * scale;

    // Celestial moonlight glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE0E7FF).withValues(alpha: 0.4),
          const Color(0xFFE0E7FF).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: r * 2.5));
    canvas.drawCircle(moonCenter, r * 2.5, glowPaint);

    // Accurate Vector Moon Phase rendering
    _drawMoonPhaseDirect(canvas, moonCenter, r, moonPhase.phase);
  }

  void _paintDistantMountains(Canvas canvas, double w, double h) {
    final path = Path();
    path.moveTo(0, h * 0.62);
    path.lineTo(w * 0.18, h * 0.48);
    path.lineTo(w * 0.38, h * 0.58);
    path.lineTo(w * 0.60, h * 0.44);
    path.lineTo(w * 0.82, h * 0.54);
    path.lineTo(w, h * 0.46);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    final paint = Paint()
      ..color = weather.isDay
          ? const Color(0xFF7DD3FC).withValues(alpha: 0.45)
          : const Color(0xFF312E81).withValues(alpha: 0.5);
    canvas.drawPath(path, paint);
  }

  void _paintMidgroundMountains(Canvas canvas, double w, double h) {
    final path = Path();
    path.moveTo(0, h * 0.72);
    path.lineTo(w * 0.25, h * 0.54);
    path.lineTo(w * 0.46, h * 0.66);
    // Valley canyon center
    path.lineTo(w * 0.52, h * 0.78);
    path.lineTo(w * 0.70, h * 0.52);
    path.lineTo(w * 0.88, h * 0.64);
    path.lineTo(w, h * 0.58);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: weather.isDay
            ? [const Color(0xFF0369A1), const Color(0xFF0C4A6E)]
            : [const Color(0xFF1E1B4B), const Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(0, h * 0.52, w, h * 0.48));
    canvas.drawPath(path, paint);
  }

  void _paintForegroundHills(Canvas canvas, double w, double h) {
    final path = Path();
    path.moveTo(0, h * 0.82);
    path.quadraticBezierTo(w * 0.22, h * 0.74, w * 0.48, h * 0.84);
    path.quadraticBezierTo(w * 0.76, h * 0.92, w, h * 0.80);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: weather.isDay
            ? (weather.aqi < 100
                ? [const Color(0xFF15803D), const Color(0xFF14532D)]
                : [const Color(0xFF78716C), const Color(0xFF44403C)])
            : [const Color(0xFF064E3B), const Color(0xFF022C22)],
      ).createShader(Rect.fromLTWH(0, h * 0.74, w, h * 0.26));
    canvas.drawPath(path, paint);
  }

  void _paintFloodSurge(Canvas canvas, double w, double h) {
    // A rapid foaming mountain river rushing down the canyon valley
    final waveShift = (floodProgress * w * 0.8) % w;

    final floodPath = Path();
    floodPath.moveTo(w * 0.40, h * 0.72);
    floodPath.quadraticBezierTo(
      w * 0.50 + math.sin(floodProgress * math.pi * 2) * 12,
      h * 0.82,
      w * 0.56,
      h,
    );
    floodPath.lineTo(w * 0.35, h);
    floodPath.close();

    final floodPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
      ).createShader(Rect.fromLTWH(w * 0.35, h * 0.72, w * 0.25, h * 0.28));
    canvas.drawPath(floodPath, floodPaint);

    // Foaming white wave crests
    final foamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final y = h * 0.76 + (i * 12);
      final x = w * 0.38 + ((waveShift + (i * 20)) % 60);
      canvas.drawLine(Offset(x, y), Offset(x + 18, y + 2), foamPaint);
    }
  }

  void _paintEcology(Canvas canvas, double w, double h) {
    final aqi = weather.aqi;
    final isGoodAqi = aqi < 100;

    // 1. BIRDS IN SKY (Only when AQI < 100)
    if (isGoodAqi) {
      final birdPaint = Paint()
        ..color = (weather.isDay ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1))
            .withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      // Flying flock gliding across mountains
      final birdBaseX = ((animProgress * w * 1.3) % (w + 100)) - 60;
      final wingFlap = math.sin(animProgress * math.pi * 14) * 4.0;

      _drawBird(canvas, birdBaseX, h * 0.38, wingFlap, birdPaint);
      _drawBird(canvas, birdBaseX + 24, h * 0.35, wingFlap + 0.8, birdPaint);
      _drawBird(canvas, birdBaseX + 46, h * 0.40, wingFlap - 0.6, birdPaint);
      _drawBird(canvas, birdBaseX + 70, h * 0.37, wingFlap + 1.2, birdPaint);
    }

    // 2. MINI TREES ON MOUNTAIN FOOTHILLS
    // Sway offset in fresh air breeze
    final sway = isGoodAqi ? (math.sin(animProgress * math.pi * 4) * 3.0) : 0.0;

    final treePositions = [
      Offset(w * 0.08, h * 0.78),
      Offset(w * 0.16, h * 0.76),
      Offset(w * 0.24, h * 0.80),
      Offset(w * 0.34, h * 0.83),
      Offset(w * 0.64, h * 0.84),
      Offset(w * 0.78, h * 0.86),
      Offset(w * 0.88, h * 0.82),
      Offset(w * 0.94, h * 0.79),
    ];

    for (final pos in treePositions) {
      if (isGoodAqi) {
        // Lush green pine tree swaying gently
        _drawLushTree(canvas, pos.dx, pos.dy, sway);
      } else {
        // Bare dry branch tree (Sukhe ped)
        _drawBareDryTree(canvas, pos.dx, pos.dy);
      }
    }
  }

  void _drawBird(Canvas canvas, double x, double y, double wingFlap, Paint paint) {
    final path = Path();
    path.moveTo(x - 9, y - wingFlap);
    path.quadraticBezierTo(x - 4, y - 2, x, y);
    path.quadraticBezierTo(x + 4, y - 2, x + 9, y - wingFlap);
    canvas.drawPath(path, paint);
  }

  void _drawLushTree(Canvas canvas, double x, double y, double sway) {
    // Tree Trunk
    final trunk = Paint()
      ..color = const Color(0xFF451A03)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, y), Offset(x + (sway * 0.25), y - 12), trunk);

    // Green Foliage Tiers with Flutter/Wing Tips in Fresh Air
    final foliageDark = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.fill;
    final foliageLight = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    // Bottom tier (broad)
    final t1 = Path()
      ..moveTo(x + (sway * 0.8), y - 24)
      ..lineTo(x - 9 - (sway * 0.5), y - 10)
      ..quadraticBezierTo(x, y - 8, x + 9 + (sway * 0.5), y - 10)
      ..close();
    canvas.drawPath(t1, foliageDark);

    // Middle tier
    final t2 = Path()
      ..moveTo(x + sway, y - 30)
      ..lineTo(x - 7 - (sway * 0.4), y - 18)
      ..quadraticBezierTo(x, y - 16, x + 7 + (sway * 0.4), y - 18)
      ..close();
    canvas.drawPath(t2, foliageLight);

    // Top tier crown fluttering in wind
    final t3 = Path()
      ..moveTo(x + (sway * 1.3), y - 36)
      ..lineTo(x - 5, y - 26)
      ..lineTo(x + 5, y - 26)
      ..close();
    canvas.drawPath(t3, foliageLight);
  }

  void _drawBareDryTree(Canvas canvas, double x, double y) {
    // Dry bare branches (Sukhe ped without leaves)
    final dryPaint = Paint()
      ..color = const Color(0xFF57534E)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Bare trunk
    canvas.drawLine(Offset(x, y), Offset(x, y - 18), dryPaint);
    // Spindly dry branches
    canvas.drawLine(Offset(x, y - 10), Offset(x - 6, y - 16), dryPaint);
    canvas.drawLine(Offset(x, y - 14), Offset(x + 7, y - 22), dryPaint);
    canvas.drawLine(Offset(x - 6, y - 16), Offset(x - 9, y - 23), dryPaint);
  }

  void _paintClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: weather.isThunder ? 0.35 : 0.65)
      ..style = PaintingStyle.fill;

    // Multi-layer drifting clouds
    final x1 = ((animProgress * w * 0.7) % (w + 140)) - 70;
    final x2 = (((animProgress * w * 0.4) + (w * 0.5)) % (w + 140)) - 70;

    _drawCloudShape(canvas, x1, h * 0.22, 54, cloudPaint);
    _drawCloudShape(canvas, x2, h * 0.16, 68, cloudPaint);
  }

  void _drawCloudShape(Canvas canvas, double cx, double cy, double r, Paint paint) {
    canvas.drawCircle(Offset(cx, cy), r * 0.45, paint);
    canvas.drawCircle(Offset(cx + (r * 0.35), cy - (r * 0.15)), r * 0.55, paint);
    canvas.drawCircle(Offset(cx + (r * 0.75), cy), r * 0.42, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - (r * 0.2), cy - (r * 0.05), r * 1.15, r * 0.45),
        Radius.circular(r * 0.2),
      ),
      paint,
    );
  }

  void _paintRain(Canvas canvas, double w, double h) {
    final rainPaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.6)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const drops = 24;
    for (int i = 0; i < drops; i++) {
      final seed = i * 37.0;
      final x = (seed * 13.0) % w;
      final startY = (seed * 19.0 + (animProgress * h * 5.0)) % h;
      canvas.drawLine(Offset(x, startY), Offset(x - 4, startY + 12), rainPaint);
    }
  }

  void _paintLightning(Canvas canvas, double w, double h) {
    // Intermittent flash burst (at specific lightningProgress intervals)
    if (lightningProgress > 0.88 && lightningProgress < 0.96) {
      // Screen ambient lightning flash
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );

      // Jagged bolt path striking mountain crest
      final boltPaint = Paint()
        ..color = const Color(0xFFFEF08A)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(w * 0.48, h * 0.18);
      path.lineTo(w * 0.44, h * 0.32);
      path.lineTo(w * 0.50, h * 0.38);
      path.lineTo(w * 0.42, h * 0.52);
      path.lineTo(w * 0.47, h * 0.58);
      path.lineTo(w * 0.38, h * 0.72); // strikes mountain ridge
      canvas.drawPath(path, boltPaint);

      // Secondary smaller branch
      final branch = Path();
      branch.moveTo(w * 0.44, h * 0.32);
      branch.lineTo(w * 0.36, h * 0.42);
      canvas.drawPath(branch, boltPaint..strokeWidth = 1.5);
    }
  }

  void _paintTornado(Canvas canvas, double w, double h) {
    // A spiraling twister funnel vortex
    final funnelBaseX = w * 0.55 + (math.sin(twisterProgress * math.pi * 2) * 20);
    final topY = h * 0.18;
    final groundY = h * 0.82;

    final tornadoPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Funnel cloud polygon
    final funnel = Path();
    funnel.moveTo(funnelBaseX - 45, topY);
    funnel.lineTo(funnelBaseX + 45, topY);
    funnel.quadraticBezierTo(funnelBaseX + 16, (topY + groundY) / 2, funnelBaseX + 6, groundY);
    funnel.lineTo(funnelBaseX - 6, groundY);
    funnel.quadraticBezierTo(funnelBaseX - 16, (topY + groundY) / 2, funnelBaseX - 45, topY);
    funnel.close();
    canvas.drawPath(funnel, tornadoPaint);

    // Spiraling wind debris particles
    final debrisPaint = Paint()..color = const Color(0xFF334155);
    for (int i = 0; i < 16; i++) {
      final t = (twisterProgress + (i / 16.0)) % 1.0;
      final y = topY + (t * (groundY - topY));
      final widthAtY = 45.0 * (1.0 - (t * 0.85));
      final angle = (twisterProgress * math.pi * 6) + (i * 1.2);
      final x = funnelBaseX + (math.cos(angle) * widthAtY);
      canvas.drawCircle(Offset(x, y), 1.6, debrisPaint);
    }
  }

  void _paintSmogHaze(Canvas canvas, double w, double h) {
    // Murky sepia/gray haze across mountains
    final smogIntensity = ((weather.aqi - 100) / 200.0).clamp(0.15, 0.65);
    final smogPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF78716C).withValues(alpha: 0.1),
          const Color(0xFFB45309).withValues(alpha: smogIntensity * 0.6),
          const Color(0xFF713F12).withValues(alpha: smogIntensity),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.4, w, h * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.4, w, h * 0.6), smogPaint);
  }

  void _drawMoonPhaseDirect(Canvas canvas, Offset center, double r, double phase) {
    // Dark side base
    final darkPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(center, r, darkPaint);

    // Illuminated portion with vector curve
    final lightPaint = Paint()..color = const Color(0xFFFEF08A);

    final path = Path();
    if (phase >= 0.0 && phase <= 0.5) {
      // Waxing: right side illuminates
      path.addArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2, math.pi);
      final k = (0.25 - phase) / 0.25; // 1.0 at new, 0.0 at quarter, -1.0 at full
      final rInner = (r * k).abs();
      final sweep = k >= 0 ? -math.pi : math.pi;
      path.arcTo(
        Rect.fromCenter(center: center, width: rInner * 2, height: r * 2),
        math.pi / 2,
        sweep,
        false,
      );
    } else {
      // Waning: left side illuminates
      path.addArc(Rect.fromCircle(center: center, radius: r), math.pi / 2, math.pi);
      final k = (0.75 - phase) / 0.25;
      final rInner = (r * k).abs();
      final sweep = k >= 0 ? math.pi : -math.pi;
      path.arcTo(
        Rect.fromCenter(center: center, width: rInner * 2, height: r * 2),
        -math.pi / 2,
        sweep,
        false,
      );
    }
    path.close();
    canvas.drawPath(path, lightPaint);

    // Subtle outline
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, r, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _AtmosphericLandscapePainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// VECTOR MOON PHASE STANDALONE PAINTER (For Moon Card & 8-Phase Strip)
// ---------------------------------------------------------------------------
class _VectorMoonPhasePainter extends CustomPainter {
  final double phase;
  final bool isDark;

  _VectorMoonPhasePainter({required this.phase, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, w / 2);
    final r = (w / 2) * 0.88;

    // Dark disc
    final darkPaint = Paint()..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF334155);
    canvas.drawCircle(center, r, darkPaint);

    // Lit phase
    final lightPaint = Paint()..color = const Color(0xFFFEF08A);

    final path = Path();
    if (phase >= 0.0 && phase <= 0.5) {
      path.addArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2, math.pi);
      final k = (0.25 - phase) / 0.25;
      final rInner = (r * k).abs();
      final sweep = k >= 0 ? -math.pi : math.pi;
      path.arcTo(
        Rect.fromCenter(center: center, width: rInner * 2, height: r * 2),
        math.pi / 2,
        sweep,
        false,
      );
    } else {
      path.addArc(Rect.fromCircle(center: center, radius: r), math.pi / 2, math.pi);
      final k = (0.75 - phase) / 0.25;
      final rInner = (r * k).abs();
      final sweep = k >= 0 ? math.pi : -math.pi;
      path.arcTo(
        Rect.fromCenter(center: center, width: rInner * 2, height: r * 2),
        -math.pi / 2,
        sweep,
        false,
      );
    }
    path.close();
    canvas.drawPath(path, lightPaint);

    // Rim ring
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, r, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _VectorMoonPhasePainter old) =>
      old.phase != phase || old.isDark != isDark;
}

// ---------------------------------------------------------------------------
// AQI REACTIVE 6-STAGE CHARACTER SYSTEM (Authentic Tooler Vector Mascot)
// 1. cleanAirBreathe:         AQI <= 50  (Khul ke saans, chest expansion, fresh air breeze, green leaves)
// 2. mildCoughAutumn:         AQI 51-100 (Coughing spasm, hand to mouth, autumn red/amber leaves drifting)
// 3. unhealthyMask:           AQI 101-150 (Protective N95 mask, wilting brown leaves)
// 4. veryUnhealthySadMask:    AQI 151-200 (Visibly sad mask pose, drooping eye-bags, soot motes)
// 5. hazardousOxygenCylinder: AQI 201-300 (Medical oxygen mask + oxygen tank & coiled tube, yellow smog)
// 6. severeToxicWrinkled:     AQI > 300  (Deep facial wrinkles, emaciated gaunt, tremor, cylinder in red zone)
// ---------------------------------------------------------------------------
enum _AqiCharacterMood {
  cleanAirBreathe,
  mildCoughAutumn,
  unhealthyMask,
  veryUnhealthySadMask,
  hazardousOxygenCylinder,
  severeToxicWrinkled,
}

class _AqiToolerCharacter extends StatefulWidget {
  final _AqiCharacterMood mood;
  final StationeryTheme theme;
  final bool isDark;
  final double animValue; // 0.0 to 1.0 from _coughController
  final double width;
  final double height;

  const _AqiToolerCharacter({
    required this.mood,
    required this.theme,
    required this.isDark,
    required this.animValue,
    this.width = 118,
    this.height = 130,
  });

  @override
  State<_AqiToolerCharacter> createState() => _AqiToolerCharacterState();
}

class _AqiToolerCharacterState extends State<_AqiToolerCharacter> {
  static String? _rawCleanSvg;
  static final Map<String, String> _themedCache = {};
  String? _themedSvg;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(covariant _AqiToolerCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme.mode != widget.theme.mode ||
        oldWidget.theme.isDark != widget.theme.isDark ||
        oldWidget.theme.primary != widget.theme.primary) {
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    final cacheKey = '${widget.theme.mode}_${widget.theme.isDark}_${widget.theme.primary.toARGB32()}';
    if (_themedCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _themedSvg = _themedCache[cacheKey];
        });
      }
      return;
    }

    if (_rawCleanSvg == null) {
      try {
        _rawCleanSvg = await rootBundle.loadString('assets/illustrations/character_weather_clean.svg');
      } catch (e) {
        return;
      }
    }

    if (_rawCleanSvg != null) {
      final hexPrimary = '#${(widget.theme.primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
      final hexLight = '#${(widget.theme.primary.withValues(alpha: 0.22).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
      final hexPantsBack = '#${(widget.theme.primary.withValues(alpha: 0.78).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

      final processed = _rawCleanSvg!
          .replaceAll('var(--char-accent, #9468E8)', hexPrimary)
          .replaceAll('#9468E8', hexPrimary)
          .replaceAll('#7E4EE0', hexPantsBack)
          .replaceAll('#EDE9FE', hexLight)
          .replaceAll('#C8B6FA', hexLight)
          .replaceAll('#DDD6FE', hexLight);

      _themedCache[cacheKey] = processed;
      if (mounted) {
        setState(() {
          _themedSvg = processed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;

    // Movement & posture variations according to 6 AQI mood stages:
    Offset charOffset = Offset.zero;
    double charAngle = 0.0;
    double scaleX = 1.0;
    double scaleY = 1.0;

    switch (widget.mood) {
      case _AqiCharacterMood.cleanAirBreathe:
        // Deep relaxing rhythmic breathing: chest expands up and widens gently
        final breath = math.sin(widget.animValue * math.pi * 2);
        charOffset = Offset(0, -breath * 2.8);
        scaleY = 1.0 + (breath * 0.026);
        scaleX = 1.0 + (breath * 0.016);
        break;

      case _AqiCharacterMood.mildCoughAutumn:
        // Cough spasm: rapid forward jolt and vibration
        final jolt = math.sin(widget.animValue * math.pi * 6);
        final isCoughPhase = widget.animValue > 0.15 && widget.animValue < 0.75;
        if (isCoughPhase) {
          charOffset = Offset(-jolt * 2.5, (jolt.abs()) * 2.0);
          charAngle = -jolt * 0.026;
        } else {
          charOffset = Offset(0, math.sin(widget.animValue * math.pi * 2) * 0.8);
        }
        break;

      case _AqiCharacterMood.unhealthyMask:
        // Restricted breathing through mask
        final breath = math.sin(widget.animValue * math.pi * 2);
        charOffset = Offset(0, breath * 1.2);
        break;

      case _AqiCharacterMood.veryUnhealthySadMask:
        // Sad drooping posture: slouched forward, drooping down
        final breath = math.sin(widget.animValue * math.pi * 2);
        charOffset = Offset(0, 2.2 + (breath * 0.8));
        charAngle = -0.028; // sad posture slouch
        scaleY = 0.985;
        break;

      case _AqiCharacterMood.hazardousOxygenCylinder:
        // Heavy burdened breathing with medical oxygen support
        final breath = math.sin(widget.animValue * math.pi * 2);
        charOffset = Offset(0, 1.2 + (breath * 1.0));
        scaleX = 0.98;
        break;

      case _AqiCharacterMood.severeToxicWrinkled:
        // Severe toxic condition: "bahut zyada sukha hai aur bahut uski halat kharab hai"
        // Emaciated / gaunt silhouette (scaleX: 0.90, scaleY: 0.97) + continuous shivering tremors
        final tremor = math.sin(widget.animValue * math.pi * 12) * 1.1;
        charOffset = Offset(tremor * 0.8, 3.2 + (tremor.abs() * 0.5));
        charAngle = -0.042; // extreme exhausted slouch
        scaleX = 0.90;
        scaleY = 0.97;
        break;
    }

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Soft Ground Shadow underneath character feet
          Positioned(
            bottom: 3,
            right: w * 0.10,
            child: Container(
              width: w * 0.58,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isDark ? Colors.black : Colors.black26).withValues(alpha: 0.28),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // 2. Pure Authentic Tooler Vector Character (No board, themed)
          if (_themedSvg != null)
            Transform.translate(
              offset: charOffset,
              child: Transform.rotate(
                angle: charAngle,
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  alignment: Alignment.bottomCenter,
                  child: SvgPicture.string(
                    _themedSvg!,
                    width: w,
                    height: h,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

          // 3. Scenario Overlays (Coughing puffs, Masks, Oxygen cylinder, O2 tube, smile, leaves, wrinkles)
          Positioned.fill(
            child: CustomPaint(
              painter: _AqiScenarioOverlayPainter(
                mood: widget.mood,
                theme: widget.theme,
                isDark: widget.isDark,
                animValue: widget.animValue,
                charOffset: charOffset,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AqiScenarioOverlayPainter extends CustomPainter {
  final _AqiCharacterMood mood;
  final StationeryTheme theme;
  final bool isDark;
  final double animValue;
  final Offset charOffset;

  _AqiScenarioOverlayPainter({
    required this.mood,
    required this.theme,
    required this.isDark,
    required this.animValue,
    required this.charOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 827.0;
    final renderedW = 510.0 * scale;
    final dx0 = (size.width - renderedW) / 2.0;

    // Line / stroke styling
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Landmark coordinates based on authentic character SVG viewBox
    final faceCenter = Offset(
      dx0 + (795.0 - 566.0) * scale + charOffset.dx,
      (210.0 - 111.0) * scale + charOffset.dy,
    );

    final mouthCenter = Offset(
      dx0 + (805.0 - 566.0) * scale + charOffset.dx,
      (243.0 - 111.0) * scale + charOffset.dy,
    );

    final groundY = (920.0 - 111.0) * scale;

    // -------------------------------------------------------------------------
    // 1. OXYGEN CYLINDER TANK (For Stages 5 & 6)
    // -------------------------------------------------------------------------
    if (mood == _AqiCharacterMood.hazardousOxygenCylinder ||
        mood == _AqiCharacterMood.severeToxicWrinkled) {
      _drawOxygenCylinderAndTube(
        canvas,
        size,
        scale,
        dx0,
        groundY,
        mouthCenter,
        linePaint,
        isCritical: mood == _AqiCharacterMood.severeToxicWrinkled,
      );
    }

    // -------------------------------------------------------------------------
    // 2. SCENARIOS & ENVIRONMENTAL OVERLAYS (6 Distinct Progressive Stages)
    // -------------------------------------------------------------------------
    switch (mood) {
      case _AqiCharacterMood.cleanAirBreathe:
        _drawCleanAirBreathe(canvas, size, faceCenter, mouthCenter, linePaint);
        break;

      case _AqiCharacterMood.mildCoughAutumn:
        _drawMildCoughAutumn(canvas, size, faceCenter, mouthCenter, linePaint);
        break;

      case _AqiCharacterMood.unhealthyMask:
        _drawUnhealthyMask(canvas, size, faceCenter, mouthCenter, linePaint);
        break;

      case _AqiCharacterMood.veryUnhealthySadMask:
        _drawVeryUnhealthySadMask(canvas, size, faceCenter, mouthCenter, linePaint);
        break;

      case _AqiCharacterMood.hazardousOxygenCylinder:
        _drawHazardousOxygenMask(canvas, size, faceCenter, mouthCenter, linePaint);
        break;

      case _AqiCharacterMood.severeToxicWrinkled:
        _drawSevereToxicWrinkled(canvas, size, faceCenter, mouthCenter, linePaint);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // STAGE 1: CLEAN AIR BREATHE (AQI <= 50)
  // Deep breathing, blushing cheeks, smile, fresh air breeze trails & green leaves
  // ---------------------------------------------------------------------------
  void _drawCleanAirBreathe(
    Canvas canvas,
    Size size,
    Offset faceCenter,
    Offset mouthCenter,
    Paint linePaint,
  ) {
    // 1. Rosy Blushing Cheeks
    final blush = Paint()..color = const Color(0xFFF43F5E).withValues(alpha: 0.50);
    canvas.drawCircle(Offset(faceCenter.dx - 7.0, faceCenter.dy + 3.0), 3.0, blush);
    canvas.drawCircle(Offset(faceCenter.dx + 7.0, faceCenter.dy + 3.0), 3.0, blush);

    // 2. Peaceful, Joyful Inhaling Closed Eyes (^ ^)
    final eyePaint = Paint()
      ..color = linePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo(faceCenter.dx - 8.5, faceCenter.dy - 1.5)
      ..quadraticBezierTo(faceCenter.dx - 6.0, faceCenter.dy - 4.5, faceCenter.dx - 3.5, faceCenter.dy - 1.5);
    final rightEye = Path()
      ..moveTo(faceCenter.dx + 3.5, faceCenter.dy - 1.5)
      ..quadraticBezierTo(faceCenter.dx + 6.0, faceCenter.dy - 4.5, faceCenter.dx + 8.5, faceCenter.dy - 1.5);
    canvas.drawPath(leftEye, eyePaint);
    canvas.drawPath(rightEye, eyePaint);

    // 3. Wide Relaxed Smiling Mouth
    final smile = Path()
      ..moveTo(mouthCenter.dx - 6.0, mouthCenter.dy - 1.0)
      ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + 5.0, mouthCenter.dx + 6.0, mouthCenter.dy - 1.0);
    canvas.drawPath(smile, linePaint);

    // 4. Fresh Air Breeze Currents (Swirling Wind Streams)
    final breezeWave = math.sin(animValue * math.pi * 2);
    final breezePaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final breeze1 = Path()
      ..moveTo(size.width * 0.10, size.height * 0.40 + (breezeWave * 3))
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.28 - (breezeWave * 4),
        size.width * 0.55,
        size.height * 0.38 + (breezeWave * 2),
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.46,
        size.width * 0.92,
        size.height * 0.32 - (breezeWave * 3),
      );
    canvas.drawPath(breeze1, breezePaint);

    final breeze2 = Path()
      ..moveTo(size.width * 0.18, size.height * 0.55 - (breezeWave * 2))
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.62 + (breezeWave * 3),
        size.width * 0.82,
        size.height * 0.52 - (breezeWave * 2),
      );
    canvas.drawPath(
      breeze2,
      Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );

    // 5. Fluttering Vibrant Green Leaves
    final leafFloat = math.sin(animValue * math.pi * 2) * 5.0;
    _drawVibrantLeaf(
      canvas,
      Offset(size.width * 0.16, size.height * 0.32 + leafFloat),
      rotation: -0.35 + (breezeWave * 0.15),
      color: const Color(0xFF10B981),
      linePaint: linePaint,
    );
    _drawVibrantLeaf(
      canvas,
      Offset(size.width * 0.84, size.height * 0.24 - (leafFloat * 0.8)),
      rotation: 0.45 - (breezeWave * 0.12),
      color: const Color(0xFF34D399),
      linePaint: linePaint,
    );
    _drawVibrantLeaf(
      canvas,
      Offset(size.width * 0.78, size.height * 0.65 + (leafFloat * 0.6)),
      rotation: -0.20,
      color: const Color(0xFF059669),
      linePaint: linePaint,
    );

    // 6. Emerald Sparkles
    _drawSparkle(canvas, Offset(size.width * 0.32, size.height * 0.22 - (leafFloat * 0.5)), const Color(0xFF34D399));
    _drawSparkle(canvas, Offset(size.width * 0.88, size.height * 0.45 + (leafFloat * 0.5)), const Color(0xFF10B981));
  }

  // ---------------------------------------------------------------------------
  // STAGE 2: MILD COUGH & AUTUMN LEAVES (AQI 51-100)
  // Hand to mouth, squinting cough eyes, animated cough puffs & reddish/amber leaves
  // ---------------------------------------------------------------------------
  void _drawMildCoughAutumn(
    Canvas canvas,
    Size size,
    Offset faceCenter,
    Offset mouthCenter,
    Paint linePaint,
  ) {
    // 1. Squinting Cough Eyes (> <)
    final eyeY = faceCenter.dy - 3.0;
    final leftEye = Path()
      ..moveTo(faceCenter.dx - 9, eyeY - 2.5)
      ..lineTo(faceCenter.dx - 5, eyeY)
      ..lineTo(faceCenter.dx - 9, eyeY + 2.5);
    final rightEye = Path()
      ..moveTo(faceCenter.dx + 9, eyeY - 2.5)
      ..lineTo(faceCenter.dx + 5, eyeY)
      ..lineTo(faceCenter.dx + 9, eyeY + 2.5);
    canvas.drawPath(leftEye, linePaint);
    canvas.drawPath(rightEye, linePaint);

    // 2. Open Cough Mouth "O"
    final mouthRect = Rect.fromCenter(center: mouthCenter, width: 6.5, height: 7.0);
    canvas.drawOval(mouthRect, Paint()..color = const Color(0xFF7F1D1D));
    canvas.drawOval(mouthRect, linePaint..strokeWidth = 1.2);
    linePaint.strokeWidth = 1.6;

    // 3. Hand Raised Towards Mouth Covering the Cough!
    final armPath = Path()
      ..moveTo(mouthCenter.dx + 18, mouthCenter.dy + 20)
      ..quadraticBezierTo(mouthCenter.dx + 14, mouthCenter.dy + 7, mouthCenter.dx + 1.5, mouthCenter.dy + 2.0);
    canvas.drawPath(
      armPath,
      Paint()
        ..color = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(mouthCenter.dx + 1.5, mouthCenter.dy + 2.0),
      3.8,
      Paint()..color = (isDark ? const Color(0xFF27272A) : Colors.white),
    );
    canvas.drawCircle(
      Offset(mouthCenter.dx + 1.5, mouthCenter.dy + 2.0),
      3.8,
      linePaint..strokeWidth = 1.2,
    );
    linePaint.strokeWidth = 1.6;

    // 4. Animated Cough Puff Clouds (shooting outward to left)
    final p = (animValue * 1.5) % 1.0;
    final cloudColor = (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF71717A));

    void drawPuff(Offset center, double radius, double alpha) {
      if (alpha <= 0.0) return;
      final paint = Paint()
        ..color = cloudColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = linePaint.color.withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;

      final puff = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius))
        ..addOval(Rect.fromCircle(center: center + const Offset(-2.5, -2), radius: radius * 0.7))
        ..addOval(Rect.fromCircle(center: center + const Offset(2.0, 1.5), radius: radius * 0.65));
      canvas.drawPath(puff, paint);
      canvas.drawPath(puff, border);
    }

    drawPuff(
      mouthCenter + Offset(-10 - (p * 12), -2 - (p * 4)),
      4.2 + (p * 3.5),
      (0.85 - (p * 0.7)).clamp(0.0, 1.0),
    );
    drawPuff(
      mouthCenter + Offset(-20 - (p * 16), -6 - (p * 8)),
      6.0 + (p * 4.5),
      (0.65 - (p * 0.6)).clamp(0.0, 0.65),
    );
    drawPuff(
      mouthCenter + Offset(-32 - (p * 18), -11 - (p * 10)),
      7.5 + (p * 5.0),
      (0.45 - (p * 0.5)).clamp(0.0, 0.45),
    );

    // Stylish "*cough!*" bubble
    if (animValue > 0.2 && animValue < 0.8) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '*cough!*',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFF59E0B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          mouthCenter.dx - 36,
          mouthCenter.dy - 20,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        bubbleRect,
        Paint()..color = (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.9),
      );
      canvas.drawRRect(
        bubbleRect,
        Paint()
          ..color = const Color(0xFFF59E0B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      textPainter.paint(canvas, Offset(mouthCenter.dx - 32, mouthCenter.dy - 18));
    }

    // 5. Autumn Reddish & Amber Dried Leaves (User: "leaves red ho gaye, sookh gaye")
    final leafFall = (animValue * size.height * 0.4);
    _drawAutumnLeaf(
      canvas,
      Offset(size.width * 0.20, (size.height * 0.25 + leafFall) % size.height),
      rotation: 0.6 + math.sin(animValue * math.pi * 2) * 0.2,
      color: const Color(0xFFEF4444), // Crimson dried
      linePaint: linePaint,
    );
    _drawAutumnLeaf(
      canvas,
      Offset(size.width * 0.82, (size.height * 0.15 + leafFall * 1.2) % size.height),
      rotation: -0.4 - math.sin(animValue * math.pi * 2) * 0.25,
      color: const Color(0xFFF97316), // Burnt orange
      linePaint: linePaint,
    );
    _drawAutumnLeaf(
      canvas,
      Offset(size.width * 0.14, (size.height * 0.55 + leafFall * 0.8) % size.height),
      rotation: 0.2,
      color: const Color(0xFFD97706), // Golden dry amber
      linePaint: linePaint,
    );
  }

  // ---------------------------------------------------------------------------
  // STAGE 3: UNHEALTHY PROTECTIVE MASK (AQI 101-150)
  // N95 face mask, concerned eyebrows, wilting brown leaves, slight dust
  // ---------------------------------------------------------------------------
  void _drawUnhealthyMask(
    Canvas canvas,
    Size size,
    Offset faceCenter,
    Offset mouthCenter,
    Paint linePaint,
  ) {
    // 1. Concerned slanted eyebrows
    canvas.drawLine(
      Offset(faceCenter.dx - 10, faceCenter.dy - 5.5),
      Offset(faceCenter.dx - 3, faceCenter.dy - 2.5),
      linePaint,
    );
    canvas.drawLine(
      Offset(faceCenter.dx + 10, faceCenter.dy - 5.5),
      Offset(faceCenter.dx + 3, faceCenter.dy - 2.5),
      linePaint,
    );

    // 2. Protective N95 Face Mask
    _drawN95MaskShape(canvas, mouthCenter, faceCenter, linePaint);

    // 3. Mild sweat droplet on temple
    final sw = Path()
      ..moveTo(faceCenter.dx + 11.5, faceCenter.dy - 7.0)
      ..quadraticBezierTo(faceCenter.dx + 13.5, faceCenter.dy - 3.5, faceCenter.dx + 11.5, faceCenter.dy - 2.0)
      ..quadraticBezierTo(faceCenter.dx + 9.5, faceCenter.dy - 3.5, faceCenter.dx + 11.5, faceCenter.dy - 7.0);
    canvas.drawPath(sw, Paint()..color = const Color(0xFF38BDF8));

    // 4. Wilting Dried Brown Leaves falling down
    final leafFall = (animValue * size.height * 0.35);
    _drawAutumnLeaf(
      canvas,
      Offset(size.width * 0.18, (size.height * 0.30 + leafFall) % size.height),
      rotation: 0.8,
      color: const Color(0xFFB45309), // Dry brown
      linePaint: linePaint,
    );
    _drawAutumnLeaf(
      canvas,
      Offset(size.width * 0.84, (size.height * 0.40 + leafFall) % size.height),
      rotation: -0.7,
      color: const Color(0xFF92400E),
      linePaint: linePaint,
    );

    // 5. Faint grey dust specks
    _drawDustParticle(canvas, Offset(size.width * 0.28, size.height * 0.22), 1.6);
    _drawDustParticle(canvas, Offset(size.width * 0.74, size.height * 0.58), 1.4);
  }

  // ---------------------------------------------------------------------------
  // STAGE 4: VERY UNHEALTHY SAD MASK (AQI 151-200)
  // Visibly sad slumped posture, downturned brows, dark eye-bags, tear/sweat, soot particles
  // ---------------------------------------------------------------------------
  void _drawVeryUnhealthySadMask(
    Canvas canvas,
    Size size,
    Offset faceCenter,
    Offset mouthCenter,
    Paint linePaint,
  ) {
    // 1. Noticeably SAD Downturned Eyebrows (\ /)
    canvas.drawLine(
      Offset(faceCenter.dx - 10, faceCenter.dy - 2.0),
      Offset(faceCenter.dx - 3, faceCenter.dy - 6.0),
      linePaint..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(faceCenter.dx + 10, faceCenter.dy - 2.0),
      Offset(faceCenter.dx + 3, faceCenter.dy - 6.0),
      linePaint,
    );
    linePaint.strokeWidth = 1.6;

    // 2. Heavy Dark Under-Eye Fatigue Bags
    final eyeBagPaint = Paint()
      ..color = (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leftBag = Path()
      ..moveTo(faceCenter.dx - 9.5, faceCenter.dy + 1.5)
      ..quadraticBezierTo(faceCenter.dx - 6.0, faceCenter.dy + 4.2, faceCenter.dx - 2.5, faceCenter.dy + 1.5);
    final rightBag = Path()
      ..moveTo(faceCenter.dx + 2.5, faceCenter.dy + 1.5)
      ..quadraticBezierTo(faceCenter.dx + 6.0, faceCenter.dy + 4.2, faceCenter.dx + 9.5, faceCenter.dy + 1.5);
    canvas.drawPath(leftBag, eyeBagPaint);
    canvas.drawPath(rightBag, eyeBagPaint);

    // 3. Sad Protective N95 Face Mask
    _drawN95MaskShape(canvas, mouthCenter, faceCenter, linePaint, sadCrease: true);

    // 4. Large Distressed Sweat / Tear Droplet dripping down
    final tear = Path()
      ..moveTo(faceCenter.dx + 12.0, faceCenter.dy - 6.0)
      ..quadraticBezierTo(faceCenter.dx + 14.5, faceCenter.dy - 1.5, faceCenter.dx + 12.0, faceCenter.dy + 1.0)
      ..quadraticBezierTo(faceCenter.dx + 9.5, faceCenter.dy - 1.5, faceCenter.dx + 12.0, faceCenter.dy - 6.0);
    canvas.drawPath(tear, Paint()..color = const Color(0xFF0284C7));

    // 5. Crumbling Dead Leaf Fragments
    final crumbFall = (animValue * size.height * 0.45);
    _drawCrumbledLeaf(canvas, Offset(size.width * 0.16, (size.height * 0.35 + crumbFall) % size.height));
    _drawCrumbledLeaf(canvas, Offset(size.width * 0.82, (size.height * 0.20 + crumbFall * 1.1) % size.height));

    // 6. Floating Dark Soot & PM2.5 Dust Particles
    final sootMove = math.sin(animValue * math.pi * 2) * 3;
    _drawDustParticle(canvas, Offset(size.width * 0.22, size.height * 0.25 + sootMove), 2.2, color: const Color(0xFF52525B));
    _drawDustParticle(canvas, Offset(size.width * 0.35, size.height * 0.65 - sootMove), 1.8, color: const Color(0xFF3F3F46));
    _drawDustParticle(canvas, Offset(size.width * 0.78, size.height * 0.38 + sootMove), 2.5, color: const Color(0xFF52525B));
    _drawDustParticle(canvas, Offset(size.width * 0.88, size.height * 0.70 - sootMove), 2.0, color: const Color(0xFF27272A));
  }

  // ---------------------------------------------------------------------------
  // STAGE 5: HAZARDOUS OXYGEN MASK & CYLINDER TANK (AQI 201-300)
  // Transparent medical oxygen cup mask + O2 cylinder on ground with flexible tube, yellow smog
  // ---------------------------------------------------------------------------
  void _drawHazardousOxygenMask(
    Canvas canvas,
    Size size,
    Offset faceCenter,
    Offset mouthCenter,
    Paint linePaint,
  ) {
    // 1. Distressed, Tired Drooping Brows
    canvas.drawLine(
      Offset(faceCenter.dx - 10, faceCenter.dy - 5.5),
      Offset(faceCenter.dx - 3, faceCenter.dy - 2.0),
      linePaint,
    );
    canvas.drawLine(
      Offset(faceCenter.dx + 10, faceCenter.dy - 5.5),
      Offset(faceCenter.dx + 3, faceCenter.dy - 2.0),
      linePaint,
    );

    // 2. Transparent Medical Oxygen Mask Cup
    final maskRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(mouthCenter.dx, mouthCenter.dy + 2.0), width: 19.0, height: 14.0),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      maskRect,
      Paint()..color = const Color(0xFF06B6D4).withValues(alpha: 0.65),
    );
    canvas.drawRRect(maskRect, linePaint);

    // Bottom inlet port
    final barb = Rect.fromLTWH(mouthCenter.dx - 3.0, mouthCenter.dy + 8.5, 6.0, 3.5);
    canvas.drawRect(barb, Paint()..color = const Color(0xFF0891B2));
    canvas.drawRect(barb, linePaint..strokeWidth = 1.0);
    linePaint.strokeWidth = 1.6;

    // Elastic head strap
    canvas.drawLine(
      Offset(mouthCenter.dx - 9.5, mouthCenter.dy + 2.0),
      Offset(faceCenter.dx - 13.0, faceCenter.dy + 3.0),
      linePaint..strokeWidth = 1.2,
    );
    linePaint.strokeWidth = 1.6;

    // Distressed sweat droplets
    final sw1 = Path()
      ..moveTo(faceCenter.dx + 11.5, faceCenter.dy - 8.0)
      ..quadraticBezierTo(faceCenter.dx + 13.5, faceCenter.dy - 4.5, faceCenter.dx + 11.5, faceCenter.dy - 3.0)
      ..quadraticBezierTo(faceCenter.dx + 9.5, faceCenter.dy - 4.5, faceCenter.dx + 11.5, faceCenter.dy - 8.0);
    canvas.drawPath(sw1, Paint()..color = const Color(0xFF38BDF8));

    // 3. Yellowish Toxic Smog Haze Clouds in the background (No leaves!)
    final smogPulse = math.sin(animValue * math.pi * 2) * 4;
    final toxicCloudPaint = Paint()..color = const Color(0xFF78350F).withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.32, size.height * 0.40 + smogPulse), width: 55, height: 26),
      toxicCloudPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.75, size.height * 0.55 - smogPulse), width: 65, height: 32),
      toxicCloudPaint,
    );

    // Toxic floating particulate specks
    _drawDustParticle(canvas, Offset(size.width * 0.25, size.height * 0.30), 2.2, color: const Color(0xFFD97706));
    _drawDustParticle(canvas, Offset(size.width * 0.85, size.height * 0.35), 2.4, color: const Color(0xFFB45309));
  }

  // ---------------------------------------------------------------------------
  // STAGE 6: SEVERE TOXIC WRINKLED & EXHAUSTED (AQI > 300)
  // User: "Face me bahut jyada wrinkles hai, cylinder mask to hai hi, lekin wo bahut sukha hai aur halat kharab hai"
  // Deep forehead wrinkles, crow's feet, sunken cheeks, shivering tremor, cylinder in RED empty zone
  // ---------------------------------------------------------------------------
  void _drawSevereToxicWrinkled(
    Canvas canvas,
    Size size,
    Offset faceCenter,
    Offset mouthCenter,
    Paint linePaint,
  ) {
    // Wrinkle paint styling
    final wrinklePaint = Paint()
      ..color = (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF27272A))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    // 1. Three Prominent Horizontal Forehead Worry / Exhaustion Wrinkles
    final w1 = Path()
      ..moveTo(faceCenter.dx - 8.5, faceCenter.dy - 12.0)
      ..quadraticBezierTo(faceCenter.dx, faceCenter.dy - 13.5, faceCenter.dx + 8.5, faceCenter.dy - 12.0);
    final w2 = Path()
      ..moveTo(faceCenter.dx - 10.0, faceCenter.dy - 9.5)
      ..quadraticBezierTo(faceCenter.dx, faceCenter.dy - 11.0, faceCenter.dx + 10.0, faceCenter.dy - 9.5);
    final w3 = Path()
      ..moveTo(faceCenter.dx - 8.0, faceCenter.dy - 7.0)
      ..quadraticBezierTo(faceCenter.dx, faceCenter.dy - 8.2, faceCenter.dx + 8.0, faceCenter.dy - 7.0);
    canvas.drawPath(w1, wrinklePaint);
    canvas.drawPath(w2, wrinklePaint);
    canvas.drawPath(w3, wrinklePaint);

    // 2. Deep Furrowed Brow Vertical Stress Creases Between Eyes
    canvas.drawLine(
      Offset(faceCenter.dx - 2.0, faceCenter.dy - 6.5),
      Offset(faceCenter.dx - 2.0, faceCenter.dy - 3.0),
      wrinklePaint..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(faceCenter.dx + 2.0, faceCenter.dy - 6.5),
      Offset(faceCenter.dx + 2.0, faceCenter.dy - 3.0),
      wrinklePaint,
    );

    // 3. Tired Weary Heavy Eyebrows
    canvas.drawLine(
      Offset(faceCenter.dx - 11, faceCenter.dy - 4.0),
      Offset(faceCenter.dx - 3, faceCenter.dy - 2.0),
      linePaint..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(faceCenter.dx + 11, faceCenter.dy - 4.0),
      Offset(faceCenter.dx + 3, faceCenter.dy - 2.0),
      linePaint,
    );
    linePaint.strokeWidth = 1.6;

    // 4. Heavy Crow's Feet Wrinkles radiating from outer corners of eyes
    canvas.drawLine(
      Offset(faceCenter.dx - 10.0, faceCenter.dy - 2.5),
      Offset(faceCenter.dx - 13.5, faceCenter.dy - 4.5),
      wrinklePaint..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(faceCenter.dx - 10.0, faceCenter.dy - 1.5),
      Offset(faceCenter.dx - 14.0, faceCenter.dy - 1.5),
      wrinklePaint,
    );
    canvas.drawLine(
      Offset(faceCenter.dx + 10.0, faceCenter.dy - 2.5),
      Offset(faceCenter.dx + 13.5, faceCenter.dy - 4.5),
      wrinklePaint,
    );
    canvas.drawLine(
      Offset(faceCenter.dx + 10.0, faceCenter.dy - 1.5),
      Offset(faceCenter.dx + 14.0, faceCenter.dy - 1.5),
      wrinklePaint,
    );

    // 5. Deep Hollow Under-Eye Bags (Severe exhaustion circles)
    final severeBagPaint = Paint()
      ..color = (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final leftDeepBag = Path()
      ..moveTo(faceCenter.dx - 10.0, faceCenter.dy + 1.2)
      ..quadraticBezierTo(faceCenter.dx - 6.0, faceCenter.dy + 4.8, faceCenter.dx - 2.0, faceCenter.dy + 1.2);
    final rightDeepBag = Path()
      ..moveTo(faceCenter.dx + 2.0, faceCenter.dy + 1.2)
      ..quadraticBezierTo(faceCenter.dx + 6.0, faceCenter.dy + 4.8, faceCenter.dx + 10.0, faceCenter.dy + 1.2);
    canvas.drawPath(leftDeepBag, severeBagPaint);
    canvas.drawPath(rightDeepBag, severeBagPaint);

    // 6. Gaunt Sunken Cheek Hollows ("sukha character / halat kharab")
    final cheekHollowPaint = Paint()
      ..color = (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    // Left sunken cheek curve
    final leftCheek = Path()
      ..moveTo(faceCenter.dx - 11.5, faceCenter.dy + 4.0)
      ..quadraticBezierTo(faceCenter.dx - 8.5, faceCenter.dy + 8.5, faceCenter.dx - 10.5, faceCenter.dy + 13.0);
    // Right sunken cheek curve
    final rightCheek = Path()
      ..moveTo(faceCenter.dx + 11.5, faceCenter.dy + 4.0)
      ..quadraticBezierTo(faceCenter.dx + 8.5, faceCenter.dy + 8.5, faceCenter.dx + 10.5, faceCenter.dy + 13.0);
    canvas.drawPath(leftCheek, cheekHollowPaint);
    canvas.drawPath(rightCheek, cheekHollowPaint);

    // 7. Medical Oxygen Mask Cup strapped tightly
    final maskRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(mouthCenter.dx, mouthCenter.dy + 2.0), width: 19.0, height: 14.0),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      maskRect,
      Paint()..color = const Color(0xFF0891B2).withValues(alpha: 0.75),
    );
    canvas.drawRRect(maskRect, linePaint);

    // Inlet barb
    final barb = Rect.fromLTWH(mouthCenter.dx - 3.0, mouthCenter.dy + 8.5, 6.0, 3.5);
    canvas.drawRect(barb, Paint()..color = const Color(0xFF0E7490));
    canvas.drawRect(barb, linePaint..strokeWidth = 1.0);
    linePaint.strokeWidth = 1.6;

    // Elastic head straps
    canvas.drawLine(
      Offset(mouthCenter.dx - 9.5, mouthCenter.dy + 2.0),
      Offset(faceCenter.dx - 13.5, faceCenter.dy + 3.0),
      linePaint..strokeWidth = 1.3,
    );
    canvas.drawLine(
      Offset(mouthCenter.dx + 9.5, mouthCenter.dy + 2.0),
      Offset(faceCenter.dx + 13.5, faceCenter.dy + 3.0),
      linePaint,
    );
    linePaint.strokeWidth = 1.6;

    // 8. Distressed Shivering Sweat Drops
    final swDrop = Path()
      ..moveTo(faceCenter.dx + 12.5, faceCenter.dy - 8.5)
      ..quadraticBezierTo(faceCenter.dx + 15.0, faceCenter.dy - 4.0, faceCenter.dx + 12.5, faceCenter.dy - 2.0)
      ..quadraticBezierTo(faceCenter.dx + 10.0, faceCenter.dy - 4.0, faceCenter.dx + 12.5, faceCenter.dy - 8.5);
    canvas.drawPath(swDrop, Paint()..color = const Color(0xFF0284C7));

    // 9. Dense Toxic Dark Smog Clouds & Swirling Ash Motes
    final toxicSmog = Paint()..color = const Color(0xFF1C1917).withValues(alpha: 0.38);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.30, size.height * 0.38), width: 70, height: 32),
      toxicSmog,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.78, size.height * 0.52), width: 75, height: 36),
      toxicSmog,
    );

    // Floating Ash & Hazardous Particles
    final ashWave = math.sin(animValue * math.pi * 3) * 2;
    _drawDustParticle(canvas, Offset(size.width * 0.18, size.height * 0.28 + ashWave), 2.8, color: const Color(0xFF451A03));
    _drawDustParticle(canvas, Offset(size.width * 0.34, size.height * 0.62 - ashWave), 2.4, color: const Color(0xFF7F1D1D));
    _drawDustParticle(canvas, Offset(size.width * 0.82, size.height * 0.32 + ashWave), 3.0, color: const Color(0xFF1C1917));
    _drawDustParticle(canvas, Offset(size.width * 0.90, size.height * 0.65 - ashWave), 2.2, color: const Color(0xFF78350F));

    // 10. Warning Biohazard Aura (Red warning pulse around character)
    final pulseAura = math.sin(animValue * math.pi * 2).abs();
    canvas.drawCircle(
      faceCenter + const Offset(0, 8),
      32.0 + (pulseAura * 4.0),
      Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.08 + (pulseAura * 0.08))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ---------------------------------------------------------------------------
  // MEDICAL OXYGEN CYLINDER TANK & COILED DELIVERY TUBE (Stages 5 & 6)
  // ---------------------------------------------------------------------------
  void _drawOxygenCylinderAndTube(
    Canvas canvas,
    Size size,
    double scale,
    double dx0,
    double groundY,
    Offset mouthCenter,
    Paint linePaint, {
    bool isCritical = false,
  }) {
    const tankX = 6.0;
    const tankW = 20.0;
    const bodyH = 40.0;
    final tankBottomY = groundY;
    final tankTopY = tankBottomY - bodyH;

    // Cylinder Base Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(tankX + (tankW / 2), tankBottomY), width: tankW + 4, height: 5),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Cylinder Body (Metallic Deep Green Hospital Medical Grade)
    final cylinderBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(tankX, tankTopY, tankW, bodyH),
      const Radius.circular(5),
    );
    final bodyGradient = LinearGradient(
      colors: isCritical
          ? const [
              Color(0xFF064E3B),
              Color(0xFF047857),
              Color(0xFF475569),
              Color(0xFF064E3B),
            ]
          : const [
              Color(0xFF064E3B),
              Color(0xFF047857),
              Color(0xFF10B981),
              Color(0xFF064E3B),
            ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
    canvas.drawRRect(
      cylinderBody,
      Paint()..shader = bodyGradient.createShader(cylinderBody.outerRect),
    );
    canvas.drawRRect(cylinderBody, linePaint);

    // Cylinder Neck Dome Cap
    final dome = Path()
      ..moveTo(tankX, tankTopY + 2)
      ..quadraticBezierTo(tankX + (tankW / 2), tankTopY - 7, tankX + tankW, tankTopY + 2)
      ..close();
    canvas.drawPath(dome, Paint()..color = const Color(0xFF059669));
    canvas.drawPath(dome, linePaint);

    // Brass Neck Regulator Valve
    final valveRect = Rect.fromLTWH(tankX + (tankW / 2) - 4.5, tankTopY - 13, 9.0, 7.0);
    canvas.drawRect(valveRect, Paint()..color = const Color(0xFFEAB308));
    canvas.drawRect(valveRect, linePaint..strokeWidth = 1.0);

    // Top protective collar ring
    final collar = Rect.fromLTWH(tankX + (tankW / 2) - 3.0, tankTopY - 16, 6.0, 3.5);
    canvas.drawRect(collar, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawRect(collar, linePaint);

    // Pressure Gauge Dial Meter (Round dial on right of valve)
    final gaugeCenter = Offset(tankX + tankW + 2.0, tankTopY - 10.0);
    canvas.drawCircle(gaugeCenter, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(gaugeCenter, 4.5, linePaint);
    // Green safe zone / Red danger zone arcs
    canvas.drawArc(
      Rect.fromCircle(center: gaugeCenter, radius: 3.5),
      -math.pi * 0.8,
      math.pi * 0.6,
      false,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: gaugeCenter, radius: 3.5),
      -math.pi * 0.2,
      math.pi * 0.4,
      false,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Gauge Needle
    final needleEnd = isCritical
        ? Offset(gaugeCenter.dx + 2.2, gaugeCenter.dy + 2.0) // Empty Red Zone
        : Offset(gaugeCenter.dx - 1.5, gaugeCenter.dy - 2.2); // Normal Operating Zone
    canvas.drawLine(
      gaugeCenter,
      needleEnd,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );

    // Critical warning pulse
    if (isCritical) {
      final warnPulse = math.sin(animValue * math.pi * 4).abs();
      canvas.drawCircle(
        gaugeCenter,
        6.0,
        Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.3 * warnPulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Prominent "O₂" Medical Badge on Tank Body
    final o2Painter = TextPainter(
      text: TextSpan(
        text: 'O₂',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    o2Painter.paint(
      canvas,
      Offset(tankX + (tankW - o2Painter.width) / 2, tankTopY + 14),
    );

    // -------------------------------------------------------------------------
    // FLEXIBLE CONNECTING OXYGEN DELIVERY TUBE
    // From cylinder valve outlet -> gracefully sweeps into the character mask!
    // -------------------------------------------------------------------------
    final tubeStart = Offset(tankX + (tankW / 2) + 1.0, tankTopY - 10.0);
    final tubeEnd = Offset(mouthCenter.dx, mouthCenter.dy + 10.0);

    final tube = Path()
      ..moveTo(tubeStart.dx, tubeStart.dy)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.50,
        size.width * 0.42,
        size.height * 0.32,
        tubeEnd.dx,
        tubeEnd.dy,
      );

    // Tube outer glow / turquoise medical casing
    canvas.drawPath(
      tube,
      Paint()
        ..color = isCritical ? const Color(0xFF0891B2) : const Color(0xFF06B6D4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    // Tube inner transparent core
    canvas.drawPath(
      tube,
      Paint()
        ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Animated oxygen pulse bubble flowing along tube
    final pulseT = animValue % 1.0;
    final p0 = tubeStart;
    final p1 = Offset(size.width * 0.28, size.height * 0.50);
    final p2 = Offset(size.width * 0.42, size.height * 0.32);
    final p3 = tubeEnd;
    final oneMinusT = 1.0 - pulseT;
    final pulseX = (math.pow(oneMinusT, 3) * p0.dx) +
        (3 * math.pow(oneMinusT, 2) * pulseT * p1.dx) +
        (3 * oneMinusT * math.pow(pulseT, 2) * p2.dx) +
        (math.pow(pulseT, 3) * p3.dx);
    final pulseY = (math.pow(oneMinusT, 3) * p0.dy) +
        (3 * math.pow(oneMinusT, 2) * pulseT * p1.dy) +
        (3 * oneMinusT * math.pow(pulseT, 2) * p2.dy) +
        (math.pow(pulseT, 3) * p3.dy);

    canvas.drawCircle(
      Offset(pulseX, pulseY),
      2.2,
      Paint()..color = isCritical ? const Color(0xFF67E8F9) : const Color(0xFF38BDF8),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER SHAPE RENDERERS
  // ---------------------------------------------------------------------------
  void _drawN95MaskShape(
    Canvas canvas,
    Offset mouthCenter,
    Offset faceCenter,
    Paint linePaint, {
    bool sadCrease = false,
  }) {
    final mask = Path()
      ..moveTo(mouthCenter.dx - 9.5, mouthCenter.dy - 2.5)
      ..lineTo(mouthCenter.dx, mouthCenter.dy - 6.5) // nose bridge apex
      ..lineTo(mouthCenter.dx + 9.5, mouthCenter.dy - 2.5)
      ..lineTo(mouthCenter.dx + 8.5, mouthCenter.dy + 8.5) // right chin
      ..lineTo(mouthCenter.dx - 8.5, mouthCenter.dy + 8.5) // left chin
      ..close();

    // Clean white mask body with 3D contour
    canvas.drawPath(mask, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawPath(mask, linePaint);

    // Center vertical contour fold seam
    if (sadCrease) {
      final crease = Path()
        ..moveTo(mouthCenter.dx, mouthCenter.dy - 6.5)
        ..quadraticBezierTo(mouthCenter.dx - 1.5, mouthCenter.dy + 1.0, mouthCenter.dx, mouthCenter.dy + 8.5);
      canvas.drawPath(
        crease,
        Paint()
          ..color = const Color(0xFF94A3B8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    } else {
      canvas.drawLine(
        Offset(mouthCenter.dx, mouthCenter.dy - 6.5),
        Offset(mouthCenter.dx, mouthCenter.dy + 8.5),
        Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 1.0,
      );
    }

    // Metallic nose-bridge clip accent
    canvas.drawLine(
      Offset(mouthCenter.dx - 4.5, mouthCenter.dy - 5.0),
      Offset(mouthCenter.dx + 4.5, mouthCenter.dy - 5.0),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // Dual elastic head / ear loop straps
    linePaint.strokeWidth = 1.1;
    canvas.drawLine(
      Offset(mouthCenter.dx - 9.5, mouthCenter.dy - 2.5),
      Offset(faceCenter.dx - 12.0, faceCenter.dy - 1.5),
      linePaint,
    );
    canvas.drawLine(
      Offset(mouthCenter.dx - 8.5, mouthCenter.dy + 6.0),
      Offset(faceCenter.dx - 11.0, faceCenter.dy + 8.0),
      linePaint,
    );
    linePaint.strokeWidth = 1.6;
  }

  void _drawVibrantLeaf(
    Canvas canvas,
    Offset center, {
    required double rotation,
    required Color color,
    required Paint linePaint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final leaf = Path()
      ..moveTo(0, -6)
      ..quadraticBezierTo(5, -3, 0, 6)
      ..quadraticBezierTo(-5, -3, 0, -6)
      ..close();

    canvas.drawPath(leaf, Paint()..color = color);
    canvas.drawPath(
      leaf,
      linePaint
        ..strokeWidth = 0.9
        ..color = (isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B)).withValues(alpha: 0.6),
    );

    // Center vein
    canvas.drawLine(
      const Offset(0, -5),
      const Offset(0, 5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 0.8,
    );

    canvas.restore();
  }

  void _drawAutumnLeaf(
    Canvas canvas,
    Offset center, {
    required double rotation,
    required Color color,
    required Paint linePaint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Curled autumn leaf contour
    final leaf = Path()
      ..moveTo(0, -6.5)
      ..quadraticBezierTo(6, -2, 1, 6.5)
      ..quadraticBezierTo(-4, 0, 0, -6.5)
      ..close();

    canvas.drawPath(leaf, Paint()..color = color);
    canvas.drawPath(
      leaf,
      linePaint
        ..strokeWidth = 0.9
        ..color = (isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B)).withValues(alpha: 0.5),
    );
    canvas.restore();
  }

  void _drawCrumbledLeaf(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF78350F);
    canvas.drawCircle(center, 1.8, p);
    canvas.drawCircle(center + const Offset(2.2, -1.5), 1.2, p);
    canvas.drawCircle(center + const Offset(-1.8, 2.0), 1.0, p);
  }

  void _drawSparkle(Canvas canvas, Offset center, Color color) {
    final sp = Path()
      ..moveTo(center.dx, center.dy - 3.5)
      ..lineTo(center.dx + 2.2, center.dy)
      ..lineTo(center.dx, center.dy + 3.5)
      ..lineTo(center.dx - 2.2, center.dy)
      ..close();
    canvas.drawPath(sp, Paint()..color = color);
  }

  void _drawDustParticle(Canvas canvas, Offset center, double radius, {Color? color}) {
    final p = Paint()..color = (color ?? const Color(0xFF71717A)).withValues(alpha: 0.75);
    canvas.drawCircle(center, radius, p);
  }

  @override
  bool shouldRepaint(covariant _AqiScenarioOverlayPainter old) =>
      old.mood != mood ||
      old.animValue != animValue ||
      old.charOffset != charOffset ||
      old.isDark != isDark ||
      old.theme != theme;
}

// PROMINENT LARGE ANIMATED WEATHER SVG ICON (SUN, MOON, CLOUD, RAIN, THUNDER, FLOOD, TWISTER)
// ---------------------------------------------------------------------------
class _BigAnimatedWeatherIcon extends StatelessWidget {
  final _EffectiveWeather weather;
  final MoonPhaseInfo moonPhase;
  final double animProgress;
  final double lightningProgress;
  final double floodProgress;
  final double twisterProgress;

  const _BigAnimatedWeatherIcon({
    required this.weather,
    required this.moonPhase,
    required this.animProgress,
    required this.lightningProgress,
    required this.floodProgress,
    required this.twisterProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _BigWeatherIconPainter(
          weather: weather,
          moonPhase: moonPhase,
          animProgress: animProgress,
          lightningProgress: lightningProgress,
          floodProgress: floodProgress,
          twisterProgress: twisterProgress,
        ),
      ),
    );
  }
}

class _BigWeatherIconPainter extends CustomPainter {
  final _EffectiveWeather weather;
  final MoonPhaseInfo moonPhase;
  final double animProgress;
  final double lightningProgress;
  final double floodProgress;
  final double twisterProgress;

  _BigWeatherIconPainter({
    required this.weather,
    required this.moonPhase,
    required this.animProgress,
    required this.lightningProgress,
    required this.floodProgress,
    required this.twisterProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    if (weather.isTwister) {
      // Swirling Tornado Twister Funnel
      _drawBigTornado(canvas, w, h, center);
    } else if (weather.isFlood) {
      // Rushing Mountain Flood Wave
      _drawBigFlood(canvas, w, h, center);
    } else if (weather.isThunder) {
      // Thunderhead cloud with live lightning bolt
      _drawBigThunder(canvas, w, h, center);
    } else if (weather.isRain) {
      // Rain cloud with animated falling drops
      _drawBigRain(canvas, w, h, center);
    } else if (weather.isCloudy) {
      // Billowing soft clouds
      _drawBigCloud(canvas, w, h, center);
    } else if (weather.isDay) {
      // Blazing Sun with rotating flares
      _drawBigSun(canvas, w, h, center);
    } else {
      // Glowing Moon with exact phase face
      _drawBigMoon(canvas, w, h, center);
    }
  }

  void _drawBigSun(Canvas canvas, double w, double h, Offset center) {
    // Outer solar corona
    final corona = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withValues(alpha: 0.7),
          const Color(0xFFF59E0B).withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.48));
    canvas.drawCircle(center, w * 0.48, corona);

    // Rotating solar rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final rot = animProgress * math.pi * 2;
    for (int i = 0; i < 8; i++) {
      final angle = rot + (i * (math.pi / 4));
      final p1 = Offset(center.dx + math.cos(angle) * (w * 0.26), center.dy + math.sin(angle) * (w * 0.26));
      final p2 = Offset(center.dx + math.cos(angle) * (w * 0.38), center.dy + math.sin(angle) * (w * 0.38));
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Golden Core
    final sunCore = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.22));
    canvas.drawCircle(center, w * 0.22, sunCore);
  }

  void _drawBigMoon(Canvas canvas, double w, double h, Offset center) {
    final r = w * 0.24;

    // Moonlight halo
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE0E7FF).withValues(alpha: 0.5),
          const Color(0xFFC7D2FE).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.8));
    canvas.drawCircle(center, r * 1.8, glow);

    // Moon disc with exact phase
    final darkBase = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(center, r, darkBase);

    final litPaint = Paint()..color = const Color(0xFFFEF08A);
    final phase = moonPhase.phase;

    final path = Path();
    if (phase >= 0.0 && phase <= 0.5) {
      path.addArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2, math.pi);
      final k = (0.25 - phase) / 0.25;
      final rInner = (r * k).abs();
      final sweep = k >= 0 ? -math.pi : math.pi;
      path.arcTo(
        Rect.fromCenter(center: center, width: rInner * 2, height: r * 2),
        math.pi / 2,
        sweep,
        false,
      );
    } else {
      path.addArc(Rect.fromCircle(center: center, radius: r), math.pi / 2, math.pi);
      final k = (0.75 - phase) / 0.25;
      final rInner = (r * k).abs();
      final sweep = k >= 0 ? math.pi : -math.pi;
      path.arcTo(
        Rect.fromCenter(center: center, width: rInner * 2, height: r * 2),
        -math.pi / 2,
        sweep,
        false,
      );
    }
    path.close();
    canvas.drawPath(path, litPaint);

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, r, stroke);
  }

  void _drawBigCloud(Canvas canvas, double w, double h, Offset center) {
    final cloudPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFE2E8F0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final cy = center.dy - 2;
    canvas.drawCircle(Offset(center.dx - 12, cy + 2), 16, cloudPaint);
    canvas.drawCircle(Offset(center.dx + 4, cy - 6), 20, cloudPaint);
    canvas.drawCircle(Offset(center.dx + 20, cy + 4), 14, cloudPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 22, cy + 2, 48, 18),
        const Radius.circular(9),
      ),
      cloudPaint,
    );
  }

  void _drawBigRain(Canvas canvas, double w, double h, Offset center) {
    _drawBigCloud(canvas, w, h, Offset(center.dx, center.dy - 8));

    // Animated raindrop streaks
    final rainPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final x = center.dx - 16 + (i * 10);
      final dropProgress = (animProgress * 3.0 + (i * 0.25)) % 1.0;
      final yStart = center.dy + 8 + (dropProgress * 14.0);
      canvas.drawLine(Offset(x, yStart), Offset(x - 2, yStart + 8), rainPaint);
    }
  }

  void _drawBigThunder(Canvas canvas, double w, double h, Offset center) {
    // Dark moody storm cloud
    final darkCloud = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF64748B), Color(0xFF334155)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final cy = center.dy - 10;
    canvas.drawCircle(Offset(center.dx - 12, cy + 2), 16, darkCloud);
    canvas.drawCircle(Offset(center.dx + 4, cy - 6), 20, darkCloud);
    canvas.drawCircle(Offset(center.dx + 20, cy + 4), 14, darkCloud);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 22, cy + 2, 48, 18),
        const Radius.circular(9),
      ),
      darkCloud,
    );

    // Glowing zigzag lightning bolt
    final isFlashing = lightningProgress > 0.85;
    final boltColor = isFlashing ? const Color(0xFFFEF08A) : const Color(0xFFFBBF24);

    final bolt = Path();
    bolt.moveTo(center.dx + 2, center.dy - 4);
    bolt.lineTo(center.dx - 8, center.dy + 12);
    bolt.lineTo(center.dx, center.dy + 12);
    bolt.lineTo(center.dx - 6, center.dy + 28);
    bolt.lineTo(center.dx + 8, center.dy + 8);
    bolt.lineTo(center.dx + 1, center.dy + 8);
    bolt.close();

    final boltPaint = Paint()
      ..color = boltColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bolt, boltPaint);

    // Halo glow
    if (isFlashing) {
      final halo = Paint()
        ..color = const Color(0xFFFEF08A).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawPath(bolt, halo);
    }
  }

  void _drawBigFlood(Canvas canvas, double w, double h, Offset center) {
    // Surging mountain flood waves
    final wave1 = Path();
    wave1.moveTo(center.dx - 28, center.dy + 12);
    wave1.quadraticBezierTo(center.dx - 14, center.dy - 8 + (math.sin(floodProgress * math.pi * 2) * 4), center.dx, center.dy + 8);
    wave1.quadraticBezierTo(center.dx + 14, center.dy + 22 - (math.sin(floodProgress * math.pi * 2) * 4), center.dx + 28, center.dy + 6);
    wave1.lineTo(center.dx + 28, center.dy + 24);
    wave1.lineTo(center.dx - 28, center.dy + 24);
    wave1.close();

    final floodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(wave1, floodPaint);

    // White foam crests
    final foam = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 22, center.dy + 4), Offset(center.dx - 8, center.dy + 6), foam);
    canvas.drawLine(Offset(center.dx + 6, center.dy + 12), Offset(center.dx + 22, center.dy + 8), foam);
  }

  void _drawBigTornado(Canvas canvas, double w, double h, Offset center) {
    // Swirling Twister Funnel
    final rot = twisterProgress * math.pi * 2;
    const topW = 28.0;
    const botW = 6.0;

    final funnel = Path();
    funnel.moveTo(center.dx - (topW / 2), center.dy - 20);
    funnel.lineTo(center.dx + (topW / 2), center.dy - 20);
    funnel.quadraticBezierTo(center.dx + (botW / 2) + 4, center.dy, center.dx + (botW / 2), center.dy + 22);
    funnel.lineTo(center.dx - (botW / 2), center.dy + 22);
    funnel.quadraticBezierTo(center.dx - (botW / 2) - 4, center.dy, center.dx - (topW / 2), center.dy - 20);
    funnel.close();

    final tornadoPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF94A3B8), Color(0xFF475569)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(funnel, tornadoPaint);

    // Spiraling wind debris orbits
    final debris = Paint()..color = const Color(0xFF1E293B);
    for (int i = 0; i < 4; i++) {
      final a = rot + (i * (math.pi / 2));
      final orbitY = center.dy - 12 + (i * 9);
      final orbitW = (topW - (i * 6));
      final x = center.dx + (math.cos(a) * (orbitW / 2));
      canvas.drawCircle(Offset(x, orbitY), 2.0, debris);
    }
  }

  @override
  bool shouldRepaint(covariant _BigWeatherIconPainter old) => true;
}
