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
  String selectedStudentId = '';
  String selectedStudentName = '';

  String currentRole = 'Student';
  String currentUserId = '';
  String currentUserName = '';

  bool get isStudent => currentRole == 'Student';
  bool get isParent => currentRole == 'Parent';

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

      currentRole = authProvider.role ?? 'Student';
      currentUserId = authProvider.userId ?? '';
      currentUserName = authProvider.fullName ?? currentRole;

      setState(() {
        isLoading = true;
        errorMessage = null;
        marks = [];
        students = [];
        classes = [];
        selectedClassId = '';
        selectedStudentId = '';
        selectedStudentName = '';
      });

      if (currentRole == 'Student') {
        selectedStudentId = currentUserId;
        selectedStudentName = currentUserName;

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

      if (currentRole == 'Parent') {
        final loadedChildren = await databaseService.getStudentsByParent(
          parentId: currentUserId,
        );

        if (!mounted) return;

        students = loadedChildren;

        if (students.length == 1) {
          selectedStudentId = students.first['id'] ?? '';
          selectedStudentName = students.first['fullName'] ?? '';

          final loadedMarks = await databaseService.getMarksByStudent(
            studentId: selectedStudentId,
          );

          if (!mounted) return;

          setState(() {
            marks = loadedMarks;
            isLoading = false;
          });

          return;
        }

        setState(() {
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

    setState(() {
      selectedClassId = value;
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

  double parseNumber(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0;
  }

  double calculateAverage() {
    if (marks.isEmpty) return 0;

    double weightedTotal = 0;
    double coefficientTotal = 0;

    for (final mark in marks) {
      final value = parseNumber(mark['mark']);
      final coefficient = parseNumber(mark['coefficient']);
      final safeCoefficient = coefficient <= 0 ? 1 : coefficient;

      weightedTotal += value * safeCoefficient;
      coefficientTotal += safeCoefficient;
    }

    if (coefficientTotal == 0) return 0;

    return weightedTotal / coefficientTotal;
  }

  String progressStatus(double average) {
    if (average >= 16) return 'Excellent Progress';
    if (average >= 14) return 'Good Progress';
    if (average >= 10) return 'Average Progress';
    return 'Needs Support';
  }

  String progressFromMark(double mark) {
    if (mark >= 16) return 'Excellent';
    if (mark >= 14) return 'Good';
    if (mark >= 10) return 'Average';
    return 'Needs Support';
  }

  Color progressColor(double average) {
    if (average >= 14) return AppColors.softGreen;
    if (average >= 10) return Colors.orange;
    return AppColors.danger;
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
    String title = 'Results';
    String subtitle = 'View marks, averages, and academic progress.';

    if (currentRole == 'Admin') {
      title = 'All Student Results';
      subtitle = 'Select a class and student to review results.';
    }

    if (currentRole == 'Teacher') {
      title = 'Student Results';
      subtitle = 'Select a class and student to review marks.';
    }

    if (currentRole == 'Parent') {
      title = 'Child Results';
      subtitle = 'Follow your child marks and progress.';
    }

    if (currentRole == 'Student') {
      title = 'My Results';
      subtitle = 'Track your marks, comments, and progress.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.darkBlue,
          ],
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
                    'assets/icons/results.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.bar_chart_outlined,
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
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$subtitle ${marks.length} mark(s) found.',
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

  Widget smallStatusChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget detailLine({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.textGrey,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget selectorSection() {
    if (isStudent) {
      return const SizedBox();
    }

    if (isParent) {
      if (students.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'No child is assigned to this parent account yet. Ask Admin to assign a student to this parent.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        );
      }

      if (students.length == 1) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Child: $selectedStudentName',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }

      return DropdownButtonFormField<String>(
        initialValue: selectedStudentId.isEmpty ? null : selectedStudentId,
        decoration: const InputDecoration(
          labelText: 'Select Child',
          prefixIcon: Icon(Icons.child_care_outlined),
        ),
        items: students.map((student) {
          return DropdownMenuItem<String>(
            value: student['id'],
            child: Text(student['fullName'] ?? 'Unknown Child'),
          );
        }).toList(),
        onChanged: selectStudent,
      );
    }

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

  Widget summaryCard() {
    final average = calculateAverage();
    final status = progressStatus(average);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          pngIconBox(
            imagePath: 'assets/icons/results.png',
            fallbackIcon: Icons.bar_chart_outlined,
            size: 58,
            padding: 12,
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
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  marks.isEmpty
                      ? 'No marks available yet'
                      : 'Weighted Average: ${average.toStringAsFixed(2)}/20',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    height: 1.35,
                  ),
                ),
                if (marks.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      smallStatusChip(
                        text: 'Subjects: ${marks.length}',
                        color: AppColors.primaryBlue,
                      ),
                      smallStatusChip(
                        text: status,
                        color: progressColor(average),
                      ),
                    ],
                  ),
                ],
              ],
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
    final value = parseNumber(mark['mark']);
    final grade = mark['grade'] ?? progressFromMark(value);
    final comment = mark['comment'] ?? '';
    final coefficient = parseNumber(mark['coefficient']);
    final progress = mark['progress'] ?? progressFromMark(value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pngIconBox(
            imagePath: 'assets/icons/results.png',
            fallbackIcon: Icons.grade_outlined,
            color: progressColor(value),
            size: 56,
            padding: 11,
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
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    smallStatusChip(
                      text:
                          '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}/20',
                      color: progressColor(value),
                    ),
                    smallStatusChip(
                      text: grade.toString(),
                      color: progressColor(value),
                    ),
                    smallStatusChip(
                      text: 'Progress: $progress',
                      color: progressColor(value),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                detailLine(
                  icon: Icons.class_outlined,
                  text: className.isEmpty ? 'No class' : className,
                ),
                const SizedBox(height: 6),
                detailLine(
                  icon: Icons.person_outline,
                  text: 'Teacher: $teacherName',
                ),
                if (coefficient > 0) ...[
                  const SizedBox(height: 6),
                  detailLine(
                    icon: Icons.tune_outlined,
                    text:
                        'Coefficient: ${coefficient.toStringAsFixed(coefficient % 1 == 0 ? 0 : 1)}',
                  ),
                ],
                if (comment.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Teacher Comment: $comment',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyMarksState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/results.png',
              fallbackIcon: Icons.bar_chart_outlined,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'No results yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Marks, teacher comments, and progress will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Results';

    if (currentRole == 'Admin') title = 'All Student Results';
    if (currentRole == 'Teacher') title = 'Student Results';
    if (currentRole == 'Parent') title = 'Child Results';
    if (currentRole == 'Student') title = 'My Results';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadInitialData,
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
                            headerCard(),
                            if (!isStudent) ...[
                              const SizedBox(height: 18),
                              selectorSection(),
                            ],
                            const SizedBox(height: 18),
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
                          child: RefreshIndicator(
                            onRefresh: loadInitialData,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 0, 18, 24),
                              itemCount: marks.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 12);
                              },
                              itemBuilder: (context, index) {
                                return markCard(marks[index]);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
