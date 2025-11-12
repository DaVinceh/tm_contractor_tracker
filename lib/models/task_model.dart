class Task {
  final String id;
  final String teamId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final double completionPercentage;
  final String status; // pending, in_progress, completed
  final String createdBy; // SO or higher who created the task
  final DateTime createdAt;

  // New fields for project tracking
  final String? projectNumber;
  final String? projectId;
  final String? exchange;
  final String? state;
  final String? tmNote;
  final String? program;
  final String? lorId;
  final String priority; // high, medium, low

  Task({
    required this.id,
    required this.teamId,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.completionPercentage,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.projectNumber,
    this.projectId,
    this.exchange,
    this.state,
    this.tmNote,
    this.program,
    this.lorId,
    this.priority = 'medium',
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: _parseDateTime(json['start_date']),
      endDate:
          json['end_date'] != null ? _parseDateTime(json['end_date']) : null,
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
      status: json['status'] as String,
      createdBy: json['created_by'] as String,
      createdAt: _parseDateTime(json['created_at']),
      projectNumber: json['project_number'] as String?,
      projectId: json['project_id'] as String?,
      exchange: json['exchange'] as String?,
      state: json['state'] as String?,
      tmNote: json['tm_note'] as String?,
      program: json['program'] as String?,
      lorId: json['lor_id'] as String?,
      priority: json['priority'] as String? ?? 'medium',
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
      'team_id': teamId,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'completion_percentage': completionPercentage,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'project_number': projectNumber,
      'project_id': projectId,
      'exchange': exchange,
      'state': state,
      'tm_note': tmNote,
      'program': program,
      'lor_id': lorId,
      'priority': priority,
    };
  }
}
