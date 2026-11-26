import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/screens/settings_screen.dart';
import 'package:tooler/services/storage_service.dart';
import 'package:tooler/theme/stationery_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('New palette colors (brown, yellow, maroon, darkBlue, terracotta, olive) resolve properly', () {
    const newColors = [
      ToolerAccent.brown,
      ToolerAccent.yellow,
      ToolerAccent.maroon,
      ToolerAccent.darkBlue,
      ToolerAccent.terracotta,
      ToolerAccent.olive,
    ];

    for (final accent in newColors) {
      final light = StationeryTheme.custom(isDark: false, accent: accent);
      final dark = StationeryTheme.custom(isDark: true, accent: accent);
      expect(accent.displayName, isNotEmpty);
      expect(light.primary, isNot(equals(dark.primary)));
      expect(light.accentColorDot, equals(accent.swatchColor));
      expect(light.lavenderCard, isNot(equals(light.bg)));
      expect(light.lavenderBubble, isNot(equals(light.cardBg)));
    }
  });

  test('StorageService defaults fresh install to Material You and preserves custom selection', () async {
    final storage = StorageService();

    final freshTheme = await storage.loadTheme();
    expect(freshTheme.useMaterialYou, isTrue);
    expect(freshTheme.activeColorName, 'Material You');

    await storage.saveTheme(true, ToolerAccent.maroon, useMaterialYou: false);
    final customTheme = await storage.loadTheme();
    expect(customTheme.useMaterialYou, isFalse);
    expect(customTheme.isDark, isTrue);
    expect(customTheme.accentPalette, ToolerAccent.maroon);
    expect(customTheme.activeColorName, 'Royal Maroon');

    await storage.saveTheme(false, ToolerAccent.darkBlue, useMaterialYou: true);
    final materialYouTheme = await storage.loadTheme();
    expect(materialYouTheme.useMaterialYou, isTrue);
    expect(materialYouTheme.isDark, isFalse);
    expect(materialYouTheme.activeColorName, 'Material You');
  });

  testWidgets('Settings Color Palette removes captions/ACTIVE/Explore, toggles Material You, and slides animated color dots', (WidgetTester tester) async {
    StationeryThemeMode? latestMode;
    final initialTheme = StationeryTheme.custom(
      isDark: true,
      accent: ToolerAccent.rose,
      useMaterialYou: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          theme: initialTheme,
          onThemeChanged: (mode) {
            latestMode = mode;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Captions, ACTIVE badge, and Explore button are removed
    expect(find.text('Select accent color for buttons, badges, icons & cards'), findsNothing);
    expect(find.text('ACTIVE'), findsNothing);
    expect(find.text('Explore'), findsNothing);
    for (final accent in ToolerAccent.values) {
      expect(find.text(accent.description), findsNothing);
    }

    // Current selected color is shown cleanly
    expect(find.text('Blush Rose'), findsOneWidget);

    // Toggle Material You ON
    final switchFinder = find.byKey(const ValueKey('material_you_switch'));
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(find.text('Material You'), findsNWidgets(2));
    expect(await StorageService().loadUseMaterialYou(), isTrue);
    expect(latestMode, StationeryThemeMode.blueprintChalkboard);

    // Slide the animated color carousel horizontally to switch back to custom palette
    final sliderFinder = find.byKey(const ValueKey('color_palette_slider'));
    expect(sliderFinder, findsOneWidget);

    await tester.drag(sliderFinder, const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(await StorageService().loadUseMaterialYou(), isFalse);
    expect(find.text('Material You'), findsOneWidget); // Only the toggle row label remains
  });
}
