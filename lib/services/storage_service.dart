import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/counter_model.dart';
import '../models/calc_history_model.dart';
import '../theme/stationery_theme.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String keyTasks = 'tooler_tasks';
  static const String keyCounters = 'tooler_counters';
  static const String keyCalcHistory = 'tooler_calc_history';
  static const String keyThemeMode = 'tooler_theme_mode';
  static const String keyIsDarkMode = 'tooler_is_dark_mode';
  static const String keyAccentColor = 'tooler_accent_color';
  static const String keySoundEnabled = 'tooler_sound_enabled';
  static const String keyHapticsEnabled = 'tooler_haptics_enabled';
  static const String keyFavorites = 'tooler_favorites_list';

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
    await prefs.setString(keyTasks, str);
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
    await prefs.setString(keyCounters, str);
  }

  Future<List<CalcHistoryItem>> loadCalcHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyCalcHistory);
    if (str == null || str.isEmpty) return [];
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
    await prefs.setString(keyCalcHistory, str);
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

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyTasks);
    await prefs.remove(keyCounters);
    await prefs.remove(keyCalcHistory);
  }
}
