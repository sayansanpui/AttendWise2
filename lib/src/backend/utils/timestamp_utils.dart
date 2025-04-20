import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Utility class for handling Firestore Timestamp operations
class TimestampUtils {
  /// Format a Firestore Timestamp to a readable date string
  static String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(date);
  }

  /// Format a Firestore Timestamp to a readable time string
  static String formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formatter = DateFormat('hh:mm a');
    return formatter.format(date);
  }

  /// Format a Firestore Timestamp to a readable date and time string
  static String formatDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formatter = DateFormat('MMM dd, yyyy - hh:mm a');
    return formatter.format(date);
  }

  /// Check if the given Timestamp is today
  static bool isToday(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Calculate the difference in days between now and the given Timestamp
  static int daysDifference(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Return a human-readable relative time (e.g., "2 days ago", "just now")
  static String getRelativeTime(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return formatDate(timestamp);
    }
  }

  /// Format a due date for assignments with remaining time
  static String formatDueDate(Timestamp dueDate) {
    final daysDiff = daysDifference(dueDate);

    if (daysDiff < 0) {
      return 'Due ${-daysDiff} ${-daysDiff == 1 ? 'day' : 'days'} ago';
    } else if (daysDiff == 0) {
      return 'Due today';
    } else if (daysDiff == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $daysDiff days';
    }
  }

  /// Get the start of the current day as a Timestamp
  static Timestamp startOfToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return Timestamp.fromDate(startOfDay);
  }

  /// Get the end of the current day as a Timestamp
  static Timestamp endOfToday() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return Timestamp.fromDate(endOfDay);
  }

  /// Get the start of the current week as a Timestamp
  static Timestamp startOfWeek() {
    final now = DateTime.now();
    // Get the weekday (1 for Monday, 7 for Sunday)
    final weekday = now.weekday;
    // Calculate days to subtract to get to the start of the week (Monday)
    final daysToSubtract = weekday - 1;
    final startOfWeek = DateTime(now.year, now.month, now.day - daysToSubtract);
    return Timestamp.fromDate(startOfWeek);
  }

  /// Get the end of the current week as a Timestamp
  static Timestamp endOfWeek() {
    final now = DateTime.now();
    // Get the weekday (1 for Monday, 7 for Sunday)
    final weekday = now.weekday;
    // Calculate days to add to get to the end of the week (Sunday)
    final daysToAdd = 7 - weekday;
    final endOfWeek =
        DateTime(now.year, now.month, now.day + daysToAdd, 23, 59, 59);
    return Timestamp.fromDate(endOfWeek);
  }

  /// Get the start of the current month as a Timestamp
  static Timestamp startOfMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return Timestamp.fromDate(startOfMonth);
  }

  /// Get the end of the current month as a Timestamp
  static Timestamp endOfMonth() {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return Timestamp.fromDate(endOfMonth);
  }

  /// Get the start of the current year as a Timestamp
  static Timestamp startOfYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return Timestamp.fromDate(startOfYear);
  }

  /// Get the end of the current year as a Timestamp
  static Timestamp endOfYear() {
    final now = DateTime.now();
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
    return Timestamp.fromDate(endOfYear);
  }
}
