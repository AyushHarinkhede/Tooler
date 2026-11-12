import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../models/task_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets_3d/bouncy_tap.dart';
import '../widgets_3d/tooler_character.dart';

class TasksScreen extends StatefulWidget {
  final StationeryTheme theme;
  const TasksScreen({super.key, required this.theme});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskItem> _tasks = [];
  final TextEditingController _taskCtrl = TextEditingController();
  String _selectedCategory = 'School';
  String _selectedPriority = 'Medium';
  String _filter = 'All'; // 'All', 'Pending', 'Done'
  DateTime? _selectedDueDateTime;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final list = await StorageService().loadTasks();
    setState(() => _tasks = list);
  }

  void _pickDueDateTime() async {
    SoundService().playClick();
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: widget.theme.primary,
              primary: widget.theme.primary,
              surface: widget.theme.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDueDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDueDateTime!)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: widget.theme.primary,
              primary: widget.theme.primary,
              surface: widget.theme.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDueDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _addTask() {
    final text = _taskCtrl.text.trim();
    if (text.isEmpty) return;

    SoundService().playSpecialClick();
    final newId = DateTime.now().millisecondsSinceEpoch;
    final newTask = TaskItem(
      id: newId,
      text: text,
      category: _selectedCategory,
      priority: _selectedPriority,
      dueDateTime: _selectedDueDateTime,
    );

    setState(() {
      _tasks.insert(0, newTask);
      _taskCtrl.clear();
      _selectedDueDateTime = null;
    });

    StorageService().saveTasks(_tasks);

    // Schedule background reminder notification if due date is set in future
    if (newTask.dueDateTime != null && newTask.dueDateTime!.isAfter(DateTime.now())) {
      NotificationService().scheduleTaskReminder(
        taskId: newId,
        taskTitle: text,
        dueDateTime: newTask.dueDateTime!,
      );
    }
  }

  void _toggleTask(int id) {
    setState(() {
      final t = _tasks.firstWhere((item) => item.id == id);
      t.completed = !t.completed;
      if (t.completed) {
        SoundService().playTaskComplete();
        NotificationService().cancelTaskReminder(id);
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
    StorageService().saveTasks(_tasks);
  }

  void _removeTask(int id) {
    SoundService().playAlert();
    NotificationService().cancelTaskReminder(id);
    setState(() {
      _tasks.removeWhere((item) => item.id == id);
    });
    StorageService().saveTasks(_tasks);
  }

  List<TaskItem> get _filteredTasks {
    if (_filter == 'Pending') return _tasks.where((t) => !t.completed).toList();
    if (_filter == 'Done') return _tasks.where((t) => t.completed).toList();
    return _tasks;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFFF4757);
      case 'Medium':
        return const Color(0xFFFFA502);
      case 'Low':
      default:
        return const Color(0xFF2ED573);
    }
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
    }
    return DateFormat('MMM d, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
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
                // Add Task Input Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: widget.theme.doodleCard(borderWidth: 2.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _taskCtrl,
                          style: widget.theme.fontDoodle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Write a new task (e.g. Science Project)",
                            hintStyle: widget.theme.fontDoodle(
                              fontSize: 14,
                              color: widget.theme.text.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                        const SizedBox(height: 8),

                        // Due Date Picker & Category Row
                        Row(
                          children: [
                            // Due Date Button
                            BouncyTap(
                              onTap: _pickDueDateTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _selectedDueDateTime != null
                                      ? widget.theme.lavenderCard
                                      : widget.theme.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedDueDateTime != null
                                        ? widget.theme.primary
                                        : widget.theme.border,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 13,
                                      color: _selectedDueDateTime != null
                                          ? widget.theme.primary
                                          : widget.theme.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _selectedDueDateTime != null
                                          ? _formatDueDate(_selectedDueDateTime!)
                                          : 'Set Due Time',
                                      style: widget.theme.fontMono(
                                        fontSize: 11,
                                        fontWeight: _selectedDueDateTime != null
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: _selectedDueDateTime != null
                                            ? widget.theme.primary
                                            : widget.theme.textSecondary,
                                      ),
                                    ),
                                    if (_selectedDueDateTime != null) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          SoundService().playClick();
                                          setState(() => _selectedDueDateTime = null);
                                        },
                                        child: Icon(Icons.close_rounded,
                                            size: 14, color: widget.theme.primary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),

                            // Category Selector
                            DropdownButton<String>(
                              value: _selectedCategory,
                              dropdownColor: widget.theme.cardBg,
                              style: widget.theme.fontMono(fontSize: 12, color: widget.theme.text),
                              underline: const SizedBox(),
                              items: ['School', 'Homework', 'Project', 'Personal'].map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                            const SizedBox(width: 8),

                            // Priority Selector
                            DropdownButton<String>(
                              value: _selectedPriority,
                              dropdownColor: widget.theme.cardBg,
                              style: widget.theme.fontMono(
                                fontSize: 12,
                                color: _getPriorityColor(_selectedPriority),
                                fontWeight: FontWeight.bold,
                              ),
                              underline: const SizedBox(),
                              items: ['High', 'Medium', 'Low'].map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    style: TextStyle(color: _getPriorityColor(p)),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPriority = val);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.theme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _addTask,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Save Task"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter Tabs (All, Pending, Done)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: ['All', 'Pending', 'Done'].map((f) {
                      final isSelected = (_filter == f);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            f,
                            style: widget.theme.fontMono(
                              fontSize: 12,
                              color: isSelected ? Colors.white : widget.theme.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: widget.theme.primary,
                          backgroundColor: widget.theme.cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: widget.theme.border, width: 1.5),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _filter = f);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Tasks List
                Expanded(
                  child: _filteredTasks.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ToolerCharacter.celebrating(
                                  theme: widget.theme,
                                  width: 170,
                                  height: 150,
                                  animate: true,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _filter == 'Done'
                                      ? "No completed tasks yet!\nCheck off a task to celebrate!"
                                      : "All tasks done!\nEnjoy your free time!",
                                  textAlign: TextAlign.center,
                                  style: widget.theme.fontDoodle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.theme.text.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final t = _filteredTasks[index];
                            final isOverdue = t.dueDateTime != null &&
                                t.dueDateTime!.isBefore(DateTime.now()) &&
                                !t.completed;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: widget.theme.doodleCard(
                                color: t.completed
                                    ? widget.theme.cardBg.withValues(alpha: 0.6)
                                    : widget.theme.cardBg,
                                borderWidth: 1.8,
                              ),
                              child: Row(
                                children: [
                                  // Hand-drawn check box
                                  Checkbox(
                                    value: t.completed,
                                    activeColor: widget.theme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (_) => _toggleTask(t.id),
                                  ),
                                  const SizedBox(width: 8),

                                  // Task Text & Meta
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.text,
                                          style: widget.theme.fontDoodle(
                                            fontSize: 16,
                                            color: t.completed
                                                ? widget.theme.text.withValues(alpha: 0.5)
                                                : widget.theme.text,
                                          ).copyWith(
                                            decoration: t.completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: widget.theme.bg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                t.category,
                                                style: widget.theme.fontMono(fontSize: 10),
                                              ),
                                            ),
                                            CircleAvatar(
                                              radius: 4,
                                              backgroundColor: _getPriorityColor(t.priority),
                                            ),
                                            if (t.dueDateTime != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isOverdue
                                                      ? Colors.red.withValues(alpha: 0.12)
                                                      : widget.theme.primary.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isOverdue
                                                        ? Colors.red
                                                        : widget.theme.primary,
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.alarm,
                                                      size: 10,
                                                      color: isOverdue
                                                          ? Colors.red
                                                          : widget.theme.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatDueDate(t.dueDateTime!),
                                                      style: widget.theme.fontMono(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: isOverdue
                                                            ? Colors.red
                                                            : widget.theme.primary,
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

                                  // Delete
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: Colors.red.shade400,
                                    onPressed: () => _removeTask(t.id),
                                  ),
                                ],
                              ),
                            );
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
}
