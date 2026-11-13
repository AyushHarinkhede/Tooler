import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../models/task_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_character.dart';

/// ---------------------------------------------------------------------------
/// TOOLER TASKS & NOTES SCREEN (UPGRADED V2)
/// - Zero auto-generated tasks: Only displays what user explicitly creates.
/// - Rich Task & Note Options:
///   1. Multi-line detailed notes & thoughts
///   2. Category tags (Personal, Work, Study, Shopping, Health, Finance, Ideas, Urgent)
///   3. Priority levels (Urgent P1, High P2, Medium P3, Low P4)
///   4. Due date & time with quick shortcuts (Today, Tomorrow, Weekend, Next Week)
///   5. Checklist subtasks with live inline completion
///   6. Star / Favorite priority bookmarking
///   7. Recurrence & Repeat intervals (Daily, Weekdays, Weekly, Monthly)
///   8. Search & multi-criteria filtering (All, Pending, Done, Starred, Today, Overdue)
///   9. Full in-place task editor & stationery notebook aesthetics
/// ---------------------------------------------------------------------------

class TasksScreen extends StatefulWidget {
  final StationeryTheme theme;
  const TasksScreen({super.key, required this.theme});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  // Filter & Search State
  String _selectedStatusFilter = 'All'; // 'All', 'Pending', 'Done', 'Starred', 'Today', 'Overdue'
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Set of expanded task IDs for notes & subtasks preview
  final Set<int> _expandedTaskIds = {};

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Personal', 'icon': Icons.person_rounded, 'color': Color(0xFF6366F1)},
    {'name': 'Work', 'icon': Icons.work_rounded, 'color': Color(0xFF0EA5E9)},
    {'name': 'Study', 'icon': Icons.menu_book_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Health', 'icon': Icons.fitness_center_rounded, 'color': Color(0xFF14B8A6)},
    {'name': 'Finance', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Ideas', 'icon': Icons.lightbulb_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Urgent', 'icon': Icons.bolt_rounded, 'color': Color(0xFFEF4444)},
  ];

