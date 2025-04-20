import 'package:cloud_firestore/cloud_firestore.dart';

enum ClassType { theory, lab }

class ClassroomModel {
  final String classroomId;
  final String classCode;
  final String subjectCode;
  final String subjectName;
  final String section;
  final int year;
  final int semester;
  final String stream;
  final ClassType classType;
  final String createdBy;
  final Timestamp createdAt;
  final bool isActive;

  ClassroomModel({
    required this.classroomId,
    required this.classCode,
    required this.subjectCode,
    required this.subjectName,
    required this.section,
    required this.year,
    required this.semester,
    required this.stream,
    required this.classType,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      classroomId: json['classroomId'] as String,
      classCode: json['classCode'] as String,
      subjectCode: json['subjectCode'] as String,
      subjectName: json['subjectName'] as String,
      section: json['section'] as String,
      year: json['year'] as int,
      semester: json['semester'] as int,
      stream: json['stream'] as String,
      classType: _stringToClassType(json['classType'] as String),
      createdBy: json['createdBy'] as String,
      createdAt: json['createdAt'] as Timestamp,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classroomId': classroomId,
      'classCode': classCode,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'section': section,
      'year': year,
      'semester': semester,
      'stream': stream,
      'classType': _classTypeToString(classType),
      'createdBy': createdBy,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  static ClassType _stringToClassType(String typeStr) {
    switch (typeStr) {
      case 'theory':
        return ClassType.theory;
      case 'lab':
        return ClassType.lab;
      default:
        throw ArgumentError('Invalid class type: $typeStr');
    }
  }

  static String _classTypeToString(ClassType type) {
    switch (type) {
      case ClassType.theory:
        return 'theory';
      case ClassType.lab:
        return 'lab';
    }
  }

  ClassroomModel copyWith({
    String? classroomId,
    String? classCode,
    String? subjectCode,
    String? subjectName,
    String? section,
    int? year,
    int? semester,
    String? stream,
    ClassType? classType,
    String? createdBy,
    Timestamp? createdAt,
    bool? isActive,
  }) {
    return ClassroomModel(
      classroomId: classroomId ?? this.classroomId,
      classCode: classCode ?? this.classCode,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      section: section ?? this.section,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      stream: stream ?? this.stream,
      classType: classType ?? this.classType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
