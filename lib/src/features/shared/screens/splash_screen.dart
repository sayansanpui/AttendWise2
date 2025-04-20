import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants/asset_paths.dart';
import '../../../config/constants/app_constants.dart';

/// Splash screen displayed when the app is launched
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.mediumAnimationDuration,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Image.asset(
                AssetPaths.logo,
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: AssetPaths.audiowideFont,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Text(
                'Digital Attendance Management System',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 48),
            FadeTransition(
              opacity: _fadeInAnimation,
              child: const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
