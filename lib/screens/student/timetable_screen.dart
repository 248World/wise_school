import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timetable = [
      {
        'day': 'Monday',
        'subject': 'Mathematics',
        'teacher': 'Mr. Johnson',
        'time': '08:00 - 09:30',
        'room': 'Room 12',
      },
      {
        'day': 'Tuesday',
        'subject': 'Science',
        'teacher': 'Mrs. Carter',
        'time': '10:00 - 11:30',
        'room': 'Lab 2',
      },
      {
        'day': 'Wednesday',
        'subject': 'English',
        'teacher': 'Ms. Brown',
        'time': '09:00 - 10:30',
        'room': 'Room 8',
      },
      {
        'day': 'Thursday',
        'subject': 'Computer Science',
        'teacher': 'Mr. Smith',
        'time': '13:00 - 14:30',
        'room': 'ICT Lab',
      },
      {
        'day': 'Friday',
        'subject': 'History',
        'teacher': 'Mrs. Wilson',
        'time': '11:00 - 12:30',
        'room': 'Room 5',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Timetable'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: timetable.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = timetable[index];

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['day'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['subject'] as String,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Teacher: ${item['teacher']}',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time: ${item['time']}',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Room: ${item['room']}',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
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