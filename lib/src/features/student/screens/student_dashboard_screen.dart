import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/dimensions.dart';
import '../../../config/theme/color_schemes.dart';
import 'package:fl_chart/fl_chart.dart';

/// Student dashboard screen displaying enrolled classes and attendance statistics
class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _classes = [];
  final Map<String, int> _attendanceCounts = {};
  final List<Map<String, dynamic>> _upcomingClasses = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Fetch real data from Firebase
      await Future.delayed(const Duration(seconds: 1));

      // Sample data for demonstration
      setState(() {
        // Enrolled classes
        _classes.addAll([
          {
            'id': 'cs101',
            'name': 'Introduction to Computer Science',
            'code': 'CS101',
            'professor': 'Dr. Smith',
            'time': 'Mon, Wed, Fri 10:00 AM',
            'attendance': 95.0,
          },
          {
            'id': 'cs201',
            'name': 'Data Structures & Algorithms',
            'code': 'CS201',
            'professor': 'Dr. Johnson',
            'time': 'Tue, Thu 1:00 PM',
            'attendance': 88.5,
          },
          {
            'id': 'math101',
            'name': 'Calculus I',
            'code': 'MATH101',
            'professor': 'Dr. Williams',
            'time': 'Mon, Wed 2:00 PM',
            'attendance': 92.0,
          },
          {
            'id': 'eng101',
            'name': 'English Composition',
            'code': 'ENG101',
            'professor': 'Prof. Davis',
            'time': 'Fri 9:00 AM',
            'attendance': 82.5,
          },
        ]);

        // Attendance counts
        _attendanceCounts.addAll({
          'Present': 42,
          'Absent': 3,
          'Late': 5,
          'Excused': 2,
        });

        // Upcoming classes for today
        _upcomingClasses.addAll([
          {
            'id': 'cs101',
            'name': 'Introduction to Computer Science',
            'code': 'CS101',
            'time': '10:00 AM',
            'room': 'Science Building, Room 203',
          },
          {
            'id': 'math101',
            'name': 'Calculus I',
            'code': 'MATH101',
            'time': '2:00 PM',
            'room': 'Math Building, Room 105',
          },
        ]);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
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
        title: const Text('Student Dashboard'),
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
      drawer: _buildStudentDrawer(context),
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
                    _buildAttendanceOverview(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildTodayClasses(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildEnrolledClasses(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStudentDrawer(BuildContext context) {
    final theme = Theme.of(context);

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
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/account_circle.png'),
                ),
                SizedBox(height: AppDimensions.spacing8),
                Text(
                  'John Doe',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  'student@attendwise.com',
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
              context.go(RouteNames.studentClassrooms);
            },
          ),
          ListTile(
            leading: const Icon(Icons.how_to_reg),
            title: const Text('Attendance Record'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.studentAttendance);
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan QR Code'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to QR code scanner
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () {
              // TODO: Implement logout with Firebase Auth
              Navigator.pop(context);
              context.go(RouteNames.login);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final theme = Theme.of(context);

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
                        'Welcome, John',
                        style: theme.textTheme.headlineSmall,
                      ),
                      SizedBox(height: AppDimensions.spacing4),
                      Text(
                        'You have ${_upcomingClasses.length} classes today',
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
            if (_upcomingClasses.isNotEmpty) ...[
              SizedBox(height: AppDimensions.spacing16),
              Text(
                'Next class: ${_upcomingClasses[0]['name']} at ${_upcomingClasses[0]['time']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceOverview() {
    final theme = Theme.of(context);

    // Calculate overall attendance percentage
    final total =
        _attendanceCounts.values.fold<int>(0, (sum, value) => sum + value);
    final present =
        (_attendanceCounts['Present'] ?? 0) + (_attendanceCounts['Late'] ?? 0);
    final percentage = total > 0 ? (present / total) * 100 : 0.0;

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
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Attendance',
                        style: theme.textTheme.titleMedium,
                      ),
                      SizedBox(height: AppDimensions.spacing8),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: _getAttendanceColor(percentage),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacing8),
                      Text(
                        'Classes attended: $present / $total',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 160,
                    child: _buildAttendancePieChart(),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),
            Row(
              children: [
                _buildAttendanceIndicator(
                    'Present',
                    _attendanceCounts['Present'] ?? 0,
                    AppColorScheme.presentColor),
                SizedBox(width: AppDimensions.spacing24),
                _buildAttendanceIndicator(
                    'Absent',
                    _attendanceCounts['Absent'] ?? 0,
                    AppColorScheme.absentColor),
                SizedBox(width: AppDimensions.spacing24),
                _buildAttendanceIndicator('Late',
                    _attendanceCounts['Late'] ?? 0, AppColorScheme.lateColor),
                SizedBox(width: AppDimensions.spacing24),
                _buildAttendanceIndicator(
                    'Excused',
                    _attendanceCounts['Excused'] ?? 0,
                    AppColorScheme.excusedColor),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: AppDimensions.spacing4),
        Text(
          '$label: $count',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAttendancePieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: [
          PieChartSectionData(
            value: _attendanceCounts['Present']?.toDouble() ?? 0,
            title: '',
            color: AppColorScheme.presentColor,
            radius: 50,
          ),
          PieChartSectionData(
            value: _attendanceCounts['Absent']?.toDouble() ?? 0,
            title: '',
            color: AppColorScheme.absentColor,
            radius: 50,
          ),
          PieChartSectionData(
            value: _attendanceCounts['Late']?.toDouble() ?? 0,
            title: '',
            color: AppColorScheme.lateColor,
            radius: 50,
          ),
          PieChartSectionData(
            value: _attendanceCounts['Excused']?.toDouble() ?? 0,
            title: '',
            color: AppColorScheme.excusedColor,
            radius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayClasses() {
    final theme = Theme.of(context);

    if (_upcomingClasses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Classes',
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: AppDimensions.spacing16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _upcomingClasses.length,
          itemBuilder: (context, index) {
            final classData = _upcomingClasses[index];
            final isNext = index == 0;

            return Card(
              margin: EdgeInsets.only(bottom: AppDimensions.spacing12),
              color: isNext ? theme.colorScheme.primary.withOpacity(0.1) : null,
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.spacing16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isNext
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary.withOpacity(0.7),
                      child: Icon(
                        isNext ? Icons.access_time : Icons.class_,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(width: AppDimensions.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classData['name'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppDimensions.spacing4),
                          Text(
                            '${classData['code']} • ${classData['time']}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: AppDimensions.spacing4),
                          Text(
                            classData['room'],
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isNext)
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to attendance marking
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Mark'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
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

  Widget _buildEnrolledClasses() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Classes',
              style: theme.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.studentClassrooms),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.spacing16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _classes.length > 4 ? 4 : _classes.length,
          itemBuilder: (context, index) {
            final classData = _classes[index];
            return Card(
              elevation: AppDimensions.cardElevation,
              child: InkWell(
                onTap: () {
                  context.go(
                      '${RouteNames.studentClassroomDetail.replaceAll(':classroomId', '')}${classData['id']}');
                },
                borderRadius:
                    BorderRadius.circular(AppDimensions.cardBorderRadius),
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              classData['code'].substring(0, 2),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacing8,
                              vertical: AppDimensions.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _getAttendanceColor(classData['attendance'])
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.borderRadiusSmall),
                            ),
                            child: Text(
                              '${classData['attendance']}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getAttendanceColor(
                                    classData['attendance']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimensions.spacing8),
                      Text(
                        classData['code'],
                        style: theme.textTheme.titleSmall,
                      ),
                      SizedBox(height: AppDimensions.spacing4),
                      Text(
                        classData['name'],
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        'Prof. ${classData['professor']}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
                  'Scan QR Code',
                  Icons.qr_code_scanner,
                  theme.colorScheme.primary,
                  () {
                    // TODO: Navigate to QR code scanner
                  },
                ),
                _buildQuickActionButton(
                  'Attendance Report',
                  Icons.assessment,
                  theme.colorScheme.secondary,
                  () {
                    context.go(RouteNames.studentAttendance);
                  },
                ),
                _buildQuickActionButton(
                  'Class Schedule',
                  Icons.calendar_month,
                  AppColorScheme.infoColor,
                  () {
                    // TODO: Navigate to schedule view
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
}
