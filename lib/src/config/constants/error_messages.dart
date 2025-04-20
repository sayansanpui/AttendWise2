/// Standardized error messages for the AttendWise app
class ErrorMessages {
  // Authentication Errors
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPassword =
      'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String loginFailed =
      'Login failed. Please check your credentials and try again';
  static const String userNotFound =
      'User not found. Please check your email or contact administrator';
  static const String emailAlreadyInUse = 'This email is already in use';
  static const String weakPassword =
      'Password is too weak. Please use a stronger password';
  static const String accountDisabled =
      'This account has been disabled. Please contact administrator';

  // Network Errors
  static const String networkError =
      'Network error. Please check your connection and try again';
  static const String serverError = 'Server error. Please try again later';
  static const String timeoutError = 'Request timed out. Please try again';
  static const String unknownError =
      'An unknown error occurred. Please try again';

  // Firestore Errors
  static const String documentNotFound = 'Document not found';
  static const String collectionNotFound = 'Collection not found';
  static const String writeError = 'Failed to write data. Please try again';
  static const String readError = 'Failed to read data. Please try again';

  // Attendance Errors
  static const String sessionExpired = 'Attendance session has expired';
  static const String alreadyMarked =
      'Attendance already marked for this session';
  static const String outsideRange =
      'You are not within the allowed range to mark attendance';
  static const String sessionNotActive = 'No active attendance session found';

  // User Management Errors
  static const String userCreationFailed =
      'Failed to create user. Please try again';
  static const String userUpdateFailed =
      'Failed to update user information. Please try again';
  static const String userDeletionFailed =
      'Failed to delete user. Please try again';
  static const String bulkImportFailed =
      'Failed to import users. Please check your file and try again';

  // Classroom Errors
  static const String classroomCreationFailed =
      'Failed to create classroom. Please try again';
  static const String classroomUpdateFailed =
      'Failed to update classroom. Please try again';
  static const String classroomDeletionFailed =
      'Failed to delete classroom. Please try again';
  static const String invalidClassCode =
      'Invalid class code. Please check and try again';

  // Permission Errors
  static const String insufficientPermissions =
      'You do not have permission to perform this action';
  static const String adminOnlyFeature =
      'This feature is only available to administrators';
  static const String teacherOnlyFeature =
      'This feature is only available to teachers';

  // File Errors
  static const String fileUploadFailed =
      'Failed to upload file. Please try again';
  static const String fileDownloadFailed =
      'Failed to download file. Please try again';
  static const String invalidFileFormat =
      'Invalid file format. Please use a supported format';
  static const String fileTooLarge =
      'File is too large. Please use a smaller file';

  // Form Validation
  static const String requiredField = 'This field is required';
  static const String invalidInput =
      'Invalid input. Please check and try again';
  static const String invalidDate = 'Invalid date. Please enter a valid date';
  static const String invalidTime = 'Invalid time. Please enter a valid time';
  static const String invalidNumber =
      'Invalid number. Please enter a numeric value';
}
