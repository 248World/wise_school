import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/module_card.dart';
import '../../widgets/section_title.dart';
import '../ai/ai_assistant_screen.dart';
import '../ai/ai_performance_analysis_screen.dart';
import '../ai/ai_report_generator_screen.dart';
import '../common/announcements_screen.dart';
import '../common/messages_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../parent/fees_screen.dart';
import '../student/results_screen.dart';
import '../student/timetable_screen.dart';
import '../teacher/assignments_screen.dart';
import 'class_management_screen.dart';
import 'subject_management_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String displayName;

  const AdminDashboardScreen({
    super.key,
    this.displayName = 'Admin',
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoadingStats = true;

  String adminId = '';

  int studentsCount = 0;
  int timetableCount = 0;
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
      adminId = authProvider.userId ?? '';

      final studentsSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('isActive', isEqualTo: true)
          .get();

      final timetableSnapshot = await firestore.collection('timetables').get();

      final feesSnapshot = await firestore.collection('fees').get();

      int unreadNotifications = 0;

      if (adminId.isNotEmpty) {
        final notificationsSnapshot = await firestore
            .collection('notifications')
            .where('userId', isEqualTo: adminId)
            .where('isRead', isEqualTo: false)
            .get();

        unreadNotifications = notificationsSnapshot.docs.length;
      }

      if (!mounted) return;

      setState(() {
        studentsCount = studentsSnapshot.docs.length;
        timetableCount = timetableSnapshot.docs.length;
        feesCount = feesSnapshot.docs.length;
        notificationsCount = unreadNotifications;
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

  void openAIAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AIAssistantScreen(),
      ),
    );
  }

  void openAIReportGenerator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AIReportGeneratorScreen(),
      ),
    );
  }

  void openAIPerformanceAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AIPerformanceAnalysisScreen(),
      ),
    );
  }

  Widget aiToolCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'User Management',
        'icon': Icons.manage_accounts_outlined,
      },
      {
        'title': 'Class Management',
        'icon': Icons.apartment_outlined,
      },
      {
        'title': 'Subject Management',
        'icon': Icons.menu_book_outlined,
      },
      {
        'title': 'Timetable',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'title': 'Student Results',
        'icon': Icons.bar_chart_outlined,
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
        'title': 'Notifications',
        'icon': Icons.notifications_outlined,
      },
      {
        'title': 'Parent Messages',
        'icon': Icons.family_restroom_outlined,
      },
      {
        'title': 'Teacher Messages',
        'icon': Icons.support_agent_outlined,
      },
      {
        'title': 'Reports',
        'icon': Icons.description_outlined,
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
        title: const Text('Admin Dashboard'),
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
                'Manage users, classes, timetable, fees, results, announcements, notifications, messages, reports, and AI tools.',
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
                    title: 'Students',
                    value: statValue(studentsCount),
                    icon: Icons.school_outlined,
                  ),
                  DashboardCard(
                    title: 'Timetables',
                    value: statValue(timetableCount),
                    icon: Icons.calendar_month_outlined,
                  ),
                  DashboardCard(
                    title: 'Fee Records',
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
              const SectionTitle(title: 'School Modules'),
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
                                const AnnouncementsScreen(role: 'Admin'),
                          ),
                        );
                      }

                      if (title == 'Assignments') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignmentsScreen(role: 'Admin'),
                          ),
                        );
                      }

                      if (title == 'Class Management') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClassManagementScreen(),
                          ),
                        );
                      }

                      if (title == 'Fees') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeesScreen(role: 'Admin'),
                          ),
                        );
                      }

                      if (title == 'Notifications') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsScreen(role: 'Admin'),
                          ),
                        );
                      }

                      if (title == 'Parent Messages') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessagesScreen(
                              role: 'Admin',
                              targetRole: 'Parent',
                            ),
                          ),
                        );
                      }

                      if (title == 'Reports') {
                        openAIReportGenerator();
                      }

                      if (title == 'Student Results') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResultsScreen(),
                          ),
                        );
                      }

                      if (title == 'Subject Management') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubjectManagementScreen(),
                          ),
                        );
                      }

                      if (title == 'Teacher Messages') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessagesScreen(
                              role: 'Admin',
                              targetRole: 'Teacher',
                            ),
                          ),
                        );
                      }

                      if (title == 'Timetable') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TimetableScreen(role: 'Admin'),
                          ),
                        );
                      }

                      if (title == 'User Management') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserManagementScreen(),
                          ),
                        );
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 26),
              const SectionTitle(title: 'AI Tools'),
              const SizedBox(height: 14),

              aiToolCard(
                icon: Icons.smart_toy_outlined,
                title: 'AI Assistant',
                description:
                    'Generate reports, summarize attendance, and improve announcements.',
                color: AppColors.primaryBlue,
                onTap: openAIAssistant,
              ),

              const SizedBox(height: 14),

              aiToolCard(
                icon: Icons.description_outlined,
                title: 'AI Report Generator',
                description:
                    'Create school, class, attendance, assignment, fee, timetable, and performance reports.',
                color: AppColors.softGreen,
                onTap: openAIReportGenerator,
              ),

              const SizedBox(height: 14),

              aiToolCard(
                icon: Icons.analytics_outlined,
                title: 'AI Performance Analysis',
                description:
                    'Detect attendance risk and summarize student progress.',
                color: AppColors.primaryBlue,
                onTap: openAIPerformanceAnalysis,
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
                builder: (_) => const TimetableScreen(role: 'Admin'),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FeesScreen(role: 'Admin'),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(role: 'Admin'),
              ),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(role: 'Admin'),
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