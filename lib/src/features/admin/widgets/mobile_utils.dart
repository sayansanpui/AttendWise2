// Mobile-specific utility functions
// This file is used when the app is running on Android, iOS, or other non-web platforms

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// Function to save a file locally and open it
Future<void> saveAndOpenFile(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);

  await file.writeAsBytes(bytes);
  await OpenFile.open(filePath);
}

// These methods exist for API compatibility with web version
// but aren't actually needed on mobile platforms
dynamic createBlob(List<Uint8List> bytes) {
  return null; // Not needed on mobile
}

String createObjectUrlFromBlob(dynamic blob) {
  return ''; // Not needed on mobile
}

void revokeObjectUrl(String url) {
  // Not needed on mobile
}

dynamic createAnchorElement({String? href}) {
  return null; // Not needed on mobile
}
