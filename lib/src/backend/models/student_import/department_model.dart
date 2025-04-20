import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a department in the institution
class DepartmentModel {
  final String departmentId; // Department ID (e.g., CSE, IT, ECE)
  final String name; // Full name (e.g., Computer Science & Engineering)
  final String? hodUid; // UID of Head of Department
  final List<String> sections; // Array of sections (e.g., ["A", "B", "C"])
  final List<String>
      specializations; // Array of specializations (e.g., ["AIML", "DS", "IOT"])
  final Timestamp createdAt; // Creation timestamp
  final Timestamp updatedAt; // Last update timestamp

  DepartmentModel({
    required this.departmentId,
    required this.name,
    this.hodUid,
    required this.sections,
    required this.specializations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      departmentId: json['departmentId'] as String,
      name: json['name'] as String,
      hodUid: json['hodUid'] as String?,
      sections: List<String>.from(json['sections'] as List),
      specializations: List<String>.from(json['specializations'] as List),
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'name': name,
      'hodUid': hodUid,
      'sections': sections,
      'specializations': specializations,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  DepartmentModel copyWith({
    String? departmentId,
    String? name,
    String? hodUid,
    List<String>? sections,
    List<String>? specializations,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return DepartmentModel(
      departmentId: departmentId ?? this.departmentId,
      name: name ?? this.name,
      hodUid: hodUid ?? this.hodUid,
      sections: sections ?? this.sections,
      specializations: specializations ?? this.specializations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
