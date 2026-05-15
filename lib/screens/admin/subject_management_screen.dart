import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
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

      final subjectsSnapshot = await firestore.collection('subjects').get();
      final classesSnapshot = await firestore.collection('classes').get();
      final usersSnapshot = await firestore.collection('users').get();

      final loadedSubjects = subjectsSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'subjectName': data['subjectName'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'teacherId': data['teacherId'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'coefficient': data['coefficient'] ?? 1,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }).toList();

      loadedSubjects.sort((a, b) {
        return (a['subjectName'] ?? '').toString().compareTo(
              (b['subjectName'] ?? '').toString(),
            );
      });

      final loadedClasses = classesSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'className': data['className'] ?? '',
          'level': data['level'] ?? '',
          'teacherId': data['teacherId'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'studentCount': data['studentCount'] ?? 0,
        };
      }).toList();

      loadedClasses.sort((a, b) {
        return (a['className'] ?? '').toString().compareTo(
              (b['className'] ?? '').toString(),
            );
      });

      final loadedTeachers = usersSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'fullName': data['fullName'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': data['role'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }).where((user) {
        return user['role'] == 'Teacher' && user['isActive'] == true;
      }).toList();

      loadedTeachers.sort((a, b) {
        return (a['fullName'] ?? '').toString().compareTo(
              (b['fullName'] ?? '').toString(),
            );
      });

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

  int parseCoefficient(String value) {
    final coefficient = int.tryParse(value.trim()) ?? 1;

    if (coefficient <= 0) {
      return 1;
    }

    return coefficient;
  }

  Future<void> addSubject() async {
    final subjectName = subjectNameController.text.trim();
    final coefficient = parseCoefficient(coefficientController.text);

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
      setState(() {
        isSaving = true;
      });

      await firestore.collection('subjects').add({
        'subjectName': subjectName,
        'classId': selectedClassId,
        'className': selectedClassName,
        'teacherId': selectedTeacherId,
        'teacherName': selectedTeacherName,
        'coefficient': coefficient,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      subjectNameController.clear();
      coefficientController.text = '1';
      selectedClassId = '';
      selectedClassName = '';
      selectedTeacherId = '';
      selectedTeacherName = '';

      if (!mounted) return;

      Navigator.pop(context);

      setState(() {
        isSaving = false;
      });

      await loadData();

      showSnackBar('Subject added successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateSubject({
    required String subjectId,
    required String oldSubjectName,
  }) async {
    final subjectName = subjectNameController.text.trim();
    final coefficient = parseCoefficient(coefficientController.text);

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
      setState(() {
        isSaving = true;
      });

      final batch = firestore.batch();
      final subjectRef = firestore.collection('subjects').doc(subjectId);

      batch.update(subjectRef, {
        'subjectName': subjectName,
        'classId': selectedClassId,
        'className': selectedClassName,
        'teacherId': selectedTeacherId,
        'teacherName': selectedTeacherName,
        'coefficient': coefficient,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final marksSnapshot = await firestore
          .collection('marks')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final markDoc in marksSnapshot.docs) {
        batch.update(markDoc.reference, {
          'subjectName': subjectName,
          'classId': selectedClassId,
          'className': selectedClassName,
          'teacherId': selectedTeacherId,
          'teacherName': selectedTeacherName,
          'coefficient': coefficient,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final assignmentsSnapshot = await firestore
          .collection('assignments')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final assignmentDoc in assignmentsSnapshot.docs) {
        batch.update(assignmentDoc.reference, {
          'subjectName': subjectName,
          'classId': selectedClassId,
          'className': selectedClassName,
          'teacherId': selectedTeacherId,
          'teacherName': selectedTeacherName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final timetableSnapshot = await firestore
          .collection('timetables')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final timetableDoc in timetableSnapshot.docs) {
        batch.update(timetableDoc.reference, {
          'subjectName': subjectName,
          'classId': selectedClassId,
          'className': selectedClassName,
          'teacherId': selectedTeacherId,
          'teacherName': selectedTeacherName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      Navigator.pop(context);

      setState(() {
        isSaving = false;
      });

      await loadData();

      showSnackBar('$oldSubjectName updated successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> removeTeacherFromSubject({
    required String subjectId,
    required String subjectName,
  }) async {
    try {
      await firestore.collection('subjects').doc(subjectId).update({
        'teacherId': '',
        'teacherName': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final batch = firestore.batch();

      final marksSnapshot = await firestore
          .collection('marks')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final markDoc in marksSnapshot.docs) {
        batch.update(markDoc.reference, {
          'teacherId': '',
          'teacherName': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final assignmentsSnapshot = await firestore
          .collection('assignments')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final assignmentDoc in assignmentsSnapshot.docs) {
        batch.update(assignmentDoc.reference, {
          'teacherId': '',
          'teacherName': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await loadData();

      showSnackBar('Teacher removed from $subjectName');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteSubject({
    required String subjectId,
    required String subjectName,
  }) async {
    try {
      final batch = firestore.batch();

      batch.delete(firestore.collection('subjects').doc(subjectId));

      final marksSnapshot = await firestore
          .collection('marks')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final markDoc in marksSnapshot.docs) {
        batch.delete(markDoc.reference);
      }

      final assignmentsSnapshot = await firestore
          .collection('assignments')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final assignmentDoc in assignmentsSnapshot.docs) {
        batch.delete(assignmentDoc.reference);
      }

      final timetableSnapshot = await firestore
          .collection('timetables')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      for (final timetableDoc in timetableSnapshot.docs) {
        batch.delete(timetableDoc.reference);
      }

      await batch.commit();

      await loadData();

      showSnackBar('$subjectName deleted successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDelete({
    required String subjectId,
    required String subjectName,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Subject'),
          content: Text(
            'Are you sure you want to delete $subjectName? Related marks, assignments, and timetable records for this subject will also be deleted.',
          ),
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
      await deleteSubject(
        subjectId: subjectId,
        subjectName: subjectName,
      );
    }
  }

  Future<void> confirmRemoveTeacher({
    required String subjectId,
    required String subjectName,
    required String teacherName,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Remove Teacher'),
          content: Text(
            'Remove $teacherName from $subjectName? The teacher account will not be deleted.',
          ),
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
                'Remove',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      await removeTeacherFromSubject(
        subjectId: subjectId,
        subjectName: subjectName,
      );
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

  void prepareAddSubject() {
    subjectNameController.clear();
    coefficientController.text = '1';
    selectedClassId = '';
    selectedClassName = '';
    selectedTeacherId = '';
    selectedTeacherName = '';
  }

  void prepareEditSubject(Map<String, dynamic> item) {
    subjectNameController.text = item['subjectName'] ?? '';
    coefficientController.text = (item['coefficient'] ?? 1).toString();
    selectedClassId = item['classId'] ?? '';
    selectedClassName = item['className'] ?? '';
    selectedTeacherId = item['teacherId'] ?? '';
    selectedTeacherName = item['teacherName'] ?? '';
  }

  void showAddSubjectSheet() {
    prepareAddSubject();

    showSubjectFormSheet(
      title: 'Add New Subject',
      buttonText: 'Save Subject',
      onSubmit: addSubject,
    );
  }

  void showEditSubjectSheet(Map<String, dynamic> item) {
    final subjectId = item['id'] ?? '';
    final oldSubjectName = item['subjectName'] ?? 'Subject';

    prepareEditSubject(item);

    showSubjectFormSheet(
      title: 'Edit Subject',
      buttonText: 'Update Subject',
      onSubmit: () {
        updateSubject(
          subjectId: subjectId,
          oldSubjectName: oldSubjectName,
        );
      },
    );
  }

  void showSubjectFormSheet({
    required String title,
    required String buttonText,
    required VoidCallback onSubmit,
  }) {
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
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
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
                        labelText: 'Select / Change Class',
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
                        labelText: 'Assign / Change Teacher',
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
                        onPressed: isSaving ? null : onSubmit,
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
                          isSaving ? 'Saving...' : buttonText,
                        ),
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
    final teacherName = item['teacherName'] ?? '';
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showEditSubjectSheet(item);
                        }

                        if (value == 'removeTeacher') {
                          if (teacherName.toString().isEmpty) {
                            showSnackBar('No teacher assigned to this subject');
                            return;
                          }

                          confirmRemoveTeacher(
                            subjectId: subjectId,
                            subjectName: subjectName,
                            teacherName: teacherName,
                          );
                        }

                        if (value == 'delete') {
                          confirmDelete(
                            subjectId: subjectId,
                            subjectName: subjectName,
                          );
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Subject'),
                          ),
                          PopupMenuItem(
                            value: 'removeTeacher',
                            child: Text('Remove Teacher'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Subject'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        showEditSubjectSheet(item);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: teacherName.toString().isEmpty
                          ? null
                          : () {
                              confirmRemoveTeacher(
                                subjectId: subjectId,
                                subjectName: subjectName,
                                teacherName: teacherName,
                              );
                            },
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Teacher'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        confirmDelete(
                          subjectId: subjectId,
                          subjectName: subjectName,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
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
