import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  present,
  absent,
  requested,
  approved,
  rejected,
}

class AttendanceRecordModel {
  final String recordId;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final Timestamp timestamp;
  final int reportCount;
  final String? requestReason;
  final String? verifiedBy;
  final Timestamp? verifiedAt;
  final List<String>? issuedBy;

  AttendanceRecordModel({
    required this.recordId,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.timestamp,
    required this.reportCount,
    this.requestReason,
    this.verifiedBy,
    this.verifiedAt,
    this.issuedBy,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      recordId: json['recordId'] as String,
      sessionId: json['sessionId'] as String,
      studentId: json['studentId'] as String,
      status: _stringToStatus(json['status'] as String),
      timestamp: json['timestamp'] as Timestamp,
      reportCount: json['reportCount'] as int? ?? 0,
      requestReason: json['requestReason'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] as Timestamp?,
      issuedBy: json['issuedBy'] != null
          ? List<String>.from(json['issuedBy'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'sessionId': sessionId,
      'studentId': studentId,
      'status': _statusToString(status),
      'timestamp': timestamp,
      'reportCount': reportCount,
      'requestReason': requestReason,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt,
      'issuedBy': issuedBy,
    };
  }

  static AttendanceStatus _stringToStatus(String statusStr) {
    switch (statusStr) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'requested':
        return AttendanceStatus.requested;
      case 'approved':
        return AttendanceStatus.approved;
      case 'rejected':
        return AttendanceStatus.rejected;
      default:
        throw ArgumentError('Invalid attendance status: $statusStr');
    }
  }

  static String _statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.requested:
        return 'requested';
      case AttendanceStatus.approved:
        return 'approved';
      case AttendanceStatus.rejected:
        return 'rejected';
    }
  }

  AttendanceRecordModel copyWith({
    String? recordId,
    String? sessionId,
    String? studentId,
    AttendanceStatus? status,
    Timestamp? timestamp,
    int? reportCount,
    String? requestReason,
    String? verifiedBy,
    Timestamp? verifiedAt,
    List<String>? issuedBy,
  }) {
    return AttendanceRecordModel(
      recordId: recordId ?? this.recordId,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      reportCount: reportCount ?? this.reportCount,
      requestReason: requestReason ?? this.requestReason,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      issuedBy: issuedBy ?? this.issuedBy,
    );
  }
}
