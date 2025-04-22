import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io'; // Added for File class
import 'dart:typed_data'; // Add for Uint8List
import 'package:flutter/foundation.dart'
    show kIsWeb; // Add to detect web platform
import 'package:permission_handler/permission_handler.dart'; // Added for runtime permissions
import 'package:http/http.dart' as http; // Added for HTTP requests
import 'package:path_provider/path_provider.dart'; // Added for temporary directory
import 'package:device_info_plus/device_info_plus.dart'; // Added for device info

import '../../../config/theme/app_theme.dart';
import '../../../config/theme/dimensions.dart'; // Added for AppDimensions
import '../../../config/theme/color_schemes.dart'; // Added for AppColorScheme
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/utils/date_time_helper.dart';
import '../../shared/widgets/loading_button.dart'; // Added for LoadingButton
import '../../shared/widgets/empty_state.dart'; // Added for EmptyState
// Platform-specific utilities
import '../../admin/widgets/web_utils.dart'
    if (dart.library.io) '../../admin/widgets/mobile_utils.dart';

/// Screen for managing classroom materials and assignments
class ClassroomMaterialsScreen extends ConsumerStatefulWidget {
  /// ID of the classroom
  final String classroomId;

  const ClassroomMaterialsScreen({
    super.key,
    required this.classroomId,
  });

  @override
  ConsumerState<ClassroomMaterialsScreen> createState() =>
      _ClassroomMaterialsScreenState();
}

