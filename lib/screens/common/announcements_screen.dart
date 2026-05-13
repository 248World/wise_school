import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnnouncementsScreen extends StatelessWidget {
  final String role;

  const AnnouncementsScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = role == 'Admin';

    final announcements = [
      {
        'title': 'Exam Schedule Published',
        'body':
            'The final exam schedule is now available. Students should check their timetable carefully.',
        'date': 'Apr 30, 2026',
      },
      {
        'title': 'Parent Meeting',
        'body':
            'A parent meeting will be held next week to discuss student progress and school updates.',
        'date': 'May 02, 2026',
      },
      {
        'title': 'Sports Day',
        'body':
            'The school sports day will take place this month. Students are encouraged to participate.',
        'date': 'May 05, 2026',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Create announcement screen will be added later'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: announcements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = announcements[index];

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
                          Icons.campaign_outlined,
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
                    item['body'] as String,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['date'] as String,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('AI improve/translate placeholder'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('AI Improve / Translate'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}