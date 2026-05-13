import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AssignmentsScreen extends StatefulWidget {
  final String role;

  const AssignmentsScreen({
    super.key,
    this.role = 'Teacher',
  });

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> subjects = [];

  String selectedClassId = '';
  String selectedClassName = '';
  String selectedSubjectId = '';
  String selectedSubjectName = '';

  DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  bool get canCreateAssignment {
    return widget.role == 'Teacher' || widget.role == 'Admin';
  }

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final authProvider = context.read<AuthProvider>();
      final currentRole = authProvider.role ?? widget.role;
      final currentUserId = authProvider.userId ?? '';

      if (currentRole == 'Student') {
        await loadStudentAssignments(currentUserId);
      } else if (currentRole == 'Parent') {
        await loadParentAssignments(currentUserId);
      } else {
        await loadClassesAndAssignments();
      }

      if (!mounted) return;

      setState(() {
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

  Future<void> loadClassesAndAssignments() async {
    final classesSnapshot = await firestore.collection('classes').get();

    final loadedClasses = classesSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'className': data['className'] ?? '',
        'level': data['level'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
      };
    }).toList();

    final assignmentsSnapshot = await firestore.collection('assignments').get();

    final loadedAssignments = assignmentsSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'subjectId': data['subjectId'] ?? '',
        'subjectName': data['subjectName'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'dueDate': data['dueDate'],
        'createdAt': data['createdAt'],
      };
    }).toList();

    loadedAssignments.sort((a, b) {
      final aCreated = a['createdAt'];
      final bCreated = b['createdAt'];

      if (aCreated is Timestamp && bCreated is Timestamp) {
        return bCreated.compareTo(aCreated);
      }

      return 0;
    });

    classes = loadedClasses;
    assignments = loadedAssignments;
  }

  Future<void> loadStudentAssignments(String userId) async {
    final userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      assignments = [];
      return;
    }

    final userData = userDoc.data();
    final classId = userData?['classId'] ?? '';

    if (classId.toString().isEmpty) {
      assignments = [];
      return;
    }

    final assignmentsSnapshot = await firestore
        .collection('assignments')
        .where('classId', isEqualTo: classId)
        .get();

    final loadedAssignments = assignmentsSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'subjectId': data['subjectId'] ?? '',
        'subjectName': data['subjectName'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
        'dueDate': data['dueDate'],
        'createdAt': data['createdAt'],
      };
    }).toList();

    loadedAssignments.sort((a, b) {
      final aCreated = a['createdAt'];
      final bCreated = b['createdAt'];

      if (aCreated is Timestamp && bCreated is Timestamp) {
        return bCreated.compareTo(aCreated);
      }

      return 0;
    });

    assignments = loadedAssignments;
  }

  Future<void> loadParentAssignments(String parentId) async {
    final childrenSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .get();

    final classIds = childrenSnapshot.docs
        .map((doc) => doc.data()['classId'] ?? '')
        .where((classId) => classId.toString().isNotEmpty)
        .toSet()
        .toList();

    if (classIds.isEmpty) {
      assignments = [];
      return;
    }

    final loadedAssignments = <Map<String, dynamic>>[];

    for (final classId in classIds) {
      final assignmentsSnapshot = await firestore
          .collection('assignments')
          .where('classId', isEqualTo: classId)
          .get();

      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();

        loadedAssignments.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'classId': data['classId'] ?? '',
          'className': data['className'] ?? '',
          'subjectId': data['subjectId'] ?? '',
          'subjectName': data['subjectName'] ?? '',
          'teacherId': data['teacherId'] ?? '',
          'teacherName': data['teacherName'] ?? '',
          'dueDate': data['dueDate'],
          'createdAt': data['createdAt'],
        });
      }
    }

    loadedAssignments.sort((a, b) {
      final aCreated = a['createdAt'];
      final bCreated = b['createdAt'];

      if (aCreated is Timestamp && bCreated is Timestamp) {
        return bCreated.compareTo(aCreated);
      }

      return 0;
    });

    assignments = loadedAssignments;
  }

  Future<void> loadSubjectsByClass(String classId) async {
    final subjectsSnapshot = await firestore
        .collection('subjects')
        .where('classId', isEqualTo: classId)
        .get();

    final loadedSubjects = subjectsSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'subjectName': data['subjectName'] ?? '',
        'classId': data['classId'] ?? '',
        'className': data['className'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'teacherName': data['teacherName'] ?? '',
      };
    }).toList();

    if (!mounted) return;

    setState(() {
      subjects = loadedSubjects;
      selectedSubjectId = '';
      selectedSubjectName = '';
    });
  }

  void selectClass(String? value, void Function(void Function()) setModalState) {
    if (value == null) return;

    final selectedClass = classes.firstWhere(
      (schoolClass) => schoolClass['id'] == value,
      orElse: () => {},
    );

    setModalState(() {
      selectedClassId = value;
      selectedClassName = selectedClass['className'] ?? '';
      subjects = [];
      selectedSubjectId = '';
      selectedSubjectName = '';
    });

    loadSubjectsByClass(value);
  }

  void selectSubject(
    String? value,
    void Function(void Function()) setModalState,
  ) {
    if (value == null) return;

    final selectedSubject = subjects.firstWhere(
      (subject) => subject['id'] == value,
      orElse: () => {},
    );

    setModalState(() {
      selectedSubjectId = value;
      selectedSubjectName = selectedSubject['subjectName'] ?? '';
    });
  }

  Future<void> pickDueDate(
    BuildContext modalContext,
    void Function(void Function()) setModalState,
  ) async {
    final pickedDate = await showDatePicker(
      context: modalContext,
      initialDate: selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    setModalState(() {
      selectedDueDate = pickedDate;
    });
  }

  Future<void> saveAssignment() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter assignment title'),
        ),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter assignment description'),
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

    if (selectedSubjectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final authProvider = context.read<AuthProvider>();

      await firestore.collection('assignments').add({
        'title': title,
        'description': description,
        'classId': selectedClassId,
        'className': selectedClassName,
        'subjectId': selectedSubjectId,
        'subjectName': selectedSubjectName,
        'teacherId': authProvider.userId ?? '',
        'teacherName': authProvider.fullName ?? widget.role,
        'dueDate': Timestamp.fromDate(selectedDueDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      titleController.clear();
      descriptionController.clear();
      selectedClassId = '';
      selectedClassName = '';
      selectedSubjectId = '';
      selectedSubjectName = '';
      subjects = [];
      selectedDueDate = DateTime.now().add(const Duration(days: 7));

      await loadInitialData();

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment created successfully'),
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

  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await firestore.collection('assignments').doc(assignmentId).delete();

      await loadInitialData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment deleted successfully'),
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

  Future<void> confirmDelete(String assignmentId, String title) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Assignment'),
          content: Text('Are you sure you want to delete "$title"?'),
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
      await deleteAssignment(assignmentId);
    }
  }

  void showAddAssignmentSheet() {
    titleController.clear();
    descriptionController.clear();
    selectedClassId = '';
    selectedClassName = '';
    selectedSubjectId = '';
    selectedSubjectName = '';
    subjects = [];
    selectedDueDate = DateTime.now().add(const Duration(days: 7));

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
                      'Create Assignment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Assignment Title',
                        prefixIcon: Icon(Icons.assignment_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description_outlined),
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
                      onChanged: (value) => selectClass(value, setModalState),
                    ),
                    if (classes.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No class found yet. Admin must create a class first.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedSubjectId.isEmpty ? null : selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Select Subject',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      items: subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject['id'],
                          child: Text(
                            subject['subjectName'] ?? 'Unnamed Subject',
                          ),
                        );
                      }).toList(),
                      onChanged: subjects.isEmpty
                          ? null
                          : (value) => selectSubject(value, setModalState),
                    ),
                    if (selectedClassId.isNotEmpty && subjects.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No subject found for this class. Admin must create a subject first.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => pickDueDate(context, setModalState),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Due Date: ${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveAssignment,
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
                          isSaving ? 'Saving...' : 'Save Assignment',
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

  String formatDueDate(dynamic dueDate) {
    if (dueDate is Timestamp) {
      final date = dueDate.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'No due date';
  }

  Widget assignmentCard(Map<String, dynamic> assignment) {
    final assignmentId = assignment['id'] ?? '';
    final title = assignment['title'] ?? 'Untitled Assignment';
    final description = assignment['description'] ?? '';
    final className = assignment['className'] ?? '';
    final subjectName = assignment['subjectName'] ?? '';
    final teacherName = assignment['teacherName'] ?? '';
    final dueDate = assignment['dueDate'];

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
              Icons.assignment_outlined,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subjectName.isEmpty ? 'No subject' : subjectName,
                  style: const TextStyle(
                    color: AppColors.textGrey,
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
                  teacherName.isEmpty ? 'Teacher not assigned' : 'Teacher: $teacherName',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Due: ${formatDueDate(dueDate)}',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (canCreateAssignment)
            IconButton(
              onPressed: () {
                confirmDelete(assignmentId, title);
              },
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }

  Widget emptyState() {
    String message = 'No assignments found yet.';

    if (widget.role == 'Student') {
      message =
          'No assignments found for your class yet. Ask your teacher to create assignments.';
    }

    if (widget.role == 'Teacher' || widget.role == 'Admin') {
      message = 'No assignments found yet. Tap Add Assignment to create one.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == 'Student'
        ? 'My Assignments'
        : widget.role == 'Parent'
            ? 'Child Assignments'
            : 'Assignments';

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
      floatingActionButton: canCreateAssignment
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              onPressed: showAddAssignmentSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Assignment'),
            )
          : null,
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
                : assignments.isEmpty
                    ? emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                        itemCount: assignments.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 12);
                        },
                        itemBuilder: (context, index) {
                          return assignmentCard(assignments[index]);
                        },
                      ),
      ),
    );
  }
}