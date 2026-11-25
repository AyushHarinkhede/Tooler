import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/screens/security_screen.dart';
import 'package:tooler/screens/sound_recorder_screen.dart';
import 'package:tooler/screens/speed_test_screen.dart';
import 'package:tooler/screens/step_counter_screen.dart';
import 'package:tooler/screens/timer_screen.dart';
import 'package:tooler/services/pedometer_sensor_service.dart';
import 'package:tooler/theme/stationery_theme.dart';
import 'package:tooler/widgets_3d/smooth_radial_gauge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final darkTheme = StationeryTheme.custom(
    isDark: true,
    accentPalette: ToolerAccent.rose,
  );
  final lightTheme = StationeryTheme.custom(
    isDark: false,
    accentPalette: ToolerAccent.lilac,
  );

  testWidgets('SmoothRadialGauge animates smoothly and responds to listenable',
      (WidgetTester tester) async {
    final targetNotifier = ValueNotifier<double>(0.25);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SmoothRadialGauge(
              size: 264,
              progress: 0.25,
              progressListenable: targetNotifier,
              gaugeColor: const Color(0xFF10B981),
              primaryColor: darkTheme.primary,
              trackColor: darkTheme.border,
              smoothDamping: true,
              enableAutoPeakHold: true,
              center: const Text('25%'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SmoothRadialGauge), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120));
    targetNotifier.value = 0.85;
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 800));

    targetNotifier.dispose();
  });

  testWidgets('TimerScreen renders independent 264px SmoothRadialGauge',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TimerScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final gaugeFinder = find.byType(SmoothRadialGauge);
    expect(gaugeFinder, findsOneWidget);
    final gauge = tester.widget<SmoothRadialGauge>(gaugeFinder);
    expect(gauge.size, 264.0);
    expect(gauge.smoothDamping, isTrue);

    // Trigger +30s quick add and ensure no errors
    await tester.tap(find.text('+30s'));
    await tester.pump(const Duration(milliseconds: 120));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('StepCounterScreen renders unboxed 260px SmoothRadialGauge',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StepCounterScreen(theme: darkTheme)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final gaugeFinder = find.byType(SmoothRadialGauge);
    expect(gaugeFinder, findsOneWidget);
    final gauge = tester.widget<SmoothRadialGauge>(gaugeFinder);
    expect(gauge.size, 260.0);
    expect(gauge.smoothDamping, isTrue);
    expect(find.text('WALKING LIVE'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    PedometerSensorService().dispose();
  });

  testWidgets('SoundRecorderScreen renders unboxed 264px SmoothRadialGauge',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SoundRecorderScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    final gaugeFinder = find.byType(SmoothRadialGauge);
    expect(gaugeFinder, findsOneWidget);
    final gauge = tester.widget<SmoothRadialGauge>(gaugeFinder);
    expect(gauge.size, 264.0);
    expect(find.text('dB'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('SpeedTestScreen renders unboxed 264px SmoothRadialGauge',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SpeedTestScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final gaugeFinder = find.byType(SmoothRadialGauge);
    expect(gaugeFinder, findsOneWidget);
    final gauge = tester.widget<SmoothRadialGauge>(gaugeFinder);
    expect(gauge.size, 264.0);
    expect(find.text('START SPEED TEST'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'SecurityScreen renders unboxed 264px gauge with multi-color waves in dark and light themes',
      (WidgetTester tester) async {
    for (final t in [darkTheme, lightTheme]) {
      await tester.pumpWidget(
        MaterialApp(
          home: SecurityScreen(theme: t),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 120));

      final gaugeFinder = find.byType(SmoothRadialGauge);
      expect(gaugeFinder, findsOneWidget);
      final gauge = tester.widget<SmoothRadialGauge>(gaugeFinder);
      expect(gauge.size, 264.0);
      expect(gauge.smoothDamping, isTrue);
      expect(find.text('DEEP AUDIT'), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
