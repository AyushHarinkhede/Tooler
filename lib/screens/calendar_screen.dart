import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/stationery_theme.dart';
import '../models/calendar_event_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_character.dart';

/// ---------------------------------------------------------------------------
/// TOOLER CALENDAR & OBSERVANCES SCREEN
/// ---------------------------------------------------------------------------
/// Key Features:
/// 1. Smooth horizontal slide/swipe month navigation (PageView)
/// 2. Exact mathematical date precision (leap years, month days, weekday alignment)
/// 3. Sundays rendered in PURE RED (#E74C3C) font & numbers
/// 4. Fixed Annual Universally Celebrated International Days (UN/UNESCO/WHO)
/// 5. Special occasion containers highlighted in UI theme color with vector icons (zero emojis)
/// 6. Interactive date selection with custom personal notes & instructions
/// 7. Recurrence options (One-Time, Annually, Monthly, Weekly) with radio toggles
/// 8. High-priority notification reminders for personal events & celebrations
/// 9. Future Task integration: automatically synchronizes personal reminders with Tasks checklist
/// ---------------------------------------------------------------------------

class CalendarScreen extends StatefulWidget {
  final StationeryTheme theme;
  const CalendarScreen({super.key, required this.theme});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _basePage = 1200;
  late final DateTime _baseDate;
  late final PageController _pageController;

