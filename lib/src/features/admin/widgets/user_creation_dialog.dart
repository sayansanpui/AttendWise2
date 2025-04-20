import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../backend/services/firebase_service.dart';
import '../../../backend/models/user_model.dart';
import '../../../config/theme/dimensions.dart';

class UserCreationDialog extends ConsumerStatefulWidget {
  final UserRole userRole;

  const UserCreationDialog({
    super.key,
    required this.userRole,
  });

  @override
  ConsumerState<UserCreationDialog> createState() => _UserCreationDialogState();
}

class _UserCreationDialogState extends ConsumerState<UserCreationDialog> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final _departments = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Business Administration',
  ];

  String _selectedDepartment = 'Computer Science';
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _departmentController.dispose();
    _universityIdController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate all required fields first
      if (_displayNameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _universityIdController.text.isEmpty) {
        throw Exception('Please fill in all required fields');
      }

      // 1. Create user with Firebase Authentication
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Create user document in Firestore
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: _emailController.text.trim(),
        displayName: _displayNameController.text.trim(),
        role: widget.userRole,
        department: _selectedDepartment,
        universityId: _universityIdController.text.trim(),
        createdAt: Timestamp.now(),
        lastLogin: Timestamp.now(),
        isActive: true,
        passwordChanged: false,
        phoneNumber: _phoneNumberController.text.trim().isNotEmpty
            ? _phoneNumberController.text.trim()
            : null,
      );

      // Log user data for debugging
      print('Creating user with data: ${newUser.toJson()}');

      // Save to Firestore
      await _firebaseService.usersCollection
          .doc(userCredential.user!.uid)
          .set(newUser.toJson());

      // 3. Update profile display name
      await userCredential.user!
          .updateDisplayName(_displayNameController.text.trim());

      // Show success message and close dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.userRole == UserRole.teacher ? "Teacher" : "Student"} created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already in use';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Try again later';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your internet connection';
          break;
        default:
          errorMessage = e.message ?? 'An unknown error occurred';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseException catch (e) {
      // Specific handling for Firestore errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore Error: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Log detailed error information to help with debugging
      print('Detailed error in user creation: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: ${e.toString()}'),
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
    final roleText =
        widget.userRole == UserRole.teacher ? 'Teacher' : 'Student';

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
                'Create New $roleText',
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: AppDimensions.spacing16),
              Text(
                'Enter the details to create a new ${roleText.toLowerCase()} account',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: AppDimensions.spacing24),

              // Two column layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Basic Information',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: AppDimensions.spacing16),

                        // Display Name
                        TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: AppDimensions.spacing16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: AppDimensions.spacing16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            helperText: 'Minimum 6 characters',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
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
                          'Additional Details',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: AppDimensions.spacing16),

                        // Department
                        DropdownButtonFormField<String>(
                          value: _selectedDepartment,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
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
                                _selectedDepartment = newValue;
                              });
                            }
                          },
                        ),

                        SizedBox(height: AppDimensions.spacing16),

                        // University ID
                        TextFormField(
                          controller: _universityIdController,
                          decoration: InputDecoration(
                            labelText: widget.userRole == UserRole.teacher
                                ? 'Employee ID'
                                : 'Student ID',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.badge),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter ${widget.userRole == UserRole.teacher ? 'Employee' : 'Student'} ID';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: AppDimensions.spacing16),

                        // Phone Number
                        TextFormField(
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    onPressed: _isLoading ? null : _createUser,
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
                              Text('Creating $roleText...'),
                            ],
                          )
                        : Text('Create $roleText'),
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
