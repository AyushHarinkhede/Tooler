import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/screens/settings_screen.dart';
import 'package:tooler/services/app_update_service.dart';
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
    AppUpdateService().resetForTest();
  });

  testWidgets(
      'SettingsScreen renders Update App right before Legal & Privacy with Update button and Warning Hover Page',
      (WidgetTester tester) async {
    bool startUpdateCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.tooler.tooler/app_updater'),
      (MethodCall call) async {
        if (call.method == 'startUpdate') {
          startUpdateCalled = true;
          return true;
        }
        if (call.method == 'canInstallUnknownPackages') {
          return true;
        }
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.tooler.tooler/app_updater'),
        null,
      );
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          theme: darkTheme,
          onThemeChanged: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    final mainScrollable = find.byType(Scrollable).first;
    final updateTitleFinder = find.text('Update App');
    await tester.scrollUntilVisible(
      updateTitleFinder,
      250,
      scrollable: mainScrollable,
    );
    await tester.pump(const Duration(milliseconds: 100));

    final legalTitleFinder = find.text('Legal & Privacy');
    await tester.scrollUntilVisible(
      legalTitleFinder,
      180,
      scrollable: mainScrollable,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(updateTitleFinder, findsOneWidget);
    expect(legalTitleFinder, findsOneWidget);
    expect(
      tester.getTopLeft(updateTitleFinder).dy,
      lessThan(tester.getTopLeft(legalTitleFinder).dy),
    );

    // Update button opens Warning Hover Page
    final updateBtnFinder = find.text('Update');
    expect(updateBtnFinder, findsOneWidget);
    await tester.ensureVisible(updateBtnFinder);
    await tester.tap(updateBtnFinder);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Update App Warning'), findsOneWidget);
    expect(find.textContaining('AyushHarinkhede/Tooler'), findsOneWidget);
    expect(find.text('Download & Update'), findsOneWidget);

    // Confirming starts GitHub APK download with progress numbers & loading animation
    await tester.tap(find.text('Download & Update'));
    await tester.pump(const Duration(milliseconds: 150));

    expect(startUpdateCalled, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);
  });
}
