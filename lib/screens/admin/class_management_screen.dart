import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> students = [];

  final classNameController = TextEditingController();
  final levelController = TextEditingController();

  String selectedTeacherId = '';
  String selectedTeacherName = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    classNameController.dispose();
    levelController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final classesSnapshot = await firestore.collection('classes').get();
      final usersSnapshot = await firestore.collection('users').get();

      final loadedClasses = classesSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'className': data['className'] ?? '',
          'level': data['level'] ?? '',
          'teacherId': data['teacherId'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'studentCount': data['studentCount'] ?? 0,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
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

      final loadedStudents = usersSnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          'fullName': data['fullName'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': data['role'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }).where((user) {
        return user['role'] == 'Student' && user['isActive'] == true;
      }).toList();

      loadedStudents.sort((a, b) {
        return (a['fullName'] ?? '').toString().compareTo(
              (b['fullName'] ?? '').toString(),
            );
      });

      if (!mounted) return;

      setState(() {
        classes = loadedClasses;
        teachers = loadedTeachers;
        students = loadedStudents;
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

  Future<void> recalculateClassStudentCount(String classId) async {
    if (classId.isEmpty) return;

    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .get();

    await firestore.collection('classes').doc(classId).set(
      {
        'studentCount': snapshot.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addClass() async {
    final className = classNameController.text.trim();
    final level = levelController.text.trim();

    if (className.isEmpty || level.isEmpty) {
      showSnackBar('Please enter class name and level');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await firestore.collection('classes').add({
        'className': className,
        'level': level,
        'teacherId': selectedTeacherId,
        'teacherName': selectedTeacherName,
        'studentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      classNameController.clear();
      levelController.clear();
      selectedTeacherId = '';
      selectedTeacherName = '';

      if (!mounted) return;

      Navigator.pop(context);

      setState(() {
        isSaving = false;
      });

      await loadData();

      showSnackBar('Class added successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateClass({
    required String classId,
    required String oldClassName,
  }) async {
    final className = classNameController.text.trim();
    final level = levelController.text.trim();

    if (className.isEmpty || level.isEmpty) {
      showSnackBar('Please enter class name and level');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final batch = firestore.batch();
      final classRef = firestore.collection('classes').doc(classId);

      batch.update(classRef, {
        'className': className,
        'level': level,
        'teacherId': selectedTeacherId,
        'teacherName': selectedTeacherName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final studentsSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('classId', isEqualTo: classId)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        batch.update(studentDoc.reference, {
          'className': className,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final subjectsSnapshot = await firestore
          .collection('subjects')
          .where('classId', isEqualTo: classId)
          .get();

      for (final subjectDoc in subjectsSnapshot.docs) {
        batch.update(subjectDoc.reference, {
          'className': className,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final assignmentsSnapshot = await firestore
          .collection('assignments')
          .where('classId', isEqualTo: classId)
          .get();

      for (final assignmentDoc in assignmentsSnapshot.docs) {
        batch.update(assignmentDoc.reference, {
          'className': className,
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

      showSnackBar('$oldClassName updated successfully');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> removeTeacherFromClass({
    required String classId,
    required String className,
  }) async {
    try {
      await firestore.collection('classes').doc(classId).update({
        'teacherId': '',
        'teacherName': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadData();

      showSnackBar('Teacher removed from $className');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteClass({
    required String classId,
    required String className,
  }) async {
    try {
      final batch = firestore.batch();

      final classRef = firestore.collection('classes').doc(classId);
      batch.delete(classRef);

      final studentsSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('classId', isEqualTo: classId)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        batch.update(studentDoc.reference, {
          'classId': '',
          'className': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      await loadData();

      showSnackBar('$className deleted. Students were unassigned from this class.');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> assignStudentToClass({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
    required String oldClassId,
  }) async {
    try {
      await firestore.collection('users').doc(studentId).update({
        'classId': classId,
        'className': className,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await recalculateClassStudentCount(classId);

      if (oldClassId.isNotEmpty && oldClassId != classId) {
        await recalculateClassStudentCount(oldClassId);
      }

      await loadData();

      showSnackBar('$studentName added to $className');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> removeStudentFromClass({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
  }) async {
    try {
      await firestore.collection('users').doc(studentId).update({
        'classId': '',
        'className': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await recalculateClassStudentCount(classId);

      await loadData();

      showSnackBar('$studentName removed from $className');
    } catch (error) {
      if (!mounted) return;

      showSnackBar(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> confirmDeleteClass({
    required String classId,
    required String className,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Class'),
          content: Text(
            'Are you sure you want to delete $className? Students will not be deleted, they will only be removed from this class.',
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
      await deleteClass(
        classId: classId,
        className: className,
      );
    }
  }

  Future<void> confirmRemoveTeacher({
    required String classId,
    required String className,
    required String teacherName,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Remove Teacher'),
          content: Text(
            'Remove $teacherName from $className? The teacher account will not be deleted.',
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
      await removeTeacherFromClass(
        classId: classId,
        className: className,
      );
    }
  }

  Future<void> confirmRemoveStudent({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Remove Student'),
          content: Text(
            'Remove $studentName from $className? The student account will not be deleted.',
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
      await removeStudentFromClass(
        studentId: studentId,
        studentName: studentName,
        classId: classId,
        className: className,
      );
    }
  }

  List<Map<String, dynamic>> studentsInClass(String classId) {
    return students.where((student) {
      return student['classId'] == classId;
    }).toList();
  }

  List<Map<String, dynamic>> studentsNotInClass(String classId) {
    return students.where((student) {
      return student['classId'] != classId;
    }).toList();
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
                    'assets/icons/classes.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.class_outlined,
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
                      'Class Management',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${classes.length} class(es) • ${teachers.length} teacher(s) • ${students.length} student(s).',
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

  void showAddClassSheet() {
    classNameController.clear();
    levelController.clear();
    selectedTeacherId = '';
    selectedTeacherName = '';

    showClassFormSheet(
      title: 'Add New Class',
      buttonText: 'Save Class',
      onSubmit: addClass,
    );
  }

  void showEditClassSheet(Map<String, dynamic> item) {
    final classId = item['id'] ?? '';
    final className = item['className'] ?? '';

    classNameController.text = className;
    levelController.text = item['level'] ?? '';
    selectedTeacherId = item['teacherId'] ?? '';
    selectedTeacherName = item['teacherName'] ?? '';

    showClassFormSheet(
      title: 'Edit Class',
      buttonText: 'Update Class',
      onSubmit: () {
        updateClass(
          classId: classId,
          oldClassName: className,
        );
      },
    );
  }

  void showClassFormSheet({
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
                          imagePath: 'assets/icons/classes.png',
                          fallbackIcon: Icons.class_outlined,
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
                      controller: classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Class Name',
                        hintText: 'Example: Class A',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: levelController,
                      decoration: const InputDecoration(
                        labelText: 'Level',
                        hintText: 'Example: Primary 6',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
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
                        final teacher = teachers.firstWhere(
                          (item) => item['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          selectedTeacherId = value ?? '';
                          selectedTeacherName = teacher['fullName'] ?? '';
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

  void showManageTeacherSheet(Map<String, dynamic> item) {
    final classId = item['id'] ?? '';
    final className = item['className'] ?? '';
    String modalTeacherId = item['teacherId'] ?? '';
    String modalTeacherName = item['teacherName'] ?? '';

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
                          imagePath: 'assets/icons/teacher.png',
                          fallbackIcon: Icons.person_4_outlined,
                          size: 48,
                          padding: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Manage Teacher for $className',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: modalTeacherId.isEmpty ? null : modalTeacherId,
                      decoration: const InputDecoration(
                        labelText: 'Select Teacher',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: teachers.map((teacher) {
                        return DropdownMenuItem<String>(
                          value: teacher['id'],
                          child: Text(teacher['fullName'] ?? 'Unknown Teacher'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final teacher = teachers.firstWhere(
                          (item) => item['id'] == value,
                          orElse: () => {},
                        );

                        setModalState(() {
                          modalTeacherId = value ?? '';
                          modalTeacherName = teacher['fullName'] ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: modalTeacherId.isEmpty
                            ? null
                            : () async {
                                try {
                                  await firestore
                                      .collection('classes')
                                      .doc(classId)
                                      .update({
                                    'teacherId': modalTeacherId,
                                    'teacherName': modalTeacherName,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });

                                  if (!context.mounted) return;

                                  Navigator.pop(context);

                                  await loadData();

                                  showSnackBar('Teacher updated successfully');
                                } catch (error) {
                                  showSnackBar(
                                    error
                                        .toString()
                                        .replaceAll('Exception: ', ''),
                                  );
                                }
                              },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Teacher'),
                      ),
                    ),
                    if ((item['teacherName'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);

                            confirmRemoveTeacher(
                              classId: classId,
                              className: className,
                              teacherName: item['teacherName'] ?? '',
                            );
                          },
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: AppColors.danger,
                          ),
                          label: const Text(
                            'Remove Teacher from Class',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showManageStudentsSheet(Map<String, dynamic> item) {
    final classId = item['id'] ?? '';
    final className = item['className'] ?? '';

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
            final assignedStudents = studentsInClass(classId);
            final availableStudents = studentsNotInClass(classId);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sheetHandle(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        pngIconBox(
                          imagePath: 'assets/icons/student.png',
                          fallbackIcon: Icons.school_outlined,
                          size: 48,
                          padding: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Manage Students for $className',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    smallStatusChip(
                      text: '${assignedStudents.length} assigned student(s)',
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Students in this class',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: assignedStudents.isEmpty
                          ? const Center(
                              child: Text(
                                'No students assigned to this class yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: assignedStudents.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 8);
                              },
                              itemBuilder: (context, index) {
                                final student = assignedStudents[index];

                                return studentRow(
                                  student: student,
                                  trailing: IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);

                                      confirmRemoveStudent(
                                        studentId: student['id'] ?? '',
                                        studentName:
                                            student['fullName'] ?? 'Student',
                                        classId: classId,
                                        className: className,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Add students',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: availableStudents.isEmpty
                          ? const Center(
                              child: Text(
                                'No available students to add.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: availableStudents.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 8);
                              },
                              itemBuilder: (context, index) {
                                final student = availableStudents[index];

                                return studentRow(
                                  student: student,
                                  trailing: IconButton(
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      await assignStudentToClass(
                                        studentId: student['id'] ?? '',
                                        studentName:
                                            student['fullName'] ?? 'Student',
                                        classId: classId,
                                        className: className,
                                        oldClassId: student['classId'] ?? '',
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                );
                              },
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

  Widget studentRow({
    required Map<String, dynamic> student,
    required Widget trailing,
  }) {
    final studentName = student['fullName'] ?? 'Student';
    final email = student['email'] ?? '';
    final currentClassName = student['className'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          pngIconBox(
            imagePath: 'assets/icons/student.png',
            fallbackIcon: Icons.school_outlined,
            size: 42,
            padding: 9,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  currentClassName.toString().isEmpty
                      ? email
                      : '$email • Current: $currentClassName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
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
              imagePath: 'assets/icons/classes.png',
              fallbackIcon: Icons.class_outlined,
              size: 88,
              padding: 18,
            ),
            const SizedBox(height: 18),
            const Text(
              'No classes found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No classes found yet. Tap Add Class to create your first class.',
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

  Widget classCard(Map<String, dynamic> item) {
    final classId = item['id'] ?? '';
    final className = item['className'] ?? 'Unnamed Class';
    final level = item['level'] ?? 'No level';
    final teacherName = item['teacherName'] ?? '';
    final assignedStudents = studentsInClass(classId);
    final studentCount = assignedStudents.length;

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
                      imagePath: 'assets/icons/classes.png',
                      fallbackIcon: Icons.class_outlined,
                      size: 56,
                      padding: 11,
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
                                text: level.toString().isEmpty
                                    ? 'No level'
                                    : level,
                                color: AppColors.primaryBlue,
                              ),
                              smallStatusChip(
                                text: '$studentCount Students',
                                color: AppColors.softGreen,
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
                          showEditClassSheet(item);
                        }

                        if (value == 'teacher') {
                          showManageTeacherSheet(item);
                        }

                        if (value == 'students') {
                          showManageStudentsSheet(item);
                        }

                        if (value == 'delete') {
                          confirmDeleteClass(
                            classId: classId,
                            className: className,
                          );
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Class'),
                          ),
                          PopupMenuItem(
                            value: 'teacher',
                            child: Text('Manage Teacher'),
                          ),
                          PopupMenuItem(
                            value: 'students',
                            child: Text('Manage Students'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Class'),
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
                        showEditClassSheet(item);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        showManageTeacherSheet(item);
                      },
                      icon: const Icon(Icons.person_4_outlined),
                      label: const Text('Teacher'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        showManageStudentsSheet(item);
                      },
                      icon: const Icon(Icons.groups_outlined),
                      label: const Text('Students'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        confirmDeleteClass(
                          classId: classId,
                          className: className,
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
        title: const Text('Class Management'),
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
        onPressed: showAddClassSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage != null
                ? errorState()
                : classes.isEmpty
                    ? emptyState()
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                          itemCount: classes.length + 1,
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

                            return classCard(classes[index - 1]);
                          },
                        ),
                      ),
      ),
    );
  }
}
