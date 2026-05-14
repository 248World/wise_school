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

  String notificationImagePath(String type) {
    if (type == 'announcement') return 'assets/icons/announcements.png';
    if (type == 'announcement_reply') return 'assets/icons/announcements.png';
    if (type == 'message') return 'assets/icons/messages.png';
    if (type == 'assignment') return 'assets/icons/assignments.png';
    if (type == 'payment_confirmation') return 'assets/icons/fees.png';
    if (type == 'payment_decision') return 'assets/icons/fees.png';
    if (type == 'fees' || type == 'payment') return 'assets/icons/fees.png';

    return 'assets/icons/notifications.png';
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

  Widget notificationPngIcon(String type) {
    final color = notificationColor(type);

    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Image.asset(
          notificationImagePath(type),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              notificationIcon(type),
              color: color,
              size: 28,
            );
          },
        ),
      ),
    );
  }

  Widget headerCard(int unreadCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardBlueGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -28,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -42,
            left: -34,
            child: Container(
              height: 115,
              width: 115,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Image.asset(
                    'assets/icons/notifications.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.white,
                        size: 34,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unreadCount > 0
                          ? 'You have $unreadCount unread notification(s).'
                          : 'You are all caught up.',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget notificationCard(Map<String, dynamic> notification) {
    final notificationId = notification['id'] ?? '';
    final title = notification['title'] ?? 'Notification';
    final message = notification['message'] ?? '';
    final type = notification['type'] ?? '';
    final isRead = notification['isRead'] == true;
    final createdAt = notification['createdAt'];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          openNotification(notification);
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isRead
                  ? AppColors.softBorder
                  : AppColors.primaryBlue.withValues(alpha: 0.20),
            ),
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
                top: -28,
                right: -26,
                child: Container(
                  height: 78,
                  width: 78,
                  decoration: BoxDecoration(
                    color: notificationColor(type).withValues(alpha: 0.045),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  notificationPngIcon(type),
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
                                      isRead ? FontWeight.w700 : FontWeight.w900,
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
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: notificationColor(type)
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                notificationTypeLabel(type),
                                style: TextStyle(
                                  color: notificationColor(type),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              formatDate(createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 86,
              width: 86,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Image.asset(
                  'assets/icons/notifications.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.notifications_none_outlined,
                      color: AppColors.primaryBlue,
                      size: 42,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Messages, announcements, assignments, and payment updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget errorState() {
    return Center(
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
                ? errorState()
                : notifications.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                          itemCount: notifications.length + 1,
                          separatorBuilder: (_, __) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return headerCard(unreadCount);
                            }

                            return notificationCard(
                              notifications[index - 1],
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}