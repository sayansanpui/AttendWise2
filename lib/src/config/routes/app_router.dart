import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../src/features/auth/screens/login_screen.dart';
import '../../../src/features/shared/screens/splash_screen.dart'; // Using the shared splash screen
import '../../../src/features/auth/screens/forgot_password_screen.dart';
import '../../../src/features/auth/screens/change_password_screen.dart';

import '../../../src/features/admin/screens/admin_dashboard_screen.dart';
import '../../../src/features/teacher/screens/teacher_dashboard_screen.dart';
import '../../../src/features/student/screens/student_dashboard_screen.dart';

import '../../../src/features/shared/screens/profile_screen.dart';
import '../../../src/features/shared/screens/notifications_screen.dart';

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
          // Add nested teacher routes here as they're implemented
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
    redirect: (BuildContext context, GoRouterState state) {
      // TODO: Add authentication logic here
      // This can check if user is logged in and redirect to the appropriate dashboard
      // For now, we'll let all navigation proceed as is
      return null;
    },
  );
}
