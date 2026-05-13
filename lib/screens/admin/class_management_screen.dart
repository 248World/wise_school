import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ClassManagementScreen extends StatelessWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final classes = [
      {
        'name': 'Class A',
        'level': 'Primary 6',
        'teacher': 'Mr. Johnson',
        'students': '32 Students',
      },
      {
        'name': 'Class B',
        'level': 'Middle School 1',
        'teacher': 'Mrs. Carter',
        'students': '28 Students',
      },
      {
        'name': 'Class C',
        'level': 'Middle School 2',
        'teacher': 'Mr. Smith',
        'students': '30 Students',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Class Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add class form will be added later'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
          itemCount: classes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = classes[index];

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
                      Icons.class_outlined,
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
                          item['level'] as String,
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

                  Text(
                    item['students'] as String,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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