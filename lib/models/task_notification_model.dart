class TaskNotification {
  final String id;
  final String taskId;
  final String teamId;
  final String title;
  final String message;
  final String changeType; // 'updated', 'deleted', 'restored'
  final Map<String, dynamic>? changes; // Details of what changed
  final DateTime createdAt;
  final bool isRead;

  TaskNotification({
    required this.id,
    required this.taskId,
    required this.teamId,
    required this.title,
    required this.message,
    required this.changeType,
    this.changes,
    required this.createdAt,
    this.isRead = false,
  });

  factory TaskNotification.fromJson(Map<String, dynamic> json) {
    return TaskNotification(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      teamId: json['team_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      changeType: json['change_type'] as String,
      changes: json['changes'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(json['created_at']),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'team_id': teamId,
      'title': title,
      'message': message,
      'change_type': changeType,
      'changes': changes,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
