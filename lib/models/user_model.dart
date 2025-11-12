enum UserRole {
  contractor,
  so, // Site Officer
  executive,
  gmAgm, // GM/AGM
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final String name;
  final String? teamId; // For contractors
  final String?
      managerId; // For SO (reports to Executive), For Executive (reports to GM/AGM)
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.teamId,
    this.managerId,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
      ),
      name: json['name'] as String,
      teamId: json['team_id'] as String?,
      managerId: json['manager_id'] as String?,
      createdAt: _parseDateTime(json['created_at']),
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
      'email': email,
      'role': role.toString().split('.').last,
      'name': name,
      'team_id': teamId,
      'manager_id': managerId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
