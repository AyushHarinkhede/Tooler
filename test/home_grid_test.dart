import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/screens/home_screen.dart';
import 'package:tooler/services/pedometer_sensor_service.dart';
import 'package:tooler/services/storage_service.dart';
import 'package:tooler/services/weather_telemetry_service.dart';
import 'package:tooler/theme/stationery_theme.dart';

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.tooler.tooler/widget_sync'),
      (_) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.tooler.tooler/pedometer'),
      (_) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.tooler.tooler/widget_sync'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.tooler.tooler/pedometer'),
      null,
    );
  });

  testWidgets(
      'HomeScreen removes category chips & favorite tags, renders ALL sections side-by-side in 2 columns, and allows animated drag-and-drop reordering of every card including Calculator',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          theme: darkTheme,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    // 1. Category chips & Favorite tags are completely gone
    expect(find.text('All'), findsNothing);
    expect(find.text('Calculate'), findsNothing);
    expect(find.text('Convert'), findsNothing);
    expect(find.text('Time & Tasks'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_outline_rounded), findsNothing);

    // 2. Both top tools (Calculator, Calendar, Weather, Games) AND lower tools (Step Counter, Alarm)
    // render side-by-side in the same 2-column grid
    final calcFinder = find.text('Calculator');
    final calFinder = find.text('Calendar');
    final weatherFinder = find.text('Weather');
    final gamesFinder = find.text('Games');
    final stepsFinder = find.text('Step Counter');
    final alarmFinder = find.text('Alarm');

    expect(calcFinder, findsOneWidget);
    expect(calFinder, findsOneWidget);
    expect(weatherFinder, findsOneWidget);
    expect(gamesFinder, findsOneWidget);
    expect(stepsFinder, findsOneWidget);
    expect(alarmFinder, findsOneWidget);

    final calcBox = tester.getRect(find.byKey(const ValueKey('tool_card_calc')));
    final calBox = tester.getRect(find.byKey(const ValueKey('tool_card_calendar')));
    final weatherBox = tester.getRect(find.byKey(const ValueKey('tool_card_weather')));
    final stepsBox = tester.getRect(find.byKey(const ValueKey('tool_card_steps')));
    final alarmBox = tester.getRect(find.byKey(const ValueKey('tool_card_alarm')));

    // Calculator & Calendar share row 0; Step Counter & Alarm share row 2 side-by-side
    expect((calcBox.top - calBox.top).abs(), lessThan(1.0));
    expect(calBox.left, greaterThan(calcBox.left));
    expect((stepsBox.top - alarmBox.top).abs(), lessThan(1.0));
    expect(alarmBox.left, greaterThan(stepsBox.left));
    expect(stepsBox.top, greaterThan(weatherBox.top));

    // 3. Long-press & drag Calculator onto Calendar's right slot (swapping row 0 left/right)
    final calcCard = find.byKey(const ValueKey('tool_card_calc'));
    final calCard = find.byKey(const ValueKey('tool_card_calendar'));
    final calcCenter = tester.getCenter(calcCard);
    final calCenter = tester.getCenter(calCard);

    final gesture = await tester.startGesture(calcCenter);
    await tester.pump(const Duration(milliseconds: 350)); // Trigger LongPressDraggable
    await gesture.moveTo(calCenter);
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 320));

    // Order is updated and persisted in StorageService
    final savedOrder = await StorageService().loadToolOrder();
    expect(savedOrder.first, 'calendar');
    expect(savedOrder[1], 'calc');

    // Visual layout reflects the swap: Calendar is now on the left of Calculator
    expect(
      tester.getTopLeft(find.text('Calendar')).dx,
      lessThan(tester.getTopLeft(find.text('Calculator')).dx),
    );

    // Also verify a lower tool (Step Counter) can be dragged up into top row!
    final stepsCard = find.byKey(const ValueKey('tool_card_steps'));
    final calSwappedCenter = tester.getCenter(find.byKey(const ValueKey('tool_card_calendar')));
    final stepsCenter = tester.getCenter(stepsCard);

    final gesture2 = await tester.startGesture(stepsCenter);
    await tester.pump(const Duration(milliseconds: 350));
    await gesture2.moveTo(calSwappedCenter);
    await tester.pump(const Duration(milliseconds: 120));
    await gesture2.up();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 320));

    final updatedOrder = await StorageService().loadToolOrder();
    expect(updatedOrder.first, 'steps');

    // Verify order persists across a fresh HomeScreen mount
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          theme: darkTheme,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    final reloadedStepsBox =
        tester.getRect(find.byKey(const ValueKey('tool_card_steps')));
    final reloadedCalBox =
        tester.getRect(find.byKey(const ValueKey('tool_card_calendar')));
    expect((reloadedStepsBox.top - reloadedCalBox.top).abs(), lessThan(1.0));
    expect(reloadedStepsBox.left, lessThan(reloadedCalBox.left));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    PedometerSensorService().dispose();
    await WeatherTelemetryService().resetFromCacheForTest();
  });
}
