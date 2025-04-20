import 'package:cloud_firestore/cloud_firestore.dart';
import '../user_model.dart';

/// Model representing a student with extended academic information
class StudentModel {
  final String uid; // Firebase Auth UID
  final String studentId; // College ID (e.g., 2214201001)

  // Personal information
  final String displayName; // Full name of student
  final String email; // College email
  final String? personalEmail; // Personal email
  final String? mobileNumber; // Student's mobile number

  // Academic information
  final String department; // Department (e.g., CSE, IT, ECE)
  final String? section; // Section (e.g., A, B, C)
  final String? specialization; // Specialization if any (e.g., AIML, DS, IOT)
  final String batch; // Batch/Session (e.g., 2022-2026)
  final int currentSemester; // Current semester (e.g., 1)
  final int currentYear; // Current year (e.g., 1)
  final String? stream; // Stream name (e.g., Computer Science & Engineering)

  // Admission details
  final String? entranceExam; // Entrance exam (e.g., WBJEE, JEE-MAIN)
  final int? entranceExamRank; // Rank in entrance exam
  final String? category; // Category (e.g., General, MQ, TFW, DC)
  final Timestamp? admissionDate; // Date of admission
  final String? admissionStatus; // Status (e.g., ADMITTED)

  // Family information
  final String? fatherName; // Father's name
  final String? fatherMobile; // Father's mobile number
  final String? motherName; // Mother's name
  final String? motherMobile; // Mother's mobile number

  // Account information
  final String? defaultPassword; // Default password (hashed)
  final bool passwordChanged; // Whether default password was changed
  final Timestamp accountCreatedAt; // Account creation timestamp
  final Timestamp lastLoginAt; // Last login timestamp
  final bool isActive; // Whether account is active

  // Optional fields
  final String? bloodGroup; // Blood group
  final String? gender; // Gender
  final Timestamp? dateOfBirth; // Date of birth
  final String? address; // Address
  final String? profileImageUrl; // URL to profile image

