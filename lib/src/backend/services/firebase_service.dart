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

  // Helper methods
  String generateId(String collectionPath) {
    return _firestore.collection(collectionPath).doc().id;
  }

  // Server timestamp
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();
}
