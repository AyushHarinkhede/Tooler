import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tooler/theme/stationery_theme.dart';
import 'package:tooler/widgets_3d/tooler_hover_sheet.dart';

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

  testWidgets(
      'ToolerHoverSheet removes fullscreen & favorite buttons, centers title, and supports dock slide to fullscreen',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    bool scopedFullScreen = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ToolerHoverSheet(
          title: 'Step Counter',
          subtitle: 'Steps & Fitness',
          tag: 'Fitness',
          theme: darkTheme,
          child: Builder(
            builder: (ctx) {
              scopedFullScreen = ToolerHoverSheet.isFullScreen(ctx);
              return const Center(child: Text('Body Content'));
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    // Only Back button + centered Title remain; dedicated fullscreen & favorite buttons are gone
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.open_in_full_rounded), findsNothing);
    expect(find.byIcon(Icons.close_fullscreen_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_outline_rounded), findsNothing);

    final titleFinder = find.text('Step Counter');
    expect(titleFinder, findsOneWidget);
    final titleCenterX = tester.getCenter(titleFinder).dx;
    expect((titleCenterX - 195.0).abs(), lessThan(2.0));
    expect(scopedFullScreen, isFalse);

    // Slide the top dock upward to enter fullscreen
    final dockFinder = find.byKey(const ValueKey('hover_sheet_dock'));
    expect(dockFinder, findsOneWidget);
    await tester.fling(dockFinder, const Offset(0, -100), 600);
    await tester.pumpAndSettle();
    expect(scopedFullScreen, isTrue);

    // Slide the dock downward to return to hover mode
    await tester.fling(dockFinder, const Offset(0, 100), 600);
    await tester.pumpAndSettle();
    expect(scopedFullScreen, isFalse);
  });
}
