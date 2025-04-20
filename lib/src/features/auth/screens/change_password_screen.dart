import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants/error_messages.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/dimensions.dart';
import '../../../shared/widgets/buttons/primary_button.dart';

/// Change password screen for first-time login or password reset
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement password change with Firebase Auth
      // This is a placeholder for the actual implementation
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful password change
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to change password. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Password Changed'),
        content: const Text(
          'Your password has been changed successfully. You will now be redirected to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(RouteNames.login);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.screenPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: _buildChangePasswordForm(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Change Your Password',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacing16),
          Text(
            'Please enter your current password and set a new password.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.spacing32),
          if (_errorMessage != null) ...[
            Container(
              padding: EdgeInsets.all(AppDimensions.spacing16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppDimensions.cardBorderRadius),
              ),
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: AppDimensions.spacing16),
          ],
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            decoration: InputDecoration(
              labelText: 'Current Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return ErrorMessages.requiredField;
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          SizedBox(height: AppDimensions.spacing24),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return ErrorMessages.requiredField;
              }
              if (value.length < 8) {
                return ErrorMessages.invalidPassword;
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          SizedBox(height: AppDimensions.spacing16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return ErrorMessages.requiredField;
              }
              if (value != _newPasswordController.text) {
                return ErrorMessages.passwordMismatch;
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          SizedBox(height: AppDimensions.spacing32),
          PrimaryButton(
            text: 'Change Password',
            onPressed: _changePassword,
            isLoading: _isLoading,
            icon: Icons.lock_reset,
          ),
          SizedBox(height: AppDimensions.spacing16),
          TextButton(
            onPressed: _isLoading ? null : () => context.go(RouteNames.login),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
