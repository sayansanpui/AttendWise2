import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/config/routes/app_router.dart';
import 'src/config/theme/app_theme.dart';

/// Main app widget that configures themes and routing
class App extends ConsumerWidget {
  /// Creates a new App instance
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the router from the provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AttendWise',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Uses the system theme by default

      // Router configuration
      routerConfig: router,
    );
  }
}
