import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSessionModel {
  final String sessionId;
  final String classroomId;
  final String teacherId;
  final Timestamp date;
  final int? headCount;
  final Timestamp startTime;
  final Timestamp? endTime;
  final bool isActive;
  final String? notes;

  AttendanceSessionModel({
    required this.sessionId,
    required this.classroomId,
    required this.teacherId,
    required this.date,
    this.headCount,
    required this.startTime,
    this.endTime,
    required this.isActive,
    this.notes,
  });

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      sessionId: json['sessionId'] as String,
      classroomId: json['classroomId'] as String,
      teacherId: json['teacherId'] as String,
      date: json['date'] as Timestamp,
      headCount: json['headCount'] as int?,
      startTime: json['startTime'] as Timestamp,
      endTime: json['endTime'] as Timestamp?,
      isActive: json['isActive'] as bool,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'classroomId': classroomId,
      'teacherId': teacherId,
      'date': date,
      'headCount': headCount,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'notes': notes,
    };
  }

  AttendanceSessionModel copyWith({
    String? sessionId,
    String? classroomId,
    String? teacherId,
    Timestamp? date,
    int? headCount,
    Timestamp? startTime,
    Timestamp? endTime,
    bool? isActive,
    String? notes,
  }) {
    return AttendanceSessionModel(
      sessionId: sessionId ?? this.sessionId,
      classroomId: classroomId ?? this.classroomId,
      teacherId: teacherId ?? this.teacherId,
      date: date ?? this.date,
      headCount: headCount ?? this.headCount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }
}
