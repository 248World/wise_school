import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  final String role;

  const NotificationsScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'New Announcement',
        'body': 'The school has published a new announcement.',
        'time': '10 min ago',
        'read': false,
      },
      {
        'title': 'Attendance Updated',
        'body': 'Today’s attendance has been marked successfully.',
        'time': '1 hour ago',
        'read': true,
      },
      {
        'title': 'Assignment Reminder',
        'body': 'You have a pending assignment due soon.',
        'time': 'Yesterday',
        'read': false,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = notifications[index];
            final bool isRead = item['read'] as bool;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isRead
                      ? AppColors.border
                      : AppColors.primaryBlue.withValues(alpha: 0.35),
                ),
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
                  CircleAvatar(
                    backgroundColor: isRead
                        ? AppColors.border
                        : AppColors.primaryBlue.withValues(alpha: 0.12),
                    child: Icon(
                      isRead
                          ? Icons.notifications_none_outlined
                          : Icons.notifications_active_outlined,
                      color: isRead ? AppColors.textGrey : AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['body'] as String,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['time'] as String,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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