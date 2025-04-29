class Attendance {
  final String id;
  final String uid;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String type; 

  Attendance({
    required this.id,
    required this.uid,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map, String id) {
    return Attendance(
      id: id,
      uid: map['uid'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'] ?? '',
    );
  }
}