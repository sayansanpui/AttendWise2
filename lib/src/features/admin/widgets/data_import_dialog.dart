import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib; // Added for Excel processing
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart'; // Added for file handling
import 'package:open_file/open_file.dart'; // Added for opening files
import 'package:firebase_auth/firebase_auth.dart'; // Added for Firebase Auth
import 'dart:math'; // Added for password generation
import 'package:permission_handler/permission_handler.dart'; // Added for runtime permissions
import 'package:device_info_plus/device_info_plus.dart'; // Added for device info
import '../../../config/theme/dimensions.dart';

// Web-specific imports using conditional imports
import 'web_utils.dart' if (dart.library.io) 'mobile_utils.dart';

class DataImportDialog extends ConsumerStatefulWidget {
  const DataImportDialog({super.key});

  @override
  ConsumerState<DataImportDialog> createState() => _DataImportDialogState();
}

class _DataImportDialogState extends ConsumerState<DataImportDialog> {
  bool _isLoading = false;
  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  String _fileName = '';
  List<List<dynamic>>? _csvData;
  List<Map<String, dynamic>>? _excelData; // Added for Excel data
  String _importType = 'students'; // Default to students
  // Add state variables for expansion panels
  bool _isFieldMappingExpanded = false; // Collapsed by default
  bool _isPreviewExpanded = false; // Collapsed by default

  // Added to keep track of field mappings for Excel/CSV
  final Map<String, String> _fieldMappings = {
    'studentId': '',
    'name': '',
    'email': '',
    'personalEmail': '',
    'mobileNumber': '',
    'section': '',
    'stream': '',
    'department': '',
    'specialization': '',
    'batch': '',
    'joiningYear': '',
    'joiningSemester': '', // Added joining semester
    'passOutYear': '',
    'bloodGroup': '',
    'rank': '',
    'examType': '',
    'category': '',
    'fatherName': '',
    'fatherMobile': '',
    'motherName': '',
    'motherMobile': '',
    'admissionDate': '',
    'universityRollNo': '',
    'universityRegistrationNo': '',
    'lastQualification': '', // Added last qualification
    'lastQualificationYear': '', // Added last qualification passout year
    'aadharNo': '', // Added Aadhar number
    'dob': '', // Added date of birth
  };

  // Keep track of selected columns from the first row of data
  List<String> _headers = [];

