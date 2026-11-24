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
/// TOOLER ALARM & SLEEP CYCLES SCREEN
/// - Clean single-header flow (reuses Tooler outer shell header cleanly)
/// - Dedicated Add Alarm button right beneath the live analog/digital clock
/// - Compact Wake-Up Missions, Sleep Cycle & Power Naps buttons -> Hover Pages
/// - Interactive animated scroll-wheel time picker inside Hover Edit/Add modal
/// - Multi-tone built-in sound selector + Device Audio file import & preview
/// - Bidirectional swipe-to-delete + prominent Delete button with warning dialog
/// - Auto-removes completed one-time ('Once') alarms while preserving repeats
/// ---------------------------------------------------------------------------

enum WakeMissionType {
  slide('Smooth Slide'),
  math('Math Challenge'),
  shake('Shake to Wake'),
  memory('Mind Pattern');

  final String title;
  const WakeMissionType(this.title);
}

class BuiltInAlarmTone {
  final String key;
  final String title;
  const BuiltInAlarmTone(this.key, this.title);
}

const List<BuiltInAlarmTone> kBuiltInAlarmTones = [
  BuiltInAlarmTone('alarm', 'Classic Pulse'),
  BuiltInAlarmTone('alarm_chime', 'Crystal Chimes'),
  BuiltInAlarmTone('alarm_radar', 'Precision Radar'),
  BuiltInAlarmTone('alarm_zen', 'Warm Zen Bowl'),
  BuiltInAlarmTone('alarm_siren', 'Morning Siren'),
  BuiltInAlarmTone('alert', 'Crisp Alert'),
  BuiltInAlarmTone('success', 'Bright Triad'),
  BuiltInAlarmTone('system_alarm', 'System Ringtone'),
];

class AlarmItem {
  final String id;
  int hour; // 0..23
  int minute; // 0..59
  String label;
  bool isEnabled;
  List<int> repeatDays; // 1=Mon .. 7=Sun, empty = Once
  WakeMissionType mission;
  int mathDifficulty; // 1=Easy, 2=Medium, 3=Hard
  int shakeTarget; // 15, 25, 40
  bool sound;
  bool vibrate;
  int snoozeMinutes;
  String soundKey;
  String soundTitle;
  String? customSoundPath;
  int? targetEpochMs; // Exact scheduled epoch ms for one-time alarms

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
    this.sound = true,
    this.vibrate = true,
    this.snoozeMinutes = 5,
    this.soundKey = 'alarm',
    this.soundTitle = 'Classic Pulse',
    this.customSoundPath,
    this.targetEpochMs,
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
        'sound': sound,
        'vibrate': vibrate,
        'snoozeMinutes': snoozeMinutes,
        'soundKey': soundKey,
        'soundTitle': soundTitle,
        'customSoundPath': customSoundPath,
        'targetEpochMs': targetEpochMs,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> json) {
    WakeMissionType mission = WakeMissionType.math;
    try {
      mission = WakeMissionType.values.firstWhere(
        (e) => e.name == json['mission'],
        orElse: () => WakeMissionType.math,
      );
    } catch (_) {}

    final sKey = (json['soundKey'] as String?) ?? 'alarm';
    final sTitle = (json['soundTitle'] as String?) ??
        kBuiltInAlarmTones
            .firstWhere(
              (t) => t.key == sKey,
              orElse: () => kBuiltInAlarmTones.first,
            )
            .title;

    return AlarmItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      hour: json['hour'] ?? 7,
      minute: json['minute'] ?? 0,
      label: json['label'] ?? 'Alarm',
      isEnabled: json['isEnabled'] ?? true,
      repeatDays:
          (json['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ??
              [],
      mission: mission,
      mathDifficulty: json['mathDifficulty'] ?? 1,
      shakeTarget: json['shakeTarget'] ?? 20,
      sound: json['sound'] ?? true,
      vibrate: json['vibrate'] ?? true,
      snoozeMinutes: json['snoozeMinutes'] ?? 5,
      soundKey: sKey,
      soundTitle: sTitle,
      customSoundPath: json['customSoundPath'] as String?,
      targetEpochMs: (json['targetEpochMs'] as num?)?.toInt(),
    );
  }

  String get formattedTime {
    final dt = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(dt);
  }

  String get repeatSummary {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Daily';
    if (repeatDays.length == 5 &&
        repeatDays.contains(1) &&
        repeatDays.contains(2) &&
        repeatDays.contains(3) &&
        repeatDays.contains(4) &&
        repeatDays.contains(5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 &&
        repeatDays.contains(6) &&
        repeatDays.contains(7)) {
      return 'Weekends';
    }
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => dayNames[d - 1]).join(', ');
  }

  DateTime nextTriggerDate([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute, 0);

    if (repeatDays.isEmpty) {
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      return target;
    }

    for (int i = 0; i < 7; i++) {
      final candidate =
          DateTime(now.year, now.month, now.day + i, hour, minute, 0);
      if (candidate.isAfter(now) && repeatDays.contains(candidate.weekday)) {
        return candidate;
      }
    }
    return target.add(const Duration(days: 1));
  }

  /// Syncs [targetEpochMs] cleanly for one-time alarms so expired once-alarms
  /// are reliably detected & removed even after app relaunches.
  void refreshTargetEpoch([DateTime? reference]) {
    if (repeatDays.isEmpty && isEnabled) {
      targetEpochMs = nextTriggerDate(reference).millisecondsSinceEpoch;
    } else if (repeatDays.isNotEmpty) {
      targetEpochMs = null;
    }
  }
}

class AlarmScreen extends StatefulWidget {
  final StationeryTheme theme;
  const AlarmScreen({super.key, required this.theme});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  Timer? _secondTimer;
  Timer? _alarmCheckTimer;
  DateTime _now = DateTime.now();

  List<AlarmItem> _alarms = [];
  List<Map<String, String>> _customSounds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
    _secondTimer?.cancel();
    _alarmCheckTimer?.cancel();
    SoundService().stopAlarmPreview();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final saved = await StorageService().loadAlarms();
    final custom = await StorageService().loadCustomAlarmSounds();
    if (!mounted) return;