  StudentModel({
    required this.uid,
    required this.studentId,
    required this.displayName,
    required this.email,
    required this.department,
    required this.batch,
    required this.currentSemester,
    required this.currentYear,
    required this.accountCreatedAt,
    required this.lastLoginAt,
    required this.isActive,
    required this.passwordChanged,
    this.personalEmail,
    this.mobileNumber,
    this.section,
    this.specialization,
    this.stream,
    this.entranceExam,
    this.entranceExamRank,
    this.category,
    this.admissionDate,
    this.admissionStatus,
    this.fatherName,
    this.fatherMobile,
    this.motherName,
    this.motherMobile,
    this.defaultPassword,
    this.bloodGroup,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.profileImageUrl,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      uid: json['uid'] as String,
      studentId: json['studentId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      department: json['department'] as String,
      batch: json['batch'] as String,
      currentSemester: json['currentSemester'] as int,
      currentYear: json['currentYear'] as int,
      accountCreatedAt: json['accountCreatedAt'] as Timestamp,
      lastLoginAt: json['lastLoginAt'] as Timestamp,
      isActive: json['isActive'] as bool,
      passwordChanged: json['passwordChanged'] as bool? ?? false,
      personalEmail: json['personalEmail'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      section: json['section'] as String?,
      specialization: json['specialization'] as String?,
      stream: json['stream'] as String?,
      entranceExam: json['entranceExam'] as String?,
      entranceExamRank: json['entranceExamRank'] as int?,
      category: json['category'] as String?,
      admissionDate: json['admissionDate'] as Timestamp?,
      admissionStatus: json['admissionStatus'] as String?,
      fatherName: json['fatherName'] as String?,
      fatherMobile: json['fatherMobile'] as String?,
      motherName: json['motherName'] as String?,
      motherMobile: json['motherMobile'] as String?,
      defaultPassword: json['defaultPassword'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] as Timestamp?,
      address: json['address'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'studentId': studentId,
      'displayName': displayName,
      'email': email,
      'department': department,
      'batch': batch,
      'currentSemester': currentSemester,
      'currentYear': currentYear,
      'accountCreatedAt': accountCreatedAt,
      'lastLoginAt': lastLoginAt,
      'isActive': isActive,
      'passwordChanged': passwordChanged,
      'personalEmail': personalEmail,
      'mobileNumber': mobileNumber,
      'section': section,
      'specialization': specialization,
      'stream': stream,
      'entranceExam': entranceExam,
      'entranceExamRank': entranceExamRank,
      'category': category,
      'admissionDate': admissionDate,
      'admissionStatus': admissionStatus,
      'fatherName': fatherName,
      'fatherMobile': fatherMobile,
      'motherName': motherName,
      'motherMobile': motherMobile,
      'defaultPassword': defaultPassword,
      'bloodGroup': bloodGroup,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Convert to a user model (simpler model with common fields)
  UserModel toUserModel() {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: UserRole.student,
      department: department,
      universityId: studentId,
      createdAt: accountCreatedAt,
      lastLogin: lastLoginAt,
      isActive: isActive,
      passwordChanged: passwordChanged,
      profileImageUrl: profileImageUrl,
      phoneNumber: mobileNumber,
    );
  }

  /// Create a student model from a basic user model
  static StudentModel fromUserModel(
    UserModel user, {
    required String batch,
    required int currentSemester,
    required int currentYear,
    String? section,
    String? specialization,
    String? personalEmail,
  }) {
    return StudentModel(
      uid: user.uid,
      studentId: user.universityId,
      displayName: user.displayName,
      email: user.email,
      department: user.department,
      batch: batch,
      currentSemester: currentSemester,
      currentYear: currentYear,
      accountCreatedAt: user.createdAt,
      lastLoginAt: user.lastLogin,
      isActive: user.isActive,
      passwordChanged: user.passwordChanged,
      mobileNumber: user.phoneNumber,
      profileImageUrl: user.profileImageUrl,
      section: section,
      specialization: specialization,
      personalEmail: personalEmail,
    );
  }

  StudentModel copyWith({
    String? uid,
    String? studentId,
    String? displayName,
    String? email,
    String? personalEmail,
    String? mobileNumber,
    String? department,
    String? section,
    String? specialization,
    String? batch,
    int? currentSemester,
    int? currentYear,
    String? stream,
    String? entranceExam,
    int? entranceExamRank,
    String? category,
    Timestamp? admissionDate,
    String? admissionStatus,
    String? fatherName,
    String? fatherMobile,
    String? motherName,
    String? motherMobile,
    String? defaultPassword,
    bool? passwordChanged,
    Timestamp? accountCreatedAt,
    Timestamp? lastLoginAt,
    bool? isActive,
    String? bloodGroup,
    String? gender,
    Timestamp? dateOfBirth,
    String? address,
    String? profileImageUrl,
  }) {
    return StudentModel(
      uid: uid ?? this.uid,
      studentId: studentId ?? this.studentId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      personalEmail: personalEmail ?? this.personalEmail,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      department: department ?? this.department,
      section: section ?? this.section,
      specialization: specialization ?? this.specialization,
      batch: batch ?? this.batch,
      currentSemester: currentSemester ?? this.currentSemester,
      currentYear: currentYear ?? this.currentYear,
      stream: stream ?? this.stream,
      entranceExam: entranceExam ?? this.entranceExam,
      entranceExamRank: entranceExamRank ?? this.entranceExamRank,
      category: category ?? this.category,
      admissionDate: admissionDate ?? this.admissionDate,
      admissionStatus: admissionStatus ?? this.admissionStatus,
      fatherName: fatherName ?? this.fatherName,
      fatherMobile: fatherMobile ?? this.fatherMobile,
      motherName: motherName ?? this.motherName,
      motherMobile: motherMobile ?? this.motherMobile,
      defaultPassword: defaultPassword ?? this.defaultPassword,
      passwordChanged: passwordChanged ?? this.passwordChanged,
      accountCreatedAt: accountCreatedAt ?? this.accountCreatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
