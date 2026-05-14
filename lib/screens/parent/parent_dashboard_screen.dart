import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/module_card.dart';
import '../../widgets/section_title.dart';
import '../common/announcements_screen.dart';
import '../common/messages_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../student/results_screen.dart';
import '../student/timetable_screen.dart';
import '../teacher/assignments_screen.dart';
import '../teacher/attendance_screen.dart';
import 'child_overview_screen.dart';
import 'fees_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final String displayName;

  const ParentDashboardScreen({
    super.key,
    this.displayName = 'Parent',
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoadingStats = true;

  String parentId = '';

  int childrenCount = 0;
  int assignmentsCount = 0;
  int feesCount = 0;
  int notificationsCount = 0;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadDashboardStats();
    });
  }

  Future<void> loadDashboardStats() async {
    try {
      final authProvider = context.read<AuthProvider>();
      parentId = authProvider.userId ?? '';

      if (parentId.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingStats = false;
        });

        return;
      }

      final childrenSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .get();

      final childIds = childrenSnapshot.docs.map((doc) => doc.id).toList();

      final classIds = childrenSnapshot.docs
          .map((doc) => doc.data()['classId'] ?? '')
          .where((classId) => classId.toString().isNotEmpty)
          .toSet()
          .toList();

      int loadedAssignments = 0;
      int loadedFees = 0;

      for (final classId in classIds) {
        final assignmentSnapshot = await firestore
            .collection('assignments')
            .where('classId', isEqualTo: classId)
            .get();

        loadedAssignments += assignmentSnapshot.docs.length;
      }

      for (final childId in childIds) {
        final feesSnapshot = await firestore
            .collection('fees')
            .where('studentId', isEqualTo: childId)
            .get();

        loadedFees += feesSnapshot.docs.length;
      }

      final notificationsSnapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: parentId)
          .where('isRead', isEqualTo: false)
          .get();

      if (!mounted) return;

      setState(() {
        childrenCount = childrenSnapshot.docs.length;
        assignmentsCount = loadedAssignments;
        feesCount = loadedFees;
        notificationsCount = notificationsSnapshot.docs.length;
        isLoadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingStats = false;
      });
    }
  }

  String statValue(int value) {
    if (isLoadingStats) return '...';
    return value.toString();
  }

  Widget headerCard() {
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
                    'assets/icons/parent.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.family_restroom_outlined,
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
                    Text(
                      'Welcome, ${widget.displayName}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Follow your child’s timetable, results, fees, attendance, and updates.',
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

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Child Overview',
        'icon': Icons.child_care_outlined,
        'imagePath': 'assets/icons/child_overview.png',
      },
      {
        'title': 'Timetable',
        'icon': Icons.calendar_month_outlined,
        'imagePath': 'assets/icons/timetable.png',
      },
      {
        'title': 'Attendance',
        'icon': Icons.fact_check_outlined,
        'imagePath': 'assets/icons/attendance.png',
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment_outlined,
        'imagePath': 'assets/icons/assignments.png',
      },
      {
        'title': 'Fees',
        'icon': Icons.account_balance_wallet_outlined,
        'imagePath': 'assets/icons/fees.png',
      },
      {
        'title': 'Results',
        'icon': Icons.bar_chart_outlined,
        'imagePath': 'assets/icons/results.png',
      },
      {
        'title': 'Announcements',
        'icon': Icons.campaign_outlined,
        'imagePath': 'assets/icons/announcements.png',
      },
      {
        'title': 'Messaging',
        'icon': Icons.chat_bubble_outline,
        'imagePath': 'assets/icons/messages.png',
      },
      {
        'title': 'Notifications',
        'icon': Icons.notifications_outlined,
        'imagePath': 'assets/icons/notifications.png',
        'badgeText': notificationsCount > 0 ? notificationsCount.toString() : '',
      },
    ];

    modules.sort((a, b) {
      final titleA = a['title'] as String;
      final titleB = b['title'] as String;
      return titleA.compareTo(titleB);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            onPressed: loadDashboardStats,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerCard(),

              const SizedBox(height: 22),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.45,
                children: [
                  DashboardCard(
                    title: 'Children',
                    value: statValue(childrenCount),
                    icon: Icons.child_care_outlined,
                    imagePath: 'assets/icons/children.png',
                  ),
                  DashboardCard(
                    title: 'Assignments',
                    value: statValue(assignmentsCount),
                    icon: Icons.assignment_outlined,
                    imagePath: 'assets/icons/assignments.png',
                  ),
                  DashboardCard(
                    title: 'Fees',
                    value: statValue(feesCount),
                    icon: Icons.account_balance_wallet_outlined,
                    imagePath: 'assets/icons/fees.png',
                  ),
                  DashboardCard(
                    title: 'Unread Notices',
                    value: statValue(notificationsCount),
                    icon: Icons.notifications_outlined,
                    imagePath: 'assets/icons/notifications.png',
                  ),
                ],
              ),

              const SizedBox(height: 26),

              const SectionTitle(
                title: 'Parent Modules',
                icon: Icons.dashboard_outlined,
                imagePath: 'assets/icons/modules.png',
              ),

              const SizedBox(height: 14),

              GridView.builder(
                itemCount: modules.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final title = modules[index]['title'] as String;

                  return ModuleCard(
                    title: title,
                    icon: modules[index]['icon'] as IconData,
                    imagePath: modules[index]['imagePath'] as String,
                    badgeText: modules[index]['badgeText'] as String?,
                    onTap: () {
                      if (title == 'Announcements') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AnnouncementsScreen(role: 'Parent'),
                          ),
                        );
                      }

                      if (title == 'Assignments') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignmentsScreen(role: 'Parent'),
                          ),
                        );
                      }

                      if (title == 'Attendance') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AttendanceScreen(role: 'Parent'),
                          ),
                        );
                      }

                      if (title == 'Child Overview') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChildOverviewScreen(),
                          ),
                        );
                      }

                      if (title == 'Fees') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeesScreen(role: 'Parent'),
                          ),
                        );
                      }

                      if (title == 'Messaging') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessagesScreen(
                              role: 'Parent',
                              targetRole: 'Admin',
                            ),
                          ),
                        );
                      }

                      if (title == 'Notifications') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsScreen(role: 'Parent'),
                          ),
                        );
                      }

                      if (title == 'Results') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResultsScreen(),
                          ),
                        );
                      }

                      if (title == 'Timetable') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TimetableScreen(role: 'Parent'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) return;

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TimetableScreen(role: 'Parent'),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FeesScreen(role: 'Parent'),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(role: 'Parent'),
              ),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(role: 'Parent'),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Fees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}