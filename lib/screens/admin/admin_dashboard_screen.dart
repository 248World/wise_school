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
import '../teacher/add_marks_screen.dart';
import '../teacher/assignments_screen.dart';
import 'admin_attendance_screen.dart';
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
  int teachersCount = 0;
  int classesCount = 0;
  int subjectsCount = 0;
  int attendanceCount = 0;
  int timetableCount = 0;
  int feesCount = 0;
  int assignmentsCount = 0;
  int notificationsCount = 0;
  int reportsCount = 0;

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

      setState(() {
        isLoadingStats = true;
      });

      final studentsSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('isActive', isEqualTo: true)
          .get();

      final teachersSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Teacher')
          .where('isActive', isEqualTo: true)
          .get();

      final classesSnapshot = await firestore.collection('classes').get();
      final subjectsSnapshot = await firestore.collection('subjects').get();
      final attendanceSnapshot = await firestore.collection('attendance').get();
      final timetableSnapshot = await firestore.collection('timetables').get();
      final feesSnapshot = await firestore.collection('fees').get();
      final assignmentsSnapshot = await firestore.collection('assignments').get();
      final reportsSnapshot = await firestore.collection('ai_reports').get();

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
        teachersCount = teachersSnapshot.docs.length;
        classesCount = classesSnapshot.docs.length;
        subjectsCount = subjectsSnapshot.docs.length;
        attendanceCount = attendanceSnapshot.docs.length;
        timetableCount = timetableSnapshot.docs.length;
        feesCount = feesSnapshot.docs.length;
        assignmentsCount = assignmentsSnapshot.docs.length;
        reportsCount = reportsSnapshot.docs.length;
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

  void openAdminAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminAttendanceScreen(),
      ),
    );
  }

  Widget pngIconBox({
    required String imagePath,
    required IconData fallbackIcon,
    Color color = AppColors.primaryBlue,
    double size = 54,
    double padding = 11,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              fallbackIcon,
              color: color,
              size: size * 0.52,
            );
          },
        ),
      ),
    );
  }

  Widget headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.darkBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                    'assets/icons/admin.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.admin_panel_settings_outlined,
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
                      'Manage users, classes, subjects, attendance, timetable, fees, results, reports, and AI tools.',
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

  Widget aiToolCard({
    required IconData icon,
    required String imagePath,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              pngIconBox(
                imagePath: imagePath,
                fallbackIcon: icon,
                color: color,
                size: 56,
                padding: 11,
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
                        fontWeight: FontWeight.w900,
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
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openModule(String title) {
    if (title == 'Add Marks') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddMarksScreen(),
        ),
      );
    }

    if (title == 'Announcements') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AnnouncementsScreen(role: 'Admin'),
        ),
      );
    }

    if (title == 'Assignments') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AssignmentsScreen(role: 'Admin'),
        ),
      );
    }

    if (title == 'Attendance') {
      openAdminAttendance();
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
          builder: (_) => const NotificationsScreen(role: 'Admin'),
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
          builder: (_) => const TimetableScreen(role: 'Admin'),
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
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Add Marks',
        'icon': Icons.edit_note_outlined,
        'imagePath': 'assets/icons/add_marks.png',
      },
      {
        'title': 'Announcements',
        'icon': Icons.campaign_outlined,
        'imagePath': 'assets/icons/announcements.png',
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment_outlined,
        'imagePath': 'assets/icons/assignments.png',
        'badgeText': assignmentsCount > 0 ? assignmentsCount.toString() : '',
      },
      {
        'title': 'Attendance',
        'icon': Icons.fact_check_outlined,
        'imagePath': 'assets/icons/attendance.png',
        'badgeText': attendanceCount > 0 ? attendanceCount.toString() : '',
      },
      {
        'title': 'Class Management',
        'icon': Icons.apartment_outlined,
        'imagePath': 'assets/icons/classes.png',
        'badgeText': classesCount > 0 ? classesCount.toString() : '',
      },
      {
        'title': 'Fees',
        'icon': Icons.account_balance_wallet_outlined,
        'imagePath': 'assets/icons/fees.png',
        'badgeText': feesCount > 0 ? feesCount.toString() : '',
      },
      {
        'title': 'Notifications',
        'icon': Icons.notifications_outlined,
        'imagePath': 'assets/icons/notifications.png',
        'badgeText': notificationsCount > 0 ? notificationsCount.toString() : '',
      },
      {
        'title': 'Parent Messages',
        'icon': Icons.family_restroom_outlined,
        'imagePath': 'assets/icons/messages.png',
      },
      {
        'title': 'Reports',
        'icon': Icons.description_outlined,
        'imagePath': 'assets/icons/ai_report.png',
        'badgeText': reportsCount > 0 ? reportsCount.toString() : '',
      },
      {
        'title': 'Student Results',
        'icon': Icons.bar_chart_outlined,
        'imagePath': 'assets/icons/results.png',
      },
      {
        'title': 'Subject Management',
        'icon': Icons.menu_book_outlined,
        'imagePath': 'assets/icons/subjects.png',
        'badgeText': subjectsCount > 0 ? subjectsCount.toString() : '',
      },
      {
        'title': 'Teacher Messages',
        'icon': Icons.support_agent_outlined,
        'imagePath': 'assets/icons/teacher_messages.png',
      },
      {
        'title': 'Timetable',
        'icon': Icons.calendar_month_outlined,
        'imagePath': 'assets/icons/timetable.png',
        'badgeText': timetableCount > 0 ? timetableCount.toString() : '',
      },
      {
        'title': 'User Management',
        'icon': Icons.manage_accounts_outlined,
        'imagePath': 'assets/icons/users.png',
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
        child: RefreshIndicator(
          onRefresh: loadDashboardStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                      title: 'Students',
                      value: statValue(studentsCount),
                      icon: Icons.school_outlined,
                      imagePath: 'assets/icons/student.png',
                    ),
                    DashboardCard(
                      title: 'Teachers',
                      value: statValue(teachersCount),
                      icon: Icons.person_4_outlined,
                      imagePath: 'assets/icons/teacher.png',
                    ),
                    DashboardCard(
                      title: 'Classes',
                      value: statValue(classesCount),
                      icon: Icons.apartment_outlined,
                      imagePath: 'assets/icons/classes.png',
                    ),
                    DashboardCard(
                      title: 'Attendance',
                      value: statValue(attendanceCount),
                      icon: Icons.fact_check_outlined,
                      imagePath: 'assets/icons/attendance.png',
                    ),
                    DashboardCard(
                      title: 'Fee Records',
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
                        openModule(title);
                      },
                    );
                  },
                ),

                const SizedBox(height: 26),
                const SectionTitle(title: 'AI Tools'),
                const SizedBox(height: 14),

                aiToolCard(
                  icon: Icons.smart_toy_outlined,
                  imagePath: 'assets/icons/ai_assistant.png',
                  title: 'AI Assistant',
                  description:
                      'Summarize users, attendance, marks, fees, assignments, announcements, and generate school insights.',
                  color: AppColors.primaryBlue,
                  onTap: openAIAssistant,
                ),

                const SizedBox(height: 14),

                aiToolCard(
                  icon: Icons.description_outlined,
                  imagePath: 'assets/icons/ai_report.png',
                  title: 'AI Report Generator',
                  description:
                      'Create school, class, attendance, assignment, fee, timetable, and performance reports.',
                  color: AppColors.softGreen,
                  onTap: openAIReportGenerator,
                ),

                const SizedBox(height: 14),

                aiToolCard(
                  icon: Icons.analytics_outlined,
                  imagePath: 'assets/icons/ai_performance.png',
                  title: 'AI Performance Analysis',
                  description:
                      'Detect attendance risk, weak subjects, assignment issues, and student progress problems.',
                  color: AppColors.primaryBlue,
                  onTap: openAIPerformanceAnalysis,
                ),

                const SizedBox(height: 20),
              ],
            ),
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
                builder: (_) => const UserManagementScreen(),
              ),
            );
          }

          if (index == 2) {
            openAdminAttendance();
          }

          if (index == 3) {
            openAIAssistant();
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
            icon: Icon(Icons.manage_accounts_outlined),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: 'AI',
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
