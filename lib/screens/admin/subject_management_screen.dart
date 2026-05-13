import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final DatabaseService databaseService = DatabaseService();

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> teachers = [];

  final subjectNameController = TextEditingController();
  final coefficientController = TextEditingController(text: '1');

  String selectedClassId = '';
  String selectedClassName = '';
  String selectedTeacherId = '';
  String selectedTeacherName = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    subjectNameController.dispose();
    coefficientController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedSubjects = await databaseService.getSubjects();
      final loadedClasses = await databaseService.getClasses();
      final loadedUsers = await databaseService.getUsers();

      final loadedTeachers = loadedUsers.where((user) {
        return user['role'] == 'Teacher' && user['isActive'] == true;
      }).toList();

      setState(() {
        subjects = loadedSubjects;
        classes = loadedClasses;
        teachers = loadedTeachers;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> addSubject() async {
    final subjectName = subjectNameController.text.trim();
    final coefficientText = coefficientController.text.trim();
    final coefficient = int.tryParse(coefficientText) ?? 1;

    if (subjectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter subject name'),
        ),
      );
      return;
    }

    if (selectedClassId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class'),
        ),
      );
      return;
    }

    if (selectedTeacherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a teacher'),
        ),
      );
      return;
    }

    try {
      await databaseService.addSubject(
        subjectName: subjectName,
        classId: selectedClassId,
        className: selectedClassName,
        teacherId: selectedTeacherId,
        teacherName: selectedTeacherName,
        coefficient: coefficient,
      );

      if (!mounted) return;

      Navigator.pop(context);

      subjectNameController.clear();
      coefficientController.text = '1';
      selectedClassId = '';
      selectedClassName = '';
      selectedTeacherId = '';
      selectedTeacherName = '';

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject added successfully'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await databaseService.deleteSubject(subjectId: subjectId);

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject deleted successfully'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> confirmDelete(String subjectId, String subjectName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Subject'),
          content: Text('Are you sure you want to delete $subjectName?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteSubject(subjectId);
    }
  }

  void showAddSubjectSheet() {
    subjectNameController.clear();
    coefficientController.text = '1';
    selectedClassId = '';
    selectedClassName = '';
    selectedTeacherId = '';
    selectedTeacherName = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Subject',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 18),

                    TextField(
                      controller: subjectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        hintText: 'Example: Mathematics',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedClassId.isEmpty ? null : selectedClassId,
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
                      onChanged: (value) {
                        final selectedClass = classes.firstWhere(
                          (schoolClass) => schoolClass['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          selectedClassId = value ?? '';
                          selectedClassName =
                              selectedClass['className'] ?? '';
                        });
                      },
                    ),

                    if (classes.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No class found yet. Create a class first.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedTeacherId.isEmpty ? null : selectedTeacherId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Teacher',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: teachers.map((teacher) {
                        return DropdownMenuItem<String>(
                          value: teacher['id'],
                          child: Text(
                            teacher['fullName'] ?? 'Unknown Teacher',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final selectedTeacher = teachers.firstWhere(
                          (teacher) => teacher['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          selectedTeacherId = value ?? '';
                          selectedTeacherName =
                              selectedTeacher['fullName'] ?? '';
                        });
                      },
                    ),

                    if (teachers.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No teacher found yet. Register a teacher account first.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    TextField(
                      controller: coefficientController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Coefficient',
                        hintText: 'Example: 4',
                        prefixIcon: Icon(Icons.numbers_outlined),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: addSubject,
                        icon: const Icon(Icons.add),
                        label: const Text('Save Subject'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No subjects found yet. Tap Add Subject to create your first subject.',
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
        title: const Text('Subject Management'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        onPressed: showAddSubjectSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
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
                : subjects.isEmpty
                    ? emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                        itemCount: subjects.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 12);
                        },
                        itemBuilder: (context, index) {
                          final item = subjects[index];

                          final subjectId = item['id'] ?? '';
                          final subjectName =
                              item['subjectName'] ?? 'Unnamed Subject';
                          final className = item['className'] ?? 'No Class';
                          final teacherName =
                              item['teacherName'] ?? 'No Teacher';
                          final coefficient = item['coefficient'] ?? 1;

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
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_outlined,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        className,
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
                                    ],
                                  ),
                                ),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.softGreen.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Coeff: $coefficient',
                                        style: const TextStyle(
                                          color: AppColors.softGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        confirmDelete(
                                          subjectId,
                                          subjectName,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}