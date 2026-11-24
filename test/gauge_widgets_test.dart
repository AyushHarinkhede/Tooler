import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      // Before scan completes, Security Risk Detection & Recycle Bin must stay hidden
      expect(find.textContaining('SECURITY RISK DETECTION'), findsNothing);
      expect(find.text('RECYCLE BIN & TRASH CLEANER'), findsNothing);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'SecurityScreen post-scan shows shifted risk card, Clean & Finish, Recycle Bin, and Nothing Else sweet card',
      (WidgetTester tester) async {
    const MethodChannel secChannel =
        MethodChannel('com.tooler.tooler/security_scan');
    const String eventChannelName = 'com.tooler.tooler/security_scan_events';
    final List<MethodCall> methodCalls = [];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      secChannel,
      (MethodCall call) async {
        methodCalls.add(call);
        if (call.method == 'getSecurityInfo') {
          return {
            'androidVersion': 'Android 14',
            'sdkInt': 34,
            'hasAllFilesAccess': true,
            'hasUsageAccess': true,
            'hasNotificationAccess': true,
            'totalRamMb': 8192,
            'availRamMb': 4096,
            'totalStorageBytes': 128000000000,
            'availStorageBytes': 64000000000,
            'usedStorageBytes': 64000000000,
          };
        }
        if (call.method == 'startDeepScan') {
          scheduleMicrotask(() {
            const codec = StandardMethodCodec();
            final payload = codec.encodeSuccessEnvelope({
              'type': 'complete',
              'securityScore': 82,
              'durationMs': 1200,
              'appsScanned': 42,
              'filesScanned': 1500,
              'hasAllFilesAccess': true,
              'hasUsageAccess': true,
              'hasNotificationAccess': true,
              'systemWarnings': [
                {
                  'id': 'adb_enabled',
                  'fingerprint': 'sys:adb_enabled:1',
                  'title': 'USB Debugging (ADB) is Active',
                  'severity': 'MEDIUM',
                  'category': 'System Port',
                  'detail': 'ADB active',
                  'actionType': 'open_dev_settings',
                }
              ],
              'suspiciousApps': [],
              'fishyFiles': [
                {
                  'name': 'dropper.apk',
                  'path': '/storage/emulated/0/Download/dropper.apk',
                  'fingerprint': 'file:/storage/emulated/0/Download/dropper.apk:2048:100',
                  'sizeBytes': 2048,
                  'severity': 'HIGH',
                  'threatType': 'Stray APK',
                  'detail': 'Found in Download',
                }
              ],
              'junkFiles': [
                {
                  'name': 'cache.tmp',
                  'path': '/storage/emulated/0/cache.tmp',
                  'fingerprint': 'junk:/storage/emulated/0/cache.tmp:4096:100',
                  'sizeBytes': 4096,
                  'category': 'Temp',
                  'folder': '0',
                }
              ],
              'largestFiles': [
                {
                  'name': 'video.mp4',
                  'path': '/storage/emulated/0/Movies/video.mp4',
                  'sizeBytes': 52428800,
                  'extension': 'MP4',
                  'folder': 'Movies',
                }
              ],
              'unopenedFiles': [
                {
                  'name': 'old.pdf',
                  'path': '/storage/emulated/0/Download/old.pdf',
                  'sizeBytes': 204800,
                  'extension': 'PDF',
                  'folder': 'Download',
                  'ageDays': 40,
                  'statusLabel': 'Never Opened',
                  'neverOpened': true,
                }
              ],
              'backgroundApps': [
                {
                  'packageName': 'com.example.bgapp',
                  'appName': 'Smart BG App',
                  'isForegroundService': true,
                  'statusLabel': 'Active Service',
                  'estimatedRamMb': 64,
                }
              ],
              'activeNotifications': [
                {
                  'key': 'k1',
                  'packageName': 'com.example.bgapp',
                  'appName': 'Smart BG App',
                  'title': 'Alert',
                  'isClearable': true,
                }
              ],
              'trashFiles': [
                {
                  'id': '/storage/.Trash/old_trash.jpg',
                  'name': 'old_trash.jpg',
                  'path': '/storage/.Trash/old_trash.jpg',
                  'mediaUri': '',
                  'sizeBytes': 8192,
                  'source': 'Recycle Folder',
                }
              ],
            });
            tester.binding.defaultBinaryMessenger.handlePlatformMessage(
              eventChannelName,
              payload,
              (_) {},
            );
          });
          return true;
        }
        if (call.method == 'cleanMasterSweep') {
          return {
            'deletedJunkCount': 1,
            'deletedFishyCount': 1,
            'deletedJunkPaths': ['/storage/emulated/0/cache.tmp'],
            'deletedFishyPaths': ['/storage/emulated/0/Download/dropper.apk'],
            'freedBytes': 6144,
            'killedBgCount': 1,
            'killedPackages': ['com.example.bgapp'],
            'protectedFgsPackages': <String>[],
            'ramFreedMb': 128,
            'availRamMb': 4224,
            'notificationsCleared': 1,
            'notificationListenerConnected': true,
          };
        }
        if (call.method == 'deleteFiles') {
          final paths = (call.arguments['paths'] as List).cast<String>();
          return {
            'deletedCount': paths.length,
            'freedBytes': 52428800,
            'deletedPaths': paths,
            'availRamMb': 4224,
          };
        }
        if (call.method == 'markResolvedFingerprints') return true;
        if (call.method == 'cleanRecycleBin') {
          return {
            'deletedCount': 1,
            'freedBytes': 8192,
            'deletedIds': ['/storage/.Trash/old_trash.jpg'],
          };
        }
        return null;
      },
    );

    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      eventChannelName,
      (ByteData? message) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SecurityScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Tap START REAL DEEP SCAN
    await tester.tap(find.text('START REAL DEEP SCAN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // After scan completes:
    // 1) Ready to Clean & Finish appears
    expect(find.text('READY TO CLEAN & FINISH'), findsOneWidget);
    // 2) Security Risk Detection moved below telemetry and now visible
    expect(find.textContaining('SECURITY RISKS DETECTED'), findsOneWidget);
    final telemetryTop = tester.getTopLeft(find.text('REAL HARDWARE TELEMETRY')).dy;
    final riskTop = tester.getTopLeft(find.textContaining('SECURITY RISKS DETECTED')).dy;
    expect(riskTop, greaterThan(telemetryTop));
    // 3) Recycle Bin & Trash Cleaner section strictly visible at the bottom
    expect(find.text('RECYCLE BIN & TRASH CLEANER'), findsOneWidget);

    final mainScrollable = find.byType(Scrollable).first;

    // 4) Switch to Largest tab & verify Select All + Permanent Delete controls exist
    await tester.scrollUntilVisible(
      find.text('Largest'),
      200,
      scrollable: mainScrollable,
    );
    await tester.tap(find.text('Largest'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('SELECT ALL'), findsWidgets);
    await tester.tap(find.text('SELECT ALL').first);
    await tester.pump();
    expect(find.textContaining('DELETE 1 SELECTED'), findsOneWidget);

    // 5) Tap CLEAN & FINISH (4) (1-click sweep) -> shows sweet NOTHING ELSE TO CLEAN card
    await tester.scrollUntilVisible(
      find.text('CLEAN & FINISH (4)'),
      -300,
      scrollable: mainScrollable,
    );
    await tester.tap(find.text('CLEAN & FINISH (4)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('NOTHING ELSE TO CLEAN'), findsOneWidget);
    expect(methodCalls.any((c) => c.method == 'cleanMasterSweep'), isTrue);

    // Dismiss floating SnackBar and position bottom Recycle Bin button clearly in view
    final messenger = ScaffoldMessenger.of(tester.element(find.byType(Scaffold)));
    messenger.removeCurrentSnackBar();
    messenger.clearSnackBars();
    await tester.pump(const Duration(milliseconds: 400));

    // 6) Scroll to bottom Recycle Bin section & verify permanent trash clean
    await tester.scrollUntilVisible(
      find.textContaining('CLEAN RECYCLE BIN'),
      300,
      scrollable: mainScrollable,
    );
    await Scrollable.ensureVisible(
      tester.element(find.textContaining('CLEAN RECYCLE BIN')),
      alignment: 0.3,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.textContaining('CLEAN RECYCLE BIN'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Empty Trash'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(methodCalls.any((c) => c.method == 'cleanRecycleBin'), isTrue);
    expect(find.text('RECYCLE BIN IS COMPLETELY CLEAN'), findsOneWidget);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(secChannel, null);
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(eventChannelName, null);
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
