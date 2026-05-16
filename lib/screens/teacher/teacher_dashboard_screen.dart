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
  String teacherName = '';

  int classesCount = 0;
  int assignmentsCount = 0;
  int notificationsCount = 0;
  int timetableCount = 0;
  int attendanceCount = 0;
  int subjectsCount = 0;

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
      teacherName = authProvider.fullName ?? widget.displayName;

      if (!mounted) return;

      setState(() {
        isLoadingStats = true;
      });

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

      final subjectsSnapshot = await firestore
          .collection('subjects')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final attendanceSnapshot = await firestore
          .collection('attendance')
          .where('markedById', isEqualTo: teacherId)
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
        subjectsCount = subjectsSnapshot.docs.length;
        attendanceCount = attendanceSnapshot.docs.length;
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

  void openModule(String title) {
    if (title == 'Add Marks') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddMarksScreen(),
        ),
      );
      return;
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
      return;
    }

    if (title == 'Announcements') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AnnouncementsScreen(role: 'Teacher'),
        ),
      );
      return;
    }

    if (title == 'Assignments') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AssignmentsScreen(role: 'Teacher'),
        ),
      );
      return;
    }

    if (title == 'Attendance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AttendanceScreen(role: 'Teacher'),
        ),
      );
      return;
    }

    if (title == 'My Classes') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyClassesScreen(
            teacherName: teacherName.isEmpty ? widget.displayName : teacherName,
          ),
        ),
      );
      return;
    }

    if (title == 'Notifications') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NotificationsScreen(role: 'Teacher'),
        ),
      );
      return;
    }

    if (title == 'Profile') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(role: 'Teacher'),
        ),
      );
      return;
    }

    if (title == 'Timetable') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TimetableScreen(role: 'Teacher'),
        ),
      );
      return;
    }
  }

  Widget headerCard() {
    final nameToShow = teacherName.isEmpty ? widget.displayName : teacherName;

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
                    'assets/icons/teacher.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person_4_outlined,
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
                      'Welcome, $nameToShow',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your assigned classes, marks, attendance, assignments, timetable, and communication.',
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

  Widget noClassNotice() {
    if (classesCount > 0 || isLoadingStats) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primaryBlue,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No class is assigned to your teacher account yet. Some modules may appear empty until Admin assigns you to a class and subject.',
              style: TextStyle(
                color: AppColors.textGrey,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
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
        'title': 'Admin Chat',
        'icon': Icons.chat_bubble_outline,
        'imagePath': 'assets/icons/admin_chat.png',
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
      },
      {
        'title': 'Attendance',
        'icon': Icons.fact_check_outlined,
        'imagePath': 'assets/icons/attendance.png',
      },
      {
        'title': 'My Classes',
        'icon': Icons.groups_2_outlined,
        'imagePath': 'assets/icons/classes.png',
      },
      {
        'title': 'Notifications',
        'icon': Icons.notifications_outlined,
        'imagePath': 'assets/icons/notifications.png',
        'badgeText':
            notificationsCount > 0 ? notificationsCount.toString() : null,
      },
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
        child: RefreshIndicator(
          onRefresh: loadDashboardStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerCard(),
                noClassNotice(),
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
                      imagePath: 'assets/icons/classes.png',
                    ),
                    DashboardCard(
                      title: 'Subjects',
                      value: statValue(subjectsCount),
                      icon: Icons.menu_book_outlined,
                      imagePath: 'assets/icons/subjects.png',
                    ),
                    DashboardCard(
                      title: 'Assignments',
                      value: statValue(assignmentsCount),
                      icon: Icons.assignment_outlined,
                      imagePath: 'assets/icons/assignments.png',
                    ),
                    DashboardCard(
                      title: 'Timetable',
                      value: statValue(timetableCount),
                      icon: Icons.calendar_month_outlined,
                      imagePath: 'assets/icons/timetable.png',
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const SectionTitle(
                  title: 'Teacher Modules',
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
                    final module = modules[index];
                    final title = module['title'] as String;

                    return ModuleCard(
                      title: title,
                      icon: module['icon'] as IconData,
                      imagePath: module['imagePath'] as String,
                      badgeText: module['badgeText'] as String?,
                      onTap: () {
                        openModule(title);
                      },
                    );
                  },
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
                builder: (_) => const TimetableScreen(role: 'Teacher'),
              ),
            );
            return;
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AttendanceScreen(role: 'Teacher'),
              ),
            );
            return;
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AssignmentsScreen(role: 'Teacher'),
              ),
            );
            return;
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(role: 'Teacher'),
              ),
            );
            return;
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
            icon: Icon(Icons.fact_check_outlined),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
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
