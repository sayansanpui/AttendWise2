import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service class to manage Firebase interactions
class FirebaseService {
  // Singleton pattern for FirebaseService
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get classroomsCollection =>
      _firestore.collection('classrooms');
  CollectionReference get enrollmentsCollection =>
      _firestore.collection('enrollments');
  CollectionReference get attendanceSessionsCollection =>
      _firestore.collection('attendanceSessions');
  CollectionReference get attendanceRecordsCollection =>
      _firestore.collection('attendanceRecords');
  CollectionReference get postsCollection => _firestore.collection('posts');
  CollectionReference get submissionsCollection =>
      _firestore.collection('submissions');

  // New collections for student import
  CollectionReference get studentsCollection =>
      _firestore.collection('students');
  CollectionReference get departmentsCollection =>
      _firestore.collection('departments');
  CollectionReference get batchesCollection => _firestore.collection('batches');
  CollectionReference get studentImportsCollection =>
      _firestore.collection('studentImports');

  // Helper methods
  String generateId(String collectionPath) {
    return _firestore.collection(collectionPath).doc().id;
  }

  // Server timestamp
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();
}
