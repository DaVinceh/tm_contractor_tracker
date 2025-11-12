class Attendance {
  final String id;
  final String userId;
  final String teamId;
  final DateTime checkInTime;
  final double latitude;
  final double longitude;
  final String? locationAddress;
  final DateTime date;

  Attendance({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.checkInTime,
    required this.latitude,
    required this.longitude,
    this.locationAddress,
    required this.date,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      teamId: json['team_id'] as String,
      checkInTime: _parseDateTime(json['check_in_time']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationAddress: json['location_address'] as String?,
      date: _parseDateTime(json['date']),
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
      'user_id': userId,
      'team_id': teamId,
      'check_in_time': checkInTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'date': date.toIso8601String(),
    };
  }
}
