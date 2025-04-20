import 'package:attendwise/src/features/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../backend/repositories/classroom_repository.dart';
import '../../../config/theme/app_theme.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/dimensions.dart';
import '../../../shared/widgets/loading_button.dart';

/// Screen for creating a new virtual classroom
class CreateClassroomScreen extends ConsumerStatefulWidget {
  const CreateClassroomScreen({super.key});

  @override
  ConsumerState<CreateClassroomScreen> createState() =>
      _CreateClassroomScreenState();
}

class _CreateClassroomScreenState extends ConsumerState<CreateClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _classroomRepository = ClassroomRepository();

  // Form field controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _roomController = TextEditingController();
  final _timeController = TextEditingController();

  String _selectedLevel = 'Undergraduate';
  String _selectedYear = '1st Year';
  String _selectedSemester = 'Fall 2025';

  // Level options
  final List<String> _levels = [
    'Undergraduate',
    'Graduate',
    'Postgraduate',
    'Diploma',
    'Certificate'
  ];

  // Year options
  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year'
  ];

  // Semester options
  final List<String> _semesters = [
    'Fall 2025',
    'Spring 2025',
    'Summer 2025',
    'Winter 2025'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _roomController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _createClassroom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current teacher ID from Firebase Auth
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) {
        throw Exception('User not authenticated');
      }

      // Create classroom using the repository
      final classroomId = await _classroomRepository.createClassroom(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        teacherId: teacherId,
        room: _roomController.text.trim(),
        level: _selectedLevel,
        year: _selectedYear,
        semester: _selectedSemester,
        time: _timeController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to teacher dashboard
        context.go(RouteNames.teacherDashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create classroom: ${e.toString()}'),
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
        title: const Text('Create New Classroom'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Classroom information header
              Text(
                'Classroom Information',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: AppDimensions.spacing24),

              // Class name field
              CustomTextField(
                controller: _nameController,
                labelText: 'Class Name',
                hintText: 'e.g. Introduction to Computer Science',
                prefixIcon: Icons.subject,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a class name';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDimensions.spacing16),

              // Class code field
              CustomTextField(
                controller: _codeController,
                labelText: 'Class Code',
                hintText: 'e.g. CS101 (Leave empty to auto-generate)',
                prefixIcon: Icons.code,
                validator: null, // Optional, will be auto-generated if empty
              ),
              SizedBox(height: AppDimensions.spacing16),

              // Room field
              CustomTextField(
                controller: _roomController,
                labelText: 'Room',
                hintText: 'e.g. Room 301',
                prefixIcon: Icons.room,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDimensions.spacing16),

              // Class time field
              CustomTextField(
                controller: _timeController,
                labelText: 'Class Time',
                hintText: 'e.g. Mon, Wed, Fri 10:00 AM',
                prefixIcon: Icons.access_time,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter class time';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDimensions.spacing16),

              // Level dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Level',
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusMedium),
                  ),
                ),
                value: _selectedLevel,
                items: _levels.map((String level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLevel = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a level';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDimensions.spacing16),

              // Year dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Year',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusMedium),
                  ),
                ),
                value: _selectedYear,
                items: _years.map((String year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedYear = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a year';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDimensions.spacing16),

              // Semester dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Semester',
                  prefixIcon: const Icon(Icons.date_range),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusMedium),
                  ),
                ),
                value: _selectedSemester,
                items: _semesters.map((String semester) {
                  return DropdownMenuItem<String>(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSemester = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a semester';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDimensions.spacing32),

              // Create classroom button
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _createClassroom,
                text: 'Create Classroom',
                loadingText: 'Creating...',
                icon: Icons.add_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
