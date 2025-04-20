import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String classroomId;
  final String teacherId;
  final String title;
  final String content;
  final List<String>? attachmentUrls;
  final Timestamp createdAt;
  final bool isAssignment;
  final Timestamp? dueDate;
  final int? maxPoints;
  final Timestamp? updatedAt;

  PostModel({
    required this.postId,
    required this.classroomId,
    required this.teacherId,
    required this.title,
    required this.content,
    this.attachmentUrls,
    required this.createdAt,
    required this.isAssignment,
    this.dueDate,
    this.maxPoints,
    this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['postId'] as String,
      classroomId: json['classroomId'] as String,
      teacherId: json['teacherId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      attachmentUrls: json['attachmentUrls'] != null
          ? List<String>.from(json['attachmentUrls'] as List)
          : null,
      createdAt: json['createdAt'] as Timestamp,
      isAssignment: json['isAssignment'] as bool,
      dueDate: json['dueDate'] as Timestamp?,
      maxPoints: json['maxPoints'] as int?,
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'classroomId': classroomId,
      'teacherId': teacherId,
      'title': title,
      'content': content,
      'attachmentUrls': attachmentUrls,
      'createdAt': createdAt,
      'isAssignment': isAssignment,
      'dueDate': dueDate,
      'maxPoints': maxPoints,
      'updatedAt': updatedAt,
    };
  }

  PostModel copyWith({
    String? postId,
    String? classroomId,
    String? teacherId,
    String? title,
    String? content,
    List<String>? attachmentUrls,
    Timestamp? createdAt,
    bool? isAssignment,
    Timestamp? dueDate,
    int? maxPoints,
    Timestamp? updatedAt,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      classroomId: classroomId ?? this.classroomId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      content: content ?? this.content,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      isAssignment: isAssignment ?? this.isAssignment,
      dueDate: dueDate ?? this.dueDate,
      maxPoints: maxPoints ?? this.maxPoints,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
