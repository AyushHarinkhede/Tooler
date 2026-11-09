class CounterItem {
  final int id;
  String name;
  int value;
  int step;

  CounterItem({
    required this.id,
    required this.name,
    this.value = 0,
    this.step = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'value': value,
        'step': step,
      };

  factory CounterItem.fromJson(Map<String, dynamic> json) => CounterItem(
        id: json['id'] as int,
        name: json['name'] as String,
        value: json['value'] as int? ?? 0,
        step: json['step'] as int? ?? 1,
      );
}
