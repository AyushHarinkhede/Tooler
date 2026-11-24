import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/screens/weather_screen.dart';
import 'package:tooler/services/weather_telemetry_service.dart';
import 'package:tooler/theme/stationery_theme.dart';
import 'package:tooler/widgets_3d/tooler_hover_sheet.dart';
import 'package:tooler/widgets_3d/weather_outfit_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final darkTheme = StationeryTheme.custom(
    isDark: true,
    accent: ToolerAccent.rose,
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('OutfitRecommendation covers snow, summer, winter, autumn, rain, and high AQI gear & tools', () {
    final snowRec = OutfitRecommendation.compute(
      const WeatherOutfitContext(
        tempC: -4.0,
        condition: 'Heavy Snowfall',
        isDay: true,
        isRain: false,
        isThunder: false,
        isCloudy: true,
        isSnow: true,
        aqi: 32,
        humidity: 78,
        windSpeedKmH: 20,
        uvIndex: 1.5,
        season: WeatherSeason.winter,
        city: 'Snow Ridge',
      ),
    );
    expect(snowRec.capStyle, CapStyle.woolBeanie);
    expect(snowRec.footwearStyle, FootwearStyle.snowBoots);
    expect(snowRec.pantStyle, PantStyle.thermalSnowPants);
    expect(snowRec.hasGloves, isTrue);
    expect(snowRec.activeToolsTitle, 'Snow Tools & Kit');

    final summerRec = OutfitRecommendation.compute(
      const WeatherOutfitContext(
        tempC: 37.0,
        condition: 'Hot Sunny Summer',
        isDay: true,
        isRain: false,
        isThunder: false,
        isCloudy: false,
        isSnow: false,
        aqi: 45,
        humidity: 35,
        windSpeedKmH: 8,
        uvIndex: 9.0,
        season: WeatherSeason.summer,
        city: 'Summer City',
      ),
    );
    expect(summerRec.capStyle, CapStyle.baseballCap);
    expect(summerRec.topStyle, TopStyle.tShirt);
    expect(summerRec.pantStyle, PantStyle.shorts);
    expect(summerRec.footwearStyle, FootwearStyle.slippers);
    expect(summerRec.hasGloves, isFalse);
    expect(summerRec.activeToolsTitle, 'Summer Tools & Clothes');

    final rainSmogRec = OutfitRecommendation.compute(
      const WeatherOutfitContext(
        tempC: 21.0,
        condition: 'Storm & Smog',
        isDay: false,
        isRain: true,
        isThunder: true,
        isCloudy: true,
        isSnow: false,
        aqi: 260,
        humidity: 90,
        windSpeedKmH: 24,
        uvIndex: 1.0,
        season: WeatherSeason.autumn,
        city: 'Storm Town',
      ),
    );
    expect(rainSmogRec.hasRaincoat, isTrue);
    expect(rainSmogRec.hasUmbrella, isTrue);
    expect(rainSmogRec.hasMask, isTrue);
    expect(rainSmogRec.hasOxygenCylinder, isTrue);
    expect(rainSmogRec.footwearStyle, FootwearStyle.rainBoots);
  });

  testWidgets(
      'WeatherScreen centers temperature, shows condition & location side-by-side (wrapping when long), renders Activities & Allergies, What to Wear hover page, and Season bar without legacy caption',
      (WidgetTester tester) async {
    // Seed cached telemetry with a short city first
    final shortData = WeatherTelemetryData(
      city: 'Pune',
      country: 'IN',
      temperatureC: 26.0,
      apparentTempC: 27.0,
      weatherCode: 0,
      isDay: true,
      condition: 'Clear Sky',
      aqi: 68,
      aqiStatus: 'Moderate',
      aqiColor: const Color(0xFFF59E0B),
      humidity: 54.0,
      windSpeedKmH: 11.0,
      uvIndex: 5.5,
      pressureHpa: 1013.0,
      pm25: 20.4,
      pm10: 42.1,
      sunriseToday: '06:15 AM',
      sunsetToday: '05:45 PM',
      dailyList: WeatherTelemetryData.defaultData().dailyList,
      hourlyList: WeatherTelemetryData.defaultData().hourlyList,
      moonPhase: MoonPhaseInfo.calculate(DateTime(2026, 11, 27)),
      lastSync: DateTime(2026, 11, 27),
    );
    SharedPreferences.setMockInitialValues({
      'tooler_cached_weather_telemetry_v2': jsonEncode(shortData.toJson()),
    });
    await WeatherTelemetryService().resetFromCacheForTest();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ToolerHoverSheet(
          title: 'Weather',
          subtitle: 'Live Weather',
          tag: 'Weather',
          theme: darkTheme,
          child: WeatherScreen(theme: darkTheme),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 250));

    // 1. Sky CustomPaint is positioned tightly right below the Weather header divider
    final titleFinder = find.text('Weather');
    expect(titleFinder, findsOneWidget);
    final skyFinder = find.descendant(
      of: find.byType(WeatherScreen),
      matching: find.byType(CustomPaint),
    );
    expect(skyFinder, findsWidgets);
    // Verify top of WeatherScreen sits directly below header divider with zero top ScrollView padding gap
    final weatherScreenTop = tester.getTopLeft(find.byType(WeatherScreen)).dy;
    final skyTop = tester.getTopLeft(skyFinder.first).dy;
    expect((skyTop - weatherScreenTop).abs(), lessThan(2.0));

    // 2. Temperature number + unit is centered cleanly
    final tempFinder = find.text('${shortData.temperatureC.round()}');
    final unitFinder = find.text('°C');
    expect(tempFinder, findsWidgets);
    expect(unitFinder, findsWidgets);
    final tempBox = tester.getRect(tempFinder.first);
    final unitBox = tester.getRect(unitFinder.first);
    final combinedCenterX = (tempBox.left + unitBox.right) / 2.0;
    expect((combinedCenterX - 195.0).abs(), lessThan(8.0));

    // 3. Condition & Location pills appear once and sit side-by-side when location is short
    final condFinder = find.text('Clear Sky');
    final locFinder = find.text('Pune, IN');
    expect(condFinder, findsOneWidget);
    expect(locFinder, findsOneWidget); // No duplicate location pill!
    expect((tester.getCenter(condFinder).dy - tester.getCenter(locFinder).dy).abs(), lessThan(6.0));

    // 4. Activities & Allergies section exists below Atmospheric Metrics
    final metricsTitle = find.text('Atmospheric Metrics');
    final activitiesTitle = find.text('Activities');
    final allergiesTitle = find.text('Allergies');
    final wearBtnFinder = find.text('What to Wear & Carry');
    expect(metricsTitle, findsOneWidget);
    expect(activitiesTitle, findsOneWidget);
    expect(allergiesTitle, findsOneWidget);
    expect(wearBtnFinder, findsOneWidget);

    expect(tester.getTopLeft(metricsTitle).dy, lessThan(tester.getTopLeft(activitiesTitle).dy));
    expect(tester.getTopLeft(activitiesTitle).dy, lessThan(tester.getTopLeft(allergiesTitle).dy));
    expect(tester.getTopLeft(allergiesTitle).dy, lessThan(tester.getTopLeft(wearBtnFinder).dy));

    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Jogging'), findsOneWidget);
    expect(find.text('Cycling'), findsOneWidget);
    expect(find.text('Hiking'), findsOneWidget);
    expect(find.text('Dust and dander'), findsOneWidget);
    expect(find.text('Pollen'), findsOneWidget);
    expect(find.text('Mold'), findsOneWidget);
    expect(find.text('Sinus & UV'), findsOneWidget);

    // Toggle Activities collapse/expand chevron cleanly
    await tester.ensureVisible(activitiesTitle);
    await tester.tap(activitiesTitle);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Running'), findsNothing);
    await tester.tap(activitiesTitle);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Running'), findsOneWidget);

    // 5. Legacy Weather Controls text and caption are removed, replaced by active Season + Icon
    expect(find.text('Weather Controls'), findsNothing);
    expect(find.text('°C/°F, Live Refresh & Simulator'), findsNothing);
    expect(find.textContaining('Season'), findsOneWidget);

    // 6. Scroll to and tap 'What to Wear & Carry' -> opens Hover Page with Tooler Character + items
    await tester.ensureVisible(wearBtnFinder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(wearBtnFinder);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(WearableToolerCharacter), findsOneWidget);
    expect(find.text('Cap / Headwear'), findsOneWidget);
    expect(find.text('Sweater / Outer'), findsOneWidget);
    expect(find.text('Shirt / T-Shirt'), findsOneWidget);
    expect(find.text('Pant Type'), findsOneWidget);
    expect(find.text('Boots / Shoes / Slippers'), findsOneWidget);
    expect(find.text('Gloves'), findsOneWidget);
    expect(find.text('Raincoat'), findsOneWidget);
    expect(find.text('Umbrella'), findsOneWidget);
    expect(find.text('Mask'), findsOneWidget);
    expect(find.text('Oxygen Cylinder'), findsOneWidget);
    expect(find.text('Weather & Seasonal Tools'), findsOneWidget);

    // Switch preset to High AQI and verify Oxygen Cylinder & N95 Mask activate
    await tester.ensureVisible(find.text('High AQI'));
    await tester.tap(find.text('High AQI'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Carry Portable O₂ Cylinder'), findsOneWidget);
    expect(find.text('Mandatory N95 / N99 Mask'), findsOneWidget);

    // Switch preset to Snow and verify Snow Tools & Kit appear
    await tester.ensureVisible(find.text('Snow'));
    await tester.tap(find.text('Snow'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Snow Tools & Kit'), findsOneWidget);
    expect(find.text('Snow Shovel'), findsOneWidget);

    // Close hover page cleanly
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pump(const Duration(milliseconds: 300));

    // Clean teardown before disposing timers/tickers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await WeatherTelemetryService().resetFromCacheForTest();
  });

  testWidgets('WeatherScreen wraps long location step-by-step below condition pill', (WidgetTester tester) async {
    final longCityData = WeatherTelemetryData(
      city: 'Chhatrapati Sambhajinagar',
      country: 'India',
      temperatureC: 24.0,
      apparentTempC: 24.0,
      weatherCode: 2,
      isDay: true,
      condition: 'Partly Cloudy',
      aqi: 55,
      aqiStatus: 'Moderate',
      aqiColor: const Color(0xFFF59E0B),
      humidity: 50.0,
      windSpeedKmH: 10.0,
      uvIndex: 4.5,
      pressureHpa: 1012.0,
      pm25: 15.0,
      pm10: 32.0,
      sunriseToday: '06:20 AM',
      sunsetToday: '05:50 PM',
      dailyList: WeatherTelemetryData.defaultData().dailyList,
      hourlyList: WeatherTelemetryData.defaultData().hourlyList,
      moonPhase: MoonPhaseInfo.calculate(DateTime(2026, 11, 27)),
      lastSync: DateTime(2026, 11, 27),
    );
    SharedPreferences.setMockInitialValues({
      'tooler_cached_weather_telemetry_v2': jsonEncode(longCityData.toJson()),
    });
    await WeatherTelemetryService().resetFromCacheForTest();

    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: WeatherScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 250));

    final condFinder = find.text('Partly Cloudy');
    final locFinder = find.text('Chhatrapati Sambhajinagar, India');
    expect(condFinder, findsOneWidget);
    expect(locFinder, findsOneWidget);
    // Long location wraps cleanly below condition pill (step-by-step)
    expect(tester.getTopLeft(locFinder).dy, greaterThan(tester.getBottomLeft(condFinder).dy - 2.0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await WeatherTelemetryService().resetFromCacheForTest();
  });

  testWidgets('WeatherScreen simulator renders Starry Night, Thunder Lightning, and Snowfall skies cleanly', (WidgetTester tester) async {
    await WeatherTelemetryService().resetFromCacheForTest();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: WeatherScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    // Open Weather Simulator via 3-dots menu
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Weather Simulator'));
    await tester.tap(find.text('Weather Simulator'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Switch through Starry Night, Thunder Lightning, and Snowfall
    await tester.ensureVisible(find.text('Starry Night'));
    await tester.tap(find.text('Starry Night'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Clear Moonlit Night'), findsOneWidget);

    await tester.ensureVisible(find.text('Thunder Lightning'));
    await tester.tap(find.text('Thunder Lightning'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Violent Thunderstorm'), findsOneWidget);

    await tester.ensureVisible(find.text('Snowfall'));
    await tester.tap(find.text('Snowfall'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Heavy Snowfall'), findsOneWidget);
    expect(find.text('Winter Season'), findsOneWidget);

    await tester.ensureVisible(find.text('Mountain Flood'));
    await tester.tap(find.text('Mountain Flood'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Mountain Flood Hazard'), findsOneWidget);

    await tester.ensureVisible(find.text('Tornado Twister'));
    await tester.tap(find.text('Tornado Twister'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Tornado Twister Vortex'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await WeatherTelemetryService().resetFromCacheForTest();
  });
}
