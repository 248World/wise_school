import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MessagesScreen extends StatelessWidget {
  final String role;

  const MessagesScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  Widget build(BuildContext context) {
    final conversations = [
      {
        'name': 'School Admin',
        'message': 'Please check the latest school announcement.',
        'time': '09:30',
        'unread': '2',
      },
      {
        'name': 'Class Teacher',
        'message': 'Attendance and marks have been updated.',
        'time': 'Yesterday',
        'unread': '0',
      },
      {
        'name': 'Parent Support',
        'message': 'Your request has been received.',
        'time': 'Mon',
        'unread': '1',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = conversations[index];
            final bool hasUnread = item['unread'] != '0';

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
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.person_outline,
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
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item['message'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['time'] as String,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            item['unread'] as String,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
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