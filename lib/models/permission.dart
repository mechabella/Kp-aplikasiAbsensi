class Permission {
  final String id;
  final String uid;
  final String nama;
  final DateTime fromDate;
  final DateTime toDate;
  final int duration;
  final String notes;
  final String fileUrl;
  final String type;
  final String status;
  final DateTime submissionDate;
  final String? reviewedBy;
  final String? reviewNotes;

  Permission({
    required this.id,
    required this.uid,
    required this.nama,
    required this.fromDate,
    required this.toDate,
    required this.duration,
    required this.notes,
    required this.fileUrl,
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
    return Permission(
      id: id,
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      fromDate: DateTime.parse(map['fromDate']),
      toDate: DateTime.parse(map['toDate']),
      duration: map['duration'] ?? 0,
      notes: map['notes'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? 'Pending',
      submissionDate: DateTime.parse(map['submissionDate']),
      reviewedBy: map['reviewedBy'],
      reviewNotes: map['reviewNotes'],
    );
  }
}