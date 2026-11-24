import 'dart:math' as math;
import 'dart:ui' as ui;
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

  test('SmoothRadialBarPainter keeps start cap pure primaryColor and maintains vivid red<->green gradient', () async {
    const startPinkRed = Color(0xFFFB7185);
    const endGreen = Color(0xFF10B981);

    // 1. Check multi-stop HSV gradient colors stay saturated for both Red->Green & Green->Red
    for (final pair in [
      (startPinkRed, endGreen),
      (endGreen, startPinkRed),
    ]) {
      final stops = buildVividGaugeGradientColors(pair.$1, pair.$2, steps: 7);
      expect(stops.first.toARGB32(), pair.$1.toARGB32());
      expect(stops.last.toARGB32(), pair.$2.toARGB32());
      for (final c in stops) {
        expect(HSVColor.fromColor(c).saturation, greaterThanOrEqualTo(0.54));
      }
    }

    // 2. Render SmoothRadialBarPainter onto offscreen 264x264 canvas & inspect starting cap pixels
    const double size = 264.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const painter = SmoothRadialBarPainter(
      progress: 0.90,
      gaugeColor: endGreen,
      primaryColor: startPinkRed,
      trackColor: Color(0xFF27272A),
    );
    painter.paint(canvas, const Size(size, size));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(byteData, isNotNull);

    Color pixelAtAngle(double deg) {
      final double rad = deg * math.pi / 180.0;
      const double radius = (size / 2.0) - 18.0;
      final int x = ((size / 2.0) + radius * math.cos(rad)).round().clamp(0, 263);
      final int y = ((size / 2.0) + radius * math.sin(rad)).round().clamp(0, 263);
      final int offset = (y * size.toInt() + x) * 4;
      final int r = byteData!.getUint8(offset);
      final int g = byteData.getUint8(offset + 1);
      final int b = byteData.getUint8(offset + 2);
      final int a = byteData.getUint8(offset + 3);
      return Color.fromARGB(a, r, g, b);
    }

    // Backward cap at 138° (just before 140° startAngle) MUST be red/pink, NOT green!
    final capColor = pixelAtAngle(138.0);
    expect((capColor.r * 255).round(), greaterThan((capColor.g * 255).round() + 40));

    // Exact start at 140° MUST match pink-red start
    final startPx = pixelAtAngle(140.0);
    expect((startPx.r * 255).round(), greaterThan((startPx.g * 255).round() + 40));

    // Midpoint at 257° (50% of 0.90 * 260°) MUST stay saturated, never muddy grey
    final midPx = pixelAtAngle(257.0);
    expect(HSVColor.fromColor(midPx).saturation, greaterThan(0.50));
  });
}
