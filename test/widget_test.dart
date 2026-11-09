import 'package:flutter_test/flutter_test.dart';
import 'package:tooler/main.dart';
import 'package:tooler/theme/stationery_theme.dart';

void main() {
  testWidgets('Tooler app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ToolerApp(initialThemeMode: StationeryThemeMode.classicDoodle));
    expect(find.byType(ToolerApp), findsOneWidget);
  });
}
