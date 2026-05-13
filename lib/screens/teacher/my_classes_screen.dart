import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';

class MyClassesScreen extends StatefulWidget {
  final String teacherName;

  const MyClassesScreen({
    super.key,
    required this.teacherName,
  });

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  final DatabaseService databaseService = DatabaseService();

  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> classes = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedClasses = await databaseService.getClassesByTeacher(
        teacherName: widget.teacherName,
      );

      if (!mounted) return;

      setState(() {
        classes = loadedClasses;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Widget emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No classes assigned to ${widget.teacherName} yet. Ask Admin to assign this teacher to a class.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget classCard(Map<String, dynamic> item) {
    final className = item['className'] ?? 'Unnamed Class';
    final level = item['level'] ?? 'No level';
    final studentCount = item['studentCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.class_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  level,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Teacher: ${widget.teacherName}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$studentCount Students',
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadClasses,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : classes.isEmpty
                    ? emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                        itemCount: classes.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 12);
                        },
                        itemBuilder: (context, index) {
                          return classCard(classes[index]);
                        },
                      ),
      ),
    );
  }
}