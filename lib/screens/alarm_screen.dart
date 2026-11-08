import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../theme/stationery_theme.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_character.dart';

/// ---------------------------------------------------------------------------
/// TOOLER SMART ALARM & SLEEP CYCLES SCREEN
/// Unique wake-up missions (Math, Shake to Wake, Memory Pattern, Smooth Slide),
/// 90-minute REM sleep cycle calculator, Quick Power Naps, and 2D animated clock.
/// ---------------------------------------------------------------------------

enum WakeMissionType {
  slide('Smooth Slide', 'Gentle swipe to wake up peacefully', '🌅'),
  math('Math Challenge', 'Solve arithmetic to wake up your brain', '🔢'),
  shake('Shake to Wake', 'Physical motion accelerometer detection', '📱'),
  memory('Mind Pattern', 'Memorize and repeat color tile sequence', '🧠');

  final String title;
  final String description;
  final String emoji;
  const WakeMissionType(this.title, this.description, this.emoji);
}

class AlarmItem {
  final String id;
  int hour; // 0..23
  int minute; // 0..59
  String label;
  bool isEnabled;
  List<int> repeatDays; // 1=Mon .. 7=Sun, empty = once
  WakeMissionType mission;
  int mathDifficulty; // 1=Easy, 2=Medium, 3=Hard
  int shakeTarget; // 15, 25, 40
  bool gradualVolume;
  bool vibrate;
  int snoozeMinutes;

  AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = 'Alarm',
    this.isEnabled = true,
    List<int>? repeatDays,
    this.mission = WakeMissionType.math,
    this.mathDifficulty = 1,
    this.shakeTarget = 20,
    this.gradualVolume = true,
    this.vibrate = true,
    this.snoozeMinutes = 5,
  }) : repeatDays = repeatDays ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'isEnabled': isEnabled,
        'repeatDays': repeatDays,
        'mission': mission.name,
        'mathDifficulty': mathDifficulty,
        'shakeTarget': shakeTarget,
        'gradualVolume': gradualVolume,
        'vibrate': vibrate,
        'snoozeMinutes': snoozeMinutes,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> json) {
    WakeMissionType mission = WakeMissionType.math;
    try {
      mission = WakeMissionType.values.firstWhere(
        (e) => e.name == json['mission'],
        orElse: () => WakeMissionType.math,
      );
    } catch (_) {}

    return AlarmItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      hour: json['hour'] ?? 7,
      minute: json['minute'] ?? 0,
      label: json['label'] ?? 'Alarm',
      isEnabled: json['isEnabled'] ?? true,
      repeatDays: (json['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      mission: mission,
      mathDifficulty: json['mathDifficulty'] ?? 1,
      shakeTarget: json['shakeTarget'] ?? 20,
      gradualVolume: json['gradualVolume'] ?? true,
      vibrate: json['vibrate'] ?? true,
      snoozeMinutes: json['snoozeMinutes'] ?? 5,
    );
  }

  String get formattedTime {
    final dt = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(dt);
  }

  String get repeatSummary {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 &&
        repeatDays.contains(1) &&
        repeatDays.contains(2) &&
        repeatDays.contains(3) &&
        repeatDays.contains(4) &&
        repeatDays.contains(5)) {
      return 'Weekdays (Mon-Fri)';
    }
    if (repeatDays.length == 2 && repeatDays.contains(6) && repeatDays.contains(7)) {
      return 'Weekends';
    }
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => dayNames[d - 1]).join(', ');
  }

  DateTime nextTriggerDate() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute, 0);

    if (repeatDays.isEmpty) {
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      return target;
    }

    // Find next matching weekday
    for (int i = 0; i < 7; i++) {
      final candidate = DateTime(now.year, now.month, now.day + i, hour, minute, 0);
      if (candidate.isAfter(now) && repeatDays.contains(candidate.weekday)) {
        return candidate;
      }
    }
    return target.add(const Duration(days: 1));
  }
}

class AlarmScreen extends StatefulWidget {
  final StationeryTheme theme;
  const AlarmScreen({super.key, required this.theme});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _clockController;
  Timer? _secondTimer;
  DateTime _now = DateTime.now();

  List<AlarmItem> _alarms = [];
  bool _isLoading = true;

  // Background monitor for upcoming alarms
  Timer? _alarmCheckTimer;

  @override
  void initState() {
    super.initState();
    _clockController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _loadAlarms();
    _startAlarmChecker();
  }

