import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String submissionId;
  final String postId;
  final String studentId;
  final List<String> submissionUrls;
  final Timestamp submittedAt;
  final double? grade;
  final String? feedback;
  final String? gradedBy;
  final Timestamp? gradedAt;

  SubmissionModel({
    required this.submissionId,
    required this.postId,
    required this.studentId,
    required this.submissionUrls,
    required this.submittedAt,
    this.grade,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      submissionId: json['submissionId'] as String,
      postId: json['postId'] as String,
      studentId: json['studentId'] as String,
      submissionUrls: List<String>.from(json['submissionUrls'] as List),
      submittedAt: json['submittedAt'] as Timestamp,
      grade: json['grade'] as double?,
      feedback: json['feedback'] as String?,
      gradedBy: json['gradedBy'] as String?,
      gradedAt: json['gradedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submissionId': submissionId,
      'postId': postId,
      'studentId': studentId,
      'submissionUrls': submissionUrls,
      'submittedAt': submittedAt,
      'grade': grade,
      'feedback': feedback,
      'gradedBy': gradedBy,
      'gradedAt': gradedAt,
    };
  }

  SubmissionModel copyWith({
    String? submissionId,
    String? postId,
    String? studentId,
    List<String>? submissionUrls,
    Timestamp? submittedAt,
    double? grade,
    String? feedback,
    String? gradedBy,
    Timestamp? gradedAt,
  }) {
    return SubmissionModel(
      submissionId: submissionId ?? this.submissionId,
      postId: postId ?? this.postId,
      studentId: studentId ?? this.studentId,
      submissionUrls: submissionUrls ?? this.submissionUrls,
      submittedAt: submittedAt ?? this.submittedAt,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
    );
  }
}
