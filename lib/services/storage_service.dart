import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/counter_model.dart';
import '../models/calc_history_model.dart';
import '../models/calendar_event_model.dart';
import '../theme/stationery_theme.dart';
import 'security_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String keyTasks = 'tooler_tasks';
  static const String keyTasksChecksum = 'tooler_tasks_checksum';
  static const String keyCalendarEvents = 'tooler_calendar_events';
  static const String keyCalendarEventsChecksum = 'tooler_calendar_events_checksum';
  static const String keyCalendarIntlNotifications = 'tooler_calendar_intl_notifications';
  static const String keyCounters = 'tooler_counters';
  static const String keyCountersChecksum = 'tooler_counters_checksum';
  static const String keyCalcHistory = 'tooler_calc_history';
  static const String keyCalcHistoryChecksum = 'tooler_calc_history_checksum';
  static const String keyThemeMode = 'tooler_theme_mode';
  static const String keyIsDarkMode = 'tooler_is_dark_mode';
  static const String keyAccentColor = 'tooler_accent_color';
  static const String keySoundEnabled = 'tooler_sound_enabled';
  static const String keyHapticsEnabled = 'tooler_haptics_enabled';
  static const String keyFavorites = 'tooler_favorites_list';
  static const String keyNotificationsEnabled = 'tooler_notifications_enabled';
  static const String keyTamperProtection = 'tooler_tamper_protection_enabled';

  // Background Timer State
  static const String keyTimerRunning = 'tooler_timer_running';
  static const String keyTimerTargetEpoch = 'tooler_timer_target_epoch';
  static const String keyTimerInitialSecs = 'tooler_timer_initial_secs';

  // Background Stopwatch State
  static const String keyStopwatchRunning = 'tooler_stopwatch_running';
  static const String keyStopwatchStartEpoch = 'tooler_stopwatch_start_epoch';
  static const String keyStopwatchElapsedMs = 'tooler_stopwatch_elapsed_ms';
  static const String keyStopwatchLaps = 'tooler_stopwatch_laps';

  Future<bool> loadTamperProtection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyTamperProtection) ?? true;
  }

  Future<void> saveTamperProtection(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyTamperProtection, enabled);
    SecurityService().tamperProtectionEnabled = enabled;
  }

  Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyTasks);
    if (str == null || str.isEmpty) {
      return [
        TaskItem(id: 1, text: "Finish Math calculation report", category: "Work", priority: "High"),
        TaskItem(id: 2, text: "Organize unit conversion references", category: "Focus", priority: "Medium"),
        TaskItem(id: 3, text: "Explore Tooler features", category: "Personal", priority: "Low"),
      ];
    }
    // Verify cryptographic integrity
    final checksum = prefs.getString(keyTasksChecksum);
    if (!SecurityService().verifyIntegrity(content: str, storedChecksum: checksum)) {
      return [];
    }
    try {
      final List decoded = jsonDecode(str);
      return decoded.map((e) => TaskItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final str = jsonEncode(tasks.map((e) => e.toJson()).toList());
    final checksum = SecurityService().generateIntegrityChecksum(str);
    await prefs.setString(keyTasks, str);
    await prefs.setString(keyTasksChecksum, checksum);
  }

  Future<bool> loadCalendarIntlNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyCalendarIntlNotifications) ?? true;
  }

  Future<void> saveCalendarIntlNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyCalendarIntlNotifications, enabled);
  }

  Future<List<CalendarEventModel>> loadCalendarEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyCalendarEvents);
    if (str == null || str.isEmpty) {
      return [];
    }
    final checksum = prefs.getString(keyCalendarEventsChecksum);
    if (!SecurityService().verifyIntegrity(content: str, storedChecksum: checksum)) {
      return [];
    }
    try {
      final List decoded = jsonDecode(str);
      return decoded.map((e) => CalendarEventModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCalendarEvents(List<CalendarEventModel> events) async {
    final prefs = await SharedPreferences.getInstance();
    final str = jsonEncode(events.map((e) => e.toJson()).toList());
    final checksum = SecurityService().generateIntegrityChecksum(str);
    await prefs.setString(keyCalendarEvents, str);
    await prefs.setString(keyCalendarEventsChecksum, checksum);
  }

  Future<List<CounterItem>> loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyCounters);
    if (str == null || str.isEmpty) {
      return [
        CounterItem(id: 1, name: "Water Glasses", value: 4, step: 1),
        CounterItem(id: 2, name: "Productivity Sprints", value: 3, step: 1),
      ];
    }
    // Verify cryptographic integrity
    final checksum = prefs.getString(keyCountersChecksum);
    if (!SecurityService().verifyIntegrity(content: str, storedChecksum: checksum)) {
      return [];
    }
    try {
      final List decoded = jsonDecode(str);
      return decoded.map((e) => CounterItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCounters(List<CounterItem> counters) async {
    final prefs = await SharedPreferences.getInstance();
    final str = jsonEncode(counters.map((e) => e.toJson()).toList());
    final checksum = SecurityService().generateIntegrityChecksum(str);
    await prefs.setString(keyCounters, str);
    await prefs.setString(keyCountersChecksum, checksum);
  }

  Future<List<CalcHistoryItem>> loadCalcHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyCalcHistory);
    if (str == null || str.isEmpty) return [];
    final checksum = prefs.getString(keyCalcHistoryChecksum);
    if (!SecurityService().verifyIntegrity(content: str, storedChecksum: checksum)) {
      return [];
    }
    try {
      final List decoded = jsonDecode(str);
      return decoded.map((e) => CalcHistoryItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCalcHistory(List<CalcHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final str = jsonEncode(history.map((e) => e.toJson()).toList());
    final checksum = SecurityService().generateIntegrityChecksum(str);
    await prefs.setString(keyCalcHistory, str);
    await prefs.setString(keyCalcHistoryChecksum, checksum);
  }

  Future<StationeryTheme> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(keyIsDarkMode) ?? false;
    final accentName = prefs.getString(keyAccentColor) ?? 'lilac';
    ToolerAccent accent = ToolerAccent.lilac;
    for (final a in ToolerAccent.values) {
      if (a.name == accentName) {
        accent = a;
        break;
      }
    }
    return StationeryTheme.custom(isDark: isDark, accent: accent);
  }

  Future<void> saveTheme(bool isDark, ToolerAccent accent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsDarkMode, isDark);
    await prefs.setString(keyAccentColor, accent.name);
  }

  Future<StationeryThemeMode> loadThemeMode() async {
    final theme = await loadTheme();
    return theme.mode;
  }

  Future<void> saveThemeMode(StationeryThemeMode mode) async {
    final isDark = mode == StationeryThemeMode.blueprintChalkboard;
    final accent = mode == StationeryThemeMode.neonHighlighter ? ToolerAccent.rose : ToolerAccent.lilac;
    await saveTheme(isDark, accent);
  }

  Future<bool> isToolFavorite(String toolTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(keyFavorites) ?? [];
    return list.contains(toolTitle);
  }

  Future<bool> toggleToolFavorite(String toolTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(keyFavorites) ?? [];
    final bool isFav = list.contains(toolTitle);
    if (isFav) {
      list.remove(toolTitle);
    } else {
      list.add(toolTitle);
    }
    await prefs.setStringList(keyFavorites, list);
    return !isFav;
  }

  Future<bool> loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyNotificationsEnabled) ?? true;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyNotificationsEnabled, enabled);
  }

  // --- Background Timer Persistence ---
  Future<void> saveTimerState({
    required bool isRunning,
    required int targetEpochMs,
    required int initialSeconds,
    int remainingSeconds = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyTimerRunning, isRunning);
    await prefs.setInt(keyTimerTargetEpoch, targetEpochMs);
    await prefs.setInt(keyTimerInitialSecs, initialSeconds);
    await prefs.setInt('timer_remaining_secs', remainingSeconds);
  }

  Future<Map<String, dynamic>> loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isRunning': prefs.getBool(keyTimerRunning) ?? false,
      'targetEpochMs': prefs.getInt(keyTimerTargetEpoch) ?? 0,
      'initialSeconds': prefs.getInt(keyTimerInitialSecs) ?? 300,
      'remainingSeconds': prefs.getInt('timer_remaining_secs') ?? 0,
    };
  }

  Future<void> clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyTimerRunning);
    await prefs.remove(keyTimerTargetEpoch);
    await prefs.remove('timer_remaining_secs');
  }

  // --- Background Stopwatch Persistence ---
  Future<void> saveStopwatchState({
    required bool isRunning,
    required int startEpochMs,
    required int elapsedMs,
    List<String> laps = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyStopwatchRunning, isRunning);
    await prefs.setInt(keyStopwatchStartEpoch, startEpochMs);
    await prefs.setInt(keyStopwatchElapsedMs, elapsedMs);
    await prefs.setStringList(keyStopwatchLaps, laps);
  }

  Future<Map<String, dynamic>> loadStopwatchState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isRunning': prefs.getBool(keyStopwatchRunning) ?? false,
      'startEpochMs': prefs.getInt(keyStopwatchStartEpoch) ?? 0,
      'elapsedMs': prefs.getInt(keyStopwatchElapsedMs) ?? 0,
      'laps': prefs.getStringList(keyStopwatchLaps) ?? <String>[],
    };
  }

  Future<void> clearStopwatchState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyStopwatchRunning);
    await prefs.remove(keyStopwatchStartEpoch);
    await prefs.remove(keyStopwatchElapsedMs);
    await prefs.remove(keyStopwatchLaps);
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyTasks);
    await prefs.remove(keyCounters);
    await prefs.remove(keyCalcHistory);
    await clearTimerState();
    await clearStopwatchState();
  }
}
