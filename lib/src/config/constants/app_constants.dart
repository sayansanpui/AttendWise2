/// General constants used throughout the AttendWise app
class AppConstants {
  // App Information
  static const String appName = 'AttendWise';
  static const String appVersion = '2.0.4';

  // Collection Names
  static const String usersCollection = 'users';
  static const String departmentsCollection = 'departments';
  static const String classroomsCollection = 'classrooms';
  static const String attendanceSessionsCollection = 'attendance_sessions';
  static const String attendanceRecordsCollection = 'attendance_records';

  // User Roles
  static const String adminRole = 'admin';
  static const String teacherRole = 'teacher';
  static const String studentRole = 'student';

  // Attendance Status
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusLate = 'late';
  static const String statusExcused = 'excused';

  // Time Constants
  static const int sessionTimeoutMinutes = 60;
  static const int attendanceMarkingWindowMinutes = 15;

  // Default Values
  static const int defaultPageSize = 20;
  static const double defaultAttendanceThreshold = 75.0;

  // Cache Keys
  static const String userProfileCacheKey = 'user_profile';
  static const String themeModeKey = 'theme_mode';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 250);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 750);
}
