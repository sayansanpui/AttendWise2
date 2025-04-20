import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Route guard to check if user is authenticated
class AuthGuard {
  static String? handleAuthState(BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null &&
        state.matchedLocation != RouteNames.login &&
        state.matchedLocation != RouteNames.forgotPassword) {
      return RouteNames.login;
    }
    return null;
  }
}

/// Enum representing user roles in the system
enum UserRole {
  admin,
  teacher,
  student,
  unknown,
}

/// Route guard to check user roles and permissions
class RoleGuard {
  static Future<UserRole> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return UserRole.unknown;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return UserRole.unknown;

      final role = userDoc.data()?['role'] as String?;

      switch (role) {
        case 'admin':
          return UserRole.admin;
        case 'teacher':
          return UserRole.teacher;
        case 'student':
          return UserRole.student;
        default:
          return UserRole.unknown;
      }
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return UserRole.unknown;
    }
  }

  /// Redirect based on user role
  static Future<String?> handleRoleBasedRedirect(
      BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return RouteNames.login;

    // Skip role check for these routes
    if (state.matchedLocation == RouteNames.profile ||
        state.matchedLocation == RouteNames.notifications ||
        state.matchedLocation == RouteNames.changePassword) {
      return null;
    }

    final userRole = await getUserRole();

    // Admin route access control
    if (state.matchedLocation.startsWith('/admin') &&
        userRole != UserRole.admin) {
      switch (userRole) {
        case UserRole.teacher:
          return RouteNames.teacherDashboard;
        case UserRole.student:
          return RouteNames.studentDashboard;
        default:
          return RouteNames.login;
      }
    }

    // Teacher route access control
    if (state.matchedLocation.startsWith('/teacher') &&
        userRole != UserRole.teacher) {
      switch (userRole) {
        case UserRole.admin:
          return RouteNames.adminDashboard;
        case UserRole.student:
          return RouteNames.studentDashboard;
        default:
          return RouteNames.login;
      }
    }

    // Student route access control
    if (state.matchedLocation.startsWith('/student') &&
        userRole != UserRole.student) {
      switch (userRole) {
        case UserRole.admin:
          return RouteNames.adminDashboard;
        case UserRole.teacher:
          return RouteNames.teacherDashboard;
        default:
          return RouteNames.login;
      }
    }

    // Handle root path redirect based on role
    if (state.matchedLocation == RouteNames.splash) {
      switch (userRole) {
        case UserRole.admin:
          return RouteNames.adminDashboard;
        case UserRole.teacher:
          return RouteNames.teacherDashboard;
        case UserRole.student:
          return RouteNames.studentDashboard;
        default:
          return RouteNames.login;
      }
    }

    return null;
  }
}
