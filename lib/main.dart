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

  final initialTheme = await StorageService().loadTheme();

  runApp(ToolerApp(initialTheme: initialTheme));
}

class ToolerApp extends StatefulWidget {
  final StationeryTheme? initialTheme;
  final StationeryThemeMode? initialThemeMode;

  const ToolerApp({
    super.key,
    this.initialTheme,
    this.initialThemeMode,
  });

  @override
  State<ToolerApp> createState() => _ToolerAppState();
}

class _ToolerAppState extends State<ToolerApp> {
  late StationeryTheme _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme ??
        StationeryTheme(widget.initialThemeMode ?? StationeryThemeMode.classicDoodle);
  }

  void _onThemeChanged(StationeryThemeMode mode) async {
    final theme = await StorageService().loadTheme();
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tooler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _currentTheme.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _currentTheme.primary,
          surface: _currentTheme.cardBg,
          onSurface: _currentTheme.text,
          brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      home: HomeScreen(
        theme: _currentTheme,
        onThemeChanged: _onThemeChanged,
      ),
    );
  }
}
