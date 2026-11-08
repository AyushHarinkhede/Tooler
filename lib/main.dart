import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/stationery_theme.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final initialThemeMode = await StorageService().loadThemeMode();

  runApp(ToolerApp(initialThemeMode: initialThemeMode));
}

class ToolerApp extends StatefulWidget {
  final StationeryThemeMode initialThemeMode;

  const ToolerApp({super.key, required this.initialThemeMode});

  @override
  State<ToolerApp> createState() => _ToolerAppState();
}

class _ToolerAppState extends State<ToolerApp> {
  late StationeryThemeMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialThemeMode;
  }

  void _onThemeChanged(StationeryThemeMode mode) {
    setState(() {
      _currentMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationeryTheme = StationeryTheme(_currentMode);

    return MaterialApp(
      title: 'Tooler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: stationeryTheme.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: stationeryTheme.primary,
          surface: stationeryTheme.cardBg,
          onSurface: stationeryTheme.text,
        ),
      ),
      home: HomeScreen(
        theme: stationeryTheme,
        onThemeChanged: _onThemeChanged,
      ),
    );
  }
}
