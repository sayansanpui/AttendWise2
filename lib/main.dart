import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase with protection against duplicate initialization
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // Get the already initialized app
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(
    // Add Riverpod provider to the entire app
    const ProviderScope(
      child: App(),
    ),
  );
}
