import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_theme.dart';
import '../../../config/theme/dimensions.dart'; // Added for AppDimensions
import '../../../config/theme/color_schemes.dart'; // Added for AppColorScheme
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/utils/date_time_helper.dart';
import '../../shared/widgets/loading_button.dart'; // Added for LoadingButton
import '../../../config/routes/route_names.dart';

/// Screen for starting a new attendance session for a specific classroom
class StartAttendanceScreen extends ConsumerStatefulWidget {
  /// Classroom ID for which attendance is being taken
  final String classroomId;

  const StartAttendanceScreen({
    super.key,
    required this.classroomId,
  });

  @override
  ConsumerState<StartAttendanceScreen> createState() =>
      _StartAttendanceScreenState();
}

class _StartAttendanceScreenState extends ConsumerState<StartAttendanceScreen> {
  bool _isLoading = true;
  bool _isStartingSession = false;
  Map<String, dynamic>? _classroom;

  // Form controllers
  final _topicController = TextEditingController();
  final _headcountController = TextEditingController();
  final _durationController =
      TextEditingController(text: '60'); // Default 60 minutes
  bool _enableHeadcountVerification = true;
  String _selectedAttendanceType = 'Regular';

  // Attendance type options
  final List<String> _attendanceTypes = [
    'Regular',
    'Lab',
    'Tutorial',
    'Extra Class'
  ];

  @override
  void initState() {
    super.initState();
    _loadClassroomDetails();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _headcountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadClassroomDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get classroom details from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroomId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Classroom not found');
      }

      if (mounted) {
        setState(() {
          _classroom = {
            'id': docSnapshot.id,
            ...docSnapshot.data()!,
          };

          // Pre-fill headcount with student count if available
          final studentCount = _classroom?['studentCount'] ?? 0;
          if (studentCount > 0) {
            _headcountController.text = studentCount.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load classroom details: ${e.toString()}'),
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

  Future<void> _startAttendanceSession() async {
    // Validate inputs
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a topic for the session'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration in minutes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? headcount;
    if (_enableHeadcountVerification) {
      headcount = int.tryParse(_headcountController.text);
      if (headcount == null || headcount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid headcount for verification'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isStartingSession = true;
    });

    try {
      // Get current teacher ID
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) {
        throw Exception('User not authenticated');
      }

      // Create attendance session document
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: duration));

      final session = {
        'classroomId': widget.classroomId,
        'teacherId': teacherId,
        'topic': _topicController.text.trim(),
        'type': _selectedAttendanceType,
        'startTime': now,
        'endTime': endTime,
        'duration': duration,
        'status': 'active',
        'headcountVerification': _enableHeadcountVerification,
        'expectedHeadcount': headcount,
        'actualHeadcount': 0, // Will be updated as students mark attendance
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Create session in Firestore
      final sessionRef = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .add(session);

      // Update classroom with totalSessions count
      await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroomId)
          .update({
        'totalSessions': FieldValue.increment(1),
        'lastSessionId': sessionRef.id,
        'lastSessionTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance session started successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to active session screen
        context.push(
            '${RouteNames.teacherActiveSession.replaceAll(':sessionId', '')}${sessionRef.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to start attendance session: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingSession = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Attendance'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClassroomInfoCard(),
                  SizedBox(height: AppDimensions.spacing24),

                  Text(
                    'Session Details',
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: AppDimensions.spacing16),

                  // Session topic field
                  TextFormField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      labelText: 'Topic',
                      hintText: 'e.g. Introduction to Arrays',
                      prefixIcon: const Icon(Icons.subject),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusMedium),
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacing16),

                  // Session type dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Session Type',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusMedium),
                      ),
                    ),
                    value: _selectedAttendanceType,
                    items: _attendanceTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedAttendanceType = newValue;
                        });
                      }
                    },
                  ),
                  SizedBox(height: AppDimensions.spacing16),

                  // Session duration field
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      hintText: 'e.g. 60',
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadiusMedium),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: AppDimensions.spacing24),

                  // Headcount verification section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimensions.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Headcount Verification',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    SizedBox(height: AppDimensions.spacing4),
                                    Text(
                                      'Verify attendance against expected number of students',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _enableHeadcountVerification,
                                onChanged: (value) {
                                  setState(() {
                                    _enableHeadcountVerification = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_enableHeadcountVerification) ...[
                            SizedBox(height: AppDimensions.spacing16),
                            TextFormField(
                              controller: _headcountController,
                              decoration: InputDecoration(
                                labelText: 'Expected Headcount',
                                hintText: 'Number of students expected',
                                prefixIcon: const Icon(Icons.people),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.borderRadiusMedium),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacing32),

                  // Start attendance button
                  LoadingButton(
                    isLoading: _isStartingSession,
                    onPressed: _startAttendanceSession,
                    text: 'Start Attendance Session',
                    loadingText: 'Starting...',
                    icon: Icons.play_circle_outline,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildClassroomInfoCard() {
    final theme = Theme.of(context);

    if (_classroom == null) {
      return const SizedBox.shrink();
    }

    final classroomName = _classroom!['name'] ?? 'Unnamed Class';
    final classCode = _classroom!['code'] ?? '';
    final section = _classroom!['section'] ?? '';
    final semester = _classroom!['semester'] ?? '';
    final stream = _classroom!['stream'] ?? '';

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
            SizedBox(height: AppDimensions.spacing12),
            Divider(),
            SizedBox(height: AppDimensions.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildClassroomStat('Semester', semester),
                _buildClassroomStat('Stream', stream),
                _buildClassroomStat(
                    'Students', '${_classroom!['studentCount'] ?? 0}'),
              ],
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              'Current date: ${DateTimeHelper.formatDate(DateTime.now())}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomStat(String label, String value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        SizedBox(height: AppDimensions.spacing4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
