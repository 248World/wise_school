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
import '../student/timetable_screen.dart';
import 'add_marks_screen.dart';
import 'assignments_screen.dart';
import 'attendance_screen.dart';
import 'my_classes_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String displayName;

  const TeacherDashboardScreen({
    super.key,
    this.displayName = 'Teacher',
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoadingStats = true;

  String teacherId = '';

  int classesCount = 0;
  int assignmentsCount = 0;
  int notificationsCount = 0;
  int timetableCount = 0;

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
      teacherId = authProvider.userId ?? '';

      if (teacherId.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingStats = false;
        });

        return;
      }

      final classesSnapshot = await firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final timetableSnapshot = await firestore
          .collection('timetables')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final assignmentsSnapshot = await firestore
          .collection('assignments')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final notificationsSnapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: teacherId)
          .where('isRead', isEqualTo: false)
          .get();

      if (!mounted) return;

      setState(() {
        classesCount = classesSnapshot.docs.length;
        timetableCount = timetableSnapshot.docs.length;
        assignmentsCount = assignmentsSnapshot.docs.length;
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
        'title': 'My Classes',
        'icon': Icons.groups_2_outlined,
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
        'title': 'Add Marks',
        'icon': Icons.edit_note_outlined,
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment_outlined,
      },
      {
        'title': 'Announcements',
        'icon': Icons.campaign_outlined,
      },
      {
        'title': 'Admin Chat',
        'icon': Icons.chat_bubble_outline,
      },
      {
        'title': 'Notifications',
        'icon': Icons.notifications_outlined,
      },
      {
        'title': 'Profile',
        'icon': Icons.account_circle_outlined,
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
        title: const Text('Teacher Dashboard'),
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
                'Manage your classes, timetable, attendance, marks, assignments, announcements, notifications, and messages.',
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
                    title: 'My Classes',
                    value: statValue(classesCount),
                    icon: Icons.groups_2_outlined,
                  ),
                  DashboardCard(
                    title: 'Timetable',
                    value: statValue(timetableCount),
                    icon: Icons.calendar_month_outlined,
                  ),
                  DashboardCard(
                    title: 'Assignments',
                    value: statValue(assignmentsCount),
                    icon: Icons.assignment_outlined,
                  ),
                  DashboardCard(
                    title: 'Unread Notices',
                    value: statValue(notificationsCount),
                    icon: Icons.notifications_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const SectionTitle(title: 'Teacher Modules'),
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
                      if (title == 'Add Marks') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddMarksScreen(),
                          ),
                        );
                      }

                      if (title == 'Admin Chat') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessagesScreen(
                              role: 'Teacher',
                              targetRole: 'Admin',
                            ),
                          ),
                        );
                      }

                      if (title == 'Announcements') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AnnouncementsScreen(role: 'Teacher'),
                          ),
                        );
                      }

                      if (title == 'Assignments') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AssignmentsScreen(role: 'Teacher'),
                          ),
                        );
                      }

                      if (title == 'Attendance') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AttendanceScreen(role: 'Teacher'),
                          ),
                        );
                      }

                      if (title == 'My Classes') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyClassesScreen(
                              teacherName: widget.displayName,
                            ),
                          ),
                        );
                      }

                      if (title == 'Notifications') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsScreen(role: 'Teacher'),
                          ),
                        );
                      }

                      if (title == 'Profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfileScreen(role: 'Teacher'),
                          ),
                        );
                      }

                      if (title == 'Timetable') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TimetableScreen(role: 'Teacher'),
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
                builder: (_) => const TimetableScreen(role: 'Teacher'),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AssignmentsScreen(role: 'Teacher'),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(role: 'Teacher'),
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