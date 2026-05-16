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

  String studentId = '';
  String studentName = '';
  String studentClassId = '';
  String studentClassName = '';

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

      studentId = authProvider.userId ?? '';
      studentName = authProvider.fullName ?? 'Student';

      final assignmentId = widget.assignment['id'] ?? '';

      if (studentId.isEmpty || assignmentId.toString().isEmpty) {
        throw Exception('Invalid student or assignment');
      }

      final userDoc = await firestore.collection('users').doc(studentId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        studentClassId = userData?['classId'] ?? '';
        studentClassName = userData?['className'] ?? '';
      }

      final assignmentClassId = (widget.assignment['classId'] ?? '').toString();

      if (studentClassId.isNotEmpty &&
          assignmentClassId.isNotEmpty &&
          studentClassId != assignmentClassId) {
        throw Exception(
          'This assignment does not belong to your current class.',
        );
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
      showSnackBar('Please write a comment before submitting');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final assignmentId = (widget.assignment['id'] ?? '').toString();

      if (studentId.isEmpty || assignmentId.isEmpty) {
        throw Exception('Invalid student or assignment');
      }

      final assignmentClassId = (widget.assignment['classId'] ?? '').toString();

      if (studentClassId.isNotEmpty &&
          assignmentClassId.isNotEmpty &&
          studentClassId != assignmentClassId) {
        throw Exception(
          'This assignment does not belong to your current class.',
        );
      }

      final freshSnapshot = await firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      String submissionIdToUpdate = existingSubmissionId;
      dynamic submittedAtToKeep = existingSubmittedAt;

      if (freshSnapshot.docs.isNotEmpty) {
        final doc = freshSnapshot.docs.first;
        final data = doc.data();

        submissionIdToUpdate = doc.id;
        submittedAtToKeep = data['submittedAt'];
      }

      final submissionData = {
        'assignmentId': assignmentId,
        'assignmentTitle': widget.assignment['title'] ?? '',
        'studentId': studentId,
        'studentName': studentName,
        'classId': widget.assignment['classId'] ?? studentClassId,
        'className': widget.assignment['className'] ?? studentClassName,
        'subjectId': widget.assignment['subjectId'] ?? '',
        'subjectName': widget.assignment['subjectName'] ?? '',
        'teacherId': widget.assignment['teacherId'] ?? '',
        'teacherName': widget.assignment['teacherName'] ?? '',
        'comment': comment,
        'status': 'Submitted',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (submissionIdToUpdate.isEmpty) {
        await firestore.collection('assignment_submissions').add({
          ...submissionData,
          'submittedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await firestore
            .collection('assignment_submissions')
            .doc(submissionIdToUpdate)
            .update({
          ...submissionData,
          'submittedAt': submittedAtToKeep ?? FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  String formatDueDate(dynamic dueDate) {
    if (dueDate is Timestamp) {
      final date = dueDate.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'No due date';
  }

  String formatSubmittedAt(dynamic submittedAt) {
    if (submittedAt is Timestamp) {
      final date = submittedAt.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Already submitted';
  }

  Widget pngIconBox({
    required String imagePath,
    required IconData fallbackIcon,
    Color color = AppColors.primaryBlue,
    double size = 54,
    double padding = 11,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              fallbackIcon,
              color: color,
              size: size * 0.52,
            );
          },
        ),
      ),
    );
  }

  Widget smallStatusChip({
    required String text,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 190,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget detailLine({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.textLight,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget assignmentDetailsCard() {
    final title = widget.assignment['title'] ?? 'Assignment';
    final description = widget.assignment['description'] ?? '';
    final subjectName = widget.assignment['subjectName'] ?? '';
    final className = widget.assignment['className'] ?? '';
    final teacherName = widget.assignment['teacherName'] ?? '';
    final dueDate = widget.assignment['dueDate'];
    final alreadySubmitted = existingSubmissionId.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -24,
            child: Container(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  pngIconBox(
                    imagePath: 'assets/icons/assignments.png',
                    fallbackIcon: Icons.assignment_outlined,
                    size: 56,
                    padding: 11,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            smallStatusChip(
                              text: subjectName.isEmpty
                                  ? 'No subject'
                                  : subjectName,
                              color: AppColors.primaryBlue,
                            ),
                            smallStatusChip(
                              text: 'Due: ${formatDueDate(dueDate)}',
                              color: AppColors.softGreen,
                            ),
                            smallStatusChip(
                              text: alreadySubmitted
                                  ? 'Submitted'
                                  : 'Not submitted',
                              color: alreadySubmitted
                                  ? AppColors.softGreen
                                  : AppColors.danger,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              detailLine(
                icon: Icons.class_outlined,
                text: className.isEmpty ? 'No class' : 'Class: $className',
              ),
              const SizedBox(height: 6),
              detailLine(
                icon: Icons.person_outline,
                text: teacherName.isEmpty
                    ? 'Teacher not assigned'
                    : 'Teacher: $teacherName',
              ),
              if (alreadySubmitted) ...[
                const SizedBox(height: 6),
                detailLine(
                  icon: Icons.check_circle_outline,
                  text: 'Submitted: ${formatSubmittedAt(existingSubmittedAt)}',
                ),
              ],
              if (description.toString().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget commentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              pngIconBox(
                imagePath: 'assets/icons/messages.png',
                fallbackIcon: Icons.comment_outlined,
                size: 46,
                padding: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  existingSubmissionId.isEmpty
                      ? 'Submit Your Work'
                      : 'Update Your Work',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: commentController,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Comment to teacher',
              hintText: 'Example: Sir/Madam, I have completed the assignment.',
              prefixIcon: Icon(Icons.comment_outlined),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'File upload is disabled for now. This submission will save your comment and status.',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitLabel =
        existingSubmissionId.isEmpty ? 'Submit Work' : 'Update Work';

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
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        assignmentDetailsCard(),
                        const SizedBox(height: 18),
                        commentCard(),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: errorMessage != null || isLoading
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: SizedBox(
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
                      isSaving ? 'Submitting...' : submitLabel,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
