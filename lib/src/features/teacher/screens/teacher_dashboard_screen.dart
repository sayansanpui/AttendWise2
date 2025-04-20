import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../backend/repositories/classroom_repository.dart';
import '../../../backend/models/classroom_model.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/dimensions.dart';
import '../../../config/theme/color_schemes.dart';
import 'package:fl_chart/fl_chart.dart';

/// Teacher dashboard screen displaying classes, attendance and student information
class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  bool _isLoading = false;
  final _classroomRepository = ClassroomRepository();
  String? _teacherId;

  // Data variables
  List<ClassroomModel> _classes = [];
  Map<String, double> _attendanceData = {};
  Map<String, int> _attendanceCountsByStatus = {};
  List<Map<String, dynamic>> _recentSessions = [];
  int _totalStudents = 0;
  int _todaySessions = 0;
  double _avgAttendance = 0.0;

  @override
  void initState() {
    super.initState();
    _teacherId = FirebaseAuth.instance.currentUser?.uid;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_teacherId == null) {
      // Not logged in as a teacher
      context.go(RouteNames.login);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Load classes
      final classes =
          await _classroomRepository.getClassroomsByTeacher(_teacherId!);

      // Calculate total students
      int totalStudents = 0;
      for (var classroom in classes) {
        totalStudents += classroom.studentCount;
      }

      // Calculate attendance data
      Map<String, double> attendanceData = {};
      double totalAttendanceRate = 0;
      for (var classroom in classes) {
        attendanceData[classroom.code] = classroom.attendanceRate;
        totalAttendanceRate += classroom.attendanceRate;
      }

      // Get average attendance
      double avgAttendance =
          classes.isNotEmpty ? totalAttendanceRate / classes.length : 0;

      // Get today's sessions count
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get attendance stats
      Map<String, int>? attendanceStats = {
        'Present': 0,
        'Absent': 0,
        'Late': 0,
        'Excused': 0,
      };

      // If there are classes, get attendance stats for the first class
      if (classes.isNotEmpty) {
        attendanceStats = (await _classroomRepository
            .getAttendanceStats(classes[0].classroomId)).cast<String, int>();
      }

      // Get recent sessions
      final recentSessions =
          await _classroomRepository.getRecentSessions(_teacherId!);

      // Calculate today's sessions
      int todaySessions = 0;
      for (var session in recentSessions) {
        final sessionDate = (session['date'] as DateTime);
        if (sessionDate.year == today.year &&
            sessionDate.month == today.month &&
            sessionDate.day == today.day) {
          todaySessions++;
        }
      }

      // Update state with fetched data
      if (mounted) {
        setState(() {
          _classes = classes;
          _attendanceData = attendanceData;
          _attendanceCountsByStatus = attendanceStats!;
          _recentSessions = recentSessions;
          _totalStudents = totalStudents;
          _todaySessions = todaySessions;
          _avgAttendance = avgAttendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(RouteNames.notifications),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(RouteNames.profile),
            tooltip: 'Profile',
          ),
        ],
      ),
      drawer: _buildTeacherDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppDimensions.screenPadding),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildClassSummaryCards(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildAttendanceStats(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildActiveClassesCards(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildRecentAttendanceSessions(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RouteNames.createClassroom);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
      ),
    );
  }

  Widget _buildTeacherDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Teacher';
    final email = user?.email ?? '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!) as ImageProvider
                      : const AssetImage('assets/account_circle.png'),
                ),
                SizedBox(height: AppDimensions.spacing8),
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('My Classes'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.teacherClassrooms);
            },
          ),
          ListTile(
            leading: const Icon(Icons.how_to_reg),
            title: const Text('Attendance Sessions'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.teacherSessions);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.teacherReports);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
                // Navigate to login screen
                if (context.mounted) {
                  context.go(RouteNames.login);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to log out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Teacher';

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  radius: 24,
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: AppDimensions.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $displayName',
                        style: theme.textTheme.headlineSmall,
                      ),
                      SizedBox(height: AppDimensions.spacing4),
                      Text(
                        'You have ${_classes.length} active classes',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),
            Text(
              'Current date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSummaryCards() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard('Active Classes', _classes.length.toString(),
              Icons.class_outlined, Colors.blue),
          SizedBox(width: AppDimensions.spacing12),
          _buildSummaryCard('Total Students', _totalStudents.toString(),
              Icons.people_outline, Colors.green),
          SizedBox(width: AppDimensions.spacing12),
          _buildSummaryCard('Today\'s Sessions', _todaySessions.toString(),
              Icons.schedule, Colors.orange),
          SizedBox(width: AppDimensions.spacing12),
          _buildSummaryCard(
              'Avg. Attendance',
              '${_avgAttendance.toStringAsFixed(1)}%',
              Icons.insert_chart_outlined,
              Colors.purple),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Container(
        width: 160,
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Overview',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: AppDimensions.spacing16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 200,
                    child: _buildAttendancePieChart(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAttendanceIndicator(
                          'Present',
                          _attendanceCountsByStatus['Present'] ?? 0,
                          AppColorScheme.presentColor),
                      SizedBox(height: AppDimensions.spacing8),
                      _buildAttendanceIndicator(
                          'Absent',
                          _attendanceCountsByStatus['Absent'] ?? 0,
                          AppColorScheme.absentColor),
                      SizedBox(height: AppDimensions.spacing8),
                      _buildAttendanceIndicator(
                          'Late',
                          _attendanceCountsByStatus['Late'] ?? 0,
                          AppColorScheme.lateColor),
                      SizedBox(height: AppDimensions.spacing8),
                      _buildAttendanceIndicator(
                          'Excused',
                          _attendanceCountsByStatus['Excused'] ?? 0,
                          AppColorScheme.excusedColor),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceIndicator(String label, int count, Color color) {
    final theme = Theme.of(context);

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

  Widget _buildAttendancePieChart() {
    final total = _attendanceCountsByStatus.values
        .fold<int>(0, (sum, value) => sum + value);

    if (total == 0) {
      return Center(
        child: Text(
          'No attendance data yet',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: _attendanceCountsByStatus['Present']?.toDouble() ?? 0,
            title:
                '${((_attendanceCountsByStatus['Present'] ?? 0) / total * 100).toStringAsFixed(0)}%',
            color: AppColorScheme.presentColor,
            radius: 60,
          ),
          PieChartSectionData(
            value: _attendanceCountsByStatus['Absent']?.toDouble() ?? 0,
            title:
                '${((_attendanceCountsByStatus['Absent'] ?? 0) / total * 100).toStringAsFixed(0)}%',
            color: AppColorScheme.absentColor,
            radius: 60,
          ),
          PieChartSectionData(
            value: _attendanceCountsByStatus['Late']?.toDouble() ?? 0,
            title:
                '${((_attendanceCountsByStatus['Late'] ?? 0) / total * 100).toStringAsFixed(0)}%',
            color: AppColorScheme.lateColor,
            radius: 65,
          ),
          PieChartSectionData(
            value: _attendanceCountsByStatus['Excused']?.toDouble() ?? 0,
            title:
                '${((_attendanceCountsByStatus['Excused'] ?? 0) / total * 100).toStringAsFixed(0)}%',
            color: AppColorScheme.excusedColor,
            radius: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveClassesCards() {
    final theme = Theme.of(context);

    if (_classes.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacing16),
          child: Column(
            children: [
              const Icon(
                Icons.class_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: AppDimensions.spacing8),
              Text(
                'No classes yet',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: AppDimensions.spacing8),
              Text(
                'Create your first class by clicking the "New Class" button below',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: AppDimensions.spacing16),
              ElevatedButton.icon(
                onPressed: () {
                  context.push(RouteNames.createClassroom);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Class'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Classes',
              style: theme.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.teacherClassrooms),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.spacing16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final classroom = _classes[index];
              return Card(
                margin: EdgeInsets.only(right: AppDimensions.spacing16),
                child: Container(
                  width: 280,
                  padding: EdgeInsets.all(AppDimensions.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              classroom.code
                                  .substring(0, min(2, classroom.code.length)),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: AppDimensions.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  classroom.name,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  classroom.code,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimensions.spacing12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildClassInfoItem(Icons.people,
                              '${classroom.studentCount} Students'),
                          _buildClassInfoItem(Icons.room, classroom.room),
                        ],
                      ),
                      SizedBox(height: AppDimensions.spacing8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildClassInfoItem(
                              Icons.calendar_today, classroom.time),
                          _buildClassInfoItem(Icons.school, classroom.level),
                        ],
                      ),
                      SizedBox(height: AppDimensions.spacing12),
                      LinearProgressIndicator(
                        value: classroom.totalSessions > 0
                            ? classroom.completedSessions /
                                classroom.totalSessions
                            : 0.0,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: AppDimensions.spacing4),
                      Text(
                        'Progress: ${classroom.completedSessions}/${classroom.totalSessions} Sessions',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(
                                '${classroom.attendanceRate.toStringAsFixed(1)}%'),
                            backgroundColor:
                                _getAttendanceColor(classroom.attendanceRate)
                                    .withOpacity(0.1),
                            labelStyle: TextStyle(
                              color:
                                  _getAttendanceColor(classroom.attendanceRate),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              context.go(
                                  '${RouteNames.teacherClassroomDetail.replaceAll(':classroomId', '')}${classroom.classroomId}');
                            },
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClassInfoItem(IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRecentAttendanceSessions() {
    final theme = Theme.of(context);

    if (_recentSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacing16),
          child: Column(
            children: [
              Text(
                'Recent Attendance Sessions',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: AppDimensions.spacing16),
              const Icon(
                Icons.history,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: AppDimensions.spacing8),
              Text(
                'No recent attendance sessions',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: AppDimensions.spacing8),
              Text(
                'Start taking attendance in your classes to see records here',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Attendance Sessions',
              style: theme.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.teacherSessions),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.spacing16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentSessions.length > 3 ? 3 : _recentSessions.length,
          itemBuilder: (context, index) {
            final session = _recentSessions[index];
            final attendancePercentage = session['totalStudents'] > 0
                ? (session['studentsPresent'] / session['totalStudents']) * 100
                : 0.0;

            return Card(
              margin: EdgeInsets.only(bottom: AppDimensions.spacing12),
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.spacing16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            session['classCode'].substring(
                                0, min(2, session['classCode'].length)),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimensions.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session['className'],
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_formatDate(session['date'] as DateTime)} | ${session['duration']} mins',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                              '${attendancePercentage.toStringAsFixed(1)}%'),
                          backgroundColor:
                              _getAttendanceColor(attendancePercentage)
                                  .withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: _getAttendanceColor(attendancePercentage),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.spacing12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance: ${session['studentsPresent']}/${session['totalStudents']} students',
                          style: theme.textTheme.bodyMedium,
                        ),
                        OutlinedButton(
                          onPressed: () {
                            context.push(
                                '${RouteNames.teacherSessionSummary.replaceAll(':sessionId', '')}${session['id']}');
                          },
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: AppDimensions.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  'Take Attendance',
                  Icons.how_to_reg,
                  theme.colorScheme.primary,
                  () {
                    if (_classes.isNotEmpty) {
                      context.push(
                          '${RouteNames.teacherStartAttendance.replaceAll(':classroomId', '')}${_classes[0].classroomId}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You need to create a class first'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      context.push(RouteNames.createClassroom);
                    }
                  },
                ),
                _buildQuickActionButton(
                  'Create Class',
                  Icons.add_circle_outline,
                  theme.colorScheme.secondary,
                  () {
                    context.push(RouteNames.createClassroom);
                  },
                ),
                _buildQuickActionButton(
                  'Generate Report',
                  Icons.assessment,
                  AppColorScheme.infoColor,
                  () {
                    context.push(RouteNames.teacherReports);
                  },
                ),
                _buildQuickActionButton(
                  'Upload Material',
                  Icons.upload_file,
                  AppColorScheme.successColor,
                  () {
                    if (_classes.isNotEmpty) {
                      context.push(
                          '${RouteNames.teacherClassroomMaterials.replaceAll(':classroomId', '')}${_classes[0].classroomId}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You need to create a class first'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      context.push(RouteNames.createClassroom);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      child: Container(
        width: 100,
        padding: EdgeInsets.all(AppDimensions.spacing8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) {
      return AppColorScheme.presentColor;
    } else if (percentage >= 80) {
      return AppColorScheme.successColor;
    } else if (percentage >= 70) {
      return AppColorScheme.warningColor;
    } else {
      return AppColorScheme.absentColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}
