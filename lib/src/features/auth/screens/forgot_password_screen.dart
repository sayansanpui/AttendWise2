import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants/asset_paths.dart';
import '../../../config/constants/error_messages.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/dimensions.dart';
import '../../../shared/widgets/buttons/primary_button.dart';

/// Forgot password screen for password reset
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetEmailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement password reset with Firebase Auth
      // This is a placeholder for the actual implementation
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _resetEmailSent = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to send password reset email. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.screenPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: _resetEmailSent
                ? _buildSuccessMessage(theme)
                : _buildResetForm(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          AssetPaths.logo,
          height: 80,
          width: 80,
        ),
        SizedBox(height: AppDimensions.spacing24),
        Text(
          'Forgot Your Password?',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacing16),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
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
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ErrorMessages.requiredField;
                  }
                  if (!value.contains('@')) {
                    return ErrorMessages.invalidEmail;
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              SizedBox(height: AppDimensions.spacing24),
              PrimaryButton(
                text: 'Send Reset Link',
                onPressed: _sendResetEmail,
                isLoading: _isLoading,
                icon: Icons.send,
              ),
              SizedBox(height: AppDimensions.spacing16),
              TextButton(
                onPressed: _isLoading ? null : _navigateToLogin,
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: AppDimensions.spacing24),
        Text(
          'Email Sent!',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacing16),
        Text(
          'We\'ve sent a password reset link to:\n${_emailController.text}',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacing16),
        Text(
          'Please check your inbox and follow the instructions to reset your password.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacing32),
        PrimaryButton(
          text: 'Return to Login',
          onPressed: _navigateToLogin,
          icon: Icons.login,
        ),
      ],
    );
  }
}
