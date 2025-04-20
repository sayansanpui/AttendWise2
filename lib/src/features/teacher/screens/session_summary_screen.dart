import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart'; // Added for PieChart

import '../../../config/theme/app_theme.dart';
import '../../../config/theme/dimensions.dart'; // Added for AppDimensions
import '../../../config/theme/color_schemes.dart'; // Added for AppColorScheme
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/utils/date_time_helper.dart';

/// Screen for viewing attendance session summary after a session has ended
class SessionSummaryScreen extends ConsumerStatefulWidget {
  /// ID of the attendance session
  final String sessionId;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<SessionSummaryScreen> createState() =>
      _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen> {
  bool _isLoading = true;
  bool _isGeneratingReport = false;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _classroom;
  List<Map<String, dynamic>> _attendanceRecords = [];

  // For statistics
  int _totalStudents = 0;
  int _presentCount = 0;
  int _absentCount = 0;
  int _lateCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get session details
      final sessionDoc = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(widget.sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found');
      }

      final sessionData = sessionDoc.data()!;

      // Get classroom details
      final classroomId = sessionData['classroomId'];
      final classroomDoc = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(classroomId)
          .get();

      if (classroomDoc.exists) {
        setState(() {
          _classroom = {
            'id': classroomDoc.id,
            ...classroomDoc.data()!,
          };

          _totalStudents = _classroom?['studentCount'] ?? 0;
        });
      }

      // Get attendance records
      final recordsSnapshot = await FirebaseFirestore.instance
          .collection('attendance_records')
          .where('sessionId', isEqualTo: widget.sessionId)
          .get();

      final records = recordsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      // Calculate statistics
      int presentCount = 0;
      int lateCount = 0;

      for (final record in records) {
        final status = record['status'];
        if (status == 'present') {
          presentCount++;
        } else if (status == 'late') {
          lateCount++;
        }
      }

      setState(() {
        _session = {
          'id': sessionDoc.id,
          ...sessionData,
        };
        _attendanceRecords = records;
        _presentCount = presentCount;
        _lateCount = lateCount;
        _absentCount = _totalStudents - presentCount - lateCount;
        if (_absentCount < 0) _absentCount = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load session data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateAttendanceReport() async {
    if (_session == null || _classroom == null) return;

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final pdf = pw.Document();

      // Create the PDF content
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Header(
                  level: 0,
                  child: pw.Text('Attendance Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),

                // Class and session info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Class: ${_classroom!['name']} (${_classroom!['code']} - Section ${_classroom!['section']})',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Topic: ${_session!['topic']}'),
                      pw.SizedBox(height: 5),
                      pw.Text('Session Type: ${_session!['type']}'),
                      pw.SizedBox(height: 5),
                      pw.Text(
                          'Date: ${DateTimeHelper.formatDate((_session!['startTime'] as Timestamp).toDate())}'),
                      pw.SizedBox(height: 5),
                      pw.Text(
                          'Time: ${DateTimeHelper.formatTime((_session!['startTime'] as Timestamp).toDate())} - ${DateTimeHelper.formatTime((_session!['endTime'] as Timestamp).toDate())}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Attendance summary
                pw.Header(level: 1, text: 'Attendance Summary'),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfSummaryItem(
                        'Total Students', _totalStudents.toString()),
                    _buildPdfSummaryItem('Present', _presentCount.toString()),
                    _buildPdfSummaryItem('Absent', _absentCount.toString()),
                    _buildPdfSummaryItem('Late', _lateCount.toString()),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Attendance percentage
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Attendance Rate: ${_totalStudents > 0 ? ((_presentCount + _lateCount) / _totalStudents * 100).toStringAsFixed(1) : 0}%',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Student list header
                pw.Header(level: 1, text: 'Student Attendance List'),
                pw.SizedBox(height: 10),

                // Table header
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'No.',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Student Name',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Status',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Time',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    // Student rows
                    ..._buildStudentAttendanceRows(),
                  ],
                ),

                // Footer
                pw.Positioned(
                  bottom: 20,
                  right: 20,
                  child: pw.Text(
                    'Generated on ${DateTimeHelper.formatDate(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Preview PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'AttendWise - ${_classroom!['code']} Attendance Report',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
    }
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.TableRow> _buildStudentAttendanceRows() {
    final rows = <pw.TableRow>[];

    // Add present students
    for (int i = 0; i < _attendanceRecords.length; i++) {
      final record = _attendanceRecords[i];
      final studentName = record['studentName'] ?? 'Unknown Student';
      final status = record['status'] ?? 'present';
      final timestamp = (record['markedAt'] as Timestamp?)?.toDate();
      final timeString =
          timestamp != null ? DateTimeHelper.formatTime(timestamp) : 'N/A';

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                '${i + 1}',
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(studentName),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                status.toString().toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: status == 'present'
                      ? PdfColors.green700
                      : status == 'late'
                          ? PdfColors.orange700
                          : PdfColors.red700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                timeString,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // If we have absent students to add
    if (_absentCount > 0) {
      // Placeholder for absent students (in a real app, you'd have a list of all enrolled students)
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                '${_attendanceRecords.length + 1}',
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('(${_absentCount} absent students not listed)'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'ABSENT',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: PdfColors.red700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'N/A',
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessionData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionCard(),
                  SizedBox(height: AppDimensions.spacing24),
                  _buildAttendanceStats(),
                  SizedBox(height: AppDimensions.spacing24),
                  _buildAttendanceChart(),
                  SizedBox(height: AppDimensions.spacing24),
                  _buildAttendanceList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGeneratingReport ? null : _generateAttendanceReport,
        icon: _isGeneratingReport
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(_isGeneratingReport ? 'Generating...' : 'Generate Report'),
        backgroundColor: _isGeneratingReport
            ? theme.colorScheme.primary.withOpacity(0.5)
            : theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSessionCard() {
    final theme = Theme.of(context);

    if (_session == null || _classroom == null) {
      return const SizedBox.shrink();
    }

    final sessionTopic = _session!['topic'] ?? 'Untitled Session';
    final sessionType = _session!['type'] ?? 'Regular';
    final classroomName = _classroom!['name'] ?? 'Unknown Class';
    final classCode = _classroom!['code'] ?? '';
    final section = _classroom!['section'] ?? '';

    final startTime = (_session!['startTime'] as Timestamp?)?.toDate();
    final endTime = (_session!['endTime'] as Timestamp?)?.toDate();

    final dateString = startTime != null
        ? DateTimeHelper.formatDate(startTime)
        : 'Unknown date';

    final timeRangeString = startTime != null && endTime != null
        ? '${DateTimeHelper.formatTime(startTime)} - ${DateTimeHelper.formatTime(endTime)}'
        : 'Unknown time';

    final duration = _session!['duration'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.class_,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroomName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacing4),
                      Text(
                        '$classCode - Section $section',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),
            Divider(),
            SizedBox(height: AppDimensions.spacing12),
            Text(
              'Session Information',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: AppDimensions.spacing12),
            _buildInfoRow(theme, 'Topic', sessionTopic),
            _buildInfoRow(theme, 'Type', sessionType),
            _buildInfoRow(theme, 'Date', dateString),
            _buildInfoRow(theme, 'Time', timeRangeString),
            _buildInfoRow(theme, 'Duration', '$duration minutes'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final theme = Theme.of(context);

    // Calculate attendance percentage
    final attendancePercentage = _totalStudents > 0
        ? ((_presentCount + _lateCount) / _totalStudents * 100)
            .toStringAsFixed(1)
        : '0.0';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Statistics',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: AppDimensions.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  theme,
                  'Total Students',
                  _totalStudents.toString(),
                  theme.colorScheme.primary,
                ),
                _buildStatCard(
                  theme,
                  'Present',
                  _presentCount.toString(),
                  AppColorScheme.presentColor,
                ),
                _buildStatCard(
                  theme,
                  'Absent',
                  _absentCount.toString(),
                  AppColorScheme.absentColor,
                ),
                _buildStatCard(
                  theme,
                  'Late',
                  _lateCount.toString(),
                  AppColorScheme.lateColor,
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),
            Divider(),
            SizedBox(height: AppDimensions.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Overall Attendance Rate: ',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '$attendancePercentage%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: double.parse(attendancePercentage) >= 75
                        ? AppColorScheme.successColor
                        : double.parse(attendancePercentage) >= 50
                            ? AppColorScheme.warningColor
                            : AppColorScheme.absentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      ThemeData theme, String label, String value, Color color) {
    return Container(
      width: 80,
      padding: EdgeInsets.all(AppDimensions.spacing8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: AppDimensions.spacing4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final theme = Theme.of(context);

    // Skip chart if no data
    if (_totalStudents == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Breakdown',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: AppDimensions.spacing16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: _presentCount.toDouble(),
                            title:
                                '${((_presentCount / _totalStudents) * 100).round()}%',
                            color: AppColorScheme.presentColor,
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: _absentCount.toDouble(),
                            title:
                                '${((_absentCount / _totalStudents) * 100).round()}%',
                            color: AppColorScheme.absentColor,
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: _lateCount.toDouble(),
                            title:
                                '${((_lateCount / _totalStudents) * 100).round()}%',
                            color: AppColorScheme.lateColor,
                            radius: 65,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(theme, 'Present', _presentCount,
                            AppColorScheme.presentColor),
                        SizedBox(height: AppDimensions.spacing12),
                        _buildLegendItem(theme, 'Absent', _absentCount,
                            AppColorScheme.absentColor),
                        SizedBox(height: AppDimensions.spacing12),
                        _buildLegendItem(theme, 'Late', _lateCount,
                            AppColorScheme.lateColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
      ThemeData theme, String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: AppDimensions.spacing8),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance List',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: AppDimensions.spacing16),
            if (_attendanceRecords.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.spacing16),
                  child: Text(
                    'No attendance records available',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = _attendanceRecords[index];
                  final studentName =
                      record['studentName'] ?? 'Unknown Student';
                  final status = record['status'] ?? 'present';
                  final timestamp =
                      (record['markedAt'] as Timestamp?)?.toDate();
                  final timeString = timestamp != null
                      ? DateTimeHelper.formatTime(timestamp)
                      : 'Unknown time';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: status == 'present'
                          ? AppColorScheme.presentColor.withOpacity(0.1)
                          : status == 'late'
                              ? AppColorScheme.lateColor.withOpacity(0.1)
                              : AppColorScheme.absentColor.withOpacity(0.1),
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: status == 'present'
                              ? AppColorScheme.presentColor
                              : status == 'late'
                                  ? AppColorScheme.lateColor
                                  : AppColorScheme.absentColor,
                        ),
                      ),
                    ),
                    title: Text(studentName),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        SizedBox(width: AppDimensions.spacing4),
                        Text('Marked at $timeString'),
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing12,
                        vertical: AppDimensions.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'present'
                            ? AppColorScheme.presentColor.withOpacity(0.1)
                            : status == 'late'
                                ? AppColorScheme.lateColor.withOpacity(0.1)
                                : AppColorScheme.absentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusSmall),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'present'
                              ? AppColorScheme.presentColor
                              : status == 'late'
                                  ? AppColorScheme.lateColor
                                  : AppColorScheme.absentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
