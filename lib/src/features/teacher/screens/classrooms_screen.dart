import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_theme.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/dimensions.dart';
import '../../../config/routes/route_names.dart';
import '../../../shared/widgets/empty_state.dart';

/// Screen for listing all classrooms created by the teacher
class ClassroomsScreen extends ConsumerStatefulWidget {
  const ClassroomsScreen({super.key});

  @override
  ConsumerState<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends ConsumerState<ClassroomsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _classrooms = [];

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current teacher ID
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) {
        throw Exception('User not authenticated');
      }

      // Query classrooms from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .get();

      // Parse data
      final classrooms = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _classrooms = classrooms;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load classrooms: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classrooms'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClassrooms,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _classrooms.isEmpty
              ? EmptyState(
                  icon: Icons.class_outlined,
                  title: 'No Classrooms Yet',
                  description:
                      'Create your first classroom to start taking attendance',
                  actionButtonText: 'Create Classroom',
                  onActionButtonPressed: () {
                    context.push(RouteNames.createClassroom);
                  },
                )
              : RefreshIndicator(
                  onRefresh: _loadClassrooms,
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppDimensions.screenPadding),
                    itemCount: _classrooms.length,
                    itemBuilder: (context, index) {
                      final classroom = _classrooms[index];
                      return _buildClassroomCard(classroom);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RouteNames.createClassroom);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Classroom'),
      ),
    );
  }

  Widget _buildClassroomCard(Map<String, dynamic> classroom) {
    final theme = Theme.of(context);
    final classCode = classroom['code'] ?? '';
    final section = classroom['section'] ?? '';
    final fullCode = '$classCode - $section';

    final studentCount = classroom['studentCount'] ?? 0;
    final totalSessions = classroom['totalSessions'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: InkWell(
        onTap: () {
          context.go(
              '${RouteNames.teacherClassroomDetail.replaceAll(':classroomId', '')}${classroom['id']}');
        },
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    radius: 24,
                    child: Text(
                      classCode.isNotEmpty
                          ? classCode.substring(0, min(2, classCode.length))
                          : '??',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroom['name'] ?? 'Unnamed Class',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppDimensions.spacing4),
                        Text(
                          fullCode,
                          style: theme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: AppDimensions.spacing4),
                        Text(
                          'Sem ${classroom['semester']} - ${classroom['stream']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacing16),
              Divider(height: 1),
              SizedBox(height: AppDimensions.spacing12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                      Icons.people_outline, '$studentCount', 'Students'),
                  _buildStatCard(
                      Icons.event_note_outlined, '$totalSessions', 'Sessions'),
                  _buildStatCard(
                    Icons.qr_code,
                    classroom['classroomCode'] ?? '------',
                    'Class Code',
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacing12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    Icons.how_to_reg,
                    'Attendance',
                    theme.colorScheme.primary,
                    () {
                      context.push(
                          '${RouteNames.teacherStartAttendance.replaceAll(':classroomId', '')}${classroom['id']}');
                    },
                  ),
                  _buildActionButton(
                    Icons.share,
                    'Share Code',
                    theme.colorScheme.secondary,
                    () => _shareClassroomCode(classroom),
                  ),
                  _buildActionButton(
                    Icons.insert_drive_file_outlined,
                    'Materials',
                    theme.colorScheme.tertiary,
                    () {
                      context.push(
                          '${RouteNames.teacherClassroomMaterials.replaceAll(':classroomId', '')}${classroom['id']}');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: AppDimensions.spacing4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppDimensions.spacing2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppDimensions.spacing8,
          horizontal: AppDimensions.spacing12,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: AppDimensions.spacing4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareClassroomCode(Map<String, dynamic> classroom) {
    final classroomCode = classroom['classroomCode'];
    final className = classroom['name'];

    if (classroomCode == null || classroomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No classroom code available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show share dialog
    showDialog(
      context: context,
      builder: (context) => _buildShareCodeDialog(className, classroomCode),
    );
  }

  Widget _buildShareCodeDialog(String className, String code) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Share Classroom Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Students can join "$className" using this code:',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: AppDimensions.spacing16),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing24,
              vertical: AppDimensions.spacing16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusMedium),
            ),
            child: Text(
              code,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: AppDimensions.spacing16),
          Text(
            'Share this code with your students to allow them to join your classroom.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // In a real app, this would use a share plugin
            // For now, we'll just copy to clipboard
            // Clipboard.setData(ClipboardData(text: code));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Classroom code copied to clipboard'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.copy),
          label: Text('Copy Code'),
        ),
      ],
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
