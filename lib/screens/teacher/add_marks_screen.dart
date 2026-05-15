import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class AddMarksScreen extends StatefulWidget {
  const AddMarksScreen({super.key});

  @override
  State<AddMarksScreen> createState() => _AddMarksScreenState();
}

class _AddMarksScreenState extends State<AddMarksScreen> {
  final DatabaseService databaseService = DatabaseService();

  bool isLoading = true;
  bool isLoadingStudents = false;
  bool isLoadingSubjects = false;
  bool isLoadingExistingMarks = false;
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> existingMarks = [];

  String currentUserId = '';
  String currentUserName = '';
  String currentRole = 'Teacher';

  String selectedClassId = '';
  String selectedClassName = '';
  String selectedSubjectId = '';
  String selectedSubjectName = '';
  String selectedTeacherId = '';
  String selectedTeacherName = '';
  double selectedCoefficient = 1;

  final Map<String, TextEditingController> markControllers = {};
  final Map<String, TextEditingController> commentControllers = {};

  bool get isAdmin => currentRole == 'Admin';
  bool get isTeacher => currentRole == 'Teacher';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      loadInitialData();
    });
  }

  @override
  void dispose() {
    clearControllers();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    final authProvider = context.read<AuthProvider>();

    currentUserId = authProvider.userId ?? '';
    currentUserName = authProvider.fullName ?? 'Teacher';
    currentRole = authProvider.role ?? 'Teacher';

    await loadClasses();
  }

  Future<void> loadClasses() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        selectedClassId = '';
        selectedClassName = '';
        selectedSubjectId = '';
        selectedSubjectName = '';
        selectedTeacherId = '';
        selectedTeacherName = '';
        selectedCoefficient = 1;
        subjects = [];
        students = [];
        existingMarks = [];
        clearControllers();
      });

      final loadedClasses = await databaseService.getClasses();

      List<Map<String, dynamic>> scopedClasses = loadedClasses;

      if (isTeacher) {
        scopedClasses = loadedClasses.where((schoolClass) {
          final teacherId = (schoolClass['teacherId'] ?? '').toString();
          final teacherName = (schoolClass['teacherName'] ?? '').toString();

          return teacherId == currentUserId || teacherName == currentUserName;
        }).toList();
      }

      scopedClasses.sort((a, b) {
        return (a['className'] ?? '').toString().compareTo(
              (b['className'] ?? '').toString(),
            );
      });

      if (!mounted) return;

      setState(() {
        classes = scopedClasses;
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

  Future<void> loadSubjectsAndStudents(String classId) async {
    try {
      setState(() {
        isLoadingSubjects = true;
        isLoadingStudents = true;
        isLoadingExistingMarks = false;
        subjects = [];
        students = [];
        existingMarks = [];
        selectedSubjectId = '';
        selectedSubjectName = '';
        selectedTeacherId = '';
        selectedTeacherName = '';
        selectedCoefficient = 1;
        clearControllers();
      });

      final loadedSubjects = await databaseService.getSubjectsByClass(
        classId: classId,
      );

      List<Map<String, dynamic>> scopedSubjects = loadedSubjects;

      if (isTeacher) {
        scopedSubjects = loadedSubjects.where((subject) {
          final teacherId = (subject['teacherId'] ?? '').toString();
          final teacherName = (subject['teacherName'] ?? '').toString();

          return teacherId == currentUserId || teacherName == currentUserName;
        }).toList();
      }

      scopedSubjects.sort((a, b) {
        return (a['subjectName'] ?? '').toString().compareTo(
              (b['subjectName'] ?? '').toString(),
            );
      });

      final loadedStudents = await databaseService.getStudentsByClass(
        classId: classId,
      );

      for (final student in loadedStudents) {
        final studentId = student['id'] ?? '';

        if (studentId.toString().isNotEmpty) {
          markControllers[studentId] = TextEditingController();
          commentControllers[studentId] = TextEditingController();
        }
      }

      if (!mounted) return;

      setState(() {
        subjects = scopedSubjects;
        students = loadedStudents;
        isLoadingSubjects = false;
        isLoadingStudents = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoadingSubjects = false;
        isLoadingStudents = false;
      });
    }
  }

  Future<void> loadExistingMarksForSelectedSubject() async {
    if (selectedClassId.isEmpty || selectedSubjectId.isEmpty) {
      return;
    }

    try {
      setState(() {
        isLoadingExistingMarks = true;
      });

      final loadedMarks = await databaseService.getMarksByClass(
        classId: selectedClassId,
      );

      existingMarks = loadedMarks.where((mark) {
        return mark['subjectId'] == selectedSubjectId;
      }).toList();

      for (final student in students) {
        final studentId = student['id'] ?? '';

        if (studentId.toString().isEmpty) {
          continue;
        }

        Map<String, dynamic>? savedMark;

        try {
          savedMark = existingMarks.firstWhere(
            (mark) => mark['studentId'] == studentId,
          );
        } catch (_) {
          savedMark = null;
        }

        if (savedMark != null) {
          final markValue = parseNumber(savedMark['mark']);
          final commentValue = savedMark['comment'] ?? '';

          markControllers[studentId]?.text =
              markValue.toStringAsFixed(markValue % 1 == 0 ? 0 : 1);
          commentControllers[studentId]?.text = commentValue.toString();
        } else {
          markControllers[studentId]?.clear();
          commentControllers[studentId]?.clear();
        }
      }

      if (!mounted) return;

      setState(() {
        isLoadingExistingMarks = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingExistingMarks = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearControllers() {
    for (final controller in markControllers.values) {
      controller.dispose();
    }

    for (final controller in commentControllers.values) {
      controller.dispose();
    }

    markControllers.clear();
    commentControllers.clear();
  }

  double parseNumber(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0;
  }

  double parseCoefficient(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;

    final parsed = double.tryParse(value.toString());

    if (parsed == null || parsed <= 0) {
      return 1;
    }

    return parsed;
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

    loadSubjectsAndStudents(value);
  }

  void selectSubject(String? value) {
    if (value == null) return;

    final selectedSubject = subjects.firstWhere(
      (subject) => subject['id'] == value,
      orElse: () => {},
    );

    setState(() {
      selectedSubjectId = value;
      selectedSubjectName = selectedSubject['subjectName'] ?? '';

      selectedTeacherId = selectedSubject['teacherId'] ?? currentUserId;
      selectedTeacherName = selectedSubject['teacherName'] ?? currentUserName;
      selectedCoefficient = parseCoefficient(
        selectedSubject['coefficient'] ?? selectedSubject['coeff'] ?? 1,
      );

      if (selectedTeacherId.toString().isEmpty) {
        selectedTeacherId = currentUserId;
      }

      if (selectedTeacherName.toString().isEmpty) {
        selectedTeacherName = currentUserName;
      }
    });

    loadExistingMarksForSelectedSubject();
  }

  String gradeFromMark(double mark) {
    if (mark >= 16) return 'Excellent';
    if (mark >= 14) return 'Good';
    if (mark >= 10) return 'Pass';
    return 'Weak';
  }

  String progressFromMark(double mark) {
    if (mark >= 16) return 'Excellent';
    if (mark >= 14) return 'Good';
    if (mark >= 10) return 'Average';
    return 'Needs Support';
  }

  Future<void> saveMarks() async {
    if (selectedClassId.isEmpty) {
      showSnackBar('Please select a class');
      return;
    }

    if (selectedSubjectId.isEmpty) {
      showSnackBar('Please select a subject');
      return;
    }

    if (students.isEmpty) {
      showSnackBar('No students found for this class');
      return;
    }

    if (isTeacher && selectedTeacherId != currentUserId) {
      showSnackBar('You can only save marks for subjects assigned to you.');
      return;
    }

    final marksData = <Map<String, dynamic>>[];

    for (final student in students) {
      final studentId = student['id'] ?? '';
      final markText = markControllers[studentId]?.text.trim() ?? '';
      final comment = commentControllers[studentId]?.text.trim() ?? '';

      if (markText.isEmpty) {
        continue;
      }

      final mark = double.tryParse(markText);

      if (mark == null || mark < 0 || mark > 20) {
        showSnackBar(
          'Invalid mark for ${student['fullName']}. Use a value between 0 and 20.',
        );
        return;
      }

      marksData.add({
        'studentId': studentId,
        'studentName': student['fullName'] ?? 'Unknown Student',
        'mark': mark,
        'grade': gradeFromMark(mark),
        'progress': progressFromMark(mark),
        'comment': comment,
        'coefficient': selectedCoefficient,
      });
    }

    if (marksData.isEmpty) {
      showSnackBar('Please enter at least one mark');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await databaseService.saveMarks(
        classId: selectedClassId,
        className: selectedClassName,
        subjectId: selectedSubjectId,
        subjectName: selectedSubjectName,
        teacherId: selectedTeacherId.isEmpty ? currentUserId : selectedTeacherId,
        teacherName:
            selectedTeacherName.isEmpty ? currentUserName : selectedTeacherName,
        marksData: marksData,
      );

      await loadExistingMarksForSelectedSubject();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar('Marks saved successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
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
    String title = 'Add Marks';
    String subtitle = 'Select a class, subject, and enter student marks.';

    if (isAdmin) {
      title = 'Manage Student Marks';
      subtitle = 'Review and manage marks for students by class and subject.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.darkBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                    'assets/icons/add_marks.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.edit_note_outlined,
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
                      '$subtitle ${students.length} student(s) loaded.',
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

  Color markColorFromText(String studentId) {
    final text = markControllers[studentId]?.text.trim() ?? '';
    final value = double.tryParse(text);

    if (value == null) return AppColors.primaryBlue;
    if (value >= 14) return AppColors.softGreen;
    if (value >= 10) return Colors.orange;
    return AppColors.danger;
  }

  Widget emptyStateBox({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/add_marks.png',
              fallbackIcon: icon,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyClassState() {
    if (isTeacher) {
      return emptyStateBox(
        title: 'No assigned classes',
        message:
            'No class is assigned to your teacher account yet. Ask Admin to assign you to a class.',
        icon: Icons.class_outlined,
      );
    }

    return emptyStateBox(
      title: 'No classes yet',
      message: 'No classes found yet. Create a class first from Admin Dashboard.',
      icon: Icons.class_outlined,
    );
  }

  Widget emptyStudentState() {
    return emptyStateBox(
      title: 'No students found',
      message:
          'No students found for this class. Assign students to this class from User Management first.',
      icon: Icons.people_outline,
    );
  }

  Widget markCard(Map<String, dynamic> student) {
    final studentId = student['id'] ?? '';
    final studentName = student['fullName'] ?? 'Unknown Student';
    final color = markColorFromText(studentId);
    final hasExistingMark = existingMarks.any((mark) {
      return mark['studentId'] == studentId;
    });

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
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
        child: Stack(
          children: [
            Positioned(
              top: -26,
              right: -24,
              child: Container(
                height: 82,
                width: 82,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.045),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    pngIconBox(
                      imagePath: 'assets/icons/student.png',
                      fallbackIcon: Icons.person_outline,
                      color: color,
                      size: 54,
                      padding: 11,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.25,
                        ),
                      ),
                    ),
                    smallStatusChip(
                      text: hasExistingMark ? 'Updating' : 'New',
                      color: hasExistingMark ? Colors.orange : AppColors.softGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: markControllers[studentId],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Mark / 20',
                    prefixIcon: Icon(Icons.grade_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentControllers[studentId],
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Teacher Comment / Progress Note',
                    prefixIcon: Icon(Icons.comment_outlined),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget subjectInfoCard() {
    if (selectedSubjectId.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          pngIconBox(
            imagePath: 'assets/icons/results.png',
            fallbackIcon: Icons.info_outline,
            size: 46,
            padding: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Subject: $selectedSubjectName • Teacher: $selectedTeacherName • Coefficient: ${selectedCoefficient.toStringAsFixed(selectedCoefficient % 1 == 0 ? 0 : 1)}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add Marks';

    if (isAdmin) {
      title = 'Manage Student Marks';
    }

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
                : classes.isEmpty
                    ? emptyClassState()
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                headerCard(),
                                const SizedBox(height: 18),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedClassId.isEmpty
                                      ? null
                                      : selectedClassId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Class',
                                    prefixIcon: Icon(Icons.class_outlined),
                                  ),
                                  items: classes.map((schoolClass) {
                                    return DropdownMenuItem<String>(
                                      value: schoolClass['id'],
                                      child: Text(
                                        schoolClass['className'] ??
                                            'Unnamed Class',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: selectClass,
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedSubjectId.isEmpty
                                      ? null
                                      : selectedSubjectId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Subject',
                                    prefixIcon: Icon(Icons.menu_book_outlined),
                                  ),
                                  items: subjects.map((subject) {
                                    return DropdownMenuItem<String>(
                                      value: subject['id'],
                                      child: Text(
                                        subject['subjectName'] ??
                                            'Unnamed Subject',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged:
                                      subjects.isEmpty ? null : selectSubject,
                                ),
                                if (selectedClassId.isNotEmpty &&
                                    subjects.isEmpty &&
                                    !isLoadingSubjects) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    isTeacher
                                        ? 'No subjects assigned to you for this class.'
                                        : 'No subjects found for this class. Create a subject first.',
                                    style: const TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                subjectInfoCard(),
                              ],
                            ),
                          ),
                          if (selectedClassId.isEmpty)
                            Expanded(
                              child: emptyStateBox(
                                title: 'Select a class',
                                message:
                                    'Choose a class to load subjects and students.',
                                icon: Icons.class_outlined,
                              ),
                            )
                          else if (isLoadingStudents ||
                              isLoadingSubjects ||
                              isLoadingExistingMarks)
                            const Expanded(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (students.isEmpty)
                            Expanded(
                              child: emptyStudentState(),
                            )
                          else
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  await loadSubjectsAndStudents(
                                    selectedClassId,
                                  );

                                  if (selectedSubjectId.isNotEmpty) {
                                    await loadExistingMarksForSelectedSubject();
                                  }
                                },
                                child: ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 0, 18, 90),
                                  itemCount: students.length,
                                  separatorBuilder: (context, index) {
                                    return const SizedBox(height: 12);
                                  },
                                  itemBuilder: (context, index) {
                                    return markCard(students[index]);
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : saveMarks,
              icon: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                isSaving ? 'Saving...' : 'Save Marks',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
