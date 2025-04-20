import 'dart:io';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/student_import/index.dart';
import '../services/firebase_service.dart';

/// Repository for managing student data imports and related operations
class StudentImportRepository {
  final FirebaseService _firebaseService = FirebaseService();

  // CRUD Operations for Students

  /// Add a new student to Firestore
  Future<String> addStudent(StudentModel student) async {
    try {
      // Save to students collection
      await _firebaseService.studentsCollection
          .doc(student.uid)
          .set(student.toJson());

      // Also save user info to users collection
      await _firebaseService.usersCollection
          .doc(student.uid)
          .set(student.toUserModel().toJson());

      return student.uid;
    } catch (e) {
      throw Exception('Error adding student: ${e.toString()}');
    }
  }

  /// Get a student by ID
  Future<StudentModel?> getStudentById(String uid) async {
    try {
      final doc = await _firebaseService.studentsCollection.doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      return StudentModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error getting student: ${e.toString()}');
    }
  }

  /// Get students by batch and department
  Future<List<StudentModel>> getStudentsByBatchAndDepartment(
      String batch, String department) async {
    try {
      final querySnapshot = await _firebaseService.studentsCollection
          .where('batch', isEqualTo: batch)
          .where('department', isEqualTo: department)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              StudentModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error getting students: ${e.toString()}');
    }
  }

  /// Update an existing student
  Future<void> updateStudent(StudentModel student) async {
    try {
      // Update in students collection
      await _firebaseService.studentsCollection
          .doc(student.uid)
          .update(student.toJson());

      // Also update basic info in users collection
      await _firebaseService.usersCollection
          .doc(student.uid)
          .update(student.toUserModel().toJson());
    } catch (e) {
      throw Exception('Error updating student: ${e.toString()}');
    }
  }

  /// Delete a student (typically soft-delete by setting isActive to false)
  Future<void> deleteStudent(String uid) async {
    try {
      // Soft delete by updating isActive flag
      await _firebaseService.studentsCollection
          .doc(uid)
          .update({'isActive': false});

      // Also update in users collection
      await _firebaseService.usersCollection
          .doc(uid)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Error deleting student: ${e.toString()}');
    }
  }

  // CRUD Operations for Departments

  /// Add a new department
  Future<String> addDepartment(DepartmentModel department) async {
    try {
      await _firebaseService.departmentsCollection
          .doc(department.departmentId)
          .set(department.toJson());

      return department.departmentId;
    } catch (e) {
      throw Exception('Error adding department: ${e.toString()}');
    }
  }

  /// Get a department by ID
  Future<DepartmentModel?> getDepartmentById(String departmentId) async {
    try {
      final doc =
          await _firebaseService.departmentsCollection.doc(departmentId).get();

      if (!doc.exists) {
        return null;
      }

      return DepartmentModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error getting department: ${e.toString()}');
    }
  }

