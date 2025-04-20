import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, teacher, student }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String department;
  final String universityId;
  final Timestamp createdAt;
  final Timestamp lastLogin;
  final bool isActive;
  final bool passwordChanged;
  final String? profileImageUrl;
  final String? phoneNumber;
  final List<String>? fcmTokens;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.department,
    required this.universityId,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
    required this.passwordChanged,
    this.profileImageUrl,
    this.phoneNumber,
    this.fcmTokens,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: _stringToRole(json['role'] as String),
      department: json['department'] as String,
      universityId: json['universityId'] as String,
      createdAt: json['createdAt'] as Timestamp,
      lastLogin: json['lastLogin'] as Timestamp,
      isActive: json['isActive'] as bool,
      passwordChanged: json['passwordChanged'] as bool? ?? false,
      profileImageUrl: json['profileImageUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      fcmTokens: json['fcmTokens'] != null
          ? List<String>.from(json['fcmTokens'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': _roleToString(role),
      'department': department,
      'universityId': universityId,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'isActive': isActive,
      'passwordChanged': passwordChanged,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'fcmTokens': fcmTokens,
    };
  }

  static UserRole _stringToRole(String roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      default:
        throw ArgumentError('Invalid role: $roleStr');
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
    }
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? department,
    String? universityId,
    Timestamp? createdAt,
    Timestamp? lastLogin,
    bool? isActive,
    bool? passwordChanged,
    String? profileImageUrl,
    String? phoneNumber,
    List<String>? fcmTokens,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      department: department ?? this.department,
      universityId: universityId ?? this.universityId,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      passwordChanged: passwordChanged ?? this.passwordChanged,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
