import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/dimensions.dart';
import '../../../config/theme/color_schemes.dart';
import 'package:fl_chart/fl_chart.dart';

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
                    _buildStatisticsCards(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildAttendanceChart(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildQuickActions(),
                    SizedBox(height: AppDimensions.spacing24),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
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
            leading: const Icon(Icons.business),
            title: const Text('Departments'),
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.adminDepartments);
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

  Widget _buildAttendanceChart() {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department Attendance Overview',
              style: theme.textTheme.titleLarge,
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

  Widget _buildQuickActions() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
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
              'Add User',
              Icons.person_add,
              theme.colorScheme.primary,
              () => context.go(RouteNames.adminUsers),
            ),
            _buildActionCard(
              'Generate Report',
              Icons.assessment,
              theme.colorScheme.secondary,
              () => context.go(RouteNames.adminReports),
            ),
            _buildActionCard(
              'Import Users',
              Icons.upload_file,
              AppColorScheme.infoColor,
              () => context.go(RouteNames.adminUsers),
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
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge,
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
            SizedBox(height: AppDimensions.spacing8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navigate to activity log or similar
                },
                child: const Text('View All Activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
