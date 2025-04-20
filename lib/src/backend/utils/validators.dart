/// Utility class for validation functions
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    // For stronger password requirements, uncomment below:
    /*
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    */

    return null;
  }

  /// Validate that the field is not empty
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  /// Validate numeric input
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (int.tryParse(value) == null) {
      return '$fieldName must be a number';
    }

    return null;
  }

  /// Validate phone number format
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Allow only digits, spaces, dashes, parentheses and plus sign
    final phoneRegex = RegExp(r'^[0-9\s\-\(\)\+]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    // Ensure it has at least 10 digits
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      return 'Phone number must have at least 10 digits';
    }

    return null;
  }

  /// Validate university ID format (can be customized based on institution)
  static String? validateUniversityId(String? value) {
    if (value == null || value.isEmpty) {
      return 'University ID is required';
    }

    // Example format: Two letters followed by 6 digits
    final idRegex = RegExp(r'^[A-Za-z]{2}\d{6}$');
    if (!idRegex.hasMatch(value)) {
      return 'Please enter a valid university ID (e.g., AB123456)';
    }

    return null;
  }

  /// Validate date format (YYYY-MM-DD)
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }

    // Check format
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Please enter a valid date (YYYY-MM-DD)';
    }

    // Check if it's a valid date
    try {
      final parts = value.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      if (month < 1 || month > 12) {
        return 'Month must be between 1 and 12';
      }

      // Check day based on month
      int daysInMonth;
      if ([4, 6, 9, 11].contains(month)) {
        daysInMonth = 30;
      } else if (month == 2) {
        // Leap year check
        bool isLeapYear =
            (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
        daysInMonth = isLeapYear ? 29 : 28;
      } else {
        daysInMonth = 31;
      }

      if (day < 1 || day > daysInMonth) {
        return 'Invalid day for the selected month';
      }
    } catch (e) {
      return 'Please enter a valid date';
    }

    return null;
  }

  /// Check if two passwords match
  static String? validatePasswordMatch(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate class code format
  static String? validateClassCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Class code is required';
    }

    // Class code should be 6 alphanumeric characters
    final codeRegex = RegExp(r'^[A-Za-z0-9]{6}$');
    if (!codeRegex.hasMatch(value)) {
      return 'Please enter a valid 6-character class code';
    }

    return null;
  }
}
