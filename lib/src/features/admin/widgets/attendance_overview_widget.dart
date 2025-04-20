import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/dimensions.dart';
import '../../../config/theme/color_schemes.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceOverviewWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;

  const AttendanceOverviewWidget({
    super.key,
    this.data,
  });

  @override
  ConsumerState<AttendanceOverviewWidget> createState() =>
      _AttendanceOverviewWidgetState();
}

class _AttendanceOverviewWidgetState
    extends ConsumerState<AttendanceOverviewWidget> {
  String _selectedTimeFrame = 'Weekly';
  final List<String> _timeFrames = ['Daily', 'Weekly', 'Monthly', 'Semester'];

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
                  'Attendance Overview',
                  style: theme.textTheme.titleLarge,
                ),
                DropdownButton<String>(
                  value: _selectedTimeFrame,
                  underline: const SizedBox.shrink(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTimeFrame = newValue;
                      });
                    }
                  },
                  items:
                      _timeFrames.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing16),
            SizedBox(
              height: 200,
              child: _buildLineChart(),
            ),
            SizedBox(height: AppDimensions.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Average', '86%', Colors.blue),
                _buildStatItem('Highest', '98%', Colors.green),
                _buildStatItem('Lowest', '72%', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    // Sample data points for the attendance line chart
    final List<FlSpot> spots = [
      const FlSpot(0, 87),
      const FlSpot(1, 85),
      const FlSpot(2, 90),
      const FlSpot(3, 82),
      const FlSpot(4, 86),
      const FlSpot(5, 93),
      const FlSpot(6, 84),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: _bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: _leftTitleWidgets,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            left: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    Widget text;

    // Get day names based on the selected time frame
    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    if (_selectedTimeFrame == 'Daily') {
      // Show hours
      text = Text('${value.toInt() * 4}h');
    } else if (_selectedTimeFrame == 'Weekly') {
      // Show days of week
      text = Text(daysOfWeek[value.toInt()]);
    } else {
      // Show months or weeks
      final index = value.toInt() % months.length;
      text = Text(months[index]);
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == 0) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${value.toInt()}%',
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
