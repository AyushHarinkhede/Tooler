import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const int weatherDailyNotificationId = 3001;
  static const int stepGoalNotificationId = 4001;
  static const int stepMilestoneNotificationId = 4002;
  static const int stepPeriodicNotificationId = 4003;
  static const int tallyMilestoneBaseId = 5000;

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

        final alarmChannel = AndroidNotificationChannel(
          'tooler_alarm_channel',
          'Alarms',
          description: 'High-priority wake-up alerts and alarms',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        const tallyChannel = AndroidNotificationChannel(
          'tooler_tally_channel',
          'Tally Counter Milestones',
          description: 'Goal completions and sacred counting milestones',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        const weatherChannel = AndroidNotificationChannel(
          'tooler_weather_channel',
          'Daily Weather Brief',
          description: 'Morning weather and AQI forecast summary (once daily)',
          importance: Importance.high,
          playSound: true,
          enableVibration: false,
        );

        const fitnessChannel = AndroidNotificationChannel(
          'tooler_fitness_channel',
          'Step Counter Goals & Milestones',
          description: 'Daily step goal completions, 1,000-step milestones & 6-hour progress checks',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await androidImpl.createNotificationChannel(timerChannel);
        await androidImpl.createNotificationChannel(taskChannel);
        await androidImpl.createNotificationChannel(calendarChannel);
        await androidImpl.createNotificationChannel(stopwatchChannel);
        await androidImpl.createNotificationChannel(alarmChannel);
        await androidImpl.createNotificationChannel(tallyChannel);
        await androidImpl.createNotificationChannel(weatherChannel);
        await androidImpl.createNotificationChannel(fitnessChannel);
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

  // =========================================================================
  // 5. ALARM NOTIFICATIONS (Exact Background Wake-Up Alarms)
  // =========================================================================

  Future<void> scheduleAlarmNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!await isEnabled) return;
    await init();

    if (scheduledDate.isBefore(DateTime.now())) return;

    try {
      final scheduledTz = tz.TZDateTime.from(scheduledDate.toUtc(), tz.UTC);

      const androidDetails = AndroidNotificationDetails(
        'tooler_alarm_channel',
        'Alarms',
        channelDescription: 'High-priority wake-up alerts and alarms',
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
        interruptionLevel: InterruptionLevel.critical,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
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
          body,
          scheduledTz,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }

  Future<void> cancelAlarmNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (_) {}
  }

  // =========================================================================
  // 6. TALLY COUNTER MILESTONES & GOAL NOTIFICATIONS
  // =========================================================================

  Future<void> showTallyMilestoneNotification({
    required int counterId,
    required String counterName,
    required int value,
    int? targetGoal,
  }) async {
    if (!await isEnabled) return;
    await init();

    final bool isGoal = targetGoal != null && value >= targetGoal;
    final String title = isGoal
        ? "🎯 Goal Reached: $counterName!"
        : (value == 108
            ? "📿 Sacred 108 Chants Completed: $counterName!"
            : "📿 Milestone: $counterName ($value counts)");
    final String body = isGoal
        ? "Congratulations! You completed your target goal of $targetGoal counts."
        : "You just crossed $value counts on $counterName! Tap to view counter.";

    const androidDetails = AndroidNotificationDetails(
      'tooler_tally_channel',
      'Tally Counter Milestones',
      channelDescription: 'Goal completions and sacred counting milestones',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.status,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(
        tallyMilestoneBaseId + (counterId % 1000),
        title,
        body,
        details,
      );
    } catch (_) {}
  }

  // =========================================================================
  // 7. WEATHER DAILY MORNING BRIEF (Strictly Once Per Day)
  // =========================================================================

  Future<void> showDailyMorningWeatherNotification({
    required String city,
    required double tempC,
    required String condition,
    required int aqi,
    required String aqiStatus,
    double? tempMin,
    double? tempMax,
  }) async {
    if (!await isEnabled) return;
    await init();

    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString('tooler_last_weather_notif_date');

    // Strictly 1 weather notification at the start of the day
    if (lastDate == todayStr) return;

    final String title = "🌤️ Good Morning! Today's Weather in $city";
    final String summary = "${tempC.round()}°C · $condition • AQI $aqi ($aqiStatus)";
    final String extended = tempMin != null && tempMax != null
        ? "Today: ${tempMin.round()}°C to ${tempMax.round()}°C · $condition\nAir Quality Index: AQI $aqi ($aqiStatus).\nHave a productive and wonderful day!"
        : "$summary\nHave a great and energized day!";

    final androidDetails = AndroidNotificationDetails(
      'tooler_weather_channel',
      'Daily Weather Brief',
      channelDescription: 'Morning weather and AQI forecast summary (once daily)',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: false,
      styleInformation: BigTextStyleInformation(
        extended,
        contentTitle: title,
        summaryText: "Daily Weather Brief",
      ),
      category: AndroidNotificationCategory.status,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(
        weatherDailyNotificationId,
        title,
        summary,
        details,
      );
      await prefs.setString('tooler_last_weather_notif_date', todayStr);
    } catch (_) {}
  }

  // =========================================================================
  // 8. STEP COUNTER (Goal Achieved, 1,000-Step Milestone & 6-Hour Progress)
  // =========================================================================

  Future<void> showStepGoalAchievedNotification({
    required int steps,
    required int goal,
    required double distanceKm,
    required int calories,
  }) async {
    if (!await isEnabled) return;
    await init();

    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastGoalDate = prefs.getString('tooler_step_goal_notif_date');
    if (lastGoalDate == todayStr) return; // Strictly once per day on achieving goal

    const String title = "🏆 Daily Step Goal Achieved! 🎉";
    final String body =
        "Incredible effort! You reached your goal of $goal steps today ($distanceKm km, $calories kcal burned). Keep up the great streak!";

    final androidDetails = AndroidNotificationDetails(
      'tooler_fitness_channel',
      'Step Counter Goals & Milestones',
      channelDescription: 'Daily step goal completions and milestones',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: "Daily Step Goal",
      ),
      category: AndroidNotificationCategory.status,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(
        stepGoalNotificationId,
        title,
        body,
        details,
      );
      await prefs.setString('tooler_step_goal_notif_date', todayStr);
    } catch (_) {}
  }

  Future<void> showStepMilestoneNotification({
    required int milestoneSteps,
    required double distanceKm,
    required int calories,
  }) async {
    if (!await isEnabled) return;
    await init();

    final String title = "👟 Step Milestone: $milestoneSteps Steps!";
    final String body =
        "You've covered $distanceKm km and burned $calories kcal today. Great momentum!";

    const androidDetails = AndroidNotificationDetails(
      'tooler_fitness_channel',
      'Step Counter Goals & Milestones',
      channelDescription: 'Milestone distance and step progress',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.status,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(
        stepMilestoneNotificationId,
        title,
        body,
        details,
      );
    } catch (_) {}
  }

  Future<void> showStepPeriodic6HourNotification({
    required int steps,
    required double distanceKm,
    required int calories,
  }) async {
    if (!await isEnabled) return;
    await init();

    const String title = "🚶 6-Hour Step Check-in";
    final String body =
        "Today's active progress: $steps steps ($distanceKm km · $calories kcal). Stay active and energized!";

    const androidDetails = AndroidNotificationDetails(
      'tooler_fitness_channel',
      'Step Counter Goals & Milestones',
      channelDescription: '6-hour activity check-ins',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: false,
      category: AndroidNotificationCategory.status,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(
        stepPeriodicNotificationId,
        title,
        body,
        details,
      );
    } catch (_) {}
  }
}
