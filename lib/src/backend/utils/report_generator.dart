import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../models/user_model.dart';
import '../models/classroom_model.dart';
import '../models/attendance_session_model.dart';
import '../models/attendance_record_model.dart';
import 'timestamp_utils.dart';

/// Utility class for generating reports
class ReportGenerator {
  /// Generate a PDF attendance report for a classroom
  static Future<File> generateAttendanceReportPdf({
    required ClassroomModel classroom,
    required List<UserModel> students,
    required List<AttendanceSessionModel> sessions,
    required Map<String, List<AttendanceRecordModel>> attendanceRecords,
  }) async {
    final pdf = pw.Document();

    // Add title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Attendance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  classroom.name,
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Subject Code: ${classroom.code}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Room: ${classroom.room}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Semester: ${classroom.semester}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Add summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Attendance Summary'),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Students: ${students.length}'),
              pw.SizedBox(height: 5),
              pw.Text('Total Sessions: ${sessions.length}'),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                child: pw.Text('Student Attendance Overview'),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                headerHeight: 25,
                cellHeight: 25,
                headers: [
                  'Student ID',
                  'Name',
                  'Present',
                  'Absent',
                  'Percentage'
                ],
                data: students.map((student) {
                  final records = attendanceRecords[student.uid] ?? [];
                  int presentCount = 0;
                  int absentCount = 0;

                  for (var record in records) {
                    if (record.status == AttendanceStatus.present ||
                        record.status == AttendanceStatus.approved) {
                      presentCount++;
                    } else if (record.status == AttendanceStatus.absent ||
                        record.status == AttendanceStatus.rejected) {
                      absentCount++;
                    }
                  }

                  double percentage = sessions.isEmpty
                      ? 0
                      : (presentCount / sessions.length) * 100;

                  return [
                    student.universityId,
                    student.displayName,
                    presentCount.toString(),
                    absentCount.toString(),
                    '${percentage.toStringAsFixed(1)}%',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Add detailed session pages
    for (final session in sessions) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final sessionDate = TimestampUtils.formatDate(session.date);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Session Details: $sessionDate'),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Start Time: ${TimestampUtils.formatTime(session.startTime)}'),
                if (session.endTime != null)
                  pw.Text(
                      'End Time: ${TimestampUtils.formatTime(session.endTime!)}'),
                if (session.notes != null && session.notes!.isNotEmpty)
                  pw.Text('Notes: ${session.notes}'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  context: context,
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  headerHeight: 25,
                  cellHeight: 25,
                  headers: ['Student ID', 'Name', 'Status', 'Time'],
                  data: students.map((student) {
                    final records = attendanceRecords[student.uid] ?? [];
                    final sessionRecord = records.firstWhere(
                      (record) => record.sessionId == session.sessionId,
                      orElse: () => AttendanceRecordModel(
                        recordId: '',
                        sessionId: session.sessionId,
                        studentId: student.uid,
                        status: AttendanceStatus.absent,
                        timestamp: Timestamp.now(),
                        reportCount: 0,
                      ),
                    );

                    return [
                      student.universityId,
                      student.displayName,
                      _statusToString(sessionRecord.status),
                      sessionRecord.recordId.isNotEmpty
                          ? TimestampUtils.formatTime(sessionRecord.timestamp)
                          : '-',
                    ];
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );
    }

    // Save the PDF to a temporary file
    final output = await getTemporaryDirectory();
    final fileName =
        'attendance_report_${classroom.code}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Generate an Excel attendance report for a classroom
  static Future<File> generateAttendanceReportExcel({
    required ClassroomModel classroom,
    required List<UserModel> students,
    required List<AttendanceSessionModel> sessions,
    required Map<String, List<AttendanceRecordModel>> attendanceRecords,
  }) async {
    final excel = Excel.createExcel();

    // Remove the default sheet
    excel.delete('Sheet1');

    // Add summary sheet
    final summarySheet = excel['Summary'];

    // Add header row
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = 'Attendance Report';
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .value = classroom.name;
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = 'Subject Code: ${classroom.code}';
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = 'Room: ${classroom.room}';
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = 'Semester: ${classroom.semester}';
    summarySheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
            .value =
        'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';

    // Student attendance summary
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = 'Student ID';
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = 'Name';
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 7))
        .value = 'Present';
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 7))
        .value = 'Absent';
    summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 7))
        .value = 'Percentage';

    // Fill student data
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final records = attendanceRecords[student.uid] ?? [];
      int presentCount = 0;
      int absentCount = 0;

      for (var record in records) {
        if (record.status == AttendanceStatus.present ||
            record.status == AttendanceStatus.approved) {
          presentCount++;
        } else if (record.status == AttendanceStatus.absent ||
            record.status == AttendanceStatus.rejected) {
          absentCount++;
        }
      }

      double percentage =
          sessions.isEmpty ? 0 : (presentCount / sessions.length) * 100;

      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8 + i))
          .value = student.universityId;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8 + i))
          .value = student.displayName;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 8 + i))
          .value = presentCount;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 8 + i))
          .value = absentCount;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 8 + i))
          .value = '${percentage.toStringAsFixed(1)}%';
    }

    // Create detailed sheet
    final detailedSheet = excel['Detailed Attendance'];

    // Add header row for detailed sheet
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = 'Student ID';
    detailedSheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        .value = 'Name';

    // Add session dates as columns
    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final sessionDate = TimestampUtils.formatDate(session.date);
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2 + i, rowIndex: 0))
          .value = sessionDate;
    }

    // Fill student attendance for each session
    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final records = attendanceRecords[student.uid] ?? [];

      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1 + i))
          .value = student.universityId;
      detailedSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1 + i))
          .value = student.displayName;

      for (int j = 0; j < sessions.length; j++) {
        final session = sessions[j];
        final sessionRecord = records.firstWhere(
          (record) => record.sessionId == session.sessionId,
          orElse: () => AttendanceRecordModel(
            recordId: '',
            sessionId: session.sessionId,
            studentId: student.uid,
            status: AttendanceStatus.absent,
            timestamp: Timestamp.now(),
            reportCount: 0,
          ),
        );

        detailedSheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2 + j, rowIndex: 1 + i))
            .value = _statusToString(sessionRecord.status);
      }
    }

    // Auto-fit columns in both sheets
    for (final sheet in excel.sheets.values) {
      for (int i = 0; i < 20; i++) {
        sheet.setColumnWidth(i, 15);
      }
    }

    // Save the Excel file
    final output = await getTemporaryDirectory();
    final fileName =
        'attendance_report_${classroom.code}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final file = File('${output.path}/$fileName');

    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  /// Generate a student performance report
  static Future<File> generateStudentPerformanceReport({
    required UserModel student,
    required List<ClassroomModel> classrooms,
    required Map<String, Map<String, dynamic>> attendanceStats,
  }) async {
    final pdf = pw.Document();

    // Add title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Student Performance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  student.displayName,
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'ID: ${student.universityId}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Department: ${student.department}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Add performance summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Attendance Summary'),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                headerHeight: 25,
                cellHeight: 25,
                headers: [
                  'Course',
                  'Total Sessions',
                  'Present',
                  'Absent',
                  'Percentage'
                ],
                data: classrooms.map((classroom) {
                  final stats = attendanceStats[classroom.classroomId] ??
                      {
                        'totalSessions': 0,
                        'present': 0,
                        'absent': 0,
                        'percentage': 0.0,
                      };

                  return [
                    classroom.name,
                    stats['totalSessions'].toString(),
                    stats['present'].toString(),
                    stats['absent'].toString(),
                    '${stats['percentage'].toStringAsFixed(1)}%',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 30),
              pw.Header(
                level: 1,
                child: pw.Text('Overall Performance'),
              ),
              pw.SizedBox(height: 10),
              _buildOverallStats(attendanceStats),
            ],
          );
        },
      ),
    );

    // Save the PDF to a temporary file
    final output = await getTemporaryDirectory();
    final fileName =
        'student_report_${student.universityId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build overall statistics widget for student report
  static pw.Widget _buildOverallStats(
      Map<String, Map<String, dynamic>> attendanceStats) {
    int totalSessions = 0;
    int totalPresent = 0;
    int totalAbsent = 0;

    attendanceStats.forEach((classroomId, stats) {
      totalSessions += stats['totalSessions'] as int;
      totalPresent += stats['present'] as int;
      totalAbsent += stats['absent'] as int;
    });

    double overallPercentage =
        totalSessions > 0 ? (totalPresent / totalSessions) * 100 : 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Total Sessions Across All Courses: $totalSessions'),
        pw.SizedBox(height: 5),
        pw.Text('Total Present: $totalPresent'),
        pw.SizedBox(height: 5),
        pw.Text('Total Absent: $totalAbsent'),
        pw.SizedBox(height: 5),
        pw.Text('Overall Attendance: ${overallPercentage.toStringAsFixed(1)}%'),
        pw.SizedBox(height: 10),
        pw.Text(
          _getPerformanceMessage(overallPercentage),
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: overallPercentage >= 75 ? PdfColors.green : PdfColors.red,
          ),
        ),
      ],
    );
  }

  /// Get a performance message based on attendance percentage
  static String _getPerformanceMessage(double percentage) {
    if (percentage >= 90) {
      return 'Excellent attendance record!';
    } else if (percentage >= 75) {
      return 'Good attendance record.';
    } else if (percentage >= 60) {
      return 'Average attendance record. Improvement needed.';
    } else {
      return 'Poor attendance record. Immediate improvement required.';
    }
  }

  /// Convert attendance status to readable string
  static String _statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.requested:
        return 'Requested';
      case AttendanceStatus.approved:
        return 'Approved';
      case AttendanceStatus.rejected:
        return 'Rejected';
    }
  }
}

extension on Sheet {
  void setColumnWidth(int i, int j) {}
}
