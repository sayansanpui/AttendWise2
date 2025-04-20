import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String enrollmentId;
  final String studentId;
  final String classroomId;
  final Timestamp enrolledAt;
  final bool isActive;

  EnrollmentModel({
    required this.enrollmentId,
    required this.studentId,
    required this.classroomId,
    required this.enrolledAt,
    required this.isActive,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      enrollmentId: json['enrollmentId'] as String,
      studentId: json['studentId'] as String,
      classroomId: json['classroomId'] as String,
      enrolledAt: json['enrolledAt'] as Timestamp,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enrollmentId': enrollmentId,
      'studentId': studentId,
      'classroomId': classroomId,
      'enrolledAt': enrolledAt,
      'isActive': isActive,
    };
  }

  EnrollmentModel copyWith({
    String? enrollmentId,
    String? studentId,
    String? classroomId,
    Timestamp? enrolledAt,
    bool? isActive,
  }) {
    return EnrollmentModel(
      enrollmentId: enrollmentId ?? this.enrollmentId,
      studentId: studentId ?? this.studentId,
      classroomId: classroomId ?? this.classroomId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
