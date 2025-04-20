import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/dimensions.dart';
import '../../../config/theme/color_schemes.dart';
import '../../../config/routes/route_names.dart';

/// Profile screen for viewing and editing user profile information
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;
  bool _isEditing = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();

  // Mock user data
  final Map<String, dynamic> _userData = {
    'name': 'John Doe',
    'email': 'john.doe@university.edu',
    'phone': '+1 (555) 123-4567',
    'department': 'Computer Science',
    'role': 'Student',
    'id': '12345678',
    'profileImage': null,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load user data from Firebase Auth and Firestore
      // For now, using mock data
      await Future.delayed(const Duration(milliseconds: 500));

      // Set form values
      _nameController.text = _userData['name'];
      _emailController.text = _userData['email'];
      _phoneController.text = _userData['phone'] ?? '';
      _departmentController.text = _userData['department'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile data: ${e.toString()}'),
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Save to Firebase Firestore
        await Future.delayed(const Duration(seconds: 1));

        // Update local data
        setState(() {
          _userData['name'] = _nameController.text;
          _userData['phone'] = _phoneController.text;
          _userData['department'] = _departmentController.text;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColorScheme.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
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
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;

      // If canceling edit, reset form values
      if (!_isEditing) {
        _nameController.text = _userData['name'];
        _emailController.text = _userData['email'];
        _phoneController.text = _userData['phone'] ?? '';
        _departmentController.text = _userData['department'] ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          _isEditing
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleEditMode,
                  tooltip: 'Cancel',
                )
              : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _toggleEditMode,
                  tooltip: 'Edit Profile',
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: AppDimensions.spacing32),
                  _isEditing ? _buildEditForm() : _buildProfileDetails(),
                  SizedBox(height: AppDimensions.spacing32),
                  if (_isEditing)
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes'),
                    ),
                  SizedBox(height: AppDimensions.spacing16),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to change password screen
                      context.push(RouteNames.changePassword);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Change Password'),
                  ),
                  SizedBox(height: AppDimensions.spacing16),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement logout functionality with Firebase Auth
                      context.go(RouteNames.login);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColorScheme.errorColor,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: _userData['profileImage'] != null
                  ? NetworkImage(_userData['profileImage'])
                  : const AssetImage('assets/account_circle.png')
                      as ImageProvider,
              child: _userData['profileImage'] == null
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            if (_isEditing)
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 20),
                    color: Colors.white,
                    onPressed: () {
                      // TODO: Implement image upload
                    },
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppDimensions.spacing16),
        Text(
          _userData['name'],
          style: theme.textTheme.headlineSmall,
        ),
        SizedBox(height: AppDimensions.spacing4),
        Text(
          _userData['role'],
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: AppDimensions.spacing4),
        Text(
          'ID: ${_userData['id']}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: AppDimensions.spacing16),
            _buildInfoItem(
              icon: Icons.person,
              title: 'Name',
              value: _userData['name'],
            ),
            const Divider(),
            _buildInfoItem(
              icon: Icons.email,
              title: 'Email',
              value: _userData['email'],
            ),
            const Divider(),
            _buildInfoItem(
              icon: Icons.phone,
              title: 'Phone',
              value: _userData['phone'] ?? 'Not provided',
            ),
            const Divider(),
            _buildInfoItem(
              icon: Icons.business,
              title: 'Department',
              value: _userData['department'] ?? 'Not provided',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppDimensions.spacing4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final theme = Theme.of(context);

    return Card(
      elevation: AppDimensions.cardElevation,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Information',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: AppDimensions.spacing16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDimensions.spacing16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                readOnly: true, // Email cannot be changed
                enabled: false,
              ),
              SizedBox(height: AppDimensions.spacing16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: AppDimensions.spacing16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business),
                ),
                readOnly: true, // Department assigned by admin
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
