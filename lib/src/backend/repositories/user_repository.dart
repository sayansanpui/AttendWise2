import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class UserRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();

  // Get user by ID
  Future<UserModel> getUserById(String uid) async {
    try {
      final doc = await _firebaseService.usersCollection.doc(uid).get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error fetching user: ${e.toString()}');
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _firebaseService.usersCollection
          .where('role', isEqualTo: _roleToString(role))
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching users by role: ${e.toString()}');
    }
  }

  // Get users by department
  Future<List<UserModel>> getUsersByDepartment(String department) async {
    try {
      final querySnapshot = await _firebaseService.usersCollection
          .where('department', isEqualTo: department)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching users by department: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firebaseService.usersCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('Error updating user profile: ${e.toString()}');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final downloadUrl =
          await _storageService.uploadProfileImage(uid, imageFile);

      // Update the user profile with the new image URL
      await _firebaseService.usersCollection.doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading profile image: ${e.toString()}');
    }
  }

  // Search users by name or university ID
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // We can't do direct string contains queries in Firestore
      // So we'll fetch and filter client-side for simplicity
      // In a production app, consider using Firebase extensions or a different search solution

      final querySnapshot = await _firebaseService.usersCollection.get();

      final List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter users where name or ID contains the query (case insensitive)
      return users.where((user) {
        final lowercaseQuery = query.toLowerCase();
        final lowercaseName = user.displayName.toLowerCase();
        final lowercaseId = user.universityId.toLowerCase();

        return lowercaseName.contains(lowercaseQuery) ||
            lowercaseId.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Error searching users: ${e.toString()}');
    }
  }

  // Deactivate user
  Future<void> deactivateUser(String uid) async {
    try {
      await _firebaseService.usersCollection.doc(uid).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Error deactivating user: ${e.toString()}');
    }
  }

  // Reactivate user
  Future<void> reactivateUser(String uid) async {
    try {
      await _firebaseService.usersCollection.doc(uid).update({
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Error reactivating user: ${e.toString()}');
    }
  }

  // Change user role
  Future<void> changeUserRole(String uid, UserRole newRole) async {
    try {
      await _firebaseService.usersCollection.doc(uid).update({
        'role': _roleToString(newRole),
      });
    } catch (e) {
      throw Exception('Error changing user role: ${e.toString()}');
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
}
