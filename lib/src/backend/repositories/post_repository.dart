import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/submission_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class PostRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  // Create a new post
  Future<String> createPost({
    required String classroomId,
    required String teacherId,
    required String title,
    required String content,
    List<File>? attachments,
    bool isAssignment = false,
    DateTime? dueDate,
    int? maxPoints,
  }) async {
    try {
      final postId = _firebaseService.generateId('posts');

      // Upload attachments if any
      List<String>? attachmentUrls;
      if (attachments != null && attachments.isNotEmpty) {
        attachmentUrls = [];
        for (final file in attachments) {
          final url = await _storageService.uploadClassMaterial(
              classroomId, postId, file);
          attachmentUrls.add(url);
        }
      }

      // Create post document
      await _firebaseService.postsCollection.doc(postId).set({
        'postId': postId,
        'classroomId': classroomId,
        'teacherId': teacherId,
        'title': title,
        'content': content,
        'attachmentUrls': attachmentUrls,
        'createdAt': _firebaseService.serverTimestamp,
        'isAssignment': isAssignment,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'maxPoints': maxPoints,
      });

      // Send notification for assignments
      if (isAssignment && dueDate != null) {
        await _notificationService.sendAssignmentNotification(
          classroomId: classroomId,
          title: title,
          dueDate: dueDate.toString().substring(0, 10), // YYYY-MM-DD format
        );
      }

      return postId;
    } catch (e) {
      throw Exception('Error creating post: ${e.toString()}');
    }
  }

  // Get post by ID
  Future<PostModel> getPostById(String postId) async {
    try {
      final doc = await _firebaseService.postsCollection.doc(postId).get();

      if (!doc.exists) {
        throw Exception('Post not found');
      }

      return PostModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error fetching post: ${e.toString()}');
    }
  }

  // Get posts for a classroom
  Future<List<PostModel>> getPostsForClassroom(String classroomId) async {
    try {
      final querySnapshot = await _firebaseService.postsCollection
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching posts: ${e.toString()}');
    }
  }

  // Get assignments for a classroom
  Future<List<PostModel>> getAssignmentsForClassroom(String classroomId) async {
    try {
      final querySnapshot = await _firebaseService.postsCollection
          .where('classroomId', isEqualTo: classroomId)
          .where('isAssignment', isEqualTo: true)
          .orderBy('dueDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching assignments: ${e.toString()}');
    }
  }

  // Update a post
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = _firebaseService.serverTimestamp;
      await _firebaseService.postsCollection.doc(postId).update(data);
    } catch (e) {
      throw Exception('Error updating post: ${e.toString()}');
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Get the post to find any attachments
      final post = await getPostById(postId);

      // Delete attachments from storage
      if (post.attachmentUrls != null && post.attachmentUrls!.isNotEmpty) {
        for (final url in post.attachmentUrls!) {
          await _storageService.deleteFile(url);
        }
      }

      // Delete post document
      await _firebaseService.postsCollection.doc(postId).delete();

      // Also delete any submissions for this post
      final submissionsSnapshot = await _firebaseService.submissionsCollection
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _firebaseService.firestore.batch();
      for (final doc in submissionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (submissionsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Error deleting post: ${e.toString()}');
    }
  }

  // Submit assignment
  Future<String> submitAssignment({
    required String postId,
    required String studentId,
    required List<File> files,
  }) async {
    try {
      final submissionId = _firebaseService.generateId('submissions');

      // Upload submission files
      List<String> submissionUrls = [];
      for (final file in files) {
        final url =
            await _storageService.uploadSubmission(postId, studentId, file);
        submissionUrls.add(url);
      }

      // Create submission document
      await _firebaseService.submissionsCollection.doc(submissionId).set({
        'submissionId': submissionId,
        'postId': postId,
        'studentId': studentId,
        'submissionUrls': submissionUrls,
        'submittedAt': _firebaseService.serverTimestamp,
      });

      return submissionId;
    } catch (e) {
      throw Exception('Error submitting assignment: ${e.toString()}');
    }
  }

  // Get submission for a student
  Future<SubmissionModel?> getStudentSubmission(
      String postId, String studentId) async {
    try {
      final querySnapshot = await _firebaseService.submissionsCollection
          .where('postId', isEqualTo: postId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return SubmissionModel.fromJson(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error fetching submission: ${e.toString()}');
    }
  }

  // Get all submissions for an assignment
  Future<List<SubmissionModel>> getSubmissionsForAssignment(
      String postId) async {
    try {
      final querySnapshot = await _firebaseService.submissionsCollection
          .where('postId', isEqualTo: postId)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SubmissionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching submissions: ${e.toString()}');
    }
  }

  // Grade submission
  Future<void> gradeSubmission({
    required String submissionId,
    required double grade,
    String? feedback,
    required String gradedBy,
  }) async {
    try {
      await _firebaseService.submissionsCollection.doc(submissionId).update({
        'grade': grade,
        'feedback': feedback,
        'gradedBy': gradedBy,
        'gradedAt': _firebaseService.serverTimestamp,
      });
    } catch (e) {
      throw Exception('Error grading submission: ${e.toString()}');
    }
  }

  // Get submissions by student
  Future<List<SubmissionModel>> getSubmissionsByStudent(
      String studentId) async {
    try {
      final querySnapshot = await _firebaseService.submissionsCollection
          .where('studentId', isEqualTo: studentId)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SubmissionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching student submissions: ${e.toString()}');
    }
  }

  // Get upcoming assignments for a student
  Future<List<PostModel>> getUpcomingAssignments(String studentId) async {
    try {
      final now = Timestamp.now();

      // First get classrooms the student is enrolled in
      final enrollmentSnapshot = await _firebaseService.enrollmentsCollection
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .get();

      final classroomIds = enrollmentSnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['classroomId'] as String)
          .toList();

      if (classroomIds.isEmpty) {
        return [];
      }

      // Get assignments from these classrooms with due dates in the future
      List<PostModel> upcomingAssignments = [];

      // Process classrooms in chunks (Firestore limitation)
      for (int i = 0; i < classroomIds.length; i += 10) {
        final endIndex =
            (i + 10 < classroomIds.length) ? i + 10 : classroomIds.length;
        final chunk = classroomIds.sublist(i, endIndex);

        final querySnapshot = await _firebaseService.postsCollection
            .where('classroomId', whereIn: chunk)
            .where('isAssignment', isEqualTo: true)
            .where('dueDate', isGreaterThan: now)
            .orderBy('dueDate', descending: false)
            .get();

        final assignments = querySnapshot.docs
            .map(
                (doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        upcomingAssignments.addAll(assignments);
      }

      return upcomingAssignments;
    } catch (e) {
      throw Exception('Error fetching upcoming assignments: ${e.toString()}');
    }
  }
}
