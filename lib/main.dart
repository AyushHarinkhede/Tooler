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

  // True full-screen edge-to-edge display (draws seamlessly behind notch/punch-hole & nav bar)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  _applySystemUiStyle(initialTheme.isDark);

  runApp(ToolerApp(initialTheme: initialTheme, popupToolId: popupToolId));
}

void _applySystemUiStyle(bool isDark) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
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

class _ToolerAppState extends State<ToolerApp> with WidgetsBindingObserver {
  late StationeryTheme _currentTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentTheme = widget.initialTheme ??
        StationeryTheme(widget.initialThemeMode ?? StationeryThemeMode.classicDoodle);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentTheme.useMaterialYou) {
      _refreshSystemMaterialYou();
    }
  }

  Future<void> _refreshSystemMaterialYou() async {
    final refreshed = await StorageService().loadTheme();
    if (!mounted) return;
    if (refreshed.primary.toARGB32() != _currentTheme.primary.toARGB32() ||
        refreshed.bg.toARGB32() != _currentTheme.bg.toARGB32() ||
        refreshed.useMaterialYou != _currentTheme.useMaterialYou) {
      _applySystemUiStyle(refreshed.isDark);
      setState(() {
        _currentTheme = refreshed;
      });
    }
  }

  void _onThemeChanged(StationeryThemeMode mode) async {
    final theme = await StorageService().loadTheme();
    if (!mounted) return;
    _applySystemUiStyle(theme.isDark);
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPopup = widget.popupToolId != null && widget.popupToolId!.isNotEmpty;
    final bool isDark = _currentTheme.isDark;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );

    final themeData = ThemeData(
      useMaterial3: true,
      canvasColor: isPopup ? Colors.transparent : _currentTheme.bg,
      scaffoldBackgroundColor: isPopup ? Colors.transparent : _currentTheme.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _currentTheme.primary,
        surface: _currentTheme.cardBg,
        onSurface: _currentTheme.text,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp(
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
      ),
    );
  }
}
