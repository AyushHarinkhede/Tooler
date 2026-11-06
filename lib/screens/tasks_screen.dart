import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import '../theme/notebook_painter.dart';
import '../models/task_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final list = await StorageService().loadTasks();
    setState(() => _tasks = list);
  }

  void _addTask() {
    final text = _taskCtrl.text.trim();
    if (text.isEmpty) return;

    SoundService().playClick();
    setState(() {
      _tasks.insert(
        0,
        TaskItem(
          id: DateTime.now().millisecondsSinceEpoch,
          text: text,
          category: _selectedCategory,
          priority: _selectedPriority,
        ),
      );
      _taskCtrl.clear();
    });
    StorageService().saveTasks(_tasks);
  }

  void _toggleTask(int id) {
    SoundService().playKey();
    setState(() {
      final t = _tasks.firstWhere((item) => item.id == id);
      t.completed = !t.completed;
    });
    StorageService().saveTasks(_tasks);
  }

  void _removeTask(int id) {
    SoundService().playAlert();
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
                              color: widget.theme.text.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
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
                            const Spacer(),
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
                              label: const Text("Save"),
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
                          child: Text(
                            "No tasks found!\nEnjoy your free time!",
                            textAlign: TextAlign.center,
                            style: widget.theme.fontDoodle(
                              fontSize: 18,
                              color: widget.theme.text.withOpacity(0.6),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final t = _filteredTasks[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: widget.theme.doodleCard(
                                color: t.completed
                                    ? widget.theme.cardBg.withOpacity(0.6)
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

                                  // Task Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.text,
                                          style: widget.theme.fontDoodle(
                                            fontSize: 16,
                                            color: t.completed
                                                ? widget.theme.text.withOpacity(0.5)
                                                : widget.theme.text,
                                          ).copyWith(
                                            decoration: t.completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: widget.theme.bg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                t.category,
                                                style: widget.theme.fontMono(fontSize: 10),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            CircleAvatar(
                                              radius: 4,
                                              backgroundColor: _getPriorityColor(t.priority),
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
