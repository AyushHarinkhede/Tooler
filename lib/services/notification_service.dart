import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';

/// ---------------------------------------------------------------------------
/// TOOLER REAL-TIME BACKGROUND & NOTIFICATION SERVICE
/// ---------------------------------------------------------------------------
/// Handles:
/// 1. Real-time Exact Timer Alarms (Scheduled in AlarmManager, fires even when app is killed)
/// 2. Active Stopwatch Background Notifications & Milestone Alerts
/// 3. Scheduled Real-time Task Reminders with Due Date & Time
/// 4. Calendar Observance & Custom Event Notifications
/// 5. Android 12/13/14 Exact Alarm Permissions & Notification Channels
/// ---------------------------------------------------------------------------

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int timerNotificationId = 1001;
  static const int stopwatchNotificationId = 1002;

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

      final androidImpl = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        // Request notification permission (Android 13+)
        await androidImpl.requestNotificationsPermission();

        // Request exact alarms permission (Android 12+) for real-time background delivery
        try {
          await androidImpl.requestExactAlarmsPermission();
        } catch (_) {}

        // Explicitly create high-importance notification channels
        final vibrationPattern = Int64List.fromList([0, 500, 250, 500]);

        final timerChannel = AndroidNotificationChannel(
          'tooler_timer_channel',
          'Timer Alarms',
          description: 'High-priority alerts when countdown timers finish',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        final taskChannel = AndroidNotificationChannel(
          'tooler_tasks_channel',
          'Task Reminders',
          description: 'Exact due date reminders for your scheduled tasks',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
        );

        const calendarChannel = AndroidNotificationChannel(
          'tooler_calendar_channel',
          'Calendar Reminders',
          description: 'Event and celebration alerts for Calendar',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        const stopwatchChannel = AndroidNotificationChannel(
          'tooler_stopwatch_channel',
          'Stopwatch Alerts',
          description: 'Background status and milestone alerts for stopwatch',
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
        );

        await androidImpl.createNotificationChannel(timerChannel);
        await androidImpl.createNotificationChannel(taskChannel);
        await androidImpl.createNotificationChannel(calendarChannel);
        await androidImpl.createNotificationChannel(stopwatchChannel);
      }
      _initialized = true;
    } catch (_) {}
  }

  Future<bool> get isEnabled async => await StorageService().loadNotificationsEnabled();

  // =========================================================================
  // 1. TIMER NOTIFICATIONS (Real-time Exact Background Alarms)
  // =========================================================================

  /// Schedules an exact OS Alarm for the timer completion timestamp.
  /// Even if the user kills Tooler or locks their phone, AlarmManager will
  /// ring and show this notification at the exact second it finishes.
  Future<void> scheduleTimerNotification({
    required int secondsRemaining,
    required String label,
    required DateTime completionTime,
  }) async {
    if (!await isEnabled) return;
    await init();

    if (completionTime.isBefore(DateTime.now())) return;

    try {
      final scheduledTz = tz.TZDateTime.from(completionTime.toUtc(), tz.UTC);

      const androidDetails = AndroidNotificationDetails(
        'tooler_timer_channel',
        'Timer Alarms',
        channelDescription: 'High-priority alerts when countdown timers finish',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      try {
        await _notifications.zonedSchedule(
          timerNotificationId,
          "⏱️ Time's Up!",
          "Your $label countdown timer has completed.",
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Fallback to inexact if system rejects exact schedule mode
        await _notifications.zonedSchedule(
          timerNotificationId,
          "⏱️ Time's Up!",
          "Your $label countdown timer has completed.",
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }

  /// Cancels any pending scheduled timer background alarms (e.g. on pause or reset)
  Future<void> cancelTimerNotification() async {
    try {
      await _notifications.cancel(timerNotificationId);
    } catch (_) {}
  }

  /// Shows immediate completed notification when finished in foreground
  Future<void> showTimerCompleteNotification({required String label}) async {
    if (!await isEnabled) return;
    await init();

    const androidDetails = AndroidNotificationDetails(
      'tooler_timer_channel',
      'Timer Alarms',
      channelDescription: 'Alerts when countdown timers finish',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(
        timerNotificationId,
        "⏱️ Time's Up!",
        "Your $label countdown has completed.",
        details,
      );
    } catch (_) {}
  }

  // =========================================================================
  // 2. STOPWATCH NOTIFICATIONS (Background Tracking & Milestones)
  // =========================================================================

  Future<void> showStopwatchActiveNotification({
    required String timeStr,
    bool ongoing = false,
  }) async {
    if (!await isEnabled) return;
    await init();

    final androidDetails = AndroidNotificationDetails(
      'tooler_stopwatch_channel',
      'Stopwatch Alerts',
      channelDescription: 'Alerts and milestones for stopwatch',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: ongoing,
      autoCancel: !ongoing,
      category: AndroidNotificationCategory.status,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      ),
    );

    try {
      await _notifications.show(
        stopwatchNotificationId,
        "⏱️ Stopwatch Active in Background",
        "Elapsed: $timeStr • Tap to return to Tooler",
        details,
      );
    } catch (_) {}
  }

  Future<void> showStopwatchMilestoneNotification({required String timeStr}) async {
    await showStopwatchActiveNotification(timeStr: timeStr, ongoing: false);
  }

  Future<void> cancelStopwatchNotification() async {
    try {
      await _notifications.cancel(stopwatchNotificationId);
    } catch (_) {}
  }

  // =========================================================================
  // 3. TASK DUE REMINDERS (Real-time Exact Notification)
  // =========================================================================

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required DateTime dueDateTime,
  }) async {
    if (!await isEnabled) return;
    await init();

    if (dueDateTime.isBefore(DateTime.now())) return;

    try {
      final scheduledTz = tz.TZDateTime.from(dueDateTime.toUtc(), tz.UTC);

      const androidDetails = AndroidNotificationDetails(
        'tooler_tasks_channel',
        'Task Reminders',
        channelDescription: 'Exact due date reminders for your scheduled tasks',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      try {
        await _notifications.zonedSchedule(
          taskId,
          "📌 Task Due: $taskTitle",
          "Due right now. Tap to view and mark complete in Tooler.",
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        await _notifications.zonedSchedule(
          taskId,
          "📌 Task Due: $taskTitle",
          "Due right now. Tap to view and mark complete in Tooler.",
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }

  Future<void> cancelTaskReminder(int taskId) async {
    try {
      await _notifications.cancel(taskId);
    } catch (_) {}
  }

  // =========================================================================
  // 4. CALENDAR NOTIFICATIONS (Real-time Exact Notification)
  // =========================================================================

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
      final scheduledTz = tz.TZDateTime.from(dueDateTime.toUtc(), tz.UTC);

      const androidDetails = AndroidNotificationDetails(
        'tooler_calendar_channel',
        'Calendar Reminders',
        channelDescription: 'Event and celebration alerts for Calendar',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.event,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      try {
        await _notifications.zonedSchedule(
          id,
          title,
          note.isNotEmpty ? note : "Tooler Calendar Event Reminder",
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        await _notifications.zonedSchedule(
          id,
          title,
          note.isNotEmpty ? note : "Tooler Calendar Event Reminder",
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }

  Future<void> cancelCalendarReminder(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (_) {}
  }
}
