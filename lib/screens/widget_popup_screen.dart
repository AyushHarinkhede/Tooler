import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/stationery_theme.dart';
import '../widgets_3d/tooler_hover_sheet.dart';
import 'calculator_screen.dart';
import 'age_calculator_screen.dart';
import 'converters_screen.dart';
import 'stopwatch_screen.dart';
import 'timer_screen.dart';
import 'alarm_screen.dart';
import 'sizer_screen.dart';
import 'counters_screen.dart';
import 'tasks_screen.dart';
import 'calendar_screen.dart';
import 'currency_screen.dart';
import 'games_screen.dart';
import 'browser_screen.dart';
import 'compass_screen.dart';
import 'password_generator_screen.dart';
import 'sound_recorder_screen.dart';
import 'character_illustrations_screen.dart';
import 'power_screen.dart';
import 'security_screen.dart';
import 'fm_radio_screen.dart';
import 'weather_screen.dart';
import 'step_counter_screen.dart';
import 'speed_test_screen.dart';

/// Direct Transparent Home Screen Floating Hover Page launched by Android Widgets.
/// Floats directly on top of the user's phone Home Screen / Wallpaper without
/// opening or flashing Tooler's main app behind it.
class WidgetPopupScreen extends StatefulWidget {
  final String initialToolId;
  final StationeryTheme theme;

  const WidgetPopupScreen({
    super.key,
    required this.initialToolId,
    required this.theme,
  });

  @override
  State<WidgetPopupScreen> createState() => _WidgetPopupScreenState();
}

