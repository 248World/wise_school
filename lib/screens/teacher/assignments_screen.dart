import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AssignmentsScreen extends StatelessWidget {
  final String role;

  const AssignmentsScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  Widget build(BuildContext context) {
    final assignments = [
      {
        'title': 'Mathematics Homework',
        'subject': 'Mathematics',
        'description': 'Complete exercises 1 to 10 from chapter 3.',
        'dueDate': 'Due: May 05, 2026',
        'status': 'Pending',
      },
      {
        'title': 'Science Report',
        'subject': 'Science',
        'description': 'Prepare a short report about renewable energy.',
        'dueDate': 'Due: May 08, 2026',
        'status': 'Submitted',
      },
      {
        'title': 'English Essay',
        'subject': 'English',
        'description': 'Write an essay about technology in education.',
        'dueDate': 'Due: May 10, 2026',
        'status': 'Pending',
      },
    ];

    final bool isTeacher = role == 'Teacher';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: assignments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = assignments[index];
            final bool isSubmitted = item['status'] == 'Submitted';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
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
                  Row(
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item['subject'] as String,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description'] as String,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['dueDate'] as String,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSubmitted
                              ? AppColors.softGreen.withValues(alpha: 0.14)
                              : AppColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['status'] as String,
                          style: TextStyle(
                            color: isSubmitted
                                ? AppColors.softGreen
                                : AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}