  /// Get all departments
  Future<List<DepartmentModel>> getAllDepartments() async {
    try {
      final querySnapshot = await _firebaseService.departmentsCollection.get();

      return querySnapshot.docs
          .map((doc) =>
              DepartmentModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error getting departments: ${e.toString()}');
    }
  }

  /// Update an existing department
  Future<void> updateDepartment(DepartmentModel department) async {
    try {
      await _firebaseService.departmentsCollection
          .doc(department.departmentId)
          .update(department.toJson());
    } catch (e) {
      throw Exception('Error updating department: ${e.toString()}');
    }
  }

  // CRUD Operations for Batches

  /// Add a new batch
  Future<String> addBatch(BatchModel batch) async {
    try {
      await _firebaseService.batchesCollection
          .doc(batch.batchId)
          .set(batch.toJson());

      return batch.batchId;
    } catch (e) {
      throw Exception('Error adding batch: ${e.toString()}');
    }
  }

  /// Get a batch by ID
  Future<BatchModel?> getBatchById(String batchId) async {
    try {
      final doc = await _firebaseService.batchesCollection.doc(batchId).get();

      if (!doc.exists) {
        return null;
      }

      return BatchModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error getting batch: ${e.toString()}');
    }
  }

  /// Get all active batches
  Future<List<BatchModel>> getActiveBatches() async {
    try {
      final querySnapshot = await _firebaseService.batchesCollection
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BatchModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error getting active batches: ${e.toString()}');
    }
  }

  /// Update an existing batch
  Future<void> updateBatch(BatchModel batch) async {
    try {
      await _firebaseService.batchesCollection
          .doc(batch.batchId)
          .update(batch.toJson());
    } catch (e) {
      throw Exception('Error updating batch: ${e.toString()}');
    }
  }

  /// Advance all batches to the next semester
  Future<void> advanceAllBatches() async {
    try {
      // Get all active batches
      final batches = await getActiveBatches();

      // Update each batch
      final batch = _firebaseService.firestore.batch();

      for (final batchModel in batches) {
        final updatedBatch = batchModel.advanceSemester();
        final batchRef =
            _firebaseService.batchesCollection.doc(updatedBatch.batchId);
        batch.update(batchRef, updatedBatch.toJson());
      }

      // Commit batch update
      await batch.commit();
    } catch (e) {
      throw Exception('Error advancing batches: ${e.toString()}');
    }
  }

  // Student Import Operations

  /// Import students from Excel file
  Future<StudentImportModel> importStudentsFromExcel({
    required File excelFile,
    required String importedBy,
    required String batch,
  }) async {
    try {
      final fileName = path.basename(excelFile.path);
      final importId = _firebaseService.generateId('studentImports');
      final bytes = await excelFile.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Get the first sheet
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet]!;

      // Skip header row and count records
      final totalRecords = table.rows.length - 1;

      // Parse departments from the file
      final departmentSet = <String>{};
      for (var i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        final department = row[2]?.value.toString() ??
            ''; // Assuming department is in column C
        if (department.isNotEmpty) {
          departmentSet.add(department);
        }
      }
      final departments = departmentSet.toList();

      // Create import record
      final importModel = StudentImportModel.create(
        importId: importId,
        importedBy: importedBy,
        fileName: fileName,
        totalRecords: totalRecords,
        departments: departments,
        batch: batch,
      );

      // Save initial import record
      await _firebaseService.studentImportsCollection
          .doc(importId)
          .set(importModel.toJson());

      // Process the file
      var currentImport = importModel;

      // Process each row (skip header)
      for (var i = 1; i < table.rows.length; i++) {
        try {
          final row = table.rows[i];

          // Extract student data from row
          final studentId =
              row[0]?.value.toString() ?? ''; // Column A: Student ID
          final name = row[1]?.value.toString() ?? ''; // Column B: Name
          final department =
              row[2]?.value.toString() ?? ''; // Column C: Department
          final section = row[3]?.value.toString() ?? ''; // Column D: Section
          final email = row[4]?.value.toString() ?? ''; // Column E: Email
          final personalEmail =
              row[5]?.value.toString() ?? ''; // Column F: Personal Email
          final mobileNumber =
              row[6]?.value.toString() ?? ''; // Column G: Mobile

          // Validate required fields
          if (studentId.isEmpty ||
              name.isEmpty ||
              department.isEmpty ||
              email.isEmpty) {
            throw Exception('Missing required fields');
          }

          // Create Firebase Auth account with default password
          final defaultPassword =
              'Attend@${studentId.substring(studentId.length - 4)}';
          final userCredential =
              await _firebaseService.auth.createUserWithEmailAndPassword(
            email: email,
            password: defaultPassword,
          );

          final uid = userCredential.user!.uid;

          // Create student model
          final studentModel = StudentModel(
            uid: uid,
            studentId: studentId,
            displayName: name,
            email: email,
            personalEmail: personalEmail.isNotEmpty ? personalEmail : null,
            mobileNumber: mobileNumber.isNotEmpty ? mobileNumber : null,
            department: department,
            section: section.isNotEmpty ? section : null,
            batch: batch,
            currentSemester: 1, // Default to first semester
            currentYear: 1, // Default to first year
            accountCreatedAt: Timestamp.now(),
            lastLoginAt: Timestamp.now(),
            isActive: true,
            passwordChanged: false,
            defaultPassword: defaultPassword,
          );

          // Save student to Firestore
          await addStudent(studentModel);

          // Update import record
          currentImport = currentImport.addSuccess();
          await _firebaseService.studentImportsCollection
              .doc(importId)
              .update({'successfulImports': currentImport.successfulImports});
        } catch (e) {
          // Record the error and continue
          final error = ImportError(
            studentId: table.rows[i][0]?.value.toString() ?? 'Unknown',
            error: e.toString(),
            rowNumber: i,
          );

          currentImport = currentImport.addFailure(error);
          await _firebaseService.studentImportsCollection.doc(importId).update({
            'failedImports': currentImport.failedImports,
            'errors': currentImport.errors.map((e) => e.toJson()).toList(),
          });
        }
      }

      // Mark import as complete
      currentImport = currentImport.markComplete();
      await _firebaseService.studentImportsCollection
          .doc(importId)
          .update({'status': 'completed'});

      return currentImport;
    } catch (e) {
      // If there's an error with the overall process, mark the import as failed
      final failedImport = StudentImportModel.create(
        importId: _firebaseService.generateId('studentImports'),
        importedBy: importedBy,
        fileName: path.basename(excelFile.path),
        totalRecords: 0,
        departments: [],
        batch: batch,
      ).markFailed(e.toString());

      await _firebaseService.studentImportsCollection
          .doc(failedImport.importId)
          .set(failedImport.toJson());

      throw Exception('Error importing students: ${e.toString()}');
    }
  }

  /// Get all student imports
  Future<List<StudentImportModel>> getAllImports() async {
    try {
      final querySnapshot = await _firebaseService.studentImportsCollection
          .orderBy('importDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              StudentImportModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error getting imports: ${e.toString()}');
    }
  }

  /// Get import by ID
  Future<StudentImportModel?> getImportById(String importId) async {
    try {
      final doc =
          await _firebaseService.studentImportsCollection.doc(importId).get();

      if (!doc.exists) {
        return null;
      }

      return StudentImportModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error getting import: ${e.toString()}');
    }
  }

  /// Generate default credentials for a batch of students
  Future<Map<String, String>> generateDefaultCredentials(
      String batchId, String departmentId) async {
    try {
      final students =
          await getStudentsByBatchAndDepartment(batchId, departmentId);
      final credentials = <String, String>{};

      for (final student in students) {
        // Only generate for students without a default password
        if (student.defaultPassword == null) {
          final defaultPassword =
              'Attend@${student.studentId.substring(student.studentId.length - 4)}';

          // Update student record
          await _firebaseService.studentsCollection
              .doc(student.uid)
              .update({'defaultPassword': defaultPassword});

          // Add to credentials map
          credentials[student.email] = defaultPassword;

          // Reset password in Firebase Auth
          await _firebaseService.auth
              .sendPasswordResetEmail(email: student.email);
        } else {
          // Use existing default password
          credentials[student.email] = student.defaultPassword!;
        }
      }

      return credentials;
    } catch (e) {
      throw Exception('Error generating credentials: ${e.toString()}');
    }
  }
}
