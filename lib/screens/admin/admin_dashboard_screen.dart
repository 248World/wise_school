import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/module_card.dart';
import '../../widgets/section_title.dart';
import '../ai/ai_assistant_screen.dart';
import '../ai/ai_performance_analysis_screen.dart';
import '../ai/ai_report_generator_screen.dart';
import '../common/announcements_screen.dart';
import '../common/messages_screen.dart';
import '../common/profile_screen.dart';
import '../parent/fees_screen.dart';
import '../student/results_screen.dart';
import '../teacher/assignments_screen.dart';
import 'class_management_screen.dart';
import 'subject_management_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String displayName;

  const AdminDashboardScreen({
    super.key,
    this.displayName = 'Admin',
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      {'title': 'User Management', 'icon': Icons.people_outline},
      {'title': 'Class Management', 'icon': Icons.class_outlined},
      {'title': 'Subject Management', 'icon': Icons.menu_book_outlined},
      {'title': 'Student Results', 'icon': Icons.bar_chart_outlined},
      {'title': 'Assignments', 'icon': Icons.assignment_outlined},
      {'title': 'Fees', 'icon': Icons.payments_outlined},
      {'title': 'Parent Messages', 'icon': Icons.family_restroom_outlined},
      {'title': 'Teacher Messages', 'icon': Icons.support_agent_outlined},
      {'title': 'Announcements', 'icon': Icons.campaign_outlined},
      {'title': 'Reports', 'icon': Icons.description_outlined},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $displayName',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage users, classes, fees, results, messages, reports, and AI insights.',
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
                children: const [
                  DashboardCard(
                    title: 'Students',
                    value: 'Live',
                    icon: Icons.school_outlined,
                  ),
                  DashboardCard(
                    title: 'Fees',
                    value: 'Live',
                    icon: Icons.payments_outlined,
                  ),
                  DashboardCard(
                    title: 'Parent Chat',
                    value: 'Live',
                    icon: Icons.family_restroom_outlined,
                  ),
                  DashboardCard(
                    title: 'Teacher Chat',
                    value: 'Live',
                    icon: Icons.support_agent_outlined,
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
                      if (title == 'User Management') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserManagementScreen(),
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

                      if (title == 'Subject Management') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubjectManagementScreen(),
                          ),
                        );
                      }

                      if (title == 'Student Results') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResultsScreen(),
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

                      if (title == 'Fees') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeesScreen(role: 'Admin'),
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

                      if (title == 'Announcements') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AnnouncementsScreen(role: 'Admin'),
                          ),
                        );
                      }

                      if (title == 'Reports') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AIReportGeneratorScreen(),
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
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AIAssistantScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        color: AppColors.primaryBlue,
                        size: 38,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'AI Assistant: Generate reports, summarize attendance, and improve announcements.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AIReportGeneratorScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.softGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: AppColors.softGreen,
                        size: 38,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'AI Report Generator: Create school, class, attendance, assignment, fee, and performance reports.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AIPerformanceAnalysisScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: AppColors.primaryBlue,
                        size: 38,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'AI Performance Analysis: Detect attendance risk and summarize student progress.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                builder: (_) => const UserManagementScreen(),
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
                builder: (_) => const MessagesScreen(
                  role: 'Admin',
                  targetRole: 'Parent',
                ),
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
            icon: Icon(Icons.people_outline),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Fees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Parent Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}