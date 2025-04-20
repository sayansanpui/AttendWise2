import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib; // Added for Excel processing
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/dimensions.dart';

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

  // Added to keep track of field mappings for Excel/CSV
  final Map<String, String> _fieldMappings = {
    'studentId': '',
    'name': '',
    'email': '',
    'phone': '',
    'department': '',
    'year': '',
    'section': '',
    'rollNo': '',
  };

  // Keep track of selected columns from the first row of data
  List<String> _headers = [];

  Future<void> _pickFile() async {
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
          (lowerHeader.contains('id') ||
              lowerHeader.contains('student id') ||
              lowerHeader.contains('studentid'))) {
        _fieldMappings['studentId'] = header;
      }

      // Map name
      else if (_fieldMappings['name']!.isEmpty &&
          (lowerHeader.contains('name') ||
              lowerHeader.contains('student name'))) {
        _fieldMappings['name'] = header;
      }

      // Map email
      else if (_fieldMappings['email']!.isEmpty &&
          lowerHeader.contains('email')) {
        _fieldMappings['email'] = header;
      }

      // Map phone
      else if (_fieldMappings['phone']!.isEmpty &&
          (lowerHeader.contains('phone') || lowerHeader.contains('mobile'))) {
        _fieldMappings['phone'] = header;
      }

      // Map department
      else if (_fieldMappings['department']!.isEmpty &&
          (lowerHeader.contains('dept') ||
              lowerHeader.contains('department'))) {
        _fieldMappings['department'] = header;
      }

      // Map year
      else if (_fieldMappings['year']!.isEmpty &&
          lowerHeader.contains('year')) {
        _fieldMappings['year'] = header;
      }

      // Map section
      else if (_fieldMappings['section']!.isEmpty &&
          lowerHeader.contains('section')) {
        _fieldMappings['section'] = header;
      }

      // Map roll number
      else if (_fieldMappings['rollNo']!.isEmpty &&
          (lowerHeader.contains('roll') || lowerHeader.contains('roll no'))) {
        _fieldMappings['rollNo'] = header;
      }
    }
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

    // Check if student ID and name fields are mapped for students
    if (_importType == 'students') {
      if (_fieldMappings['studentId']!.isEmpty ||
          _fieldMappings['name']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student ID and Name fields must be mapped'),
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

  // New method to handle student import specifically
  Future<void> _importStudents() async {
    List<Map<String, dynamic>> studentsToImport = [];

    // Determine the data source
    if (_excelData != null) {
      // Use Excel data if available
      for (var row in _excelData!) {
        // Skip rows that don't have the required fields
        if (!row.containsKey(_fieldMappings['studentId']) ||
            !row.containsKey(_fieldMappings['name'])) {
          continue;
        }

        // Map fields from Excel to student document structure
        Map<String, dynamic> student = {
          'studentId': row[_fieldMappings['studentId']],
          'name': row[_fieldMappings['name']],
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add optional fields if they exist
        for (String field in [
          'email',
          'phone',
          'department',
          'year',
          'section',
          'rollNo'
        ]) {
          if (_fieldMappings[field]!.isNotEmpty &&
              row.containsKey(_fieldMappings[field])) {
            student[field] = row[_fieldMappings[field]];
          }
        }

        studentsToImport.add(student);
      }
    } else if (_csvData != null && _csvData!.length > 1) {
      // Use CSV data as fallback
      final headerRow = _csvData![0];

      // Find indexes of required fields
      int studentIdIndex = -1;
      int nameIndex = -1;

      // Map other fields
      Map<String, int> fieldIndexes = {};

      for (int i = 0; i < headerRow.length; i++) {
        String header = headerRow[i].toString();

        if (header == _fieldMappings['studentId']) {
          studentIdIndex = i;
        } else if (header == _fieldMappings['name']) {
          nameIndex = i;
        }

        // Map other field indexes
        for (String field in [
          'email',
          'phone',
          'department',
          'year',
          'section',
          'rollNo'
        ]) {
          if (header == _fieldMappings[field]) {
            fieldIndexes[field] = i;
          }
        }
      }

      // Ensure required fields are found
      if (studentIdIndex == -1 || nameIndex == -1) {
        throw Exception('Student ID or Name column not found in data');
      }

      // Process each row
      for (int i = 1; i < _csvData!.length; i++) {
        final row = _csvData![i];

        // Skip invalid rows
        if (row.length <= studentIdIndex || row.length <= nameIndex) {
          continue;
        }

        // Create student document
        Map<String, dynamic> student = {
          'studentId': row[studentIdIndex].toString(),
          'name': row[nameIndex].toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add optional fields
        fieldIndexes.forEach((field, index) {
          if (index < row.length && row[index] != null) {
            student[field] = row[index].toString();
          }
        });

        studentsToImport.add(student);
      }
    }

    if (studentsToImport.isEmpty) {
      throw Exception('No valid student data found to import');
    }

    // Use Firestore batch for efficient writing
    final batch = FirebaseFirestore.instance.batch();
    final studentsRef = FirebaseFirestore.instance.collection('students');

    // Add each student to the batch
    for (var student in studentsToImport) {
      // Use studentId as the document ID
      final docRef = studentsRef.doc(student['studentId'].toString());
      batch.set(docRef, student, SetOptions(merge: true));
    }

    // Commit the batch
    await batch.commit();

    // Return the count of imported students
    return;
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
      child: Container(
        width: 600,
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

            // File selection area
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              child: _selectedFilePath == null && _selectedFileBytes == null
                  ? InkWell(
                      onTap: _pickFile,
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.spacing24),
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
                      padding: EdgeInsets.all(AppDimensions.spacing16),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                            onPressed: _fileName.isEmpty ? null : _pickFile,
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
              Text(
                'Map Fields:',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: AppDimensions.spacing8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2)),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                padding: EdgeInsets.all(AppDimensions.spacing16),
                child: Column(
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
                    _buildFieldMapping('studentId', 'Student ID*'),
                    SizedBox(height: AppDimensions.spacing8),
                    _buildFieldMapping('name', 'Name*'),
                    SizedBox(height: AppDimensions.spacing8),
                    _buildFieldMapping('email', 'Email'),
                    SizedBox(height: AppDimensions.spacing8),
                    _buildFieldMapping('phone', 'Phone'),
                    SizedBox(height: AppDimensions.spacing8),
                    _buildFieldMapping('department', 'Department'),
                    SizedBox(height: AppDimensions.spacing8),
                    _buildFieldMapping('year', 'Year'),
                    SizedBox(height: AppDimensions.spacing8),
                    _buildFieldMapping('section', 'Section'),
                    SizedBox(height: AppDimensions.spacing8),
                    _buildFieldMapping('rollNo', 'Roll Number'),
                    SizedBox(height: AppDimensions.spacing8),
                    Text(
                      '* Required fields',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Preview section
            if (_csvData != null && _csvData!.isNotEmpty) ...[
              SizedBox(height: AppDimensions.spacing16),
              Text(
                'Preview:',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: AppDimensions.spacing8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2)),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                ),
                height: 200,
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
                                      fontWeight: FontWeight.bold),
                                ),
                              ))
                          .toList(),
                      rows: _csvData!
                          .skip(1)
                          .take(5)
                          .map(
                            (row) => DataRow(
                              cells: row
                                  .map(
                                      (cell) => DataCell(Text(cell.toString())))
                                  .toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              if (_csvData!.length > 6)
                Padding(
                  padding: EdgeInsets.only(top: AppDimensions.spacing8),
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
                  onPressed: () {
                    // TODO: Implement template download functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Template download initiated'),
                      ),
                    );
                  },
                  child: const Text('Download template'),
                ),
              ],
            ),

            SizedBox(height: AppDimensions.spacing24),

            // Action buttons
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
    );
  }
}
