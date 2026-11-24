import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tooler/screens/power_screen.dart';
import 'package:tooler/theme/stationery_theme.dart';
import 'package:tooler/widgets_3d/smooth_radial_gauge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const powerChannel = MethodChannel('com.tooler.tooler/power_telemetry');
  final darkTheme = StationeryTheme.custom(
    isDark: true,
    accent: ToolerAccent.rose,
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(powerChannel, null);
  });

  testWidgets(
      'PowerScreen puts unboxed voltage SmoothRadialGauge at top with amps, watts, and brick container above brand and battery cards',
      (WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(powerChannel, (MethodCall call) async {
      if (call.method == 'getPowerTelemetry') {
        return <String, dynamic>{
          'brand': 'MOTOROLA',
          'model': 'EDGE 40 NEO',
          'percentage': 100,
          'isCharging': true,
          'isFull': true,
          'plugType': 'AC',
          'voltageV': 4.47,
          'temperatureC': 38.0,
          'health': 'Good',
          'technology': 'Li-poly',
          'capacityMah': 5000,
          'cycleCount': -1,
          'currentMa': 270.0,
          'deliveredWatts': 1.2,
          'chargingMode': 'TRICKLE FLOAT PROTECTION',
          'nativeChargeTimeMs': -1,
          'maxSupportedWatts': 68,
          'fastChargeProtocol': 'TurboPower 68W',
          'isDualCell': true,
          'chargerBrand': 'MOTOROLA',
          'chargerProtocol': 'TurboPower 68W',
          'chargerTechnology': 'TurboPower 68W (OEM Authentic)',
          'isOemConfirmed': true,
          'negotiatedChargerWatts': 68,
          'brickSource': 'Hardware V×I Negotiation',
          'cableMaxWatts': 100,
        };
      }
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PowerScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 200));

    // Unboxed top voltage gauge
    final gaugeFinder = find.byType(SmoothRadialGauge);
    expect(gaugeFinder, findsOneWidget);
    final gauge = tester.widget<SmoothRadialGauge>(gaugeFinder);
    expect(gauge.size, 264.0);
    expect(gauge.smoothDamping, isTrue);

    expect(find.text('4.47'), findsOneWidget);
    expect(find.text('V'), findsOneWidget);

    // Removed legacy words and safety/delivering captions from the top gauge section
    expect(find.text('CHARGING OUTPUT'), findsNothing);
    expect(find.text('POWER OUTPUT'), findsNothing);
    expect(find.text('FLOAT TRICKLE PROTECTION'), findsNothing);
    expect(find.textContaining('Delivering'), findsNothing);
    expect(find.textContaining('Current safely throttled'), findsNothing);

    // Ampere, Watt, and Charging Brick container
    expect(find.text('0.27'), findsOneWidget);
    expect(find.text('Ampere'), findsOneWidget);
    expect(find.text('1.2'), findsOneWidget);
    expect(find.text('Watt'), findsOneWidget);
    expect(find.text('68W'), findsOneWidget);
    expect(find.text('Brick • TurboPower'), findsOneWidget);

    // Brand and mAh / % sections below
    expect(find.text('MOTOROLA • EDGE 40 NEO'), findsOneWidget);
    expect(find.text('5,000'), findsOneWidget);
    expect(find.text('mAh'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // Verify top-to-bottom vertical ordering
    final gaugeY = tester.getTopLeft(gaugeFinder).dy;
    final brickY = tester.getTopLeft(find.text('68W')).dy;
    final brandY = tester.getTopLeft(find.text('MOTOROLA • EDGE 40 NEO')).dy;
    final mahY = tester.getTopLeft(find.text('5,000')).dy;

    expect(gaugeY, lessThan(brickY));
    expect(brickY, lessThan(brandY));
    expect(brandY, lessThan(mahY));

    // Clean teardown before disposing timer/ticker
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
