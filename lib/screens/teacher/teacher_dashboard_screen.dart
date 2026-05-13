import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/module_card.dart';
import '../../widgets/section_title.dart';
import '../ai/ai_assistant_screen.dart';
import '../common/profile_screen.dart';
import '../common/messages_screen.dart';
import 'assignments_screen.dart';
import 'attendance_screen.dart';
import 'add_marks_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  final String displayName;

  const TeacherDashboardScreen({
    super.key,
    this.displayName = 'Teacher',
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      {'title': 'My Classes', 'icon': Icons.class_outlined},
      {'title': 'Attendance', 'icon': Icons.fact_check_outlined},
      {'title': 'Add Marks', 'icon': Icons.edit_note_outlined},
      {'title': 'Assignments', 'icon': Icons.assignment_outlined},
      {'title': 'Messages', 'icon': Icons.message_outlined},
      {'title': 'AI Teaching Assistant', 'icon': Icons.smart_toy_outlined},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
                'Manage classes, attendance, marks, and assignments.',
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
                    title: 'My Classes',
                    value: '05',
                    icon: Icons.class_outlined,
                  ),
                  DashboardCard(
                    title: 'Today Attendance',
                    value: '92%',
                    icon: Icons.fact_check_outlined,
                  ),
                  DashboardCard(
                    title: 'Pending Tasks',
                    value: '12',
                    icon: Icons.assignment_late_outlined,
                  ),
                  DashboardCard(
                    title: 'Marks Added',
                    value: '68',
                    icon: Icons.grade_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const SectionTitle(title: 'Teaching Modules'),
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
                      if (modules[index]['title'] == 'Attendance') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AttendanceScreen(role: 'Teacher'),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'Add Marks') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddMarksScreen(),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'Assignments') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignmentsScreen(role: 'Teacher'),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'Messages') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const MessagesScreen(role: 'Teacher'),
                          ),
                        );
                      }

                      if (modules[index]['title'] == 'AI Teaching Assistant') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AIAssistantScreen(),
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

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AttendanceScreen(role: 'Teacher'),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AIAssistantScreen(),
              ),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(role: 'Teacher'),
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
            icon: Icon(Icons.class_outlined),
            label: 'Classes',
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
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}