import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/module_card.dart';
import '../../widgets/section_title.dart';
import '../ai/ai_performance_analysis_screen.dart';
import '../common/profile_screen.dart';
import '../common/messages_screen.dart';
import '../teacher/attendance_screen.dart';
import '../student/results_screen.dart';
import 'fees_screen.dart';
import 'child_overview_screen.dart';

class ParentDashboardScreen extends StatelessWidget {
  final String displayName;

  const ParentDashboardScreen({
    super.key,
    this.displayName = 'Parent',
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      {'title': 'Child Overview', 'icon': Icons.child_care_outlined},
      {'title': 'Attendance', 'icon': Icons.fact_check_outlined},
      {'title': 'Fees', 'icon': Icons.payments_outlined},
      {'title': 'Results', 'icon': Icons.bar_chart_outlined},
      {'title': 'Messaging', 'icon': Icons.message_outlined},
      {'title': 'AI Progress Summary', 'icon': Icons.smart_toy_outlined},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
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
                'Follow your child attendance, results, fees, and messages.',
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
                    title: 'Child Attendance',
                    value: '91%',
                    icon: Icons.fact_check_outlined,
                  ),
                  DashboardCard(
                    title: 'Average Result',
                    value: '15.2',
                    icon: Icons.bar_chart_outlined,
                  ),
                  DashboardCard(
                    title: 'Fee Status',
                    value: 'Paid',
                    icon: Icons.payments_outlined,
                  ),
                  DashboardCard(
                    title: 'Messages',
                    value: '06',
                    icon: Icons.message_outlined,
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
                  return ModuleCard(
                    title: modules[index]['title'] as String,
                    icon: modules[index]['icon'] as IconData,
                    onTap: () {
                      if (modules[index]['title'] == 'Child Overview') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChildOverviewScreen(),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'Attendance') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AttendanceScreen(role: 'Parent'),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'Fees') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeesScreen(),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'Results') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResultsScreen(),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'Messaging') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessagesScreen(role: 'Parent'),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'AI Progress Summary') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AIPerformanceAnalysisScreen(),
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
          if (index == 0) {
            return;
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChildOverviewScreen(),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MessagesScreen(role: 'Parent'),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AIPerformanceAnalysisScreen(),
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
            icon: Icon(Icons.child_care_outlined),
            label: 'Child',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: 'AI',
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