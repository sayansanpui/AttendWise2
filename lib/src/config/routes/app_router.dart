import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';

import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/screens/create_classroom_screen.dart';
import '../../features/teacher/screens/classrooms_screen.dart';
import '../../features/teacher/screens/start_attendance_screen.dart';
import '../../features/teacher/screens/active_session_screen.dart';
import '../../features/teacher/screens/session_summary_screen.dart';
import '../../features/teacher/screens/classroom_materials_screen.dart';

import '../../features/student/screens/student_dashboard_screen.dart';

import '../../features/shared/screens/splash_screen.dart'; // Using the shared splash screen
import '../../features/shared/screens/profile_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';

import 'route_names.dart';

// Global router provider
final routerProvider = Provider<GoRouter>((ref) => AppRouter.router);

/// Manages app routing with GoRouter
class AppRouter {
  // Private constructor
  AppRouter._();

  /// Get the router instance
  static final router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,

    routes: [
      // Auth routes
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Shared routes
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Admin routes
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          // Add nested admin routes here as they're implemented
        ],
      ),

      // Teacher routes
      GoRoute(
        path: RouteNames.teacherDashboard,
        name: 'teacherDashboard',
        builder: (context, state) => const TeacherDashboardScreen(),
        routes: [
          GoRoute(
            path: RouteNames.createClassroom,
            name: 'createClassroom',
            builder: (context, state) => const CreateClassroomScreen(),
          ),
          GoRoute(
            path: 'classrooms', // Changed to relative path
            name: 'teacherClassrooms',
            builder: (context, state) => const ClassroomsScreen(),
          ),
          GoRoute(
            path: '${RouteNames.teacherStartAttendance}/:classroomId',
            name: 'teacherStartAttendance',
            builder: (context, state) => StartAttendanceScreen(
              classroomId: state.pathParameters['classroomId']!,
            ),
          ),
          GoRoute(
            path: '${RouteNames.teacherActiveSession}/:sessionId',
            name: 'teacherActiveSession',
            builder: (context, state) => ActiveSessionScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
          GoRoute(
            path: '${RouteNames.teacherSessionSummary}/:sessionId',
            name: 'teacherSessionSummary',
            builder: (context, state) => SessionSummaryScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
          GoRoute(
            path: '${RouteNames.teacherClassroomMaterials}/:classroomId',
            name: 'teacherClassroomMaterials',
            builder: (context, state) => ClassroomMaterialsScreen(
              classroomId: state.pathParameters['classroomId']!,
            ),
          ),
        ],
      ),

      // Student routes
      GoRoute(
        path: RouteNames.studentDashboard,
        name: 'studentDashboard',
        builder: (context, state) => const StudentDashboardScreen(),
        routes: [
          // Add nested student routes here as they're implemented
        ],
      ),
    ],

    // Error handler for invalid routes
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('The requested page was not found.',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.login),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    ),

    // Redirect logic
    redirect: (BuildContext context, GoRouterState state) async {
      // Skip redirection for auth-related routes
      if (state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.signup ||
          state.matchedLocation == RouteNames.forgotPassword ||
          state.matchedLocation == RouteNames.splash) {
        return null;
      }

      // Check if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // Not logged in, redirect to login
        return RouteNames.login;
      }

      // User is logged in, check their role and ensure they're on the correct dashboard
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!userDoc.exists) {
          // No user document found, sign out and redirect to login
          await FirebaseAuth.instance.signOut();
          return RouteNames.login;
        }

        final userData = userDoc.data()!;
        final userRole = userData['role'] as String?;

        // Redirect to appropriate dashboard based on role
        if (userRole == 'admin') {
          // If trying to access student or teacher dashboards, redirect to admin
          if (state.matchedLocation.startsWith(RouteNames.studentDashboard) ||
              state.matchedLocation.startsWith(RouteNames.teacherDashboard)) {
            return RouteNames.adminDashboard;
          }
        } else if (userRole == 'teacher') {
          // If trying to access student or admin dashboards, redirect to teacher
          if (state.matchedLocation.startsWith(RouteNames.studentDashboard) ||
              state.matchedLocation.startsWith(RouteNames.adminDashboard)) {
            return RouteNames.teacherDashboard;
          }
        } else if (userRole == 'student') {
          // If trying to access teacher or admin dashboards, redirect to student
          if (state.matchedLocation.startsWith(RouteNames.teacherDashboard) ||
              state.matchedLocation.startsWith(RouteNames.adminDashboard)) {
            return RouteNames.studentDashboard;
          }
        } else {
          // Unknown role, redirect to login
          await FirebaseAuth.instance.signOut();
          return RouteNames.login;
        }
      } catch (e) {
        debugPrint('Error in router redirection: $e');
        // On error, redirect to login
        return RouteNames.login;
      }

      // Allow navigation to proceed
      return null;
    },
  );
}
