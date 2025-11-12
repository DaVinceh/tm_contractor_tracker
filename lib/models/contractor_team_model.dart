class ContractorTeam {
  final String id;
  final String teamId;
  final String leaderName;
  final String soId; // Site Officer managing this team
  final DateTime createdAt;

  ContractorTeam({
    required this.id,
    required this.teamId,
    required this.leaderName,
    required this.soId,
    required this.createdAt,
  });

  factory ContractorTeam.fromJson(Map<String, dynamic> json) {
    return ContractorTeam(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      leaderName: json['leader_name'] as String,
      soId: json['so_id'] as String,
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
      'team_id': teamId,
      'leader_name': leaderName,
      'so_id': soId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
