import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final List<Map<String, dynamic>> _classes = [];
  final Map<String, double> _attendanceData = {};
  final Map<String, int> _attendanceCountsByStatus = {};

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
        // Class data
        _classes.addAll([
          {
            'id': 'cs101',
            'name': 'Introduction to Computer Science',
            'code': 'CS101',
            'students': 45,
            'time': 'Mon, Wed, Fri 10:00 AM',
            'attendance': 92.5,
          },
          {
            'id': 'cs201',
            'name': 'Data Structures & Algorithms',
            'code': 'CS201',
            'students': 38,
            'time': 'Tue, Thu 1:00 PM',
            'attendance': 87.3,
          },
          {
            'id': 'cs301',
            'name': 'Database Systems',
            'code': 'CS301',
            'students': 32,
            'time': 'Mon, Wed 3:00 PM',
            'attendance': 84.7,
          },
          {
            'id': 'cs401',
            'name': 'Software Engineering',
            'code': 'CS401',
            'students': 28,
            'time': 'Fri 9:00 AM',
            'attendance': 88.2,
          },
        ]);

        // Attendance data
        _attendanceData.addAll({
          'CS101': 92.5,
          'CS201': 87.3,
          'CS301': 84.7,
          'CS401': 88.2,
        });

        // Attendance status counts
        _attendanceCountsByStatus.addAll({
          'Present': 124,
          'Absent': 18,
          'Late': 7,
          'Excused': 5,
        });
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
                    _buildRecentClasses(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create classroom screen
        },
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
      ),
    );
  }

  Widget _buildTeacherDrawer(BuildContext context) {
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
                  'Professor Smith',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  'teacher@attendwise.com',
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
              context.go(RouteNames.teacherClassrooms);
            },
          ),
          ListTile(
            leading: const Icon(Icons.how_to_reg),
            title: const Text('Attendance Sessions'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to attendance sessions screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to reports screen
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
                        'Welcome, Professor Smith',
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
          _buildSummaryCard(
              'Total Students', '143', Icons.people_outline, Colors.green),
          SizedBox(width: AppDimensions.spacing12),
          _buildSummaryCard(
              'Today\'s Sessions', '2', Icons.schedule, Colors.orange),
          SizedBox(width: AppDimensions.spacing12),
          _buildSummaryCard('Avg. Attendance', '88%',
              Icons.insert_chart_outlined, Colors.purple),
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

  Widget _buildRecentClasses() {
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
              onPressed: () => context.go(RouteNames.teacherClassrooms),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.spacing16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _classes.length > 3 ? 3 : _classes.length,
          itemBuilder: (context, index) {
            final classData = _classes[index];
            return Card(
              margin: EdgeInsets.only(bottom: AppDimensions.spacing12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    classData['code'].substring(0, 2),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(classData['name']),
                subtitle: Text(
                    '${classData['code']} - ${classData['students']} students'),
                trailing: Chip(
                  label: Text('${classData['attendance']}%'),
                  backgroundColor: _getAttendanceColor(classData['attendance'])
                      .withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: _getAttendanceColor(classData['attendance']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  context.go(
                      '${RouteNames.teacherClassroomDetail.replaceAll(':classroomId', '')}${classData['id']}');
                },
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
                  'Take Attendance',
                  Icons.how_to_reg,
                  theme.colorScheme.primary,
                  () {
                    // TODO: Navigate to start attendance session
                  },
                ),
                _buildQuickActionButton(
                  'Create Class',
                  Icons.add_circle_outline,
                  theme.colorScheme.secondary,
                  () {
                    // TODO: Navigate to create class
                  },
                ),
                _buildQuickActionButton(
                  'Generate Report',
                  Icons.assessment,
                  AppColorScheme.infoColor,
                  () {
                    // TODO: Navigate to reports
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
