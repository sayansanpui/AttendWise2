import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for common Firebase operations
class FirebaseUtils {
  /// Create an index field for case-insensitive searching
  static List<String> generateSearchKeywords(String text) {
    // Ignore common words, punctuation, and make lowercase
    final String cleanText = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\b(and|the|or|in|on|at|for|to|with|by|of)\b'), '');

    // Split into words
    final List<String> words =
        cleanText.split(' ').where((word) => word.trim().isNotEmpty).toList();

    // Generate all substrings for each word for partial matching
    final List<String> keywords = [];
    for (String word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }

    return keywords;
  }

  /// Extract collection path from a document reference
  static String getCollectionPath(DocumentReference docRef) {
    final String fullPath = docRef.path;
    final int lastSlashIndex = fullPath.lastIndexOf('/');
    return fullPath.substring(0, lastSlashIndex);
  }

  /// Convert a Firestore snapshot to a list of Maps
  static List<Map<String, dynamic>> snapshotToMapList(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  /// Convert a Firestore document snapshot to a Map
  static Map<String, dynamic>? docToMap(DocumentSnapshot doc) {
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  /// Safely get a value from a Firestore document with optional default value
  static T getValue<T>(DocumentSnapshot doc, String field, T defaultValue) {
    if (!doc.exists) return defaultValue;

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey(field)) {
      return defaultValue;
    }

    final value = data[field];
    if (value is T) {
      return value;
    }

    return defaultValue;
  }

  /// Chunk a list into smaller lists of the specified size
  static List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];

    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }

    return chunks;
  }

  /// Execute a Firestore query with pagination
  static Future<QuerySnapshot> paginatedQuery(
    Query query, {
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query paginatedQuery = query.limit(limit);

    if (startAfter != null) {
      paginatedQuery = paginatedQuery.startAfterDocument(startAfter);
    }

    return await paginatedQuery.get();
  }

  /// Merge update data while preserving existing fields
  static Future<void> mergeUpdate(
    DocumentReference docRef,
    Map<String, dynamic> data,
  ) async {
    // Get the current document
    final doc = await docRef.get();

    if (!doc.exists) {
      // Document doesn't exist, just set the data
      await docRef.set(data);
      return;
    }

    // Document exists, merge with existing data
    final currentData = doc.data() as Map<String, dynamic>;
    final mergedData = {...currentData, ...data};

    await docRef.set(mergedData);
  }

  /// Run a transaction that creates a unique ID and uses it in the document
  static Future<String> createWithId(
    FirebaseFirestore firestore,
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    final String docId = firestore.collection(collectionPath).doc().id;

    await firestore.runTransaction((transaction) async {
      // Add the ID to the document data
      final docData = {...data, 'id': docId};

      // Create the document with the generated ID
      transaction.set(
        firestore.collection(collectionPath).doc(docId),
        docData,
      );
    });

    return docId;
  }

  /// Safely delete a document with optional batch
  static Future<void> safeDelete(
    DocumentReference docRef, {
    WriteBatch? batch,
  }) async {
    try {
      if (batch != null) {
        batch.delete(docRef);
      } else {
        await docRef.delete();
      }
    } catch (e) {
      // Ignore "not found" errors
      if (e is FirebaseException && e.code == 'not-found') {
        return;
      }
      rethrow;
    }
  }

  /// Check if a document exists
  static Future<bool> documentExists(DocumentReference docRef) async {
    try {
      final doc = await docRef.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