  // Method to check and request storage permissions on Android
  Future<bool> _checkPermissions() async {
    if (kIsWeb) {
      // Web doesn't need runtime permissions
      return true;
    }
    // Check Android version
    if (Platform.isAndroid) {
      // Get Android SDK version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      // For Android 13+ (API 33+), request new media permissions
      // instead of storage permissions
      if (sdkVersion >= 33) {
        // Request media permissions for Android 13+
        Map<Permission, PermissionStatus> statuses = await [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ].request();

        // Check if any permission is granted (we only need one for Excel files)
        if (statuses.values.any((status) => status.isGranted)) {
          return true;
        } else {
          // Show error message if all permissions denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission is required to access files'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      } else {
        // For Android 12 and below, use storage permission
        PermissionStatus status = await Permission.storage.status;

        if (status.isGranted) {
          return true;
        }

        // Request permission if not granted
        status = await Permission.storage.request();

        if (status.isGranted) {
          return true;
        } else {
          // Show error message if permission denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission is required to access files'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }
      }
    }

    // For iOS and other platforms, return true
    return true;
  }

  Future<void> _pickFile() async {
    // For Android, check permissions first
    if (!kIsWeb) {
      bool hasPermission = await _checkPermissions();
      if (!hasPermission) {
        return;
      }
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
          _csvData = null; // Reset CSV data when selecting a new file
          _excelData = null; // Reset Excel data when selecting a new file
          _headers = []; // Reset headers

          if (kIsWeb) {
            // For web platform
            _selectedFileBytes = result.files.single.bytes;
            _selectedFilePath = null;
          } else {
            // For mobile/desktop platforms
            _selectedFilePath = result.files.single.path;
            _selectedFileBytes = null;
          }
        });

        // Parse the file based on type
        if (_fileName.endsWith('.csv')) {
          await _parseCSV();
        } else if (_fileName.endsWith('.xlsx') || _fileName.endsWith('.xls')) {
          await _parseExcel();
        }

        // Auto-map fields if headers exist
        _autoMapFields();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _autoMapFields() {
    if (_headers.isEmpty) return;

    // Clear previous mappings
    _fieldMappings.forEach((key, value) {
      _fieldMappings[key] = '';
    });

    // Try to auto-map fields based on header names
    for (String header in _headers) {
      String lowerHeader = header.toLowerCase();

      // Map student ID
      if (_fieldMappings['studentId']!.isEmpty &&
          (lowerHeader == 'studentid' ||
              lowerHeader.contains('student id') ||
              lowerHeader == 'id' ||
              lowerHeader == 'roll no')) {
        _fieldMappings['studentId'] = header;
      }

      // Map name
      else if (_fieldMappings['name']!.isEmpty &&
          (lowerHeader == 'displayname' ||
              lowerHeader == 'name' ||
              lowerHeader == 'student name' ||
              lowerHeader == 'full name')) {
        _fieldMappings['name'] = header;
      }

      // Map email
      else if (_fieldMappings['email']!.isEmpty &&
          (lowerHeader == 'email' ||
              lowerHeader == 'college email' ||
              lowerHeader == 'official email')) {
        _fieldMappings['email'] = header;
      }

      // Map personal email
      else if (_fieldMappings['personalEmail']!.isEmpty &&
          (lowerHeader == 'personalemail' ||
              lowerHeader == 'personal email' ||
              lowerHeader == 'student email id')) {
        _fieldMappings['personalEmail'] = header;
      }

      // Map mobile number
      else if (_fieldMappings['mobileNumber']!.isEmpty &&
          (lowerHeader == 'mobilenumber' ||
              lowerHeader == 'mobile' ||
              lowerHeader == 'phone' ||
              lowerHeader == 'phone number' ||
              lowerHeader == 'contact')) {
        _fieldMappings['mobileNumber'] = header;
      }

      // Map section
      else if (_fieldMappings['section']!.isEmpty &&
          (lowerHeader == 'section')) {
        _fieldMappings['section'] = header;
      }

      // Map stream
      else if (_fieldMappings['stream']!.isEmpty && (lowerHeader == 'stream')) {
        _fieldMappings['stream'] = header;
      }

      // Map department
      else if (_fieldMappings['department']!.isEmpty &&
          (lowerHeader == 'department' || lowerHeader == 'dept')) {
        _fieldMappings['department'] = header;
      }

      // Map specialization
      else if (_fieldMappings['specialization']!.isEmpty &&
          (lowerHeader == 'specialization')) {
        _fieldMappings['specialization'] = header;
      }

      // Map batch
      else if (_fieldMappings['batch']!.isEmpty &&
          (lowerHeader == 'batch' ||
              lowerHeader == 'session' ||
              lowerHeader.contains('batch'))) {
        _fieldMappings['batch'] = header;
      }

      // Map joining year
      else if (_fieldMappings['joiningYear']!.isEmpty &&
          (lowerHeader == 'joiningyear' ||
              lowerHeader == 'joining year' ||
              lowerHeader == 'admission year' ||
              lowerHeader == 'year of joining')) {
        _fieldMappings['joiningYear'] = header;
      }

      // Map joining semester
      else if (_fieldMappings['joiningSemester']!.isEmpty &&
          (lowerHeader == 'joiningsemester' ||
              lowerHeader == 'joining semester' ||
              lowerHeader == 'semester of joining')) {
        _fieldMappings['joiningSemester'] = header;
      }

      // Map pass out year
      else if (_fieldMappings['passOutYear']!.isEmpty &&
          (lowerHeader == 'passoutyear' ||
              lowerHeader == 'pass out year' ||
              lowerHeader == 'graduation year' ||
              lowerHeader == 'year of passing')) {
        _fieldMappings['passOutYear'] = header;
      }

      // Map blood group
      else if (_fieldMappings['bloodGroup']!.isEmpty &&
          (lowerHeader == 'bloodgroup' || lowerHeader == 'blood group')) {
        _fieldMappings['bloodGroup'] = header;
      }

      // Map rank
      else if (_fieldMappings['rank']!.isEmpty && (lowerHeader == 'rank')) {
        _fieldMappings['rank'] = header;
      }

      // Map exam type
      else if (_fieldMappings['examType']!.isEmpty &&
          (lowerHeader == 'examtype' || lowerHeader == 'exam type')) {
        _fieldMappings['examType'] = header;
      }

      // Map category
      else if (_fieldMappings['category']!.isEmpty &&
          (lowerHeader == 'category')) {
        _fieldMappings['category'] = header;
      }

      // Map father's name
      else if (_fieldMappings['fatherName']!.isEmpty &&
          (lowerHeader == 'fathername' ||
              lowerHeader == 'father name' ||
              lowerHeader == 'father')) {
        _fieldMappings['fatherName'] = header;
      }

      // Map father's mobile
      else if (_fieldMappings['fatherMobile']!.isEmpty &&
          (lowerHeader == 'fathermobile' ||
              lowerHeader == 'father mobile' ||
              lowerHeader == 'father phone')) {
        _fieldMappings['fatherMobile'] = header;
      }

      // Map mother's name
      else if (_fieldMappings['motherName']!.isEmpty &&
          (lowerHeader == 'mothername' ||
              lowerHeader == 'mother name' ||
              lowerHeader == 'mother')) {
        _fieldMappings['motherName'] = header;
      }

      // Map mother's mobile
      else if (_fieldMappings['motherMobile']!.isEmpty &&
          (lowerHeader == 'mothermobile' ||
              lowerHeader == 'mother mobile' ||
              lowerHeader == 'mother phone')) {
        _fieldMappings['motherMobile'] = header;
      }

      // Map admission date
      else if (_fieldMappings['admissionDate']!.isEmpty &&
          (lowerHeader == 'admissiondate' ||
              lowerHeader == 'admission date' ||
              lowerHeader == 'date of admission')) {
        _fieldMappings['admissionDate'] = header;
      }

      // Map university roll number
      else if (_fieldMappings['universityRollNo']!.isEmpty &&
          (lowerHeader == 'universityrollno' ||
              lowerHeader == 'university roll no' ||
              lowerHeader == 'university roll')) {
        _fieldMappings['universityRollNo'] = header;
      }

      // Map university registration number
      else if (_fieldMappings['universityRegistrationNo']!.isEmpty &&
          (lowerHeader == 'universityregistrationno' ||
              lowerHeader == 'university registration no' ||
              lowerHeader == 'registration no')) {
        _fieldMappings['universityRegistrationNo'] = header;
      }

      // Map last qualification
      else if (_fieldMappings['lastQualification']!.isEmpty &&
          (lowerHeader == 'lastqualification' ||
              lowerHeader == 'last qualification' ||
              lowerHeader == 'qualification')) {
        _fieldMappings['lastQualification'] = header;
      }

      // Map last qualification passout year
      else if (_fieldMappings['lastQualificationYear']!.isEmpty &&
          (lowerHeader == 'lastqualificationyear' ||
              lowerHeader == 'last qualification year' ||
              lowerHeader == 'qualification year')) {
        _fieldMappings['lastQualificationYear'] = header;
      }

      // Map Aadhar number
      else if (_fieldMappings['aadharNo']!.isEmpty &&
          (lowerHeader == 'aadharno' ||
              lowerHeader == 'aadhar no' ||
              lowerHeader == 'aadhar')) {
        _fieldMappings['aadharNo'] = header;
      }

      // Map date of birth
      else if (_fieldMappings['dob']!.isEmpty &&
          (lowerHeader == 'dob' ||
              lowerHeader == 'date of birth' ||
              lowerHeader == 'birthdate')) {
        _fieldMappings['dob'] = header;
      }
    }

    // Log mapping for debugging
    print('Field mappings after auto-mapping: $_fieldMappings');
  }

  Future<void> _parseCSV() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String contents;

      if (kIsWeb && _selectedFileBytes != null) {
        // For web, convert bytes to string
        contents = String.fromCharCodes(_selectedFileBytes!);
      } else if (_selectedFilePath != null) {
        // For mobile/desktop, read from file
        final file = File(_selectedFilePath!);
        contents = await file.readAsString();
      } else {
        throw Exception('No file selected');
      }

      // Parse CSV file
      final parsedData = const CsvToListConverter().convert(contents);
      setState(() {
        _csvData = parsedData;
        if (parsedData.isNotEmpty) {
          _headers = parsedData[0].map((e) => e.toString()).toList();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing CSV: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // New method to parse Excel files
  Future<void> _parseExcel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb && _selectedFileBytes != null) {
        // For web, decode from bytes
        final excel = excel_lib.Excel.decodeBytes(_selectedFileBytes!);
        _processExcelData(excel);
      } else if (_selectedFilePath != null) {
        // For mobile/desktop, read from file
        final bytes = await File(_selectedFilePath!).readAsBytes();
        final excel = excel_lib.Excel.decodeBytes(bytes);
        _processExcelData(excel);
      } else {
        throw Exception('No file selected');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing Excel file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to extract data from Excel
  void _processExcelData(excel_lib.Excel excel) {
    if (excel.tables.isEmpty) {
      throw Exception('No worksheet found in Excel file');
    }

    // Use the first sheet
    final sheet = excel.tables.entries.first.value;
    final rows = sheet.rows;

    if (rows.isEmpty) {
      throw Exception('Excel sheet is empty');
    }

    // Convert Excel data to list format for display
    List<List<dynamic>> data = [];

    // Extract headers (first row)
    List<String> headers = [];
    for (var cell in rows[0]) {
      headers.add(cell?.value.toString() ?? '');
    }
    data.add(headers);

    // Extract data rows
    for (int i = 1; i < rows.length; i++) {
      List<dynamic> rowData = [];
      for (var cell in rows[i]) {
        rowData.add(cell?.value ?? '');
      }
      data.add(rowData);
    }

    setState(() {
      _csvData = data; // Use _csvData for UI display regardless of file type
      _headers = headers;

      // Also prepare Excel-specific data structure for import
      _excelData = [];
      for (int i = 1; i < data.length; i++) {
        Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length && j < data[i].length; j++) {
          row[headers[j]] = data[i][j].toString();
        }
        _excelData!.add(row);
      }
    });
  }

  Future<void> _importData() async {
    if (_selectedFilePath == null && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if required fields are mapped for students
    if (_importType == 'students') {
      if (_fieldMappings['studentId']!.isEmpty ||
          _fieldMappings['name']!.isEmpty ||
          _fieldMappings['email']!.isEmpty ||
          _fieldMappings['department']!.isEmpty ||
          _fieldMappings['batch']!.isEmpty ||
          _fieldMappings['joiningYear']!.isEmpty ||
          _fieldMappings['passOutYear']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'All required fields must be mapped (Student ID, Name, Email, Department, Batch, Joining Year, Pass Out Year)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Handle different import types
      if (_importType == 'students') {
        await _importStudents();
      } else if (_importType == 'teachers') {
        // TODO: Implement teacher import logic
        await Future.delayed(const Duration(seconds: 2));
        throw Exception('Teacher import not yet implemented');
      } else if (_importType == 'classes') {
        // TODO: Implement class import logic
        await Future.delayed(const Duration(seconds: 2));
        throw Exception('Class import not yet implemented');
      }

      // Show success message and close dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $_importType data'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // New method to handle student import specifically with better field handling and automatic password generation
  Future<void> _importStudents() async {
    List<Map<String, dynamic>> studentsToImport = [];

    // Determine the data source
    if (_excelData != null) {
      // Use Excel data if available
      for (var row in _excelData!) {
        try {
          // Skip rows that don't have the required fields
          if (!row.containsKey(_fieldMappings['studentId']) ||
              !row.containsKey(_fieldMappings['name']) ||
              !row.containsKey(_fieldMappings['email']) ||
              !row.containsKey(_fieldMappings['department']) ||
              !row.containsKey(_fieldMappings['batch']) ||
              !row.containsKey(_fieldMappings['joiningYear']) ||
              !row.containsKey(_fieldMappings['passOutYear'])) {
            continue;
          }

          final studentId = row[_fieldMappings['studentId']].toString().trim();
          final displayName = row[_fieldMappings['name']].toString().trim();
          final email = row[_fieldMappings['email']].toString().trim();
          final department =
              row[_fieldMappings['department']].toString().trim();
          final batch = row[_fieldMappings['batch']].toString().trim();
          final joiningYear =
              row[_fieldMappings['joiningYear']].toString().trim();
          final passOutYear =
              row[_fieldMappings['passOutYear']].toString().trim();

          // Skip if mandatory fields are empty
          if (studentId.isEmpty ||
              displayName.isEmpty ||
              email.isEmpty ||
              department.isEmpty ||
              batch.isEmpty ||
              joiningYear.isEmpty ||
              passOutYear.isEmpty) {
            continue;
          }

          // Generate a default password based on student ID
          final defaultPassword =
              // 'Attend@${studentId.substring(max(0, studentId.length - 4))}';
              'password';

          // Create base student document with required fields
          Map<String, dynamic> student = {
            'uid': '', // Will be filled after Firebase Auth account creation
            'studentId': studentId,
            'displayName': displayName,
            'email': email,
            'department': department,
            'batch': batch,
            'section': _getValueFromRow(row, 'section') ?? '',
            'isActive': true,
            'passwordChanged': false,
            'defaultPassword': defaultPassword,
            'joiningYear': joiningYear,
            'joiningSemester': _getValueFromRow(row, 'joiningSemester') ?? '',
            'passOutYear': passOutYear,
            'bloodGroup': _getValueFromRow(row, 'bloodGroup') ?? '',
            'rank': _getValueFromRow(row, 'rank') ?? '',
            'examType': _getValueFromRow(row, 'examType') ?? '',
            'category': _getValueFromRow(row, 'category') ?? '',
            'fatherName': _getValueFromRow(row, 'fatherName') ?? '',
            'fatherMobile': _getValueFromRow(row, 'fatherMobile') ?? '',
            'motherName': _getValueFromRow(row, 'motherName') ?? '',
            'motherMobile': _getValueFromRow(row, 'motherMobile') ?? '',
            'admissionDate': _getValueFromRow(row, 'admissionDate') ?? '',
            'mobileNumber': _getValueFromRow(row, 'mobileNumber') ?? '',
            'personalEmail': _getValueFromRow(row, 'personalEmail') ?? '',
          };

          // Add all optional fields from Excel if they exist
          final allFields = [
            'stream',
            'specialization',
            'universityRollNo',
            'universityRegistrationNo',
            'courseStartingYear',
            'courseEndingYear',
            'courseDuration',
            'courseName',
            'currentSemesterName',
            'instituteName',
            'entranceExam',
            'entranceExamRank',
            'address',
            'lastQualification',
            'lastQualificationYear',
            'aadharNo',
            'dob',
          ];

          for (var field in allFields) {
            final value = _getValueFromRow(row, field);
            if (value != null && value.isNotEmpty) {
              student[field] = value;
            }
          }

          studentsToImport.add(student);
        } catch (e) {
          print('Error processing Excel row: $e');
          // Continue with next row
        }
      }
    } else if (_csvData != null && _csvData!.length > 1) {
      // Use CSV data
      // First row contains headers
      final headers = _csvData![0];

      // Process data rows
      for (int i = 1; i < _csvData!.length; i++) {
        try {
          final row = _csvData![i];
          // Skip rows that don't have enough data
          if (row.length < headers.length) continue;

          // Convert CSV row to map for easier processing
          Map<String, dynamic> rowMap = {};
          for (int j = 0; j < headers.length; j++) {
            if (j < row.length) {
              rowMap[headers[j].toString()] = row[j].toString();
            }
          }

          // Get required values using mapped fields
          final studentIdField = _fieldMappings['studentId']!;
          final nameField = _fieldMappings['name']!;
          final emailField = _fieldMappings['email']!;
          final departmentField = _fieldMappings['department']!;
          final batchField = _fieldMappings['batch']!;
          final joiningYearField = _fieldMappings['joiningYear']!;
          final passOutYearField = _fieldMappings['passOutYear']!;

          // Skip if any required field mapping is missing
          if (studentIdField.isEmpty ||
              nameField.isEmpty ||
              emailField.isEmpty ||
              departmentField.isEmpty ||
              batchField.isEmpty ||
              joiningYearField.isEmpty ||
              passOutYearField.isEmpty) {
            continue;
          }

          // Get values
          final studentIdIndex = headers.indexOf(studentIdField);
          final nameIndex = headers.indexOf(nameField);
          final emailIndex = headers.indexOf(emailField);
          final departmentIndex = headers.indexOf(departmentField);
          final batchIndex = headers.indexOf(batchField);
          final joiningYearIndex = headers.indexOf(joiningYearField);
          final passOutYearIndex = headers.indexOf(passOutYearField);

          // Skip if any required field can't be found
          if (studentIdIndex < 0 ||
              nameIndex < 0 ||
              emailIndex < 0 ||
              departmentIndex < 0 ||
              batchIndex < 0 ||
              joiningYearIndex < 0 ||
              passOutYearIndex < 0) {
            continue;
          }

          final studentId = row[studentIdIndex].toString().trim();
          final displayName = row[nameIndex].toString().trim();
          final email = row[emailIndex].toString().trim();
          final department = row[departmentIndex].toString().trim();
          final batch = row[batchIndex].toString().trim();
          final joiningYear = row[joiningYearIndex].toString().trim();
          final passOutYear = row[passOutYearIndex].toString().trim();

          // Skip if any required value is empty
          if (studentId.isEmpty ||
              displayName.isEmpty ||
              email.isEmpty ||
              department.isEmpty ||
              batch.isEmpty ||
              joiningYear.isEmpty ||
              passOutYear.isEmpty) {
            continue;
          }

          // Generate a default password
          final defaultPassword =
              // 'Attend@${studentId.substring(max(0, studentId.length - 4))}';
              'password';

          // Create student document
          Map<String, dynamic> student = {
            'uid': '',
            'studentId': studentId,
            'displayName': displayName,
            'email': email,
            'department': department,
            'batch': batch,
            'isActive': true,
            'passwordChanged': false,
            'defaultPassword': defaultPassword,
            'joiningYear': joiningYear,
            'joiningSemester':
                _getValueFromRow(rowMap, 'joiningSemester') ?? '',
            'passOutYear': passOutYear,
          };

          // Add other fields if they're mapped
          final fieldMappingsList = {
            'section': 'section',
            'bloodGroup': 'bloodGroup',
            'rank': 'rank',
            'examType': 'examType',
            'category': 'category',
            'fatherName': 'fatherName',
            'fatherMobile': 'fatherMobile',
            'motherName': 'motherName',
            'motherMobile': 'motherMobile',
            'admissionDate': 'admissionDate',
            'mobileNumber': 'mobileNumber',
            'personalEmail': 'personalEmail',
            'stream': 'stream',
            'specialization': 'specialization',
            'universityRollNo': 'universityRollNo',
            'universityRegistrationNo': 'universityRegistrationNo',
            'lastQualification': 'lastQualification',
            'lastQualificationYear': 'lastQualificationYear',
            'aadharNo': 'aadharNo',
            'dob': 'dob',
          };

          fieldMappingsList.forEach((key, value) {
            if (_fieldMappings[key]!.isNotEmpty) {
              final index = headers.indexOf(_fieldMappings[key]!);
              if (index >= 0 &&
                  index < row.length &&
                  row[index].toString().isNotEmpty) {
                student[value] = row[index].toString().trim();
              }
            }
          });

          studentsToImport.add(student);
        } catch (e) {
          print('Error processing CSV row: $e');
          // Continue with next row
        }
      }
    }

    if (studentsToImport.isEmpty) {
      throw Exception('No valid student data found to import');
    }

    print('Prepared ${studentsToImport.length} students for import');

    // Use Firestore batch and Firebase Auth for creating accounts
    final batch = FirebaseFirestore.instance.batch();
    final studentsRef = FirebaseFirestore.instance.collection('students');
    final usersRef = FirebaseFirestore.instance.collection('users');

    int successCount = 0;
    List<String> failedImports = [];

    // Process each student
    for (var student in studentsToImport) {
      try {
        // Check if a user with this email already exists
        bool userExists = false;
        try {
          final methods = await FirebaseAuth.instance
              .fetchSignInMethodsForEmail(student['email']);
          userExists = methods.isNotEmpty;
        } catch (e) {
          print('Error checking existing user: $e');
          // Continue with account creation attempt
        }

        UserCredential? userCredential;
        String uid = '';

        if (userExists) {
          // If user exists, skip creation but add to failed imports
          failedImports.add('${student['studentId']} - Email already exists');
          continue;
        } else {
          // Try to create user account with retry logic
          int retryCount = 0;
          const maxRetries = 3;
          bool success = false;

          while (!success && retryCount < maxRetries) {
            try {
              // Create Firebase Auth account with default password
              userCredential =
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: student['email'],
                password: student['defaultPassword'],
              );
              uid = userCredential.user!.uid;
              success = true;
            } catch (authError) {
              retryCount++;
              if (retryCount >= maxRetries) {
                String errorMessage =
                    'Failed after $maxRetries attempts: ${authError.toString()}';
                if (authError is FirebaseAuthException) {
                  // Provide more specific error messages for common auth errors
                  switch (authError.code) {
                    case 'email-already-in-use':
                      errorMessage = 'Email is already in use';
                      break;
                    case 'invalid-email':
                      errorMessage = 'Email format is invalid';
                      break;
                    case 'weak-password':
                      errorMessage = 'Password is too weak';
                      break;
                    case 'operation-not-allowed':
                      errorMessage = 'Email/password accounts are not enabled';
                      break;
                    default:
                      errorMessage = 'Firebase Auth error: ${authError.code}';
                  }
                }
                throw Exception(errorMessage);
              }
              // Wait before retrying
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            }
          }
        }

        // Only proceed if we have a valid UID
        if (uid.isNotEmpty) {
          // Get the UID and add it to the student document
          student['uid'] = uid;
          student['accountCreatedAt'] = FieldValue.serverTimestamp();
          student['lastLoginAt'] = FieldValue.serverTimestamp();

          // Add to students collection
          final studentRef = studentsRef.doc(uid);
          batch.set(studentRef, student);

          // Also add to users collection with minimal data for authentication
          final userDoc = {
            'uid': uid,
            'email': student['email'],
            'displayName': student['displayName'],
            'role': 'student',
            'department': student['department'],
            'universityId': student['studentId'],
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'isActive': true,
            'passwordChanged': false,
            'profileImageUrl': student['profileImageUrl'] ?? '',
            'phoneNumber': student['mobileNumber'] ?? '',
          };

          batch.set(usersRef.doc(uid), userDoc);
          successCount++;
        }
      } catch (e) {
        failedImports.add('${student['studentId']} - ${e.toString()}');
      }
    }

    // Commit the batch only if there are successful imports
    if (successCount > 0) {
      try {
        await batch.commit();
      } catch (batchError) {
        // If batch commit fails, add it to the error report
        throw Exception(
            'Error committing data to Firestore: ${batchError.toString()}. $successCount accounts were created but data was not saved.');
      }
    }

    // Report results
    if (failedImports.isNotEmpty) {
      if (successCount == 0) {
        throw Exception(
            'All imports failed. Errors: ${failedImports.join('; ')}');
      } else {
        throw Exception(
            '${successCount} students imported successfully. ${failedImports.length} imports failed: ${failedImports.join('; ')}');
      }
    } else if (successCount == 0) {
      throw Exception(
          'No students were imported. Check your data and try again.');
    }

    return;
  }

  // Helper method to get value from row with appropriate column mapping
  String? _getValueFromRow(Map<String, dynamic> row, String fieldName) {
    // Check if we have a direct mapping
    if (_fieldMappings.containsKey(fieldName) &&
        _fieldMappings[fieldName]!.isNotEmpty &&
        row.containsKey(_fieldMappings[fieldName])) {
      return row[_fieldMappings[fieldName]]?.toString();
    }

    // Try to find by field name directly
    if (row.containsKey(fieldName)) {
      return row[fieldName]?.toString();
    }

    return null;
  }

  // Method to generate and download a template Excel file
  Future<void> _downloadTemplate() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create Excel object
      final excel = excel_lib.Excel.createExcel();

      // Create a worksheet
      final sheet = excel['AttendWise'];

      // Add headers based on import type
      if (_importType == 'students') {
        // Define headers - include all StudentModel fields with their exact field names
        final headers = [
          'studentId', // Required student ID
          'displayName', // Required full name
          'email', // Required college email
          'personalEmail', // Optional personal email
          'mobileNumber', // Optional mobile number
          'section', // Optional section
          'stream', // Optional stream
          'department', // Required department
          'specialization', // Optional specialization
          'batch', // Required batch/session
          'joiningYear', // Required joining year field
          'joiningSemester', // Optional joining semester field
          'passOutYear', // Required pass out year field
          'bloodGroup', // Optional blood group field
          'rank', // Optional rank field
          'examType', // Optional exam type field
          'category', // Optional category field
          'fatherName', // Optional father name
          'fatherMobile', // Optional father mobile
          'motherName', // Optional mother name
          'motherMobile', // Optional mother mobile
          'admissionDate', // Optional admission date
          'universityRollNo', // Optional university roll number
          'universityRegistrationNo', // Optional university registration number
          'lastQualification', // Optional last qualification
          'lastQualificationYear', // Optional last qualification passout year
          'aadharNo', // Optional Aadhar number
          'dob', // Optional date of birth
        ];

        // Add header row with styling
        for (var i = 0; i < headers.length; i++) {
          sheet
              .cell(excel_lib.CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: 0))
              .value = headers[i];
          sheet
              .cell(excel_lib.CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: 0))
              .cellStyle = excel_lib.CellStyle(
            bold: true,
            horizontalAlign: excel_lib.HorizontalAlign.Center,
            backgroundColorHex: 'FF90CAF9', // Light blue background
          );
        }

        // Add sample data for ease of use - ensure data aligns with header columns
        final sampleData = [
          // Row 1: Computer Science student
          {
            'studentId': 'CS001',
            'displayName': 'John Doe',
            'email': 'john.doe@college.edu',
            'personalEmail': 'johndoe@gmail.com',
            'mobileNumber': '9876543210',
            'section': 'A',
            'stream': 'Computer Science',
            'department': 'Computer Science',
            'specialization': 'Artificial Intelligence',
            'batch': '2023-2027',
            'joiningYear': '2023',
            'joiningSemester': 'Fall',
            'passOutYear': '2027',
            'bloodGroup': 'O+',
            'rank': '1',
            'examType': 'Regular',
            'category': 'General',
            'fatherName': 'Robert Doe',
            'fatherMobile': '9876543210',
            'motherName': 'Jane Doe',
            'motherMobile': '8765432109',
            'admissionDate': '2023-08-01',
            'universityRollNo': 'CS23001',
            'universityRegistrationNo': 'REG2023CS001',
            'lastQualification': 'B.Tech',
            'lastQualificationYear': '2023',
            'aadharNo': '123456789012',
            'dob': '2000-01-01',
          },

          // Row 2: Business student
          {
            'studentId': 'BBA002',
            'displayName': 'Jane Smith',
            'email': 'jane.smith@college.edu',
            'personalEmail': 'janesmith@outlook.com',
            'mobileNumber': '8765432109',
            'section': 'B',
            'stream': 'Business Administration',
            'department': 'Business Administration',
            'specialization': 'Marketing',
            'batch': '2023-2027',
            'joiningYear': '2023',
            'joiningSemester': 'Spring',
            'passOutYear': '2027',
            'bloodGroup': 'A+',
            'rank': '2',
            'examType': 'Regular',
            'category': 'General',
            'fatherName': 'John Smith',
            'fatherMobile': '8765432109',
            'motherName': 'Emily Smith',
            'motherMobile': '7654321098',
            'admissionDate': '2023-08-01',
            'universityRollNo': 'BBA23002',
            'universityRegistrationNo': 'REG2023BBA002',
            'lastQualification': 'MBA',
            'lastQualificationYear': '2023',
            'aadharNo': '987654321098',
            'dob': '1999-12-31',
          },

          // Row 3: Engineering student
          {
            'studentId': 'EE003',
            'displayName': 'Alex Johnson',
            'email': 'alex.johnson@college.edu',
            'personalEmail': 'alexj@yahoo.com',
            'mobileNumber': '7654321098',
            'section': 'C',
            'stream': 'Electrical Engineering',
            'department': 'Electrical Engineering',
            'specialization': 'Power Systems',
            'batch': '2022-2026',
            'joiningYear': '2022',
            'joiningSemester': 'Fall',
            'passOutYear': '2026',
            'bloodGroup': 'B+',
            'rank': '3',
            'examType': 'Regular',
            'category': 'General',
            'fatherName': 'Michael Johnson',
            'fatherMobile': '7654321098',
            'motherName': 'Sarah Johnson',
            'motherMobile': '6543210987',
            'admissionDate': '2022-08-01',
            'universityRollNo': 'EE22003',
            'universityRegistrationNo': 'REG2022EE003',
            'lastQualification': 'Diploma',
            'lastQualificationYear': '2022',
            'aadharNo': '456789012345',
            'dob': '2001-05-15',
          }
        ];

        // Add sample data with proper alignment to headers
        final rowColors = ['FFF3F3F3', 'FFFFFFFF']; // Light gray, white

        for (var i = 0; i < sampleData.length; i++) {
          final rowData = sampleData[i];
          final rowColor = rowColors[i % rowColors.length];

          for (var j = 0; j < headers.length; j++) {
            final headerName = headers[j];
            final cellValue = rowData[headerName] ?? '';

            final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: j, rowIndex: i + 1));
            cell.value = cellValue;
            cell.cellStyle = excel_lib.CellStyle(
              horizontalAlign: excel_lib.HorizontalAlign.Left,
              backgroundColorHex: rowColor,
            );
          }
        }

        // Add note below sample data
        final noteRowIndex = sampleData.length + 2;
        final noteCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: noteRowIndex));
        noteCell.value =
            "Note: This is sample data. Please replace with your actual student data before importing.";
        noteCell.cellStyle = excel_lib.CellStyle(
          italic: true,
          fontColorHex: "FF666666",
        );

        // Merge cells for the note
        sheet.merge(
            excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: noteRowIndex),
            excel_lib.CellIndex.indexByColumnRow(
                columnIndex: headers.length - 1, rowIndex: noteRowIndex));

        // Add required field note
        final requiredNoteRowIndex = noteRowIndex + 1;
        final requiredCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: requiredNoteRowIndex));
        requiredCell.value =
            "Required fields: studentId, displayName, email, department, batch, joiningYear, passOutYear";
        requiredCell.cellStyle = excel_lib.CellStyle(
          bold: true,
          fontColorHex: "FFE65100", // Orange text for emphasis
        );

        // Merge cells for the required fields note
        sheet.merge(
            excel_lib.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: requiredNoteRowIndex),
            excel_lib.CellIndex.indexByColumnRow(
                columnIndex: headers.length - 1,
                rowIndex: requiredNoteRowIndex));

        // Set column widths for better readability
        for (var i = 0; i < headers.length; i++) {
          sheet.setColWidth(i, 20.0);
        }
      } else if (_importType == 'teachers') {
        // Teacher template headers
        final headers = [
          'teacherId',
          'displayName',
          'email',
          'personalEmail',
          'mobileNumber',
          'department',
          'designation',
          'specialization'
        ];

        // Add headers to Excel with styling
        for (var i = 0; i < headers.length; i++) {
          sheet
              .cell(excel_lib.CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: 0))
              .value = headers[i];
          sheet
              .cell(excel_lib.CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: 0))
              .cellStyle = excel_lib.CellStyle(
            bold: true,
            horizontalAlign: excel_lib.HorizontalAlign.Center,
            backgroundColorHex: 'FF90CAF9', // Light blue background
          );
        }

        // Add sample teacher data
        final sampleTeachers = [
          {
            'teacherId': 'PROF001',
            'displayName': 'Dr. Robert Brown',
            'email': 'robert.brown@college.edu',
            'personalEmail': 'rbrown@gmail.com',
            'mobileNumber': '9876543210',
            'department': 'Computer Science',
            'designation': 'Professor',
            'specialization': 'Machine Learning'
          },
          {
            'teacherId': 'ASST002',
            'displayName': 'Emily White',
            'email': 'emily.white@college.edu',
            'personalEmail': 'emilywhite@outlook.com',
            'mobileNumber': '8765432109',
            'department': 'Business Administration',
            'designation': 'Assistant Professor',
            'specialization': 'Finance'
          }
        ];

        // Add sample teacher data
        for (var i = 0; i < sampleTeachers.length; i++) {
          final rowData = sampleTeachers[i];
          for (var j = 0; j < headers.length; j++) {
            final headerName = headers[j];
            final cellValue = rowData[headerName] ?? '';

            sheet
                .cell(excel_lib.CellIndex.indexByColumnRow(
                    columnIndex: j, rowIndex: i + 1))
                .value = cellValue;
          }
        }
      } else if (_importType == 'classes') {
        // Classes template headers
        final headers = [
          'classId',
          'className',
          'teacherId',
          'schedule',
          'room',
          'semester',
          'department',
          'batch'
        ];

        // Add headers to Excel with styling
        for (var i = 0; i < headers.length; i++) {
          sheet
              .cell(excel_lib.CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: 0))
              .value = headers[i];
          sheet
              .cell(excel_lib.CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: 0))
              .cellStyle = excel_lib.CellStyle(
            bold: true,
            horizontalAlign: excel_lib.HorizontalAlign.Center,
            backgroundColorHex: 'FF90CAF9', // Light blue background
          );
        }

        // Add sample class data
        final sampleClasses = [
          {
            'classId': 'CS101',
            'className': 'Introduction to Programming',
            'teacherId': 'PROF001',
            'schedule': 'Monday 9:00-11:00, Wednesday 10:00-12:00',
            'room': 'Room 101',
            'semester': '1',
            'department': 'Computer Science',
            'batch': '2023-2027'
          },
          {
            'classId': 'BBA205',
            'className': 'Marketing Management',
            'teacherId': 'ASST002',
            'schedule': 'Tuesday 14:00-16:00, Thursday 15:00-17:00',
            'room': 'Room 205',
            'semester': '3',
            'department': 'Business Administration',
            'batch': '2022-2026'
          }
        ];

        // Add sample class data
        for (var i = 0; i < sampleClasses.length; i++) {
          final rowData = sampleClasses[i];
          for (var j = 0; j < headers.length; j++) {
            final headerName = headers[j];
            final cellValue = rowData[headerName] ?? '';

            sheet
                .cell(excel_lib.CellIndex.indexByColumnRow(
                    columnIndex: j, rowIndex: i + 1))
                .value = cellValue;
          }
        }
      }

      // Generate bytes for download
      final bytes = excel.save();

      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Use our platform-specific file handling utility
      await saveAndOpenFile(
          Uint8List.fromList(bytes), '${_importType}_template.xlsx');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template downloaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating template: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper widget to build field mapping dropdowns
  Widget _buildFieldMapping(String fieldName, String displayName) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(displayName, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing12,
                vertical: AppDimensions.spacing8,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
            ),
            value: _fieldMappings[fieldName]!.isEmpty
                ? null
                : _fieldMappings[fieldName],
            hint: const Text('Select column'),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Not used'),
              ),
              ..._headers
                  .map((header) => DropdownMenuItem<String>(
                        value: header,
                        child: Text(header, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
            ],
            onChanged: (String? value) {
              setState(() {
                _fieldMappings[fieldName] = value ?? '';
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height *
              0.8, // Limit max height to 80% of screen
        ),
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import Data',
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: AppDimensions.spacing16),
              Text(
                'Import student, teacher, or class data from CSV or Excel files',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: AppDimensions.spacing24),

              // Data type selection
              Text(
                'Select data type:',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: AppDimensions.spacing8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'students',
                    label: Text('Students'),
                    icon: Icon(Icons.school),
                  ),
                  ButtonSegment(
                    value: 'teachers',
                    label: Text('Teachers'),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: 'classes',
                    label: Text('Classes'),
                    icon: Icon(Icons.class_),
                  ),
                ],
                selected: {_importType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _importType = newSelection.first;
                    // Reset field mappings when changing import type
                    _fieldMappings.forEach((key, value) {
                      _fieldMappings[key] = '';
                    });
                    // Remap fields based on new type
                    _autoMapFields();
                  });
                },
              ),
              SizedBox(height: AppDimensions.spacing24),

              // Make the rest of the content scrollable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File selection area
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color:
                                  theme.colorScheme.outline.withOpacity(0.5)),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.borderRadius),
                        ),
                        child: _selectedFilePath == null &&
                                _selectedFileBytes == null
                            ? InkWell(
                                onTap: _pickFile,
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(AppDimensions.spacing24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        size: 48,
                                        color: theme.colorScheme.primary,
                                      ),
                                      SizedBox(height: AppDimensions.spacing16),
                                      Text(
                                        'Click to select a file',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      SizedBox(height: AppDimensions.spacing8),
                                      Text(
                                        'Supported formats: .csv, .xlsx, .xls',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Padding(
                                padding:
                                    EdgeInsets.all(AppDimensions.spacing16),
                                child: Row(
                                  children: [
                                    Icon(
                                      _fileName.endsWith('.csv')
                                          ? Icons.insert_drive_file
                                          : Icons.table_chart,
                                      color: theme.colorScheme.primary,
                                    ),
                                    SizedBox(width: AppDimensions.spacing16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _fileName,
                                            style: theme.textTheme.titleMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (_csvData != null)
                                            Text(
                                              '${_csvData!.length - 1} rows found',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed:
                                          _fileName.isEmpty ? null : _pickFile,
                                      tooltip: 'Select a different file',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () {
                                        setState(() {
                                          _selectedFilePath = null;
                                          _selectedFileBytes = null;
                                          _fileName = '';
                                          _csvData = null;
                                          _excelData = null;
                                          _headers = [];
                                          _fieldMappings.forEach((key, value) {
                                            _fieldMappings[key] = '';
                                          });
                                        });
                                      },
                                      tooltip: 'Remove file',
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      SizedBox(height: AppDimensions.spacing16),

                      // Field mapping section - show only when file is selected and data type is students
                      if (_headers.isNotEmpty && _importType == 'students') ...[
                        ExpansionPanelList(
                          expansionCallback: (int index, bool isExpanded) {
                            setState(() {
                              _isFieldMappingExpanded =
                                  !_isFieldMappingExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              isExpanded: _isFieldMappingExpanded,
                              headerBuilder:
                                  (BuildContext context, bool isExpanded) {
                                return ListTile(
                                  title: Text(
                                    'Map Fields:',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                );
                              },
                              body: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.borderRadius),
                                ),
                                padding:
                                    EdgeInsets.all(AppDimensions.spacing16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Field',
                                            style: theme.textTheme.titleSmall,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            'Column in File',
                                            style: theme.textTheme.titleSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: AppDimensions.spacing12),
                                    _buildFieldMapping(
                                        'studentId', 'Student ID*'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('name', 'Name*'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'email', 'College E-mail*'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'personalEmail', 'Student Email Id'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'mobileNumber', 'Mobile'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('section', 'Section'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('stream', 'Stream'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'department', 'Department*'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'specialization', 'Specialization'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('batch', 'Batch*'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'joiningYear', 'Joining Year*'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'joiningSemester', 'Joining Semester'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'passOutYear', 'Pass Out Year*'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'bloodGroup', 'Blood Group'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('rank', 'Rank'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('examType', 'Exam Type'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('category', 'Category'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'fatherName', 'Father Name'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'fatherMobile', 'Father Mobile'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'motherName', 'Mother Name'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'motherMobile', 'Mother Mobile'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'admissionDate', 'Admission Date'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('universityRollNo',
                                        'University Roll No'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping(
                                        'universityRegistrationNo',
                                        'University Registration No'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('lastQualification',
                                        'Last Qualification'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('lastQualificationYear',
                                        'Last Qualification Passout Year'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('aadharNo', 'Aadhar No'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    _buildFieldMapping('dob', 'Date of Birth'),
                                    SizedBox(height: AppDimensions.spacing8),
                                    Text(
                                      '* Required fields',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Preview section
                      if (_csvData != null && _csvData!.isNotEmpty) ...[
                        SizedBox(height: AppDimensions.spacing16),
                        ExpansionPanelList(
                          expansionCallback: (int index, bool isExpanded) {
                            setState(() {
                              _isPreviewExpanded = !_isPreviewExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              isExpanded: _isPreviewExpanded,
                              headerBuilder:
                                  (BuildContext context, bool isExpanded) {
                                return ListTile(
                                  title: Text(
                                    'Preview:',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                );
                              },
                              body: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.borderRadius),
                                ),
                                // Set a reasonable maximum height but allow content to be smaller
                                constraints: BoxConstraints(maxHeight: 200),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: _csvData![0]
                                          .map((header) => DataColumn(
                                                label: Text(
                                                  header.toString(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ))
                                          .toList(),
                                      rows: _csvData!
                                          .skip(1)
                                          .take(5)
                                          .map(
                                            (row) => DataRow(
                                              cells: row
                                                  .map((cell) => DataCell(
                                                      Text(cell.toString())))
                                                  .toList(),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_csvData!.length > 6)
                          Padding(
                            padding:
                                EdgeInsets.only(top: AppDimensions.spacing8),
                            child: Text(
                              'Showing 5 of ${_csvData!.length - 1} rows',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],

                      SizedBox(height: AppDimensions.spacing24),

                      // Template download option
                      Row(
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: AppDimensions.spacing8),
                          Text(
                            'Need a template?',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _downloadTemplate,
                            child: const Text('Download template'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppDimensions.spacing24),

              // Action buttons always visible at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: AppDimensions.spacing16),
                  FilledButton(
                    onPressed: _isLoading ? null : _importData,
                    child: _isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                              SizedBox(width: AppDimensions.spacing8),
                              const Text('Importing...'),
                            ],
                          )
                        : const Text('Import Data'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
