import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/dimensions.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceAnalyticsWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;

  const AttendanceAnalyticsWidget({
    super.key,
    this.data,
  });

  @override
  ConsumerState<AttendanceAnalyticsWidget> createState() =>
      _AttendanceAnalyticsWidgetState();
}

class _AttendanceAnalyticsWidgetState
    extends ConsumerState<AttendanceAnalyticsWidget> {
  int _touchedIndex = -1;
  String _selectedView = 'Departments';
  final List<String> _viewOptions = ['Departments', 'Classes', 'Days of Week'];

  @override
  Widget build(BuildContext context) {
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
                  'Attendance Analytics',
                  style: theme.textTheme.titleLarge,
                ),
                DropdownButton<String>(
                  value: _selectedView,
                  underline: const SizedBox.shrink(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedView = newValue;
                      });
                    }
                  },
                  items: _viewOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),
            Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: _buildPieChart(),
                  ),
                ),

                // Legend
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.only(left: AppDimensions.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildLegendItems(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),

            // Additional insights
            Container(
              padding: EdgeInsets.all(AppDimensions.spacing12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: AppDimensions.spacing8),
                  Expanded(
                    child: Text(
                      _getInsightText(),
                      style: theme.textTheme.bodyMedium,
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

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _generatePieChartSections(),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    // Sample data based on the selected view
    final List<Map<String, dynamic>> data = [];

    if (_selectedView == 'Departments') {
      data.addAll([
        {'name': 'Computer Science', 'percentage': 88.2, 'color': Colors.blue},
        {'name': 'Electrical Eng.', 'percentage': 82.5, 'color': Colors.green},
        {'name': 'Mechanical Eng.', 'percentage': 76.8, 'color': Colors.red},
        {'name': 'Civil Eng.', 'percentage': 85.1, 'color': Colors.purple},
        {'name': 'Business Admin.', 'percentage': 72.3, 'color': Colors.orange},
      ]);
    } else if (_selectedView == 'Classes') {
      data.addAll([
        {'name': 'Morning', 'percentage': 90.7, 'color': Colors.blue},
        {'name': 'Afternoon', 'percentage': 82.4, 'color': Colors.green},
        {'name': 'Evening', 'percentage': 76.1, 'color': Colors.red},
      ]);
    } else {
      // Days of Week
      data.addAll([
        {'name': 'Monday', 'percentage': 84.3, 'color': Colors.blue},
        {'name': 'Tuesday', 'percentage': 86.2, 'color': Colors.green},
        {'name': 'Wednesday', 'percentage': 88.5, 'color': Colors.red},
        {'name': 'Thursday', 'percentage': 85.7, 'color': Colors.purple},
        {'name': 'Friday', 'percentage': 78.1, 'color': Colors.orange},
      ]);
    }

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedIndex;
      final double fontSize = isTouched ? 18 : 14;
      final double radius = isTouched ? 70 : 60;

      return PieChartSectionData(
        color: item['color'] as Color,
        value: item['percentage'] as double,
        title: '${(item['percentage'] as double).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegendItems() {
    // Sample data based on the selected view
    final List<Map<String, dynamic>> data = [];

    if (_selectedView == 'Departments') {
      data.addAll([
        {'name': 'Computer Science', 'percentage': 88.2, 'color': Colors.blue},
        {
          'name': 'Electrical Engineering',
          'percentage': 82.5,
          'color': Colors.green
        },
        {
          'name': 'Mechanical Engineering',
          'percentage': 76.8,
          'color': Colors.red
        },
        {
          'name': 'Civil Engineering',
          'percentage': 85.1,
          'color': Colors.purple
        },
        {
          'name': 'Business Administration',
          'percentage': 72.3,
          'color': Colors.orange
        },
      ]);
    } else if (_selectedView == 'Classes') {
      data.addAll([
        {'name': 'Morning Classes', 'percentage': 90.7, 'color': Colors.blue},
        {
          'name': 'Afternoon Classes',
          'percentage': 82.4,
          'color': Colors.green
        },
        {'name': 'Evening Classes', 'percentage': 76.1, 'color': Colors.red},
      ]);
    } else {
      // Days of Week
      data.addAll([
        {'name': 'Monday', 'percentage': 84.3, 'color': Colors.blue},
        {'name': 'Tuesday', 'percentage': 86.2, 'color': Colors.green},
        {'name': 'Wednesday', 'percentage': 88.5, 'color': Colors.red},
        {'name': 'Thursday', 'percentage': 85.7, 'color': Colors.purple},
        {'name': 'Friday', 'percentage': 78.1, 'color': Colors.orange},
      ]);
    }

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedIndex;

      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spacing4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: item['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppDimensions.spacing8),
            Expanded(
              child: Text(
                item['name'] as String,
                style: TextStyle(
                  fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                  color: isTouched ? (item['color'] as Color) : null,
                ),
              ),
            ),
            Text(
              '${(item['percentage'] as double).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTouched ? (item['color'] as Color) : null,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getInsightText() {
    if (_selectedView == 'Departments') {
      return 'Computer Science department has the highest attendance rate at 88.2%, while Business Administration has the lowest at 72.3%.';
    } else if (_selectedView == 'Classes') {
      return 'Morning classes have significantly higher attendance (90.7%) compared to evening classes (76.1%). Consider scheduling important sessions in the morning.';
    } else {
      // Days of Week
      return 'Wednesday has the highest attendance rate (88.5%), while Friday has the lowest (78.1%). Consider scheduling important classes mid-week for better attendance.';
    }
  }
}
