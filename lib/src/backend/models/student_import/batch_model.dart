import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a student batch/session in the institution
class BatchModel {
  final String batchId; // Batch ID (e.g., 2022-2026)
  final int startYear; // Start year (e.g., 2022)
  final int endYear; // End year (e.g., 2026)
  final int currentSemester; // Current semester for this batch
  final int currentYear; // Current year for this batch
  final List<String> departments; // Array of departments in this batch
  final bool isActive; // Whether batch is active
  final Timestamp createdAt; // Creation timestamp
  final Timestamp updatedAt; // Last update timestamp

  BatchModel({
    required this.batchId,
    required this.startYear,
    required this.endYear,
    required this.currentSemester,
    required this.currentYear,
    required this.departments,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      batchId: json['batchId'] as String,
      startYear: json['startYear'] as int,
      endYear: json['endYear'] as int,
      currentSemester: json['currentSemester'] as int,
      currentYear: json['currentYear'] as int,
      departments: List<String>.from(json['departments'] as List),
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'startYear': startYear,
      'endYear': endYear,
      'currentSemester': currentSemester,
      'currentYear': currentYear,
      'departments': departments,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a new batch with default values
  factory BatchModel.create({
    required String batchId,
    required int startYear,
    required int endYear,
    required List<String> departments,
  }) {
    final now = Timestamp.now();
    return BatchModel(
      batchId: batchId,
      startYear: startYear,
      endYear: endYear,
      currentSemester: 1, // Default to first semester
      currentYear: 1, // Default to first year
      departments: departments,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  BatchModel copyWith({
    String? batchId,
    int? startYear,
    int? endYear,
    int? currentSemester,
    int? currentYear,
    List<String>? departments,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return BatchModel(
      batchId: batchId ?? this.batchId,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      currentSemester: currentSemester ?? this.currentSemester,
      currentYear: currentYear ?? this.currentYear,
      departments: departments ?? this.departments,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Advance the batch to the next semester
  BatchModel advanceSemester() {
    int newSemester = currentSemester + 1;
    int newYear = currentYear;

    // If we've completed both semesters in a year, advance to next year
    if (newSemester > 2) {
      newSemester = 1;
      newYear++;
    }

    // If we've completed all years, mark as inactive
    bool newIsActive = isActive;
    if (newYear > 4) {
      newIsActive = false;
    }

    return copyWith(
      currentSemester: newSemester,
      currentYear: newYear,
      isActive: newIsActive,
      updatedAt: Timestamp.now(),
    );
  }
}
