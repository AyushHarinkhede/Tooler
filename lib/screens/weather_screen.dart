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
  int _forecastTab = 0; // 0: Hourly 24h, 1: 14 Days, 2: Past 7 Days, 3: Next 7 Days
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
                          // 1. Modern Themed Hero Container (No landscape/river, SVG Sun/Moon/Cloud/Thunder/Rain + Lunar Trajectory arc, Character in center, Weather Degree, AQI in UI font, PM rating, Live Location, zero extra captions)
                          _buildModernWeatherHeroCard(theme, isDark, weather, rawData),
                          const SizedBox(height: 14),

                          // 2. Sleek Moon Phase Bar (Single bar with Aaj ka Moon Phase, tap to open 7/8 moon phases circular orbit hover sheet)
                          _buildMoonPhaseBar(theme, isDark, rawData.moonPhase),
                          const SizedBox(height: 14),

                          // 3. Simple Clean Graph (Hourly 24h & 14-Day Past/Future trends with toggle)
                          _buildForecastGraphCard(theme, isDark, rawData),
                          const SizedBox(height: 14),

                          // 4. Detailed Atmospheric Metrics Grid
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
  // 1. MODERN THEMED WEATHER HERO CARD
  // - Top: Celestial Lunar / Solar Trajectory Arc + SVG Sun/Moon/Cloud/Thunder/Rain/Disasters
  // - Middle: Tooler Reactive Vector Mascot + Temperature, AQI in UI font, PM rating, Location
  // - Zero extra captions or verbose text!
  // ---------------------------------------------------------------------------
  Widget _buildModernWeatherHeroCard(
    StationeryTheme theme,
    bool isDark,
    _EffectiveWeather weather,
    WeatherTelemetryData raw,
  ) {
    final displayTemp = _toDisplayTemp(weather.tempC).round();
    final displayUnit = _tempUnit();

    // Progressive 6-Stage Character AQI Logic
    final _AqiCharacterMood mood;
    if (weather.aqi <= 50) {
      mood = _AqiCharacterMood.cleanAirBreathe;
    } else if (weather.aqi <= 100) {
      mood = _AqiCharacterMood.mildCoughAutumn;
    } else if (weather.aqi <= 150) {
      mood = _AqiCharacterMood.unhealthyMask;
    } else if (weather.aqi <= 200) {
      mood = _AqiCharacterMood.veryUnhealthySadMask;
    } else if (weather.aqi <= 300) {
      mood = _AqiCharacterMood.hazardousOxygenCylinder;
    } else {
      mood = _AqiCharacterMood.severeToxicWrinkled;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upper Visuals: Animated Celestial Trajectory Arc + SVG Sun/Moon/Cloud/Thunder/Rain/Disasters
          SizedBox(
            height: 124,
            child: Stack(
              children: [
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
                        painter: _CelestialSkySvgPainter(
                          weather: weather,
                          moonPhase: raw.moonPhase,
                          animProgress: _animController.value,
                          lightningProgress: _lightningController.value,
                          floodProgress: _floodController.value,
                          twisterProgress: _twisterController.value,
                          isDark: isDark,
                          accentColor: theme.primary,
                        ),
                      );
                    },
                  ),
                ),

                // Top Left: Condition Badge
                Positioned(
                  top: 12,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF1E1E22) : Colors.white).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.border.withValues(alpha: 0.6), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _telemetry.getWeatherIcon(
                            weather.isRain
                                ? 61
                                : (weather.isThunder
                                    ? 95
                                    : (weather.isCloudy ? 2 : (weather.isDay ? 1 : 0))),
                            weather.isDay,
                          ),
                          size: 13,
                          color: theme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          weather.condition,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right: Live Location Badge
                Positioned(
                  top: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF1E1E22) : Colors.white).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.border.withValues(alpha: 0.6), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 4),
                        Text(
                          '${weather.city}, ${weather.country}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
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

          // Lower Section: Reactive Vector Character + Temperature, AQI, PM Rating, Location
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Middle Main Character (Reactive AQI Mascot with Upgraded SVGs)
                AnimatedBuilder(
                  animation: _coughController,
                  builder: (context, _) {
                    return _AqiToolerCharacter(
                      mood: mood,
                      theme: theme,
                      isDark: isDark,
                      animValue: _coughController.value,
                      width: 126,
                      height: 112,
                    );
                  },
                ),
                const SizedBox(width: 16),

                // Side Data: Degree, AQI, PM Rating, Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Weather Degree
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$displayTemp',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: theme.text,
                              letterSpacing: -1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 3),
                            child: Text(
                              displayUnit,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // AQI in Tooler theme color font
                      Text(
                        'AQI ${weather.aqi} • ${weather.aqiStatus}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: weather.aqiColor,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // PM Rating
                      Text(
                        'PM2.5: ${raw.pm25} µg/m³  •  PM10: ${raw.pm10} µg/m³',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Live Location
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${weather.city}, ${weather.country}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SLEEK MOON PHASE BAR (Aaj ka Moon Phase, tap to open circular hover sheet)
  // ---------------------------------------------------------------------------
  Widget _buildMoonPhaseBar(StationeryTheme theme, bool isDark, MoonPhaseInfo moon) {
    return InkWell(
      onTap: () {
        SoundService().playTap();
        HapticFeedback.selectionClick();
        _showCircularMoonPhasesModal(context, theme, isDark, moon);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini Vector Moon
            SizedBox(
              width: 28,
              height: 28,
              child: CustomPaint(
                painter: _VectorMoonPhasePainter(phase: moon.phase, isDark: isDark),
              ),
            ),
            const SizedBox(width: 12),

            // Moon Phase Name & Illumination
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moon.phaseName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  Text(
                    '${moon.illuminationPercent.round()}% Illumination • Today\'s Phase',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 7 Phases Button Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primary.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '7 Phases',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: theme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HOVER PAGE: 7/8 MOON PHASES IN CIRCULAR ORBIT AROUND CENTRAL MOON
  // ---------------------------------------------------------------------------
  void _showCircularMoonPhasesModal(
    BuildContext context,
    StationeryTheme theme,
    bool isDark,
    MoonPhaseInfo currentMoon,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _CircularMoonPhasesSheet(
          theme: theme,
          isDark: isDark,
          currentMoon: currentMoon,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CLEAN FORECAST GRAPH CARD (Hourly 24h & 14-Day Past/Future trends)
  // ---------------------------------------------------------------------------
  Widget _buildForecastGraphCard(StationeryTheme theme, bool isDark, WeatherTelemetryData raw) {
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
          // Header Row with Title and 4-way Segmented Toggle: Hourly | 14 Days | Past 7D | Next 7D
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weather Trend',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: theme.text,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildForecastTabBtn('Hourly', 0, theme, isDark),
                    _buildForecastTabBtn('14d', 1, theme, isDark),
                    _buildForecastTabBtn('Past 7d', 2, theme, isDark),
                    _buildForecastTabBtn('Next 7d', 3, theme, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Graph Body (Hourly vs Daily)
          if (_forecastTab == 0)
            _buildHourlyGraphView(theme, isDark, raw.hourlyList)
          else
            _buildDailyGraphView(theme, isDark, raw.dailyList),
        ],
      ),
    );
  }

  Widget _buildHourlyGraphView(
    StationeryTheme theme,
    bool isDark,
    List<HourlyForecastItem> hours,
  ) {
    if (hours.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hourly data available',
            style: GoogleFonts.plusJakartaSans(color: theme.textSecondary),
          ),
        ),
      );
    }

    double minT = 999;
    double maxT = -999;
    for (final h in hours) {
      if (h.tempC < minT) minT = h.tempC;
      if (h.tempC > maxT) maxT = h.tempC;
    }
    if ((maxT - minT).abs() < 1) maxT = minT + 5;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: hours.map((item) {
          final tempVal = _toDisplayTemp(item.tempC).round();
          final norm = ((item.tempC - minT) / (maxT - minT)).clamp(0.0, 1.0);
          final barHeight = 26.0 + (norm * 44.0);
          final hourStr = item.isNow ? 'Now' : _formatHour(item.hour);

          return Container(
            width: 52,
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
            decoration: BoxDecoration(
              color: item.isNow
                  ? theme.primary.withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.isNow ? theme.primary : theme.border.withValues(alpha: 0.4),
                width: item.isNow ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hour label
                Text(
                  hourStr,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: item.isNow ? FontWeight.w900 : FontWeight.w700,
                    color: item.isNow ? theme.primary : theme.text,
                  ),
                ),
                const SizedBox(height: 6),

                // Weather Icon
                Icon(
                  _telemetry.getWeatherIcon(item.weatherCode, item.isDay),
                  size: 17,
                  color: [0, 1].contains(item.weatherCode)
                      ? (item.isDay ? const Color(0xFFF59E0B) : const Color(0xFF818CF8))
                      : ([95, 96, 99].contains(item.weatherCode)
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF0284C7)),
                ),
                const SizedBox(height: 8),

                // Temperature text
                Text(
                  '$tempVal°',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 5),

                // Visual Temperature Bar
                Container(
                  width: 7,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        item.isNow ? theme.primary : const Color(0xFFF97316),
                        const Color(0xFF38BDF8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Rain Probability or dot
                if (item.precipProb > 0)
                  Text(
                    '${item.precipProb}%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0284C7),
                    ),
                  )
                else
                  Text(
                    '•',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      color: theme.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyGraphView(
    StationeryTheme theme,
    bool isDark,
    List<DailyForecastItem> dailyList,
  ) {
    List<DailyForecastItem> items;
    if (_forecastTab == 2) {
      items = dailyList.where((d) => d.isPast).toList();
    } else if (_forecastTab == 3) {
      items = dailyList.where((d) => !d.isPast).toList();
    } else {
      items = dailyList;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((item) {
          final maxT = _toDisplayTemp(item.maxTempC).round();
          final minT = _toDisplayTemp(item.minTempC).round();
          final dayLabel = _formatDayLabel(item.date, item.isToday);
          final dateLabel = '${item.date.day}/${item.date.month}';

          return Container(
            width: 56,
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: item.isToday
                  ? theme.primary.withValues(alpha: 0.12)
                  : (item.isPast
                      ? (isDark ? const Color(0xFF222226) : const Color(0xFFF9FAFB))
                      : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5))),
              borderRadius: BorderRadius.circular(12),
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
                // Day Name & Date
                Text(
                  dayLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: item.isToday ? FontWeight.w900 : FontWeight.w700,
                    color: item.isToday ? theme.primary : theme.text,
                  ),
                ),
                Text(
                  dateLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),

                // Weather Icon
                Icon(
                  _telemetry.getWeatherIcon(item.weatherCode, true),
                  size: 18,
                  color: [0, 1].contains(item.weatherCode)
                      ? const Color(0xFFF59E0B)
                      : ([95, 96, 99].contains(item.weatherCode)
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF0284C7)),
                ),
                const SizedBox(height: 6),

                // Max Temp
                Text(
                  '$maxT°',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFEF4444),
                  ),
                ),

                // Range Bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 7,
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

                // Min Temp
                Text(
                  '$minT°',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(height: 5),

                // Rain Prob
                if (item.precipProb > 0)
                  Text(
                    '${item.precipProb}%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0284C7),
                    ),
                  )
                else
                  Text(
                    '•',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      color: theme.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForecastTabBtn(String label, int tabIndex, StationeryTheme theme, bool isDark) {
    final isSelected = _forecastTab == tabIndex;
    return InkWell(
      onTap: () {
        SoundService().playTap();
        setState(() => _forecastTab = tabIndex);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
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
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? theme.primary : theme.textSecondary,
          ),
        ),
      ),
    );
  }

  static String _formatHour(int h) {
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hr = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hr $ampm';
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
// CELESTIAL SKY SVG PAINTER (Lunar / Solar Trajectory Arc + SVG Sun/Moon/Clouds/Rain/Thunder/Disasters)
// ---------------------------------------------------------------------------
class _CelestialSkySvgPainter extends CustomPainter {
  final _EffectiveWeather weather;
  final MoonPhaseInfo moonPhase;
  final double animProgress;
  final double lightningProgress;
  final double floodProgress;
  final double twisterProgress;
  final bool isDark;
  final Color accentColor;

  _CelestialSkySvgPainter({
    required this.weather,
    required this.moonPhase,
    required this.animProgress,
    required this.lightningProgress,
    required this.floodProgress,
    required this.twisterProgress,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient tailored to weather conditions
    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final Gradient grad;
    if (weather.isTwister) {
      grad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF132E27)],
      );
    } else if (weather.isThunder || weather.isFlood) {
      grad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
      );
    } else if (weather.isRain) {
      grad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
            : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
      );
    } else if (weather.isDay) {
      grad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4)],
      );
    } else {
      grad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF090D1A), Color(0xFF0F172A)],
      );
    }
    canvas.drawRect(rect, Paint()..shader = grad.createShader(rect));

    // 2. Stars at night
    if (!weather.isDay) {
      final starPaint = Paint()..color = Colors.white;
      final stars = [
        Offset(w * 0.12, h * 0.28),
        Offset(w * 0.24, h * 0.18),
        Offset(w * 0.38, h * 0.34),
        Offset(w * 0.62, h * 0.20),
        Offset(w * 0.76, h * 0.32),
        Offset(w * 0.88, h * 0.16),
      ];
      for (int i = 0; i < stars.length; i++) {
        final twinkle = (math.sin((animProgress * math.pi * 2) + i * 1.5) + 1.0) / 2.0;
        starPaint.color = Colors.white.withValues(alpha: 0.25 + (twinkle * 0.65));
        canvas.drawCircle(stars[i], 1.0 + (twinkle * 0.8), starPaint);
      }
    }

    // 3. SVG Celestial Lunar / Solar Trajectory Arc across the top
    final p0 = Offset(w * 0.08, h * 0.82);
    final p1 = Offset(w * 0.50, h * 0.18);
    final p2 = Offset(w * 0.92, h * 0.82);

    final dashPaint = Paint()
      ..color = (isDark ? Colors.white : accentColor).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    const dashCount = 28;
    for (int i = 0; i <= dashCount; i++) {
      final t = i / dashCount;
      if (i % 2 == 0) {
        final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
        final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
        canvas.drawCircle(Offset(x, y), 1.2, dashPaint);
      }
    }

    // Dynamic celestial position along the trajectory arc
    final now = DateTime.now();
    final hour = now.hour + (now.minute / 60.0);
    final double arcT;
    if (weather.isDay) {
      arcT = ((hour - 6.0) / 12.0).clamp(0.12, 0.88);
    } else {
      final nightHour = hour < 6.0 ? hour + 18.0 : hour - 6.0;
      arcT = (nightHour / 12.0).clamp(0.12, 0.88);
    }

    final celestialX = (1 - arcT) * (1 - arcT) * p0.dx + 2 * (1 - arcT) * arcT * p1.dx + arcT * arcT * p2.dx;
    final celestialY = (1 - arcT) * (1 - arcT) * p0.dy + 2 * (1 - arcT) * arcT * p1.dy + arcT * arcT * p2.dy;

    // Glowing coordinate tick on the trajectory arc
    final nodeGlow = Paint()
      ..color = (weather.isDay ? const Color(0xFFFBBF24) : const Color(0xFFE0E7FF)).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(celestialX, celestialY), 7.0, nodeGlow);

    // 4. Paint Sun or Moon at the celestial coordinate
    if (weather.isDay) {
      _paintSvgSun(canvas, Offset(celestialX, celestialY));
    } else {
      _paintSvgMoon(canvas, Offset(celestialX, celestialY));
    }

    // 5. Paint SVG Weather Overlays: Clouds, Rain, Thunder Lightning, Disasters
    if (weather.isTwister) {
      _paintSvgTwister(canvas, w, h);
    } else if (weather.isFlood) {
      _paintSvgFlood(canvas, w, h);
    } else if (weather.isThunder) {
      _paintSvgThunder(canvas, w, h);
    } else if (weather.isRain) {
      _paintSvgRain(canvas, w, h);
    } else if (weather.isCloudy) {
      _paintSvgClouds(canvas, w, h);
    }
  }

  void _paintSvgSun(Canvas canvas, Offset center) {
    const r = 13.0;
    // Corona
    final corona = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withValues(alpha: 0.65),
          const Color(0xFFF59E0B).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.2));
    canvas.drawCircle(center, r * 2.2, corona);

    // Rotating solar rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final rot = animProgress * math.pi * 2;
    for (int i = 0; i < 8; i++) {
      final angle = rot + (i * (math.pi / 4));
      final p1 = Offset(center.dx + math.cos(angle) * (r * 1.25), center.dy + math.sin(angle) * (r * 1.25));
      final p2 = Offset(center.dx + math.cos(angle) * (r * 1.8), center.dy + math.sin(angle) * (r * 1.8));
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Golden Core
    final sunCore = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, sunCore);
  }

  void _paintSvgMoon(Canvas canvas, Offset center) {
    const r = 12.0;
    // Glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE0E7FF).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.0));
    canvas.drawCircle(center, r * 2.0, glow);

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
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, r, stroke);
  }

  void _paintSvgClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()
      ..color = (isDark ? const Color(0xFF475569) : Colors.white).withValues(alpha: 0.85);

    final floatOffset = math.sin(animProgress * math.pi * 2) * 8.0;

    // Cloud 1
    final c1x = w * 0.30 + floatOffset;
    final c1y = h * 0.62;
    _drawCloudShape(canvas, Offset(c1x, c1y), 1.0, cloudPaint);

    // Cloud 2
    final c2x = w * 0.72 - floatOffset;
    final c2y = h * 0.52;
    _drawCloudShape(canvas, Offset(c2x, c2y), 0.82, cloudPaint);
  }

  void _drawCloudShape(Canvas canvas, Offset center, double scale, Paint paint) {
    canvas.drawCircle(Offset(center.dx - 10 * scale, center.dy + 2 * scale), 12 * scale, paint);
    canvas.drawCircle(Offset(center.dx + 4 * scale, center.dy - 4 * scale), 16 * scale, paint);
    canvas.drawCircle(Offset(center.dx + 16 * scale, center.dy + 3 * scale), 11 * scale, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 18 * scale, center.dy + 2 * scale, 38 * scale, 14 * scale),
        Radius.circular(7 * scale),
      ),
      paint,
    );
  }

  void _paintSvgRain(Canvas canvas, double w, double h) {
    // Rain cloud
    final darkCloud = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)).withValues(alpha: 0.9);
    _drawCloudShape(canvas, Offset(w * 0.50, h * 0.45), 1.1, darkCloud);

    // Falling rain streaks
    final rainPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final x = w * 0.38 + (i * 12);
      final dropProg = (animProgress * 4.0 + (i * 0.22)) % 1.0;
      final yStart = h * 0.58 + (dropProg * 36.0);
      canvas.drawLine(Offset(x, yStart), Offset(x - 2, yStart + 8), rainPaint);
    }
  }

  void _paintSvgThunder(Canvas canvas, double w, double h) {
    // Storm cloud
    final darkCloud = Paint()
      ..color = (isDark ? const Color(0xFF1E293B) : const Color(0xFF475569)).withValues(alpha: 0.95);
    _drawCloudShape(canvas, Offset(w * 0.50, h * 0.42), 1.15, darkCloud);

    // Live flashing lightning bolt
    final isFlashing = lightningProgress > 0.85;
    final bolt = Path();
    bolt.moveTo(w * 0.52, h * 0.46);
    bolt.lineTo(w * 0.46, h * 0.64);
    bolt.lineTo(w * 0.52, h * 0.64);
    bolt.lineTo(w * 0.47, h * 0.84);
    bolt.lineTo(w * 0.58, h * 0.60);
    bolt.lineTo(w * 0.53, h * 0.60);
    bolt.close();

    final boltPaint = Paint()
      ..color = isFlashing ? const Color(0xFFFEF08A) : const Color(0xFFFBBF24);
    canvas.drawPath(bolt, boltPaint);

    if (isFlashing) {
      final halo = Paint()
        ..color = const Color(0xFFFEF08A).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawPath(bolt, halo);
    }
  }

  void _paintSvgFlood(Canvas canvas, double w, double h) {
    // Flood wave surge
    final wave = Path();
    wave.moveTo(0, h * 0.82);
    final waveShift = math.sin(floodProgress * math.pi * 2) * 5.0;
    wave.quadraticBezierTo(w * 0.25, h * 0.74 + waveShift, w * 0.50, h * 0.82);
    wave.quadraticBezierTo(w * 0.75, h * 0.90 - waveShift, w, h * 0.80);
    wave.lineTo(w, h);
    wave.lineTo(0, h);
    wave.close();

    final wavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.30));
    canvas.drawPath(wave, wavePaint);
  }

  void _paintSvgTwister(Canvas canvas, double w, double h) {
    final cx = w * 0.50;
    final rot = twisterProgress * math.pi * 2;
    const topW = 24.0;
    const botW = 6.0;

    final funnel = Path();
    funnel.moveTo(cx - (topW / 2), h * 0.30);
    funnel.lineTo(cx + (topW / 2), h * 0.30);
    funnel.quadraticBezierTo(cx + (botW / 2) + 3, h * 0.58, cx + (botW / 2), h * 0.86);
    funnel.lineTo(cx - (botW / 2), h * 0.86);
    funnel.quadraticBezierTo(cx - (botW / 2) - 3, h * 0.58, cx - (topW / 2), h * 0.30);
    funnel.close();

    final twisterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF94A3B8), Color(0xFF475569)],
      ).createShader(Rect.fromLTWH(cx - 20, h * 0.30, 40, h * 0.60));
    canvas.drawPath(funnel, twisterPaint);

    final debris = Paint()..color = const Color(0xFF1E293B);
    for (int i = 0; i < 4; i++) {
      final a = rot + (i * (math.pi / 2));
      final orbitY = h * 0.40 + (i * 9);
      final orbitW = topW - (i * 5);
      final x = cx + (math.cos(a) * (orbitW / 2));
      canvas.drawCircle(Offset(x, orbitY), 1.8, debris);
    }
  }

  @override
  bool shouldRepaint(covariant _CelestialSkySvgPainter old) => true;
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
  final double animValue;
  final double width;
  final double height;

  const _AqiToolerCharacter({
    required this.mood,
    required this.theme,
    required this.isDark,
    required this.animValue,
    this.width = 134,
    this.height = 118,
  });

  @override
  State<_AqiToolerCharacter> createState() => _AqiToolerCharacterState();
}

