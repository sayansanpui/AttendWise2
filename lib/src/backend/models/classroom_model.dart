import 'package:cloud_firestore/cloud_firestore.dart';

enum ClassroomStatus { active, archived, completed }

class ClassroomModel {
  final String classroomId;
  final String name;
  final String code;
  final String teacherId;
  final String room;
  final String level;
  final String year;
  final String semester;
  final String time;
  final int totalSessions;
  final int completedSessions;
  final double attendanceRate;
  final int studentCount;
  final ClassroomStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClassroomModel({
    required this.classroomId,
    required this.name,
    required this.code,
    required this.teacherId,
    required this.room,
    required this.level,
    required this.year,
    required this.semester,
    required this.time,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.attendanceRate = 0.0,
    this.studentCount = 0,
    this.status = ClassroomStatus.active,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'classroomId': classroomId,
      'name': name,
      'code': code,
      'teacherId': teacherId,
      'room': room,
      'level': level,
      'year': year,
      'semester': semester,
      'time': time,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'attendanceRate': attendanceRate,
      'studentCount': studentCount,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      classroomId: json['classroomId'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      teacherId: json['teacherId'] as String,
      room: json['room'] as String,
      level: json['level'] as String,
      year: json['year'] as String,
      semester: json['semester'] as String,
      time: json['time'] as String,
      totalSessions: json['totalSessions'] as int? ?? 0,
      completedSessions: json['completedSessions'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
      studentCount: json['studentCount'] as int? ?? 0,
      status: ClassroomStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ClassroomStatus.active,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  ClassroomModel copyWith({
    String? classroomId,
    String? name,
    String? code,
    String? teacherId,
    String? room,
    String? level,
    String? year,
    String? semester,
    String? time,
    int? totalSessions,
    int? completedSessions,
    double? attendanceRate,
    int? studentCount,
    ClassroomStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassroomModel(
      classroomId: classroomId ?? this.classroomId,
      name: name ?? this.name,
      code: code ?? this.code,
      teacherId: teacherId ?? this.teacherId,
      room: room ?? this.room,
      level: level ?? this.level,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      time: time ?? this.time,
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      studentCount: studentCount ?? this.studentCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
