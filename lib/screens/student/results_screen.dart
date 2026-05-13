import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final results = [
      {
        'subject': 'Mathematics',
        'mark': '16/20',
        'grade': 'A',
        'comment': 'Excellent work. Keep practicing.',
      },
      {
        'subject': 'Science',
        'mark': '14/20',
        'grade': 'B',
        'comment': 'Good performance with room to improve.',
      },
      {
        'subject': 'English',
        'mark': '17/20',
        'grade': 'A',
        'comment': 'Strong communication and writing skills.',
      },
      {
        'subject': 'Computer Science',
        'mark': '18/20',
        'grade': 'A+',
        'comment': 'Very strong understanding of the subject.',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = results[index];

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
                          Icons.menu_book_outlined,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item['subject'] as String,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['grade'] as String,
                          style: const TextStyle(
                            color: AppColors.softGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Mark: ${item['mark']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item['comment'] as String,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.4,
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