class _AqiToolerCharacterState extends State<_AqiToolerCharacter> {
  static final Map<_AqiCharacterMood, String> _rawSvgs = {};
  static final Map<String, String> _themedCache = {};
  String? _themedSvg;

  static String _assetForMood(_AqiCharacterMood mood) {
    switch (mood) {
      case _AqiCharacterMood.cleanAirBreathe:
        return 'assets/illustrations/character_aqi_pose1_good.svg';
      case _AqiCharacterMood.mildCoughAutumn:
        return 'assets/illustrations/character_aqi_pose2_cough.svg';
      case _AqiCharacterMood.unhealthyMask:
        return 'assets/illustrations/character_aqi_pose3_mask.svg';
      case _AqiCharacterMood.veryUnhealthySadMask:
        return 'assets/illustrations/character_aqi_pose4_sad.svg';
      case _AqiCharacterMood.hazardousOxygenCylinder:
        return 'assets/illustrations/character_aqi_pose5_oxygen.svg';
      case _AqiCharacterMood.severeToxicWrinkled:
        return 'assets/illustrations/character_aqi_pose6_worst.svg';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void didUpdateWidget(covariant _AqiToolerCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood ||
        oldWidget.theme.mode != widget.theme.mode ||
        oldWidget.theme.isDark != widget.theme.isDark ||
        oldWidget.theme.primary != widget.theme.primary) {
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    final assetPath = _assetForMood(widget.mood);
    final cacheKey = '${widget.mood}_${widget.theme.mode}_${widget.theme.isDark}_${widget.theme.primary.toARGB32()}';
    if (_themedCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _themedSvg = _themedCache[cacheKey];
        });
      }
      return;
    }

