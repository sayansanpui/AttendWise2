import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/dimensions.dart';

class SystemConfigDialog extends ConsumerStatefulWidget {
  const SystemConfigDialog({super.key});

  @override
  ConsumerState<SystemConfigDialog> createState() => _SystemConfigDialogState();
}

class _SystemConfigDialogState extends ConsumerState<SystemConfigDialog> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // System settings
  bool _allowStudentCorrections = true;
  bool _enableNotifications = true;
  String _attendanceThreshold = '75';
  String _defaultAttendanceView = 'daily';
  bool _automaticReportGeneration = false;
  String _reportFrequency = 'weekly';
  TimeOfDay _sessionAutoCloseTime = const TimeOfDay(hour: 23, minute: 59);
  String _attendanceEditTimeLimit = '24';

  final List<String> _viewOptions = ['daily', 'weekly', 'monthly'];
  final List<String> _reportOptions = ['daily', 'weekly', 'monthly'];

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement saving to Firebase
      await Future.delayed(const Duration(seconds: 2)); // Simulate loading

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('System settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ${e.toString()}'),
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

  Future<void> _selectSessionCloseTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _sessionAutoCloseTime,
    );

    if (picked != null && picked != _sessionAutoCloseTime) {
      setState(() {
        _sessionAutoCloseTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 600,
        padding: EdgeInsets.all(AppDimensions.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Configuration',
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: AppDimensions.spacing16),
              Text(
                'Configure system-wide settings for the attendance management system',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: AppDimensions.spacing24),

              // Content in a scrollable container
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attendance Settings
                      _buildSectionHeader('Attendance Settings', theme),
                      SizedBox(height: AppDimensions.spacing8),

                      // Attendance Threshold
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Attendance Threshold:',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: _attendanceThreshold,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                suffixText: '%',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a value';
                                }
                                final threshold = int.tryParse(value);
                                if (threshold == null ||
                                    threshold < 0 ||
                                    threshold > 100) {
                                  return 'Enter a valid percentage (0-100)';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  _attendanceThreshold = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppDimensions.spacing16),

                      // Default Attendance View
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Default Attendance View:',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _defaultAttendanceView,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: _viewOptions
                                  .map((view) => DropdownMenuItem(
                                        value: view,
                                        child: Text(
                                            view.substring(0, 1).toUpperCase() +
                                                view.substring(1)),
                                      ))
                                  .toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _defaultAttendanceView = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppDimensions.spacing16),

                      // Attendance Edit Time Limit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Attendance Edit Time Limit:',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: _attendanceEditTimeLimit,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                suffixText: 'hours',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a value';
                                }
                                final hours = int.tryParse(value);
                                if (hours == null || hours < 0 || hours > 72) {
                                  return 'Enter a valid hour (0-72)';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  _attendanceEditTimeLimit = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppDimensions.spacing16),

                      // Allow Student Corrections
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Allow Student Corrections:',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Switch(
                              value: _allowStudentCorrections,
                              onChanged: (bool value) {
                                setState(() {
                                  _allowStudentCorrections = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppDimensions.spacing16),

                      // Session Auto-Close Time
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Session Auto-Close Time:',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: InkWell(
                              onTap: _selectSessionCloseTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: theme.colorScheme.outline),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_sessionAutoCloseTime.hour.toString().padLeft(2, '0')}:${_sessionAutoCloseTime.minute.toString().padLeft(2, '0')}',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    const Icon(Icons.access_time),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppDimensions.spacing24),

                      // Notification Settings
                      _buildSectionHeader('Notification Settings', theme),
                      SizedBox(height: AppDimensions.spacing8),

                      // Enable Notifications
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Enable Notifications:',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Switch(
                              value: _enableNotifications,
                              onChanged: (bool value) {
                                setState(() {
                                  _enableNotifications = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppDimensions.spacing24),

                      // Report Settings
                      _buildSectionHeader('Report Settings', theme),
                      SizedBox(height: AppDimensions.spacing8),

                      // Automatic Report Generation
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Automatic Report Generation:',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Switch(
                              value: _automaticReportGeneration,
                              onChanged: (bool value) {
                                setState(() {
                                  _automaticReportGeneration = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppDimensions.spacing16),

                      // Report Frequency
                      if (_automaticReportGeneration) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Report Frequency:',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _reportFrequency,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: _reportOptions
                                    .map((option) => DropdownMenuItem(
                                          value: option,
                                          child: Text(option
                                                  .substring(0, 1)
                                                  .toUpperCase() +
                                              option.substring(1)),
                                        ))
                                    .toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _reportFrequency = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppDimensions.spacing24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: AppDimensions.spacing16),
                  FilledButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                              SizedBox(width: AppDimensions.spacing8),
                              const Text('Saving...'),
                            ],
                          )
                        : const Text('Save Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
      ],
    );
  }
}
