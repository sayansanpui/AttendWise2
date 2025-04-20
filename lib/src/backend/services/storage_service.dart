import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Service class to manage Firebase Storage interactions
class StorageService {
  // Singleton pattern for StorageService
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseStorage get storage => _storage;

  /// Upload a profile image to Firebase Storage
  /// Returns the download URL of the uploaded file
  Future<String> uploadProfileImage(String userId, File file) async {
    final extension = path.extension(file.path);
    final ref = _storage.ref().child('profile_images/$userId$extension');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload class material to Firebase Storage
  /// Returns the download URL of the uploaded file
  Future<String> uploadClassMaterial(
      String classroomId, String postId, File file) async {
    final fileName = path.basename(file.path);
    final ref =
        _storage.ref().child('class_materials/$classroomId/$postId/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload assignment submission to Firebase Storage
  /// Returns the download URL of the uploaded file
  Future<String> uploadSubmission(
      String postId, String studentId, File file) async {
    final fileName = path.basename(file.path);
    final ref = _storage
        .ref()
        .child('assignment_submissions/$postId/$studentId/$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload generated report to Firebase Storage
  /// Returns the download URL of the uploaded file
  Future<String> uploadReport(
      String reportType, String fileName, File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref =
        _storage.ref().child('reports/$reportType/${timestamp}_$fileName');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => null);
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Error deleting file: $e');
    }
  }
}
