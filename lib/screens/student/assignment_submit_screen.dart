import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AssignmentSubmitScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const AssignmentSubmitScreen({
    super.key,
    required this.assignment,
  });

  @override
  State<AssignmentSubmitScreen> createState() => _AssignmentSubmitScreenState();
}

class _AssignmentSubmitScreenState extends State<AssignmentSubmitScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController commentController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  String existingSubmissionId = '';
  dynamic existingSubmittedAt;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadExistingSubmission();
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> loadExistingSubmission() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final studentId = authProvider.userId ?? '';
      final assignmentId = widget.assignment['id'] ?? '';

      if (studentId.isEmpty || assignmentId.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      final snapshot = await firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        existingSubmissionId = doc.id;
        existingSubmittedAt = data['submittedAt'];
        commentController.text = data['comment'] ?? '';
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> submitAssignment() async {
    final comment = commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment before submitting'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final authProvider = context.read<AuthProvider>();

      final studentId = authProvider.userId ?? '';
      final studentName = authProvider.fullName ?? 'Student';
      final assignmentId = widget.assignment['id'] ?? '';

      if (studentId.isEmpty || assignmentId.isEmpty) {
        throw Exception('Invalid student or assignment');
      }

      final submissionData = {
        'assignmentId': assignmentId,
        'assignmentTitle': widget.assignment['title'] ?? '',
        'studentId': studentId,
        'studentName': studentName,
        'classId': widget.assignment['classId'] ?? '',
        'className': widget.assignment['className'] ?? '',
        'subjectId': widget.assignment['subjectId'] ?? '',
        'subjectName': widget.assignment['subjectName'] ?? '',
        'teacherId': widget.assignment['teacherId'] ?? '',
        'teacherName': widget.assignment['teacherName'] ?? '',
        'comment': comment,
        'status': 'Submitted',
        'submittedAt': existingSubmissionId.isEmpty
            ? FieldValue.serverTimestamp()
            : existingSubmittedAt,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingSubmissionId.isEmpty) {
        await firestore.collection('assignment_submissions').add(submissionData);
      } else {
        await firestore
            .collection('assignment_submissions')
            .doc(existingSubmissionId)
            .update(submissionData);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  String formatDueDate(dynamic dueDate) {
    if (dueDate is Timestamp) {
      final date = dueDate.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'No due date';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.assignment['title'] ?? 'Assignment';
    final description = widget.assignment['description'] ?? '';
    final subjectName = widget.assignment['subjectName'] ?? '';
    final className = widget.assignment['className'] ?? '';
    final teacherName = widget.assignment['teacherName'] ?? '';
    final dueDate = widget.assignment['dueDate'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Submit Assignment'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                subjectName.isEmpty
                                    ? 'No subject'
                                    : 'Subject: $subjectName',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                className.isEmpty
                                    ? 'No class'
                                    : 'Class: $className',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                teacherName.isEmpty
                                    ? 'Teacher not assigned'
                                    : 'Teacher: $teacherName',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Due: ${formatDueDate(dueDate)}',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: commentController,
                          minLines: 6,
                          maxLines: 10,
                          decoration: const InputDecoration(
                            labelText: 'Comment to teacher',
                            hintText:
                                'Example: Sir/Madam, I have completed the assignment.',
                            prefixIcon: Icon(Icons.comment_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'File upload is disabled for now because Firebase Storage requires upgrading the project plan. This submission will save your comment and status.',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : submitAssignment,
                            icon: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: Text(
                              isSaving
                                  ? 'Submitting...'
                                  : existingSubmissionId.isEmpty
                                      ? 'Submit Work'
                                      : 'Update Work',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}