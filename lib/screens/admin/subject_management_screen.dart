import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SubjectManagementScreen extends StatelessWidget {
  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = [
      {
        'name': 'Mathematics',
        'class': 'Class A',
        'teacher': 'Mr. Johnson',
        'coefficient': 'Coeff: 4',
      },
      {
        'name': 'Science',
        'class': 'Class B',
        'teacher': 'Mrs. Carter',
        'coefficient': 'Coeff: 3',
      },
      {
        'name': 'English',
        'class': 'Class A',
        'teacher': 'Ms. Brown',
        'coefficient': 'Coeff: 2',
      },
      {
        'name': 'Computer Science',
        'class': 'Class C',
        'teacher': 'Mr. Smith',
        'coefficient': 'Coeff: 4',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subject Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add subject form will be added later'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
          itemCount: subjects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = subjects[index];

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
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: AppColors.primaryBlue,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item['class'] as String,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Teacher: ${item['teacher']}',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['coefficient'] as String,
                      style: const TextStyle(
                        color: AppColors.softGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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