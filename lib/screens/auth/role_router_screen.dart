import 'package:flutter/material.dart';
import '../admin/admin_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../parent/parent_dashboard_screen.dart';

class RoleRouterScreen extends StatelessWidget {
  final String role;
  final String displayName;

  const RoleRouterScreen({
    super.key,
    required this.role,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    if (role == 'Admin') {
      return AdminDashboardScreen(displayName: displayName);
    } else if (role == 'Teacher') {
      return TeacherDashboardScreen(displayName: displayName);
    } else if (role == 'Parent') {
      return ParentDashboardScreen(displayName: displayName);
    } else {
      return StudentDashboardScreen(displayName: displayName);
    }
  }
}