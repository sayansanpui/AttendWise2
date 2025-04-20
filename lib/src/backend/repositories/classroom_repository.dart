import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/classroom_model.dart';
import '../models/enrollment_model.dart';
import '../services/firebase_service.dart';

class ClassroomRepository {
  final FirebaseService _firebaseService = FirebaseService();

  // Create a new classroom
  Future<String> createClassroom({
    required String subjectCode,
    required String subjectName,
    required String section,
    required int year,
    required int semester,
    required String stream,
    required ClassType classType,
    required String createdBy,
  }) async {
    try {
      // Generate a unique classroom ID
      final classroomId = _firebaseService.generateId('classrooms');

      // Generate a unique 6-character class code
      final classCode = _generateClassCode();

      // Create the classroom document
      await _firebaseService.classroomsCollection.doc(classroomId).set({
        'classroomId': classroomId,
        'classCode': classCode,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'section': section,
        'year': year,
        'semester': semester,
        'stream': stream,
        'classType': _classTypeToString(classType),
        'createdBy': createdBy,
        'createdAt': _firebaseService.serverTimestamp,
        'isActive': true,
      });

      return classroomId;
    } catch (e) {
      throw Exception('Error creating classroom: ${e.toString()}');
    }
  }

  // Get classroom by ID
  Future<ClassroomModel> getClassroomById(String classroomId) async {
    try {
      final doc =
          await _firebaseService.classroomsCollection.doc(classroomId).get();

      if (!doc.exists) {
        throw Exception('Classroom not found');
      }

      return ClassroomModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error fetching classroom: ${e.toString()}');
    }
  }

  // Get classrooms by teacher ID
  Future<List<ClassroomModel>> getClassroomsByTeacher(String teacherId) async {
    try {
      final querySnapshot = await _firebaseService.classroomsCollection
          .where('createdBy', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              ClassroomModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching classrooms: ${e.toString()}');
    }
  }

  // Get classrooms by department
  Future<List<ClassroomModel>> getClassroomsByDepartment(
      String department) async {
    try {
      final querySnapshot = await _firebaseService.classroomsCollection
          .where('stream', isEqualTo: department)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              ClassroomModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching classrooms: ${e.toString()}');
    }
  }

  // Get classrooms by student ID (via enrollments)
  Future<List<ClassroomModel>> getClassroomsByStudent(String studentId) async {
    try {
      // First, get all enrollments for this student
      final enrollmentSnapshot = await _firebaseService.enrollmentsCollection
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .get();

      // Extract classroom IDs from enrollments
      final classroomIds = enrollmentSnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['classroomId'] as String)
          .toList();

      if (classroomIds.isEmpty) {
        return [];
      }

      // Firestore doesn't support array contains with more than 10 items
      // So we'll split into chunks if needed
      List<ClassroomModel> allClassrooms = [];

      for (int i = 0; i < classroomIds.length; i += 10) {
        final endIndex =
            (i + 10 < classroomIds.length) ? i + 10 : classroomIds.length;
        final chunk = classroomIds.sublist(i, endIndex);

        final querySnapshot = await _firebaseService.classroomsCollection
            .where('classroomId', whereIn: chunk)
            .where('isActive', isEqualTo: true)
            .get();

        final classrooms = querySnapshot.docs
            .map((doc) =>
                ClassroomModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        allClassrooms.addAll(classrooms);
      }

      return allClassrooms;
    } catch (e) {
      throw Exception('Error fetching student classrooms: ${e.toString()}');
    }
  }

  // Update classroom details
  Future<void> updateClassroom(
      String classroomId, Map<String, dynamic> data) async {
    try {
      await _firebaseService.classroomsCollection.doc(classroomId).update(data);
    } catch (e) {
      throw Exception('Error updating classroom: ${e.toString()}');
    }
  }

  // Deactivate classroom
  Future<void> deactivateClassroom(String classroomId) async {
    try {
      await _firebaseService.classroomsCollection.doc(classroomId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Error deactivating classroom: ${e.toString()}');
    }
  }

  // Join classroom with class code (for students)
  Future<String> joinClassroomWithCode(
      String classCode, String studentId) async {
    try {
      // Find the classroom with this code
      final querySnapshot = await _firebaseService.classroomsCollection
          .where('classCode', isEqualTo: classCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Invalid class code or inactive classroom');
      }

      final classroomData =
          querySnapshot.docs.first.data() as Map<String, dynamic>;
      final classroomId = classroomData['classroomId'] as String;

      // Check if student is already enrolled
      final enrollmentCheck = await _firebaseService.enrollmentsCollection
          .where('studentId', isEqualTo: studentId)
          .where('classroomId', isEqualTo: classroomId)
          .get();

      if (enrollmentCheck.docs.isNotEmpty) {
        // Student is already enrolled, check if active
        final enrollmentData =
            enrollmentCheck.docs.first.data() as Map<String, dynamic>;
        final isActive = enrollmentData['isActive'] as bool;

        if (isActive) {
          throw Exception('You are already enrolled in this classroom');
        } else {
          // Reactivate the enrollment
          await _firebaseService.enrollmentsCollection
              .doc(enrollmentCheck.docs.first.id)
              .update({'isActive': true});
          return classroomId;
        }
      }

      // Create new enrollment
      final enrollmentId = _firebaseService.generateId('enrollments');
      await _firebaseService.enrollmentsCollection.doc(enrollmentId).set({
        'enrollmentId': enrollmentId,
        'studentId': studentId,
        'classroomId': classroomId,
        'enrolledAt': _firebaseService.serverTimestamp,
        'isActive': true,
      });

      return classroomId;
    } catch (e) {
      throw Exception('Error joining classroom: ${e.toString()}');
    }
  }

  // Get enrolled students for a classroom
  Future<List<String>> getEnrolledStudentIds(String classroomId) async {
    try {
      final querySnapshot = await _firebaseService.enrollmentsCollection
          .where('classroomId', isEqualTo: classroomId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['studentId'] as String)
          .toList();
    } catch (e) {
      throw Exception('Error fetching enrolled students: ${e.toString()}');
    }
  }

  // Remove student from classroom
  Future<void> removeStudentFromClassroom(
      String classroomId, String studentId) async {
    try {
      final querySnapshot = await _firebaseService.enrollmentsCollection
          .where('classroomId', isEqualTo: classroomId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Student is not enrolled in this classroom');
      }

      await _firebaseService.enrollmentsCollection
          .doc(querySnapshot.docs.first.id)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Error removing student: ${e.toString()}');
    }
  }

  // Generate a unique 6-character class code
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var code = '';

    for (var i = 0; i < 6; i++) {
      code += chars[(DateTime.now().millisecondsSinceEpoch % chars.length)];
    }

    return code;
  }

  // Convert class type enum to string
  String _classTypeToString(ClassType type) {
    switch (type) {
      case ClassType.theory:
        return 'theory';
      case ClassType.lab:
        return 'lab';
    }
  }
}
