import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_session_model.dart';
import '../models/attendance_record_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AttendanceRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  // Create a new attendance session
  Future<String> createAttendanceSession({
    required String classroomId,
    required String teacherId,
    int? headCount,
    String? notes,
  }) async {
    try {
      final sessionId = _firebaseService.generateId('attendanceSessions');
      final now = DateTime.now();

      await _firebaseService.attendanceSessionsCollection.doc(sessionId).set({
        'sessionId': sessionId,
        'classroomId': classroomId,
        'teacherId': teacherId,
        'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
        'headCount': headCount,
        'startTime': _firebaseService.serverTimestamp,
        'endTime': null,
        'isActive': true,
        'notes': notes,
      });

      return sessionId;
    } catch (e) {
      throw Exception('Error creating attendance session: ${e.toString()}');
    }
  }

  // End an attendance session
  Future<void> endAttendanceSession(String sessionId) async {
    try {
      await _firebaseService.attendanceSessionsCollection
          .doc(sessionId)
          .update({
        'endTime': _firebaseService.serverTimestamp,
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Error ending attendance session: ${e.toString()}');
    }
  }

  // Get active attendance session for a classroom
  Future<AttendanceSessionModel?> getActiveSessionForClassroom(
      String classroomId) async {
    try {
      final querySnapshot = await _firebaseService.attendanceSessionsCollection
          .where('classroomId', isEqualTo: classroomId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return AttendanceSessionModel.fromJson(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error fetching active session: ${e.toString()}');
    }
  }

  // Get attendance session by ID
  Future<AttendanceSessionModel> getSessionById(String sessionId) async {
    try {
      final doc = await _firebaseService.attendanceSessionsCollection
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        throw Exception('Attendance session not found');
      }

      return AttendanceSessionModel.fromJson(
          doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error fetching attendance session: ${e.toString()}');
    }
  }

  // Get attendance sessions for a classroom
  Future<List<AttendanceSessionModel>> getSessionsForClassroom(
      String classroomId) async {
    try {
      final querySnapshot = await _firebaseService.attendanceSessionsCollection
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AttendanceSessionModel.fromJson(
              doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching attendance sessions: ${e.toString()}');
    }
  }

  // Mark student attendance
  Future<String> markAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) async {
    try {
      // Check if record already exists
      final existingRecord = await _firebaseService.attendanceRecordsCollection
          .where('sessionId', isEqualTo: sessionId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingRecord.docs.isNotEmpty) {
        // Update existing record
        final recordId = existingRecord.docs.first.id;
        await _firebaseService.attendanceRecordsCollection
            .doc(recordId)
            .update({
          'status': _statusToString(status),
          'timestamp': _firebaseService.serverTimestamp,
        });

        return recordId;
      }

      // Create new record
      final recordId = _firebaseService.generateId('attendanceRecords');
      await _firebaseService.attendanceRecordsCollection.doc(recordId).set({
        'recordId': recordId,
        'sessionId': sessionId,
        'studentId': studentId,
        'status': _statusToString(status),
        'timestamp': _firebaseService.serverTimestamp,
        'reportCount': 0,
      });

      return recordId;
    } catch (e) {
      throw Exception('Error marking attendance: ${e.toString()}');
    }
  }

  // Mark attendance for multiple students
  Future<void> markBulkAttendance({
    required String sessionId,
    required List<String> studentIds,
    required AttendanceStatus status,
  }) async {
    try {
      // Firestore batch write for better performance
      final batch = _firebaseService.firestore.batch();

      for (final studentId in studentIds) {
        final recordId = _firebaseService.generateId('attendanceRecords');
        final docRef =
            _firebaseService.attendanceRecordsCollection.doc(recordId);

        batch.set(docRef, {
          'recordId': recordId,
          'sessionId': sessionId,
          'studentId': studentId,
          'status': _statusToString(status),
          'timestamp': FieldValue.serverTimestamp(),
          'reportCount': 0,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error marking bulk attendance: ${e.toString()}');
    }
  }

  // Get attendance records for a session
  Future<List<AttendanceRecordModel>> getRecordsForSession(
      String sessionId) async {
    try {
      final querySnapshot = await _firebaseService.attendanceRecordsCollection
          .where('sessionId', isEqualTo: sessionId)
          .get();

      return querySnapshot.docs
          .map((doc) => AttendanceRecordModel.fromJson(
              doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching attendance records: ${e.toString()}');
    }
  }

  // Get attendance record for a student in a session
  Future<AttendanceRecordModel?> getStudentRecordForSession(
      String sessionId, String studentId) async {
    try {
      final querySnapshot = await _firebaseService.attendanceRecordsCollection
          .where('sessionId', isEqualTo: sessionId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return AttendanceRecordModel.fromJson(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception(
          'Error fetching student attendance record: ${e.toString()}');
    }
  }

  // Get attendance history for a student in a classroom
  Future<List<AttendanceRecordModel>> getStudentAttendanceHistory(
      String studentId, String classroomId) async {
    try {
      // First get all sessions for this classroom
      final sessionSnapshot = await _firebaseService
          .attendanceSessionsCollection
          .where('classroomId', isEqualTo: classroomId)
          .get();

      final sessionIds = sessionSnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['sessionId'] as String)
          .toList();

      if (sessionIds.isEmpty) {
        return [];
      }

      // Get records for these sessions for this student
      // Firestore doesn't support "whereIn" with more than 10 values
      List<AttendanceRecordModel> allRecords = [];

      for (int i = 0; i < sessionIds.length; i += 10) {
        final endIndex =
            (i + 10 < sessionIds.length) ? i + 10 : sessionIds.length;
        final chunk = sessionIds.sublist(i, endIndex);

        final recordSnapshot = await _firebaseService
            .attendanceRecordsCollection
            .where('sessionId', whereIn: chunk)
            .where('studentId', isEqualTo: studentId)
            .get();

        final records = recordSnapshot.docs
            .map((doc) => AttendanceRecordModel.fromJson(
                doc.data() as Map<String, dynamic>))
            .toList();

        allRecords.addAll(records);
      }

      return allRecords;
    } catch (e) {
      throw Exception('Error fetching attendance history: ${e.toString()}');
    }
  }

  // Calculate attendance statistics for a student in a classroom
  Future<Map<String, dynamic>> calculateStudentAttendanceStats(
      String studentId, String classroomId) async {
    try {
      final records = await getStudentAttendanceHistory(studentId, classroomId);

      int totalSessions = records.length;
      int present = 0;
      int absent = 0;

      for (var record in records) {
        if (record.status == AttendanceStatus.present ||
            record.status == AttendanceStatus.approved) {
          present++;
        } else if (record.status == AttendanceStatus.absent ||
            record.status == AttendanceStatus.rejected) {
          absent++;
        }
      }

      double attendancePercentage =
          totalSessions > 0 ? (present / totalSessions) * 100 : 0;

      return {
        'totalSessions': totalSessions,
        'present': present,
        'absent': absent,
        'percentage': attendancePercentage,
      };
    } catch (e) {
      throw Exception('Error calculating attendance stats: ${e.toString()}');
    }
  }

  // Request attendance correction
  Future<void> requestAttendanceCorrection({
    required String recordId,
    required String reason,
  }) async {
    try {
      // Get the record first
      final recordDoc = await _firebaseService.attendanceRecordsCollection
          .doc(recordId)
          .get();
      if (!recordDoc.exists) {
        throw Exception('Attendance record not found');
      }

      final recordData = recordDoc.data() as Map<String, dynamic>;
      final sessionId = recordData['sessionId'] as String;

      // Get the session to find teacher
      final sessionDoc = await _firebaseService.attendanceSessionsCollection
          .doc(sessionId)
          .get();
      if (!sessionDoc.exists) {
        throw Exception('Attendance session not found');
      }

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final teacherId = sessionData['teacherId'] as String;
      final classroomId = sessionData['classroomId'] as String;

      // Get the classroom name
      final classroomDoc =
          await _firebaseService.classroomsCollection.doc(classroomId).get();
      final classroomData = classroomDoc.data() as Map<String, dynamic>;
      final className = classroomData['subjectName'] as String;

      // Update the record
      await _firebaseService.attendanceRecordsCollection.doc(recordId).update({
        'status': _statusToString(AttendanceStatus.requested),
        'requestReason': reason,
        'timestamp': _firebaseService.serverTimestamp,
      });

      // Send notification to teacher
      await _notificationService.sendAttendanceRequestNotification(
        studentId: recordData['studentId'] as String,
        teacherId: teacherId,
        sessionId: sessionId,
        className: className,
      );
    } catch (e) {
      throw Exception(
          'Error requesting attendance correction: ${e.toString()}');
    }
  }

  // Approve or reject attendance correction request
  Future<void> resolveAttendanceRequest({
    required String recordId,
    required bool approve,
    String? verifiedBy,
  }) async {
    try {
      await _firebaseService.attendanceRecordsCollection.doc(recordId).update({
        'status': _statusToString(
            approve ? AttendanceStatus.approved : AttendanceStatus.rejected),
        'verifiedBy': verifiedBy,
        'verifiedAt': _firebaseService.serverTimestamp,
      });
    } catch (e) {
      throw Exception('Error resolving attendance request: ${e.toString()}');
    }
  }

  // Report an issue with attendance record
  Future<void> reportAttendanceIssue({
    required String recordId,
    required String reportedBy,
  }) async {
    try {
      await _firebaseService.attendanceRecordsCollection.doc(recordId).update({
        'reportCount': FieldValue.increment(1),
        'issuedBy': FieldValue.arrayUnion([reportedBy]),
      });
    } catch (e) {
      throw Exception('Error reporting attendance issue: ${e.toString()}');
    }
  }

  // Calculate attendance statistics for a classroom
  Future<Map<String, dynamic>> calculateClassroomStats(
      String classroomId) async {
    try {
      // Get all sessions for this classroom
      final sessions = await getSessionsForClassroom(classroomId);

      int totalSessions = sessions.length;
      Map<String, dynamic> studentStats = {};

      for (var session in sessions) {
        final records = await getRecordsForSession(session.sessionId);

        for (var record in records) {
          if (!studentStats.containsKey(record.studentId)) {
            studentStats[record.studentId] = {
              'total': 0,
              'present': 0,
              'absent': 0,
            };
          }

          studentStats[record.studentId]['total']++;

          if (record.status == AttendanceStatus.present ||
              record.status == AttendanceStatus.approved) {
            studentStats[record.studentId]['present']++;
          } else if (record.status == AttendanceStatus.absent ||
              record.status == AttendanceStatus.rejected) {
            studentStats[record.studentId]['absent']++;
          }
        }
      }

      // Calculate percentages for each student
      studentStats.forEach((studentId, stats) {
        double percentage =
            stats['total'] > 0 ? (stats['present'] / stats['total']) * 100 : 0;
        studentStats[studentId]['percentage'] = percentage;
      });

      return {
        'totalSessions': totalSessions,
        'studentStats': studentStats,
      };
    } catch (e) {
      throw Exception('Error calculating classroom stats: ${e.toString()}');
    }
  }

  // Convert attendance status enum to string
  String _statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.requested:
        return 'requested';
      case AttendanceStatus.approved:
        return 'approved';
      case AttendanceStatus.rejected:
        return 'rejected';
    }
  }
}
