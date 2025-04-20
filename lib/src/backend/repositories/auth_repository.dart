import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login timestamp
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register a new user
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    required String department,
    required String universityId,
  }) async {
    try {
      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'role': _roleToString(role),
        'department': department,
        'universityId': universityId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'passwordChanged': false,
      });

      // Update the user's profile in Firebase Auth
      await userCredential.user!.updateDisplayName(displayName);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Bulk register users (for admin use)
  Future<List<String>> bulkRegisterUsers(
      List<Map<String, dynamic>> users) async {
    List<String> results = [];

    for (var user in users) {
      try {
        // Generate a default password from university ID
        final defaultPassword = 'Att${user['universityId']}!';

        await registerUser(
          email: user['email'],
          password: defaultPassword,
          displayName: user['displayName'],
          role: _stringToRole(user['role']),
          department: user['department'],
          universityId: user['universityId'],
        );

        results.add('Successfully registered ${user['email']}');
      } catch (e) {
        results.add('Failed to register ${user['email']}: ${e.toString()}');
      }
    }

    return results;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Change password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      // Re-authenticate user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      // Update passwordChanged flag in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'passwordChanged': true,
      });
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user role from Firestore
  Future<UserRole> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final userData = doc.data() as Map<String, dynamic>;
      return _stringToRole(userData['role']);
    } catch (e) {
      throw Exception('Error getting user role: ${e.toString()}');
    }
  }

  // Check if password has been changed
  Future<bool> hasPasswordBeenChanged(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final userData = doc.data() as Map<String, dynamic>;
      return userData['passwordChanged'] ?? false;
    } catch (e) {
      throw Exception('Error checking password status: ${e.toString()}');
    }
  }

  // Convert role enum to string
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
    }
  }

  // Convert string to role enum
  UserRole _stringToRole(String roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      default:
        throw ArgumentError('Invalid role: $roleStr');
    }
  }

  // Handle authentication exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email');
        case 'wrong-password':
          return Exception('Incorrect password');
        case 'email-already-in-use':
          return Exception('Email is already in use');
        case 'weak-password':
          return Exception('Password is too weak');
        case 'invalid-email':
          return Exception('Invalid email format');
        case 'requires-recent-login':
          return Exception('Please re-login to perform this action');
        default:
          return Exception('Authentication error: ${e.message}');
      }
    }
    return Exception('Error occurred: ${e.toString()}');
  }
}
