import 'package:intl/intl.dart';

/// Helper class for date and time operations throughout the app
class DateTimeHelper {
  // Private constructor to prevent instantiation
  DateTimeHelper._();

  /// Formats a DateTime to a human-readable date string (e.g., "Apr 20, 2023")
  static String formatDate(DateTime dateTime) {
    return DateFormat.yMMMd().format(dateTime);
  }

  /// Formats a DateTime to a human-readable time string (e.g., "3:30 PM")
  static String formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  /// Formats a DateTime to a date and time string (e.g., "Apr 20, 2023 at 3:30 PM")
  static String formatDateTime(DateTime dateTime) {
    return "${formatDate(dateTime)} at ${formatTime(dateTime)}";
  }

  /// Formats a DateTime to a day and date string (e.g., "Monday, Apr 20")
  static String formatDayAndDate(DateTime dateTime) {
    return DateFormat('EEEE, MMM d').format(dateTime);
  }

  /// Returns a relative time string like "2 minutes ago", "Yesterday", etc.
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return "${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago";
    } else if (difference.inDays > 30) {
      return "${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago";
    } else if (difference.inDays > 7) {
      return "${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago";
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? "Yesterday"
          : "${difference.inDays} days ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago";
    } else {
      return "Just now";
    }
  }

  /// Formats a duration in milliseconds to a readable format (e.g., "2h 30m")
  static String formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String result = '';
    if (hours > 0) {
      result += '${hours}h ';
    }
    if (minutes > 0 || hours > 0) {
      result += '${minutes}m ';
    }
    if (seconds > 0 || (hours == 0 && minutes == 0)) {
      result += '${seconds}s';
    }

    return result.trim();
  }

  /// Returns the current date at midnight (start of day)
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns DateTime for tomorrow at midnight
  static DateTime tomorrow() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day + 1);
  }

  /// Returns the date at midnight this many days from now
  static DateTime daysFromNow(int days) {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day + days);
  }

  /// Formats seconds into MM:SS format for timers
  static String formatSeconds(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Determines if a date is the same day as today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
