import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../admin/admin_dashboard_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';

class RoleRouterScreen extends StatefulWidget {
  final String role;
  final String displayName;

  const RoleRouterScreen({
    super.key,
    required this.role,
    required this.displayName,
  });

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      openDashboard();
    });
  }

  Future<void> openDashboard() async {
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => dashboardByRole(),
      ),
    );
  }

  Widget dashboardByRole() {
    final normalizedRole = widget.role.trim().toLowerCase();

    switch (normalizedRole) {
      case 'admin':
        return AdminDashboardScreen(
          displayName: widget.displayName,
        );

      case 'teacher':
        return TeacherDashboardScreen(
          displayName: widget.displayName,
        );

      case 'parent':
        return ParentDashboardScreen(
          displayName: widget.displayName,
        );

      case 'student':
        return StudentDashboardScreen(
          displayName: widget.displayName,
        );

      default:
        return StudentDashboardScreen(
          displayName: widget.displayName,
        );
    }
  }

  Widget bubble({
    required double size,
    required double opacity,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  String roleLabel() {
    final cleanRole = widget.role.trim();

    if (cleanRole.isEmpty) {
      return 'Student';
    }

    return cleanRole[0].toUpperCase() + cleanRole.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.authGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 48,
              left: 34,
              child: bubble(size: 8, opacity: 0.14),
            ),
            Positioned(
              top: 88,
              right: 44,
              child: bubble(size: 58, opacity: 0.10),
            ),
            Positioned(
              top: 150,
              left: -48,
              child: bubble(size: 170, opacity: 0.08),
            ),
            Positioned(
              top: 260,
              right: -58,
              child: bubble(size: 165, opacity: 0.08),
            ),
            Positioned(
              bottom: 150,
              left: 70,
              child: bubble(size: 58, opacity: 0.10),
            ),
            Positioned(
              bottom: 96,
              right: 62,
              child: bubble(size: 42, opacity: 0.12),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 98,
                      width: 98,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.white,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Welcome, ${widget.displayName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Opening your ${roleLabel()} dashboard...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 24,
              right: 24,
              bottom: 34,
              child: SafeArea(
                top: false,
                child: Text(
                  'Preparing your Wise School workspace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}