import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/notification_service.dart';
import '../parent/fees_screen.dart';
import '../teacher/assignments_screen.dart';
import 'announcements_screen.dart';
import 'messages_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String role;

  const NotificationsScreen({
    super.key,
    this.role = 'Student',
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  bool isLoading = true;
  String? errorMessage;

  String currentUserId = '';
  String currentRole = '';

  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadNotifications();
    });
  }

  Future<void> loadNotifications() async {
    try {
      final user = firebaseAuth.currentUser;

      currentUserId = user?.uid ?? '';
      currentRole = widget.role;

      if (currentUserId.isEmpty) {
        throw Exception('User not found. Please login again.');
      }

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .get();

      notifications = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'type': data['type'] ?? '',
          'relatedId': data['relatedId'] ?? '',
          'senderId': data['senderId'] ?? '',
          'senderName': data['senderName'] ?? '',
          'senderRole': data['senderRole'] ?? '',
          'isRead': data['isRead'] ?? false,
          'createdAt': data['createdAt'],
        };
      }).toList();

      notifications.sort((a, b) {
        final aCreated = a['createdAt'];
        final bCreated = b['createdAt'];

        if (aCreated is Timestamp && bCreated is Timestamp) {
          return bCreated.compareTo(aCreated);
        }

        return 0;
      });

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

  Future<void> markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead(currentUserId);

      await loadNotifications();

      if (!mounted) return;

      showSnackBar('All notifications marked as read');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);

      await loadNotifications();

      if (!mounted) return;

      showSnackBar('Notification deleted');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> openNotification(Map<String, dynamic> notification) async {
    final notificationId = notification['id'] ?? '';
    final type = notification['type'] ?? '';
    final senderRole = notification['senderRole'] ?? '';

    if (notificationId.toString().isNotEmpty) {
      await NotificationService.markAsRead(notificationId);
    }

    if (!mounted) return;

    if (type == 'announcement' || type == 'announcement_reply') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnnouncementsScreen(role: currentRole),
        ),
      );

      await loadNotifications();
      return;
    }

    if (type == 'message') {
      String targetRole = senderRole.toString();

      if (currentRole == 'Admin') {
        if (targetRole != 'Parent' && targetRole != 'Teacher') {
          targetRole = 'Parent';
        }
      } else {
        targetRole = 'Admin';
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessagesScreen(
            role: currentRole,
            targetRole: targetRole,
          ),
        ),
      );

      await loadNotifications();
      return;
    }

    if (type == 'assignment') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignmentsScreen(role: currentRole),
        ),
      );

      await loadNotifications();
      return;
    }

    if (type == 'payment_confirmation' ||
        type == 'payment_decision' ||
        type == 'fees' ||
        type == 'payment') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FeesScreen(role: currentRole),
        ),
      );

      await loadNotifications();
      return;
    }

    await loadNotifications();
  }

  IconData notificationIcon(String type) {
    if (type == 'announcement') {
      return Icons.campaign_outlined;
    }

    if (type == 'announcement_reply') {
      return Icons.reply_outlined;
    }

    if (type == 'message') {
      return Icons.chat_bubble_outline;
    }

    if (type == 'assignment') {
      return Icons.assignment_outlined;
    }

    if (type == 'payment_confirmation') {
      return Icons.payments_outlined;
    }

    if (type == 'payment_decision') {
      return Icons.verified_outlined;
    }

    if (type == 'fees' || type == 'payment') {
      return Icons.account_balance_wallet_outlined;
    }

    return Icons.notifications_outlined;
  }

  Color notificationColor(String type) {
    if (type == 'announcement') {
      return AppColors.primaryBlue;
    }

    if (type == 'announcement_reply') {
      return AppColors.softGreen;
    }

    if (type == 'message') {
      return AppColors.primaryBlue;
    }

    if (type == 'assignment') {
      return Colors.orange;
    }

    if (type == 'payment_confirmation') {
      return Colors.orange;
    }

    if (type == 'payment_decision') {
      return AppColors.softGreen;
    }

    if (type == 'fees' || type == 'payment') {
      return AppColors.danger;
    }

    return AppColors.textGrey;
  }

  String notificationTypeLabel(String type) {
    if (type == 'announcement') return 'Announcement';
    if (type == 'announcement_reply') return 'Reply';
    if (type == 'message') return 'Message';
    if (type == 'assignment') return 'Assignment';
    if (type == 'payment_confirmation') return 'Payment Confirmation';
    if (type == 'payment_decision') return 'Payment Decision';
    if (type == 'fees') return 'Fees';
    if (type == 'payment') return 'Payment';

    return 'Notification';
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year • $hour:$minute';
    }

    return 'Recently';
  }

  Widget notificationCard(Map<String, dynamic> notification) {
    final notificationId = notification['id'] ?? '';
    final title = notification['title'] ?? 'Notification';
    final message = notification['message'] ?? '';
    final type = notification['type'] ?? '';
    final isRead = notification['isRead'] == true;
    final createdAt = notification['createdAt'];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        openNotification(notification);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? AppColors.white
              : AppColors.primaryBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead
                ? AppColors.border
                : AppColors.primaryBlue.withValues(alpha: 0.25),
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
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: notificationColor(type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                notificationIcon(type),
                color: notificationColor(type),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          height: 9,
                          width: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: notificationColor(type).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          notificationTypeLabel(type),
                          style: TextStyle(
                            color: notificationColor(type),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatDate(createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  deleteNotification(notificationId);
                }
              },
              itemBuilder: (_) {
                return const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No notifications yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  void showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((item) {
      return item['isRead'] != true;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadNotifications,
            icon: const Icon(Icons.refresh_outlined),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text(
                'Read all',
                style: TextStyle(color: AppColors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
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
                : notifications.isEmpty
                    ? emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(18),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) {
                          return const SizedBox(height: 12);
                        },
                        itemBuilder: (context, index) {
                          return notificationCard(notifications[index]);
                        },
                      ),
      ),
    );
  }
}