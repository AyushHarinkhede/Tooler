import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER BACKGROUND & NOTIFICATION SERVICE
/// ---------------------------------------------------------------------------
/// Handles:
/// 1. High-priority Timer finished alarms (rings & alerts even in background)
/// 2. Stopwatch milestone alerts
/// 3. Task scheduled reminders with due date & time
/// 4. Global notifications enabled/disabled toggle
/// ---------------------------------------------------------------------------

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
      );

      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }
      _initialized = true;
    } catch (_) {}
  }

  Future<bool> get isEnabled async => await StorageService().loadNotificationsEnabled();

  Future<void> showTimerCompleteNotification({required String label}) async {
    if (!await isEnabled) return;
    await init();

    const androidDetails = AndroidNotificationDetails(
      'tooler_timer_channel',
      'Timer Alarms',
      channelDescription: 'Alerts when countdown timers finish',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(
        1001,
        "⏱️ Time's Up!",
        "Your $label countdown has completed.",
        details,
      );
    } catch (_) {}
  }

  Future<void> showStopwatchMilestoneNotification({required String timeStr}) async {
    if (!await isEnabled) return;
    await init();

    const androidDetails = AndroidNotificationDetails(
      'tooler_stopwatch_channel',
      'Stopwatch Alerts',
      channelDescription: 'Alerts and milestones for stopwatch',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        1002,
        "⏱️ Stopwatch Active",
        "Elapsed: $timeStr",
        details,
      );
    } catch (_) {}
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required DateTime dueDateTime,
  }) async {
    if (!await isEnabled) return;
    await init();

    if (dueDateTime.isBefore(DateTime.now())) return;

    try {
      final scheduledTz = tz.TZDateTime.from(dueDateTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'tooler_tasks_channel',
        'Task Reminders',
        channelDescription: 'Due date reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        taskId,
        "📌 Task Due: $taskTitle",
        "Due right now. Tap to view and mark complete in Tooler.",
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> cancelTaskReminder(int taskId) async {
    try {
      await _notifications.cancel(taskId);
    } catch (_) {}
  }

  Future<void> scheduleCalendarReminder({
    required int id,
    required String title,
    required String note,
    required DateTime dueDateTime,
  }) async {
    if (!await isEnabled) return;
    await init();

    if (dueDateTime.isBefore(DateTime.now())) return;

    try {
      final scheduledTz = tz.TZDateTime.from(dueDateTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'tooler_calendar_channel',
        'Calendar Reminders',
        channelDescription: 'Event and celebration alerts for Calendar',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        id,
        title,
        note.isNotEmpty ? note : "Tooler Calendar Event Reminder",
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> cancelCalendarReminder(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (_) {}
  }
}