class _WidgetPopupScreenState extends State<WidgetPopupScreen>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _widgetChannel =
      MethodChannel('com.tooler.tooler/widgets');

  late String _activeToolId;
  late AnimationController _entryController;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _activeToolId = widget.initialToolId;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _entryController.forward();

    if (!kIsWeb && Platform.isAndroid) {
      _widgetChannel.setMethodCallHandler((call) async {
        if (call.method == 'onPopupToolChange') {
          final String? newTool = call.arguments as String?;
          if (newTool != null && newTool.isNotEmpty && mounted) {
            setState(() => _activeToolId = newTool);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _closePopup() async {
    if (_isClosing) return;
    _isClosing = true;
    try {
      await _entryController.reverse();
    } catch (_) {}
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _widgetChannel.invokeMethod('closePopup');
        return;
      } catch (_) {}
    }
    SystemNavigator.pop();
  }

  _PopupToolMeta _resolveTool(String toolId) {
    final t = widget.theme;
    switch (toolId) {
      case 'calc':
        return _PopupToolMeta(
          title: 'Calculator',
          subtitle: 'Basic, Scientific & Programmer Modes',
          tag: 'Precision',
          child: CalculatorScreen(theme: t),
        );
      case 'calendar':
        return _PopupToolMeta(
          title: 'Calendar',
          subtitle: 'Festivals, Holidays & Personal Notes',
          tag: 'Schedule',
          child: CalendarScreen(theme: t),
        );
      case 'games':
        return _PopupToolMeta(
          title: 'Games',
          subtitle: 'Classic Arcade & Mind Puzzles',
          tag: 'Arcade',
          child: GamesScreen(theme: t),
        );
      case 'recorder':
        return _PopupToolMeta(
          title: 'Noise Meter & Recorder',
          subtitle: 'Decibel Meter, Voice Recorder & Monitor',
          tag: 'Audio',
          child: SoundRecorderScreen(theme: t),
        );
      case 'speed_test':
        return _PopupToolMeta(
          title: 'Speed Test',
          subtitle: 'Wi-Fi, 5G Radio & Nearest Tower',
          tag: 'Network',
          child: SpeedTestScreen(theme: t),
        );
      case 'power':
        return _PopupToolMeta(
          title: 'Power',
          subtitle: 'Battery Telemetry & Charging Analytics',
          tag: 'Hardware',
          child: PowerScreen(theme: t),
        );
      case 'compass':
        return _PopupToolMeta(
          title: 'Compass',
          subtitle: 'Real-time Gyro, Heading & Spirit Level',
          tag: 'Live Sensor',
          child: CompassScreen(theme: t),
        );
      case 'converters':
        return _PopupToolMeta(
          title: 'Unit Converters',
          subtitle: 'Length, Mass, Speed, Data, Temp, Area, Vol',
          tag: 'Multi-unit',
          child: ConvertersScreen(theme: t),
        );
      case 'currency':
        return _PopupToolMeta(
          title: 'Currency Converter',
          subtitle: 'Live Exchange Rates & Quick Math',
          tag: 'Finance',
          child: CurrencyScreen(theme: t),
        );
      case 'tasks_add':
        return _PopupToolMeta(
          title: 'New Task & Note',
          subtitle: 'Create Quick Checklist or Note',
          tag: 'Organize',
          child: TasksScreen(theme: t, autoOpenComposer: true),
        );
      case 'tasks':
        return _PopupToolMeta(
          title: 'Tasks & Notes',
          subtitle: 'Quick Checklists & Study Notes',
          tag: 'Organize',
          child: TasksScreen(theme: t),
        );
      case 'alarm':
        return _PopupToolMeta(
          title: 'Alarm',
          subtitle: 'Reliable Wake-up & Custom Tones',
          tag: 'Alerts',
          child: AlarmScreen(theme: t),
        );
      case 'stopwatch':
        return _PopupToolMeta(
          title: 'Stopwatch',
          subtitle: 'Millisecond Lap Timer',
          tag: 'Timing',
          child: StopwatchScreen(theme: t),
        );
      case 'timer':
        return _PopupToolMeta(
          title: 'Timer',
          subtitle: 'Countdown Presets & Background Alerts',
          tag: 'Focus',
          child: TimerScreen(theme: t),
        );
      case 'sizer':
        return _PopupToolMeta(
          title: 'Sizer & Caliper',
          subtitle: 'On-Screen Ruler & Vernier Caliper',
          tag: 'Measure',
          child: SizerScreen(theme: t),
        );
      case 'counters':
        return _PopupToolMeta(
          title: 'Tally Counters',
          subtitle: 'Multi-Counter Tracker',
          tag: 'Count',
          child: CountersScreen(theme: t),
        );
      case 'steps':
        return _PopupToolMeta(
          title: 'Step Counter',
          subtitle: 'Hardware Pedometer, Distance & Speed',
          tag: 'Fitness',
          child: StepCounterScreen(theme: t),
        );
      case 'age':
        return _PopupToolMeta(
          title: 'Age Calculator',
          subtitle: 'Live Age Clock & Eligibility',
          tag: 'Date Math',
          child: AgeCalculatorScreen(theme: t),
        );
      case 'password':
        return _PopupToolMeta(
          title: 'Password Generator',
          subtitle: 'Cryptographic Key Generator',
          tag: 'Vault',
          child: PasswordGeneratorScreen(theme: t),
        );
      case 'security':
        return _PopupToolMeta(
          title: 'Security',
          subtitle: 'System Audit & App Scanner',
          tag: 'Shield',
          child: SecurityScreen(theme: t),
        );
      case 'browser':
        return _PopupToolMeta(
          title: 'Browser',
          subtitle: 'Lightweight Fast Web Browser',
          tag: 'Web',
          child: BrowserScreen(theme: t),
        );
      case 'radio':
        return _PopupToolMeta(
          title: 'FM Radio',
          subtitle: 'Retro FM Tuner & Global 3D Radio',
          tag: 'Tuner',
          child: FmRadioScreen(theme: t),
        );
      case 'illustrations':
        return _PopupToolMeta(
          title: 'Character Studio',
          subtitle: '2D Vector Studio Gallery',
          tag: 'Art',
          child: CharacterIllustrationsScreen(theme: t),
        );
      case 'weather':
      case 'mausam':
        return _PopupToolMeta(
          title: 'Weather',
          subtitle: 'Live Weather, 14-Day Trend & AQI Mascot',
          tag: 'Weather',
          child: WeatherScreen(theme: t),
        );
      default:
        return _PopupToolMeta(
          title: 'Calculator',
          subtitle: 'Basic, Scientific & Programmer Modes',
          tag: 'Precision',
          child: CalculatorScreen(theme: t),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _resolveTool(_activeToolId);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _closePopup();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: ToolerHoverSheet(
          key: ValueKey<String>(_activeToolId),
          title: meta.title,
          subtitle: meta.subtitle,
          tag: meta.tag,
          theme: widget.theme,
          isDirectHomeOverlay: true,
          sheetAnimation: _entryController,
          onClose: _closePopup,
          child: meta.child,
        ),
      ),
    );
  }
}

class _PopupToolMeta {
  final String title;
  final String subtitle;
  final String tag;
  final Widget child;

  const _PopupToolMeta({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.child,
  });
}
