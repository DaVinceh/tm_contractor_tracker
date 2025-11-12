class TaskUpdate {
  final String id;
  final String taskId;
  final String userId;
  final String? imageUrl;
  final String comment;
  final DateTime updatedAt;
  final double? progressUpdate; // Updated completion percentage

  TaskUpdate({
    required this.id,
    required this.taskId,
    required this.userId,
    this.imageUrl,
    required this.comment,
    required this.updatedAt,
    this.progressUpdate,
  });

  factory TaskUpdate.fromJson(Map<String, dynamic> json) {
    return TaskUpdate(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String?,
      comment: json['comment'] as String,
      updatedAt: _parseDateTime(json['updated_at']),
      progressUpdate: json['progress_update'] != null
          ? (json['progress_update'] as num).toDouble()
          : null,
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
      'user_id': userId,
      'image_url': imageUrl,
      'comment': comment,
      'updated_at': updatedAt.toIso8601String(),
      'progress_update': progressUpdate,
    };
  }
}
