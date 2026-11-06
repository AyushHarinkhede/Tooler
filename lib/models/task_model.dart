class TaskItem {
  final int id;
  String text;
  bool completed;
  String category; // 'School', 'Homework', 'Project', 'Personal', 'Focus'
  String priority; // 'High', 'Medium', 'Low'
  DateTime? dueDateTime;

  TaskItem({
    required this.id,
    required this.text,
    this.completed = false,
    this.category = 'School',
    this.priority = 'Medium',
    this.dueDateTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
        'category': category,
        'priority': priority,
        'dueDateTime': dueDateTime?.toIso8601String(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as int,
        text: json['text'] as String,
        completed: json['completed'] as bool? ?? false,
        category: json['category'] as String? ?? 'School',
        priority: json['priority'] as String? ?? 'Medium',
        dueDateTime: json['dueDateTime'] != null ? DateTime.tryParse(json['dueDateTime'] as String) : null,
      );
}