  @override
  void dispose() {
    _clockController.dispose();
    _secondTimer?.cancel();
    _alarmCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final saved = await StorageService().loadAlarms();
    if (saved.isNotEmpty) {
      _alarms = saved.map((e) => AlarmItem.fromJson(e)).toList();
    } else {
      // Default initial alarms
      _alarms = [
        AlarmItem(
          id: 'default_1',
          hour: 7,
          minute: 0,
          label: 'Morning Focus & Meditation',
          isEnabled: true,
          repeatDays: [1, 2, 3, 4, 5],
          mission: WakeMissionType.math,
        ),
        AlarmItem(
          id: 'default_2',
          hour: 8,
          minute: 30,
          label: 'Deep Work Sprint',
          isEnabled: false,
          repeatDays: [1, 2, 3, 4, 5],
          mission: WakeMissionType.shake,
          shakeTarget: 25,
        ),
      ];
      await _persistAlarms();
    }
    setState(() {
      _isLoading = false;
    });
    _rescheduleAllNotifications();
  }

  Future<void> _persistAlarms() async {
    await StorageService().saveAlarms(_alarms.map((e) => e.toJson()).toList());
  }

  void _rescheduleAllNotifications() {
    for (final alarm in _alarms) {
      final notifId = (alarm.id.hashCode & 0x7FFFFFFF) % 1000 + 2000;
      if (alarm.isEnabled) {
        final nextDate = alarm.nextTriggerDate();
        NotificationService().scheduleAlarmNotification(
          id: notifId,
          title: "⏰ Alarm: ${alarm.label}",
          body: "It's ${alarm.formattedTime}! Time to wake up and start your day.",
          scheduledDate: nextDate,
        );
      } else {
        NotificationService().cancelAlarmNotification(notifId);
      }
    }
  }

