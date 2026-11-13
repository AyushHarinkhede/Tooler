class SubTaskItem {
  final int id;
  String text;
  bool completed;

  SubTaskItem({
    required this.id,
    required this.text,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
      };

  factory SubTaskItem.fromJson(Map<String, dynamic> json) => SubTaskItem(
        id: json['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        text: json['text'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );
}

class TaskItem {
  final int id;
  String text;
  bool completed;
  String category;
  String priority;
  DateTime? dueDateTime;
  String notes;
  bool isStarred;
  String repeat; // 'None', 'Daily', 'Weekly', 'Monthly'
  List<SubTaskItem> subtasks;
  DateTime createdAt;

  TaskItem({
    required this.id,
    required this.text,
    this.completed = false,
    this.category = 'Personal',
    this.priority = 'Medium',
    this.dueDateTime,
    this.notes = '',
    this.isStarred = false,
    this.repeat = 'None',
    List<SubTaskItem>? subtasks,
    DateTime? createdAt,
  })  : subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
        'category': category,
        'priority': priority,
        'dueDateTime': dueDateTime?.toIso8601String(),
        'notes': notes,
        'isStarred': isStarred,
        'repeat': repeat,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as int,
        text: json['text'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
        category: json['category'] as String? ?? 'Personal',
        priority: json['priority'] as String? ?? 'Medium',
        dueDateTime: json['dueDateTime'] != null ? DateTime.tryParse(json['dueDateTime'] as String) : null,
        notes: json['notes'] as String? ?? '',
        isStarred: json['isStarred'] as bool? ?? false,
        repeat: json['repeat'] as String? ?? 'None',
        subtasks: (json['subtasks'] as List<dynamic>?)
                ?.map((e) => SubTaskItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
