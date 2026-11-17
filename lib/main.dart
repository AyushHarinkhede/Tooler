import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/stationery_theme.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'screens/home_screen.dart';
import 'screens/widget_popup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect if launched via transparent Home Screen Widget Popup Activity
  final String defaultRoute = PlatformDispatcher.instance.defaultRouteName;
  String? popupToolId;
  if (defaultRoute.startsWith('/widget_popup/')) {
    popupToolId = defaultRoute.substring('/widget_popup/'.length);
  }

  // Load theme & native sound quickly; defer heavy notification init on widget popup for instant launch
  final initialTheme = await StorageService().loadTheme();
  await SoundService().init();
  if (popupToolId == null) {
    await NotificationService().init();
  } else {
    NotificationService().init();
  }

  // Set system navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(ToolerApp(initialTheme: initialTheme, popupToolId: popupToolId));
}

class ToolerApp extends StatefulWidget {
  final StationeryTheme? initialTheme;
  final StationeryThemeMode? initialThemeMode;
  final String? popupToolId;

  const ToolerApp({
    super.key,
    this.initialTheme,
    this.initialThemeMode,
    this.popupToolId,
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
    final bool isPopup = widget.popupToolId != null && widget.popupToolId!.isNotEmpty;
    final themeData = ThemeData(
      useMaterial3: true,
      canvasColor: isPopup ? Colors.transparent : _currentTheme.bg,
      scaffoldBackgroundColor: isPopup ? Colors.transparent : _currentTheme.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _currentTheme.primary,
        surface: _currentTheme.cardBg,
        onSurface: _currentTheme.text,
        brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Tooler',
      debugShowCheckedModeBanner: false,
      color: isPopup ? Colors.transparent : null,
      theme: themeData,
      home: isPopup
          ? WidgetPopupScreen(
              initialToolId: widget.popupToolId!,
              theme: _currentTheme,
            )
          : AnimatedTheme(
              data: themeData,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              child: HomeScreen(
                theme: _currentTheme,
                onThemeChanged: _onThemeChanged,
              ),
            ),
    );
  }
}
