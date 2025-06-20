import '../services/auth_service.dart';

class Permission {
  final String id;
  final String uid;
  final String nama;
  final DateTime fromDate;
  final DateTime toDate;
  final int duration;
  final String notes;
  final String? fileUrl;
  final String type;
  final String status;
  final DateTime submissionDate;
  final String? reviewedBy;
  final String? reviewNotes;

  static var storage;

  Permission({
    required this.id,
    required this.uid,
    required this.nama,
    required this.fromDate,
    required this.toDate,
    required this.duration,
    required this.notes,
    this.fileUrl,
    required this.type,
    required this.status,
    required this.submissionDate,
    this.reviewedBy,
    this.reviewNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'nama': nama,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'duration': duration,
      'notes': notes,
      'fileUrl': fileUrl,
      'type': type,
      'status': status,
      'submissionDate': submissionDate.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
    };
  }

  factory Permission.fromMap(Map<String, dynamic> map, String id) {
    final authService = AuthService(); // Untuk fallback ke getUserData jika nama tidak ada
    return Permission(
      id: id,
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? (map['uid'] != null ? (authService.getUserData(map['uid']).then((data) => data?['nama'] ?? 'Unknown')) as String : 'Unknown'),
      fromDate: DateTime.parse(map['fromDate']),
      toDate: DateTime.parse(map['toDate']),
      duration: map['duration'] ?? 0,
      notes: map['notes'] ?? '',
      fileUrl: map['fileUrl'],
      type: map['type'] ?? '',
      status: map['status'] ?? 'Pending',
      submissionDate: DateTime.parse(map['submissionDate']),
      reviewedBy: map['reviewedBy'],
      reviewNotes: map['reviewNotes'],
    );
  }
}