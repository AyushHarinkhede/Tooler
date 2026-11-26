import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/stationery_theme.dart';

class WidgetSystemColors {
  final Color cardBg;
  final Color bubbleBg;
  final Color primary;
  final Color ink;
  final Color border;
  final bool isDark;

  const WidgetSystemColors({
    required this.cardBg,
    required this.bubbleBg,
    required this.primary,
    required this.ink,
    required this.border,
    required this.isDark,
  });
}

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  static const MethodChannel _channel = MethodChannel('com.tooler.tooler/widgets');

  static const String _keyColorMode = 'tooler_widget_color_mode'; // 'app' or 'system'
  static const String _keyFavToolId = 'tooler_widget_fav_tool_id';
  static const String _keySelectedRatio = 'tooler_widget_selected_ratio'; // '4x1', '2x2', or '1x1'
  static const String _keyCounterId = 'tooler_widget_counter_id';
  static const String _keyCounterName = 'tooler_widget_counter_name';
  static const String _keyCounterValue = 'tooler_widget_counter_value';
  static const String _keyCounterStep = 'tooler_widget_counter_step';

  String _colorMode = 'app';
  String _favToolId = 'calc';
  String _selectedRatio = '4x1';
  int? _counterId;
  String _counterName = 'Tally Counter';
  int _counterValue = 0;
  int _counterStep = 1;

  String get colorMode => _colorMode;
  String get favToolId => _favToolId;
  String get selectedRatio => _selectedRatio;
  int? get counterId => _counterId;
  String get counterName => _counterName;
  int get counterValue => _counterValue;
  int get counterStep => _counterStep;

  void Function(String toolId)? _onLaunchCallback;

  Future<void> init({
    required StationeryTheme theme,
    void Function(String toolId)? onWidgetLaunch,
  }) async {
    _onLaunchCallback = onWidgetLaunch;
    await loadPrefs();

    if (!kIsWeb && Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onWidgetLaunch') {
          final String? toolId = call.arguments as String?;
          if (toolId != null && toolId.isNotEmpty) {
            _onLaunchCallback?.call(toolId);
          }
        }
      });

      // Push current theme & saved widget preferences to Android immediately
      await syncToNative(theme);

      // Check if app was cold-started by tapping a home screen widget
      try {
        final String? initialTool =
            await _channel.invokeMethod<String>('getInitialWidgetTool');
        if (initialTool != null && initialTool.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 220), () {
            _onLaunchCallback?.call(initialTool);
          });
        }
      } catch (e) {
        debugPrint('WidgetService getInitialWidgetTool error: $e');
      }
    }
  }

  Future<void> loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _colorMode = prefs.getString(_keyColorMode) ?? 'app';
      _favToolId = prefs.getString(_keyFavToolId) ?? 'calc';
      _selectedRatio = prefs.getString(_keySelectedRatio) ?? '4x1';
      _counterId = prefs.getInt(_keyCounterId);
      _counterName = prefs.getString(_keyCounterName) ?? 'Tally Counter';
      _counterValue = prefs.getInt(_keyCounterValue) ?? 0;
      _counterStep = prefs.getInt(_keyCounterStep) ?? 1;
    } catch (_) {}
  }

  Future<void> syncCounterToNative({
    required int id,
    required String name,
    required int value,
    required int step,
    required StationeryTheme theme,
  }) async {
    _counterId = id;
    _counterName = name;
    _counterValue = value;
    _counterStep = step;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCounterId, id);
      await prefs.setString(_keyCounterName, name);
      await prefs.setInt(_keyCounterValue, value);
      await prefs.setInt(_keyCounterStep, step);
    } catch (_) {}

    await syncToNative(theme);
  }

  Future<void> saveConfig({
    required StationeryTheme theme,
    String? colorMode,
    String? favToolId,
    String? selectedRatio,
  }) async {
    if (colorMode != null) _colorMode = colorMode;
    if (favToolId != null) _favToolId = favToolId;
    if (selectedRatio != null) _selectedRatio = selectedRatio;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyColorMode, _colorMode);
      await prefs.setString(_keyFavToolId, _favToolId);
      await prefs.setString(_keySelectedRatio, _selectedRatio);
    } catch (_) {}

    await syncToNative(theme);
  }

  Future<void> syncToNative(StationeryTheme theme) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('saveAndRefreshWidgets', {
        'colorMode': _colorMode,
        'favToolId': _favToolId,
        'counterId': _counterId ?? 0,
        'counterName': _counterName,
        'counterValue': _counterValue,
        'counterStep': _counterStep,
        'appCardBg': theme.cardBg.toARGB32(),
        'appBubble': theme.lavenderBubble.toARGB32(),
        'appPrimary': theme.primary.toARGB32(),
        'appText': theme.text.toARGB32(),
        'appBorder': theme.border.toARGB32(),
        'appIsDark': theme.isDark,
      });
    } catch (e) {
      debugPrint('WidgetService syncToNative error: $e');
    }
  }

  Future<void> syncStepsToNative() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('refreshStepWidget');
    } catch (_) {}
  }

  Future<void> syncTasksToNative() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('refreshTasksWidget');
    } catch (_) {}
  }

  Future<void> syncCountersToNative() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('refreshCounterWidget');
    } catch (_) {}
  }

  Future<bool> pinWidgetToHomeScreen(String ratio, StationeryTheme theme) async {
    await syncToNative(theme);
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>('pinWidget', {
        'ratio': ratio,
      });
      return ok ?? false;
    } catch (e) {
      debugPrint('WidgetService pinWidget error: $e');
      return false;
    }
  }

  Future<MaterialYouPalette> getMaterialYouPalette({required bool isDark}) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final dynamic raw = await _channel.invokeMethod('getMaterialYouTheme', {
          'isDark': isDark,
        });
        if (raw is Map) {
          return MaterialYouPalette(
            bg: Color((raw['bg'] as num).toInt()),
            cardBg: Color((raw['cardBg'] as num).toInt()),
            border: Color((raw['border'] as num).toInt()),
            text: Color((raw['text'] as num).toInt()),
            textSecondary: Color((raw['textSecondary'] as num).toInt()),
            primary: Color((raw['primary'] as num).toInt()),
            primaryDark: Color((raw['primaryDark'] as num).toInt()),
            secondary: Color((raw['secondary'] as num).toInt()),
            accent: Color((raw['accent'] as num).toInt()),
            swatch: Color((raw['swatch'] as num).toInt()),
            lavenderCard: Color((raw['lavenderCard'] as num).toInt()),
            lavenderBubble: Color((raw['lavenderBubble'] as num).toInt()),
            characterBg: Color((raw['characterBg'] as num).toInt()),
            isNativeSupported: raw['isNativeSupported'] == true,
          );
        }
      } catch (_) {}
    }
    return MaterialYouPalette.fallback(isDark: isDark);
  }

  Future<WidgetSystemColors> getSystemColors(StationeryTheme fallback) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final dynamic raw = await _channel.invokeMethod('getSystemWidgetColors');
        if (raw is Map) {
          return WidgetSystemColors(
            cardBg: Color((raw['cardBg'] as num).toInt()),
            bubbleBg: Color((raw['bubbleBg'] as num).toInt()),
            primary: Color((raw['primary'] as num).toInt()),
            ink: Color((raw['ink'] as num).toInt()),
            border: Color((raw['border'] as num).toInt()),
            isDark: raw['isDark'] == true,
          );
        }
      } catch (_) {}
    }
    return WidgetSystemColors(
      cardBg: fallback.isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFBFE),
      bubbleBg: fallback.isDark ? const Color(0xFF2E2C36) : const Color(0xFFEDE7F6),
      primary: fallback.isDark ? const Color(0xFFD0BCFF) : const Color(0xFF6750A4),
      ink: fallback.isDark ? const Color(0xFFF4EFF4) : const Color(0xFF1C1B1F),
      border: fallback.isDark ? const Color(0xFF3B3845) : const Color(0xFFE3DCE8),
      isDark: fallback.isDark,
    );
  }
}