  int _currentPage = _basePage;
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  List<CalendarEventModel> _events = [];
  bool _isLoading = true;
  bool _notifyIntlDays = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, 1);
    _currentMonth = _baseDate;
    _selectedDate = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: _basePage);

    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final events = await StorageService().loadCalendarEvents();
    final notifyIntl = await StorageService().loadCalendarIntlNotifications();
    if (mounted) {
      setState(() {
        _events = events;
        _notifyIntlDays = notifyIntl;
        _isLoading = false;
      });
    }
  }

  DateTime _getMonthForPage(int page) {
    final offset = page - _basePage;
    return DateTime(_baseDate.year, _baseDate.month + offset, 1);
  }

  int _getPageForMonth(DateTime month) {
    final yearDiff = month.year - _baseDate.year;
    final monthDiff = month.month - _baseDate.month;
    return _basePage + (yearDiff * 12) + monthDiff;
  }

  void _jumpToToday() {
    SoundService().playClick();
    final now = DateTime.now();
    final targetPage = _getPageForMonth(DateTime(now.year, now.month, 1));
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _currentMonth = DateTime(now.year, now.month, 1);
      _currentPage = targetPage;
    });
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _changeMonth(int delta) {
    SoundService().playClick();
    final targetPage = _currentPage + delta;
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _showMonthYearPicker() async {
    SoundService().playClick();
    int selectedYear = _currentMonth.year;
    int selectedMonth = _currentMonth.month;

    final theme = widget.theme;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: theme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: theme.border, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jump to Date',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: theme.text,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: () => setDialogState(() => selectedYear--),
                            ),
                            Text(
                              '$selectedYear',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: () => setDialogState(() => selectedYear++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (idx) {
                        final m = idx + 1;
                        final isSel = (m == selectedMonth);
                        final name = DateFormat.MMM().format(DateTime(2026, m));
                        return ChoiceChip(
                          label: Text(name),
                          selected: isSel,
                          selectedColor: theme.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : theme.text,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setDialogState(() => selectedMonth = m);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            final targetMonth = DateTime(selectedYear, selectedMonth, 1);
                            final targetPage = _getPageForMonth(targetMonth);
                            setState(() {
                              _currentMonth = targetMonth;
                              _currentPage = targetPage;
                            });
                            _pageController.jumpToPage(targetPage);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Jump', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InternationalDay? _getIntlDay(DateTime date) {
    for (final day in kInternationalDays) {
      if (day.month == date.month && day.day == date.day) {
        return day;
      }
    }
    return null;
  }

  List<CalendarEventModel> _getEventsForDate(DateTime date) {
    return _events.where((e) => e.occursOn(date)).toList();
  }

  // ---------------------------------------------------------------------------
  // ADD / EDIT EVENT MODAL WITH TASK SYNCHRONIZATION
  // ---------------------------------------------------------------------------
  void _openAddEventModal([CalendarEventModel? existingEvent]) {
    SoundService().playClick();
    final theme = widget.theme;

    final titleCtrl = TextEditingController(text: existingEvent?.title ?? '');
    final noteCtrl = TextEditingController(text: existingEvent?.note ?? '');
    String selectedTag = existingEvent?.tag ?? 'Birthday';
    String selectedRepeat = existingEvent?.repeat ?? 'none';
    TimeOfDay reminderTime = TimeOfDay(
      hour: existingEvent?.reminderHour ?? 9,
      minute: existingEvent?.reminderMinute ?? 0,
    );
    bool addToTasks = existingEvent?.addToTasks ?? true;

    final tags = [
      {'name': 'Birthday', 'icon': Icons.cake_rounded, 'color': const Color(0xFFE84393)},
      {'name': 'Anniversary', 'icon': Icons.diamond_rounded, 'color': const Color(0xFF9B59B6)},
      {'name': 'Meeting', 'icon': Icons.business_center_rounded, 'color': const Color(0xFF2980B9)},
      {'name': 'Exam', 'icon': Icons.school_rounded, 'color': const Color(0xFFE67E22)},
      {'name': 'Reminder', 'icon': Icons.notifications_active_rounded, 'color': const Color(0xFFF39C12)},
      {'name': 'Note', 'icon': Icons.edit_note_rounded, 'color': const Color(0xFF27AE60)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: theme.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: theme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingEvent == null ? 'Add Event / Reminder' : 'Edit Event',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.text,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            DateFormat('d MMM').format(_selectedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 12, color: theme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Event Title (e.g. Birthday, Anniversary, Exam)',
                        labelStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: theme.bg,
                        prefixIcon: Icon(Icons.title_rounded, color: theme.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.primary, width: 1.8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note & Instruction
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Special Instruction / Detail Note',
                        labelStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: theme.bg,
                        prefixIcon: Icon(Icons.notes_rounded, color: theme.primary, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.primary, width: 1.8)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tag Selector
                    Text('Category Tag:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.text)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: tags.map((t) {
                        final isSel = selectedTag == t['name'];
                        return BouncyTap(
                          onTap: () {
                            SoundService().playClick();
                            setModalState(() => selectedTag = t['name'] as String);
                          },
                          scaleFraction: 0.94,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? (t['color'] as Color).withValues(alpha: 0.18) : theme.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? (t['color'] as Color) : theme.border,
                                width: isSel ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(t['icon'] as IconData, size: 15, color: t['color'] as Color),
                                const SizedBox(width: 5),
                                Text(
                                  t['name'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                    color: isSel ? (t['color'] as Color) : theme.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Recurrence Radio Selector
                    Text('Recurrence & Repeat:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.text)),
                    const SizedBox(height: 6),
                    Column(
                      children: [
                        _buildRecurrenceOption(
                          theme: theme,
                          title: 'One-Time (No Repeat)',
                          subtitle: 'Alerts only on this specific date',
                          value: 'none',
                          groupValue: selectedRepeat,
                          onChanged: (val) => setModalState(() => selectedRepeat = val),
                        ),
                        _buildRecurrenceOption(
                          theme: theme,
                          title: 'Repeat Annually (Har Saal)',
                          subtitle: 'Ideal for Birthdays & Anniversaries every year',
                          value: 'yearly',
                          groupValue: selectedRepeat,
                          onChanged: (val) => setModalState(() => selectedRepeat = val),
                        ),
                        _buildRecurrenceOption(
                          theme: theme,
                          title: 'Repeat Monthly (Har Mahine)',
                          subtitle: 'Reminds every month on the same day',
                          value: 'monthly',
                          groupValue: selectedRepeat,
                          onChanged: (val) => setModalState(() => selectedRepeat = val),
                        ),
                        _buildRecurrenceOption(
                          theme: theme,
                          title: 'Repeat Weekly (Har Hafte)',
                          subtitle: 'Reminds every week on the same day of week',
                          value: 'weekly',
                          groupValue: selectedRepeat,
                          onChanged: (val) => setModalState(() => selectedRepeat = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Reminder Time Picker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.alarm_rounded, size: 20, color: theme.primary),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Notification Reminder Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.text)),
                                  Text(
                                    reminderTime.format(context),
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: theme.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              SoundService().playClick();
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: reminderTime,
                              );
                              if (picked != null) {
                                setModalState(() => reminderTime = picked);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Add to Tasks Checklist Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.playlist_add_check_circle_rounded, size: 22, color: Color(0xFF27AE60)),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Show in Tasks & Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.text)),
                                  Text('Synchronize as a future actionable task', style: TextStyle(fontSize: 11, color: theme.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: addToTasks,
                            activeThumbColor: theme.primary,
                            activeTrackColor: theme.primary.withValues(alpha: 0.4),
                            onChanged: (val) => setModalState(() => addToTasks = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            SoundService().playAlert();
                            return;
                          }
                          SoundService().playSuccess();

                          final eventId = existingEvent?.id ?? 'cal_${DateTime.now().microsecondsSinceEpoch}';
                          final newEvent = CalendarEventModel(
                            id: eventId,
                            title: titleCtrl.text.trim(),
                            note: noteCtrl.text.trim(),
                            date: _selectedDate,
                            tag: selectedTag,
                            repeat: selectedRepeat,
                            reminderHour: reminderTime.hour,
                            reminderMinute: reminderTime.minute,
                            addToTasks: addToTasks,
                            isCompleted: existingEvent?.isCompleted ?? false,
                          );

                          final updatedEvents = List<CalendarEventModel>.from(_events);
                          if (existingEvent != null) {
                            final idx = updatedEvents.indexWhere((e) => e.id == existingEvent.id);
                            if (idx != -1) updatedEvents[idx] = newEvent;
                          } else {
                            updatedEvents.add(newEvent);
                          }

                          await StorageService().saveCalendarEvents(updatedEvents);

                          // Schedule notification
                          final reminderDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            reminderTime.hour,
                            reminderTime.minute,
                          );
                          final notifId = eventId.hashCode.abs() % 100000;
                          await NotificationService().scheduleCalendarReminder(
                            id: notifId,
                            title: "${newEvent.tag}: ${newEvent.title}",
                            note: newEvent.note.isNotEmpty ? newEvent.note : "Scheduled event for today in Tooler Calendar.",
                            dueDateTime: reminderDateTime,
                          );

                          // Future Task integration
                          if (addToTasks) {
                            final tasks = await StorageService().loadTasks();
                            final taskPrefix = "[Calendar ${newEvent.tag}]";
                            final taskTitle = "$taskPrefix ${newEvent.title}${newEvent.note.isNotEmpty ? ' (${newEvent.note})' : ''}";
                            final existingTaskIdx = tasks.indexWhere((t) => t.text.startsWith(taskPrefix) && t.text.contains(newEvent.title));
                            if (existingTaskIdx != -1) {
                              tasks[existingTaskIdx].text = taskTitle;
                              tasks[existingTaskIdx].dueDateTime = reminderDateTime;
                            } else {
                              tasks.add(
                                TaskItem(
                                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                                  text: taskTitle,
                                  category: (selectedTag == 'Birthday' || selectedTag == 'Anniversary') ? 'Personal' : 'School',
                                  priority: (selectedTag == 'Birthday' || selectedTag == 'Exam') ? 'High' : 'Medium',
                                  dueDateTime: reminderDateTime,
                                ),
                              );
                            }
                            await StorageService().saveTasks(tasks);
                          }

                          if (mounted) {
                            setState(() => _events = updatedEvents);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          existingEvent == null ? 'Save Event & Schedule Reminder' : 'Update Event',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecurrenceOption({
    required StationeryTheme theme,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required Function(String) onChanged,
  }) {
    final isSelected = (value == groupValue);
    return BouncyTap(
      onTap: () {
        SoundService().playClick();
        onChanged(value);
      },
      scaleFraction: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary.withValues(alpha: 0.12) : theme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primary : theme.border,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primary : theme.border,
                  width: 2,
                ),
                color: isSelected ? theme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? theme.primary : theme.text,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: theme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(CalendarEventModel event) async {
    SoundService().playKey();
    final updated = _events.where((e) => e.id != event.id).toList();
    await StorageService().saveCalendarEvents(updated);
    await NotificationService().cancelCalendarReminder(event.id.hashCode.abs() % 100000);
    setState(() => _events = updated);
  }

  Future<void> _toggleEventComplete(CalendarEventModel event) async {
    SoundService().playClick();
    final updated = _events.map((e) {
      if (e.id == event.id) return e.copyWith(isCompleted: !e.isCompleted);
      return e;
    }).toList();
    await StorageService().saveCalendarEvents(updated);
    setState(() => _events = updated);
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarHeader(theme),
        const SizedBox(height: 8),
        _buildWeekdayHeader(theme),
        const SizedBox(height: 6),
        // Swipeable Month Grid View
        SizedBox(
          height: 275,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
                _currentMonth = _getMonthForPage(page);
              });
            },
            itemBuilder: (ctx, page) {
              final monthDate = _getMonthForPage(page);
              return _buildMonthGrid(theme, monthDate);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Selected Date Details & Observances
        _buildSelectedDateDetails(theme),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP BAR HEADER
  // ---------------------------------------------------------------------------
  Widget _buildCalendarHeader(StationeryTheme theme) {
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);
    final now = DateTime.now();
    final isCurrentMonth = (_currentMonth.year == now.year && _currentMonth.month == now.month);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BouncyTap(
            onTap: _showMonthYearPicker,
            scaleFraction: 0.94,
            child: Row(
              children: [
                Text(
                  monthName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.text,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down_rounded, color: theme.primary, size: 24),
              ],
            ),
          ),
          Row(
            children: [
              BouncyTap(
                onTap: () async {
                  SoundService().playClick();
                  final nextVal = !_notifyIntlDays;
                  await StorageService().saveCalendarIntlNotifications(nextVal);
                  setState(() => _notifyIntlDays = nextVal);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          nextVal
                              ? 'Global observance reminders enabled'
                              : 'Global observance reminders muted',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                scaleFraction: 0.90,
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _notifyIntlDays ? theme.primary.withValues(alpha: 0.12) : theme.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _notifyIntlDays ? theme.primary : theme.border,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    _notifyIntlDays ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                    size: 16,
                    color: _notifyIntlDays ? theme.primary : theme.textSecondary,
                  ),
                ),
              ),
              if (!isCurrentMonth)
                BouncyTap(
                  onTap: _jumpToToday,
                  scaleFraction: 0.90,
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.primary, width: 1.2),
                    ),
                    child: Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: theme.text,
                onPressed: () => _changeMonth(-1),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: theme.text,
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. WEEKDAY HEADER ROW (Sun = Pure Red)
  // ---------------------------------------------------------------------------
  Widget _buildWeekdayHeader(StationeryTheme theme) {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      children: List.generate(7, (idx) {
        final isSunday = (idx == 0);
        return Expanded(
          child: Center(
            child: Text(
              weekdays[idx],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSunday ? FontWeight.w800 : FontWeight.w700,
                color: isSunday ? const Color(0xFFE74C3C) : theme.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. MONTH GRID (6 rows x 7 cols)
  // ---------------------------------------------------------------------------
  Widget _buildMonthGrid(StationeryTheme theme, DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOffset = DateTime(month.year, month.month, 1).weekday % 7; // 0=Sun .. 6=Sat
    final prevMonthDays = DateTime(month.year, month.month, 0).day;

    final now = DateTime.now();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (ctx, i) {
        final col = i % 7;
        final isSunday = (col == 0);

        if (i < firstDayOffset) {
          // Previous month padding
          final prevDay = prevMonthDays - firstDayOffset + i + 1;
          return Center(
            child: Text(
              '$prevDay',
              style: TextStyle(
                fontSize: 11,
                color: isSunday ? const Color(0xFFE74C3C).withValues(alpha: 0.3) : theme.textSecondary.withValues(alpha: 0.25),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final dayNum = i - firstDayOffset + 1;
        if (dayNum > daysInMonth) {
          // Next month padding
          final nextDay = dayNum - daysInMonth;
          return Center(
            child: Text(
              '$nextDay',
              style: TextStyle(
                fontSize: 11,
                color: isSunday ? const Color(0xFFE74C3C).withValues(alpha: 0.3) : theme.textSecondary.withValues(alpha: 0.25),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        // Active day in current month
        final cellDate = DateTime(month.year, month.month, dayNum);
        final isToday = (cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day);
        final isSelected = (cellDate.year == _selectedDate.year && cellDate.month == _selectedDate.month && cellDate.day == _selectedDate.day);

        final intlDay = _getIntlDay(cellDate);
        final events = _getEventsForDate(cellDate);
        final hasPersonal = events.isNotEmpty;

        // Container decoration logic as requested:
        // "uss day ko Uss chote date container ko Ui colour ka bana do baaki ke number Ui theme colour ke honge or sunday ka font ya number red hoga id uss din koi special ocation aata hai to number red but uska chota container Ui theme colour ka"
        Color containerBg;
        Border border;

        if (intlDay != null) {
          containerBg = theme.primary.withValues(alpha: isSelected ? 0.26 : 0.16);
          border = Border.all(
            color: theme.primary,
            width: isSelected ? 2.0 : 1.2,
          );
        } else if (isSelected) {
          containerBg = theme.primary.withValues(alpha: 0.10);
          border = Border.all(color: theme.primary, width: 2.0);
        } else if (isToday) {
          containerBg = theme.cardBg;
          border = Border.all(color: theme.primary.withValues(alpha: 0.6), width: 1.4);
        } else {
          containerBg = theme.cardBg;
          border = Border.all(color: theme.border.withValues(alpha: 0.5), width: 0.8);
        }

        // Number color logic:
        // Sunday is ALWAYS pure red!
        Color numColor;
        if (isSunday) {
          numColor = const Color(0xFFE74C3C); // Pure Red
        } else if (intlDay != null) {
          numColor = theme.primary;
        } else {
          numColor = theme.text;
        }

        return BouncyTap(
          onTap: () {
            SoundService().playClick();
            setState(() => _selectedDate = cellDate);
          },
          scaleFraction: 0.92,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: (isSunday || isToday || intlDay != null || isSelected) ? FontWeight.w800 : FontWeight.w600,
                    color: numColor,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (intlDay != null)
                      Icon(
                        intlDay.icon,
                        size: 11,
                        color: isSunday ? const Color(0xFFE74C3C) : theme.primary,
                      ),
                    if (intlDay != null && hasPersonal) const SizedBox(width: 2),
                    if (hasPersonal)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: events.first.tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. SELECTED DATE DETAILS, CELEBRATION BANNER & PERSONAL NOTES LIST
  // ---------------------------------------------------------------------------
  Widget _buildSelectedDateDetails(StationeryTheme theme) {
    final intlDay = _getIntlDay(_selectedDate);
    final events = _getEventsForDate(_selectedDate);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);
    final isSunday = (_selectedDate.weekday == 7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_note_rounded,
                    size: 18,
                    color: isSunday ? const Color(0xFFE74C3C) : theme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSunday ? const Color(0xFFE74C3C) : theme.text,
                    ),
                  ),
                ],
              ),
              BouncyTap(
                onTap: () => _openAddEventModal(),
                scaleFraction: 0.92,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'Add Note',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // International Celebration Day Card
          if (intlDay != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.primary, width: 1.4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(intlDay.icon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                intlDay.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Global Observance',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          intlDay.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Personal Notes & Reminders List
          if (events.isEmpty) ...[
            if (intlDay == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    ToolerCharacter(
                      pose: ToolerCharacterPose.projectRoadmap,
                      theme: theme,
                      width: 140,
                      height: 105,
                      animate: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No personal notes or reminders for this date.\nTap "+ Add Note" to plan Birthdays, Anniversaries or Tasks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: theme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Text(
              'Personal Notes & Reminders (${events.length}):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.textSecondary),
            ),
            const SizedBox(height: 6),
            ...events.map((event) {
              final reminderStr = DateFormat('hh:mm a').format(DateTime(2026, 1, 1, event.reminderHour, event.reminderMinute));
              String repeatStr = 'One-Time';
              if (event.repeat == 'yearly') repeatStr = 'Repeats Annually';
              if (event.repeat == 'monthly') repeatStr = 'Repeats Monthly';
              if (event.repeat == 'weekly') repeatStr = 'Repeats Weekly';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: event.tagColor.withValues(alpha: 0.5), width: 1.2),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        event.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: event.isCompleted ? const Color(0xFF27AE60) : theme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => _toggleEventComplete(event),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(event.tagIcon, size: 14, color: event.tagColor),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.text,
                                    decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: event.tagColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  event.tag,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: event.tagColor),
                                ),
                              ),
                            ],
                          ),
                          if (event.note.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              event.note,
                              style: TextStyle(fontSize: 11, color: theme.textSecondary, height: 1.3),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.alarm_rounded, size: 12, color: theme.textSecondary),
                              const SizedBox(width: 3),
                              Text(reminderStr, style: TextStyle(fontSize: 10, color: theme.textSecondary, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 10),
                              Icon(Icons.repeat_rounded, size: 12, color: theme.textSecondary),
                              const SizedBox(width: 3),
                              Text(repeatStr, style: TextStyle(fontSize: 10, color: theme.primary, fontWeight: FontWeight.w600)),
                              if (event.addToTasks) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.task_alt_rounded, size: 12, color: Color(0xFF27AE60)),
                                const SizedBox(width: 2),
                                const Text('Synced to Tasks', style: TextStyle(fontSize: 10, color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE74C3C)),
                      onPressed: () => _deleteEvent(event),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
