import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/dimensions.dart';

class CredentialGeneratorDialog extends ConsumerStatefulWidget {
  const CredentialGeneratorDialog({super.key});

  @override
  ConsumerState<CredentialGeneratorDialog> createState() =>
      _CredentialGeneratorDialogState();
}

class _CredentialGeneratorDialogState
    extends ConsumerState<CredentialGeneratorDialog> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String _userType = 'students';
  String _department = 'All Departments';
  String _passwordType = 'standard';
  final TextEditingController _prefixController = TextEditingController();
  bool _includeNumbers = true;
  bool _includeSpecial = false;
  bool _showGeneratedCredentials = false;
  final List<Map<String, String>> _generatedCredentials = [];

  final List<String> _departments = [
    'All Departments',
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Business Administration',
  ];

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _generateCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _showGeneratedCredentials = false;
      _generatedCredentials.clear();
    });

    try {
      // TODO: Implement actual credential generation with Firebase
      await Future.delayed(const Duration(seconds: 2)); // Simulate loading

      // Generate sample credentials for demonstration
      final prefix = _prefixController.text.isEmpty
          ? (_userType == 'students' ? 'student' : 'teacher')
          : _prefixController.text;

      for (int i = 1; i <= 10; i++) {
        final username = '$prefix${100 + i}';
        final password = _generatePassword();
        _generatedCredentials.add({
          'username': username,
          'password': password,
          'email': '$username@attendwise.com',
        });
      }

      setState(() {
        _showGeneratedCredentials = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating credentials: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generatePassword() {
    // Generate random password based on settings
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_-+=<>?';

    switch (_passwordType) {
      case 'standard':
        return 'Password123';
      case 'secure':
        return 'Se@cure${100 + _generatedCredentials.length}';
      case 'random':
        final chars = letters +
            (_includeNumbers ? numbers : '') +
            (_includeSpecial ? special : '');
        final length = 10;
        return List.generate(
                length,
                (index) =>
                    chars[DateTime.now().microsecondsSinceEpoch % chars.length])
            .join();
      default:
        return 'Password123';
    }
  }

  Future<void> _exportCredentials() async {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credentials exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveToDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement saving to database with Firebase
      await Future.delayed(const Duration(seconds: 2)); // Simulate loading

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully created ${_generatedCredentials.length} user accounts'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving credentials: ${e.toString()}'),
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
                'Generate User Credentials',
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: AppDimensions.spacing16),
              Text(
                'Create default credentials for new users in the system',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: AppDimensions.spacing24),

              if (!_showGeneratedCredentials) ...[
                // Configuration options
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Type:',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: AppDimensions.spacing8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'students',
                                label: Text('Students'),
                                icon: Icon(Icons.school),
                              ),
                              ButtonSegment(
                                value: 'teachers',
                                label: Text('Teachers'),
                                icon: Icon(Icons.person),
                              ),
                            ],
                            selected: {_userType},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _userType = newSelection.first;
                              });
                            },
                          ),
                          SizedBox(height: AppDimensions.spacing16),
                          Text(
                            'Department:',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: AppDimensions.spacing8),
                          DropdownButtonFormField<String>(
                            value: _department,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: _departments
                                .map((dept) => DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept),
                                    ))
                                .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _department = newValue;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppDimensions.spacing24),
                    // Right column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Username Prefix (optional):',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: AppDimensions.spacing8),
                          TextFormField(
                            controller: _prefixController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'e.g., cs_student, math_teacher',
                            ),
                          ),
                          SizedBox(height: AppDimensions.spacing16),
                          Text(
                            'Password Type:',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: AppDimensions.spacing8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'standard',
                                label: Text('Standard'),
                              ),
                              ButtonSegment(
                                value: 'secure',
                                label: Text('Secure'),
                              ),
                              ButtonSegment(
                                value: 'random',
                                label: Text('Random'),
                              ),
                            ],
                            selected: {_passwordType},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _passwordType = newSelection.first;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.spacing16),
                // Password options
                if (_passwordType == 'random') ...[
                  Text(
                    'Password Options:',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: AppDimensions.spacing8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Include Numbers'),
                          value: _includeNumbers,
                          onChanged: (bool? value) {
                            if (value != null) {
                              setState(() {
                                _includeNumbers = value;
                              });
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Include Special Characters'),
                          value: _includeSpecial,
                          onChanged: (bool? value) {
                            if (value != null) {
                              setState(() {
                                _includeSpecial = value;
                              });
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Generated credentials table
                Text(
                  'Generated Credentials',
                  style: theme.textTheme.titleMedium,
                ),
                SizedBox(height: AppDimensions.spacing8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2)),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadius),
                  ),
                  height: 300,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label: Text('Username'),
                        ),
                        DataColumn(
                          label: Text('Password'),
                        ),
                        DataColumn(
                          label: Text('Email'),
                        ),
                        DataColumn(
                          label: Text('Actions'),
                        ),
                      ],
                      rows: _generatedCredentials
                          .map(
                            (cred) => DataRow(
                              cells: [
                                DataCell(Text(cred['username']!)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(cred['password']!),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 16),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: cred['password']!));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Password copied to clipboard'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        tooltip: 'Copy password',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(cred['email']!)),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 16),
                                    onPressed: () {
                                      // Regenerate single password
                                      setState(() {
                                        cred['password'] = _generatePassword();
                                      });
                                    },
                                    tooltip: 'Regenerate password',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(height: AppDimensions.spacing16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_generatedCredentials.length} credentials generated',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton.icon(
                      onPressed: _exportCredentials,
                      icon: const Icon(Icons.download),
                      label: const Text('Export to CSV'),
                    ),
                  ],
                ),
              ],

              SizedBox(height: AppDimensions.spacing24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_showGeneratedCredentials) {
                              setState(() {
                                _showGeneratedCredentials = false;
                              });
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                    child: Text(_showGeneratedCredentials ? 'Back' : 'Cancel'),
                  ),
                  SizedBox(width: AppDimensions.spacing16),
                  FilledButton(
                    onPressed: _isLoading
                        ? null
                        : _showGeneratedCredentials
                            ? _saveToDatabase
                            : _generateCredentials,
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
                              Text(_showGeneratedCredentials
                                  ? 'Saving...'
                                  : 'Generating...'),
                            ],
                          )
                        : Text(_showGeneratedCredentials
                            ? 'Save to Database'
                            : 'Generate Credentials'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
