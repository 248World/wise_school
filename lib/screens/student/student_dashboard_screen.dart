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
                    'assets/icons/student.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.school_outlined,
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
                      'View your timetable, assignments, results, fees, and study support.',
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
        'title': 'Profile',
        'icon': Icons.account_circle_outlined,
        'imagePath': 'assets/icons/profile.png',
      },
      {
        'title': 'Timetable',
        'icon': Icons.calendar_month_outlined,
        'imagePath': 'assets/icons/timetable.png',
      },
      {
        'title': 'Results',
        'icon': Icons.bar_chart_outlined,
        'imagePath': 'assets/icons/results.png',
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
        'title': 'Announcements',
        'icon': Icons.campaign_outlined,
        'imagePath': 'assets/icons/announcements.png',
      },
      {
        'title': 'AI Study Assistant',
        'icon': Icons.psychology_outlined,
        'imagePath': 'assets/icons/ai_assistant.png',
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
                    title: 'Attendance',
                    value: statValue(attendanceCount),
                    icon: Icons.fact_check_outlined,
                    imagePath: 'assets/icons/attendance.png',
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
                title: 'Student Modules',
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
                            builder: (_) => const FeesScreen(role: 'Student'),
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
                            builder: (_) => const TimetableScreen(role: 'Student'),
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