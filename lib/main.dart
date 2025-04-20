import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _testResult = "No test run yet";
  bool _isLoading = false;

  Future<void> _testFirestore() async {
    setState(() {
      _isLoading = true;
      _testResult = "Testing Firestore connection...";
    });

    try {
      // Test collection and document ID
      final CollectionReference testCollection =
          FirebaseFirestore.instance.collection('firestore_test');
      final String docId = DateTime.now().millisecondsSinceEpoch.toString();

      // Data to write
      final data = {
        'timestamp': FieldValue.serverTimestamp(),
        'testValue': 'Test at ${DateTime.now().toString()}',
      };

      // Write to Firestore
      await testCollection.doc(docId).set(data);

      // Read from Firestore to verify
      final docSnapshot = await testCollection.doc(docId).get();

      setState(() {
        if (docSnapshot.exists) {
          _testResult = "✅ Firestore write and read successful!\n"
              "Document ID: $docId\n"
              "Data: ${docSnapshot.data()}";
        } else {
          _testResult = "⚠️ Document was written but could not be read back.";
        }
      });
    } catch (e) {
      setState(() {
        _testResult = "❌ Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to my app!',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _testFirestore,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Test Firestore Connection'),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResult,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