    String? rawSvg = _rawSvgs[widget.mood];
    if (rawSvg == null) {
      try {
        rawSvg = await rootBundle.loadString(assetPath);
        _rawSvgs[widget.mood] = rawSvg;
      } catch (e) {
        return;
      }
    }

    final hexPrimary = '#${(widget.theme.primary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final hexLight = '#${(widget.theme.primary.withValues(alpha: 0.22).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    final processed = rawSvg
        .replaceAll('var(--char-accent, #F43F5E)', hexPrimary)
        .replaceAll('var(--char-accent, #9468E8)', hexPrimary)
        .replaceAll('#F43F5E', hexPrimary)
        .replaceAll('#9468E8', hexPrimary)
        .replaceAll('#EDE9FE', hexLight);

    _themedCache[cacheKey] = processed;
    if (mounted) {
      setState(() {
        _themedSvg = processed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;

    // Responsive micro-motion variations according to 6 AQI mood stages:
    Offset charOffset = Offset.zero;
    double scaleX = 1.0;
    double scaleY = 1.0;

    switch (widget.mood) {
      case _AqiCharacterMood.cleanAirBreathe:
        // Rhythmic deep breathing expansion: gentle chest expansion up and out
        final breath = math.sin(widget.animValue * math.pi * 2);
        charOffset = Offset(0, -breath * 2.2);
        scaleY = 1.0 + (breath * 0.022);
        scaleX = 1.0 + (breath * 0.012);
        break;

      case _AqiCharacterMood.mildCoughAutumn:
        // Cough spasm: rapid forward jolt during coughing phase
        final jolt = math.sin(widget.animValue * math.pi * 6);
        final isCoughPhase = widget.animValue > 0.15 && widget.animValue < 0.75;
        if (isCoughPhase) {
          charOffset = Offset(-jolt * 2.0, (jolt.abs()) * 1.5);
        } else {
          charOffset = Offset(0, math.sin(widget.animValue * math.pi * 2) * 0.6);
        }
        break;

      case _AqiCharacterMood.unhealthyMask:
        // Restricted breathing through mask
        final breath = math.sin(widget.animValue * math.pi * 2);
        charOffset = Offset(0, breath * 1.0);
        break;

      case _AqiCharacterMood.veryUnhealthySadMask:
        // Sad drooping posture: slouched down
        final breath = math.sin(widget.animValue * math.pi * 2);
        charOffset = Offset(0, 1.5 + (breath * 0.6));
        scaleY = 0.99;
        break;

      case _AqiCharacterMood.hazardousOxygenCylinder:
        // Burdened breathing with medical oxygen support
        final breath = math.sin(widget.animValue * math.pi * 2);
        charOffset = Offset(0, 1.0 + (breath * 0.8));
        break;

      case _AqiCharacterMood.severeToxicWrinkled:
        // Extreme exhaustion & shivering tremor ("bahut sukha hai aur halat kharab hai")
        final tremor = math.sin(widget.animValue * math.pi * 12) * 0.9;
        charOffset = Offset(tremor * 0.7, 2.0 + (tremor.abs() * 0.4));
        break;
    }

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft Ground Shadow
          Positioned(
            bottom: 2,
            child: Container(
              width: w * 0.75,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isDark ? Colors.black : Colors.black26).withValues(alpha: 0.22),
                    blurRadius: 7,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // Authentic Upgraded Pose SVG with AnimatedSwitcher
          if (_themedSvg != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey<String>('${widget.mood}_${widget.theme.mode}'),
                child: Transform.translate(
                  offset: charOffset,
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
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CIRCULAR 8-PHASE LUNAR ORBIT MODAL SHEET
// Central Moon + 8 Surrounding Orbiting Moon Phase Nodes
// ---------------------------------------------------------------------------
class _PhaseDefinition {
  final String name;
  final String shortName;
  final double phaseValue;
  final int illuminationPercent;
  final String description;

  const _PhaseDefinition({
    required this.name,
    required this.shortName,
    required this.phaseValue,
    required this.illuminationPercent,
    required this.description,
  });
}

class _CircularMoonPhasesSheet extends StatefulWidget {
  final StationeryTheme theme;
  final bool isDark;
  final MoonPhaseInfo currentMoon;

  const _CircularMoonPhasesSheet({
    required this.theme,
    required this.isDark,
    required this.currentMoon,
  });

  @override
  State<_CircularMoonPhasesSheet> createState() => _CircularMoonPhasesSheetState();
}

class _CircularMoonPhasesSheetState extends State<_CircularMoonPhasesSheet> {
  static const List<_PhaseDefinition> _phases = [
    _PhaseDefinition(
      name: 'New Moon',
      shortName: 'New',
      phaseValue: 0.0,
      illuminationPercent: 0,
      description: 'The moon is situated directly between Earth and Sun, invisible in daylight sky.',
    ),
    _PhaseDefinition(
      name: 'Waxing Crescent',
      shortName: 'Wax Cres',
      phaseValue: 0.125,
      illuminationPercent: 25,
      description: 'A slender growing crescent on the western horizon after sunset.',
    ),
    _PhaseDefinition(
      name: 'First Quarter',
      shortName: '1st Qtr',
      phaseValue: 0.25,
      illuminationPercent: 50,
      description: 'One half of the lunar surface is illuminated; 90° east of the Sun.',
    ),
    _PhaseDefinition(
      name: 'Waxing Gibbous',
      shortName: 'Wax Gibb',
      phaseValue: 0.375,
      illuminationPercent: 75,
      description: 'More than half illuminated, swelling nightly toward full brilliance.',
    ),
    _PhaseDefinition(
      name: 'Full Moon',
      shortName: 'Full',
      phaseValue: 0.5,
      illuminationPercent: 100,
      description: 'Fully illuminated hemisphere faces Earth, rising opposite the sunset with 100% brilliance.',
    ),
    _PhaseDefinition(
      name: 'Waning Gibbous',
      shortName: 'Wan Gibb',
      phaseValue: 0.625,
      illuminationPercent: 75,
      description: 'Waning past full, visible late night into morning twilight.',
    ),
    _PhaseDefinition(
      name: 'Third Quarter',
      shortName: '3rd Qtr',
      phaseValue: 0.75,
      illuminationPercent: 50,
      description: 'The decreasing half moon rises around midnight and sets at noon.',
    ),
    _PhaseDefinition(
      name: 'Waning Crescent',
      shortName: 'Wan Cres',
      phaseValue: 0.875,
      illuminationPercent: 25,
      description: 'Final silver sliver before dawn, concluding the 29.53-day synodic month.',
    ),
  ];

  late int _selectedIndex;
  late int _todayPhaseIndex;

  @override
  void initState() {
    super.initState();
    _todayPhaseIndex = _findClosestIndex(widget.currentMoon.phase);
    _selectedIndex = _todayPhaseIndex;
  }

  int _findClosestIndex(double phase) {
    int closest = 0;
    double minDiff = 999.0;
    for (int i = 0; i < _phases.length; i++) {
      double diff = (phase - _phases[i].phaseValue).abs();
      if (diff > 0.5) diff = 1.0 - diff;
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final sel = _phases[_selectedIndex];
    final isToday = _selectedIndex == _todayPhaseIndex;
    final cardBg = widget.isDark ? const Color(0xFF25252A) : const Color(0xFFF1F5F9);
    final borderColor = widget.isDark ? const Color(0xFF33333A) : const Color(0xFFE2E8F0);
    final textPrimary = widget.isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.brightness_2_rounded, size: 20, color: widget.theme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Lunar Cycle Orbit',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.theme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.theme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '29.5d Synodic',
                    style: TextStyle(
                      fontFamily: 'FiraCode',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.theme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Circular Orbit Diagram (Center Moon + 8 Surrounding Orbiting Phases)
            SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle Orbit Pathway Track
                  Container(
                    width: 216,
                    height: 216,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Center Big Celestial Moon Display
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDark ? const Color(0xFF1E222A) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFEF08A).withValues(alpha: widget.isDark ? 0.25 : 0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                      border: Border.all(
                        color: widget.theme.primary.withValues(alpha: 0.6),
                        width: 2.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(
                      painter: _VectorMoonPhasePainter(
                        phase: sel.phaseValue,
                        isDark: widget.isDark,
                      ),
                    ),
                  ),

                  // 8 Orbit Phase Nodes
                  for (int i = 0; i < _phases.length; i++) ...[
                    _buildOrbitNode(
                      index: i,
                      phase: _phases[i],
                      centerRadius: 108.0,
                      totalPhases: _phases.length,
                      isSelected: i == _selectedIndex,
                      isToday: i == _todayPhaseIndex,
                      theme: widget.theme,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selected Phase Detail Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            sel.name,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.theme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF08A).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFEF08A).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${sel.illuminationPercent}% Illum',
                          style: TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark ? const Color(0xFFFEF08A) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sel.description,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      height: 1.35,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Close / Done button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitNode({
    required int index,
    required _PhaseDefinition phase,
    required double centerRadius,
    required int totalPhases,
    required bool isSelected,
    required bool isToday,
    required StationeryTheme theme,
  }) {
    // 0 is top (-pi/2), moving clockwise
    final angle = (-math.pi / 2) + (index * (2 * math.pi / totalPhases));
    final dx = centerRadius * math.cos(angle);
    final dy = centerRadius * math.sin(angle);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDark ? const Color(0xFF1E222A) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? theme.primary
                      : (isToday ? const Color(0xFFFEF08A) : Colors.white24),
                  width: isSelected ? 2.5 : (isToday ? 2.0 : 1.0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(5),
              child: CustomPaint(
                painter: _VectorMoonPhasePainter(
                  phase: phase.phaseValue,
                  isDark: widget.isDark,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              phase.shortName,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.primary
                    : (widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
