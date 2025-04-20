import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service class to manage notifications
class NotificationService {
  // Singleton pattern for NotificationService
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification services
  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configure local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Listen for FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Update token in user document
    String? token = await _messaging.getToken();
    if (token != null) {
      await _updateUserToken(token);
    }

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen(_updateUserToken);
  }

  // Handle incoming foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    AndroidNotificationDetails androidDetails =
        const AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      channelDescription: 'Notifications related to attendance',
      importance: Importance.high,
      priority: Priority.high,
    );

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      details,
      payload: message.data['type'],
    );
  }

  // Update user's FCM token in Firestore
  Future<void> _updateUserToken(String token) async {
    String? uid = FirebaseFirestore.instance.app.options.authDomain;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    }
  }

  // Subscribe to classroom topics for notifications
  Future<void> subscribeToClassroom(String classroomId) async {
    await _messaging.subscribeToTopic('classroom_$classroomId');
  }

  // Unsubscribe from classroom topics
  Future<void> unsubscribeFromClassroom(String classroomId) async {
    await _messaging.unsubscribeFromTopic('classroom_$classroomId');
  }

  // Send notification to specific user
  Future<void> sendAttendanceRequestNotification({
    required String studentId,
    required String teacherId,
    required String sessionId,
    required String className,
  }) async {
    try {
      // This would typically be handled by a Cloud Function
      // For completeness, we're showing the client-side code that would trigger it
      await _firestore.collection('notifications').add({
        'recipientId': teacherId,
        'senderId': studentId,
        'type': 'attendance_request',
        'title': 'Attendance Request',
        'body': 'A student has requested attendance correction for $className',
        'data': {
          'sessionId': sessionId,
          'classroomId': className,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }

  // Send notification about new assignment
  Future<void> sendAssignmentNotification({
    required String classroomId,
    required String title,
    required String dueDate,
  }) async {
    try {
      // This would typically be handled by a Cloud Function
      // that sends a notification to all students in the class
      await _firestore.collection('notifications').add({
        'topicId': 'classroom_$classroomId',
        'type': 'new_assignment',
        'title': 'New Assignment',
        'body': '$title due on $dueDate',
        'data': {
          'classroomId': classroomId,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }
}
