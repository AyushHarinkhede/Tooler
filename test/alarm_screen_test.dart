import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/screens/alarm_screen.dart';
import 'package:tooler/theme/stationery_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final darkTheme = StationeryTheme.custom(
    isDark: true,
    accent: ToolerAccent.rose,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'AlarmScreen removes duplicate inner header & long captions, places Add Alarm below clock, and opens hover pages',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AlarmScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    // Duplicate inner 'Alarm' header and fluffy captions must NOT appear
    expect(find.text('Missions, sleep cycles & wake'), findsNothing);
    expect(find.text('Interactive brain & motion wake-up challenges'),
        findsNothing);
    expect(find.textContaining('If you go to sleep now'), findsNothing);
    expect(find.text('90m REM math'), findsNothing);
    expect(find.text('One-tap alarm'), findsNothing);

    // Add Alarm button exists directly below the live clock card
    expect(find.text('Add Alarm'), findsOneWidget);

    // Compact action buttons for the 3 features exist, while inline descriptions are NOT expanded
    expect(find.text('Wake-Up Missions'), findsOneWidget);
    expect(find.text('Sleep Cycle'), findsOneWidget);
    expect(find.text('Power Naps'), findsOneWidget);
    expect(find.text('Power Boost'), findsNothing);
    expect(find.text('Recommended'), findsNothing);

    // 1. Tap Wake-Up Missions -> opens Hover Page
    await tester.tap(find.text('Wake-Up Missions'));
    await tester.pumpAndSettle();
    expect(find.text('Smooth Slide'), findsOneWidget);
    expect(find.text('Test'), findsWidgets);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    // 2. Tap Sleep Cycle -> opens Sleep Cycle Calculator Hover Page
    await tester.tap(find.text('Sleep Cycle'));
    await tester.pumpAndSettle();
    expect(find.text('Sleep Cycle Calculator'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    // 3. Tap Power Naps -> opens Quick Power Naps Hover Page
    await tester.tap(find.text('Power Naps'));
    await tester.pumpAndSettle();
    expect(find.text('Quick Power Naps'), findsOneWidget);
    expect(find.text('Power Boost'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'AlarmScreen supports Hover Add/Edit with wheel picker, multi-sounds, device audio import, delete button warning, and swipe-to-delete warning',
      (WidgetTester tester) async {
    const MethodChannel soundChannel =
        MethodChannel('com.tooler.tooler/native_sound');
    final List<MethodCall> soundCalls = [];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      soundChannel,
      (MethodCall call) async {
        soundCalls.add(call);
        if (call.method == 'pickDeviceAudio') {
          return {
            'path': '/data/user/0/com.tooler.tooler/files/custom_alarm_sounds/wake_track.mp3',
            'name': 'wake_track',
            'fileName': 'wake_track.mp3',
          };
        }
        return true;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AlarmScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Active Alarms (2)'), findsOneWidget);

    // 1. Open Add Alarm Hover Page (below clock)
    await tester.tap(find.text('Add Alarm'));
    await tester.pumpAndSettle();

    expect(find.text('New Alarm'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsNWidgets(2));
    expect(find.text('Classic Pulse'), findsWidgets);

    // Open sound selector tray & pick built-in + custom device audio
    await Scrollable.ensureVisible(
      tester.element(find.text('Classic Pulse').last),
      alignment: 0.4,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Classic Pulse').last);
    await tester.pumpAndSettle();
    expect(find.text('Crystal Chimes'), findsOneWidget);
    expect(find.text('Add Audio from Device'), findsOneWidget);

    // Import device audio
    await Scrollable.ensureVisible(
      tester.element(find.text('Add Audio from Device')),
      alignment: 0.3,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Audio from Device'));
    await tester.pumpAndSettle();

    expect(find.text('wake_track'), findsWidgets);
    expect(find.text('DEVICE'), findsOneWidget);

    // Save the new alarm
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Active Alarms (3)'), findsOneWidget);

    // 2. Tap delete button on card -> shows confirmation warning popup -> Cancel keeps it, Delete removes it
    final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteButtons, findsNWidgets(3));

    await Scrollable.ensureVisible(
      tester.element(deleteButtons.last),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();
    expect(find.text('Delete Alarm?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Active Alarms (3)'), findsOneWidget);

    // 3. Swipe card horizontally -> shows red slide Delete & confirmation warning popup -> Delete removes it
    final dismissibleFinder = find.byType(Dismissible).last;
    await tester.drag(dismissibleFinder, const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
    expect(find.text('Delete Alarm?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Active Alarms (2)'), findsOneWidget);

    // 4. Open Edit Alarm hover card -> has Delete Alarm button at bottom
    await Scrollable.ensureVisible(
      tester.element(find.text('Morning Focus')),
      alignment: 0.3,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morning Focus'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Alarm'), findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.text('Delete Alarm')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Alarm'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Alarm?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Active Alarms (1)'), findsOneWidget);

    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(soundChannel, null);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'Completed Once alarms are auto-removed while repeating daily alarms stay visible whether ON or OFF',
      (WidgetTester tester) async {
    final expiredEpoch =
        DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;

    SharedPreferences.setMockInitialValues({
      'tooler_alarms':
          '[{"id":"once_done","hour":2,"minute":0,"label":"Completed Once","isEnabled":true,"repeatDays":[],"mission":"math","mathDifficulty":1,"shakeTarget":20,"sound":true,"vibrate":true,"snoozeMinutes":5,"soundKey":"alarm","soundTitle":"Classic Pulse","targetEpochMs":$expiredEpoch},'
              '{"id":"daily_off","hour":6,"minute":30,"label":"Daily Disabled","isEnabled":false,"repeatDays":[1,2,3,4,5,6,7],"mission":"slide","mathDifficulty":1,"shakeTarget":20,"sound":true,"vibrate":true,"snoozeMinutes":5,"soundKey":"alarm_chime","soundTitle":"Crystal Chimes"}]',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlarmScreen(theme: darkTheme),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    // Expired one-time alarm auto-removed; disabled daily alarm stays intact!
    expect(find.text('Completed Once'), findsNothing);
    expect(find.text('Daily Disabled'), findsOneWidget);
    expect(find.text('Active Alarms (1)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
