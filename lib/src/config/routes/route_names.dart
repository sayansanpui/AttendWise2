/// Constants for route paths used throughout the app
class RouteNames {
  // Private constructor to prevent instantiation
  RouteNames._();

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';

  // Admin Routes
  static const String adminDashboard = '/admin';
  static const String adminManageClasses = '/admin/classes';
  static const String adminManageTeachers = '/admin/teachers';
  static const String adminManageStudents = '/admin/students';
  static const String adminReports = '/admin/reports';

  // Teacher Routes
  static const String teacherDashboard = '/teacher';
  static const String teacherClasses = '/teacher/classes';
  static const String teacherTakeAttendance = '/teacher/attendance';
  static const String teacherAttendanceHistory = '/teacher/attendance-history';
  static const String teacherClassStatistics = '/teacher/statistics';
  static const String teacherClassroomDetail = '/teacher/classroom-detail';
  static const String teacherClassrooms = '/teacher/classrooms';

  // Student Routes
  static const String studentDashboard = '/student';
  static const String studentAttendanceHistory = '/student/attendance-history';
  static const String studentSchedule = '/student/schedule';
  static const String studentClassrooms = '/student/classrooms';
  static const String studentClassroomDetail = '/student/classroom-detail';
  static const String studentAttendance = '/student/attendance';

  // Shared Routes
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  static const String adminUsers = '/admin/users';

  static const String adminDepartments = '/admin/departments';

  static const String adminSettings = '/admin/settings';
}
