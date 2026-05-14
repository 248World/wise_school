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

      if (!mounted) return;

      setState(() {
        subjects = loadedSubjects;
        classes = loadedClasses;
        teachers = loadedTeachers;
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

  Future<void> addSubject() async {
    final subjectName = subjectNameController.text.trim();
    final coefficientText = coefficientController.text.trim();
    final coefficient = int.tryParse(coefficientText) ?? 1;

    if (subjectName.isEmpty) {
      showSnackBar('Please enter subject name');
      return;
    }

    if (selectedClassId.isEmpty) {
      showSnackBar('Please select a class');
      return;
    }

    if (selectedTeacherId.isEmpty) {
      showSnackBar('Please select a teacher');
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

      showSnackBar('Subject added successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await databaseService.deleteSubject(subjectId: subjectId);

      await loadData();

      if (!mounted) return;

      showSnackBar('Subject deleted successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
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

  Widget sheetHandle() {
    return Center(
      child: Container(
        height: 5,
        width: 44,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget headerCard() {
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
                    'assets/icons/subjects.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.menu_book_outlined,
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
                    const Text(
                      'Subject Management',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${subjects.length} subject(s) • ${classes.length} class(es) • ${teachers.length} teacher(s).',
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sheetHandle(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        pngIconBox(
                          imagePath: 'assets/icons/subjects.png',
                          fallbackIcon: Icons.menu_book_outlined,
                          size: 48,
                          padding: 10,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Add New Subject',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pngIconBox(
              imagePath: 'assets/icons/subjects.png',
              fallbackIcon: Icons.menu_book_outlined,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'No subjects found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No subjects found yet. Tap Add Subject to create your first subject.',
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

  Widget subjectCard(Map<String, dynamic> item) {
    final subjectId = item['id'] ?? '';
    final subjectName = item['subjectName'] ?? 'Unnamed Subject';
    final className = item['className'] ?? 'No Class';
    final teacherName = item['teacherName'] ?? 'No Teacher';
    final coefficient = item['coefficient'] ?? 1;

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
                  color: AppColors.primaryBlue.withValues(alpha: 0.045),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pngIconBox(
                  imagePath: 'assets/icons/subjects.png',
                  fallbackIcon: Icons.menu_book_outlined,
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
                            text: 'Coeff: $coefficient',
                            color: AppColors.softGreen,
                          ),
                          smallStatusChip(
                            text: className.toString().isEmpty
                                ? 'No class'
                                : className.toString(),
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      detailLine(
                        icon: Icons.person_outline,
                        text: teacherName.toString().isEmpty
                            ? 'Teacher: Not assigned'
                            : 'Teacher: $teacherName',
                      ),
                    ],
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
      ),
    );
  }

  Widget errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMessage ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                ? errorState()
                : subjects.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                          itemCount: subjects.length + 1,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: headerCard(),
                              );
                            }

                            return subjectCard(subjects[index - 1]);
                          },
                        ),
                      ),
      ),
    );
  }
}