class _ClassroomMaterialsScreenState
    extends ConsumerState<ClassroomMaterialsScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic>? _classroom;
  List<Map<String, dynamic>> _materials = [];

  // For new material form
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Study Material';
  DateTime? _dueDate;
  File? _selectedFile;
  Uint8List? _selectedFileBytes; // Add for web support
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadClassroomData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClassroomData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get classroom details
      final classroomDoc = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroomId)
          .get();

      if (!classroomDoc.exists) {
        throw Exception('Classroom not found');
      }

      // Get classroom materials
      final materialsSnapshot = await FirebaseFirestore.instance
          .collection('classroom_materials')
          .where('classroomId', isEqualTo: widget.classroomId)
          .orderBy('createdAt', descending: true)
          .get();

      final materials = materialsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _classroom = {
            'id': classroomDoc.id,
            ...classroomDoc.data()!,
          };
          _materials = materials;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load classroom data: ${e.toString()}'),
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
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;

          // Handle web platform differently
          if (kIsWeb) {
            // For web, use bytes
            _selectedFileBytes = result.files.single.bytes;
            _selectedFile = null;
          } else {
            // For mobile/desktop, use path
            if (result.files.single.path != null) {
              _selectedFile = File(result.files.single.path!);
            }
            _selectedFileBytes = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadMaterial() async {
    // Validate form
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedType == 'Assignment' && _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date for the assignment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Get current teacher ID
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) {
        throw Exception('User not authenticated');
      }

      String? fileUrl;

      // Upload file if selected
      if (_selectedFile != null || _selectedFileBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('classroom_materials')
            .child(widget.classroomId)
            .child(
                '${DateTime.now().millisecondsSinceEpoch}_${_selectedFileName}');

        UploadTask uploadTask;
        if (kIsWeb && _selectedFileBytes != null) {
          // For web, upload bytes
          uploadTask = storageRef.putData(_selectedFileBytes!);
        } else if (_selectedFile != null) {
          // For mobile/desktop, upload file
          uploadTask = storageRef.putFile(_selectedFile!);
        } else {
          throw Exception('No file selected');
        }

        final snapshot = await uploadTask.whenComplete(() {});
        fileUrl = await snapshot.ref.getDownloadURL();
      }

      // Create material document
      final material = {
        'classroomId': widget.classroomId,
        'teacherId': teacherId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'dueDate': _selectedType == 'Assignment' ? _dueDate : null,
        'fileUrl': fileUrl,
        'fileName': _selectedFileName,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('classroom_materials')
          .add(material);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedType = 'Study Material';
          _dueDate = null;
          _selectedFile = null;
          _selectedFileBytes = null;
          _selectedFileName = null;
        });

        // Reload materials
        _loadClassroomData();

        // Close bottom sheet
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload material: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteMaterial(String materialId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text(
          'Are you sure you want to delete this material? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete material from Firestore
      await FirebaseFirestore.instance
          .collection('classroom_materials')
          .doc(materialId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload materials
        _loadClassroomData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete material: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadStudentDataFromExcel() async {
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
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null) {
        // User canceled the picker
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Process the Excel file
      List<Map<String, dynamic>> studentData = [];

      if (kIsWeb) {
        // For web platform
        if (result.files.single.bytes != null) {
          final bytes = result.files.single.bytes!;
          final excel = excel_lib.Excel.decodeBytes(bytes);
          studentData = _extractStudentDataFromExcel(excel);
        }
      } else {
        // For mobile/desktop platforms
        if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final bytes = await file.readAsBytes();
          final excel = excel_lib.Excel.decodeBytes(bytes);
          studentData = _extractStudentDataFromExcel(excel);
        }
      }

      if (studentData.isEmpty) {
        throw Exception('No valid student data found in the Excel file');
      }

      // Store student data in Firestore
      final batch = FirebaseFirestore.instance.batch();
      final studentsRef = FirebaseFirestore.instance.collection('students');

      // Also update classroom's student list
      final classroomRef = FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroomId);

      // Get current student IDs in the classroom
      final classroomDoc = await classroomRef.get();
      final List<String> existingStudentIds =
          (classroomDoc.data()?['studentIds'] as List<dynamic>? ?? [])
              .cast<String>();
      final Set<String> updatedStudentIds =
          Set<String>.from(existingStudentIds);

      // Process each student
      for (final student in studentData) {
        // Check if required fields exist
        if (student['studentId'] == null || student['name'] == null) {
          continue;
        }

        final studentId = student['studentId'].toString();

        // Create or update student document
        final docRef = studentsRef.doc(studentId);
        batch.set(
            docRef,
            {
              'name': student['name'],
              'email': student['email'] ?? '',
              'phone': student['phone'] ?? '',
              'department': student['department'] ?? '',
              'year': student['year'] ?? '',
              'section': student['section'] ?? '',
              'rollNo': student['rollNo'] ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        // Add student to classroom
        updatedStudentIds.add(studentId);
      }

      // Update classroom with new student list
      batch.update(classroomRef, {
        'studentIds': updatedStudentIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully imported ${studentData.length} students'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import student data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _extractStudentDataFromExcel(
      excel_lib.Excel excel) {
    List<Map<String, dynamic>> students = [];

    // Process the first sheet (or specified sheet)
    if (excel.tables.isNotEmpty) {
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        return students;
      }

      // Extract header row (first row)
      final List<String> headers = [];
      for (var cell in sheet.rows[0]) {
        headers.add(cell?.value.toString() ?? '');
      }

      // Find the indexes of required columns
      int? studentIdIndex = headers.indexOf('Student ID');
      int? nameIndex = headers.indexOf('Name');

      if (studentIdIndex == -1 || nameIndex == -1) {
        // Try to infer column positions if not found by exact name
        for (int i = 0; i < headers.length; i++) {
          final header = headers[i].toLowerCase();
          if (studentIdIndex == -1 &&
              (header.contains('id') || header.contains('number'))) {
            studentIdIndex = i;
          }
          if (nameIndex == -1 && header.contains('name')) {
            nameIndex = i;
          }
        }
      }

      // If we still can't find required columns, return empty list
      if (studentIdIndex == -1 || nameIndex == -1) {
        return students;
      }

      // Map other potential columns
      final emailIndex =
          headers.indexWhere((h) => h.toLowerCase().contains('email'));
      final phoneIndex =
          headers.indexWhere((h) => h.toLowerCase().contains('phone'));
      final deptIndex = headers.indexWhere((h) =>
          h.toLowerCase().contains('dept') ||
          h.toLowerCase().contains('department'));
      final yearIndex =
          headers.indexWhere((h) => h.toLowerCase().contains('year'));
      final sectionIndex =
          headers.indexWhere((h) => h.toLowerCase().contains('section'));
      final rollNoIndex = headers.indexWhere((h) =>
          h.toLowerCase().contains('roll') || h.toLowerCase().contains('no'));

      // Process data rows (skip header row)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty ||
            row.length <= studentIdIndex! ||
            row.length <= nameIndex!) {
          continue;
        }

        final studentId = row[studentIdIndex]?.value.toString() ?? '';
        final name = row[nameIndex]?.value.toString() ?? '';

        // Skip if essential data is missing
        if (studentId.isEmpty || name.isEmpty) {
          continue;
        }

        // Create student record
        final student = <String, dynamic>{
          'studentId': studentId,
          'name': name,
        };

        // Add optional fields if they exist
        if (emailIndex >= 0 &&
            row.length > emailIndex &&
            row[emailIndex] != null) {
          student['email'] = row[emailIndex]!.value.toString();
        }

        if (phoneIndex >= 0 &&
            row.length > phoneIndex &&
            row[phoneIndex] != null) {
          student['phone'] = row[phoneIndex]!.value.toString();
        }

        if (deptIndex >= 0 &&
            row.length > deptIndex &&
            row[deptIndex] != null) {
          student['department'] = row[deptIndex]!.value.toString();
        }

        if (yearIndex >= 0 &&
            row.length > yearIndex &&
            row[yearIndex] != null) {
          student['year'] = row[yearIndex]!.value.toString();
        }

        if (sectionIndex >= 0 &&
            row.length > sectionIndex &&
            row[sectionIndex] != null) {
          student['section'] = row[sectionIndex]!.value.toString();
        }

        if (rollNoIndex >= 0 &&
            row.length > rollNoIndex &&
            row[rollNoIndex] != null) {
          student['rollNo'] = row[rollNoIndex]!.value.toString();
        }

        students.add(student);
      }
    }

    return students;
  }

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

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    // For Android, check permissions first
    if (!kIsWeb) {
      bool hasPermission = await _checkPermissions();
      if (!hasPermission) {
        return;
      }
    }

    try {
      if (kIsWeb) {
        // For web platform, use anchor element for download
        final anchorElement = createAnchorElement(href: fileUrl);
        anchorElement.setAttribute('download', fileName);
        anchorElement.click();
      } else {
        // Show downloading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading $fileName...')),
        );

        // Get temp directory for saving file
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);

        // Download the file using HTTP
        final response = await http.get(Uri.parse(fileUrl));
        await file.writeAsBytes(response.bodyBytes);

        // Open the file
        await OpenFile.open(filePath);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded $fileName successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddMaterialBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
      builder: (context) => _buildAddMaterialForm(),
    );
  }

  Widget _buildAddMaterialForm() {
    final theme = Theme.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.spacing16,
            right: AppDimensions.spacing16,
            top: AppDimensions.spacing16,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                AppDimensions.spacing16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New Material',
                      style: theme.textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.spacing16),

                // Title field
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter a title for the material',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMedium),
                    ),
                  ),
                ),
                SizedBox(height: AppDimensions.spacing16),

                // Description field
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter a description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMedium),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: AppDimensions.spacing16),

                // Material type
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMedium),
                    ),
                  ),
                  value: _selectedType,
                  items: ['Study Material', 'Assignment', 'Announcement']
                      .map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    }
                  },
                ),
                SizedBox(height: AppDimensions.spacing16),

                // Due date (for assignments)
                if (_selectedType == 'Assignment')
                  InkWell(
                    onTap: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ??
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );

                      if (newDate != null) {
                        setState(() {
                          _dueDate = newDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusMedium),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dueDate != null
                            ? DateTimeHelper.formatDate(_dueDate!)
                            : 'Select a due date',
                      ),
                    ),
                  ),

                if (_selectedType == 'Assignment')
                  SizedBox(height: AppDimensions.spacing16),

                // File upload section
                Text(
                  'Attachment (Optional)',
                  style: theme.textTheme.titleSmall,
                ),
                SizedBox(height: AppDimensions.spacing8),
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    padding: EdgeInsets.all(AppDimensions.spacing16),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMedium),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedFile != null || _selectedFileBytes != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: _selectedFile != null ||
                                  _selectedFileBytes != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: AppDimensions.spacing16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName ?? 'Select a file to upload',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _selectedFile != null ||
                                          _selectedFileBytes != null
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: _selectedFile != null ||
                                          _selectedFileBytes != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedFile != null ||
                                  _selectedFileBytes != null) ...[
                                SizedBox(height: AppDimensions.spacing4),
                                Text(
                                  'Click to change file',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppDimensions.spacing24),

                // Submit button
                LoadingButton(
                  isLoading: _isUploading,
                  onPressed: _uploadMaterial,
                  text: 'Upload Material',
                  loadingText: 'Uploading...',
                  icon: Icons.cloud_upload,
                ),
                SizedBox(height: AppDimensions.spacing16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_classroom != null
            ? '${_classroom!['code']} Materials'
            : 'Classroom Materials'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _uploadStudentDataFromExcel,
            tooltip: 'Import Students from Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClassroomData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _materials.isEmpty
              ? EmptyState(
                  icon: Icons.folder_open,
                  title: 'No Materials Yet',
                  description:
                      'Start by adding study materials or assignments for your students',
                  actionButtonText: 'Add Material',
                  onActionButtonPressed: _showAddMaterialBottomSheet,
                )
              : RefreshIndicator(
                  onRefresh: _loadClassroomData,
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppDimensions.spacing16),
                    itemCount: _materials.length,
                    itemBuilder: (context, index) {
                      final material = _materials[index];
                      return _buildMaterialCard(material);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMaterialBottomSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Material'),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final theme = Theme.of(context);

    final title = material['title'] ?? 'Untitled';
    final description = material['description'] ?? '';
    final type = material['type'] ?? 'Study Material';
    final fileName = material['fileName'];
    final fileUrl = material['fileUrl'];

    final timestamp = (material['createdAt'] as Timestamp?)?.toDate();
    final dateString = timestamp != null
        ? DateTimeHelper.formatDate(timestamp)
        : 'Unknown date';

    final dueDate = (material['dueDate'] as Timestamp?)?.toDate();
    final dueDateString =
        dueDate != null ? DateTimeHelper.formatDate(dueDate) : null;

    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'Assignment':
        typeColor = Colors.orange;
        typeIcon = Icons.assignment;
        break;
      case 'Announcement':
        typeColor = Colors.blue;
        typeIcon = Icons.announcement;
        break;
      default: // Study Material
        typeColor = Colors.green;
        typeIcon = Icons.book;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppDimensions.spacing8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusMedium),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacing4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          SizedBox(width: AppDimensions.spacing4),
                          Text(
                            'Posted on $dateString',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteMaterial(material['id']),
                  tooltip: 'Delete',
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: AppDimensions.spacing12),
              Text(description),
            ],
            if (dueDateString != null) ...[
              SizedBox(height: AppDimensions.spacing12),
              Row(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(width: AppDimensions.spacing4),
                  Text(
                    'Due on $dueDateString',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
            if (fileName != null && fileUrl != null) ...[
              SizedBox(height: AppDimensions.spacing12),
              Container(
                padding: EdgeInsets.all(AppDimensions.spacing12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attachment,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: AppDimensions.spacing8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadFile(fileUrl, fileName),
                      tooltip: 'Download',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppDimensions.spacing12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Chip(
                  label: Text(type),
                  backgroundColor: typeColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
