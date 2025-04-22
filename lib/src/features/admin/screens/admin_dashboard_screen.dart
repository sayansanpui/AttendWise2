import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/dimensions.dart';
import '../../../config/theme/color_schemes.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../backend/services/firebase_service.dart';
import '../../../backend/models/user_model.dart';
import '../widgets/data_import_dialog.dart';
import '../widgets/credential_generator_dialog.dart';
import '../widgets/system_config_dialog.dart';
import '../widgets/user_creation_dialog.dart';
import '../widgets/attendance_overview_widget.dart';
import '../widgets/attendance_analytics_widget.dart';

/// Admin dashboard screen displaying key statistics and management options
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = false;
  final Map<String, double> _attendanceData = {};
  final Map<String, int> _userCounts = {};
  final List<Map<String, dynamic>> _recentAttendance = [];
  final FirebaseService _firebaseService = FirebaseService();

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
        // Attendance data by department
        _attendanceData.addAll({
          'Computer Science': 87.5,
          'Electrical Engineering': 82.1,
          'Mechanical Engineering': 78.3,
          'Civil Engineering': 85.7,
          'Business Administration': 73.9,
        });

        // User counts by role
        _userCounts.addAll({
          'Students': 1250,
          'Teachers': 75,
          'Admins': 5,
        });

        // Sample recent attendance data
        _recentAttendance.addAll([
          {
            'teacher': 'Dr. Smith',
            'class': 'Advanced Programming',
            'time': '10:15 AM',
            'date': 'Today',
            'attendance_rate': 92.5,
            'total_students': 40,
            'present': 37,
          },
          {
            'teacher': 'Prof. Johnson',
            'class': 'Data Structures',
            'time': '09:00 AM',
            'date': 'Today',
            'attendance_rate': 88.0,
            'total_students': 50,
            'present': 44,
          },
          {
            'teacher': 'Dr. Williams',
            'class': 'Database Systems',
            'time': '02:30 PM',
            'date': 'Yesterday',
            'attendance_rate': 76.5,
            'total_students': 34,
            'present': 26,
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
        title: const Text('Admin Dashboard'),
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
      drawer: _buildAdminDrawer(context),
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
                    _buildWelcomeHeader(),
                    SizedBox(height: AppDimensions.spacing16),
                    _buildStatisticsCards(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildRecentAttendanceOverview(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildAttendanceChart(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildAdminActions(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionMenu,
        tooltip: 'Quick Actions',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showActionMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.person_add, color: theme.colorScheme.primary),
              title: const Text('Create New Teacher'),
              onTap: () {
                Navigator.pop(context);
                _showCreateTeacherDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.school, color: theme.colorScheme.primary),
              title: const Text('Create New Student'),
              onTap: () {
                Navigator.pop(context);
                _showCreateStudentDialog();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.upload_file, color: theme.colorScheme.primary),
              title: const Text('Import Data'),
              onTap: () {
                Navigator.pop(context);
                _showImportDataDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.key, color: theme.colorScheme.primary),
              title: const Text('Generate User Credentials'),
              onTap: () {
                Navigator.pop(context);
                _showCredentialGeneratorDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment, color: theme.colorScheme.primary),
              title: const Text('Generate Attendance Report'),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.adminReports);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.primary),
              title: const Text('System Configuration'),
              onTap: () {
                Navigator.pop(context);
                _showSystemConfigDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => const DataImportDialog(),
    );
  }

  void _showCredentialGeneratorDialog() {
    showDialog(
      context: context,
      builder: (context) => const CredentialGeneratorDialog(),
    );
  }

  void _showSystemConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => const SystemConfigDialog(),
    );
  }

  void _showCreateTeacherDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          const UserCreationDialog(userRole: UserRole.teacher),
    );
  }

  void _showCreateStudentDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          const UserCreationDialog(userRole: UserRole.student),
    );
  }

  Widget _buildWelcomeHeader() {
    final theme = Theme.of(context);
    final now = DateTime.now();
    String greeting;

    if (now.hour < 12) {
      greeting = 'Good morning';
    } else if (now.hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.titleMedium,
        ),
        Text(
          'Admin Dashboard',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Monitor and manage all system activities',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildAdminDrawer(BuildContext context) {
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
                  'Admin User',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  'admin@attendwise.com',
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
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.adminUsers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Student Management'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.adminManageStudents);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Teacher Management'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.adminManageTeachers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Departments'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.adminDepartments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('Classrooms'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.adminManageClasses);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.adminReports);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.adminSettings);
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

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppDimensions.spacing16,
      mainAxisSpacing: AppDimensions.spacing16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Students', _userCounts['Students'] ?? 0,
            Icons.school, Colors.blue),
        _buildStatCard('Total Teachers', _userCounts['Teachers'] ?? 0,
            Icons.person, Colors.green),
        _buildStatCard('Total Admins', _userCounts['Admins'] ?? 0,
            Icons.admin_panel_settings, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              value.toString(),
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: AppDimensions.spacing4),
            Text(
              title,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAttendanceOverview() {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Attendance',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => context.go(RouteNames.adminReports),
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),
            for (final attendance in _recentAttendance) ...[
              _buildAttendanceItem(attendance),
              if (attendance != _recentAttendance.last)
                Divider(height: AppDimensions.spacing24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> attendance) {
    final theme = Theme.of(context);
    final rate = attendance['attendance_rate'] as double;
    final color = rate >= 90
        ? Colors.green
        : rate >= 75
            ? Colors.orange
            : Colors.red;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attendance['class'],
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: AppDimensions.spacing4),
              Text(
                'by ${attendance['teacher']}',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: AppDimensions.spacing4),
              Text(
                '${attendance['time']} • ${attendance['date']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: AppDimensions.spacing16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppDimensions.spacing4),
            Text(
              '${attendance['present']}/${attendance['total_students']} students',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Department Attendance Overview',
                  style: theme.textTheme.titleLarge,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    // Handle different view options (daily, weekly, monthly)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: $value')),
                    );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'daily',
                      child: Text('Daily View'),
                    ),
                    const PopupMenuItem(
                      value: 'weekly',
                      child: Text('Weekly View'),
                    ),
                    const PopupMenuItem(
                      value: 'monthly',
                      child: Text('Monthly View'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              'Average attendance percentage by department',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: AppDimensions.spacing16),
            SizedBox(
              height: AppDimensions.chartHeight,
              child: _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final theme = Theme.of(context);
    final barGroups = <BarChartGroupData>[];

    int index = 0;
    _attendanceData.forEach((department, percentage) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: percentage,
              color: theme.colorScheme.primary,
              width: 20,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
          ],
        ),
      );
      index++;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < _attendanceData.length) {
                  final department =
                      _attendanceData.keys.elementAt(value.toInt());
                  final words = department.split(' ');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      words.length > 1
                          ? '${words[0]}\n${words[1]}'
                          : department,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value % 20 == 0) {
                  return Text(
                    '${value.toInt()}%',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 20,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              width: 1,
            ),
            left: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActions() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Administrative Controls',
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: AppDimensions.spacing16),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: AppDimensions.spacing16,
          mainAxisSpacing: AppDimensions.spacing16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(
              'Add Teacher',
              Icons.person_add,
              Colors.green,
              _showCreateTeacherDialog,
            ),
            _buildActionCard(
              'Add Student',
              Icons.school_outlined,
              Colors.blue,
              _showCreateStudentDialog,
            ),
            _buildActionCard(
              'User Management',
              Icons.people,
              theme.colorScheme.primary,
              () => context.go(RouteNames.adminUsers),
            ),
            _buildActionCard(
              'Import Data',
              Icons.upload_file,
              Colors.amber,
              _showImportDataDialog,
            ),
            _buildActionCard(
              'Generate Credentials',
              Icons.key,
              Colors.purple,
              _showCredentialGeneratorDialog,
            ),
            _buildActionCard(
              'Attendance Reports',
              Icons.assessment,
              theme.colorScheme.secondary,
              () => context.go(RouteNames.adminReports),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacing16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 24,
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(height: AppDimensions.spacing8),
              Text(
                title,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);

    // Sample activity data
    final activities = [
      {
        'user': 'John Smith',
        'action': 'changed password',
        'time': '10 minutes ago',
      },
      {
        'user': 'Sarah Johnson',
        'action': 'created new account',
        'time': '1 hour ago',
      },
      {
        'user': 'Michael Brown',
        'action': 'updated profile',
        'time': '3 hours ago',
      },
      {
        'user': 'Emily Davis',
        'action': 'generated attendance report',
        'time': '5 hours ago',
      },
    ];

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity log
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),
            for (final activity in activities) ...[
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage('assets/account_circle.png'),
                ),
                title: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: activity['user']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ${activity['action']}'),
                    ],
                  ),
                ),
                subtitle: Text(activity['time']!),
                contentPadding: EdgeInsets.zero,
              ),
              if (activity != activities.last) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}
