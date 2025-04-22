// Web-specific utility functions
// This file is used when the app is running on web platforms

import 'dart:html' as html;
import 'dart:typed_data';

// Function to download a file in the browser
Future<void> saveAndOpenFile(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

// Helper methods for more fine-grained control over web operations
html.Blob createBlob(List<Uint8List> bytes) {
  return html.Blob(bytes);
}

String createObjectUrlFromBlob(html.Blob blob) {
  return html.Url.createObjectUrlFromBlob(blob);
}

void revokeObjectUrl(String url) {
  html.Url.revokeObjectUrl(url);
}

html.AnchorElement createAnchorElement({String? href}) {
  return html.AnchorElement(href: href);
}
