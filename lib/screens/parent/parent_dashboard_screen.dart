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

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Child Overview',
        'icon': Icons.child_care_outlined,
      },
      {
        'title': 'Timetable',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'title': 'Attendance',
        'icon': Icons.fact_check_outlined,
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment_outlined,
      },
      {
        'title': 'Fees',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'title': 'Results',
        'icon': Icons.bar_chart_outlined,
      },
      {
        'title': 'Announcements',
        'icon': Icons.campaign_outlined,
      },
      {
        'title': 'Messaging',
        'icon': Icons.chat_bubble_outline,
      },
      {
        'title': 'Notifications',
        'icon': Icons.notifications_outlined,
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
              Text(
                'Welcome, ${widget.displayName}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Follow your child timetable, attendance, assignments, fees, results, announcements, notifications, and messages.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
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
                  ),
                  DashboardCard(
                    title: 'Assignments',
                    value: statValue(assignmentsCount),
                    icon: Icons.assignment_outlined,
                  ),
                  DashboardCard(
                    title: 'Fees',
                    value: statValue(feesCount),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  DashboardCard(
                    title: 'Unread Notices',
                    value: statValue(notificationsCount),
                    icon: Icons.notifications_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const SectionTitle(title: 'Parent Modules'),
              const SizedBox(height: 14),
              GridView.builder(
                itemCount: modules.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final title = modules[index]['title'] as String;

                  return ModuleCard(
                    title: title,
                    icon: modules[index]['icon'] as IconData,
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