  void _startAlarmChecker() {
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final now = DateTime.now();
      for (final alarm in _alarms) {
        if (alarm.isEnabled &&
            alarm.hour == now.hour &&
            alarm.minute == now.minute &&
            now.second < 20) {
          // If repeatDays is set, check today's weekday
          if (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(now.weekday)) {
            _triggerRingingAlarm(alarm);
            break;
          }
        }
      }
    });
  }

  void _triggerRingingAlarm(AlarmItem alarm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _RingingAlarmModal(
        theme: widget.theme,
        alarm: alarm,
        onDismissed: () {
          // Turn off if one-time alarm
          if (alarm.repeatDays.isEmpty) {
            setState(() {
              alarm.isEnabled = false;
            });
            _persistAlarms();
            _rescheduleAllNotifications();
          }
        },
      ),
    );
  }

  AlarmItem? get _nextAlarm {
    final enabled = _alarms.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return null;
    enabled.sort((a, b) => a.nextTriggerDate().compareTo(b.nextTriggerDate()));
    return enabled.first;
  }

  String _timeUntilNextAlarm() {
    final next = _nextAlarm;
    if (next == null) return 'No active alarms';
    final diff = next.nextTriggerDate().difference(_now);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours == 0 && mins == 0) return 'Ringing very soon!';
    if (hours == 0) return 'In $mins mins (${next.formattedTime})';
    return 'In ${hours}h ${mins}m (${next.formattedTime})';
  }

  void _showAddEditSheet([AlarmItem? existing]) {
    SoundService().playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditAlarmSheet(
        theme: widget.theme,
        existing: existing,
        onSave: (alarm) {
          setState(() {
            if (existing != null) {
              final idx = _alarms.indexWhere((a) => a.id == existing.id);
              if (idx != -1) _alarms[idx] = alarm;
            } else {
              _alarms.add(alarm);
            }
          });
          _persistAlarms();
          _rescheduleAllNotifications();
        },
      ),
    );
  }

  void _deleteAlarm(AlarmItem alarm) {
    SoundService().playClick();
    final notifId = (alarm.id.hashCode & 0x7FFFFFFF) % 1000 + 2000;
    NotificationService().cancelAlarmNotification(notifId);
    setState(() {
      _alarms.removeWhere((a) => a.id == alarm.id);
    });
    _persistAlarms();
  }

  void _toggleAlarm(AlarmItem alarm, bool val) {
    SoundService().playSpecialClick();
    setState(() {
      alarm.isEnabled = val;
    });
    _persistAlarms();
    _rescheduleAllNotifications();
  }

  void _setSleepCycleAlarm(int hours, int minutes, String label) {
    SoundService().playSpecialClick();
    final now = DateTime.now();
    // 14 min average sleep onset
    final wakeTime = now.add(Duration(hours: hours, minutes: minutes + 14));
    final newAlarm = AlarmItem(
      id: 'cycle_${DateTime.now().millisecondsSinceEpoch}',
      hour: wakeTime.hour,
      minute: wakeTime.minute,
      label: label,
      isEnabled: true,
      mission: WakeMissionType.math,
    );
    setState(() {
      _alarms.add(newAlarm);
    });
    _persistAlarms();
    _rescheduleAllNotifications();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⏰ Set $label for ${newAlarm.formattedTime}',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: widget.theme.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _setPowerNapAlarm(int minutes, String label) {
    SoundService().playSpecialClick();
    final now = DateTime.now();
    final wakeTime = now.add(Duration(minutes: minutes));
    final newAlarm = AlarmItem(
      id: 'nap_${DateTime.now().millisecondsSinceEpoch}',
      hour: wakeTime.hour,
      minute: wakeTime.minute,
      label: label,
      isEnabled: true,
      mission: WakeMissionType.shake,
      shakeTarget: 15,
    );
    setState(() {
      _alarms.add(newAlarm);
    });
    _persistAlarms();
    _rescheduleAllNotifications();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚡ Activated $label (${minutes}m) at ${newAlarm.formattedTime}',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: widget.theme.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primary),
      );
    }

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildHeader(isDark),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Live 2D Hybrid Analog/Digital Clock Canvas
                    _buildLiveClockCard(isDark),

                    const SizedBox(height: 20),

                    // 2. Wake-up Missions Showcase (Interactive Try Buttons)
                    _buildMissionsHeader(isDark),
                    const SizedBox(height: 10),
                    _buildMissionsHorizontalList(isDark),

                    const SizedBox(height: 24),

                    // 3. Smart Sleep Cycle Calculator (90m REM math)
                    _buildSleepCyclesSection(isDark),

                    const SizedBox(height: 24),

                    // 4. Quick Power Naps
                    _buildPowerNapSection(isDark),

                    const SizedBox(height: 24),

                    // 5. My Alarms Header & List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Alarms (${_alarms.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: theme.text,
                          ),
                        ),
                        BouncyTap(
                          onTap: () => _showAddEditSheet(),
                          scaleFraction: 0.9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Set Alarm',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_alarms.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      ..._alarms.map((alarm) => _buildAlarmCard(alarm, isDark)),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              BouncyTap(
                onTap: () {
                  SoundService().playClick();
                  Navigator.of(context).pop();
                },
                scaleFraction: 0.9,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.border, width: 1.2),
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: 18, color: theme.text),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Alarm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: theme.text,
                    ),
                  ),
                  Text(
                    'Missions, sleep cycles & smart wake',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          BouncyTap(
            onTap: () => _showAddEditSheet(),
            scaleFraction: 0.9,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: theme.primary.withValues(alpha: 0.3), width: 1.2),
              ),
              child: Icon(Icons.add_alarm_rounded, size: 20, color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClockCard(bool isDark) {
    final theme = widget.theme;
    final timeStr = DateFormat('hh:mm').format(_now);
    final secStr = DateFormat('ss').format(_now);
    final amPm = DateFormat('a').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM').format(_now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2D Analog Clock
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _AnalogClockPainter(
                    now: _now,
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 22),

              // Digital Time Readout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1.0,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ':$secStr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        amPm,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Next Alarm Countdown Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.lavenderBubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.alarm_on_rounded,
                  size: 15,
                  color: theme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _timeUntilNextAlarm(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsHeader(bool isDark) {
    final theme = widget.theme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wake-Up Missions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: theme.text,
              ),
            ),
            Text(
              'Interactive brain & motion wake-up challenges',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMissionsHorizontalList(bool isDark) {
    final theme = widget.theme;

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: WakeMissionType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          final m = WakeMissionType.values[idx];
          return BouncyTap(
            onTap: () {
              SoundService().playClick();
              // Test this mission right away!
              final sample = AlarmItem(
                id: 'test_mission',
                hour: _now.hour,
                minute: _now.minute,
                label: 'Test ${m.title}',
                mission: m,
                shakeTarget: 15,
              );
              _triggerRingingAlarm(sample);
            },
            scaleFraction: 0.94,
            child: Container(
              width: 148,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.border, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 22)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.lavenderBubble,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Try',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.text,
                        ),
                      ),
                      Text(
                        m.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: theme.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSleepCyclesSection(bool isDark) {
    final theme = widget.theme;

    // Based on sleep science: 14 min average latency + 90 min per cycle
    final cycles = [
      {'cycles': 4, 'h': 6, 'm': 0, 'desc': '4 Cycles • Essential', 'badge': null},
      {'cycles': 5, 'h': 7, 'm': 30, 'desc': '5 Cycles • Optimal', 'badge': 'Recommended'},
      {'cycles': 6, 'h': 9, 'm': 0, 'desc': '6 Cycles • Deep Recovery', 'badge': 'Weekend'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Sleep Cycle Calculator',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: theme.text,
                    ),
                  ),
                ],
              ),
              Text(
                '90m REM math',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'If you go to sleep now, wake up at the end of a natural 90-minute sleep cycle to feel energetic with zero grogginess:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // 3 Cycle Options
          Row(
            children: cycles.map((c) {
              final h = c['h'] as int;
              final m = c['m'] as int;
              final wakeTime = _now.add(Duration(hours: h, minutes: m + 14));
              final isRec = c['badge'] == 'Recommended';

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: BouncyTap(
                    onTap: () => _setSleepCycleAlarm(h, m, 'Cycle Wakeup (${c['cycles']}h)'),
                    scaleFraction: 0.94,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isRec
                            ? theme.primary.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F1F8)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRec ? theme.primary : theme.border,
                          width: isRec ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (c['badge'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: isRec ? theme.primary : theme.textSecondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c['badge'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 14),
                          Text(
                            DateFormat('hh:mm a').format(wakeTime),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${c['h']}h ${c['m']}m',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRec ? theme.primary : theme.textSecondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Set',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isRec ? Colors.white : theme.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerNapSection(bool isDark) {
    final theme = widget.theme;

    final naps = [
      {'mins': 15, 'title': 'Power Boost', 'icon': '⚡'},
      {'mins': 25, 'title': 'Focus Rest', 'icon': '🧘'},
      {'mins': 45, 'title': 'Recharge', 'icon': '🔋'},
      {'mins': 90, 'title': 'Full REM', 'icon': '💤'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Power Naps',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: theme.text,
              ),
            ),
            Text(
              'One-tap alarm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: naps.map((n) {
            final mins = n['mins'] as int;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: BouncyTap(
                  onTap: () => _setPowerNapAlarm(mins, '${n['title']} Nap'),
                  scaleFraction: 0.93,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        Text(n['icon'] as String, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(
                          '${mins}m',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: theme.text,
                          ),
                        ),
                        Text(
                          n['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAlarmCard(AlarmItem alarm, bool isDark) {
    final theme = widget.theme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alarm.isEnabled ? theme.primary.withValues(alpha: 0.4) : theme.border,
          width: alarm.isEnabled ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAddEditSheet(alarm),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            DateFormat('hh:mm').format(DateTime(2026, 1, 1, alarm.hour, alarm.minute)),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              color: alarm.isEnabled ? theme.text : theme.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('a').format(DateTime(2026, 1, 1, alarm.hour, alarm.minute)),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: alarm.isEnabled ? theme.primary : theme.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alarm.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: alarm.isEnabled ? theme.text : theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Test Ring Button & Switch Toggle
              Row(
                children: [
                  BouncyTap(
                    onTap: () {
                      SoundService().playClick();
                      _triggerRingingAlarm(alarm);
                    },
                    scaleFraction: 0.88,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.lavenderBubble,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active_rounded, size: 18, color: theme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch.adaptive(
                    value: alarm.isEnabled,
                    onChanged: (val) => _toggleAlarm(alarm, val),
                    activeThumbColor: theme.primary,
                    activeTrackColor: theme.primary.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 10),

          // Bottom Tags & Repeat Days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mission Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.lavenderBubble,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(alarm.mission.emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      alarm.mission.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Repeat Days Summary
              Row(
                children: [
                  Text(
                    alarm.repeatSummary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncyTap(
                    onTap: () => _deleteAlarm(alarm),
                    scaleFraction: 0.88,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: theme.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final theme = widget.theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      child: Column(
        children: [
          ToolerCharacter.studying(
            theme: theme,
            width: 110,
            height: 90,
          ),
          const SizedBox(height: 14),
          Text(
            'No alarms configured',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Set Alarm" or pick a 90m sleep cycle to wake up feeling fresh.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 2D CUSTOM PAINTER: LIVE ANALOG CLOCK
/// ---------------------------------------------------------------------------
class _AnalogClockPainter extends CustomPainter {
  final DateTime now;
  final StationeryTheme theme;
  final bool isDark;

  _AnalogClockPainter({
    required this.now,
    required this.theme,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Clock face background circle
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F1F8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Subtle outer ring
    final ringPaint = Paint()
      ..color = theme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, ringPaint);

    // 3. Hour Tick Marks (12 ticks)
    final tickPaint = Paint()
      ..color = theme.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final outerX = center.dx + (radius - 4) * math.sin(angle);
      final outerY = center.dy - (radius - 4) * math.cos(angle);
      final tickLen = (i % 3 == 0) ? 7.0 : 4.0;
      final innerX = center.dx + (radius - 4 - tickLen) * math.sin(angle);
      final innerY = center.dy - (radius - 4 - tickLen) * math.cos(angle);
      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
    }

    // 4. Hour Hand
    final hourAngle = ((now.hour % 12) + now.minute / 60.0) * 30 * math.pi / 180;
    final hourHandPaint = Paint()
      ..color = theme.text
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.45 * math.sin(hourAngle),
        center.dy - radius * 0.45 * math.cos(hourAngle),
      ),
      hourHandPaint,
    );

    // 5. Minute Hand
    final minAngle = (now.minute + now.second / 60.0) * 6 * math.pi / 180;
    final minHandPaint = Paint()
      ..color = theme.text
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.68 * math.sin(minAngle),
        center.dy - radius * 0.68 * math.cos(minAngle),
      ),
      minHandPaint,
    );

    // 6. Sweeping Second Hand
    final secAngle = (now.second + now.millisecond / 1000.0) * 6 * math.pi / 180;
    final secHandPaint = Paint()
      ..color = theme.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.78 * math.sin(secAngle),
        center.dy - radius * 0.78 * math.cos(secAngle),
      ),
      secHandPaint,
    );

    // 7. Center Pivot Dot
    final pivotPaint = Paint()
      ..color = theme.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) => true;
}

/// ---------------------------------------------------------------------------
/// ADD / EDIT ALARM BOTTOM SHEET
/// ---------------------------------------------------------------------------
class _AddEditAlarmSheet extends StatefulWidget {
  final StationeryTheme theme;
  final AlarmItem? existing;
  final ValueChanged<AlarmItem> onSave;

  const _AddEditAlarmSheet({
    required this.theme,
    this.existing,
    required this.onSave,
  });

  @override
  State<_AddEditAlarmSheet> createState() => _AddEditAlarmSheetState();
}

class _AddEditAlarmSheetState extends State<_AddEditAlarmSheet> {
  late int _hour;
  late int _minute;
  late TextEditingController _labelController;
  late List<int> _repeatDays;
  late WakeMissionType _mission;
  late int _mathDifficulty;
  late int _shakeTarget;
  late bool _gradualVolume;
  late bool _vibrate;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _hour = item?.hour ?? 7;
    _minute = item?.minute ?? 0;
    _labelController = TextEditingController(text: item?.label ?? 'Morning Wakeup');
    _repeatDays = List.from(item?.repeatDays ?? [1, 2, 3, 4, 5]);
    _mission = item?.mission ?? WakeMissionType.math;
    _mathDifficulty = item?.mathDifficulty ?? 1;
    _shakeTarget = item?.shakeTarget ?? 20;
    _gradualVolume = item?.gradualVolume ?? true;
    _vibrate = item?.vibrate ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    SoundService().playSpecialClick();
    final item = AlarmItem(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      hour: _hour,
      minute: _minute,
      label: _labelController.text.trim().isEmpty ? 'Alarm' : _labelController.text.trim(),
      isEnabled: true,
      repeatDays: _repeatDays,
      mission: _mission,
      mathDifficulty: _mathDifficulty,
      shakeTarget: _shakeTarget,
      gradualVolume: _gradualVolume,
      vibrate: _vibrate,
    );
    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: theme.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existing != null ? 'Edit Alarm' : 'Set New Alarm',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: theme.text,
                  ),
                ),
                BouncyTap(
                  onTap: _save,
                  scaleFraction: 0.9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Time Selector (Interactive Steppers)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.border, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour Stepper
                  _buildStepper(
                    value: _hour,
                    min: 0,
                    max: 23,
                    padZero: true,
                    onChanged: (v) => setState(() => _hour = v),
                    theme: theme,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      ':',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: theme.primary,
                      ),
                    ),
                  ),
                  // Minute Stepper
                  _buildStepper(
                    value: _minute,
                    min: 0,
                    max: 59,
                    padZero: true,
                    onChanged: (v) => setState(() => _minute = v),
                    theme: theme,
                  ),
                  const SizedBox(width: 14),
                  // AM/PM Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.lavenderBubble,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _hour >= 12 ? 'PM' : 'AM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Label Input
            TextField(
              controller: _labelController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
              decoration: InputDecoration(
                labelText: 'Alarm Label',
                labelStyle: GoogleFonts.plusJakartaSans(color: theme.textSecondary),
                filled: true,
                fillColor: theme.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.primary, width: 1.5),
                ),
                prefixIcon: Icon(Icons.label_outline_rounded, color: theme.primary, size: 20),
              ),
            ),
            const SizedBox(height: 18),

            // Repeat Days
            Text(
              'Repeat Days',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = i + 1;
                final isSelected = _repeatDays.contains(day);
                const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                return BouncyTap(
                  onTap: () {
                    SoundService().playTap();
                    setState(() {
                      if (isSelected) {
                        _repeatDays.remove(day);
                      } else {
                        _repeatDays.add(day);
                        _repeatDays.sort();
                      }
                    });
                  },
                  scaleFraction: 0.88,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.primary : theme.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.primary : theme.border,
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabels[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : theme.text,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Mission Selection (Wake-up Challenges)
            Text(
              'Wake-Up Mission (Dismiss Challenge)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: WakeMissionType.values.map((m) {
                final isSelected = _mission == m;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: BouncyTap(
                    onTap: () {
                      SoundService().playTap();
                      setState(() => _mission = m);
                    },
                    scaleFraction: 0.96,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.lavenderBubble : theme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? theme.primary : theme.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(m.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: theme.text,
                                  ),
                                ),
                                Text(
                                  m.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: theme.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Additional Mission Options
            if (_mission == WakeMissionType.shake) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shake Target: $_shakeTarget shakes',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w600, color: theme.text)),
                  Row(
                    children: [15, 25, 40].map((count) {
                      final sel = _shakeTarget == count;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: BouncyTap(
                          onTap: () {
                            SoundService().playTap();
                            setState(() => _shakeTarget = count);
                          },
                          scaleFraction: 0.9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sel ? theme.primary : theme.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? theme.primary : theme.border),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : theme.text,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Gentle Sunrise Volume Toggle
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Gentle Volume Escalation',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: theme.text)),
              subtitle: Text('Starts quiet and increases gently over 45s',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: theme.textSecondary)),
              value: _gradualVolume,
              onChanged: (v) => setState(() => _gradualVolume = v),
              activeThumbColor: theme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required StationeryTheme theme,
    bool padZero = false,
  }) {
    final str = padZero ? value.toString().padLeft(2, '0') : value.toString();

    return Column(
      children: [
        BouncyTap(
          onTap: () {
            SoundService().playClick();
            onChanged(value >= max ? min : value + 1);
          },
          scaleFraction: 0.85,
          child: Container(
            width: 36,
            height: 32,
            decoration: BoxDecoration(
              color: theme.lavenderBubble,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.keyboard_arrow_up_rounded, color: theme.primary, size: 22),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            str,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: theme.text,
            ),
          ),
        ),
        BouncyTap(
          onTap: () {
            SoundService().playClick();
            onChanged(value <= min ? max : value - 1);
          },
          scaleFraction: 0.85,
          child: Container(
            width: 36,
            height: 32,
            decoration: BoxDecoration(
              color: theme.lavenderBubble,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: theme.primary, size: 22),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// ACTIVE RINGING ALARM MODAL (With Interactive Missions)
/// ---------------------------------------------------------------------------
class _RingingAlarmModal extends StatefulWidget {
  final StationeryTheme theme;
  final AlarmItem alarm;
  final VoidCallback onDismissed;

  const _RingingAlarmModal({
    required this.theme,
    required this.alarm,
    required this.onDismissed,
  });

  @override
  State<_RingingAlarmModal> createState() => _RingingAlarmModalState();
}

class _RingingAlarmModalState extends State<_RingingAlarmModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellAnimController;
  Timer? _soundTimer;

  // Math Mission State
  late int _mathA;
  late int _mathB;
  late int _mathAns;
  String _userMathInput = '';

  // Shake Mission State
  int _currentShakes = 0;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShakeTime = DateTime.now();

  // Memory Pattern State
  List<int> _memorySequence = [];
  final List<int> _userMemoryTaps = [];
  int _highlightedTile = -1;
  bool _isPlayingSequence = false;
  int _memoryLevel = 1;

  // Slide state
  double _slidePosition = 0.0;

  @override
  void initState() {
    super.initState();
    _bellAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..repeat(reverse: true);

    // Continuous Ringing Audio
    SoundService().playTimerAlarm();
    _soundTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      SoundService().playTimerAlarm();
    });

    _initMission();
  }

  void _initMission() {
    switch (widget.alarm.mission) {
      case WakeMissionType.math:
        _generateMathQuestion();
        break;
      case WakeMissionType.shake:
        _startShakeDetection();
        break;
      case WakeMissionType.memory:
        _startMemoryGame();
        break;
      case WakeMissionType.slide:
        break;
    }
  }

  void _generateMathQuestion() {
    final rand = math.Random();
    if (widget.alarm.mathDifficulty == 1) {
      _mathA = rand.nextInt(30) + 12;
      _mathB = rand.nextInt(30) + 15;
      _mathAns = _mathA + _mathB;
    } else {
      _mathA = rand.nextInt(12) + 6;
      _mathB = rand.nextInt(12) + 7;
      _mathAns = _mathA * _mathB;
    }
    _userMathInput = '';
  }

  void _startShakeDetection() {
    try {
      _accelSub = accelerometerEventStream().listen((event) {
        final g = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final delta = (g - 9.8).abs();
        final now = DateTime.now();

        if (delta > 11.0 && now.difference(_lastShakeTime).inMilliseconds > 220) {
          _lastShakeTime = now;
          HapticFeedback.heavyImpact();
          if (mounted) {
            setState(() {
              _currentShakes++;
            });
            if (_currentShakes >= widget.alarm.shakeTarget) {
              _completeMission();
            }
          }
        }
      });
    } catch (_) {}
  }

  void _startMemoryGame() async {
    final rand = math.Random();
    _memorySequence = List.generate(3 + _memoryLevel, (_) => rand.nextInt(4));
    _userMemoryTaps.clear();
    _playMemorySequence();
  }

  void _playMemorySequence() async {
    _isPlayingSequence = true;
    for (int tile in _memorySequence) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _highlightedTile = tile);
      SoundService().playTap();
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => _highlightedTile = -1);
    }
    _isPlayingSequence = false;
  }

  void _handleMemoryTap(int tile) {
    if (_isPlayingSequence) return;
    SoundService().playClick();
    _userMemoryTaps.add(tile);

    final currentIdx = _userMemoryTaps.length - 1;
    if (_memorySequence[currentIdx] != tile) {
      // Wrong tap
      HapticFeedback.vibrate();
      _userMemoryTaps.clear();
      _playMemorySequence();
      return;
    }

    if (_userMemoryTaps.length == _memorySequence.length) {
      // Level passed!
      if (_memoryLevel >= 2) {
        _completeMission();
      } else {
        setState(() => _memoryLevel++);
        _startMemoryGame();
      }
    }
  }

  void _handleMathDigit(String digit) {
    SoundService().playClick();
    if (_userMathInput.length < 5) {
      setState(() {
        _userMathInput += digit;
      });
      if (int.tryParse(_userMathInput) == _mathAns) {
        _completeMission();
      }
    }
  }

  void _handleMathClear() {
    SoundService().playClick();
    setState(() {
      _userMathInput = '';
    });
  }

  void _completeMission() {
    _soundTimer?.cancel();
    _accelSub?.cancel();
    SoundService().stopTimerAlarm();
    SoundService().playTaskComplete();

    widget.onDismissed();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Good Morning! Mission Complete. Alarm Dismissed.',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _snooze() {
    _soundTimer?.cancel();
    _accelSub?.cancel();
    SoundService().stopTimerAlarm();
    SoundService().playClick();

    // Schedule 5-minute snooze notification
    final snoozeDate = DateTime.now().add(const Duration(minutes: 5));
    NotificationService().scheduleAlarmNotification(
      id: 9999,
      title: "⏰ Snooze Alarm: ${widget.alarm.label}",
      body: "Wake up! Your 5-minute snooze is over.",
      scheduledDate: snoozeDate,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '💤 Snoozed for 5 minutes (rings at ${DateFormat('hh:mm a').format(snoozeDate)})',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: widget.theme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _bellAnimController.dispose();
    _soundTimer?.cancel();
    _accelSub?.cancel();
    SoundService().stopTimerAlarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Notch
          Container(
            width: 46,
            height: 4.5,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Animated 2D Ringing Bell
          AnimatedBuilder(
            animation: _bellAnimController,
            builder: (context, child) {
              final angle = math.sin(_bellAnimController.value * math.pi * 2) * 0.16;
              return Transform.rotate(
                angle: angle,
                child: child,
              );
            },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: theme.lavenderBubble,
                shape: BoxShape.circle,
                border: Border.all(color: theme.primary, width: 2.0),
              ),
              child: Icon(Icons.notifications_active_rounded, size: 38, color: theme.primary),
            ),
          ),
          const SizedBox(height: 12),

          // Time & Alarm Label
          Text(
            widget.alarm.formattedTime,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: theme.text,
            ),
          ),
          Text(
            widget.alarm.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Mission View
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.border, width: 1.2),
              ),
              child: _buildMissionInterface(theme, isDark),
            ),
          ),

          const SizedBox(height: 16),

          // Snooze Button
          BouncyTap(
            onTap: _snooze,
            scaleFraction: 0.94,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.border, width: 1.2),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.snooze_rounded, color: theme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Snooze for 5 minutes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionInterface(StationeryTheme theme, bool isDark) {
    switch (widget.alarm.mission) {
      case WakeMissionType.math:
        return _buildMathMission(theme, isDark);
      case WakeMissionType.shake:
        return _buildShakeMission(theme, isDark);
      case WakeMissionType.memory:
        return _buildMemoryMission(theme, isDark);
      case WakeMissionType.slide:
        return _buildSlideMission(theme, isDark);
    }
  }

  Widget _buildMathMission(StationeryTheme theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(
              '🔢 Solve to Dismiss Alarm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$_mathA + $_mathB = ?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: theme.lavenderBubble,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _userMathInput.isEmpty ? 'Tap answer below' : _userMathInput,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _userMathInput.isEmpty ? theme.textSecondary : theme.primary,
                ),
              ),
            ),
          ],
        ),

        // Keypad Grid
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['1', '2', '3'].map((d) => _buildKeypadBtn(d, theme)).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['4', '5', '6'].map((d) => _buildKeypadBtn(d, theme)).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['7', '8', '9'].map((d) => _buildKeypadBtn(d, theme)).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildKeypadBtn('C', theme, isClear: true),
                _buildKeypadBtn('0', theme),
                _buildKeypadBtn('OK', theme, isAction: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadBtn(String label, StationeryTheme theme, {bool isClear = false, bool isAction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: BouncyTap(
        onTap: () {
          if (isClear) {
            _handleMathClear();
          } else if (isAction) {
            if (int.tryParse(_userMathInput) == _mathAns) {
              _completeMission();
            } else {
              HapticFeedback.vibrate();
              _handleMathClear();
            }
          } else {
            _handleMathDigit(label);
          }
        },
        scaleFraction: 0.88,
        child: Container(
          width: 58,
          height: 44,
          decoration: BoxDecoration(
            color: isAction
                ? theme.primary
                : (isClear ? Colors.redAccent.withValues(alpha: 0.15) : theme.cardBg),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAction ? theme.primary : theme.border,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isAction
                  ? Colors.white
                  : (isClear ? Colors.redAccent : theme.text),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShakeMission(StationeryTheme theme, bool isDark) {
    final progress = (_currentShakes / widget.alarm.shakeTarget).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '📱 Shake Your Phone!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Physical motion wakes up your motor cortex',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: theme.textSecondary),
        ),
        const SizedBox(height: 24),

        // Animated Radial Shake Progress
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: theme.border,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_currentShakes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  Text(
                    'of ${widget.alarm.shakeTarget}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Fallback tap button for simulators or desk use
        BouncyTap(
          onTap: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _currentShakes++;
            });
            if (_currentShakes >= widget.alarm.shakeTarget) {
              _completeMission();
            }
          },
          scaleFraction: 0.9,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.lavenderBubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: theme.primary),
                const SizedBox(width: 6),
                Text(
                  'Tap Shake (Desk Helper)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryMission(StationeryTheme theme, bool isDark) {
    const tileColors = [
      Color(0xFF8B5CF6), // Purple
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Coral Red
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '🧠 Memory Sequence (Level $_memoryLevel/2)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: theme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isPlayingSequence ? 'Watch the sequence...' : 'Repeat the sequence in order!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isPlayingSequence ? theme.primary : theme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // 2x2 Memory Pad Grid
        SizedBox(
          width: 200,
          height: 200,
          child: GridView.count(
            crossAxisCount: 2,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: List.generate(4, (i) {
              final isLit = _highlightedTile == i;
              final color = tileColors[i];

              return BouncyTap(
                onTap: () => _handleMemoryTap(i),
                scaleFraction: 0.88,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isLit ? color : color.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLit ? Colors.white : color,
                      width: isLit ? 3.0 : 1.5,
                    ),
                    boxShadow: isLit
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideMission(StationeryTheme theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '🌅 Gentle Morning',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Slide all the way to dismiss alarm',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: theme.textSecondary),
        ),
        const SizedBox(height: 36),

        // Slide Track
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            const thumbSize = 54.0;
            final maxSlide = trackWidth - thumbSize - 8;

            return Container(
              height: 64,
              decoration: BoxDecoration(
                color: theme.lavenderBubble,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Center(
                    child: Text(
                      'Slide to Dismiss >>>',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _slidePosition + 4,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _slidePosition = (_slidePosition + details.delta.dx).clamp(0.0, maxSlide);
                        });
                        if (_slidePosition >= maxSlide * 0.95) {
                          _completeMission();
                        }
                      },
                      onHorizontalDragEnd: (_) {
                        if (_slidePosition < maxSlide * 0.95) {
                          setState(() => _slidePosition = 0.0);
                        }
                      },
                      child: Container(
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
