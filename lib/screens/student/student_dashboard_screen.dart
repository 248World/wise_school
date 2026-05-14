import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/module_card.dart';
import '../../widgets/section_title.dart';
import '../ai/ai_study_assistant_screen.dart';
import '../common/announcements_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../parent/fees_screen.dart';
import '../teacher/assignments_screen.dart';
import '../teacher/attendance_screen.dart';
import 'results_screen.dart';
import 'timetable_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String displayName;

  const StudentDashboardScreen({
    super.key,
    this.displayName = 'Student',
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoadingStats = true;

  String studentId = '';
  String classId = '';

  int assignmentsCount = 0;
  int attendanceCount = 0;
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
      studentId = authProvider.userId ?? '';

      if (studentId.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingStats = false;
        });

        return;
      }

      final userDoc = await firestore.collection('users').doc(studentId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        classId = userData?['classId'] ?? '';
      }

      final attendanceSnapshot = await firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .get();

      final feesSnapshot = await firestore
          .collection('fees')
          .where('studentId', isEqualTo: studentId)
          .get();

      int loadedAssignments = 0;

      if (classId.isNotEmpty) {
        final assignmentsSnapshot = await firestore
            .collection('assignments')
            .where('classId', isEqualTo: classId)
            .get();

        loadedAssignments = assignmentsSnapshot.docs.length;
      }

      final notificationsSnapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: studentId)
          .where('isRead', isEqualTo: false)
          .get();

      if (!mounted) return;

      setState(() {
        assignmentsCount = loadedAssignments;
        attendanceCount = attendanceSnapshot.docs.length;
        feesCount = feesSnapshot.docs.length;
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
        'title': 'Profile',
        'icon': Icons.account_circle_outlined,
      },
      {
        'title': 'Timetable',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'title': 'Results',
        'icon': Icons.bar_chart_outlined,
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
        'title': 'Announcements',
        'icon': Icons.campaign_outlined,
      },
      {
        'title': 'AI Study Assistant',
        'icon': Icons.psychology_outlined,
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
        title: const Text('Student Dashboard'),
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
                'View your timetable, results, attendance, assignments, fees, announcements, notifications, and study support.',
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
                    title: 'Attendance',
                    value: statValue(attendanceCount),
                    icon: Icons.fact_check_outlined,
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
              const SectionTitle(title: 'Student Modules'),
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
                      if (title == 'AI Study Assistant') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AIStudyAssistantScreen(),
                          ),
                        );
                      }

                      if (title == 'Announcements') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AnnouncementsScreen(role: 'Student'),
                          ),
                        );
                      }

                      if (title == 'Assignments') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignmentsScreen(role: 'Student'),
                          ),
                        );
                      }

                      if (title == 'Attendance') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AttendanceScreen(role: 'Student'),
                          ),
                        );
                      }

                      if (title == 'Fees') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const FeesScreen(role: 'Student'),
                          ),
                        );
                      }

                      if (title == 'Notifications') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsScreen(role: 'Student'),
                          ),
                        );
                      }

                      if (title == 'Profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfileScreen(role: 'Student'),
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
                                const TimetableScreen(role: 'Student'),
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
                builder: (_) => const TimetableScreen(role: 'Student'),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AssignmentsScreen(role: 'Student'),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(role: 'Student'),
              ),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(role: 'Student'),
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
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
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