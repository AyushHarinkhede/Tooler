class CalcHistoryItem {
  final String expression;
  final String result;
  final DateTime timestamp;

  CalcHistoryItem({
    required this.expression,
    required this.result,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'result': result,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CalcHistoryItem.fromJson(Map<String, dynamic> json) =>
      CalcHistoryItem(
        expression: json['expression'] as String,
        result: json['result'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}
