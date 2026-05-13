import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> students = [];

  String selectedClassId = '';
  String selectedClassName = '';
  String selectedSubjectId = '';
  String selectedSubjectName = '';
  String selectedTeacherId = '';
  String selectedTeacherName = '';

  final Map<String, TextEditingController> markControllers = {};
  final Map<String, TextEditingController> commentControllers = {};

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  @override
  void dispose() {
    for (final controller in markControllers.values) {
      controller.dispose();
    }

    for (final controller in commentControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> loadClasses() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

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

  Future<void> loadSubjectsAndStudents(String classId) async {
    try {
      setState(() {
        isLoadingSubjects = true;
        isLoadingStudents = true;
        subjects = [];
        students = [];
        selectedSubjectId = '';
        selectedSubjectName = '';
        selectedTeacherId = '';
        selectedTeacherName = '';
        clearControllers();
      });

      final loadedSubjects = await databaseService.getSubjectsByClass(
        classId: classId,
      );

      final loadedStudents = await databaseService.getStudentsByClass(
        classId: classId,
      );

      for (final student in loadedStudents) {
        final studentId = student['id'] ?? '';

        markControllers[studentId] = TextEditingController();
        commentControllers[studentId] = TextEditingController();
      }

      if (!mounted) return;

      setState(() {
        subjects = loadedSubjects;
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
      selectedTeacherId = selectedSubject['teacherId'] ?? '';
      selectedTeacherName = selectedSubject['teacherName'] ?? '';
    });
  }

  String gradeFromMark(double mark) {
    if (mark >= 16) return 'Excellent';
    if (mark >= 14) return 'Good';
    if (mark >= 10) return 'Pass';
    return 'Weak';
  }

  Future<void> saveMarks() async {
    if (selectedClassId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class'),
        ),
      );
      return;
    }

    if (selectedSubjectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject'),
        ),
      );
      return;
    }

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found for this class'),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid mark for ${student['fullName']}. Use a value between 0 and 20.',
            ),
          ),
        );
        return;
      }

      marksData.add({
        'studentId': studentId,
        'studentName': student['fullName'] ?? 'Unknown Student',
        'mark': mark,
        'grade': gradeFromMark(mark),
        'comment': comment,
      });
    }

    if (marksData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one mark'),
        ),
      );
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
        teacherId: selectedTeacherId,
        teacherName: selectedTeacherName,
        marksData: marksData,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      for (final controller in markControllers.values) {
        controller.clear();
      }

      for (final controller in commentControllers.values) {
        controller.clear();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks saved successfully'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Widget emptyClassState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No classes found yet. Create a class first from Admin Dashboard.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget emptyStudentState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No students found for this class. Assign students to this class from User Management first.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget markCard(Map<String, dynamic> student) {
    final studentId = student['id'] ?? '';
    final studentName = student['fullName'] ?? 'Unknown Student';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: markControllers[studentId],
            keyboardType: TextInputType.number,
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
              labelText: 'Comment',
              prefixIcon: Icon(Icons.comment_outlined),
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
        title: const Text('Add Marks'),
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
                    ? emptyClassState()
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
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
                                    prefixIcon:
                                        Icon(Icons.menu_book_outlined),
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
                                  onChanged: subjects.isEmpty
                                      ? null
                                      : selectSubject,
                                ),
                                if (selectedClassId.isNotEmpty &&
                                    subjects.isEmpty &&
                                    !isLoadingSubjects) ...[
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No subjects found for this class. Create a subject first.',
                                    style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (selectedClassId.isEmpty)
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Select a class to load students.',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ),
                            )
                          else if (isLoadingStudents || isLoadingSubjects)
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
                        ],
                      ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          color: AppColors.white,
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