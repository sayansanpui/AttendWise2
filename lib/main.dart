import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';

// Function to verify Firebase connection
Future<bool> verifyFirebaseConnection() async {
  try {
    // Try to access Firestore with a simple query
    final testQuery = await FirebaseFirestore.instance
        .collection('_connection_test')
        .limit(1)
        .get();

    // If we get here, the connection was successful
    return true;
  } catch (e) {
    debugPrint('Firebase connection verification failed: $e');
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase with better error handling for duplicate initialization
  bool isConnected = false;
  try {
    FirebaseApp app;
    try {
      app = Firebase.app();
      debugPrint('Existing Firebase app found, using it');
    } catch (e) {
      debugPrint('Initializing new Firebase app');
      app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    isConnected = await verifyFirebaseConnection();
    debugPrint(
        'Firebase connection status: ${isConnected ? 'SUCCESS' : 'FAILED'}');
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
