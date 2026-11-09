class TaskItem {
  final int id;
  String text;
  bool completed;
  String category; // 'School', 'Homework', 'Project', 'Personal'
  String priority; // 'High', 'Medium', 'Low'

  TaskItem({
    required this.id,
    required this.text,
    this.completed = false,
    this.category = 'School',
    this.priority = 'Medium',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'completed': completed,
        'category': category,
        'priority': priority,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as int,
        text: json['text'] as String,
        completed: json['completed'] as bool? ?? false,
        category: json['category'] as String? ?? 'School',
        priority: json['priority'] as String? ?? 'Medium',
      );
}