  static const List<Map<String, dynamic>> _priorities = [
    {'name': 'Urgent', 'code': 'P1', 'color': Color(0xFFEF4444)},
    {'name': 'High', 'code': 'P2', 'color': Color(0xFFF97316)},
    {'name': 'Medium', 'code': 'P3', 'color': Color(0xFFFBBF24)},
    {'name': 'Low', 'code': 'P4', 'color': Color(0xFF10B981)},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final list = await StorageService().loadTasks();
    if (mounted) {
      setState(() {
        _tasks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _persistTasks() async {
    await StorageService().saveTasks(_tasks);
  }

  // ---------------------------------------------------------------------------
  // FILTERING LOGIC
  // ---------------------------------------------------------------------------
  List<TaskItem> get _filteredTasks {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _tasks.where((t) {
      // 1. Text Search Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = t.text.toLowerCase().contains(q);
        final matchNotes = t.notes.toLowerCase().contains(q);
        final matchCat = t.category.toLowerCase().contains(q);
        final matchSubtasks = t.subtasks.any((s) => s.text.toLowerCase().contains(q));
        if (!matchTitle && !matchNotes && !matchCat && !matchSubtasks) return false;
      }

      // 2. Category Filter
      if (_selectedCategoryFilter != 'All' && t.category != _selectedCategoryFilter) {
        return false;
      }

      // 3. Status Filter
      switch (_selectedStatusFilter) {
        case 'Pending':
          return !t.completed;
        case 'Done':
          return t.completed;
        case 'Starred':
          return t.isStarred;
        case 'Today':
          if (t.dueDateTime == null) return false;
          return t.dueDateTime!.isAfter(todayStart) && t.dueDateTime!.isBefore(todayEnd);
        case 'Overdue':
          if (t.dueDateTime == null || t.completed) return false;
          return t.dueDateTime!.isBefore(now);
        case 'All':
        default:
          return true;
      }
    }).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getCategoryColor(String category) {
    for (final c in _categories) {
      if (c['name'] == category) return c['color'] as Color;
    }
    return widget.theme.primary;
  }

  IconData _getCategoryIcon(String category) {
    for (final c in _categories) {
      if (c['name'] == category) return c['icon'] as IconData;
    }
    return Icons.label_rounded;
  }

  String _formatDueDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(dt.year, dt.month, dt.day);
    final timeStr = DateFormat('hh:mm a').format(dt);

    if (taskDay == today) {
      return 'Today $timeStr';
    } else if (taskDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow $timeStr';
    } else if (taskDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $timeStr';
    }
    return DateFormat('MMM d, hh:mm a').format(dt);
  }

  // ---------------------------------------------------------------------------
  // TASK MUTATIONS
  // ---------------------------------------------------------------------------
  void _toggleTask(int id) {
    setState(() {
      final t = _tasks.firstWhere((item) => item.id == id);
      t.completed = !t.completed;
      if (t.completed) {
        SoundService().playTaskComplete();
        NotificationService().cancelTaskReminder(id);

        // Auto handle repeat recurrence if enabled
        if (t.repeat != 'None' && t.dueDateTime != null) {
          final nextDue = _calculateNextRepeat(t.dueDateTime!, t.repeat);
          final repeatedTask = TaskItem(
            id: DateTime.now().millisecondsSinceEpoch,
            text: t.text,
            category: t.category,
            priority: t.priority,
            notes: t.notes,
            repeat: t.repeat,
            dueDateTime: nextDue,
            subtasks: t.subtasks.map((s) => SubTaskItem(id: DateTime.now().microsecondsSinceEpoch, text: s.text)).toList(),
          );
          _tasks.insert(0, repeatedTask);
          if (nextDue.isAfter(DateTime.now())) {
            NotificationService().scheduleTaskReminder(
              taskId: repeatedTask.id,
              taskTitle: repeatedTask.text,
              dueDateTime: nextDue,
            );
          }
        }
      } else {
        SoundService().playClick();
        if (t.dueDateTime != null && t.dueDateTime!.isAfter(DateTime.now())) {
          NotificationService().scheduleTaskReminder(
            taskId: id,
            taskTitle: t.text,
            dueDateTime: t.dueDateTime!,
          );
        }
      }
    });
    _persistTasks();
  }

  DateTime _calculateNextRepeat(DateTime current, String repeat) {
    switch (repeat) {
      case 'Daily':
        return current.add(const Duration(days: 1));
      case 'Weekdays':
        DateTime next = current.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case 'Weekly':
        return current.add(const Duration(days: 7));
      case 'Monthly':
        return DateTime(current.year, current.month + 1, current.day, current.hour, current.minute);
      default:
        return current.add(const Duration(days: 1));
    }
  }

  void _toggleStar(int id) {
    SoundService().playTap();
    setState(() {
      final t = _tasks.firstWhere((item) => item.id == id);
      t.isStarred = !t.isStarred;
    });
    _persistTasks();
  }

  void _toggleSubtask(int taskId, int subtaskId) {
    setState(() {
      final t = _tasks.firstWhere((item) => item.id == taskId);
      final s = t.subtasks.firstWhere((sub) => sub.id == subtaskId);
      s.completed = !s.completed;
      if (s.completed) {
        SoundService().playClick();
      }
    });
    _persistTasks();
  }

  void _removeTask(int id) {
    SoundService().playAlert();
    NotificationService().cancelTaskReminder(id);
    setState(() {
      _tasks.removeWhere((item) => item.id == id);
      _expandedTaskIds.remove(id);
    });
    _persistTasks();
  }

  // ---------------------------------------------------------------------------
  // TASK EDITOR SHEET (FULL RICH OPTIONS)
  // ---------------------------------------------------------------------------
  void _openTaskEditor({TaskItem? taskToEdit}) {
    SoundService().playClick();
    final isEditing = taskToEdit != null;

    final titleCtrl = TextEditingController(text: taskToEdit?.text ?? '');
    final notesCtrl = TextEditingController(text: taskToEdit?.notes ?? '');
    String selectedCategory = taskToEdit?.category ?? 'Personal';
    String selectedPriority = taskToEdit?.priority ?? 'Medium';
    DateTime? selectedDueDate = taskToEdit?.dueDateTime;
    String selectedRepeat = taskToEdit?.repeat ?? 'None';
    bool isStarred = taskToEdit?.isStarred ?? false;
    final subtasks = List<SubTaskItem>.from(
      taskToEdit?.subtasks.map((s) => SubTaskItem(id: s.id, text: s.text, completed: s.completed)) ?? [],
    );
    final subtaskInputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.theme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final mq = MediaQuery.of(sheetCtx);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: mq.viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 18,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: mq.size.height * 0.88,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEditing ? 'Edit Task & Note' : 'New Task & Note',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: widget.theme.text,
                              ),
                            ),
                            Row(
                              children: [
                                // Star Toggle
                                BouncyTap(
                                  onTap: () {
                                    SoundService().playTap();
                                    setSheetState(() => isStarred = !isStarred);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isStarred
                                          ? const Color(0xFFFBBF24).withValues(alpha: 0.18)
                                          : widget.theme.bg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isStarred
                                            ? const Color(0xFFFBBF24)
                                            : widget.theme.border,
                                      ),
                                    ),
                                    child: Icon(
                                      isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 20,
                                      color: isStarred
                                          ? const Color(0xFFFBBF24)
                                          : widget.theme.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 22),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Title Input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.theme.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: widget.theme.border),
                          ),
                          child: TextField(
                            controller: titleCtrl,
                            autofocus: !isEditing,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: widget.theme.text,
                            ),
                            decoration: InputDecoration(
                              hintText: 'What needs to be done?',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: widget.theme.textSecondary.withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Description / Notes Input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.theme.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: widget.theme.border),
                          ),
                          child: TextField(
                            controller: notesCtrl,
                            maxLines: 3,
                            minLines: 2,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: widget.theme.text,
                            ),
                            decoration: InputDecoration(
                              icon: Icon(Icons.notes_rounded, size: 18, color: widget.theme.textSecondary),
                              hintText: 'Add description, details, checklist notes or links...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: widget.theme.textSecondary.withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Due Date & Shortcuts Section
                        Text(
                          'DUE DATE & TIME',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Quick Date Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildQuickDateChip(
                              label: 'Today',
                              targetDate: DateTime.now(),
                              selectedDate: selectedDueDate,
                              onSelect: (dt) => setSheetState(() => selectedDueDate = dt),
                            ),
                            _buildQuickDateChip(
                              label: 'Tomorrow',
                              targetDate: DateTime.now().add(const Duration(days: 1)),
                              selectedDate: selectedDueDate,
                              onSelect: (dt) => setSheetState(() => selectedDueDate = dt),
                            ),
                            _buildQuickDateChip(
                              label: 'Next Week',
                              targetDate: DateTime.now().add(const Duration(days: 7)),
                              selectedDate: selectedDueDate,
                              onSelect: (dt) => setSheetState(() => selectedDueDate = dt),
                            ),
                            // Custom Picker Button
                            BouncyTap(
                              onTap: () async {
                                SoundService().playClick();
                                final now = DateTime.now();
                                final date = await showDatePicker(
                                  context: sheetCtx,
                                  initialDate: selectedDueDate ?? now,
                                  firstDate: now,
                                  lastDate: DateTime(2035),
                                );
                                if (date == null || !sheetCtx.mounted) return;
                                final time = await showTimePicker(
                                  context: sheetCtx,
                                  initialTime: selectedDueDate != null
                                      ? TimeOfDay.fromDateTime(selectedDueDate!)
                                      : const TimeOfDay(hour: 18, minute: 0),
                                );
                                if (time == null || !sheetCtx.mounted) return;
                                setSheetState(() {
                                  selectedDueDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selectedDueDate != null
                                      ? widget.theme.primary.withValues(alpha: 0.12)
                                      : widget.theme.bg,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: selectedDueDate != null
                                        ? widget.theme.primary
                                        : widget.theme.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_calendar_rounded,
                                      size: 14,
                                      color: selectedDueDate != null
                                          ? widget.theme.primary
                                          : widget.theme.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedDueDate != null
                                          ? _formatDueDate(selectedDueDate!)
                                          : 'Pick Date & Time',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: selectedDueDate != null
                                            ? widget.theme.primary
                                            : widget.theme.text,
                                      ),
                                    ),
                                    if (selectedDueDate != null) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => setSheetState(() => selectedDueDate = null),
                                        child: Icon(Icons.close_rounded,
                                            size: 14, color: widget.theme.primary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Priority Level Section
                        Text(
                          'PRIORITY LEVEL',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _priorities.map((p) {
                            final name = p['name'] as String;
                            final color = p['color'] as Color;
                            final isSel = selectedPriority == name;
                            return BouncyTap(
                              onTap: () {
                                SoundService().playTap();
                                setSheetState(() => selectedPriority = name);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSel ? color.withValues(alpha: 0.16) : widget.theme.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? color : widget.theme.border,
                                    width: isSel ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSel ? color : widget.theme.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Category Tag Section
                        Text(
                          'CATEGORY / TAG',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((c) {
                            final name = c['name'] as String;
                            final icon = c['icon'] as IconData;
                            final color = c['color'] as Color;
                            final isSel = selectedCategory == name;
                            return BouncyTap(
                              onTap: () {
                                SoundService().playTap();
                                setSheetState(() => selectedCategory = name);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? color.withValues(alpha: 0.14) : widget.theme.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? color : widget.theme.border,
                                    width: isSel ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 14, color: isSel ? color : widget.theme.textSecondary),
                                    const SizedBox(width: 5),
                                    Text(
                                      name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                        color: isSel ? color : widget.theme.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Subtasks / Checklist Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SUBTASKS / CHECKLIST (${subtasks.length})',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: widget.theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (subtasks.isNotEmpty) ...[
                          Column(
                            children: subtasks.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final sub = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.theme.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: widget.theme.border),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: sub.completed,
                                      activeColor: widget.theme.primary,
                                      onChanged: (val) {
                                        setSheetState(() => sub.completed = val ?? false);
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        sub.text,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: sub.completed
                                              ? widget.theme.textSecondary
                                              : widget.theme.text,
                                          decoration: sub.completed ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      color: Colors.red.shade400,
                                      onPressed: () {
                                        setSheetState(() => subtasks.removeAt(idx));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        // Add Subtask Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: widget.theme.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: widget.theme.border),
                                ),
                                child: TextField(
                                  controller: subtaskInputCtrl,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '+ Add subtask item...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: widget.theme.textSecondary.withValues(alpha: 0.6),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (val) {
                                    final txt = val.trim();
                                    if (txt.isNotEmpty) {
                                      setSheetState(() {
                                        subtasks.add(SubTaskItem(
                                          id: DateTime.now().microsecondsSinceEpoch,
                                          text: txt,
                                        ));
                                        subtaskInputCtrl.clear();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            BouncyTap(
                              onTap: () {
                                final txt = subtaskInputCtrl.text.trim();
                                if (txt.isNotEmpty) {
                                  SoundService().playTap();
                                  setSheetState(() {
                                    subtasks.add(SubTaskItem(
                                      id: DateTime.now().microsecondsSinceEpoch,
                                      text: txt,
                                    ));
                                    subtaskInputCtrl.clear();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: widget.theme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: widget.theme.primary),
                                ),
                                child: Icon(Icons.add, size: 18, color: widget.theme.primary),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Repeat Recurrence Section
                        Text(
                          'REPEAT SCHEDULE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: widget.theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['None', 'Daily', 'Weekdays', 'Weekly', 'Monthly'].map((rep) {
                            final isSel = selectedRepeat == rep;
                            return BouncyTap(
                              onTap: () {
                                SoundService().playTap();
                                setSheetState(() => selectedRepeat = rep);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? widget.theme.primary.withValues(alpha: 0.14) : widget.theme.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? widget.theme.primary : widget.theme.border,
                                  ),
                                ),
                                child: Text(
                                  rep,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel ? widget.theme.primary : widget.theme.text,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 22),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.theme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                            label: Text(
                              isEditing ? 'Save Changes' : 'Create Task & Note',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () {
                              final text = titleCtrl.text.trim();
                              if (text.isEmpty) return;
                              SoundService().playSpecialClick();

                              final newId = isEditing ? taskToEdit.id : DateTime.now().millisecondsSinceEpoch;
                              final item = TaskItem(
                                id: newId,
                                text: text,
                                completed: isEditing ? taskToEdit.completed : false,
                                category: selectedCategory,
                                priority: selectedPriority,
                                dueDateTime: selectedDueDate,
                                notes: notesCtrl.text.trim(),
                                isStarred: isStarred,
                                repeat: selectedRepeat,
                                subtasks: subtasks,
                              );

                              setState(() {
                                if (isEditing) {
                                  final idx = _tasks.indexWhere((t) => t.id == taskToEdit.id);
                                  if (idx != -1) _tasks[idx] = item;
                                } else {
                                  _tasks.insert(0, item);
                                }
                              });
                              _persistTasks();

                              // Schedule reminder if due in future
                              if (item.dueDateTime != null && item.dueDateTime!.isAfter(DateTime.now())) {
                                NotificationService().scheduleTaskReminder(
                                  taskId: item.id,
                                  taskTitle: item.text,
                                  dueDateTime: item.dueDateTime!,
                                );
                              }

                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickDateChip({
    required String label,
    required DateTime targetDate,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onSelect,
  }) {
    final isSelected = selectedDate != null &&
        selectedDate.year == targetDate.year &&
        selectedDate.month == targetDate.month &&
        selectedDate.day == targetDate.day;

    return BouncyTap(
      onTap: () {
        SoundService().playTap();
        onSelect(DateTime(targetDate.year, targetDate.month, targetDate.day, 18, 0));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.primary.withValues(alpha: 0.14) : widget.theme.bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? widget.theme.primary : widget.theme.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? widget.theme.primary : widget.theme.text,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t.completed).length;
    final totalCount = _tasks.length;
    final filtered = _filteredTasks;

    return Scaffold(
      backgroundColor: widget.theme.bg,
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: NotebookBackgroundPainter(mode: widget.theme.mode),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. Top Header Bar (Stats, Search, New Task Button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasks & Notes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: widget.theme.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalCount == 0
                                ? 'No tasks created yet'
                                : '$completedCount of $totalCount completed (${(totalCount > 0 ? (completedCount / totalCount * 100).round() : 0)}%)',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Search Toggle
                      BouncyTap(
                        onTap: () {
                          SoundService().playTap();
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchQuery = '';
                              _searchCtrl.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isSearching
                                ? widget.theme.primary.withValues(alpha: 0.14)
                                : widget.theme.cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isSearching ? widget.theme.primary : widget.theme.border,
                            ),
                          ),
                          child: Icon(
                            _isSearching ? Icons.close_rounded : Icons.search_rounded,
                            size: 18,
                            color: _isSearching ? widget.theme.primary : widget.theme.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Button
                      BouncyTap(
                        onTap: () => _openTaskEditor(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.theme.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: widget.theme.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Add Task',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar (When Active)
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: widget.theme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.theme.primary.withValues(alpha: 0.5)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: widget.theme.text),
                        decoration: InputDecoration(
                          icon: Icon(Icons.search_rounded, size: 18, color: widget.theme.primary),
                          hintText: 'Search tasks, notes, categories, subtasks...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: widget.theme.textSecondary),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      ),
                    ),
                  ),

                // 2. Status Filter Chips Bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        _buildStatusChip('All', Icons.all_inbox_rounded),
                        _buildStatusChip('Pending', Icons.pending_actions_rounded),
                        _buildStatusChip('Done', Icons.check_circle_outline_rounded),
                        _buildStatusChip('Starred', Icons.star_rounded),
                        _buildStatusChip('Today', Icons.calendar_today_rounded),
                        _buildStatusChip('Overdue', Icons.warning_amber_rounded),
                      ],
                    ),
                  ),
                ),

                // 3. Category Filter Chips Bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        _buildCategoryFilterChip('All'),
                        ..._categories.map((c) => _buildCategoryFilterChip(c['name'] as String)),
                      ],
                    ),
                  ),
                ),

                // 4. Tasks List or Clean Empty State
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: widget.theme.primary,
                          ),
                        )
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return _buildTaskCard(filtered[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER CHIP BUILDERS
  // ---------------------------------------------------------------------------
  Widget _buildStatusChip(String label, IconData icon) {
    final isSel = _selectedStatusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: BouncyTap(
        onTap: () {
          SoundService().playTap();
          setState(() => _selectedStatusFilter = label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? widget.theme.primary : widget.theme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? widget.theme.primary : widget.theme.border,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSel ? Colors.white : widget.theme.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : widget.theme.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip(String cat) {
    final isSel = _selectedCategoryFilter == cat;
    final color = cat == 'All' ? widget.theme.primary : _getCategoryColor(cat);

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: BouncyTap(
        onTap: () {
          SoundService().playTap();
          setState(() => _selectedCategoryFilter = cat);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isSel ? color.withValues(alpha: 0.16) : widget.theme.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? color : widget.theme.border,
              width: isSel ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            cat,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel ? color : widget.theme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE (NO TASKS AUTO-ADDED)
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    final isFiltered = _tasks.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToolerCharacter.celebrating(
              theme: widget.theme,
              width: 160,
              height: 140,
              animate: true,
            ),
            const SizedBox(height: 14),
            Text(
              isFiltered
                  ? 'No tasks found in this view'
                  : 'Your notebook is clean & empty!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: widget.theme.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Try selecting a different status or category filter.'
                  : 'No tasks are added automatically. Tap below to create your first personal task, reminder, or note.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.theme.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            BouncyTap(
              onTap: () => _openTaskEditor(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.theme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Create First Task',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TASK CARD WITH EXPANDABLE NOTES & SUBTASKS
  // ---------------------------------------------------------------------------
  Widget _buildTaskCard(TaskItem t) {
    final now = DateTime.now();
    final isOverdue = t.dueDateTime != null && t.dueDateTime!.isBefore(now) && !t.completed;
    final catColor = _getCategoryColor(t.category);
    final priorityColor = _getPriorityColor(t.priority);
    final isExpanded = _expandedTaskIds.contains(t.id);
    final hasDetails = t.notes.isNotEmpty || t.subtasks.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.completed ? widget.theme.cardBg.withValues(alpha: 0.6) : widget.theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : (t.isStarred ? const Color(0xFFFBBF24).withValues(alpha: 0.6) : widget.theme.border),
          width: isOverdue || t.isStarred ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.theme.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Row: Checkbox, Title, Priority/Category badges, Star, Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                Checkbox(
                  value: t.completed,
                  activeColor: widget.theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (_) => _toggleTask(t.id),
                ),

                // Title & Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: t.completed
                              ? widget.theme.textSecondary.withValues(alpha: 0.6)
                              : widget.theme.text,
                          decoration: t.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Meta badges row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Category Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getCategoryIcon(t.category), size: 11, color: catColor),
                                const SizedBox(width: 4),
                                Text(
                                  t.category,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: catColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Priority Dot Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  t.priority,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: priorityColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Due Date Chip
                          if (t.dueDateTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOverdue
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                    : widget.theme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOverdue ? Icons.warning_amber_rounded : Icons.alarm_rounded,
                                    size: 11,
                                    color: isOverdue ? const Color(0xFFEF4444) : widget.theme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDueDate(t.dueDateTime!),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isOverdue ? const Color(0xFFEF4444) : widget.theme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Repeat Icon
                          if (t.repeat != 'None')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.theme.bg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat_rounded, size: 10, color: widget.theme.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    t.repeat,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: widget.theme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Subtasks Counter
                          if (t.subtasks.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.theme.bg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.checklist_rounded, size: 11, color: widget.theme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${t.subtasks.where((s) => s.completed).length}/${t.subtasks.length}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: widget.theme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Star Button
                BouncyTap(
                  onTap: () => _toggleStar(t.id),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      t.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 20,
                      color: t.isStarred ? const Color(0xFFFBBF24) : widget.theme.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),

                // More Menu Button (Edit / Delete)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: widget.theme.textSecondary),
                  color: widget.theme.cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openTaskEditor(taskToEdit: t);
                    } else if (val == 'delete') {
                      _removeTask(t.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: widget.theme.text),
                          const SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Optional Expandable Content (Notes / Checklist Subtasks)
          if (hasDetails) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: BouncyTap(
                onTap: () {
                  SoundService().playTap();
                  setState(() {
                    if (isExpanded) {
                      _expandedTaskIds.remove(t.id);
                    } else {
                      _expandedTaskIds.add(t.id);
                    }
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: widget.theme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpanded
                          ? 'Hide notes & subtasks'
                          : (t.notes.isNotEmpty && t.subtasks.isNotEmpty
                              ? 'Show notes & ${t.subtasks.length} subtasks'
                              : (t.notes.isNotEmpty ? 'View notes' : 'View ${t.subtasks.length} subtasks')),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (isExpanded) ...[
              // Notes Block
              if (t.notes.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.theme.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.theme.border),
                  ),
                  child: Text(
                    t.notes,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: widget.theme.text.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ),

              // Checklist Subtasks
              if (t.subtasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Column(
                    children: t.subtasks.map((sub) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: sub.completed,
                                activeColor: widget.theme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (_) => _toggleSubtask(t.id, sub.id),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                sub.text,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: sub.completed
                                      ? widget.theme.textSecondary.withValues(alpha: 0.6)
                                      : widget.theme.text,
                                  decoration: sub.completed ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
