import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/screens/calculator_screen.dart';
import 'package:tooler/screens/widget_popup_screen.dart';
import 'package:tooler/services/storage_service.dart';
import 'package:tooler/theme/stationery_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = StationeryTheme.custom(
    isDark: false,
    accent: ToolerAccent.lilac,
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> tapKey(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(ValueKey<String>('calc_key_$label')));
    await tester.pump(const Duration(milliseconds: 40));
  }

  testWidgets(
      'Ongoing calculation persists across section/app close and clears only when C is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(theme: testTheme),
      ),
    );
    await tester.pumpAndSettle();

    // Enter 25+75 without pressing '='
    await tapKey(tester, '2');
    await tapKey(tester, '5');
    await tapKey(tester, '+');
    await tapKey(tester, '7');
    await tapKey(tester, '5');
    await tester.pumpAndSettle();

    expect(find.text('= 100'), findsOneWidget);

    // Close / unmount CalculatorScreen (simulates closing section, app, or RAM kill)
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    // Reopen CalculatorScreen -> ongoing expression and preview must still appear
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(theme: testTheme),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('= 100'), findsOneWidget);
    final savedMid = await StorageService().loadCalculatorState();
    expect(savedMid?['expression'], '25+75');

    // Evaluate with '=' and close immediately before animation finishes
    await tester.tap(find.byKey(const ValueKey<String>('calc_key_=')));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    // Reopen inside WidgetPopupScreen (Home Screen Widget floating calculator)
    await tester.pumpWidget(
      MaterialApp(
        home: WidgetPopupScreen(
          initialToolId: 'calc',
          theme: testTheme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('25+75 ='), findsOneWidget);
    final savedDone = await StorageService().loadCalculatorState();
    expect(savedDone?['expression'], '100');
    expect(savedDone?['lastEquation'], '25+75 =');

    // Clear explicitly via 'C' button inside WidgetPopupScreen
    await tapKey(tester, 'C');
    await tester.pumpAndSettle();

    final savedCleared = await StorageService().loadCalculatorState();
    expect(savedCleared?['expression'], '0');
    expect(savedCleared?['lastEquation'], '');

    // Reopen main CalculatorScreen -> stays cleared at 0
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(theme: testTheme),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('25+75 ='), findsNothing);
    expect(find.text('= 100'), findsNothing);
  });

  testWidgets('Programmer mode, base, and value persist across close/reopen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(theme: testTheme),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('HEX'));
    await tester.pumpAndSettle();

    await tapKey(tester, 'F');
    await tapKey(tester, 'A');
    await tester.pumpAndSettle();

    // Unmount and remount
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(theme: testTheme),
      ),
    );
    await tester.pumpAndSettle();

    final savedProg = await StorageService().loadCalculatorState();
    expect(savedProg?['calcMode'], 'programmer');
    expect(savedProg?['progBase'], 'hex');
    expect(savedProg?['expression'], 'FA');
    expect(find.text('BASE CONVERSIONS'), findsOneWidget);
  });

  testWidgets(
      'Direct clock icon is removed and holding C for 2 seconds activates live clock',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(theme: testTheme),
      ),
    );
    await tester.pumpAndSettle();

    // Direct clock button is removed, History button remains
    expect(find.byIcon(Icons.access_time_rounded), findsNothing);
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);

    // Press and hold 'C' for 2 seconds -> live clock activates
    final cFinder = find.byKey(const ValueKey<String>('calc_key_C'));
    final gesture = await tester.startGesture(tester.getCenter(cFinder));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('AM').evaluate().isEmpty && find.text('PM').evaluate().isEmpty, isTrue);

    await tester.pump(const Duration(milliseconds: 550));
    await gesture.up();
    await tester.pump();

    expect(
      find.text('AM').evaluate().isNotEmpty || find.text('PM').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
