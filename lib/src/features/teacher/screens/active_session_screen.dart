import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async'; // Added for StreamSubscription and Timer

import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/dimensions.dart'; // Added for AppDimensions
import '../../../config/theme/color_schemes.dart'; // Added for AppColorScheme
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/utils/date_time_helper.dart';

/// Screen for managing an active attendance session
class ActiveSessionScreen extends ConsumerStatefulWidget {
  /// ID of the active attendance session
  final String sessionId;

  const ActiveSessionScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _classroom;
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _attendanceRequests = [];

  // For real-time updates
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  StreamSubscription<QuerySnapshot>? _attendanceSubscription;
  StreamSubscription<QuerySnapshot>? _requestsSubscription;

  // Timer for session countdown
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _attendanceSubscription?.cancel();
    _requestsSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Listen for changes to the session document
      final sessionRef = FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(widget.sessionId);

      _sessionSubscription = sessionRef.snapshots().listen(
        (snapshot) async {
          if (!snapshot.exists) {
            // Session was deleted or doesn't exist
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance session no longer exists'),
                  backgroundColor: Colors.red,
                ),
              );
              context.go(RouteNames.teacherDashboard);
            }
            return;
          }

          final sessionData = snapshot.data()!;

          // If session is closed, navigate to summary screen
          if (sessionData['status'] == 'closed' && mounted) {
            context.go(
                '${RouteNames.teacherSessionSummary.replaceAll(':sessionId', '')}${widget.sessionId}');
            return;
          }

          // Load classroom data if needed
          if (_classroom == null) {
            final classroomId = sessionData['classroomId'];
            final classroomSnapshot = await FirebaseFirestore.instance
                .collection('classrooms')
                .doc(classroomId)
                .get();

            if (classroomSnapshot.exists) {
              if (mounted) {
                setState(() {
                  _classroom = {
                    'id': classroomSnapshot.id,
                    ...classroomSnapshot.data()!
                  };
                });
              }
            }
          }

          // Update session data
          if (mounted) {
            setState(() {
              _session = {
                'id': snapshot.id,
                ...sessionData,
              };

              // Update remaining time
              if (sessionData['endTime'] != null) {
                final endTime = (sessionData['endTime'] as Timestamp).toDate();
                final now = DateTime.now();

                if (endTime.isAfter(now)) {
                  _remainingTime = endTime.difference(now);
                  _startCountdownTimer();
                } else {
                  _remainingTime = Duration.zero;
                }
              }
            });
          }
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading session: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );

      // Listen for attendance records for this session
      _attendanceSubscription = FirebaseFirestore.instance
          .collection('attendance_records')
          .where('sessionId', isEqualTo: widget.sessionId)
          .snapshots()
          .listen(
        (snapshot) {
          final records = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList();

          if (mounted) {
            setState(() {
              _attendanceRecords = records;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Error loading attendance records: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );

      // Listen for attendance requests for this session
      _requestsSubscription = FirebaseFirestore.instance
          .collection('attendance_requests')
          .where('sessionId', isEqualTo: widget.sessionId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen(
        (snapshot) {
          final requests = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList();

          if (mounted) {
            setState(() {
              _attendanceRequests = requests;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Error loading attendance requests: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
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

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _endAttendanceSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Attendance Session'),
        content: const Text(
          'Are you sure you want to end this attendance session? This will close the session for all students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Update session status to closed
      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(widget.sessionId)
          .update({
        'status': 'closed',
        'endTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance session ended successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to session summary
        context.go(
            '${RouteNames.teacherSessionSummary.replaceAll(':sessionId', '')}${widget.sessionId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end session: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extendSessionDuration(int additionalMinutes) async {
    try {
      // Get current end time
      final currentEndTime = (_session?['endTime'] as Timestamp?)?.toDate();
      if (currentEndTime == null) return;

      // Calculate new end time
      final newEndTime =
          currentEndTime.add(Duration(minutes: additionalMinutes));

      // Update session
      await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(widget.sessionId)
          .update({
        'endTime': newEndTime,
        'duration': FieldValue.increment(additionalMinutes),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session extended by $additionalMinutes minutes'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to extend session: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExtendSessionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int additionalMinutes = 10; // Default

        return AlertDialog(
          title: const Text('Extend Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How many additional minutes do you want to add?'),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: additionalMinutes,
                items: [5, 10, 15, 30, 45, 60].map((minutes) {
                  return DropdownMenuItem<int>(
                    value: minutes,
                    child: Text('$minutes minutes'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    additionalMinutes = value;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _extendSessionDuration(additionalMinutes);
              },
              child: const Text('Extend'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processAttendanceRequest(
      Map<String, dynamic> request, bool approve) async {
    try {
      // Update request status
      await FirebaseFirestore.instance
          .collection('attendance_requests')
          .doc(request['id'])
          .update({
        'status': approve ? 'approved' : 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });

      // If approved, create attendance record
      if (approve) {
        await FirebaseFirestore.instance.collection('attendance_records').add({
          'sessionId': widget.sessionId,
          'studentId': request['studentId'],
          'studentName': request['studentName'],
          'classroomId': _session?['classroomId'],
          'status': 'present',
          'markedAt': request['createdAt'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update actual headcount
        await FirebaseFirestore.instance
            .collection('attendance_sessions')
            .doc(widget.sessionId)
            .update({
          'actualHeadcount': FieldValue.increment(1),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ${approve ? 'approved' : 'rejected'}'),
          backgroundColor: approve ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return '${hours}:${minutes}:${seconds}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Attendance Session'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timelapse),
            onPressed: _showExtendSessionDialog,
            tooltip: 'Extend Session',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                _buildSessionHeader(),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: theme.colorScheme.primary,
                          tabs: [
                            Tab(
                              icon: const Icon(Icons.how_to_reg),
                              text: 'Attendance (${_attendanceRecords.length})',
                            ),
                            Tab(
                              icon: Badge(
                                isLabelVisible: _attendanceRequests.isNotEmpty,
                                label: Text('${_attendanceRequests.length}'),
                                child: const Icon(Icons.request_page),
                              ),
                              text: 'Requests',
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildAttendanceTab(),
                              _buildRequestsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSessionHeader() {
    final theme = Theme.of(context);

    if (_session == null || _classroom == null) {
      return const SizedBox.shrink();
    }

    final sessionTopic = _session!['topic'] ?? 'Untitled Session';
    final sessionType = _session!['type'] ?? 'Regular';
    final classroomName = _classroom!['name'] ?? 'Unknown Class';
    final classCode = _classroom!['code'] ?? '';
    final section = _classroom!['section'] ?? '';

    return Container(
      color: theme.colorScheme.surfaceVariant,
      padding: EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.class_,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: AppDimensions.spacing8),
              Expanded(
                child: Text(
                  classroomName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing12,
                  vertical: AppDimensions.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColorScheme.warningColor.withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 16,
                      color: AppColorScheme.warningColor,
                    ),
                    SizedBox(width: AppDimensions.spacing4),
                    Text(
                      _formatDuration(_remainingTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColorScheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spacing8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionTopic,
                      style: theme.textTheme.bodyLarge,
                    ),
                    SizedBox(height: AppDimensions.spacing4),
                    Text(
                      '$sessionType • $classCode Section $section',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Students Present',
                    style: theme.textTheme.bodySmall,
                  ),
                  SizedBox(height: AppDimensions.spacing4),
                  Text(
                    '${_attendanceRecords.length} / ${_session!['expectedHeadcount'] ?? '?'}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    final theme = Theme.of(context);

    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: AppDimensions.spacing16),
            Text(
              'No attendees yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              'Students will appear here once they mark their attendance',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppDimensions.spacing16),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        final studentName = record['studentName'] ?? 'Unknown Student';
        final timestamp = (record['markedAt'] as Timestamp?)?.toDate();
        final timeString = timestamp != null
            ? DateTimeHelper.formatTime(timestamp)
            : 'Unknown time';

        return Card(
          margin: EdgeInsets.only(bottom: AppDimensions.spacing12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
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
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show options (e.g., to remove attendance)
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final theme = Theme.of(context);

    if (_attendanceRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: AppDimensions.spacing16),
            Text(
              'No pending requests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              'Student attendance requests will appear here',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppDimensions.spacing16),
      itemCount: _attendanceRequests.length,
      itemBuilder: (context, index) {
        final request = _attendanceRequests[index];
        final studentName = request['studentName'] ?? 'Unknown Student';
        final reason = request['reason'] ?? 'No reason provided';
        final timestamp = (request['createdAt'] as Timestamp?)?.toDate();
        final timeString = timestamp != null
            ? DateTimeHelper.formatTime(timestamp)
            : 'Unknown time';

        return Card(
          margin: EdgeInsets.only(bottom: AppDimensions.spacing12),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    SizedBox(width: AppDimensions.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: theme.textTheme.titleMedium,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              SizedBox(width: AppDimensions.spacing4),
                              Text(
                                'Requested at $timeString',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.spacing12),
                Text(
                  'Reason:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.spacing4),
                Text(reason),
                SizedBox(height: AppDimensions.spacing16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _processAttendanceRequest(request, false),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColorScheme.absentColor,
                      ),
                    ),
                    SizedBox(width: AppDimensions.spacing12),
                    ElevatedButton.icon(
                      onPressed: () => _processAttendanceRequest(request, true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.presentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: ElevatedButton.icon(
          onPressed: _endAttendanceSession,
          icon: const Icon(Icons.stop_circle),
          label: const Text('End Session'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }
}
