import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final DatabaseService databaseService = DatabaseService();

  bool isLoading = true;
  bool isLoadingStudents = false;
  bool isLoadingMarks = false;

  String? errorMessage;

  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> marks = [];

  String selectedClassId = '';
  String selectedClassName = '';
  String selectedStudentId = '';
  String selectedStudentName = '';

  bool isStudentRole = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadInitialData();
    });
  }

  Future<void> loadInitialData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentRole = authProvider.role ?? 'Student';
      final currentUserId = authProvider.userId ?? '';

      setState(() {
        isLoading = true;
        errorMessage = null;
        isStudentRole = currentRole == 'Student';
      });

      if (currentRole == 'Student') {
        selectedStudentId = currentUserId;
        selectedStudentName = authProvider.fullName ?? 'Student';

        final loadedMarks = await databaseService.getMarksByStudent(
          studentId: currentUserId,
        );

        if (!mounted) return;

        setState(() {
          marks = loadedMarks;
          isLoading = false;
        });

        return;
      }

      final loadedClasses = await databaseService.getClasses();

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

  Future<void> loadStudentsByClass(String classId) async {
    try {
      setState(() {
        isLoadingStudents = true;
        students = [];
        marks = [];
        selectedStudentId = '';
        selectedStudentName = '';
      });

      final loadedStudents = await databaseService.getStudentsByClass(
        classId: classId,
      );

      if (!mounted) return;

      setState(() {
        students = loadedStudents;
        isLoadingStudents = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoadingStudents = false;
      });
    }
  }

  Future<void> loadMarksByStudent(String studentId) async {
    try {
      setState(() {
        isLoadingMarks = true;
        marks = [];
      });

      final loadedMarks = await databaseService.getMarksByStudent(
        studentId: studentId,
      );

      if (!mounted) return;

      setState(() {
        marks = loadedMarks;
        isLoadingMarks = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoadingMarks = false;
      });
    }
  }

  void selectClass(String? value) {
    if (value == null) return;

    final selectedClass = classes.firstWhere(
      (schoolClass) => schoolClass['id'] == value,
      orElse: () => {},
    );

    setState(() {
      selectedClassId = value;
      selectedClassName = selectedClass['className'] ?? '';
    });

    loadStudentsByClass(value);
  }

  void selectStudent(String? value) {
    if (value == null) return;

    final selectedStudent = students.firstWhere(
      (student) => student['id'] == value,
      orElse: () => {},
    );

    setState(() {
      selectedStudentId = value;
      selectedStudentName = selectedStudent['fullName'] ?? '';
    });

    loadMarksByStudent(value);
  }

  double calculateAverage() {
    if (marks.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final mark in marks) {
      final value = mark['mark'];

      if (value is int) {
        total += value.toDouble();
      } else if (value is double) {
        total += value;
      } else {
        total += double.tryParse(value.toString()) ?? 0;
      }
    }

    return total / marks.length;
  }

  String averageStatus(double average) {
    if (average >= 16) return 'Excellent';
    if (average >= 14) return 'Good';
    if (average >= 10) return 'Pass';
    return 'Needs Improvement';
  }

  Color averageColor(double average) {
    if (average >= 14) return AppColors.softGreen;
    if (average >= 10) return Colors.orange;
    return AppColors.danger;
  }

  Widget summaryCard() {
    final average = calculateAverage();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.bar_chart_outlined,
              color: AppColors.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStudentName.isEmpty
                      ? 'Student Results'
                      : '$selectedStudentName Results',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  marks.isEmpty
                      ? 'No marks available yet'
                      : 'Average: ${average.toStringAsFixed(2)}/20',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          if (marks.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: averageColor(average).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                averageStatus(average),
                style: TextStyle(
                  color: averageColor(average),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget markCard(Map<String, dynamic> mark) {
    final subjectName = mark['subjectName'] ?? 'Unknown Subject';
    final teacherName = mark['teacherName'] ?? 'Unknown Teacher';
    final className = mark['className'] ?? '';
    final value = mark['mark'] ?? 0;
    final grade = mark['grade'] ?? '';
    final comment = mark['comment'] ?? '';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.grade_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  className.isEmpty ? 'No class' : className,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Teacher: $teacherName',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
                if (comment.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Comment: $comment',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value/20',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(
                    color: AppColors.softGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget nonStudentSelectors() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedClassId.isEmpty ? null : selectedClassId,
          decoration: const InputDecoration(
            labelText: 'Select Class',
            prefixIcon: Icon(Icons.class_outlined),
          ),
          items: classes.map((schoolClass) {
            return DropdownMenuItem<String>(
              value: schoolClass['id'],
              child: Text(
                schoolClass['className'] ?? 'Unnamed Class',
              ),
            );
          }).toList(),
          onChanged: selectClass,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: selectedStudentId.isEmpty ? null : selectedStudentId,
          decoration: const InputDecoration(
            labelText: 'Select Student',
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: students.map((student) {
            return DropdownMenuItem<String>(
              value: student['id'],
              child: Text(
                student['fullName'] ?? 'Unknown Student',
              ),
            );
          }).toList(),
          onChanged: students.isEmpty ? null : selectStudent,
        ),
        if (selectedClassId.isNotEmpty && students.isEmpty && !isLoadingStudents)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'No students found for this class.',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget emptyMarksState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No results found yet. Marks added by teachers will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : () {
                    if (isStudentRole) {
                      loadInitialData();
                    } else if (selectedStudentId.isNotEmpty) {
                      loadMarksByStudent(selectedStudentId);
                    } else {
                      loadInitialData();
                    }
                  },
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
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            if (!isStudentRole) nonStudentSelectors(),
                            if (!isStudentRole) const SizedBox(height: 18),
                            summaryCard(),
                          ],
                        ),
                      ),
                      if (isLoadingStudents || isLoadingMarks)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (marks.isEmpty)
                        Expanded(
                          child: emptyMarksState(),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                            itemCount: marks.length,
                            separatorBuilder: (context, index) {
                              return const SizedBox(height: 12);
                            },
                            itemBuilder: (context, index) {
                              return markCard(marks[index]);
                            },
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}