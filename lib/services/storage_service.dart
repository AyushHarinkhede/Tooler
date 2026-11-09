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
  static const String keySoundEnabled = 'tooler_sound_enabled';
  static const String keyHapticsEnabled = 'tooler_haptics_enabled';

  Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyTasks);
    if (str == null || str.isEmpty) {
      // Default sample tasks
      return [
        TaskItem(id: 1, text: "Finish Math Homework", category: "Homework", priority: "High"),
        TaskItem(id: 2, text: "Sharpen Pencils in Stationery Kit", category: "School", priority: "Medium"),
        TaskItem(id: 3, text: "Explore Tooler Features", category: "Personal", priority: "Low"),
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
        CounterItem(id: 2, name: "Study Pomodoros", value: 2, step: 1),
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

  Future<StationeryThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(keyThemeMode) ?? 0;
    if (index >= 0 && index < StationeryThemeMode.values.length) {
      return StationeryThemeMode.values[index];
    }
    return StationeryThemeMode.classicDoodle;
  }

  Future<void> saveThemeMode(StationeryThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyThemeMode, mode.index);
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyTasks);
    await prefs.remove(keyCounters);
    await prefs.remove(keyCalcHistory);
  }
}
