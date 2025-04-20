import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/classroom_model.dart';
import '../models/enrollment_model.dart';
import '../services/firebase_service.dart';

class ClassroomRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _classroomsCollection =
      FirebaseFirestore.instance.collection('classrooms');

  // Create a new classroom
  Future<String> createClassroom({
    required String name,
    required String code,
    required String teacherId,
    required String room,
    required String level,
    required String year,
    required String semester,
    required String time,
  }) async {
    try {
      // Generate a unique classroom ID
      final classroomId = _firebaseService.generateId('classrooms');

      // Generate a unique class code (if not provided)
      final classCode = code.isNotEmpty ? code : _generateClassCode();

      // Create a new ClassroomModel instance
      final classroom = ClassroomModel(
        classroomId: classroomId,
        name: name,
        code: classCode,
        teacherId: teacherId,
        room: room,
        level: level,
        year: year,
        semester: semester,
        time: time,
        totalSessions: 0,
        completedSessions: 0,
        attendanceRate: 0.0,
        studentCount: 0,
        status: ClassroomStatus.active,
        createdAt: DateTime.now(),
        updatedAt: null,
      );

      // Save to Firestore
      await _classroomsCollection.doc(classroomId).set(classroom.toJson());

      return classroomId;
    } catch (e) {
      throw Exception('Error creating classroom: ${e.toString()}');
    }
  }

  // Get classroom by ID
  Future<ClassroomModel> getClassroomById(String classroomId) async {
    try {
      final doc = await _classroomsCollection.doc(classroomId).get();

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
      final querySnapshot = await _classroomsCollection
          .where('teacherId', isEqualTo: teacherId)
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

  // Get active classrooms by teacher ID
  Future<List<ClassroomModel>> getActiveClassroomsByTeacher(
      String teacherId) async {
    try {
      final querySnapshot = await _classroomsCollection
          .where('teacherId', isEqualTo: teacherId)
          .where('status',
              isEqualTo: ClassroomStatus.active.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              ClassroomModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching active classrooms: ${e.toString()}');
    }
  }

  // Get student count for a classroom
  Future<int> getStudentCount(String classroomId) async {
    try {
      final querySnapshot = await _firebaseService.enrollmentsCollection
          .where('classroomId', isEqualTo: classroomId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.size;
    } catch (e) {
      throw Exception('Error fetching student count: ${e.toString()}');
    }
  }

  // Update classroom details
  Future<void> updateClassroom(
      String classroomId, ClassroomModel classroom) async {
    try {
      // Update the updatedAt timestamp
      final updatedClassroom = classroom.copyWith(
        updatedAt: DateTime.now(),
      );

      await _classroomsCollection
          .doc(classroomId)
          .update(updatedClassroom.toJson());
    } catch (e) {
      throw Exception('Error updating classroom: ${e.toString()}');
    }
  }

  // Update classroom status
  Future<void> updateClassroomStatus(
      String classroomId, ClassroomStatus status) async {
    try {
      await _classroomsCollection.doc(classroomId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating classroom status: ${e.toString()}');
    }
  }

  // Update classroom attendance metrics
  Future<void> updateAttendanceMetrics(String classroomId, int totalSessions,
      int completedSessions, double attendanceRate) async {
    try {
      await _classroomsCollection.doc(classroomId).update({
        'totalSessions': totalSessions,
        'completedSessions': completedSessions,
        'attendanceRate': attendanceRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating attendance metrics: ${e.toString()}');
    }
  }

  // Update student count
  Future<void> updateStudentCount(String classroomId, int count) async {
    try {
      await _classroomsCollection.doc(classroomId).update({
        'studentCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating student count: ${e.toString()}');
    }
  }

  // Join classroom with code (for students)
  Future<ClassroomModel> joinClassroomWithCode(
      String code, String studentId) async {
    try {
      // Find the classroom with this code
      final querySnapshot = await _classroomsCollection
          .where('code', isEqualTo: code)
          .where('status',
              isEqualTo: ClassroomStatus.active.toString().split('.').last)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Invalid class code or inactive classroom');
      }

      final classroomData =
          querySnapshot.docs.first.data() as Map<String, dynamic>;
      final classroomId = classroomData['classroomId'] as String;
      final classroom = ClassroomModel.fromJson(classroomData);

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

          // Update student count
          await updateStudentCount(classroomId, classroom.studentCount + 1);

          return classroom;
        }
      }

      // Create new enrollment
      final enrollmentId = _firebaseService.generateId('enrollments');
      await _firebaseService.enrollmentsCollection.doc(enrollmentId).set({
        'enrollmentId': enrollmentId,
        'studentId': studentId,
        'classroomId': classroomId,
        'enrolledAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Update student count
      await updateStudentCount(classroomId, classroom.studentCount + 1);

      return classroom;
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

  // Generate a unique 6-character class code
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var code = '';
    final random = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < 6; i++) {
      code += chars[((random + i) % chars.length)];
    }

    return code;
  }

  // Get attendance statistics for a classroom
  Future<Map<String, dynamic>> getAttendanceStats(String classroomId) async {
    try {
      final attendanceSnapshot = await _firestore
          .collection('attendance_sessions')
          .where('classroomId', isEqualTo: classroomId)
          .get();

      if (attendanceSnapshot.docs.isEmpty) {
        return {
          'Present': 0,
          'Absent': 0,
          'Late': 0,
          'Excused': 0,
        };
      }

      int presentCount = 0;
      int absentCount = 0;
      int lateCount = 0;
      int excusedCount = 0;

      for (var doc in attendanceSnapshot.docs) {
        final attendanceData = doc.data() as Map<String, dynamic>;
        final records = attendanceData['records'] as List<dynamic>? ?? [];

        for (var record in records) {
          final status = record['status'] as String? ?? '';
          if (status == 'present') {
            presentCount++;
          } else if (status == 'absent') {
            absentCount++;
          } else if (status == 'late') {
            lateCount++;
          } else if (status == 'excused') {
            excusedCount++;
          }
        }
      }

      return {
        'Present': presentCount,
        'Absent': absentCount,
        'Late': lateCount,
        'Excused': excusedCount,
      };
    } catch (e) {
      throw Exception('Error fetching attendance stats: ${e.toString()}');
    }
  }

  // Get classroom sessions
  Future<List<Map<String, dynamic>>> getClassroomSessions(
      String classroomId) async {
    try {
      final sessionSnapshot = await _firestore
          .collection('attendance_sessions')
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('date', descending: true)
          .get();

      final classroom = await getClassroomById(classroomId);

      return sessionSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final records = data['records'] as List<dynamic>? ?? [];
        final studentsPresent =
            records.where((r) => (r['status'] as String) == 'present').length;

        return {
          'id': doc.id,
          'classId': classroomId,
          'className': classroom.name,
          'classCode': classroom.code,
          'date': (data['date'] as Timestamp).toDate(),
          'studentsPresent': studentsPresent,
          'totalStudents': records.length,
          'duration': data['duration'] as int? ?? 0,
          'status': data['status'] as String? ?? 'Completed',
        };
      }).toList();
    } catch (e) {
      throw Exception('Error fetching classroom sessions: ${e.toString()}');
    }
  }

  // Get recent attendance sessions
  Future<List<Map<String, dynamic>>> getRecentSessions(String teacherId) async {
    try {
      // Get teacher's classrooms
      final classrooms = await getClassroomsByTeacher(teacherId);
      if (classrooms.isEmpty) return [];

      final classroomIds = classrooms.map((c) => c.classroomId).toList();

      // Firestore doesn't support array contains with more than 10 items
      // So we'll split into chunks if needed
      List<Map<String, dynamic>> allSessions = [];

      for (int i = 0; i < classroomIds.length; i += 10) {
        final endIndex =
            (i + 10 < classroomIds.length) ? i + 10 : classroomIds.length;
        final chunk = classroomIds.sublist(i, endIndex);

        final sessionSnapshot = await _firestore
            .collection('attendance_sessions')
            .where('classroomId', whereIn: chunk)
            .orderBy('date', descending: true)
            .limit(10)
            .get();

        for (var doc in sessionSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final classroomId = data['classroomId'] as String;
          final classroom =
              classrooms.firstWhere((c) => c.classroomId == classroomId);
          final records = data['records'] as List<dynamic>? ?? [];
          final studentsPresent =
              records.where((r) => (r['status'] as String) == 'present').length;

          allSessions.add({
            'id': doc.id,
            'classId': classroomId,
            'className': classroom.name,
            'classCode': classroom.code,
            'date': (data['date'] as Timestamp).toDate(),
            'studentsPresent': studentsPresent,
            'totalStudents': records.length,
            'duration': data['duration'] as int? ?? 0,
            'status': data['status'] as String? ?? 'Completed',
          });
        }
      }

      // Sort by date (most recent first) and limit to 5
      allSessions.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      return allSessions.take(5).toList();
    } catch (e) {
      throw Exception('Error fetching recent sessions: ${e.toString()}');
    }
  }
}