    if (saved.isNotEmpty) {
      _alarms = saved.map((e) => AlarmItem.fromJson(e)).toList();
    } else {
      _alarms = [
        AlarmItem(
          id: 'default_1',
          hour: 7,
          minute: 0,
          label: 'Morning Focus',
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

    _customSounds = custom;
    await _purgeCompletedOneTimeAlarms(notify: false);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    _rescheduleAllNotifications();
  }

  /// Automatically removes any completed one-time ('Once') alarm whose target
  /// trigger window has already passed, while keeping repeating alarms (ON/OFF).
  Future<bool> _purgeCompletedOneTimeAlarms({bool notify = true}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expired = _alarms.where((a) {
      if (a.repeatDays.isNotEmpty || !a.isEnabled) return false;
      if (a.targetEpochMs == null) return false;
      return nowMs > a.targetEpochMs! + 60000;
    }).toList();

    if (expired.isEmpty) return false;

    for (final a in expired) {
      final notifId = (a.id.hashCode & 0x7FFFFFFF) % 1000 + 2000;
      NotificationService().cancelAlarmNotification(notifId);
    }

    final expiredIds = expired.map((e) => e.id).toSet();
    if (notify && mounted) {
      setState(() {
        _alarms.removeWhere((a) => expiredIds.contains(a.id));
      });
    } else {
      _alarms.removeWhere((a) => expiredIds.contains(a.id));
    }
    await _persistAlarms();
    return true;
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
          title: "Alarm: ${alarm.label}",
          body: "${alarm.formattedTime} • ${alarm.mission.title}",
          scheduledDate: nextDate,
        );
      } else {
        NotificationService().cancelAlarmNotification(notifId);
      }
    }
  }

  void _startAlarmChecker() {
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _purgeCompletedOneTimeAlarms();
      if (!mounted) return;
      final now = DateTime.now();
      for (final alarm in _alarms) {
        if (alarm.isEnabled &&
            alarm.hour == now.hour &&
            alarm.minute == now.minute &&
            now.second < 20) {
          if (alarm.repeatDays.isEmpty ||
              alarm.repeatDays.contains(now.weekday)) {
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
          // One-time ('Once') alarms automatically remove on completion!
          if (alarm.repeatDays.isEmpty) {
            final notifId = (alarm.id.hashCode & 0x7FFFFFFF) % 1000 + 2000;
            NotificationService().cancelAlarmNotification(notifId);
            setState(() {
              _alarms.removeWhere((a) => a.id == alarm.id);
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
    if (hours == 0 && mins == 0) return 'Ringing soon';
    if (hours == 0) return 'In $mins mins (${next.formattedTime})';
    return 'In ${hours}h ${mins}m (${next.formattedTime})';
  }

  Future<bool> _showDeleteWarningDialog(AlarmItem alarm) async {
    SoundService().playTap();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Alarm?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: widget.theme.text,
              ),
            ),
          ],
        ),
        content: Text(
          '${alarm.formattedTime} • ${alarm.label}\nThis alarm will be permanently removed.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: widget.theme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: widget.theme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _confirmAndDeleteAlarm(AlarmItem alarm) async {
    final confirmed = await _showDeleteWarningDialog(alarm);
    if (confirmed && mounted) {
      _deleteAlarm(alarm);
    }
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
      if (val) {
        alarm.refreshTargetEpoch(_now);
      } else {
        alarm.targetEpochMs = null;
      }
    });
    _persistAlarms();
    _rescheduleAllNotifications();
  }

  /// Launches floating spring-animated Hover Page Dialog.
  Future<T?> _showHoverPageDialog<T>({
    required WidgetBuilder builder,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, secAnim) => Center(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: MediaQuery.of(ctx).size.height * 0.84,
              ),
              child: builder(ctx),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showAddEditHoverDialog([AlarmItem? existing]) {
    SoundService().playClick();
    _showHoverPageDialog<void>(
      builder: (ctx) => _AddEditAlarmHoverCard(
        theme: widget.theme,
        existing: existing,
        customSounds: _customSounds,
        onCustomSoundsUpdated: (updated) {
          setState(() => _customSounds = updated);
          StorageService().saveCustomAlarmSounds(updated);
        },
        onSave: (alarm) {
          alarm.refreshTargetEpoch(DateTime.now());
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
        onDelete: existing == null
            ? null
            : () async {
                final ok = await _showDeleteWarningDialog(existing);
                if (ok && ctx.mounted && mounted) {
                  Navigator.of(ctx).pop();
                  _deleteAlarm(existing);
                }
              },
      ),
    );
  }

  void _showMissionsHoverPage() {
    SoundService().playClick();
    final theme = widget.theme;
    _showHoverPageDialog<void>(
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.border, width: 1.3),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wake-Up Missions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  _hoverCloseButton(ctx, theme),
                ],
              ),
              const SizedBox(height: 16),
              ...WakeMissionType.values.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BouncyTap(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      SoundService().playClick();
                      final sample = AlarmItem(
                        id: 'test_mission',
                        hour: _now.hour,
                        minute: _now.minute,
                        label: m.title,
                        mission: m,
                        shakeTarget: 15,
                      );
                      _triggerRingingAlarm(sample);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.lavenderBubble,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: AlarmMissionSvgIcon(
                              mission: m,
                              size: 22,
                              color: theme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.text,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Test',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepCyclesHoverPage() {
    SoundService().playClick();
    final theme = widget.theme;
    final cycles = [
      {'cycles': 4, 'h': 6, 'm': 0, 'badge': null},
      {'cycles': 5, 'h': 7, 'm': 30, 'badge': 'Recommended'},
      {'cycles': 6, 'h': 9, 'm': 0, 'badge': 'Weekend'},
    ];

    _showHoverPageDialog<void>(
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.border, width: 1.3),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        AlarmMoonSvgIcon(size: 20, color: theme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sleep Cycle Calculator',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: theme.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _hoverCloseButton(ctx, theme),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: cycles.map((c) {
                  final h = c['h'] as int;
                  final m = c['m'] as int;
                  final wakeTime = _now.add(Duration(hours: h, minutes: m + 14));
                  final badge = c['badge'] as String?;
                  final isRec = badge == 'Recommended';

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: BouncyTap(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _setSleepCycleAlarm(
                              h, m, 'Cycle Wakeup (${c['cycles']}h)');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isRec
                                ? theme.primary.withValues(alpha: 0.14)
                                : theme.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isRec ? theme.primary : theme.border,
                              width: isRec ? 1.5 : 1.1,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (badge != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: isRec
                                        ? theme.primary
                                        : theme.textSecondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badge,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 18),
                              Text(
                                DateFormat('hh:mm a').format(wakeTime),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: theme.text,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${h}h ${m}m',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isRec
                                      ? theme.primary
                                      : theme.lavenderBubble,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Set',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
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
        ),
      ),
    );
  }

  void _showPowerNapsHoverPage() {
    SoundService().playClick();
    final theme = widget.theme;
    final naps = [
      {'mins': 15, 'title': 'Power Boost'},
      {'mins': 25, 'title': 'Focus Rest'},
      {'mins': 45, 'title': 'Recharge'},
      {'mins': 90, 'title': 'Full REM'},
    ];

    _showHoverPageDialog<void>(
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.border, width: 1.3),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Power Naps',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.text,
                    ),
                  ),
                  _hoverCloseButton(ctx, theme),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: naps.map((n) {
                  final mins = n['mins'] as int;
                  final title = n['title'] as String;
                  return BouncyTap(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _setPowerNapAlarm(mins, '$title Nap');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.border, width: 1.2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: theme.lavenderBubble,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: AlarmPowerNapSvgIcon(
                                  napType: title,
                                  size: 16,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${mins}m',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: theme.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hoverCloseButton(BuildContext ctx, StationeryTheme theme) {
    return BouncyTap(
      onTap: () {
        SoundService().playTap();
        Navigator.of(ctx).pop();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: theme.border),
        ),
        child: Icon(Icons.close_rounded, size: 17, color: theme.textSecondary),
      ),
    );
  }

  void _setSleepCycleAlarm(int hours, int minutes, String label) {
    SoundService().playSpecialClick();
    final now = DateTime.now();
    final wakeTime = now.add(Duration(hours: hours, minutes: minutes + 14));
    final newAlarm = AlarmItem(
      id: 'cycle_${now.millisecondsSinceEpoch}',
      hour: wakeTime.hour,
      minute: wakeTime.minute,
      label: label,
      isEnabled: true,
      mission: WakeMissionType.math,
    )..refreshTargetEpoch(now);

    setState(() {
      _alarms.add(newAlarm);
    });
    _persistAlarms();
    _rescheduleAllNotifications();
    _showQuickSnack('Set $label for ${newAlarm.formattedTime}');
  }

  void _setPowerNapAlarm(int minutes, String label) {
    SoundService().playSpecialClick();
    final now = DateTime.now();
    final wakeTime = now.add(Duration(minutes: minutes));
    final newAlarm = AlarmItem(
      id: 'nap_${now.millisecondsSinceEpoch}',
      hour: wakeTime.hour,
      minute: wakeTime.minute,
      label: label,
      isEnabled: true,
      mission: WakeMissionType.shake,
      shakeTarget: 15,
    )..refreshTargetEpoch(now);

    setState(() {
      _alarms.add(newAlarm);
    });
    _persistAlarms();
    _rescheduleAllNotifications();
    _showQuickSnack('$label set for ${newAlarm.formattedTime}');
  }

  void _showQuickSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.w600),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live 2D Analog / Digital Clock Card (No duplicate inner header!)
              _buildLiveClockCard(isDark),

              const SizedBox(height: 12),

              // 2. Separate Add Alarm Button right below the Time Clock section
              _buildAddAlarmButton(theme),

              const SizedBox(height: 14),

              // 3. Compact Action Buttons for Wake-Up Missions, Sleep Cycle & Quick Power Naps
              _buildFeatureHoverButtonsRow(theme),

              const SizedBox(height: 20),

              // 4. Active Alarms Header
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
                ],
              ),
              const SizedBox(height: 10),

              if (_alarms.isEmpty)
                _buildEmptyState(isDark)
              else
                ..._alarms.map((alarm) => _buildAlarmCard(alarm, isDark)),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
              SizedBox(
                width: 86,
                height: 86,
                child: CustomPaint(
                  painter: _AnalogClockPainter(
                    now: _now,
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.4,
                            height: 1.0,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ':$secStr',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          amPm,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
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
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: theme.lavenderBubble,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.alarm_on_rounded, size: 15, color: theme.primary),
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

  Widget _buildAddAlarmButton(StationeryTheme theme) {
    return BouncyTap(
      onTap: () => _showAddEditHoverDialog(),
      scaleFraction: 0.96,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_alarm_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Add Alarm',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHoverButtonsRow(StationeryTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _featureButtonTile(
            label: 'Wake-Up Missions',
            iconWidget: AlarmMissionSvgIcon(
              mission: WakeMissionType.math,
              size: 18,
              color: theme.primary,
            ),
            onTap: _showMissionsHoverPage,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _featureButtonTile(
            label: 'Sleep Cycle',
            iconWidget: AlarmMoonSvgIcon(size: 18, color: theme.primary),
            onTap: _showSleepCyclesHoverPage,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _featureButtonTile(
            label: 'Power Naps',
            iconWidget: AlarmPowerNapSvgIcon(
              napType: 'Power Boost',
              size: 18,
              color: theme.primary,
            ),
            onTap: _showPowerNapsHoverPage,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _featureButtonTile({
    required String label,
    required Widget iconWidget,
    required VoidCallback onTap,
    required StationeryTheme theme,
  }) {
    return BouncyTap(
      onTap: onTap,
      scaleFraction: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.lavenderBubble,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard(AlarmItem alarm, bool isDark) {
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Dismissible(
          key: ValueKey(alarm.id),
          direction: DismissDirection.horizontal,
          movementDuration: const Duration(milliseconds: 280),
          resizeDuration: const Duration(milliseconds: 240),
          confirmDismiss: (_) => _showDeleteWarningDialog(alarm),
          onDismissed: (_) => _deleteAlarm(alarm),
          background: _buildSlideDeleteBg(Alignment.centerLeft),
          secondaryBackground: _buildSlideDeleteBg(Alignment.centerRight),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: alarm.isEnabled
                    ? theme.primary.withValues(alpha: 0.45)
                    : theme.border,
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
                        onTap: () => _showAddEditHoverDialog(alarm),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  DateFormat('hh:mm').format(DateTime(
                                      2026, 1, 1, alarm.hour, alarm.minute)),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                    color: alarm.isEnabled
                                        ? theme.text
                                        : theme.textSecondary
                                            .withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('a').format(DateTime(
                                      2026, 1, 1, alarm.hour, alarm.minute)),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: alarm.isEnabled
                                        ? theme.primary
                                        : theme.textSecondary
                                            .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              alarm.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: alarm.isEnabled
                                    ? theme.text
                                    : theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                            child: Icon(Icons.notifications_active_rounded,
                                size: 18, color: theme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch.adaptive(
                          value: alarm.isEnabled,
                          onChanged: (val) => _toggleAlarm(alarm, val),
                          activeThumbColor: theme.primary,
                          activeTrackColor:
                              theme.primary.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                const Divider(height: 1, thickness: 0.8),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Mission + Sound + Repeat Chips
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.lavenderBubble,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AlarmMissionSvgIcon(
                                    mission: alarm.mission,
                                    size: 13,
                                    color: theme.primary),
                                const SizedBox(width: 5),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.music_note_rounded,
                                    size: 12, color: theme.textSecondary),
                                const SizedBox(width: 3),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 88),
                                  child: Text(
                                    alarm.soundTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.border),
                            ),
                            child: Text(
                              alarm.repeatSummary,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Larger, clear Delete button with confirmation warning
                    BouncyTap(
                      onTap: () => _confirmAndDeleteAlarm(alarm),
                      scaleFraction: 0.88,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 21,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideDeleteBg(Alignment alignment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 8),
          Text(
            'Delete',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final theme = widget.theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border, width: 1.2),
      ),
      child: Column(
        children: [
          ToolerCharacter.studying(
            theme: theme,
            width: 100,
            height: 82,
          ),
          const SizedBox(height: 12),
          Text(
            'No alarms active',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.text,
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

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F1F8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final ringPaint = Paint()
      ..color = theme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, ringPaint);

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

    final hourAngle =
        ((now.hour % 12) + now.minute / 60.0) * 30 * math.pi / 180;
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

    final secAngle =
        (now.second + now.millisecond / 1000.0) * 6 * math.pi / 180;
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

    canvas.drawCircle(
      center,
      3.5,
      Paint()
        ..color = theme.primary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) => true;
}

/// ---------------------------------------------------------------------------
/// FLOATING HOVER ADD / EDIT ALARM PAGE
/// Animated scroll-wheel time picker, multi-sound + device audio selector,
/// zero verbose captions, and bottom Delete button with warning.
/// ---------------------------------------------------------------------------
class _AddEditAlarmHoverCard extends StatefulWidget {
  final StationeryTheme theme;
  final AlarmItem? existing;
  final List<Map<String, String>> customSounds;
  final ValueChanged<List<Map<String, String>>> onCustomSoundsUpdated;
  final ValueChanged<AlarmItem> onSave;
  final VoidCallback? onDelete;

  const _AddEditAlarmHoverCard({
    required this.theme,
    this.existing,
    required this.customSounds,
    required this.onCustomSoundsUpdated,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_AddEditAlarmHoverCard> createState() => _AddEditAlarmHoverCardState();
}

class _AddEditAlarmHoverCardState extends State<_AddEditAlarmHoverCard> {
  late int _hour12; // 1..12
  late int _minute; // 0..59
  late bool _isPm;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  late TextEditingController _labelController;
  late List<int> _repeatDays;
  late WakeMissionType _mission;
  late int _mathDifficulty;
  late int _shakeTarget;
  late bool _sound;
  late bool _vibrate;
  late String _soundKey;
  late String _soundTitle;
  String? _customSoundPath;

  late List<Map<String, String>> _localCustomSounds;
  String? _previewingKey;
  bool _showSoundTray = false;

  int get _hour24 {
    if (_isPm) {
      return _hour12 == 12 ? 12 : _hour12 + 12;
    } else {
      return _hour12 == 12 ? 0 : _hour12;
    }
  }

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    final h24 = item?.hour ?? 7;
    _minute = item?.minute ?? 0;
    _isPm = h24 >= 12;
    _hour12 = (h24 % 12 == 0) ? 12 : (h24 % 12);

    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);

    _labelController = TextEditingController(text: item?.label ?? 'Alarm');
    _repeatDays = List.from(item?.repeatDays ?? <int>[]);
    _mission = item?.mission ?? WakeMissionType.math;
    _mathDifficulty = item?.mathDifficulty ?? 1;
    _shakeTarget = item?.shakeTarget ?? 20;
    _sound = item?.sound ?? true;
    _vibrate = item?.vibrate ?? true;
    _soundKey = item?.soundKey ?? 'alarm';
    _soundTitle = item?.soundTitle ?? 'Classic Pulse';
    _customSoundPath = item?.customSoundPath;
    _localCustomSounds = List<Map<String, String>>.from(widget.customSounds);
  }

  @override
  void dispose() {
    SoundService().stopAlarmPreview();
    _hourController.dispose();
    _minuteController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _jumpToTime(int h24, int m) {
    SoundService().playTap();
    final newIsPm = h24 >= 12;
    final newH12 = (h24 % 12 == 0) ? 12 : (h24 % 12);
    setState(() {
      _isPm = newIsPm;
      _hour12 = newH12;
      _minute = m;
    });
    if (_hourController.hasClients) {
      final base = _hourController.selectedItem - (_hourController.selectedItem % 12);
      _hourController.animateToItem(
        base + (newH12 - 1),
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
    if (_minuteController.hasClients) {
      final base = _minuteController.selectedItem - (_minuteController.selectedItem % 60);
      _minuteController.animateToItem(
        base + m,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _previewUntilRing() {
    final probe = AlarmItem(
      id: 'preview',
      hour: _hour24,
      minute: _minute,
      repeatDays: _repeatDays,
    );
    final diff = probe.nextTriggerDate().difference(DateTime.now());
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h == 0 && m <= 1) return 'Rings within 1 min';
    if (h == 0) return 'Rings in ${m}m';
    return 'Rings in ${h}h ${m}m';
  }

  Future<void> _togglePreview(String key, String? customPath) async {
    final previewId = customPath ?? key;
    if (_previewingKey == previewId) {
      await SoundService().stopAlarmPreview();
      if (mounted) setState(() => _previewingKey = null);
    } else {
      setState(() => _previewingKey = previewId);
      await SoundService().previewAlarmTone(
        soundKey: key,
        customPath: customPath,
      );
    }
  }

  Future<void> _pickDeviceAudioFile() async {
    SoundService().playClick();
    final picked = await SoundService().pickDeviceAudio();
    if (picked == null || !mounted) return;

    final path = picked['path'] ?? '';
    final name = picked['name'] ?? 'Custom Audio';
    if (path.isEmpty) return;

    final updated = List<Map<String, String>>.from(_localCustomSounds)
      ..removeWhere((e) => e['path'] == path)
      ..insert(0, {'path': path, 'name': name});

    setState(() {
      _localCustomSounds = updated;
      _sound = true;
      _soundKey = 'custom';
      _soundTitle = name;
      _customSoundPath = path;
      _previewingKey = path;
    });
    widget.onCustomSoundsUpdated(updated);
    SoundService().previewAlarmTone(soundKey: 'custom', customPath: path);
  }

  void _save() {
    SoundService().stopAlarmPreview();
    SoundService().playSpecialClick();
    final item = AlarmItem(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      hour: _hour24,
      minute: _minute,
      label: _labelController.text.trim().isEmpty
          ? 'Alarm'
          : _labelController.text.trim(),
      isEnabled: true,
      repeatDays: _repeatDays,
      mission: _mission,
      mathDifficulty: _mathDifficulty,
      shakeTarget: _shakeTarget,
      sound: _sound,
      vibrate: _vibrate,
      soundKey: _soundKey,
      soundTitle: _soundTitle,
      customSoundPath: _soundKey == 'custom' ? _customSoundPath : null,
    )..refreshTargetEpoch(DateTime.now());

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final formattedPreview = DateFormat('hh:mm a')
        .format(DateTime(2026, 1, 1, _hour24, _minute));

    return Container(
      padding: EdgeInsets.only(
        top: 18,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.border, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticky Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existing != null ? 'Edit Alarm' : 'New Alarm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: theme.text,
                ),
              ),
              Row(
                children: [
                  BouncyTap(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncyTap(
                    onTap: () {
                      SoundService().stopAlarmPreview();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.border),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 17, color: theme.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

            // Animated Live Preview + Scroll-Wheel Drum Time Picker
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Text(
                          formattedPreview,
                          key: ValueKey(formattedPreview),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.lavenderBubble,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _previewUntilRing(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: theme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Central highlight bar
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hour Scroll Wheel (1..12)
                            SizedBox(
                              width: 72,
                              child: ListWheelScrollView.useDelegate(
                                controller: _hourController,
                                itemExtent: 42,
                                perspective: 0.004,
                                diameterRatio: 1.4,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (idx) {
                                  final h12 = (idx % 12) + 1;
                                  if (_hour12 != h12) {
                                    SoundService().playKey();
                                    setState(() => _hour12 = h12);
                                  }
                                },
                                childDelegate: ListWheelChildLoopingListDelegate(
                                  children: List.generate(12, (i) {
                                    final h = i + 1;
                                    final active = h == _hour12;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: active ? 24 : 18,
                                          fontWeight: active
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: active
                                              ? theme.text
                                              : theme.textSecondary
                                                  .withValues(alpha: 0.55),
                                        ),
                                        child: Text(h.toString().padLeft(2, '0')),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            Text(
                              ':',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: theme.primary,
                              ),
                            ),
                            // Minute Scroll Wheel (00..59)
                            SizedBox(
                              width: 72,
                              child: ListWheelScrollView.useDelegate(
                                controller: _minuteController,
                                itemExtent: 42,
                                perspective: 0.004,
                                diameterRatio: 1.4,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (idx) {
                                  final m = idx % 60;
                                  if (_minute != m) {
                                    SoundService().playKey();
                                    setState(() => _minute = m);
                                  }
                                },
                                childDelegate: ListWheelChildLoopingListDelegate(
                                  children: List.generate(60, (m) {
                                    final active = m == _minute;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: active ? 24 : 18,
                                          fontWeight: active
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: active
                                              ? theme.text
                                              : theme.textSecondary
                                                  .withValues(alpha: 0.55),
                                        ),
                                        child: Text(m.toString().padLeft(2, '0')),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // AM / PM Animated Segmented Column
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _amPmButton('AM', !_isPm, () {
                                  SoundService().playTap();
                                  setState(() => _isPm = false);
                                }, theme),
                                const SizedBox(height: 6),
                                _amPmButton('PM', _isPm, () {
                                  SoundService().playTap();
                                  setState(() => _isPm = true);
                                }, theme),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quick-jump chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _quickPresetChip('06:00 AM', () => _jumpToTime(6, 0), theme),
                      _quickPresetChip('07:00 AM', () => _jumpToTime(7, 0), theme),
                      _quickPresetChip('08:30 AM', () => _jumpToTime(8, 30), theme),
                      _quickPresetChip('+15m', () {
                        final n = DateTime.now().add(const Duration(minutes: 15));
                        _jumpToTime(n.hour, n.minute);
                      }, theme),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Clean Label Field (no bulky helper text)
            TextField(
              controller: _labelController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
              decoration: InputDecoration(
                hintText: 'Alarm name',
                hintStyle: GoogleFonts.plusJakartaSans(color: theme.textSecondary),
                filled: true,
                fillColor: theme.cardBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.primary, width: 1.5),
                ),
                prefixIcon: Icon(Icons.label_outline_rounded,
                    color: theme.primary, size: 19),
              ),
            ),
            const SizedBox(height: 14),

            // Repeat Mode: Once vs Daily vs Custom Days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repeat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.text,
                  ),
                ),
                Row(
                  children: [
                    _quickPresetChip(
                      'Once',
                      () => setState(() => _repeatDays.clear()),
                      theme,
                      selected: _repeatDays.isEmpty,
                    ),
                    const SizedBox(width: 6),
                    _quickPresetChip(
                      'Daily',
                      () => setState(() => _repeatDays = [1, 2, 3, 4, 5, 6, 7]),
                      theme,
                      selected: _repeatDays.length == 7,
                    ),
                  ],
                ),
              ],
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : theme.text,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // Mission Chips (compact, no verbose descriptions!)
            Text(
              'Wake-Up Mission',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WakeMissionType.values.map((m) {
                final sel = _mission == m;
                return BouncyTap(
                  onTap: () {
                    SoundService().playTap();
                    setState(() => _mission = m);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? theme.lavenderBubble : theme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? theme.primary : theme.border,
                        width: sel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AlarmMissionSvgIcon(
                          mission: m,
                          size: 16,
                          color: sel ? theme.primary : theme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          m.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? theme.primary : theme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_mission == WakeMissionType.shake) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shakes: $_shakeTarget',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.textSecondary,
                    ),
                  ),
                  Row(
                    children: [15, 25, 40]
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _quickPresetChip(
                              '$c',
                              () => setState(() => _shakeTarget = c),
                              theme,
                              selected: _shakeTarget == c,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // Sound Effects + Device Audio Selector Card (caption-free!)
            Material(
              color: theme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.border, width: 1.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    secondary: Icon(
                      _sound
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color:
                          _sound ? const Color(0xFF10B981) : theme.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      'Alarm Sound',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: theme.text,
                      ),
                    ),
                    value: _sound,
                    onChanged: (v) {
                      SoundService().playTap();
                      setState(() => _sound = v);
                    },
                    activeThumbColor: const Color(0xFF10B981),
                  ),
                  if (_sound) ...[
                    const Divider(height: 1),
                    InkWell(
                      onTap: () {
                        SoundService().playTap();
                        setState(() => _showSoundTray = !_showSoundTray);
                      },
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Icon(Icons.library_music_rounded,
                                size: 18, color: theme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _soundTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.text,
                                ),
                              ),
                            ),
                            Text(
                              'Change',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showSoundTray
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: theme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: _showSoundTray
                          ? Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Device Audio Importer Button
                                  BouncyTap(
                                    onTap: _pickDeviceAudioFile,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: theme.primary
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.primary
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.audio_file_rounded,
                                              size: 17, color: theme.primary),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Add Audio from Device',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: theme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // User-Added Device Audio Tracks
                                  ..._localCustomSounds.map((cs) {
                                    final path = cs['path'] ?? '';
                                    final name = cs['name'] ?? 'Custom Audio';
                                    final isSel = _soundKey == 'custom' &&
                                        _customSoundPath == path;
                                    final isPrev = _previewingKey == path;
                                    return _toneTile(
                                      title: name,
                                      isCustom: true,
                                      selected: isSel,
                                      isPreviewing: isPrev,
                                      onSelect: () {
                                        setState(() {
                                          _soundKey = 'custom';
                                          _soundTitle = name;
                                          _customSoundPath = path;
                                        });
                                        _togglePreview('custom', path);
                                      },
                                      onPreview: () =>
                                          _togglePreview('custom', path),
                                      onRemoveCustom: () async {
                                        await SoundService()
                                            .deleteCustomAlarmSound(path);
                                        final updated = List<
                                            Map<String, String>>.from(
                                            _localCustomSounds)
                                          ..removeWhere((e) => e['path'] == path);
                                        setState(() {
                                          _localCustomSounds = updated;
                                          if (isSel) {
                                            _soundKey = 'alarm';
                                            _soundTitle = 'Classic Pulse';
                                            _customSoundPath = null;
                                          }
                                        });
                                        widget.onCustomSoundsUpdated(updated);
                                      },
                                      theme: theme,
                                    );
                                  }),

                                  // Built-In Multi-Tone Sound Effects
                                  ...kBuiltInAlarmTones.map((tone) {
                                    final isSel = _soundKey == tone.key;
                                    final isPrev = _previewingKey == tone.key;
                                    return _toneTile(
                                      title: tone.title,
                                      isCustom: false,
                                      selected: isSel,
                                      isPreviewing: isPrev,
                                      onSelect: () {
                                        setState(() {
                                          _soundKey = tone.key;
                                          _soundTitle = tone.title;
                                          _customSoundPath = null;
                                        });
                                        _togglePreview(tone.key, null);
                                      },
                                      onPreview: () =>
                                          _togglePreview(tone.key, null),
                                      theme: theme,
                                    );
                                  }),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Vibration Toggle (clean, caption-free!)
            Material(
              color: theme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.border, width: 1.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile.adaptive(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                secondary: Icon(
                  _vibrate
                      ? Icons.vibration_rounded
                      : Icons.phone_android_rounded,
                  color: _vibrate ? theme.primary : theme.textSecondary,
                  size: 20,
                ),
                title: Text(
                  'Vibration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.text,
                  ),
                ),
                value: _vibrate,
                onChanged: (v) {
                  SoundService().playTap();
                  setState(() => _vibrate = v);
                },
                activeThumbColor: theme.primary,
              ),
            ),

            // Bottom Delete Option when Editing
            if (widget.onDelete != null) ...[
              const SizedBox(height: 14),
              BouncyTap(
                onTap: widget.onDelete!,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Alarm',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
          ),
        ],
      ),
    );
  }

  Widget _toneTile({
    required String title,
    required bool isCustom,
    required bool selected,
    required bool isPreviewing,
    required VoidCallback onSelect,
    required VoidCallback onPreview,
    VoidCallback? onRemoveCustom,
    required StationeryTheme theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: selected ? theme.lavenderBubble : theme.bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected ? theme.primary : theme.border,
          width: selected ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected ? theme.primary : theme.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                    ),
                    if (isCustom) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEVICE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onPreview,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isPreviewing
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    size: 20,
                    color: isPreviewing
                        ? const Color(0xFFEF4444)
                        : theme.primary,
                  ),
                ),
              ),
              if (onRemoveCustom != null)
                GestureDetector(
                  onTap: onRemoveCustom,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amPmButton(
      String label, bool active, VoidCallback onTap, StationeryTheme theme) {
    return BouncyTap(
      onTap: onTap,
      scaleFraction: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? theme.primary : theme.bg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: active ? theme.primary : theme.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : theme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _quickPresetChip(
    String text,
    VoidCallback onTap,
    StationeryTheme theme, {
    bool selected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? theme.primary : theme.border,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : theme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ACTIVE RINGING ALARM MODAL (With Interactive Missions & Multi-Tone Sound)
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

  late int _mathA;
  late int _mathB;
  late int _mathAns;
  String _userMathInput = '';

  int _currentShakes = 0;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShakeTime = DateTime.now();

  List<int> _memorySequence = [];
  final List<int> _userMemoryTaps = [];
  int _highlightedTile = -1;
  bool _isPlayingSequence = false;
  int _memoryLevel = 1;

  double _slidePosition = 0.0;

  @override
  void initState() {
    super.initState();
    _bellAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..repeat(reverse: true);

    SoundService().playAlarm(
      sound: widget.alarm.sound,
      vibrate: widget.alarm.vibrate,
      soundKey: widget.alarm.soundKey,
      customPath: widget.alarm.customSoundPath,
    );

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
        final g = math
            .sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final delta = (g - 9.8).abs();
        final now = DateTime.now();

        if (delta > 11.0 &&
            now.difference(_lastShakeTime).inMilliseconds > 220) {
          _lastShakeTime = now;
          HapticFeedback.heavyImpact();
          if (mounted) {
            setState(() => _currentShakes++);
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
      HapticFeedback.vibrate();
      _userMemoryTaps.clear();
      _playMemorySequence();
      return;
    }

    if (_userMemoryTaps.length == _memorySequence.length) {
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
      setState(() => _userMathInput += digit);
      if (int.tryParse(_userMathInput) == _mathAns) {
        _completeMission();
      }
    }
  }

  void _handleMathClear() {
    SoundService().playClick();
    setState(() => _userMathInput = '');
  }

  void _completeMission() {
    _soundTimer?.cancel();
    _accelSub?.cancel();
    SoundService().stopAlarm();
    SoundService().playTaskComplete();

    widget.onDismissed();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Alarm Dismissed',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.w700),
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
    SoundService().stopAlarm();
    SoundService().playClick();

    final snoozeDate = DateTime.now().add(const Duration(minutes: 5));
    NotificationService().scheduleAlarmNotification(
      id: 9999,
      title: "Snooze: ${widget.alarm.label}",
      body: "5-minute snooze complete",
      scheduledDate: snoozeDate,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Snoozed until ${DateFormat('hh:mm a').format(snoozeDate)}',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.w600),
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
    SoundService().stopAlarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 4.5,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _bellAnimController,
            builder: (context, child) {
              final angle =
                  math.sin(_bellAnimController.value * math.pi * 2) * 0.16;
              return Transform.rotate(angle: angle, child: child);
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.lavenderBubble,
                shape: BoxShape.circle,
                border: Border.all(color: theme.primary, width: 2.0),
              ),
              child: Icon(Icons.notifications_active_rounded,
                  size: 36, color: theme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.alarm.formattedTime,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: theme.text,
            ),
          ),
          Text(
            widget.alarm.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
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
                  Icon(Icons.snooze_rounded,
                      color: theme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Snooze 5 min',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AlarmMissionSvgIcon(
                    mission: WakeMissionType.math,
                    size: 16,
                    color: theme.primary),
                const SizedBox(width: 8),
                Text(
                  'Math Challenge',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ],
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
                _userMathInput.isEmpty ? '?' : _userMathInput,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color:
                      _userMathInput.isEmpty ? theme.textSecondary : theme.primary,
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  ['1', '2', '3'].map((d) => _buildKeypadBtn(d, theme)).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  ['4', '5', '6'].map((d) => _buildKeypadBtn(d, theme)).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  ['7', '8', '9'].map((d) => _buildKeypadBtn(d, theme)).toList(),
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

  Widget _buildKeypadBtn(String label, StationeryTheme theme,
      {bool isClear = false, bool isAction = false}) {
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
                : (isClear
                    ? Colors.redAccent.withValues(alpha: 0.15)
                    : theme.cardBg),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AlarmMissionSvgIcon(
                mission: WakeMissionType.shake, size: 20, color: theme.primary),
            const SizedBox(width: 8),
            Text(
              'Shake Phone',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
        const SizedBox(height: 20),
        BouncyTap(
          onTap: () {
            HapticFeedback.heavyImpact();
            setState(() => _currentShakes++);
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
                  'Tap Shake',
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
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AlarmMissionSvgIcon(
                mission: WakeMissionType.memory,
                size: 18,
                color: theme.primary),
            const SizedBox(width: 8),
            Text(
              'Mind Pattern ($_memoryLevel/2)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _isPlayingSequence ? 'Watch...' : 'Repeat!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _isPlayingSequence ? theme.primary : theme.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
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
                    color: isLit
                        ? color
                        : color.withValues(alpha: isDark ? 0.25 : 0.15),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AlarmMissionSvgIcon(
                mission: WakeMissionType.slide, size: 20, color: theme.primary),
            const SizedBox(width: 8),
            Text(
              'Smooth Slide',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
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
                border: Border.all(
                    color: theme.primary.withValues(alpha: 0.3), width: 1.5),
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
                          _slidePosition =
                              (_slidePosition + details.delta.dx)
                                  .clamp(0.0, maxSlide);
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
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 24),
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

/// ---------------------------------------------------------------------------
/// TOOLER ALARM VECTOR SVG ICONS (Stationery Ink Theme)
/// ---------------------------------------------------------------------------

class AlarmMissionSvgIcon extends StatelessWidget {
  final WakeMissionType mission;
  final double size;
  final Color? color;

  const AlarmMissionSvgIcon({
    super.key,
    required this.mission,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: switch (mission) {
        WakeMissionType.slide => _SlideSunriseSvgPainter(color: c),
        WakeMissionType.math => _MathMissionSvgPainter(color: c),
        WakeMissionType.shake => _ShakePhoneSvgPainter(color: c),
        WakeMissionType.memory => _MemoryGridSvgPainter(color: c),
      },
    );
  }
}

class AlarmMoonSvgIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AlarmMoonSvgIcon({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: _SleepMoonSvgPainter(color: c),
    );
  }
}

class AlarmPowerNapSvgIcon extends StatelessWidget {
  final String napType;
  final double size;
  final Color? color;

  const AlarmPowerNapSvgIcon({
    super.key,
    required this.napType,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: switch (napType) {
        'Power Boost' => _LightningNapSvgPainter(color: c),
        'Focus Rest' => _ZenFocusNapSvgPainter(color: c),
        'Recharge' => _BatteryNapSvgPainter(color: c),
        _ => _RemWaveNapSvgPainter(color: c),
      },
    );
  }
}

class _SlideSunriseSvgPainter extends CustomPainter {
  final Color color;
  const _SlideSunriseSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.70),
      Offset(size.width * 0.88, size.height * 0.70),
      paint,
    );

    final sunCenter = Offset(size.width * 0.50, size.height * 0.70);
    final sunRadius = size.width * 0.26;
    final sunRect = Rect.fromCircle(center: sunCenter, radius: sunRadius);
    final sunPath = Path()
      ..arcTo(sunRect, math.pi, math.pi, false)
      ..close();
    canvas.drawPath(sunPath, fillPaint);
    canvas.drawArc(sunRect, math.pi, math.pi, false, paint);

    final rayAngles = [
      math.pi * 1.18,
      math.pi * 1.35,
      math.pi * 1.5,
      math.pi * 1.65,
      math.pi * 1.82
    ];
    for (final angle in rayAngles) {
      final inner = Offset(
        sunCenter.dx + math.cos(angle) * (sunRadius + 2.5),
        sunCenter.dy + math.sin(angle) * (sunRadius + 2.5),
      );
      final outer = Offset(
        sunCenter.dx + math.cos(angle) * (sunRadius + 6.0),
        sunCenter.dy + math.sin(angle) * (sunRadius + 6.0),
      );
      canvas.drawLine(inner, outer, paint..strokeWidth = 1.6);
    }

    final arrowTrackY = size.height * 0.88;
    canvas.drawLine(
      Offset(size.width * 0.22, arrowTrackY),
      Offset(size.width * 0.76, arrowTrackY),
      paint..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, arrowTrackY - 3.2),
      Offset(size.width * 0.78, arrowTrackY),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, arrowTrackY + 3.2),
      Offset(size.width * 0.78, arrowTrackY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SlideSunriseSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MathMissionSvgPainter extends CustomPainter {
  final Color color;
  const _MathMissionSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawLine(Offset(size.width * 0.18, size.height * 0.30),
        Offset(size.width * 0.42, size.height * 0.30), stroke);
    canvas.drawLine(Offset(size.width * 0.30, size.height * 0.18),
        Offset(size.width * 0.30, size.height * 0.42), stroke);
    canvas.drawLine(Offset(size.width * 0.60, size.height * 0.30),
        Offset(size.width * 0.84, size.height * 0.30), stroke);
    canvas.drawLine(Offset(size.width * 0.20, size.height * 0.62),
        Offset(size.width * 0.40, size.height * 0.82), stroke);
    canvas.drawLine(Offset(size.width * 0.40, size.height * 0.62),
        Offset(size.width * 0.20, size.height * 0.82), stroke);
    canvas.drawLine(Offset(size.width * 0.60, size.height * 0.72),
        Offset(size.width * 0.84, size.height * 0.72), stroke);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.62), 1.5, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.82), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _MathMissionSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ShakePhoneSvgPainter extends CustomPainter {
  final Color color;
  const _ShakePhoneSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.50),
        width: size.width * 0.42,
        height: size.height * 0.72,
      ),
      const Radius.circular(4.5),
    );
    canvas.drawRRect(phoneRect, stroke);

    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.22),
      Offset(size.width * 0.56, size.height * 0.22),
      stroke..strokeWidth = 1.4,
    );
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.78),
      Offset(size.width * 0.56, size.height * 0.78),
      stroke..strokeWidth = 1.4,
    );

    final leftWave = Path()
      ..moveTo(size.width * 0.18, size.height * 0.32)
      ..quadraticBezierTo(
          size.width * 0.08, size.height * 0.50, size.width * 0.18, size.height * 0.68);
    canvas.drawPath(leftWave, stroke..strokeWidth = 1.8);

    final rightWave = Path()
      ..moveTo(size.width * 0.82, size.height * 0.32)
      ..quadraticBezierTo(
          size.width * 0.92, size.height * 0.50, size.width * 0.82, size.height * 0.68);
    canvas.drawPath(rightWave, stroke);
  }

  @override
  bool shouldRepaint(covariant _ShakePhoneSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MemoryGridSvgPainter extends CustomPainter {
  final Color color;
  const _MemoryGridSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final tileW = size.width * 0.32;
    final tileH = size.height * 0.32;
    const r = Radius.circular(3.5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.14, size.height * 0.14, tileW, tileH), r),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.54, size.height * 0.14, tileW, tileH), r),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.14, size.height * 0.54, tileW, tileH), r),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.54, size.height * 0.54, tileW, tileH), r),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MemoryGridSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SleepMoonSvgPainter extends CustomPainter {
  final Color color;
  const _SleepMoonSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final moon = Path();
    moon.moveTo(size.width * 0.58, size.height * 0.14);
    moon.arcToPoint(
      Offset(size.width * 0.58, size.height * 0.86),
      radius: Radius.circular(size.width * 0.38),
      clockwise: true,
    );
    moon.arcToPoint(
      Offset(size.width * 0.58, size.height * 0.14),
      radius: Radius.circular(size.width * 0.30),
      clockwise: false,
    );
    canvas.drawPath(moon, fill);
    canvas.drawPath(moon, stroke);

    void drawSparkle(Offset center, double s) {
      canvas.drawLine(Offset(center.dx - s, center.dy),
          Offset(center.dx + s, center.dy), stroke..strokeWidth = 1.4);
      canvas.drawLine(Offset(center.dx, center.dy - s),
          Offset(center.dx, center.dy + s), stroke..strokeWidth = 1.4);
    }

    drawSparkle(Offset(size.width * 0.78, size.height * 0.28), 3.0);
    drawSparkle(Offset(size.width * 0.84, size.height * 0.64), 2.0);
  }

  @override
  bool shouldRepaint(covariant _SleepMoonSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LightningNapSvgPainter extends CustomPainter {
  final Color color;
  const _LightningNapSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final bolt = Path()
      ..moveTo(size.width * 0.56, size.height * 0.12)
      ..lineTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.50, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.88)
      ..lineTo(size.width * 0.76, size.height * 0.44)
      ..lineTo(size.width * 0.54, size.height * 0.44)
      ..close();

    canvas.drawPath(bolt, fill);
    canvas.drawPath(bolt, stroke);
  }

  @override
  bool shouldRepaint(covariant _LightningNapSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ZenFocusNapSvgPainter extends CustomPainter {
  final Color color;
  const _ZenFocusNapSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    canvas.drawCircle(center, size.width * 0.36, stroke);
    canvas.drawCircle(center, size.width * 0.18, stroke);
    canvas.drawCircle(
      center,
      2.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawLine(Offset(center.dx, size.height * 0.06),
        Offset(center.dx, size.height * 0.16), stroke..strokeWidth = 1.5);
    canvas.drawLine(Offset(center.dx, size.height * 0.84),
        Offset(center.dx, size.height * 0.94), stroke);
    canvas.drawLine(Offset(size.width * 0.06, center.dy),
        Offset(size.width * 0.16, center.dy), stroke);
    canvas.drawLine(Offset(size.width * 0.84, center.dy),
        Offset(size.width * 0.94, center.dy), stroke);
  }

  @override
  bool shouldRepaint(covariant _ZenFocusNapSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BatteryNapSvgPainter extends CustomPainter {
  final Color color;
  const _BatteryNapSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.14, size.height * 0.28, size.width * 0.64,
          size.height * 0.44),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(bodyRect, stroke);

    canvas.drawLine(
      Offset(size.width * 0.84, size.height * 0.42),
      Offset(size.width * 0.84, size.height * 0.58),
      stroke..strokeWidth = 2.2,
    );

    final bolt = Path()
      ..moveTo(size.width * 0.48, size.height * 0.36)
      ..lineTo(size.width * 0.38, size.height * 0.50)
      ..lineTo(size.width * 0.47, size.height * 0.50)
      ..lineTo(size.width * 0.44, size.height * 0.64)
      ..lineTo(size.width * 0.55, size.height * 0.48)
      ..lineTo(size.width * 0.47, size.height * 0.48)
      ..close();
    canvas.drawPath(
      bolt,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryNapSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RemWaveNapSvgPainter extends CustomPainter {
  final Color color;
  const _RemWaveNapSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (final yRatio in [0.34, 0.52, 0.70]) {
      final y = size.height * yRatio;
      final path = Path()
        ..moveTo(size.width * 0.12, y)
        ..quadraticBezierTo(size.width * 0.32, y - 5, size.width * 0.50, y)
        ..quadraticBezierTo(size.width * 0.68, y + 5, size.width * 0.88, y);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _RemWaveNapSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}
