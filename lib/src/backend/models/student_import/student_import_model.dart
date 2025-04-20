import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a record of a student import operation
class StudentImportModel {
  final String importId; // Import ID
  final String importedBy; // UID of admin who imported
  final Timestamp importDate; // Import timestamp
  final String fileName; // Name of imported file
  final int totalRecords; // Total records in import
  final int successfulImports; // Successfully imported records
  final int failedImports; // Failed import records
  final List<ImportError> errors; // Array of error objects
  final String status; // Status (e.g., "completed", "failed", "processing")
  final List<String> departments; // Departments included in import
  final String batch; // Batch/Session

  StudentImportModel({
    required this.importId,
    required this.importedBy,
    required this.importDate,
    required this.fileName,
    required this.totalRecords,
    required this.successfulImports,
    required this.failedImports,
    required this.errors,
    required this.status,
    required this.departments,
    required this.batch,
  });

  factory StudentImportModel.fromJson(Map<String, dynamic> json) {
    return StudentImportModel(
      importId: json['importId'] as String,
      importedBy: json['importedBy'] as String,
      importDate: json['importDate'] as Timestamp,
      fileName: json['fileName'] as String,
      totalRecords: json['totalRecords'] as int,
      successfulImports: json['successfulImports'] as int,
      failedImports: json['failedImports'] as int,
      errors: (json['errors'] as List)
          .map((e) => ImportError.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
      departments: List<String>.from(json['departments'] as List),
      batch: json['batch'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importId': importId,
      'importedBy': importedBy,
      'importDate': importDate,
      'fileName': fileName,
      'totalRecords': totalRecords,
      'successfulImports': successfulImports,
      'failedImports': failedImports,
      'errors': errors.map((e) => e.toJson()).toList(),
      'status': status,
      'departments': departments,
      'batch': batch,
    };
  }

  /// Create a new import record with initial values
  factory StudentImportModel.create({
    required String importId,
    required String importedBy,
    required String fileName,
    required int totalRecords,
    required List<String> departments,
    required String batch,
  }) {
    return StudentImportModel(
      importId: importId,
      importedBy: importedBy,
      importDate: Timestamp.now(),
      fileName: fileName,
      totalRecords: totalRecords,
      successfulImports: 0,
      failedImports: 0,
      errors: [],
      status: 'processing',
      departments: departments,
      batch: batch,
    );
  }

  StudentImportModel copyWith({
    String? importId,
    String? importedBy,
    Timestamp? importDate,
    String? fileName,
    int? totalRecords,
    int? successfulImports,
    int? failedImports,
    List<ImportError>? errors,
    String? status,
    List<String>? departments,
    String? batch,
  }) {
    return StudentImportModel(
      importId: importId ?? this.importId,
      importedBy: importedBy ?? this.importedBy,
      importDate: importDate ?? this.importDate,
      fileName: fileName ?? this.fileName,
      totalRecords: totalRecords ?? this.totalRecords,
      successfulImports: successfulImports ?? this.successfulImports,
      failedImports: failedImports ?? this.failedImports,
      errors: errors ?? this.errors,
      status: status ?? this.status,
      departments: departments ?? this.departments,
      batch: batch ?? this.batch,
    );
  }

  /// Update the import record with success
  StudentImportModel addSuccess() {
    return copyWith(
      successfulImports: successfulImports + 1,
    );
  }

  /// Update the import record with failure
  StudentImportModel addFailure(ImportError error) {
    final newErrors = List<ImportError>.from(errors)..add(error);
    return copyWith(
      failedImports: failedImports + 1,
      errors: newErrors,
    );
  }

  /// Mark the import as complete
  StudentImportModel markComplete() {
    return copyWith(
      status: 'completed',
    );
  }

  /// Mark the import as failed
  StudentImportModel markFailed(String reason) {
    return copyWith(
      status: 'failed',
    );
  }
}

/// Model for tracking import errors
class ImportError {
  final String studentId;
  final String error;
  final int rowNumber;

  ImportError({
    required this.studentId,
    required this.error,
    required this.rowNumber,
  });

  factory ImportError.fromJson(Map<String, dynamic> json) {
    return ImportError(
      studentId: json['studentId'] as String,
      error: json['error'] as String,
      rowNumber: json['rowNumber'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'error': error,
      'rowNumber': rowNumber,
    };
  }
}
