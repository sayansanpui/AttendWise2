import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/dimensions.dart';
import '../../../config/theme/color_schemes.dart';

/// Notifications screen shared across all user roles
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = false;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Fetch actual notifications from Firebase
      await Future.delayed(const Duration(seconds: 1));

      // Sample notifications
      setState(() {
        _notifications = [
          NotificationItem(
            id: '1',
            title: 'Attendance Session Started',
            message: 'Professor Smith started an attendance session for CS101',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
            type: NotificationType.attendance,
            isRead: false,
          ),
          NotificationItem(
            id: '2',
            title: 'New Announcement',
            message: 'Important update about the midterm exam schedule',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            type: NotificationType.announcement,
            isRead: true,
          ),
          NotificationItem(
            id: '3',
            title: 'Attendance Marked',
            message: 'Your attendance was successfully recorded for CS101',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            type: NotificationType.attendance,
            isRead: true,
          ),
          NotificationItem(
            id: '4',
            title: 'Password Changed',
            message: 'Your account password was recently changed',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            type: NotificationType.account,
            isRead: true,
          ),
          NotificationItem(
            id: '5',
            title: 'Account Created',
            message:
                'Welcome to AttendWise! Your account has been created successfully',
            timestamp: DateTime.now().subtract(const Duration(days: 7)),
            type: NotificationType.account,
            isRead: true,
          ),
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load notifications: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      // TODO: Update notification read status in Firebase
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update notification: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // TODO: Update all notification read statuses in Firebase
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update notifications: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all as read'),
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyState(theme)
                : _buildNotificationList(theme),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          SizedBox(height: AppDimensions.spacing16),
          Text(
            'No Notifications',
            style: theme.textTheme.headlineSmall,
          ),
          SizedBox(height: AppDimensions.spacing8),
          Text(
            'You don\'t have any notifications at the moment',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacing24),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            onPressed: _loadNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(ThemeData theme) {
    return ListView.separated(
      padding: EdgeInsets.all(AppDimensions.screenPadding),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(theme, notification);
      },
    );
  }

  Widget _buildNotificationItem(
      ThemeData theme, NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppDimensions.spacing16),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onError,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // TODO: Implement deletion from Firebase
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          // TODO: Navigate to relevant screen based on notification type
        },
        child: Container(
          padding: EdgeInsets.all(AppDimensions.spacing16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? null
                : theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(theme, notification.type),
              SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.spacing4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (!notification.isRead) ...[
                      SizedBox(height: AppDimensions.spacing8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _markAsRead(notification.id),
                          child: const Text('Mark as read'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacing12,
                              vertical: AppDimensions.spacing4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(ThemeData theme, NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.attendance:
        iconData = Icons.how_to_reg;
        iconColor = AppColorScheme.infoColor;
        break;
      case NotificationType.announcement:
        iconData = Icons.campaign;
        iconColor = AppColorScheme.warningColor;
        break;
      case NotificationType.account:
        iconData = Icons.account_circle;
        iconColor = theme.colorScheme.primary;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = theme.colorScheme.secondary;
        break;
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Notification types for categorization
enum NotificationType {
  attendance,
  announcement,
  account,
  system,
}

/// Model class for notification items
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}
