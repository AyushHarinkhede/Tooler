import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/stationery_theme.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_hover_sheet.dart';
import '../widgets_3d/weather_outfit_sheet.dart';
import '../services/sound_service.dart';
import '../services/weather_telemetry_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER MAUSAM & WEATHER SCREEN
/// - Real-time Weather, Location & AQI telemetry
/// - Interactive Sky Canvas with bigger Sun, Moon Phase, Line-by-Line Drifting
///   Clouds, Breeze, Birds, Rain, Snow & Thunder Animations
/// - Reactive Tooler Vector Character for AQI
/// - Past 7 Days History & Next 7 Days Forecast Charts with °C / °F toggle
/// - Astronomical Precision Moon Phase Visualizer with all 8 phases
/// - Activities & Allergies Outlook + What to Wear & Carry Hover Page
/// - Interactive Weather Simulator & Season Indicator Controls Bar
/// ---------------------------------------------------------------------------

enum WeatherSimMode {
  live,
  sunnyDay,
  starryNight,
  cloudySky,
  rainyDeluge,
  thunderstorm,
  snowfall,
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
  bool _activitiesExpanded = true;
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

    // Main ambient landscape loop (gentle line-by-line clouds, sun rotation, breeze, birds)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 32000),
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
      final isSnow = [71, 73, 75, 77, 85, 86].contains(code);
      final isRain = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code);
      final isThunder = [95, 96, 99].contains(code);
      final isCloudy = [2, 3, 45, 48].contains(code);
      return _EffectiveWeather(
        isDay: isDay,
        isRain: isRain,
        isThunder: isThunder,
        isCloudy: isCloudy,
        isSnow: isSnow,
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
          isSnow: false,
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
          isSnow: false,
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
          isSnow: false,
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
          isSnow: false,
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
          isSnow: false,
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
      case WeatherSimMode.snowfall:
        return _EffectiveWeather(
          isDay: true,
          isRain: false,
          isThunder: false,
          isCloudy: true,
          isSnow: true,
          isFlood: false,
          isTwister: false,
          tempC: -3.0,
          condition: 'Heavy Snowfall',
          aqi: _simAqiOverride ?? 34,
          aqiStatus: 'Good',
          aqiColor: const Color(0xFF10B981),
          city: 'Snow Ridge',
          country: 'Sim',
        );
      case WeatherSimMode.mountainFlood:
        return _EffectiveWeather(
          isDay: false,
          isRain: true,
          isThunder: true,
          isCloudy: true,
          isSnow: false,
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
          isSnow: false,
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
          isSnow: false,
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
          isSnow: false,
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

  /// Current weather season derived from active simulation or calendar month
  WeatherSeason _resolveSeason(_EffectiveWeather weather) {
    if (_simMode == WeatherSimMode.snowfall || weather.isSnow || weather.tempC <= 4.0) {
      return WeatherSeason.winter;
    }
    if (_simMode == WeatherSimMode.sunnyDay) {
      return WeatherSeason.summer;
    }
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return WeatherSeason.spring;
    if (month >= 6 && month <= 8) return WeatherSeason.summer;
    if (month >= 9 && month <= 11) return WeatherSeason.autumn;
    return WeatherSeason.winter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;
    final inHoverSheet = ToolerHoverSheetScope.of(context) != null;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        top: !inHoverSheet,
        child: AnimatedBuilder(
            animation: _telemetry,
            builder: (context, _) {
              final weather = _getEffectiveWeather();
              final rawData = _telemetry.data;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Modern Themed Hero Container
                    _buildModernWeatherHeroCard(theme, isDark, weather, rawData),
                    const SizedBox(height: 14),

                    // 2. Sleek Moon Phase Bar
                    _buildMoonPhaseBar(theme, isDark, rawData.moonPhase),
                    const SizedBox(height: 14),

                    // 3. Simple Clean Graph
                    _buildForecastGraphCard(theme, isDark, rawData),
                    const SizedBox(height: 14),

                    // 4. Detailed Atmospheric Metrics Grid
                    _buildMetricsGrid(theme, isDark, rawData, weather),
                    const SizedBox(height: 16),

                    // 5. Activities & Allergies Section
                    _buildActivitiesAllergiesSection(theme, isDark, rawData, weather),
                    const SizedBox(height: 14),

                    // 6. What to Wear & Carry Button (Opens Interactive Hover Page)
                    _buildWhatToWearButton(theme, isDark, rawData, weather),
                    const SizedBox(height: 14),

                    // 7. Dedicated Season Indicator & Weather Controls Bar
                    _buildWeatherControlsBar(theme, isDark, weather),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }

  // ---------------------------------------------------------------------------
  // DEDICATED SEASON & WEATHER CONTROLS BAR (Season + Vector Icon, zero caption)
  // ---------------------------------------------------------------------------
  Widget _buildWeatherControlsBar(StationeryTheme theme, bool isDark, _EffectiveWeather weather) {
    final season = _resolveSeason(weather);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: season.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: season.color.withValues(alpha: 0.35), width: 1),
            ),
            child: Icon(season.icon, size: 19, color: season.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${season.label} Season',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: theme.text,
              ),
            ),
          ),
          // Quick °C / °F Toggle Button Chip
          InkWell(
            onTap: () {
              SoundService().playClick();
              HapticFeedback.selectionClick();
              setState(() => _useFahrenheit = !_useFahrenheit);
            },
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A30) : theme.lavenderBubble,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: theme.border, width: 1),
              ),
              child: Text(
                _useFahrenheit ? '°F' : '°C',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: theme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Full Options 3-Dots Menu Button
          _buildThreeDotMenu(theme, isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // THREE-DOT MENU BUTTON (Unit Toggle, Refresh, Weather Simulator, Reset)
  // ---------------------------------------------------------------------------
  Widget _buildThreeDotMenu(StationeryTheme theme, bool isDark, {bool isCompact = false}) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(isCompact ? 5 : 7),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF2A2A30) : theme.lavenderBubble).withValues(alpha: isCompact ? 0.9 : 1.0),
          borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
          border: Border.all(color: theme.border, width: 1.1),
        ),
        child: Icon(Icons.more_vert_rounded, size: isCompact ? 16 : 18, color: theme.text),
      ),
      tooltip: 'Weather Options',
      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.border, width: 1.2),
      ),
      elevation: 8,
      onSelected: (value) {
        if (value == 'location') {
          SoundService().playTap();
          _showLocationPickerSheet(theme, isDark);
        } else if (value == 'gps') {
          SoundService().playTap();
          _telemetry.useLiveGpsLocation();
        } else if (value == 'unit') {
          SoundService().playClick();
          HapticFeedback.selectionClick();
          setState(() => _useFahrenheit = !_useFahrenheit);
        } else if (value == 'refresh') {
          SoundService().playTap();
          HapticFeedback.lightImpact();
          _telemetry.fetchTelemetry(force: true);
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
        // 0. Location Selection
        PopupMenuItem<String>(
          value: 'location',
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Change City / Location',
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
        PopupMenuItem<String>(
          value: 'gps',
          child: Row(
            children: [
              Icon(
                Icons.my_location_rounded,
                size: 18,
                color: theme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Detect Live GPS Location',
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
    );
  }

  // ---------------------------------------------------------------------------
  // 1. MODERN THEMED WEATHER HERO SECTION
  // - Unboxed: Seamless layout with zero card background or borders
  // - Top: Theme-matched Weather Vector Art (Soft Cloud + Sun/Moon + Rain/Thunder/Air in UI colors)
  // - Center: Tooler Vector Mascot (Enlarged, completely stationary stance, no vibration/smog)
  // - Data: Temperature with unit + condition, AQI with color, PM rating, Live Location
  // - Corner: Three-dot options menu relocated right above the lunar cycle container
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

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Weather Visual — pushed up directly beneath the hover title to fill top gap
          SizedBox(
            height: 106,
            width: double.infinity,
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
                    theme: theme,
                  ),
                );
              },
            ),
          ),

          // 2. Character Mascot (Tucked snugly under the sky canvas with trimmed SVG padding)
          Transform.translate(
            offset: const Offset(0, -10),
            child: _AqiToolerCharacter(
              mood: mood,
              theme: theme,
              isDark: isDark,
              animValue: 0.0,
              width: 176,
              height: 148,
            ),
          ),
          const SizedBox(height: 0),

          // 3. Weather Data: Temperature centered cleanly in the middle
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$displayTemp',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: theme.text,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  displayUnit,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 4. Weather Type Indicator + Location Pill — side by side, or step-by-step if location is long
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxLocTextWidth = math.max(150.0, constraints.maxWidth - 64);
                return Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Weather condition indicator pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222228) : theme.lavenderBubble,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border, width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _telemetry.getWeatherIcon(
                              weather.isSnow
                                  ? 71
                                  : (weather.isRain
                                      ? 61
                                      : (weather.isThunder
                                          ? 95
                                          : (weather.isCloudy ? 2 : (weather.isDay ? 1 : 0)))),
                              weather.isDay,
                            ),
                            size: 13,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            weather.condition,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Location pill (wraps onto its own line step-by-step when city name is long)
                    BouncyTap(
                      onTap: () {
                        SoundService().playTap();
                        _showLocationPickerSheet(theme, isDark);
                      },
                      scaleFraction: 0.97,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF1E1E24) : Colors.white).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _telemetry.isManualLocation ? Icons.location_city_rounded : Icons.near_me_rounded,
                              size: 13,
                              color: const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxLocTextWidth),
                              child: Text(
                                '${weather.city}, ${weather.country}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: theme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 9),

          // 5. AQI in UI theme font with glowing indicator dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: weather.aqiColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: weather.aqiColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'AQI ${weather.aqi} • ${weather.aqiStatus}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: weather.aqiColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // 6. PM Rating
          Text(
            'PM2.5: ${raw.pm25} µg/m³   •   PM10: ${raw.pm10} µg/m³',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // 7. Menu Button in bottom right corner (right above the Lunar Cycle container)
          Align(
            alignment: Alignment.centerRight,
            child: _buildThreeDotMenu(theme, isDark, isCompact: false),
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
              Flexible(
                child: Text(
                  'Weather Trend',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildForecastTabBtn('Hourly', 0, theme, isDark),
                          _buildForecastTabBtn('14d', 1, theme, isDark),
                          _buildForecastTabBtn('Past 7d', 2, theme, isDark),
                          _buildForecastTabBtn('Next 7d', 3, theme, isDark),
                        ],
                      ),
                    ),
                  ),
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMetricTile(
                  theme,
                  isDark,
                  icon: Icons.water_drop_outlined,
                  title: 'Humidity',
                  value: '${raw.humidity.round()}%',
                  subtitle: raw.humidity < 40 ? 'Dry air' : (raw.humidity > 70 ? 'Humid' : 'Comfortable'),
                  accentColor: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  theme,
                  isDark,
                  icon: Icons.air_rounded,
                  title: 'Wind Speed',
                  value: '${raw.windSpeedKmH.toStringAsFixed(1)} km/h',
                  subtitle: 'Gentle mountain breeze',
                  accentColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMetricTile(
                  theme,
                  isDark,
                  icon: Icons.wb_sunny_outlined,
                  title: 'UV Index',
                  value: raw.uvIndex.toStringAsFixed(1),
                  subtitle: raw.uvIndex >= 6 ? 'High (Wear sunscreen)' : 'Moderate safe level',
                  accentColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  theme,
                  isDark,
                  icon: Icons.speed_rounded,
                  title: 'Pressure',
                  value: '${raw.pressureHpa.round()} hPa',
                  subtitle: 'Stable atmospheric basin',
                  accentColor: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMetricTile(
                  theme,
                  isDark,
                  icon: Icons.wb_twilight_rounded,
                  title: 'Sunrise',
                  value: raw.sunriseToday,
                  subtitle: 'Golden dawn',
                  accentColor: const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  theme,
                  isDark,
                  icon: Icons.bedtime_outlined,
                  title: 'Sunset',
                  value: raw.sunsetToday,
                  subtitle: 'Twilight evening',
                  accentColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: theme.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
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
  // 5B. ACTIVITIES & ALLERGIES SECTION (Below Atmospheric Metrics)
  // ---------------------------------------------------------------------------
  Widget _buildActivitiesAllergiesSection(
    StationeryTheme theme,
    bool isDark,
    WeatherTelemetryData raw,
    _EffectiveWeather weather,
  ) {
    final season = _resolveSeason(weather);

    // Compute Outdoor Activity suitability dynamically (Running, Jogging, Cycling, Hiking)
    final bool severeWeather = weather.isThunder || weather.isTwister || weather.isFlood;
    final bool wetOrSnow = weather.isRain || weather.isSnow;

    final String runStatus;
    final Color runColor;
    if (severeWeather || weather.aqi > 150) {
      runStatus = 'Poor';
      runColor = const Color(0xFFEF4444);
    } else if (wetOrSnow || weather.aqi > 100 || weather.tempC > 34 || weather.tempC < 4) {
      runStatus = 'Fair';
      runColor = const Color(0xFFF59E0B);
    } else {
      runStatus = 'Good';
      runColor = const Color(0xFF10B981);
    }

    final String jogStatus;
    final Color jogColor;
    if (severeWeather || weather.aqi > 150) {
      jogStatus = 'Poor';
      jogColor = const Color(0xFFEF4444);
    } else if (wetOrSnow || weather.aqi > 110 || weather.tempC > 35 || weather.tempC < 3) {
      jogStatus = 'Fair';
      jogColor = const Color(0xFFF59E0B);
    } else {
      jogStatus = 'Good';
      jogColor = const Color(0xFF10B981);
    }

    final String cycleStatus;
    final Color cycleColor;
    if (severeWeather || weather.isSnow || raw.windSpeedKmH > 28 || weather.aqi > 150) {
      cycleStatus = 'Poor';
      cycleColor = const Color(0xFFEF4444);
    } else if (weather.isRain || raw.windSpeedKmH > 18 || weather.aqi > 100) {
      cycleStatus = 'Fair';
      cycleColor = const Color(0xFFF59E0B);
    } else {
      cycleStatus = 'Good';
      cycleColor = const Color(0xFF10B981);
    }

    final String hikeStatus;
    final Color hikeColor;
    if (severeWeather || weather.isRain || weather.isSnow || weather.aqi > 150) {
      hikeStatus = 'Poor';
      hikeColor = const Color(0xFFEF4444);
    } else if (weather.aqi > 100 || raw.windSpeedKmH > 24 || weather.tempC > 34 || weather.tempC < 5) {
      hikeStatus = 'Fair';
      hikeColor = const Color(0xFFF59E0B);
    } else {
      hikeStatus = 'Good';
      hikeColor = const Color(0xFF10B981);
    }

    // Compute Dust & Dander + Secondary Allergy Levels dynamically
    final String dustStatus;
    final Color dustColor;
    if (weather.aqi > 200 || raw.pm10 >= 150 || raw.pm25 >= 75) {
      dustStatus = 'Extreme';
      dustColor = const Color(0xFFEF4444);
    } else if (weather.aqi > 125 || raw.pm10 >= 55 || raw.pm25 >= 35) {
      dustStatus = 'Extreme';
      dustColor = const Color(0xFFF97316);
    } else if (weather.aqi > 75 || raw.pm10 >= 30) {
      dustStatus = 'Moderate';
      dustColor = const Color(0xFFF59E0B);
    } else {
      dustStatus = 'Low';
      dustColor = const Color(0xFF10B981);
    }

    final bool dryWindy = !weather.isRain && !weather.isSnow && raw.windSpeedKmH >= 10;
    final String pollenLevel;
    final Color pollenColor;
    if (weather.isRain || weather.isSnow || season == WeatherSeason.winter) {
      pollenLevel = 'Low';
      pollenColor = const Color(0xFF10B981);
    } else if ((season == WeatherSeason.spring || season == WeatherSeason.autumn) && dryWindy) {
      pollenLevel = 'High';
      pollenColor = const Color(0xFFF97316);
    } else {
      pollenLevel = 'Moderate';
      pollenColor = const Color(0xFFF59E0B);
    }

    final String moldLevel;
    final Color moldColor;
    if (raw.humidity >= 75 || weather.isRain) {
      moldLevel = 'High';
      moldColor = const Color(0xFFF97316);
    } else if (raw.humidity >= 55) {
      moldLevel = 'Moderate';
      moldColor = const Color(0xFFF59E0B);
    } else {
      moldLevel = 'Low';
      moldColor = const Color(0xFF10B981);
    }

    final String sinusLevel;
    final Color sinusColor;
    if (weather.aqi > 150 || raw.uvIndex >= 8 || weather.tempC <= 5) {
      sinusLevel = 'High';
      sinusColor = const Color(0xFFEF4444);
    } else if (weather.aqi > 80 || raw.uvIndex >= 5 || raw.humidity < 35) {
      sinusLevel = 'Moderate';
      sinusColor = const Color(0xFFF59E0B);
    } else {
      sinusLevel = 'Low';
      sinusColor = const Color(0xFF10B981);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Activities Card (Collapsible 2x2 grid: Running, Jogging, Cycling, Hiking)
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  SoundService().playTap();
                  setState(() => _activitiesExpanded = !_activitiesExpanded);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Activities',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.text,
                        ),
                      ),
                      Icon(
                        _activitiesExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: theme.text,
                      ),
                    ],
                  ),
                ),
              ),
              if (_activitiesExpanded) ...[
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildActivityMiniTile(
                          theme,
                          isDark,
                          icon: Icons.directions_run_rounded,
                          title: 'Running',
                          status: runStatus,
                          color: runColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActivityMiniTile(
                          theme,
                          isDark,
                          icon: Icons.directions_walk_rounded,
                          title: 'Jogging',
                          status: jogStatus,
                          color: jogColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildActivityMiniTile(
                          theme,
                          isDark,
                          icon: Icons.directions_bike_rounded,
                          title: 'Cycling',
                          status: cycleStatus,
                          color: cycleColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActivityMiniTile(
                          theme,
                          isDark,
                          icon: Icons.hiking_rounded,
                          title: 'Hiking',
                          status: hikeStatus,
                          color: hikeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Allergies Card (Featured Dust and dander banner + Pollen/Mold/Sinus chips)
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allergies',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.text,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141418) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.border.withValues(alpha: 0.65), width: 1),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CustomPaint(
                        painter: _DustDropletIconPainter(
                          color: isDark ? Colors.white : theme.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dust and dander',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dustStatus,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: dustColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'PM2.5 ${raw.pm25.toStringAsFixed(0)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildAllergyMiniChip(
                      theme,
                      isDark,
                      icon: Icons.local_florist_rounded,
                      title: 'Pollen',
                      level: pollenLevel,
                      color: pollenColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAllergyMiniChip(
                      theme,
                      isDark,
                      icon: Icons.water_drop_rounded,
                      title: 'Mold',
                      level: moldLevel,
                      color: moldColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAllergyMiniChip(
                      theme,
                      isDark,
                      icon: Icons.wb_sunny_outlined,
                      title: 'Sinus & UV',
                      level: sinusLevel,
                      color: sinusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityMiniTile(
    StationeryTheme theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141418) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border.withValues(alpha: 0.65), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isDark ? Colors.white : theme.text),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyMiniChip(
    StationeryTheme theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String level,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141418) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: theme.border.withValues(alpha: 0.55), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12.5, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            level,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5C. WHAT TO WEAR & CARRY BUTTON -> OPENS HOVER PAGE WITH CHARACTER & TOOLS
  // ---------------------------------------------------------------------------
  Widget _buildWhatToWearButton(
    StationeryTheme theme,
    bool isDark,
    WeatherTelemetryData raw,
    _EffectiveWeather weather,
  ) {
    final season = _resolveSeason(weather);
    final outfitCtx = WeatherOutfitContext(
      tempC: weather.tempC,
      condition: weather.condition,
      isDay: weather.isDay,
      isRain: weather.isRain,
      isThunder: weather.isThunder,
      isCloudy: weather.isCloudy,
      isSnow: weather.isSnow,
      aqi: weather.aqi,
      humidity: raw.humidity,
      windSpeedKmH: raw.windSpeedKmH,
      uvIndex: raw.uvIndex,
      season: season,
      city: weather.city,
    );
    final rec = OutfitRecommendation.compute(outfitCtx);

    final quickSummary = [
      rec.shirtType,
      rec.footwearType,
      if (rec.hasUmbrella) 'Umbrella',
      if (rec.hasOxygenCylinder) 'O₂ Cylinder' else if (rec.hasMask) 'N95 Mask',
    ].join(' • ');

    return BouncyTap(
      onTap: () {
        showWhatToWearHoverPage(
          context: context,
          theme: theme,
          isDark: isDark,
          weatherContext: outfitCtx,
          useFahrenheit: _useFahrenheit,
        );
      },
      scaleFraction: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primary.withValues(alpha: isDark ? 0.22 : 0.13),
              isDark ? const Color(0xFF222229) : theme.lavenderCard,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.primary.withValues(alpha: 0.42), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.checkroom_rounded, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'What to Wear & Carry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quickSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.primary.withValues(alpha: 0.32), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10.5, color: theme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. LOCATION SEARCH & LIVE GPS PICKER SHEET
  // ---------------------------------------------------------------------------
  void _showLocationPickerSheet(StationeryTheme theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        List<Map<String, dynamic>> searchResults = [];
        bool isSearching = false;
        Timer? debounce;

        final popularCities = [
          {'name': 'Balaghat', 'country': 'India', 'countryCode': 'IN', 'lat': 21.8156, 'lon': 80.1885, 'admin1': 'Madhya Pradesh'},
          {'name': 'Bhopal', 'country': 'India', 'countryCode': 'IN', 'lat': 23.2599, 'lon': 77.4126, 'admin1': 'Madhya Pradesh'},
          {'name': 'Indore', 'country': 'India', 'countryCode': 'IN', 'lat': 22.7196, 'lon': 75.8577, 'admin1': 'Madhya Pradesh'},
          {'name': 'Nagpur', 'country': 'India', 'countryCode': 'IN', 'lat': 21.1458, 'lon': 79.0882, 'admin1': 'Maharashtra'},
          {'name': 'Mumbai', 'country': 'India', 'countryCode': 'IN', 'lat': 19.0760, 'lon': 72.8777, 'admin1': 'Maharashtra'},
          {'name': 'Pune', 'country': 'India', 'countryCode': 'IN', 'lat': 18.5204, 'lon': 73.8567, 'admin1': 'Maharashtra'},
          {'name': 'New Delhi', 'country': 'India', 'countryCode': 'IN', 'lat': 28.6139, 'lon': 77.2090, 'admin1': 'Delhi'},
          {'name': 'Bengaluru', 'country': 'India', 'countryCode': 'IN', 'lat': 12.9716, 'lon': 77.5946, 'admin1': 'Karnataka'},
          {'name': 'Hyderabad', 'country': 'India', 'countryCode': 'IN', 'lat': 17.3850, 'lon': 78.4867, 'admin1': 'Telangana'},
          {'name': 'Kolkata', 'country': 'India', 'countryCode': 'IN', 'lat': 22.5726, 'lon': 88.3639, 'admin1': 'West Bengal'},
        ];

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void performSearch(String val) {
              debounce?.cancel();
              if (val.trim().length < 2) {
                setSheetState(() {
                  searchQuery = val;
                  searchResults = [];
                  isSearching = false;
                });
                return;
              }
              setSheetState(() {
                searchQuery = val;
                isSearching = true;
              });
              debounce = Timer(const Duration(milliseconds: 320), () async {
                final list = await _telemetry.searchCities(val);
                setSheetState(() {
                  searchResults = list;
                  isSearching = false;
                });
              });
            }

            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: bottomInset + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weather Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: theme.text,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            debounce?.cancel();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Detect your live GPS position or search any city or town worldwide.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Action: Use Live GPS Location
                    BouncyTap(
                      onTap: () async {
                        debounce?.cancel();
                        SoundService().playTap();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Detecting live GPS location...',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: theme.primary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        await _telemetry.useLiveGpsLocation();
                      },
                      scaleFraction: 0.98,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: !_telemetry.isManualLocation
                              ? theme.primary.withValues(alpha: 0.12)
                              : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F6)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !_telemetry.isManualLocation ? theme.primary : theme.border,
                            width: !_telemetry.isManualLocation ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.my_location_rounded, size: 18, color: theme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Use Live GPS Location',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: theme.text,
                                    ),
                                  ),
                                  Text(
                                    !_telemetry.isManualLocation
                                        ? 'Currently active (${_telemetry.data.city})'
                                        : 'Auto-detect exact live phone location',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: !_telemetry.isManualLocation ? theme.primary : theme.textSecondary,
                                      fontWeight: !_telemetry.isManualLocation ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_telemetry.isManualLocation)
                              Icon(Icons.check_circle_rounded, color: theme.primary, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Search Input Box
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.border, width: 1.1),
                      ),
                      child: TextField(
                        onChanged: performSearch,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: theme.text),
                        decoration: InputDecoration(
                          hintText: 'Search city (e.g. Balaghat, Indore, Pune)...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: theme.textSecondary),
                          prefixIcon: Icon(Icons.search_rounded, color: theme.primary, size: 20),
                          suffixIcon: isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : (searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () => performSearch(''),
                                    )
                                  : null),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Search Results List
                    if (searchResults.isNotEmpty) ...[
                      Text(
                        'Search Results',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          separatorBuilder: (_, __) => Divider(color: theme.border.withValues(alpha: 0.5), height: 1),
                          itemBuilder: (context, idx) {
                            final item = searchResults[idx];
                            final name = item['name'] as String;
                            final admin = item['admin1'] as String;
                            final country = item['country'] as String;
                            final cCode = item['countryCode'] as String;
                            final lat = item['latitude'] as double;
                            final lon = item['longitude'] as double;

                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              leading: const Icon(Icons.location_city_rounded, size: 18, color: Color(0xFF38BDF8)),
                              title: Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: theme.text),
                              ),
                              subtitle: Text(
                                admin.isNotEmpty ? '$admin, $country' : country,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: theme.textSecondary),
                              ),
                              onTap: () async {
                                debounce?.cancel();
                                SoundService().playTap();
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Weather updated to $name ($admin)',
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: theme.primary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                await _telemetry.setManualLocation(
                                  city: name,
                                  country: cCode.isNotEmpty ? cCode : 'IN',
                                  lat: lat,
                                  lon: lon,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ] else if (searchQuery.isNotEmpty && !isSearching) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'No matching cities found. Try another spelling.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: theme.textSecondary),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Popular Cities
                      Text(
                        'Popular Cities',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: popularCities.map((c) {
                          final isSelected = _telemetry.isManualLocation && _telemetry.manualCity == c['name'];
                          return InkWell(
                            onTap: () async {
                              debounce?.cancel();
                              SoundService().playTap();
                              Navigator.pop(ctx);
                              await _telemetry.setManualLocation(
                                city: c['name'] as String,
                                country: c['countryCode'] as String,
                                lat: c['lat'] as double,
                                lon: c['lon'] as double,
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primary.withValues(alpha: 0.16)
                                    : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F6)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? theme.primary : theme.border,
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: Text(
                                c['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? theme.primary : theme.text,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 6. INTERACTIVE SIMULATOR SHEET (Disasters, Sun, Moon & AQI testing)
  // ---------------------------------------------------------------------------
  void _showSimulationSheet(StationeryTheme theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
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
                    'Experience live SVG Sun, Moon phases, Line Clouds, Rain, Snow, Thunder & AQI transformations.',
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
                      _buildSimChip('Sunny & Clear', WeatherSimMode.sunnyDay, setSheetState, theme, isDark),
                      _buildSimChip('Starry Night', WeatherSimMode.starryNight, setSheetState, theme, isDark),
                      _buildSimChip('Moving Clouds', WeatherSimMode.cloudySky, setSheetState, theme, isDark),
                      _buildSimChip('Rain Showers', WeatherSimMode.rainyDeluge, setSheetState, theme, isDark),
                      _buildSimChip('Thunder Lightning', WeatherSimMode.thunderstorm, setSheetState, theme, isDark),
                      _buildSimChip('Snowfall', WeatherSimMode.snowfall, setSheetState, theme, isDark),
                      _buildSimChip('Mountain Flood', WeatherSimMode.mountainFlood, setSheetState, theme, isDark),
                      _buildSimChip('Tornado Twister', WeatherSimMode.tornadoTwister, setSheetState, theme, isDark),
                      _buildSimChip('Toxic Smog', WeatherSimMode.severeSmog, setSheetState, theme, isDark),
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
  final bool isSnow;
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
    required this.isSnow,
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

class _CloudTrackSpec {
  final int lane; // 0 = upper, 1 = mid, 2 = foreground
  final double y;
  final double scale;
  final double phaseOffset;
  final int cycles; // Integer cycles per animProgress loop for zero jump
  final bool isSecondary;

  const _CloudTrackSpec({
    required this.lane,
    required this.y,
    required this.scale,
    required this.phaseOffset,
    required this.cycles,
    required this.isSecondary,
  });
}

// ---------------------------------------------------------------------------
// DUST & DANDER CUSTOM VECTOR ICON (Droplet + Exclamation + Particle Sprinkles)
// ---------------------------------------------------------------------------
class _DustDropletIconPainter extends CustomPainter {
  final Color color;
  const _DustDropletIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final dropPaint = Paint()..color = color;
    // Teardrop slightly left-aligned so exclamation and dust motes fit cleanly
    final cx = w * 0.40;
    final dropPath = Path()
      ..moveTo(cx, h * 0.14)
      ..cubicTo(cx + w * 0.24, h * 0.42, cx + w * 0.24, h * 0.64, cx, h * 0.72)
      ..cubicTo(cx - w * 0.24, h * 0.64, cx - w * 0.24, h * 0.42, cx, h * 0.14)
      ..close();
    canvas.drawPath(dropPath, dropPaint);

    // Exclamation mark next to droplet
    final exPaint = Paint()
      ..color = color
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.76, h * 0.18), Offset(w * 0.76, h * 0.46), exPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.60), 1.3, dropPaint);

    // Fine dust / dander particle dots beneath
    const dots = [
      [0.14, 0.80, 1.1],
      [0.28, 0.86, 1.3],
      [0.44, 0.84, 1.0],
      [0.58, 0.88, 1.2],
      [0.72, 0.82, 1.1],
      [0.86, 0.86, 1.0],
      [0.36, 0.76, 0.9],
      [0.64, 0.76, 1.0],
    ];
    for (final d in dots) {
      canvas.drawCircle(Offset(w * d[0], h * d[1]), d[2], dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustDropletIconPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// CELESTIAL SKY SVG PAINTER
// - Larger Sun & Moon pushed higher up right below the hover sheet title
// - Abundant line-by-line clouds drifting gently left-to-right across 3 lanes
// - Smooth edge fade, birds, breeze streams, dust motes, twinkling stars +
//   shooting stars, multi-layer rain + splash ripples, drifting snow crystals,
//   lightning flash, flood surge waves & tornado twister vortex
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
  final StationeryTheme theme;

  _CelestialSkySvgPainter({
    required this.weather,
    required this.moonPhase,
    required this.animProgress,
    required this.lightningProgress,
    required this.floodProgress,
    required this.twisterProgress,
    required this.isDark,
    required this.accentColor,
    required this.theme,
  });

  double _edgeFadeAlpha(double x, double w) {
    const fadeZone = 28.0;
    if (x < fadeZone) return (x / fadeZone).clamp(0.0, 1.0);
    if (x > w - fadeZone) return ((w - x) / fadeZone).clamp(0.0, 1.0);
    return 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Subtle thunderstorm sky flash pulse
    if (weather.isThunder && lightningProgress > 0.80) {
      final flashAlpha = ((lightningProgress - 0.80) / 0.20).clamp(0.0, 1.0) * 0.14;
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFFEF08A).withValues(alpha: flashAlpha),
      );
    }

    // 1. Night Twinkling Stars + Periodic Shooting Stars
    if (!weather.isDay) {
      final starPaint = Paint()..color = (isDark ? Colors.white : theme.text);
      final starOffsets = <Offset>[
        Offset(cx - 150, 12),
        Offset(cx - 122, 26),
        Offset(cx - 94, 10),
        Offset(cx - 66, 24),
        Offset(cx - 34, 14),
        Offset(cx - 4, 9),
        Offset(cx + 68, 12),
        Offset(cx + 98, 22),
        Offset(cx + 128, 11),
        Offset(cx + 152, 28),
        Offset(cx - 134, 52),
        Offset(cx - 78, 46),
        Offset(cx + 88, 44),
        Offset(cx + 138, 52),
        Offset(cx - 110, 72),
        Offset(cx + 114, 70),
      ];
      for (int i = 0; i < starOffsets.length; i++) {
        final twinkle = (math.sin((animProgress * math.pi * 6) + i * 1.35) + 1.0) / 2.0;
        starPaint.color = (isDark ? Colors.white : theme.text).withValues(alpha: 0.20 + (twinkle * 0.68));
        canvas.drawCircle(starOffsets[i], 0.9 + (twinkle * 1.05), starPaint);
      }

      // Two staggered delicate shooting stars
      for (int s = 0; s < 2; s++) {
        final shootPhase = (animProgress * 2.0 + s * 0.5) % 1.0;
        if (shootPhase < 0.22) {
          final t = shootPhase / 0.22;
          final startX = s == 0 ? cx - 105 : cx + 10;
          final sx = startX + (t * 115);
          final sy = (s == 0 ? 8.0 : 14.0) + (t * 24);
          final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
          final shootPaint = Paint()
            ..color = (isDark ? const Color(0xFFFEF08A) : accentColor).withValues(alpha: alpha * 0.78)
            ..strokeWidth = 1.65
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(sx, sy), Offset(sx - 20, sy - 5), shootPaint);
        }
      }
    }

    // 2. Gentle Continuous Left-to-Right Wind / Breeze Streamlines + Drifting Air Motes
    final breezePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round;
    const breezeRows = [18.0, 38.0, 60.0, 82.0];
    for (int i = 0; i < breezeRows.length; i++) {
      final t = (animProgress * 3.0 + (i * 0.27)) % 1.0;
      final bx = -55.0 + t * (w + 110.0);
      final by = breezeRows[i] + math.sin((animProgress * math.pi * 4) + i) * 2.0;
      final alpha = _edgeFadeAlpha(bx, w) * 0.25;
      breezePaint.color = (isDark ? Colors.white : theme.textSecondary).withValues(alpha: alpha);
      final path = Path()
        ..moveTo(bx - 26, by)
        ..quadraticBezierTo(bx, by - 5.5, bx + 28, by);
      canvas.drawPath(path, breezePaint);
    }

    // Subtle floating atmospheric particles drifting left-to-right
    final motePaint = Paint();
    for (int i = 0; i < 8; i++) {
      final t = (animProgress * 2.0 + (i * 0.125)) % 1.0;
      final mx = -20.0 + t * (w + 40.0);
      final my = 16.0 + ((i * 11.0) % (h - 32.0)) + math.sin(animProgress * math.pi * 6 + i) * 2.5;
      final mAlpha = _edgeFadeAlpha(mx, w) * (weather.aqi > 120 ? 0.36 : 0.22);
      motePaint.color = (weather.aqi > 120 ? weather.aqiColor : (isDark ? Colors.white : accentColor))
          .withValues(alpha: mAlpha);
      canvas.drawCircle(Offset(mx, my), i.isEven ? 1.5 : 1.1, motePaint);
    }

    // 3. Minimalist Gliding Birds in calm daytime sky
    if (weather.isDay && !weather.isRain && !weather.isThunder && !weather.isSnow) {
      final birdPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.45
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      const birdSpecs = [
        [0.10, 18.0, 0.95],
        [0.38, 28.0, 0.84],
        [0.64, 14.0, 0.90],
        [0.86, 25.0, 0.80],
      ];
      for (int i = 0; i < birdSpecs.length; i++) {
        final spec = birdSpecs[i];
        final progress = (animProgress * 2.0 + spec[0]) % 1.0;
        final bx = -24.0 + progress * (w + 48.0);
        final by = spec[1] + math.sin(progress * math.pi * 6 + i) * 3.0;
        final flap = math.sin(animProgress * math.pi * 20 + i * 2.1) * 3.2;
        final span = 6.8 * spec[2];
        birdPaint.color = (isDark ? Colors.white : theme.text).withValues(alpha: _edgeFadeAlpha(bx, w) * 0.56);
        final bPath = Path()
          ..moveTo(bx - span, by - flap)
          ..quadraticBezierTo(bx - span * 0.45, by - 3.5, bx, by)
          ..quadraticBezierTo(bx + span * 0.45, by - 3.5, bx + span, by - flap);
        canvas.drawPath(bPath, birdPaint);
      }
    }

    // 4. Abundant Line-by-Line Drifting Cloud Tracks (Left -> Right across 3 layered rows)
    final bool denseClouds = weather.isCloudy || weather.isRain || weather.isThunder || weather.isSnow;
    final cloudSpecs = <_CloudTrackSpec>[
      // Line 1 (Top sky row, gentle 1x drift)
      const _CloudTrackSpec(lane: 0, y: 14.0, scale: 0.54, phaseOffset: 0.03, cycles: 1, isSecondary: true),
      const _CloudTrackSpec(lane: 0, y: 16.0, scale: 0.60, phaseOffset: 0.20, cycles: 1, isSecondary: true),
      const _CloudTrackSpec(lane: 0, y: 13.5, scale: 0.56, phaseOffset: 0.37, cycles: 1, isSecondary: true),
      const _CloudTrackSpec(lane: 0, y: 16.5, scale: 0.62, phaseOffset: 0.54, cycles: 1, isSecondary: true),
      const _CloudTrackSpec(lane: 0, y: 14.5, scale: 0.55, phaseOffset: 0.71, cycles: 1, isSecondary: true),
      const _CloudTrackSpec(lane: 0, y: 16.0, scale: 0.58, phaseOffset: 0.88, cycles: 1, isSecondary: true),
      if (denseClouds)
        const _CloudTrackSpec(lane: 0, y: 15.0, scale: 0.64, phaseOffset: 0.45, cycles: 1, isSecondary: true),

      // Line 2 (Middle sky row, gentle 2x drift)
      const _CloudTrackSpec(lane: 1, y: 36.0, scale: 0.68, phaseOffset: 0.07, cycles: 2, isSecondary: true),
      const _CloudTrackSpec(lane: 1, y: 39.0, scale: 0.74, phaseOffset: 0.27, cycles: 2, isSecondary: false),
      const _CloudTrackSpec(lane: 1, y: 35.5, scale: 0.70, phaseOffset: 0.47, cycles: 2, isSecondary: true),
      const _CloudTrackSpec(lane: 1, y: 39.5, scale: 0.76, phaseOffset: 0.67, cycles: 2, isSecondary: false),
      const _CloudTrackSpec(lane: 1, y: 37.0, scale: 0.69, phaseOffset: 0.87, cycles: 2, isSecondary: true),
      if (denseClouds)
        const _CloudTrackSpec(lane: 1, y: 38.0, scale: 0.78, phaseOffset: 0.57, cycles: 2, isSecondary: false),

      // Line 3 (Foreground lower row, slightly brisker 3x gentle breeze drift)
      const _CloudTrackSpec(lane: 2, y: 60.0, scale: 0.84, phaseOffset: 0.04, cycles: 3, isSecondary: false),
      const _CloudTrackSpec(lane: 2, y: 64.0, scale: 0.94, phaseOffset: 0.24, cycles: 3, isSecondary: false),
      const _CloudTrackSpec(lane: 2, y: 59.0, scale: 0.86, phaseOffset: 0.44, cycles: 3, isSecondary: false),
      const _CloudTrackSpec(lane: 2, y: 63.0, scale: 0.90, phaseOffset: 0.64, cycles: 3, isSecondary: false),
      const _CloudTrackSpec(lane: 2, y: 61.0, scale: 0.85, phaseOffset: 0.84, cycles: 3, isSecondary: false),
      if (denseClouds)
        const _CloudTrackSpec(lane: 2, y: 65.0, scale: 0.95, phaseOffset: 0.34, cycles: 3, isSecondary: false),
    ];

    final resolvedClouds = <({Offset center, double scale, bool isSecondary, Path path, double alpha})>[];
    const horizontalMargin = 54.0;
    final totalSpan = w + (horizontalMargin * 2);

    for (final spec in cloudSpecs) {
      final t = ((animProgress * spec.cycles) + spec.phaseOffset) % 1.0;
      final dx = -horizontalMargin + (t * totalSpan);
      final bob = math.sin((animProgress * math.pi * 2 * spec.cycles) + (spec.phaseOffset * math.pi * 2)) * 1.4;
      final center = Offset(dx, spec.y + bob);
      final path = _buildUnifiedCloudPath(center, spec.scale);
      final alpha = _edgeFadeAlpha(dx, w);
      resolvedClouds.add((
        center: center,
        scale: spec.scale,
        isSecondary: spec.isSecondary,
        path: path,
        alpha: alpha,
      ));
    }

    // 5. Paint Upper/Mid Back Clouds behind Sun/Moon
    for (final c in resolvedClouds.where((c) => c.isSecondary)) {
      _paintSoftCloud(
        canvas,
        c.center,
        c.scale,
        isSecondary: true,
        precomputedPath: c.path,
        alphaScale: c.alpha,
      );
    }

    // 6. Isolated Layer for Larger Sun or Moon (pushed higher up under title) + Foreground Cutout
    final celestialCenter = Offset(cx + 26, 33.5);
    canvas.saveLayer(Offset.zero & size, Paint());
    if (weather.isDay) {
      _paintSvgSun(canvas, celestialCenter);
    } else {
      _paintSvgMoon(canvas, celestialCenter);
    }

    final clearFill = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    final clearHalo = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final c in resolvedClouds.where((c) => !c.isSecondary)) {
      canvas.drawPath(c.path, clearFill);
      canvas.drawPath(c.path, clearHalo);
    }
    canvas.restore();

    // 7. Foreground Crisp Clouds (Line 2/3)
    for (final c in resolvedClouds.where((c) => !c.isSecondary)) {
      _paintSoftCloud(
        canvas,
        c.center,
        c.scale,
        isSecondary: false,
        precomputedPath: c.path,
        alphaScale: c.alpha,
      );
    }

    // 8. Precipitation, Thunder, Flood Surge & Tornado Twister Animations
    final foregroundClouds = resolvedClouds.where((c) => !c.isSecondary && c.center.dx > 20 && c.center.dx < w - 20).toList();
    if (weather.isRain || weather.isThunder) {
      for (final c in foregroundClouds) {
        _paintSvgRain(canvas, c.center.dx, c.center.dy, c.scale, c.alpha, h);
      }
    }
    if (weather.isSnow) {
      _paintSvgSnow(canvas, w, h);
    }
    if (weather.isThunder) {
      final anchorX = foregroundClouds.isNotEmpty ? foregroundClouds.first.center.dx : cx - 10;
      final anchorY = foregroundClouds.isNotEmpty ? foregroundClouds.first.center.dy : 60.0;
      _paintSvgThunder(canvas, anchorX, anchorY);
    }
    if (weather.isFlood) {
      _paintSvgFlood(canvas, w, h);
    }
    if (weather.isTwister) {
      _paintSvgTwister(canvas, cx - 34, h);
    }

    canvas.restore();
  }

  Path _buildUnifiedCloudPath(Offset center, double scale) {
    final u = 1.72 * scale;
    final ox = center.dx - (30.0 * u);
    final oy = center.dy - (32.0 * u);
    return Path()
      ..moveTo(ox + 16.5 * u, oy + 43.0 * u)
      ..lineTo(ox + 42.0 * u, oy + 43.0 * u)
      ..cubicTo(ox + 45.75 * u, oy + 43.0 * u, ox + 48.8 * u, oy + 39.95 * u, ox + 48.8 * u, oy + 36.2 * u)
      ..cubicTo(ox + 48.8 * u, oy + 32.45 * u, ox + 45.75 * u, oy + 29.4 * u, ox + 42.0 * u, oy + 29.4 * u)
      ..cubicTo(ox + 39.4 * u, oy + 29.4 * u, ox + 37.1 * u, oy + 30.6 * u, ox + 36.0 * u, oy + 32.2 * u)
      ..cubicTo(ox + 35.4 * u, oy + 25.3 * u, ox + 31.3 * u, oy + 20.6 * u, ox + 26.2 * u, oy + 20.6 * u)
      ..cubicTo(ox + 20.9 * u, oy + 20.6 * u, ox + 16.8 * u, oy + 25.1 * u, ox + 16.6 * u, oy + 31.2 * u)
      ..cubicTo(ox + 13.3 * u, oy + 31.2 * u, ox + 10.8 * u, oy + 33.7 * u, ox + 10.8 * u, oy + 37.0 * u)
      ..cubicTo(ox + 10.8 * u, oy + 40.3 * u, ox + 13.5 * u, oy + 43.0 * u, ox + 16.5 * u, oy + 43.0 * u)
      ..close();
  }

  void _paintSoftCloud(
    Canvas canvas,
    Offset center,
    double scale, {
    required bool isSecondary,
    Path? precomputedPath,
    double alphaScale = 1.0,
  }) {
    if (alphaScale <= 0.02) return;
    final path = precomputedPath ?? _buildUnifiedCloudPath(center, scale);

    final cloudFill = Paint()
      ..color = (isSecondary
              ? (isDark ? const Color(0xFF23232C) : theme.lavenderBubble).withValues(alpha: 0.44 * alphaScale)
              : (isDark ? const Color(0xFF22222A) : theme.lavenderBubble).withValues(alpha: 0.72 * alphaScale))
      ..style = PaintingStyle.fill;

    final cloudStroke = Paint()
      ..color = (isSecondary
              ? (isDark ? const Color(0xFFF4F4F5) : theme.text).withValues(alpha: 0.42 * alphaScale)
              : (isDark ? const Color(0xFFF4F4F5) : theme.text).withValues(alpha: 0.95 * alphaScale))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSecondary ? 1.2 : 1.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, cloudFill);
    canvas.drawPath(path, cloudStroke);
  }

  void _paintSvgSun(Canvas canvas, Offset center) {
    const r = 24.5;
    final sunCol = isDark ? const Color(0xFFFEF08A) : accentColor;
    final pulse = 1.0 + (math.sin(animProgress * math.pi * 6) * 0.09);

    // Warm breathing outer corona
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          sunCol.withValues(alpha: isDark ? 0.32 : 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.15 * pulse));
    canvas.drawCircle(center, r * 2.15 * pulse, auraPaint);

    // Crisp rotating primary & secondary solar rays
    final rayPaint = Paint()
      ..color = sunCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final rot = animProgress * math.pi * 2;
    for (int i = 0; i < 12; i++) {
      final angle = rot + (i * (math.pi / 6));
      final isMajor = i.isEven;
      const inner = r * 1.18;
      final outer = r * (isMajor ? 1.52 * pulse : 1.35);
      final p1 = Offset(center.dx + math.cos(angle) * inner, center.dy + math.sin(angle) * inner);
      final p2 = Offset(center.dx + math.cos(angle) * outer, center.dy + math.sin(angle) * outer);
      canvas.drawLine(p1, p2, rayPaint..strokeWidth = isMajor ? 1.8 : 1.3);
    }

    // Translucent UI-themed sun disc + inner shimmer ring + crisp outline
    final sunFill = Paint()
      ..color = sunCol.withValues(alpha: isDark ? 0.26 : 0.19)
      ..style = PaintingStyle.fill;
    final sunStroke = Paint()
      ..color = sunCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(center, r, sunFill);
    canvas.drawCircle(center, r, sunStroke);
  }

  void _paintSvgMoon(Canvas canvas, Offset center) {
    const r = 24.5;
    final pulse = 1.0 + (math.sin(animProgress * math.pi * 6) * 0.09);

    // Pulsing Moon Glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE0E7FF).withValues(alpha: 0.50),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.15 * pulse));
    canvas.drawCircle(center, r * 2.15 * pulse, glow);

    // Dark base disc
    final darkBase = Paint()..color = isDark ? const Color(0xFF1E2430) : const Color(0xFFCBD5E1);
    canvas.drawCircle(center, r, darkBase);

    // Exact lit lunar phase
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

    // Subtle lunar craters
    final craterPaint = Paint()..color = (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)).withValues(alpha: 0.24);
    canvas.drawCircle(Offset(center.dx - 6, center.dy - 7), 3.6, craterPaint);
    canvas.drawCircle(Offset(center.dx + 7, center.dy + 6), 2.6, craterPaint);

    final stroke = Paint()
      ..color = (isDark ? Colors.white : theme.text).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(center, r, stroke);
  }

  void _paintSvgRain(Canvas canvas, double cloudX, double cloudY, double scale, double alphaScale, double h) {
    final rainPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.88 * alphaScale)
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final x = (cloudX - 16 * scale) + (i * 10.5 * scale);
      final dropProg = (animProgress * 7.0 + (i * 0.24)) % 1.0;
      final yStart = (cloudY + 13 * scale) + (dropProg * 18.0);
      canvas.drawLine(Offset(x, yStart), Offset(x - 2.6, yStart + 7.5), rainPaint);

      // Animated puddle splash ripple near sky baseline
      if (dropProg > 0.82) {
        final splashT = ((dropProg - 0.82) / 0.18).clamp(0.0, 1.0);
        final splashPaint = Paint()
          ..color = accentColor.withValues(alpha: (1.0 - splashT) * 0.55 * alphaScale)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x - 2.0, h - 6), width: 4.0 + splashT * 7.0, height: 2.2),
          splashPaint,
        );
      }
    }
  }

  void _paintSvgSnow(Canvas canvas, double w, double h) {
    final snowPaint = Paint()
      ..color = (isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0EA5E9)).withValues(alpha: 0.88)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 18; i++) {
      final baseFrac = (i + 0.5) / 18.0;
      final prog = (animProgress * 4.0 + (i * 0.17)) % 1.0;
      final sway = math.sin((animProgress * math.pi * 8) + i) * 7.0;
      final sx = (baseFrac * w) + sway;
      final sy = 10.0 + (prog * (h - 16.0));
      final alpha = math.sin(prog * math.pi).clamp(0.0, 1.0) * _edgeFadeAlpha(sx, w);
      snowPaint.color = (isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0284C7)).withValues(alpha: alpha * 0.88);
      final r = i.isEven ? 2.8 : 2.1;
      canvas.drawLine(Offset(sx - r, sy), Offset(sx + r, sy), snowPaint);
      canvas.drawLine(Offset(sx, sy - r), Offset(sx, sy + r), snowPaint);
      if (i % 3 == 0) {
        canvas.drawLine(Offset(sx - r * 0.65, sy - r * 0.65), Offset(sx + r * 0.65, sy + r * 0.65), snowPaint);
      }
    }
  }

  void _paintSvgThunder(Canvas canvas, double cloudX, double cloudY) {
    final isFlashing = lightningProgress > 0.78;
    final bolt = Path();
    final bx = cloudX + 4;
    final by = cloudY + 10;

    bolt.moveTo(bx + 4, by);
    bolt.lineTo(bx - 5, by + 13);
    bolt.lineTo(bx + 1, by + 13);
    bolt.lineTo(bx - 6, by + 29);
    bolt.lineTo(bx + 6, by + 11);
    bolt.lineTo(bx, by + 11);
    bolt.close();

    final boltPaint = Paint()
      ..color = isFlashing ? const Color(0xFFFEF08A) : const Color(0xFFFBBF24);
    canvas.drawPath(bolt, boltPaint);

    if (isFlashing) {
      final halo = Paint()
        ..color = const Color(0xFFFEF08A).withValues(alpha: 0.68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6;
      canvas.drawPath(bolt, halo);
    }
  }

  void _paintSvgFlood(Canvas canvas, double w, double h) {
    final wavePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int row = 0; row < 2; row++) {
      final yBase = h - 10.0 - (row * 6.0);
      final phase = (floodProgress * math.pi * 2) + (row * 1.4);
      final path = Path()..moveTo(0, yBase);
      for (double x = 0; x <= w; x += 14) {
        final y = yBase + math.sin((x / 24.0) + phase) * 3.0;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  void _paintSvgTwister(Canvas canvas, double centerX, double h) {
    final funnelPaint = Paint()
      ..color = (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)).withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final frac = i / 5.0;
      final y = 36.0 + frac * (h - 46.0);
      final radiusX = 24.0 * (1.0 - frac * 0.72);
      final wobble = math.sin((twisterProgress * math.pi * 2) + (i * 1.1)) * 5.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(centerX + wobble, y), width: radiusX * 2, height: 6.5),
        funnelPaint,
      );
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
        // Trim dead top/bottom padding around the character while preserving full leaves & pose
        .replaceFirst('viewBox="0 0 1134 1005"', 'viewBox="80 108 1000 832"')
        // Strip out smog dots / gray circles for a clean, crisp character
        .replaceAll(RegExp(r'<circle[^>]+fill="(?:#A8A29E|#D6D3D1|#78716C)"[^>]*/>'), '')
        .replaceAll(RegExp(r'<circle[^>]+fill-opacity="[^"]+"[^>]+fill="(?:#A8A29E|#D6D3D1|#78716C)"[^>]*/>'), '')
        .replaceAll(RegExp(r'<circle[^>]+fill="(?:#A8A29E|#D6D3D1|#78716C)"[^>]+fill-opacity="[^"]+"[^>]*/>'), '')
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

    // Vibrating / moving / jitter animation turned off completely for a clean, stationary mascot
    const Offset charOffset = Offset.zero;
    const double scaleX = 1.0;
    const double scaleY = 1.0;

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
